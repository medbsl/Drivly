# Debug Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Settings switch that records adapter traffic (raw replies included), Bluetooth steps, connection steps and app errors to a file on the phone, and a button that shares it.

**Architecture:** `obd_core`'s `AdapterLog` gains a `verbose` flag that makes `ElmSession` log raw replies. The app gets a `DebugLog` (buffered, rotating file store, VIN-masked) and a recorder provider that, while the setting is on, copies adapter-log entries and connection phases into it. `BleTransport` reports its steps to the adapter log. `main()` routes errors to `DebugLog`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3.5, path_provider, share_plus, universal_ble 3.3 (its `setInstance` lets tests install a fake platform).

**Spec:** `docs/superpowers/specs/2026-11-20-debug-logging-design.md`

## Global Constraints

- Read-only toward the car: logging only observes; no new command reaches `ElmSession.send`.
- Off by default; when off, behaviour and the Adapter log screen are unchanged.
- File cap about 2 MB: two halves of 1 MB (`debug.log`, `debug.1.log`), newest kept.
- Flush about every 1 s; errors flush at once. Write failures are swallowed.
- VINs masked with the existing rule: `\b[A-HJ-NPR-Z0-9]{17}\b` → first 3 chars + `••••••••••••••`.
- No `dart:io` import in files the web build compiles, except behind a conditional import.
- Tests first; `flutter test`, `dart test` (obd_core, via `/opt/homebrew/share/flutter/bin/dart`) and both analyzers green before each commit. Commit as Mohamed Bousselmi on `main`, no co-author trailer, push.

## Review Focus

- App killed right after a failure → the lines written up to ~1 s earlier are in the file (Task 2: "survives a new instance").
- Debug logging turned off then on again → old content kept, a new header appended, no duplicate copying of entries (Task 4: "toggle twice").
- A reply that never ends with `>` (adapter hangs mid-reply) → the partial bytes appear in the log (Task 1: "partial reply on timeout").
- Huge sessions (hours of polling) → file never exceeds ~2 MB and keeps the newest lines (Task 2: "rotation").
- Bluetooth connect failure → the failure reason is in the log (Task 3: "connect failure traced").

---

### Task 1: Raw replies in the adapter log (obd_core)

**Files:**
- Modify: `packages/obd_core/lib/src/adapter/adapter_log.dart` (add `bool verbose = false;`)
- Modify: `packages/obd_core/lib/src/elm327/sanitizer.dart` (add `showControlChars`)
- Modify: `packages/obd_core/lib/src/elm327/elm_session.dart` (`_execute`)
- Modify: `packages/obd_core/lib/obd_core.dart` (export if needed)
- Test: `packages/obd_core/test/adapter_log_test.dart`

**Interfaces:**
- Produces: `AdapterLog.verbose` (mutable bool); `String showControlChars(String s)` — `\r`→`\r`, `\n`→`\n` (as two visible chars), other bytes < 0x20 → `\xNN`.
- Info entries `raw: <showControlChars(raw)>` after each reply, and `partial: <showControlChars(pending)>` on a timeout when the framer holds bytes, both only when `verbose`.

- [ ] **Step 1: Write the failing tests** — `verbose off: no raw entries` (FakeTransport replying `SEARCHING...\r41 00 BE 3E B8 11`; no entry starts with `raw:`); `verbose on: raw reply logged` (an info entry equals `raw: SEARCHING...\r41 00 BE 3E B8 11\r`-style visible text, i.e. contains `SEARCHING...\\r41 00`); `partial reply on timeout` (transport sends `41 00 BE` without `>`; with verbose an entry `partial: 41 00 BE`); `showControlChars` unit cases.
- [ ] **Step 2: Run** `cd packages/obd_core && /opt/homebrew/share/flutter/bin/dart test test/adapter_log_test.dart` — FAIL (no `verbose`).
- [ ] **Step 3: Implement** as in Interfaces; read `_framer.pending` before `_flushAfterTimeout` resets it.
- [ ] **Step 4: Run** the obd_core suite — all pass.
- [ ] **Step 5: Commit** "Log raw adapter replies when the adapter log is verbose".

