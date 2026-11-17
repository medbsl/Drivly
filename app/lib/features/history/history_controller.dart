import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obd_core/obd_core.dart';

import '../../app/providers.dart';

export '../../app/providers.dart' show AsyncValueOrNull;
import '../../data/models.dart';
import '../../data/settings.dart';

enum HistoryRange {
  live(Duration(minutes: 15)),
  hour(Duration(hours: 1)),
  day(Duration(hours: 24)),
  week(Duration(days: 7)),
  month(Duration(days: 30)),
  all(Duration(days: 3650));

  const HistoryRange(this.span);
  final Duration span;
}

@immutable
class HistorySelection {
  const HistorySelection({required this.range, required this.sensor, required this.anchor});
  final HistoryRange range;
  final Sensor sensor;

  /// End of the window, frozen so provider keys stay stable between rebuilds.
  final DateTime anchor;

  HistorySelection copyWith({HistoryRange? range, Sensor? sensor, DateTime? anchor}) =>
      HistorySelection(range: range ?? this.range, sensor: sensor ?? this.sensor, anchor: anchor ?? this.anchor);
}

final historySelectionProvider = NotifierProvider<HistorySelectionController, HistorySelection>(HistorySelectionController.new);

class HistorySelectionController extends Notifier<HistorySelection> {
  @override
  HistorySelection build() =>
      HistorySelection(range: HistoryRange.day, sensor: Sensors.speed, anchor: _now());

  static DateTime _now() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second).add(const Duration(seconds: 1));
  }

  void setRange(HistoryRange r) => state = state.copyWith(range: r, anchor: _now());
  void select(Sensor s) => state = state.copyWith(sensor: s);
  void refresh() => state = state.copyWith(anchor: _now());
}

typedef Window = ({DateTime from, DateTime to, String? vehicleId});

final firstReadingProvider = FutureProvider<DateTime?>((ref) {
  ref.watch(dataVersionProvider);
  final vehicleId = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
  return ref.watch(historyRepoProvider).firstReadingAt(vehicleId: vehicleId);
});

/// The time window for the current selection.
final historyWindowProvider = Provider<Window>((ref) {
  final sel = ref.watch(historySelectionProvider);
  final vehicleId = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
  var from = sel.anchor.subtract(sel.range.span);
  if (sel.range == HistoryRange.all) {
    final first = ref.watch(firstReadingProvider).valueOrNull;
    from = first ?? sel.anchor.subtract(const Duration(days: 30));
  }
  return (from: from, to: sel.anchor, vehicleId: vehicleId);
});

final summariesProvider = FutureProvider.family<List<SensorSummary>, Window>((ref, w) {
  ref.watch(dataVersionProvider);
  return ref.watch(historyRepoProvider).summaries(from: w.from, to: w.to, vehicleId: w.vehicleId);
});

typedef SeriesKey = ({int sensorId, DateTime from, DateTime to, int buckets, String? vehicleId});

final seriesProvider = FutureProvider.family<List<SeriesPoint>, SeriesKey>((ref, k) {
  ref.watch(dataVersionProvider);
  return ref.watch(historyRepoProvider).series(
        Sensors.byId[k.sensorId]!,
        from: k.from,
        to: k.to,
        buckets: k.buckets,
        vehicleId: k.vehicleId,
      );
});

final tripsInWindowProvider = FutureProvider.family<List<Trip>, Window>((ref, w) {
  ref.watch(dataVersionProvider);
  return ref.watch(tripRepoProvider).list(vehicleId: w.vehicleId, from: w.from);
});

final recentTripsProvider = FutureProvider<List<Trip>>((ref) {
  ref.watch(dataVersionProvider);
  final vehicleId = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
  return ref.watch(tripRepoProvider).list(vehicleId: vehicleId, limit: 20);
});
