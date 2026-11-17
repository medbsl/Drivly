# Contributing to Drivly

Thanks for helping! Three easy ways to start:

1. **Adapter transcripts.** Connect, use the app for a minute, then go to Settings → Adapter log → Share.
   Open an "adapter compatibility" issue and include the adapter name, its version, and your car's
   make, model and year. Transcripts become replay tests in `packages/obd_core/test/fixtures/`.
2. **Fault code explanations.** Add entries to `app/assets/dtc/en.json`. Write them in your own plain
   words. Don't copy text from commercial DTC sites.
3. **Translations.** The UI strings are in `app/lib/l10n/app_en.arb`. Add `app_de.arb`, `app_fr.arb`,
   `app_ar.arb` and so on.

## Setup

```sh
flutter pub get
cd packages/obd_core && dart test
cd ../../app && flutter analyze && flutter test
```

## Rules of the road

- `packages/obd_core` is pure Dart and never imports Flutter.
- Adapter methods never throw for protocol or data problems. They return an `ObdResult`.
- Values are stored in SI units and converted only when shown.
- Every user-facing string lives in the ARB files. Use `EdgeInsetsDirectional`, `start`/`end`, and
  never left/right.
- Status colors (green, orange, red) always come with an icon and a word.
- Dependencies must be GPL-3.0-compatible (MIT, BSD, Apache-2.0).
