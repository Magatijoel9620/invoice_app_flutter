import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });

async function userFromRequest(req: Request) {
  const auth = req.headers.get("Authorization");
  if (!auth) return null;
  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const client = createClient(url, anon, { global: { headers: { Authorization: auth } } });
  const result = await client.auth.getUser();
  return result.error ? null : result.data.user;
}

function mapStatus(value: string) {
  return value === "trial" ? "trialing" : value;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
  return new Response("ok", {
    status: 200,
    headers: corsHeaders,
  });
}
  if (req.method !== "POST") return json({ error: "POST required" }, 405);

  try {
    const user = await userFromRequest(req);
    if (!user) return json({ error: "Unauthorized" }, 401);

    const body = await req.json();
    const operation = String(body.operation ?? "snapshot").trim();
    const appUrl = Deno.env.get("SUPABASE_URL")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const centralUrl = Deno.env.get("PAYMENT_ENGINE_BILLING_BRIDGE_URL");
    const centralSecret = Deno.env.get("PAYMENT_ENGINE_BILLING_BRIDGE_SECRET");
    if (!centralUrl || !centralSecret) return json({ error: "Billing bridge is not configured" }, 500);

    const admin = createClient(appUrl, service);

    // Plan catalogue is independent of the user's business and subscription.
    // The app JWT is still verified above; only this server forwards to the
    // central bridge using its private shared secret.
    if (operation === "catalogue") {
      const catalogueResponse = await fetch(centralUrl.replace(/\/$/, ""), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-billing-bridge-secret": centralSecret,
        },
        body: JSON.stringify({ operation: "catalogue" }),
      });
      const catalogue = await catalogueResponse.json().catch(() => ({ error: "Invalid billing catalogue response" }));
      return json(catalogue, catalogueResponse.status);
    }

    const businessResult = await admin.from("businesses").select("id, owner_id, data").eq("owner_id", user.id).is("deleted_at", null).maybeSingle();
    if (businessResult.error) return json({ error: businessResult.error.message }, 500);
    if (!businessResult.data) return json({ error: "InvoiceEasy business not found" }, 409);
    const business = businessResult.data;

    if (body.business_id && String(body.business_id) !== String(business.id)) {
      return json({ error: "Business access denied" }, 403);
    }

    const businessData = (business.data ?? {}) as Record<string, unknown>;
    const centralBody = {
      ...body,
      operation,
      business_id: business.id,
      user_id: user.id,
      full_name: body.full_name ?? businessData.name ?? user.user_metadata?.full_name ?? "InvoiceEasy Customer",
      email: body.email ?? businessData.email ?? user.email ?? "billing@example.invalid",
      phone: body.phone ?? businessData.phone ?? user.user_metadata?.phone ?? null,
    };

    const response = await fetch(centralUrl.replace(/\/$/, ""), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-billing-bridge-secret": centralSecret,
      },
      body: JSON.stringify(centralBody),
    });
    const snapshot = await response.json().catch(() => ({ error: "Invalid billing engine response" }));
    if (!response.ok) return json(snapshot, response.status);

    // Keep the existing local subscriptions row as a trusted projection used
    // by InvoiceEasy RLS. The central Payment Engine remains authoritative.
    // This runs after the business exists and the central snapshot succeeds.
    if (operation === "snapshot" && snapshot && typeof snapshot === "object") {
      const subscription = snapshot.subscription;
      if (subscription && typeof subscription === "object") {
        const centralPlans = Array.isArray(snapshot.plans) ? snapshot.plans : [];
        const centralPlan = centralPlans.find((plan: Record<string, unknown>) =>
          String(plan.id ?? "") === String(subscription.plan_id ?? "")
        );
        if (!centralPlan?.code) {
          return json({ error: "The active Payment Engine subscription has no matching InvoiceEasy plan in the billing snapshot." }, 502);
        }

        const projectedStatus = String(subscription.status ?? "").toLowerCase();
        const supportedStatuses = new Set(["trial", "trialing", "active", "past_due", "expired", "cancelled"]);
        if (!supportedStatuses.has(projectedStatus)) {
          return json({ error: `Unsupported Payment Engine subscription status: ${projectedStatus || "unknown"}` }, 502);
        }

        const projection = await admin.rpc("invoice_easy_project_payment_engine_subscription", {
          p_owner_id: user.id,
          p_account_id: String(snapshot.account?.id ?? ""),
          p_subscription_id: String(subscription.id ?? ""),
          p_engine_plan_id: String(centralPlan.id),
          p_plan_code: String(centralPlan.code),
          p_status: projectedStatus,
          p_started_at: subscription.current_period_start ?? subscription.created_at ?? null,
          p_expires_at: subscription.current_period_end ?? null,
          p_trial_ends_at: subscription.trial_ends_at ?? null,
          p_cancelled_at: subscription.cancelled_at ?? null,
          p_auto_renew: subscription.auto_renew ?? !(subscription.cancel_at_period_end === true),
          p_entitlements: Array.isArray(snapshot.entitlements) ? snapshot.entitlements : [],
        });
        if (projection.error) {
          console.error("InvoiceEasy subscription projection failed", projection.error);
          return json({ error: "Billing is available, but InvoiceEasy could not synchronize the local access record." }, 502);
        }
        snapshot.local_subscription_projection = projection.data;
      }
    }

    return json(snapshot);
  } catch (error) {
    console.error("InvoiceEasy app billing bridge error", error);
    return json({ error: error instanceof Error ? error.message : "Billing bridge failed" }, 500);
  }
});