### Task 2: DebugLog with a rotating file store (app)

**Files:**
- Create: `app/lib/core/debug_log.dart` — `DebugLog`, `DebugLogStore`, `MemoryDebugLogStore`, `maskVins`
- Create: `app/lib/core/debug_log_io.dart` — `FileDebugLogStore`, `openDebugLogStore()`, `platformDescription()`, `shareDebugLog(DebugLog)`
- Create: `app/lib/core/debug_log_stub.dart` — web versions of the same three functions (memory store, `'web'`, share as text)
- Create: `app/lib/core/debug_log_platform.dart` — `export 'debug_log_stub.dart' if (dart.library.io) 'debug_log_io.dart';`
- Test: `app/test/debug_log_test.dart`

**Interfaces:**
- `abstract class DebugLogStore { Future<void> append(String text); Future<String> readAll(); Future<int> size(); }`
- `class MemoryDebugLogStore implements DebugLogStore`
- `class FileDebugLogStore implements DebugLogStore { FileDebugLogStore(Directory dir, {int halfBytes = 1024 * 1024}); }` — before an append that would push `debug.log` past `halfBytes`, rename it to `debug.1.log` (replacing it); `readAll` = `debug.1.log` + `debug.log`.
- `class DebugLog { DebugLog(DebugLogStore store, {Duration flushEvery = const Duration(seconds: 1), DateTime Function()? clock}); static Future<DebugLog> open(DebugLogStore store); bool enabled; bool get hasContent; void add(String source, String message, {DateTime? at}); Future<void> error(String source, String message); Future<void> flush(); Future<String> export(); Future<void> dispose(); }`
- Line format: `HH:mm:ss.SSS [source] message` with VINs masked; a header line block starts with the full date. `add`/`error` do nothing while `enabled` is false.
- `Future<DebugLogStore> openDebugLogStore()` (io: `getApplicationSupportDirectory()/debug`), `String platformDescription()`, `Future<void> shareDebugLog(DebugLog log)` (io: writes `drivly-debug-<yyyyMMdd-HHmm>.txt` to the temp dir and shares it as an `XFile`).

- [ ] **Step 1: Write the failing tests** — `disabled: nothing written`; `buffered lines reach the store after flush`; `timed flush within flushEvery` (flushEvery 20 ms, wait 100 ms); `error flushes at once`; `VINs masked` (`WVWZZZ1KZ5W123456` → `WVW••••••••••••••`); `survives a new instance` (FileDebugLogStore in a temp dir, new `DebugLog.open` sees `hasContent` and old lines); `rotation` (halfBytes 1000, write 5000 bytes: `size() <= 2000`, last line present, first line gone); `store write failure swallowed` (store throwing in `append`: `flush` completes).
- [ ] **Step 2: Run** `cd app && flutter test test/debug_log_test.dart` — FAIL.
- [ ] **Step 3: Implement** the files above.
- [ ] **Step 4: Run** the test — PASS; `flutter analyze` clean.
- [ ] **Step 5: Commit** "Add a rotating debug log file".

### Task 3: Bluetooth steps in the adapter log

**Files:**
- Modify: `app/lib/features/connection/ble_transport.dart`
- Modify: `app/lib/features/connection/connection_controller.dart` (`transportFactoryProvider` passes `trace`)
- Test: `app/test/ble_transport_test.dart` (fake `UniversalBlePlatform` installed with `UniversalBle.setInstance`)

**Interfaces:**
- `BleTransport({required String deviceId, required String deviceName, void Function(String message)? trace})`
- `String describeServices(List<BleService> services)` — one line per service: `fff0: fff1 (notify), fff2 (write, writeWithoutResponse)`.
- Trace messages: `connecting <name> <id>`, `connected`, `services: <describeServices>`, `using <service> notify <n> write <w> (<without|with> response)`, `notifications on`, `link lost`, `disconnected`, `connect failed: <error>`, `write failed: <error>`.
- Factory: `trace: (m) => ref.read(adapterLogProvider).add(LogDirection.info, 'ble: $m')`.

