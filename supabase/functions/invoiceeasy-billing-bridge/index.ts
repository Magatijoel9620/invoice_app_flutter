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


    return json(snapshot);
  } catch (error) {
    console.error("InvoiceEasy app billing bridge error", error);
    return json({ error: error instanceof Error ? error.message : "Billing bridge failed" }, 500);
  }
});


