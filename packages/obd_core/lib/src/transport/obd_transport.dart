import 'dart:async';

/// How the bytes travel between the phone and the adapter.
enum TransportKind { ble, classic, wifi, simulated }

/// Link-level state of a transport.
enum TransportStatus { disconnected, connecting, connected, failed }

/// Bytes in, bytes out. Anything that speaks the ELM327 command set plugs in
/// here (BLE, classic Bluetooth, Wi-Fi, the demo simulator).
abstract interface class ObdTransport {
  TransportKind get kind;

  /// Human-readable device name, e.g. "OBDII".
  String get name;

  Stream<TransportStatus> get status;
  TransportStatus get currentStatus;

  /// Raw bytes, any chunking. A reply may be split across many events.
  Stream<List<int>> get incoming;

  /// Throws [TransportException] when the link cannot be opened.
  Future<void> connect({Duration timeout = const Duration(seconds: 10)});

  Future<void> write(List<int> bytes);

  Future<void> disconnect();
}

class TransportException implements Exception {
  const TransportException(this.message);
  final String message;

  @override
  String toString() => 'TransportException: $message';
}
