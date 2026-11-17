# ADR-0002: Drivly only reads from the car

- **Status:** Accepted (2026-11-17)
- **Context:** v1 had a "Clear codes" action (OBD mode `04`), guarded by a speed check and a confirmation
  sheet. It was the only command that changed the car. Clearing codes turns the engine light off, deletes
  stored codes and freeze-frame data, and resets the emissions readiness monitors, so the car can fail an
  emissions test (TÜV/AU, MOT, contrôle technique) until the monitors finish again. The owner's rule:
  the app may read, never change anything in the car.

## Decision

Drivly is **read-only toward the car**, enforced in code rather than only by convention:

1. **No write API.** `DiagnosticAdapter` has no method that changes the car. `clearDtcs()`, the clear
   flow, its UI and its strings were removed.
2. **Allowlist at the single choke point.** Every command goes through `ElmSession.send`, which calls
   `isReadOnlyCommand` (`packages/obd_core/lib/src/elm327/read_only_guard.dart`). Allowed:
   - OBD-II read modes (SAE J1979) to the broadcast address: `01`, `02`, `03`, `06`, `07`, `09`, `0A`.
   - A fixed list of AT commands that set up the adapter's temporary settings or read from it
     (`ATZ ATWS ATD ATE0 ATL0 ATS0 ATH1 ATAT1 ATSP0 ATDPN ATRV`).

   Anything else is logged as `blocked (read-only)`, never sent, and throws `ReadOnlyViolation`.
   Refused examples: `04` (clear codes), `08` (control), every UDS service (`10 11 14 27 2E 2F 31 34…`),
   `ATPP` (adapter permanent memory), `ATSH`/`ATCRA` (address one ECU directly).
3. **Tests enforce it.** `packages/obd_core/test/read_only_test.dart` checks the allowlist, checks that a
   refused command never reaches the transport, and runs a full session against the simulator to assert
   every command sent was a read.

## Consequences

- Users who want to clear codes after a repair use a mechanic or another tool.
- Old scan history can still contain `beforeClear`/`afterClear` reasons. The enum values are kept so it
  still loads.
- A new feature that needs a write is out of scope. Adding a command means adding it to the allowlist,
  which must only ever contain reads.
