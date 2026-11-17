/// Pure-Dart OBD2 / ELM327 core for Drivly.
///
/// Two extension seams: [ObdTransport] (bytes in, bytes out) and
/// [DiagnosticAdapter] (semantic reads). Nothing here imports Flutter.
library;

export 'src/adapter/adapter_log.dart';
export 'src/adapter/diagnostic_adapter.dart';
export 'src/adapter/obd_result.dart';
export 'src/dtc/dtc.dart';
export 'src/elm327/elm327_adapter.dart';
export 'src/elm327/elm_error.dart';
export 'src/elm327/elm_session.dart';
export 'src/elm327/read_only_guard.dart';
export 'src/elm327/response_framer.dart';
export 'src/elm327/sanitizer.dart';
export 'src/pids/sensor.dart';
export 'src/pids/sensors.dart';
export 'src/pids/supported_pids.dart';
export 'src/polling/live_poller.dart';
export 'src/polling/poll_scheduler.dart';
export 'src/protocol/frame_parser.dart';
export 'src/protocol/obd_protocol.dart';
export 'src/simulator/elm327_simulator.dart';
export 'src/simulator/simulated_car.dart';
export 'src/transport/fake_transport.dart';
export 'src/transport/obd_transport.dart';
export 'src/vin/vin.dart';
export 'src/vin/wmi_table.dart';
