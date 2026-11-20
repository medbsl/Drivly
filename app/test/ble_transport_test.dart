import 'dart:convert';
import 'dart:typed_data';

import 'package:drivly/features/connection/ble_transport.dart';
import 'package:drivly/features/connection/connection_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obd_core/obd_core.dart';
import 'package:universal_ble/universal_ble.dart';

BleCharacteristic _c(String uuid, List<CharacteristicProperty> props) => BleCharacteristic(uuid, props, const []);

const _id = 'AA:BB:CC:DD:EE:FF';

final _clone = [
  BleService('1800', [_c('2a00', [CharacteristicProperty.read])]),
  BleService('fff0', [
    _c('fff1', [CharacteristicProperty.notify]),
    _c('fff2', [CharacteristicProperty.write, CharacteristicProperty.writeWithoutResponse]),
  ]),
];

/// The phone's Bluetooth, played by the test: one OBD adapter in range.
class _FakeBle extends UniversalBlePlatform {
  _FakeBle({this.failConnect = false});
  final bool failConnect;
  final written = <String>[];

  @override
  Future<void> connect(String deviceId,
      {Duration? connectionTimeout, bool autoConnect = false, ConnectionPlatformConfig? platformConfig}) async {
    if (failConnect) throw Exception('peer not found');
    updateConnection(deviceId, true);
  }

  @override
  Future<void> disconnect(String deviceId) async => updateConnection(deviceId, false);

  @override
  Future<List<BleService>> discoverServices(String deviceId, bool withDescriptors,
          {DiscoverServicesPlatformConfig? platformConfig}) async =>
      _clone;

  @override
  Future<void> setNotifiable(String deviceId, String service, String characteristic, BleInputProperty p) async {}

  @override
  Future<void> writeValue(String deviceId, String service, String characteristic, Uint8List value, BleOutputProperty p) async =>
      written.add(ascii.decode(value));

  @override
  Future<BleConnectionState> getConnectionState(String deviceId) async => BleConnectionState.connected;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeBle ble;
  late List<String> trace;
  late BleTransport transport;

  void setUpBle({bool failConnect = false}) {
    ble = _FakeBle(failConnect: failConnect);
    UniversalBle.setInstance(ble);
    trace = [];
    transport = BleTransport(deviceId: _id, deviceName: 'OBDII', trace: trace.add);
  }

  test('describeServices lists each service with its characteristics', () {
    expect(describeServices(_clone), '1800: 2a00 (read); fff0: fff1 (notify), fff2 (write, writeWithoutResponse)');
  });

  test('a connection is traced step by step', () async {
    setUpBle();
    await transport.connect(timeout: const Duration(seconds: 2));
    expect(transport.currentStatus, TransportStatus.connected);
    expect(trace, [
      'connecting OBDII $_id',
      'connected',
      'services: ${describeServices(_clone)}',
      'using fff0 notify fff1 write fff2 (without response)',
      'notifications on',
    ]);
  });

  test('a failed connection says why', () async {
    setUpBle(failConnect: true);
    await expectLater(transport.connect(timeout: const Duration(seconds: 2)), throwsA(isA<TransportException>()));
    expect(trace.last, startsWith('connect failed: '));
    expect(trace.last, contains('peer not found'));
  });

  test('bytes flow both ways', () async {
    setUpBle();
    await transport.connect(timeout: const Duration(seconds: 2));
    final got = <int>[];
    final sub = transport.incoming.listen(got.addAll);
    addTearDown(sub.cancel);
    await transport.write(ascii.encode('ATZ\r'));
    expect(ble.written, ['ATZ\r']);
    ble.updateCharacteristicValue(_id, 'fff1', Uint8List.fromList(ascii.encode('ELM327 v1.5\r\r>')), null);
    await Future<void>.delayed(Duration.zero);
    expect(ascii.decode(got), 'ELM327 v1.5\r\r>');
  });

  test('a lost link is traced', () async {
    setUpBle();
    await transport.connect(timeout: const Duration(seconds: 2));
    ble.updateConnection(_id, false);
    await Future<void>.delayed(Duration.zero);
    expect(transport.currentStatus, TransportStatus.disconnected);
    expect(trace.last, 'link lost');
  });

  test('disconnecting is traced', () async {
    setUpBle();
    await transport.connect(timeout: const Duration(seconds: 2));
    await transport.disconnect();
    expect(trace.last, 'disconnected');
  });

  test('the app sends Bluetooth steps to the adapter log', () async {
    setUpBle();
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final t = c.read(transportFactoryProvider)(const AdapterRef(id: _id, name: 'OBDII'));
    await t.connect(timeout: const Duration(seconds: 2));
    addTearDown(t.disconnect);
    final lines = c.read(adapterLogProvider).entries.map((e) => e.text);
    expect(lines, containsAll(['ble: connecting OBDII $_id', 'ble: connected', 'ble: notifications on']));
  });
}
