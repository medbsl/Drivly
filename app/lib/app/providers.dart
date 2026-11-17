import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/settings.dart';

/// DI root. The database is opened in main() and injected via override.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override in main'));

final historyRepoProvider = Provider((ref) => HistoryRepository(ref.watch(databaseProvider)));
final vehicleRepoProvider = Provider((ref) => VehicleRepository(ref.watch(databaseProvider)));
final dtcRepoProvider = Provider((ref) => DtcRepository(ref.watch(databaseProvider)));
final tripRepoProvider = Provider((ref) => TripRepository(ref.watch(databaseProvider)));

/// Bumped whenever something is written that lists or charts should re-read
/// (a trip saved, a session ended, codes scanned, history deleted).
final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

class DataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// The car the History / Car / Codes tabs show: the last one connected.
final currentVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  ref.watch(dataVersionProvider);
  final id = ref.watch(settingsProvider.select((s) => s.lastVehicleId));
  final repo = ref.watch(vehicleRepoProvider);
  if (id != null) {
    final v = await repo.byId(id);
    if (v != null) return v;
  }
  final all = await repo.all();
  return all.isEmpty ? null : all.first;
});

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(vehicleRepoProvider).all();
});

final storageStatsProvider = FutureProvider<StorageStats>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(historyRepoProvider).stats();
});

extension AsyncValueOrNull<T> on AsyncValue<T> {
  T? get valueOrNull => hasValue ? value : null;
}
