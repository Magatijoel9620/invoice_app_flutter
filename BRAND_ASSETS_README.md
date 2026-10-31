# InvoiceEasy refreshed brand assets

## Files
- `InvoiceEasy_Mark.png` / `.svg`: universal transparent symbol. Its teal/emerald page, white invoice strokes and white approval tick are designed to remain legible on both light and dark surfaces.
- `InvoiceEasy_Logo_Light.png` / `.svg`: transparent horizontal logo for light surfaces (dark `Invoice`, teal `Easy`).
- `InvoiceEasy_Logo_Dark.png` / `.svg`: transparent horizontal logo for dark surfaces (light `Invoice`, brighter teal `Easy`).
- `InvoiceEasy_Logo.png`: compatibility copy of the light logo using the previous filename.

## Flutter usage
The project already registers `assets/images/` in `pubspec.yaml`.

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
Image.asset(
  isDark
      ? 'assets/images/InvoiceEasy_Logo_Dark.png'
      : 'assets/images/InvoiceEasy_Logo_Light.png',
  fit: BoxFit.contain,
)
```

For app bars, compact navigation, and login avatars use the universal mark:

```dart
Image.asset('assets/images/InvoiceEasy_Mark.png', fit: BoxFit.contain)
```

The wordmark deliberately has no embedded background, so it can sit on the app's existing themed surface. No font files or additional Flutter dependencies are required.
