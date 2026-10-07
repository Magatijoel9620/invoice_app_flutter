# InvoiceEasy Release Checklist

## Before building

- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Verify the production Supabase URL and publishable key are supplied with `--dart-define`.
- [ ] Confirm no `.env.*`, signing keys, or local credentials are committed.

## Android

- [ ] Set up `android/key.properties` from `android/key.properties.example`.
- [ ] Use a production upload/release keystore. Never use the debug keystore for a store build.
- [ ] Confirm application ID is `ke.co.hempongroup.invoiceeasy`.
- [ ] Build `flutter build appbundle --release` and verify the signed AAB.
- [ ] Install/test the release build on a physical Android device.

## iOS

- [ ] Confirm bundle ID is `ke.co.hempongroup.invoiceeasy`.
- [ ] Configure Apple signing/team in Xcode.
- [ ] Archive a Release build and validate it in Xcode Organizer.

## Web / desktop

- [ ] Confirm browser/PWA title and metadata say InvoiceEasy.
- [ ] Confirm launcher/app icons use the standalone InvoiceEasy mark.
- [ ] Verify Windows/Linux/macOS application names and identifiers.

## Final smoke test

- [ ] Fresh install launches successfully.
- [ ] Authentication works.
- [ ] Business setup works.
- [ ] Customer/product/invoice create, edit, delete flows work.
- [ ] Offline local data survives app restart.
- [ ] Reconnection syncs queued local changes.
- [ ] PDF generation/printing/sharing works on the target platform.
- [ ] Account settings and sign-out work.
- [ ] No debug banners, placeholder names, or development URLs are visible.
