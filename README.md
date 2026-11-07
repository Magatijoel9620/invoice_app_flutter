# 🧾 InvoiceEasy V3.0
### Professional Invoicing. Simpler Business Management.

<p align="center">
  <img src="assets/invoiceeasy_banner.gif" alt="InvoiceEasy — Professional Invoicing" width="100%">
</p>

<p align="center">
  <strong>Create invoices. Manage customers. Track sales. Stay in control.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.0-0F766E?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Flutter-Powered-02569B?style=for-the-badge&logo=flutter" />
  <img src="https://img.shields.io/badge/Offline--First-Ready-success?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Cloud-Sync-4285F4?style=for-the-badge" />
</p>

---

## 🌟 Welcome to InvoiceEasy

Running a business shouldn't mean spending hours preparing invoices, tracking payments, or organizing customer records.

**InvoiceEasy** is a modern business invoicing and management application designed to make everyday business operations easier.

Whether you're a freelancer, entrepreneur, retailer, consultant, or growing business, InvoiceEasy gives you the tools to manage your invoicing and business records from one place.

Create professional invoices, organize customers and products, monitor business activity, and keep your information accessible — even when your internet connection isn't.

### 🎯 Built around the way businesses work

- 🧾 Create and manage professional invoices.
- 👥 Keep customer information organized.
- 📦 Manage products and services.
- 💰 Track business transactions and payments.
- 📊 Review business performance through reports.
- 📄 Export and share business documents.
- ☁️ Synchronize your business information securely.
- 📵 Continue working when offline.

---

## ✨ Explore InvoiceEasy

<table>
<tr>
<td width="50%">

### 🧾 Professional Invoicing
Create, manage, and organize invoices without complicated processes.

</td>
<td width="50%">

### 👥 Customer Management
Maintain customer records and access their information whenever needed.

</td>
</tr>
<tr>
<td width="50%">

### 📦 Products & Services
Organize the products and services you offer to customers.

</td>
<td width="50%">

### 📊 Business Reports
Get a clearer picture of your business activity through reports and exports.

</td>
</tr>
<tr>
<td width="50%">

### ☁️ Cloud Synchronization
Keep your business information synchronized with your authenticated cloud account.

</td>
<td width="50%">

### 📵 Offline Productivity
Continue using your business records without depending on a constant internet connection.

</td>
</tr>
</table>

---

## 🚀 What Makes V3.0 Different?

V3.0 brings together the established InvoiceEasy experience and a stronger cloud-connected foundation.

### 📵 Work Offline. Sync When Connected.

Your business shouldn't stop because your internet connection does.

InvoiceEasy stores working data locally, allowing you to continue managing your records while offline.

When connectivity returns, the application can synchronize pending changes with your cloud account.

**The experience:**
- Work with local business records.
- Save changes without an active internet connection.
- Keep pending updates safely queued.
- Synchronize automatically when connectivity returns.
- Monitor synchronization status.
- Retry temporary synchronization failures.

### ☁️ Your Business, Connected

With Supabase integration, InvoiceEasy introduces authenticated cloud accounts and account-scoped business data.

Your cloud account supports:
- Secure email and password authentication.
- Persistent login sessions.
- Business profile synchronization.
- Customer, product, and invoice synchronization.
- Password recovery.
- Account management.
- Cloud account deletion.

### 🔄 Intelligent Synchronization

InvoiceEasy uses a persistent synchronization queue to coordinate local and cloud data.

The synchronization system includes:
- Pending operation tracking.
- Automatic synchronization.
- Manual synchronization.
- Retry handling for temporary failures.
- Timestamp-based conflict resolution.
- Cloud deletion records.
- First-login local/cloud data initialization.

### 🔐 Privacy & Account Protection

Your business data belongs to your authenticated account.

InvoiceEasy uses Supabase Row Level Security (RLS) to enforce account-level data ownership and separation.

The V3.0 architecture follows a **one authenticated user → one business** model.

---

## 💼 Designed for Everyday Business Operations

| Business need | InvoiceEasy solution |
|---|---|
| Preparing invoices | Professional invoice creation |
| Managing customers | Organized customer records |
| Managing products | Product and service records |
| Tracking business activity | Reports and exports |
| Working without internet | Local-first data storage |
| Accessing cloud data | Authenticated synchronization |
| Managing an account | Profile and account controls |

---

## 💳 Simple Subscription Options

InvoiceEasy includes a 14-day trial to help users explore the application.

| Plan | Price |
|---|---:|
| Monthly | KSh 200 |
| Annual | KSh 2,000 |

Subscription access and paid-write authorization are enforced on the server, helping protect subscription integrity.

For implementation and configuration details, see [SUBSCRIPTION_HARDENING.md](SUBSCRIPTION_HARDENING.md).

---

## 📱 Platform Availability

InvoiceEasy is built with Flutter, supporting multiple deployment targets.

| Platform | Application |
|---|---|
| 🤖 Android | InvoiceEasy |
| 🍎 iOS | InvoiceEasy |
| 🖥️ Windows | InvoiceEasy |
| 🐧 Linux | InvoiceEasy |
| 💻 macOS | InvoiceEasy |

**Application identifier:** `ke.co.hempongroup.invoiceeasy`

