import '../dtc/dtc.dart';
import '../pids/sensor.dart';
import '../protocol/obd_protocol.dart';
import 'adapter_log.dart';
import 'obd_result.dart';

/// Which part of the connection an init step belongs to. Lets the UI say
/// whether to check the adapter or the car.
enum InitStage { adapter, car, discovery }

class AdapterInfo {
  const AdapterInfo({
    required this.elmVersion,
    required this.protocol,
    required this.supportedPids,
    required this.multiPid,
    this.batteryVoltage,
  });

  final String elmVersion;
  final ObdProtocol? protocol;
  final Set<int> supportedPids;

  /// True when the car answers several PIDs in one request (CAN only).
  final bool multiPid;
  final double? batteryVoltage;

  bool get isCan => protocol?.isCan ?? false;
}

/// Semantic adapter API. ELM327 implements it; a custom adapter speaking its
/// own protocol (ESP32 with JSON, say) can implement it directly.
///
/// Read-only by design: there is no method that changes the car, and there
/// must never be one (docs/adr/0002-read-only.md).
abstract interface class DiagnosticAdapter {
  AdapterLog get log;
  AdapterInfo? get info;

  /// Runs the init sequence. Fails with [InitFailure] wrapped in
  /// [AdapterError]/[CarNotResponding]/[TimedOut].
  Future<ObdResult<AdapterInfo>> initialize({void Function(InitStage stage)? onStage});

  /// Reads several sensors, batching into multi-PID requests when possible.
  /// Sensors the car didn't return are simply absent from the result.
  Future<ObdResult<List<SensorReading>>> readSensors(List<Sensor> sensors);

  Future<ObdResult<MonitorStatus>> readMonitorStatus();
  Future<ObdResult<List<Dtc>>> readDtcs(DtcKind kind);
  Future<ObdResult<String>> readVin();
  Future<ObdResult<double>> readBatteryVoltage();

  /// Consecutive timeouts on the link, used to detect a lost connection.
  int get consecutiveTimeouts;

  Future<void> close();
}
