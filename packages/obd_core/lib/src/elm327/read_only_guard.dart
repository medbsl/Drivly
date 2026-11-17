/// Drivly only ever reads from the car. [ElmSession] checks every command with
/// [isReadOnlyCommand] before it reaches the adapter and refuses anything else,
/// so no code path can change the car (docs/adr/0002-read-only.md).
///
/// Allowed:
/// * OBD-II read modes (SAE J1979), sent to the broadcast address: 01 live
///   data, 02 freeze frame, 03 stored codes, 06 test results, 07 pending codes,
///   09 vehicle info, 0A permanent codes.
/// * A fixed list of ELM327 AT commands that set up the adapter's temporary
///   settings or read from it.
///
/// Refused, for example: 04 (clear codes), 08 (control on-board systems), every
/// UDS service (10, 11, 14, 27, 2E, 2F, 31, 34…), ATPP (adapter permanent
/// memory) and ATSH/ATCRA (address one ECU directly).
library;

/// AT commands Drivly sends. Add one only if it cannot write to the car or to
/// the adapter's permanent memory.
const readOnlyAtCommands = {
  'ATZ', // reset adapter
  'ATWS', // warm start
  'ATD', // defaults
  'ATE0', // echo off
  'ATL0', // linefeeds off
  'ATS0', // spaces off
  'ATH1', // headers on
  'ATAT1', // adaptive timing
  'ATSP0', // automatic protocol search
  'ATDPN', // which protocol was found
  'ATRV', // battery voltage
};

final _readModes = [
  RegExp(r'^01(?:[0-9A-F]{2}){1,6}$'), // live data, up to 6 PIDs
  RegExp(r'^02(?:[0-9A-F]{2}){1,6}$'), // freeze frame
  RegExp(r'^(?:03|07|0A)$'), // stored, pending, permanent codes
  RegExp(r'^06(?:[0-9A-F]{2}){1,6}$'), // on-board test results
  RegExp(r'^09[0-9A-F]{2}$'), // vehicle info (VIN, calibration IDs)
];

/// Whether [command] only reads. Case and spaces are ignored, like the ELM327
/// does.
bool isReadOnlyCommand(String command) {
  final c = command.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (c.startsWith('AT')) return readOnlyAtCommands.contains(c);
  return _readModes.any((r) => r.hasMatch(c));
}

/// Thrown when code tries to send a command that isn't a read. It is a bug:
/// nothing in Drivly may write to the car.
class ReadOnlyViolation extends Error {
  ReadOnlyViolation(this.command);

  final String command;

  @override
  String toString() => 'ReadOnlyViolation: "$command" is not a read command. Drivly never writes to the car.';
}