- [ ] **Step 1: Write the failing tests** — `describeServices` formatting; `connect traced` (fake platform with an fff0 service: trace has `connecting`, `services:`, `using fff0 notify fff1 write fff2 (without response)`, `notifications on`); `connect failure traced` (fake `connect` throws: `TransportException`, trace has `connect failed:`); `bytes flow both ways` (write `ATZ\r` reaches the fake; fake's `updateCharacteristicValue` arrives on `incoming`); `link lost traced`.
- [ ] **Step 2: Run** `flutter test test/ble_transport_test.dart` — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the app suite — PASS.
- [ ] **Step 5: Commit** "Trace Bluetooth steps in the adapter log".

### Task 4: Setting, recorder and error capture

**Files:**
- Modify: `app/lib/data/settings.dart` (`debugLogging`, `setDebugLogging`, key `debugLogging`)
- Create: `app/lib/features/debug/debug_recorder.dart` — `debugLogProvider`, `debugRecorderProvider`
- Modify: `app/lib/app/app.dart` (`ref.listen(debugRecorderProvider, (_, _) {})` in build)
- Modify: `app/lib/main.dart` (open `DebugLog` inside the zone after `ensureInitialized`, override `debugLogProvider`, send `FlutterError.onError` and zone errors to `debugLog.error('error', …)` with the stack)
- Test: `app/test/settings_test.dart`, `app/test/debug_recorder_test.dart`

**Interfaces:**
- `final debugLogProvider = Provider<DebugLog>((ref) => DebugLog(MemoryDebugLogStore()));`
- `final debugRecorderProvider = Provider<void>(...)` — watches `settingsProvider.select((s) => s.debugLogging)`. On: `log.enabled = true`, header via `add('app', 'debug logging on · <platformDescription()> · <release|profile|debug> · adapter <savedAdapterName ?? none>')`, `adapterLog.verbose = true`, copy each `AdapterLog.stream` entry as `add('obd', '<>>|<<|--> <text>', at: entry.at)`, copy connection phase changes as `add('conn', '<phase.name>[ · <detail>]')`. `onDispose`: cancel, `verbose = false`, flush, `enabled = false`.

- [ ] **Step 1: Write the failing tests** — settings: default off, persists across relaunch. Recorder: `off: nothing recorded` (connect simulator, export empty); `on: a failed connection is fully recorded` (ignition off: export contains `debug logging on`, `>> ATZ`, `>> 0100`, `raw:`, `UNABLE TO CONNECT`, `conn] carNotResponding · UNABLE TO CONNECT`); `toggle twice` (on, off, on: two headers, each `>> ATZ` once per connection); `verbose follows the setting`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the app suite and analyze — PASS.
- [ ] **Step 5: Commit** "Record connection details to the debug log while it is on".

### Task 5: Settings UI

**Files:**
- Modify: `app/lib/features/settings/settings_screen.dart` (Adapter section, after "Adapter log")
- Modify: `app/lib/l10n/app_en.arb` — `debugLogging`: "Debug logging", `debugLoggingHint`: "Saves connection details to a file for bug reports", `shareDebugLogs`: "Share debug logs"
- Test: `app/test/settings_screen_test.dart`

**Interfaces:**
- Consumes `debugLogProvider`, `settingsProvider.setDebugLogging`, `shareDebugLog`.
- "Share debug logs" row shows when `debugLogging` is on or `DebugLog.hasContent`.

- [ ] **Step 1: Write the failing test** — `debug switch turns logging on and shows Share` (pump SettingsScreen; no "Share debug logs"; tap "Debug logging"; setting true; "Share debug logs" visible).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** (`flutter gen-l10n` after the ARB change).
- [ ] **Step 4: Run** both suites and both analyzers — PASS.
- [ ] **Step 5: Commit and push** "Add the debug logging switch and share button".
