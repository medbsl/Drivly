import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../data/settings.dart';
import '../connection/connection_controller.dart';
import '../fault_codes/dtc_controller.dart';
import '../trips/trip_recorder.dart';
import 'demo_seeder.dart';
import 'history_recorder.dart';
import 'live_data.dart';

/// Everything that happens while connected: identify the car, poll every
/// supported value, show it live, save it all, detect trips, check codes.
class LiveSession {
  LiveSession({
    required this.ref,
    required this.adapter,
    required this.info,
    required this.device,
    required this.onLost,
  });

  final Ref ref;
  final DiagnosticAdapter adapter;
  final AdapterInfo info;
  final AdapterRef device;
  final VoidCallback onLost;

  late final String sessionId;
  late final Vehicle vehicle;
  LivePoller? _poller;
  HistoryRecorder? _recorder;
  late final TripRecorder trips = TripRecorder(onFinished: _saveTrip);
  StreamSubscription<SensorReading>? _readSub;
  StreamSubscription<PollerEvent>? _eventSub;
  Timer? _ticker;
  bool _stopped = false;
  bool _started = false;

  LiveData get _live => ref.read(liveDataProvider);

  /// Every sensor the car supports, plus battery and engine light.
  List<Sensor> get sensors =>
      Sensors.all.where((s) => s.isPid ? info.supportedPids.contains(s.pid) : true).toList();

  Future<void> start() async {
    final vin = (await adapter.readVin()).valueOrNull;
    if (_stopped) return;
    vehicle = await ref.read(vehicleRepoProvider).upsertFromConnection(
          vin: vin,
          fallbackKey: device.demo ? 'demo' : 'adapter:${device.id}',
          info: info,
          demo: device.demo,
        );
    ref.read(settingsProvider.notifier).setLastVehicle(vehicle.id);
    if (device.demo) {
      final previous = await ref.read(historyRepoProvider).sessions(vehicleId: vehicle.id, limit: 1);
      if (previous.isEmpty) {
        unawaited(DemoSeeder(history: ref.read(historyRepoProvider), trips: ref.read(tripRepoProvider))
            .seed(vehicleId: vehicle.id, supportedPids: info.supportedPids)
            .then((_) => ref.read(dataVersionProvider.notifier).bump()));
      }
    }
    sessionId = await ref.read(historyRepoProvider).startSession(
          vehicleId: vehicle.id,
          adapterName: device.name,
          demo: device.demo,
        );
    if (_stopped) return;
    _started = true;

    _live.begin(sensors.where((s) => s != Sensors.dtcCount));
    final recorder = HistoryRecorder(ref.read(historyRepoProvider), sessionId)..start();
    _recorder = recorder;
    final poller = LivePoller(adapter, sensors);
    _poller = poller;
    _readSub = poller.readings.listen(_onReading);
    _eventSub = poller.events.listen((e) {
      if (e == PollerEvent.lost) onLost();
    });
    poller.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _live.requestsPerSecond = poller.requestsPerSecond;
      final dropped = poller.scheduler.dropped;
      if (dropped.length != _live.unsupported.length) _live.markUnsupported(dropped);
    });
    ref.read(dataVersionProvider.notifier).bump();

    // Codes are checked automatically so the health summary means something.
    unawaited(ref.read(dtcControllerProvider.notifier).scan(ScanReason.auto));
  }

  void _onReading(SensorReading r) {
    _live.add(r);
    _recorder?.add(r);
    if (ref.read(settingsProvider).autoRecordTrips) trips.feed(r);
  }

  void _saveTrip(TripSnapshot t) {
    final trip = Trip(
      id: newId(),
      vehicleId: vehicle.id,
      sessionId: sessionId,
      startedAt: t.startedAt,
      endedAt: t.endedAt,
      distanceKm: t.distanceKm,
      maxSpeed: t.maxSpeed,
      avgSpeed: t.avgSpeed,
      maxCoolant: t.maxCoolant,
      idleSeconds: t.idleSeconds,
      fuelUsedL: t.fuelUsedL,
      hasGap: t.hasGap,
    );
    unawaited(ref.read(tripRepoProvider).insert(trip).then((_) => ref.read(dataVersionProvider.notifier).bump()));
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _ticker?.cancel();
    await _poller?.stop();
    await _readSub?.cancel();
    await _eventSub?.cancel();
    trips.finish();
    await _recorder?.stop();
    if (_started) {
      await ref.read(historyRepoProvider).endSession(sessionId, _recorder?.saved ?? 0);
      ref.read(dataVersionProvider.notifier).bump();
    }
    await _poller?.dispose();
  }

  int get savedReadings => (_recorder?.saved ?? 0);

  String? get sessionIdOrNull => _started ? sessionId : null;
  Vehicle? get vehicleOrNull => _started ? vehicle : null;
}
