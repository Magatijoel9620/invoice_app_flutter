# 🧾 Flutter Invoice App

A modern, cross-platform Flutter application for managing invoices. Supports dark mode, PDF generation, and invoice archiving. Designed for both web and mobile platforms.

## ✨ Features

- 📄 **Invoice Management**: Create, view, edit, and delete invoices with detailed line items.
- 📂 **Invoice Archiving**: Soft delete invoices by archiving them, keeping your active list clean.
- 🌙 **Theme Customization**: Seamlessly switch between light and dark themes.
- 🖨️ **Print Invoices**: Generate printable views of your invoices (works on web and mobile via system print dialogs).
- 📥 **Download/Share as PDF**: Export invoices as PDF files for easy sharing and record-keeping.
- 🔐 **Local Data Storage**: Invoice data is saved locally on the device for persistence.
    - *Note: The current implementation uses a placeholder/simulated storage service. For production, integrate with a robust solution like SQLite (`sqflite`), Hive, or a backend service.*
- 🎨 **Modern UI**: Clean and intuitive user interface built with Material Design 3 principles.
- 📱 **Responsive Design**: Adapts to different screen sizes for a consistent experience on mobile and web.
- 🌍 **Localization Ready**: Uses `intl` for date formatting, making it easier to adapt for different locales.

## 🖥️ Key Screens

-   **Invoice List Screen**:
    -   Displays a list of active invoices, sorted by date.
    -   Swipe actions to quickly edit, archive, print, or delete invoices.
    -   Pull-to-refresh functionality.
    -   Clear empty state and error messages.
-   **Invoice Entry Screen**:
    -   A dynamic form for creating new invoices or editing existing ones.
    -   Add/remove line items easily.
    -   Automatic calculation of total amounts.
    -   Can be presented as a full screen or a modal bottom sheet.
-   **(Coming Soon/Optional) Archived Invoices Screen**: A dedicated view for managing archived invoices.

## 📦 Core Dependencies

| Package              | Purpose                                       |
|----------------------|-----------------------------------------------|
| `flutter_slidable`   | Swipeable list items for quick actions        |
| `printing`           | PDF generation, layout, printing, and sharing |
| `intl`               | Internationalization and date/number formatting |
| `uuid`               | Generating unique IDs for invoices            |
| `shared_preferences` | Storing user preferences (e.g., theme mode)   |
| `path_provider`      | (Typically used with file-based storage like Hive/Sqflite to find appropriate directories) |

## 🚀 Getting Started

### Prerequisites

-   [Flutter SDK](https://flutter.dev/docs/get-started/install) (ensure it's added to your PATH)
-   An IDE like Android Studio (with Flutter plugin) or VS Code (with Flutter extension)
-   A device or emulator to run the app

### 1. Clone the Repository

### 2. Install Dependencies

Navigate to the project directory and run:

### 3. Run the Application

You can run the application on your chosen device/emulator or on the web.

**For Mobile (Android/iOS):**

Make sure you have a connected device or a running emulator.

**For Web:**
(You can replace `chrome` with `edge` or other supported browsers.)

**For Desktop (if configured):**
(You can replace `chrome` with `edge` or other supported browsers.)

**For Desktop (if configured):**

## 💡 Future Enhancements / TODO

-   [ ] Implement a robust local database solution (e.g., `sqflite` or `hive`).
-   [ ] Add an "Archived Invoices" screen with unarchive functionality.
-   [ ] User authentication (optional, for cloud sync).
-   [ ] Cloud synchronization of invoices.
-   [ ] More detailed settings/preferences screen.
-   [ ] Unit and widget tests for core functionalities.
-   [ ] Customizable PDF templates.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Magatijoel9620/invoice_app_flutter/issues).

---

_This README was last updated on 20225-07-08._