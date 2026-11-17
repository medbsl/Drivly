import '../elm327/elm_error.dart';

/// Outcome of every adapter call. Protocol and data problems never throw.
sealed class ObdResult<T> {
  const ObdResult();

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        _ => null,
      };

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends ObdResult<T> {
  const Ok(this.value);
  final T value;

  @override
  String toString() => 'Ok($value)';
}

/// The ECU didn't answer this request ("NO DATA").
final class NoData<T> extends ObdResult<T> {
  const NoData();

  @override
  String toString() => 'NoData';
}

/// Not in the supported-PID bitmask, or the adapter replied "?".
final class NotSupported<T> extends ObdResult<T> {
  const NotSupported();

  @override
  String toString() => 'NotSupported';
}

/// UNABLE TO CONNECT, BUS INIT ERROR, CAN ERROR: ignition off or no protocol.
final class CarNotResponding<T> extends ObdResult<T> {
  const CarNotResponding();

  @override
  String toString() => 'CarNotResponding';
}

final class AdapterError<T> extends ObdResult<T> {
  const AdapterError(this.kind, this.raw);
  final ElmError kind;
  final String raw;

  @override
  String toString() => 'AdapterError(${kind.name})';
}

final class TimedOut<T> extends ObdResult<T> {
  const TimedOut();

  @override
  String toString() => 'TimedOut';
}

/// Why initialisation failed: tells the UI to check the adapter or the car.
enum InitFailure { adapterNotResponding, carNotResponding }

final class InitFailed<T> extends ObdResult<T> {
  const InitFailed(this.reason, [this.detail = '']);
  final InitFailure reason;
  final String detail;

  @override
  String toString() => 'InitFailed(${reason.name})';
}

final class Malformed<T> extends ObdResult<T> {
  const Malformed(this.raw);
  final String raw;

  @override
  String toString() => 'Malformed($raw)';
}
