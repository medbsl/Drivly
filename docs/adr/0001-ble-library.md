# ADR-0001: BLE library

- **Status:** Accepted (2026-11-16). Confirm with a 1-day spike on the real test adapters.
- **Context:** DESIGN.md §10 Q2. `flutter_blue_plus` moved from BSD to its own license, which requires
  a paid license for for-profit use. That conflicts with the open-core plans, and likely with GPL-3.0
  (no added restrictions).

## Decision

Use **`universal_ble`** (BSD-3-Clause, Navideck). It supports iOS, Android, macOS, Windows, Linux and Web,
it's actively maintained, and it includes permission helpers (`hasPermissions` / `requestPermissions`).

## Consequences

- BLE is used only in `app/lib/features/connection/ble_transport.dart` and `ble_scanner.dart`, behind
  `ObdTransport`. Swapping the library later touches only those two files.
- Characteristic discovery tries a table of known ELM327 layouts first (`FFF0/FFF1/FFF2`,
  `FFE0/FFE1`, `18F0/2AF0/2AF1`, Vgate iCar Pro). Then it falls back to the first service that has
  one notify and one write characteristic. Record new adapters in `docs/adapters.md`.
- Alternatives considered: `flutter_reactive_ble` (BSD, slower maintenance) and pinning the last BSD
  `flutter_blue_plus` (no fixes).
