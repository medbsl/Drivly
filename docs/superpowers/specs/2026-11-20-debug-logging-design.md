# Debug logging — design

Status: approved by Mohamed, 2026-11-20. Size: small change.

## Why

Drivly can't connect to Mohamed's 2005 VW Golf 5 (probably K-line), while the
Mini OBDII app can. The adapter log that should explain why came up empty: it
lives in memory only, so it is lost whenever the app closes between the
failure and opening the log. It also hides the raw reply text ("SEARCHING…",
"BUS INIT…") and records no Bluetooth steps or app errors.

Goal: one switch that, while on, records everything about a connection
attempt to a file on the phone, and one button that shares that file.

## Goals

- A **Debug logging** switch in Settings › Adapter, off by default.
- While on, a log file on the phone records, with millisecond timestamps:
  - every command sent, and the adapter's **raw** reply as well as the parsed one;
  - Bluetooth steps: connect, services and characteristics found, the serial
    channel picked, subscription, disconnects, write failures;
  - connection steps (phase changes) and their failure detail;
  - app errors (Flutter errors and uncaught async errors);
  - a header each time logging starts: date, OS and version, build mode,
    saved adapter.
- The file survives the app closing or crashing (written within about a
  second, errors immediately).
- **Share debug logs** in Settings shares the file (AirDrop, Files, Mail…).
  The row shows only when there is something to share.
- The file is capped at about 2 MB (two rotating halves), newest kept.
- VINs in text are masked the same way the adapter log export masks them.

## Non-goals

- No upload anywhere, no crash-reporting SDK (privacy, as today).
- No live streaming to the Mac.
- No change to what Drivly sends to the car.

## Anti-goals

- Logging must never send, block or change a command to the car (read-only,
  ADR 0002). It only observes.
- Logging must never crash or slow the app: write failures are swallowed.

## Approaches

1. **File on the phone behind a switch** — chosen. Survives restarts and
   crashes, works in the car without the Mac.
2. In-memory only with a share button — rejected: loses the log when the app
   closes, which is the failure we hit.
3. Stream logs to the Mac via the debugger — rejected: needs the Mac in the car.

## Design

- `obd_core`: `AdapterLog` gets a `verbose` flag. When set, `ElmSession` also
  logs each raw reply (control characters made visible). Off: unchanged.
- `app`: `DebugLog` keeps the file (`debug.log` + `debug.1.log` in the app
  support folder), appends buffered lines, flushes about every second and at
  once for errors, rotates at 1 MB per half, exports both halves as one text
  file. On the web it keeps lines in memory only.
- A recorder, active while the setting is on, copies adapter-log entries and
  connection-phase changes into `DebugLog` and turns `verbose` on.
- `BleTransport` reports its steps to the adapter log (so they also appear in
  the normal Adapter log screen).
- `main()` creates `DebugLog` before `runApp` and routes Flutter errors and
  uncaught errors to it.
- Settings: `debugLogging` saved in SharedPreferences.

## Left to the builder

File naming of the shared copy, exact line format, flush interval.

Every part ships with unit tests (TDD); both suites and analyze stay green.
