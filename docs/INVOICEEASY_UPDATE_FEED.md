# InvoiceEasy update feed

InvoiceEasy checks this metadata URL:

`https://portfolio-mjs.vercel.app/invoiceeasy/update.json`

Publish a JSON file at that exact URL. The feed is separate from Farmora's
`/farmora/update.json` feed.

Required JSON fields:

```json
{
  "version": "3.0.1",
  "downloadUrl": "https://YOUR-DOWNLOAD-HOST/invoiceeasy/latest.apk",
  "releaseNotes": "Describe the changes in this release."
}
```

- `version` must match the app's `version:` value in `pubspec.yaml` (without
  the `+buildNumber` suffix), for example `3.0.1`.
- `downloadUrl` must be an HTTPS URL to the actual release/download page or APK.
- `releaseNotes` is optional and is shown in the update prompt.
- Keep this feed's version at or below the currently published app version until
  a newer InvoiceEasy release is ready. Do not copy Farmora's version or APK URL.

The app treats an unavailable or invalid feed as a non-fatal update-check failure;
normal InvoiceEasy use and local data are unaffected.
