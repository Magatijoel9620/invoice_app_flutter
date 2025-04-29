# 🧾 Flutter Invoice App

A modern, cross-platform Flutter application for managing invoices. Supports dark mode, PDF generation, and invoice archiving. Designed for both web and mobile platforms.

## ✨ Features

- 📄 Create, edit, delete invoices
- 📂 Archive invoices (soft delete)
- 🌙 Light/Dark theme toggle
- 🖨️ Print invoices (web and mobile)
- 📥 Download invoices as PDF
- 🔐 Local data storage (persistent)
- 🎨 Clean UI using Material Design
- 📆 Date formatting using `intl`

## 🖥️ Screens

- **Invoice List Screen**: View, edit, archive, print, or delete invoices
- **Invoice Entry Screen**: Add or edit invoice details

## 📦 Dependencies

| Package            | Purpose                           |
|--------------------|-----------------------------------|
| `flutter_slidable` | Swipe actions (archive/delete)    |
| `printing`         | PDF generation & printing         |
| `intl`             | Date formatting                   |
| `uuid`             | Unique invoice IDs                |
| `path_provider`    | Local storage paths               |
| `shared_preferences` | Save theme mode & app settings |

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Magatijoel9620/invoice_app_flutter.git
cd invoice_app_flutter