---

## 🎨 Product Experience

InvoiceEasy combines a clean business-oriented interface with practical tools for everyday operations.

The design focuses on:
- Clear navigation.
- Consistent visual presentation.
- Responsive layouts.
- Persistent light and dark themes.
- Accessible business information.
- Straightforward account management.

---

## 🏗️ Under the Hood

For developers and contributors, InvoiceEasy uses a local-first architecture with Supabase providing authentication, cloud storage, synchronization, and account-level security.

### Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application |
| Dart | Application development |
| Riverpod | State management |
| Supabase Auth | Authentication |
| Supabase PostgreSQL | Cloud database |
| Supabase RLS | Data ownership and isolation |
| Supabase Edge Functions | Secure server-side account operations |
| Local storage | Offline business data |
| Persistent Sync Queue | Pending synchronization operations |

### Architecture Highlights

**1. Local-first data management**

The application's local data remains the working source used by the UI.

**2. Cloud synchronization**

A dedicated synchronization layer coordinates changes between local storage and Supabase.

**3. Account isolation**

Cloud records are associated with authenticated users, with RLS policies enforcing ownership.

**4. JSON-compatible cloud models**

Business data is stored in JSON `data` columns, preserving compatibility with the application's existing models while relational metadata handles ownership and synchronization.

**5. Conflict management**

Timestamp-based last-write-wins resolution helps reconcile changes made across local and cloud environments.

---

## 📈 V3.0 Development Milestones

<details>
<summary><strong>✅ V3.0.1 — Cloud Foundation</strong></summary>

- Email/password authentication.
- Persistent sessions.
- Account profiles.
- One-user, one-business architecture.
- Cloud repositories and data mapping.
- Automatic profile creation.
- Row Level Security.

</details>

<details>
<summary><strong>✅ V3.0.2 — Offline-First Synchronization</strong></summary>

- Local-first writes.
- Account-scoped local storage.
- Persistent pending-operation queue.
- Push and pull synchronization.
- Three-attempt transient retry.
- Timestamp-based conflict resolution.
- Cloud tombstones for deletions.
- First-login local/cloud bootstrap.

</details>

<details>
<summary><strong>✅ V3.0.3 — Account Management</strong></summary>

- Account profile screen.
- Business data synchronization.
- Manual synchronization.
- Sync status visibility.
- Password reset.
- Sign out.
- Cloud account deletion through Edge Functions.

</details>

<details>
<summary><strong>✅ Offline Connectivity Improvements</strong></summary>

- Network transport detection.
- HTTP reachability checks.
- Lifecycle-aware connectivity monitoring.
- Periodic connectivity checks.
- Automatic synchronization on reconnection.
- Exponential retry/backoff.
- Failed-operation visibility.
- Global synchronization status banner.

</details>

---

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK.
- Dart SDK.
- Android Studio or Visual Studio Code.
- Git.

### 1. Clone the repository

```bash
git clone YOUR_REPOSITORY_URL
cd invoice_app_flutter
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run locally (Offline Mode)

InvoiceEasy can run without Supabase configuration.

```bash
flutter run
```

### 4. Run with Supabase

Configure your Supabase project:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

**Security reminder:** Never include Supabase secret keys or service-role keys in Flutter application code or build arguments distributed to users.

### 5. Configure the database

Apply the consolidated V3 cloud foundation migration:

`supabase/migrations/20260912_v3_cloud_foundation.sql`

For subscription hardening, also review:

`supabase/migrations/20260914_invoice_easy_subscription_hardening.sql`

Follow [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for complete deployment instructions.

---

## 📦 Production Release

InvoiceEasy uses explicit production signing configuration for Android releases.

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Configure your production keystore.
3. Verify your signing configuration.
4. Build the release bundle.

```bash
flutter build appbundle --release
```

Debug signing fallback is intentionally disabled for release builds.

Before publishing, review:

📋 [Release Checklist](docs/RELEASE_CHECKLIST.md)

---

## 📚 Documentation

| Document | Description |
|---|---|
| [Supabase Setup](SUPABASE_SETUP.md) | Cloud configuration and deployment |
| [Release Checklist](docs/RELEASE_CHECKLIST.md) | Production release preparation |
| [Subscription Hardening](SUBSCRIPTION_HARDENING.md) | Subscription security and access control |
| [Offline Connectivity](docs/offline_first_connectivity.md) | Connectivity and synchronization architecture |

---

## 🏢 Developed by Hempon Group

InvoiceEasy is part of the Hempon Group software portfolio — building practical digital solutions that simplify everyday business operations.

🌐 Website: [www.hempongroup.co.ke](https://www.hempongroup.co.ke)

📧 Email: hempongroup@gmail.com

---

<p align="center">
  <strong>🧾 InvoiceEasy — Your Business. Better Organized.</strong>
  <br/>
  <sub>Built to simplify invoicing. Designed to support business growth.</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Made%20with-Flutter-02569B?style=flat-square&logo=flutter" />
  <img src="https://img.shields.io/badge/Powered%20by-Supabase-3FCF8E?style=flat-square&logo=supabase" />
  <img src="https://img.shields.io/badge/By-Hempon%20Group-0F766E?style=flat-square" />
</p>
