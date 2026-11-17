import 'sanitizer.dart';

/// Error replies an ELM327 (or clone) can produce.
enum ElmError {
  noData,
  unableToConnect,
  busInitError,
  canError,
  bufferFull,
  unknownCommand,
  stopped,
  busBusy,
  feedbackError,
  dataError,
  rxError,
  adapterReset,
}

extension ElmErrorX on ElmError {
  /// The car itself is not talking (ignition off, no protocol found).
  bool get meansCarSilent =>
      this == ElmError.unableToConnect || this == ElmError.busInitError || this == ElmError.canError;

  /// Worth exactly one retry.
  bool get isTransient =>
      this == ElmError.stopped ||
      this == ElmError.busBusy ||
      this == ElmError.feedbackError ||
      this == ElmError.dataError ||
      this == ElmError.rxError ||
      this == ElmError.bufferFull;
}

/// Classifies sanitized reply lines. Returns `null` when the reply carries
/// usable data. For AT commands pass [isAtCommand] so "ELM327 v1.5" (the
/// normal ATZ answer) is not mistaken for a mid-session reset.
ElmError? classifyReply(List<String> lines, {bool isAtCommand = false}) {
  if (lines.isEmpty) return isAtCommand ? null : ElmError.noData;
  if (!isAtCommand && lines.any(isHexDataLine)) return null;
  final joined = lines.join(' ');
  if (joined.contains('NO DATA')) return ElmError.noData;
  if (joined.contains('UNABLE TO CONNECT')) return ElmError.unableToConnect;
  if (joined.contains('BUS INIT') && joined.contains('ERROR')) return ElmError.busInitError;
  if (joined.contains('CAN ERROR')) return ElmError.canError;
  if (joined.contains('BUFFER FULL')) return ElmError.bufferFull;
  if (joined.contains('STOPPED')) return ElmError.stopped;
  if (joined.contains('BUS BUSY')) return ElmError.busBusy;
  if (joined.contains('FB ERROR')) return ElmError.feedbackError;
  if (joined.contains('DATA ERROR')) return ElmError.dataError;
  if (joined.contains('RX ERROR')) return ElmError.rxError;
  if (lines.length == 1 && lines.first == '?') return ElmError.unknownCommand;
  if (!isAtCommand && (joined.contains('LV RESET') || joined.contains('ELM327'))) {
    return ElmError.adapterReset;
  }
  if (!isAtCommand) return ElmError.dataError; // text we don't understand
  return null;
}
