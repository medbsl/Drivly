# Drivly

A calm, open-source OBD2 app. Plug a cheap Bluetooth LE adapter into your car and see
**every value it shares, live**, with **full history and charts** saved on your phone.
Fault codes are explained in plain words. You don't need an account, and nothing leaves your phone.

## What it does

- **Live dashboard:** speed and RPM gauges, plus a tile with a live sparkline for every value your car
  supports. That's up to ~45 standard values: engine temperature, battery, load, throttle, fuel, air
  flow, fuel trims, oxygen sensors, catalyst temperature, odometer, and more.
- **Everything is saved:** each reading is stored locally in SQLite while you're connected.
- **History charts:** Live (last 15 minutes, in real time), 1H, 24H, 7D, 30D or All. Each chart shows
  an average line with a min–max band, and you can touch it to read exact values. A small chart for
  every value sits underneath.
- **Trips:** recorded automatically, with distance, durations, max and average speed, fuel used and charts.
- **Fault codes:** read automatically when you connect. You get the severity, what it means, whether it's
  safe to drive and what to do. Clearing codes is guarded (blocked while moving, with a snapshot before
  and a re-scan after), and every scan is kept in the history.
- **Car info:** VIN, make, country and likely model year, decoded offline.
- **Demo mode:** a simulated ELM327 adapter that runs the whole real stack, so it works with no car at all.

## Which adapter do I need?

An **ELM327-compatible Bluetooth LE adapter**. These are often labeled "Bluetooth 4.0" or "for iOS".

- iPhones can only talk to Bluetooth LE adapters.
- Many very cheap ELM327 adapters are *classic* Bluetooth (2.0). They show up in Android's Bluetooth
  settings but **not in Drivly** yet.
- "v1.5" clones are often more reliable than "v2.1" clones.

## Which cars work?

OBD2 is mandatory for petrol cars from 1996 (US) and 2001 (EU), and for diesel cars from 2004 (EU).
Cars from about 2008 use CAN, which is the fastest. On CAN, Drivly asks for up to 6 values per request.
Electric cars often expose little standard OBD2 data.

## Privacy

Everything stays on the phone. There are no analytics SDKs, no crash-reporting SDKs and no fonts
fetched at runtime. Nothing goes out unless you start it yourself (Share, Search online).
See [PRIVACY.md](PRIVACY.md).

## Project layout

```
packages/obd_core/   pure Dart: ELM327 session, parser, ISO-TP, PIDs, DTCs, VIN, poll scheduler, simulator
app/                 Flutter app (Riverpod, go_router, sqflite, fl_chart, universal_ble)
docs/                DESIGN.md, ADRs, protocol notes
```

## Build & run

Requires Flutter 3.38+ (Dart 3.8+).

```sh
flutter pub get                      # resolves the whole workspace
cd packages/obd_core && dart test    # protocol core tests
cd ../../app && flutter test         # app tests
flutter run                          # on a device (Bluetooth needs real hardware)
flutter run --dart-define=DRIVLY_DEMO=true   # boots straight into demo mode
flutter run --dart-define=DRIVLY_DEMO=true --dart-define=DRIVLY_TOUR=true   # + cycles through screens (screenshots)
```

Deep links (iOS): `xcrun simctl openurl booted drivly:///history` opens a tab directly.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The easiest ways to help:
**(1)** adapter transcripts (Settings → Adapter log → Share), **(2)** DTC explanations
(`app/assets/dtc/en.json`), and **(3)** translations (`app/lib/l10n/*.arb`).

## License

GPL-3.0. See [LICENSE](LICENSE).
