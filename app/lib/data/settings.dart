import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpeedUnit { kmh, mph }

enum TempUnit { celsius, fahrenheit }

@immutable
class AppSettings {
  const AppSettings({
    this.speedUnit = SpeedUnit.kmh,
    this.tempUnit = TempUnit.celsius,
    this.themeMode = ThemeMode.dark,
    this.keepScreenOn = true,
    this.autoConnect = true,
    this.autoRecordTrips = true,
    this.onboardingDone = false,
    this.safetyNoticeSeen = false,
    this.savedAdapterId,
    this.savedAdapterName,
    this.lastVehicleId,
    this.debugLogging = false,
  });

  final SpeedUnit speedUnit;
  final TempUnit tempUnit;
  final ThemeMode themeMode;
  final bool keepScreenOn;
  final bool autoConnect;
  final bool autoRecordTrips;
  final bool onboardingDone;
  final bool safetyNoticeSeen;
  final String? savedAdapterId;
  final String? savedAdapterName;
  final String? lastVehicleId;

  /// Records connection details to a file for bug reports (Settings › Adapter).
  final bool debugLogging;

  AppSettings copyWith({
    SpeedUnit? speedUnit,
    TempUnit? tempUnit,
    ThemeMode? themeMode,
    bool? keepScreenOn,
    bool? autoConnect,
    bool? autoRecordTrips,
    bool? onboardingDone,
    bool? safetyNoticeSeen,
    String? savedAdapterId,
    String? savedAdapterName,
    String? lastVehicleId,
    bool? debugLogging,
    bool clearAdapter = false,
  }) =>
      AppSettings(
        speedUnit: speedUnit ?? this.speedUnit,
        tempUnit: tempUnit ?? this.tempUnit,
        themeMode: themeMode ?? this.themeMode,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        autoConnect: autoConnect ?? this.autoConnect,
        autoRecordTrips: autoRecordTrips ?? this.autoRecordTrips,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        safetyNoticeSeen: safetyNoticeSeen ?? this.safetyNoticeSeen,
        savedAdapterId: clearAdapter ? null : savedAdapterId ?? this.savedAdapterId,
        savedAdapterName: clearAdapter ? null : savedAdapterName ?? this.savedAdapterName,
        lastVehicleId: lastVehicleId ?? this.lastVehicleId,
        debugLogging: debugLogging ?? this.debugLogging,
      );
}

/// Overridden in main() once SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  late SharedPreferences _p;

  @override
  AppSettings build() {
    _p = ref.watch(sharedPrefsProvider);
    return AppSettings(
      speedUnit: SpeedUnit.values[_p.getInt('speedUnit') ?? 0],
      tempUnit: TempUnit.values[_p.getInt('tempUnit') ?? 0],
      themeMode: ThemeMode.values[_p.getInt('themeMode') ?? ThemeMode.dark.index],
      keepScreenOn: _p.getBool('keepScreenOn') ?? true,
      autoConnect: _p.getBool('autoConnect') ?? true,
      autoRecordTrips: _p.getBool('autoRecordTrips') ?? true,
      onboardingDone: _p.getBool('onboardingDone') ?? false,
      safetyNoticeSeen: _p.getBool('safetyNoticeSeen') ?? false,
      savedAdapterId: _p.getString('savedAdapterId'),
      savedAdapterName: _p.getString('savedAdapterName'),
      lastVehicleId: _p.getString('lastVehicleId'),
      debugLogging: _p.getBool('debugLogging') ?? false,
    );
  }

  void setSpeedUnit(SpeedUnit v) {
    _p.setInt('speedUnit', v.index);
    state = state.copyWith(speedUnit: v);
  }

  void setTempUnit(TempUnit v) {
    _p.setInt('tempUnit', v.index);
    state = state.copyWith(tempUnit: v);
  }

  void setThemeMode(ThemeMode v) {
    _p.setInt('themeMode', v.index);
    state = state.copyWith(themeMode: v);
  }

  void setKeepScreenOn(bool v) {
    _p.setBool('keepScreenOn', v);
    state = state.copyWith(keepScreenOn: v);
  }

  void setAutoConnect(bool v) {
    _p.setBool('autoConnect', v);
    state = state.copyWith(autoConnect: v);
  }

  void setAutoRecordTrips(bool v) {
    _p.setBool('autoRecordTrips', v);
    state = state.copyWith(autoRecordTrips: v);
  }

  void setDebugLogging(bool v) {
    _p.setBool('debugLogging', v);
    state = state.copyWith(debugLogging: v);
  }

  void setOnboardingDone(bool v) {
    _p.setBool('onboardingDone', v);
    state = state.copyWith(onboardingDone: v);
  }

  void setSafetyNoticeSeen() {
    _p.setBool('safetyNoticeSeen', true);
    state = state.copyWith(safetyNoticeSeen: true);
  }

  void saveAdapter(String id, String name) {
    _p.setString('savedAdapterId', id);
    _p.setString('savedAdapterName', name);
    state = state.copyWith(savedAdapterId: id, savedAdapterName: name);
  }

  void forgetAdapter() {
    _p.remove('savedAdapterId');
    _p.remove('savedAdapterName');
    state = state.copyWith(clearAdapter: true);
  }

  void setLastVehicle(String id) {
    _p.setString('lastVehicleId', id);
    state = state.copyWith(lastVehicleId: id);
  }
}
