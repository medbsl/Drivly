import 'dart:async';
import 'dart:typed_data';

import 'package:obd_core/obd_core.dart';
import 'package:universal_ble/universal_ble.dart';

/// Known ELM327 BLE layouts: (service, notify characteristic, write characteristic).
/// Verify new adapters and record them in docs/adapters.md.
const _knownLayouts = [
  ('fff0', 'fff1', 'fff2'), // most clones
  ('ffe0', 'ffe1', 'ffe1'), // HM-10 style, one char for both
  ('18f0', '2af0', '2af1'), // some v2.x clones
  ('e7810a71-73ae-499d-8c15-faa9aef0c3f2', 'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f', 'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f'), // Vgate iCar Pro BLE
];

/// Services the browser must be told about up front (Web Bluetooth only
/// exposes services listed when the device is picked).
final knownObdServices = [for (final (svc, _, _) in _knownLayouts) BleUuidParser.string(svc)];

const _ignoredServices = {'1800', '1801', '180a', '180f'};

String _norm(String uuid) => BleUuidParser.string(uuid).toLowerCase();

/// The serial channel of an ELM327 BLE adapter (UUIDs normalised).
typedef SerialLayout = ({String service, String notify, String write, bool withoutResponse});

/// Finds the adapter's serial channel: a known layout first, otherwise the
/// first non-standard service with a notify/indicate and a write
/// characteristic. Null when there is none.
SerialLayout? pickSerialLayout(List<BleService> services) {
  SerialLayout use(BleService s, BleCharacteristic n, BleCharacteristic w) => (
        service: _norm(s.uuid),
        notify: _norm(n.uuid),
        write: _norm(w.uuid),
        // Write-without-response is faster; ELM commands fit in 20 bytes.
        withoutResponse: w.properties.contains(CharacteristicProperty.writeWithoutResponse),
      );

  final byUuid = {for (final s in services) _norm(s.uuid): s};
  for (final (svc, n, w) in _knownLayouts) {
    final s = byUuid[_norm(svc)];
    if (s == null) continue;
    final chars = {for (final c in s.characteristics) _norm(c.uuid): c};
    final nc = chars[_norm(n)];
    final wc = chars[_norm(w)];
    if (nc != null && wc != null) return use(s, nc, wc);
  }
  for (final s in services) {
    if (_ignoredServices.any((x) => _norm(s.uuid) == _norm(x))) continue;
    final n = s.characteristics.where((c) =>
        c.properties.contains(CharacteristicProperty.notify) || c.properties.contains(CharacteristicProperty.indicate));
    final w = s.characteristics.where((c) =>
        c.properties.contains(CharacteristicProperty.write) ||
        c.properties.contains(CharacteristicProperty.writeWithoutResponse));
    if (n.isNotEmpty && w.isNotEmpty) return use(s, n.first, w.first);
  }
  return null;
}

/// [ObdTransport] over Bluetooth LE (iOS + Android).
class BleTransport implements ObdTransport {
  BleTransport({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  final _incoming = StreamController<List<int>>.broadcast();
  final _status = StreamController<TransportStatus>.broadcast();
  TransportStatus _current = TransportStatus.disconnected;
  StreamSubscription<Uint8List>? _valueSub;
  StreamSubscription<bool>? _connSub;
  String? _service;
  String? _notifyChar;
  String? _writeChar;
  bool _withoutResponse = false;

  @override
  TransportKind get kind => TransportKind.ble;

  @override
  String get name => deviceName;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Stream<TransportStatus> get status => _status.stream;

  @override
  TransportStatus get currentStatus => _current;

  void _set(TransportStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) async {
    _set(TransportStatus.connecting);
    try {
      await UniversalBle.connect(deviceId, timeout: timeout);
      final services = await UniversalBle.discoverServices(deviceId);
      final layout = pickSerialLayout(services);
      if (layout == null) throw const TransportException('no serial characteristic found');
      _service = layout.service;
      _notifyChar = layout.notify;
      _writeChar = layout.write;
      _withoutResponse = layout.withoutResponse;
      _valueSub = UniversalBle.characteristicValueStream(deviceId, _notifyChar!).listen(_incoming.add);
      final notify = services
          .firstWhere((s) => _norm(s.uuid) == _service)
          .characteristics
          .firstWhere((c) => _norm(c.uuid) == _notifyChar);
      if (notify.properties.contains(CharacteristicProperty.notify)) {
        await UniversalBle.subscribeNotifications(deviceId, _service!, _notifyChar!);
      } else {
        await UniversalBle.subscribeIndications(deviceId, _service!, _notifyChar!);
      }
      _connSub = UniversalBle.connectionStream(deviceId).listen((connected) {
        if (!connected && _current == TransportStatus.connected) _set(TransportStatus.disconnected);
      });
      _set(TransportStatus.connected);
    } on TransportException {
      _set(TransportStatus.failed);
      await _safeDisconnect();
      rethrow;
    } catch (e) {
      _set(TransportStatus.failed);
      await _safeDisconnect();
      throw TransportException(e.toString());
    }
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (_current != TransportStatus.connected) throw const TransportException('not connected');
    await UniversalBle.write(
      deviceId,
      _service!,
      _writeChar!,
      Uint8List.fromList(bytes),
      withoutResponse: _withoutResponse,
    );
  }

  Future<void> _safeDisconnect() async {
    await _valueSub?.cancel();
    await _connSub?.cancel();
    _valueSub = null;
    _connSub = null;
    try {
      await UniversalBle.disconnect(deviceId, timeout: const Duration(seconds: 3));
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {
    await _safeDisconnect();
    _set(TransportStatus.disconnected);
  }
}
