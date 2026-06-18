# 🧾 Flutter Invoice App

A modern, feature-rich, cross-platform Flutter application for creating, managing, printing, and sharing professional invoices.

Built with Flutter and Material Design 3, the app supports Android, iOS, Web, Windows, Linux, and macOS while providing a clean and responsive user experience.

---

## ✨ Features

### 📄 Invoice Management

* Create professional invoices
* Edit existing invoices
* Delete invoices permanently
* Automatic invoice total calculations
* Dynamic line item management
* Real-time line item total calculations
* Client information management

### 📦 Line Items

* Add unlimited invoice items
* Quantity and unit price support
* Automatic line totals
* Automatic invoice grand total updates
* Validation for required fields

### 📂 Invoice Archiving

* Archive invoices instead of deleting
* Keep active invoice list clean
* Restore archived invoices (planned)
* Soft-delete functionality

### 🖨️ PDF Generation

Generate beautiful professional PDFs with:

* Company branding
* Company logo support
* QR code generation
* Invoice details section
* Itemized invoice tables
* Payment instructions
* Bank details
* M-Pesa payment details
* Thank-you message
* Print-ready layouts

### 🎨 PDF Branding & Customization

Customize PDFs directly from the application:

* Upload company logo
* Company name customization
* Colored PDF header
* Custom footer message
* Payment details configuration
* Bank account information
* M-Pesa Till Number
* M-Pesa Phone Number

### 📥 Export & Sharing

* Print invoices directly
* Download PDF invoices
* Share invoices via device sharing options
* Web PDF download support
* Mobile print dialog support

### 🌙 Theme Support

* Light Mode
* Dark Mode
* Material Design 3 styling
* Consistent color schemes

### 💾 Local Storage

Stores data locally on the device:

* Invoices
* PDF settings
* Theme preferences
* User customizations

### 📱 Cross Platform

Supports:

* Android
* iOS
* Web
* Windows
* Linux
* macOS

### 🔄 Responsive Design

* Mobile-friendly layouts
* Tablet optimization
* Desktop support
* Adaptive navigation

---

# 🖥️ Screens

## Invoice List Screen

Features:

* View all active invoices
* Pull-to-refresh
* Swipe actions
* Quick edit
* Quick archive
* Quick delete
* Print invoice
* Share invoice
* Search-ready structure

### Swipe Actions

#### Left Swipe

* Edit Invoice

#### Right Swipe

* Archive Invoice
* Delete Invoice

---

## Invoice Entry Screen

Features:

* Create new invoice
* Edit existing invoice
* Dynamic line items
* Automatic calculations
* Validation
* Responsive form layout

### Invoice Information

* Invoice Number
* Client Name
* Invoice Date

### Line Items

Each item includes:

* Description
* Quantity
* Unit Price
* Line Total

---

## PDF Settings Screen

Configure:

### Company Information

* Company Name
* Company Logo
* Thank You Message

### Bank Details

* Bank Name
* Account Name
* Account Number

### M-Pesa Till

* Till Number
* Account Name

### M-Pesa Phone

* Phone Number
* Account Name

---

# 📄 PDF Output Features

Generated PDFs include:

✅ Company Logo

✅ Company Name

✅ Colored Header Bar

✅ Invoice Details

✅ QR Code

✅ Itemized Table

✅ Line Totals

✅ Grand Total

✅ Payment Instructions

✅ Thank You Message

✅ Footer Page Numbers

---

# 🏗️ Project Structure

```text
lib/
│
├── models/
│   ├── invoice.dart
│   ├── line_item.dart
│   └── pdf_settings.dart
│
├── screens/
│   ├── invoice_list_screen.dart
│   ├── invoice_entry_screen.dart
│   ├── pdf_settings_screen.dart
│   └── home_screen.dart
│
├── services/
│   ├── invoice_storage_service.dart
│   └── pdf_settings_service.dart
│
├── utils/
│   └── invoice_pdf_util.dart
│
├── widgets/
│
└── main.dart
```

---

# 📦 Dependencies

| Package            | Purpose                      |
| ------------------ | ---------------------------- |
| flutter_slidable   | Swipe actions                |
| printing           | PDF printing and sharing     |
| pdf                | PDF document creation        |
| intl               | Currency and date formatting |
| image_picker       | Company logo upload          |
| shared_preferences | Settings persistence         |
| uuid               | Unique invoice IDs           |
| universal_html     | Web downloads                |
| path_provider      | Local file storage           |

---

# 🚀 Getting Started

## Prerequisites

Install:

* Flutter SDK (3.x or newer)
* Android Studio or VS Code
* Flutter extension
* Device or emulator

Verify installation:

```bash
flutter doctor
```

---

## Clone Repository

```bash
git clone https://github.com/yourusername/flutter_invoice_app.git

cd flutter_invoice_app
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run Application

### Android

```bash
flutter run
```

### iOS

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### Windows

```bash
flutter run -d windows
```

### Linux

```bash
flutter run -d linux
```

### macOS

```bash
flutter run -d macos
```

---

# 👨‍💻 Developer Notes

## PDF Branding

The application supports logo uploads through:

```dart
PdfSettings.logoPath
```

The logo is stored locally and loaded during PDF generation.

---

## Settings Persistence

PDF settings are stored using:

```dart
SharedPreferences
```

through:

```dart
PdfSettingsService
```

---

## Invoice Storage

Current implementation uses local storage.

For production consider:

* Hive
* Isar
* SQLite (sqflite)
* Firebase Firestore
* Supabase

---

## Architecture

The project follows a simple layered architecture:

```text
UI (Screens)
     ↓
Services
     ↓
Models
     ↓
Storage
```

---

# 🔮 Roadmap

## Planned Features

* [ ] Archived invoices screen
* [ ] Invoice search
* [ ] Invoice filtering
* [ ] Invoice status tracking
* [ ] Customer database
* [ ] Tax/VAT support
* [ ] Multiple currencies
* [ ] Recurring invoices
* [ ] Invoice templates
* [ ] Email invoices
* [ ] Cloud sync
* [ ] Backup & restore
* [ ] PDF themes
* [ ] Analytics dashboard
* [ ] Unit tests
* [ ] Widget tests
* [ ] Integration tests

---

# 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature/my-feature
```

3. Commit changes

```bash
git commit -m "Add my feature"
```

4. Push changes

```bash
git push origin feature/my-feature
```

5. Open a Pull Request

---

# 📜 License

This project is licensed under the MIT License.

---

Built with ❤️ using Flutter.
