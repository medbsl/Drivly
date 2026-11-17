# Privacy

Drivly keeps everything on your phone.

- **No account, no cloud, no tracking.** There are no analytics or crash-reporting SDKs.
- **Your car data** (live values, history, trips, fault codes, VIN) is stored in a local database on
  your phone. You can delete it at any time in Settings → History & trips.
- **Bluetooth** is used only to talk to your OBD adapter. On Android 12+, scanning is declared
  `neverForLocation`. Older Android versions require Location to be on for Bluetooth scanning, but
  Drivly never reads your location.
- **Nothing is sent anywhere** unless you start it yourself: *Share* (a code summary or the adapter
  log, with the VIN masked) or *Search online* (opens your browser).
- **Fonts** are system fonts. Nothing is downloaded at runtime.
