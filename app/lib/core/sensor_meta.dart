import 'package:flutter/material.dart';
import 'package:obd_core/obd_core.dart';

import '../l10n/app_localizations.dart';

/// Plain-language label + one-sentence explanation for each sensor.
/// "Plain words first, technical second" (DESIGN.md §1).
class SensorText {
  const SensorText(this.label, this.info);
  final String label;
  final String info;
}

SensorText sensorText(AppLocalizations l, Sensor s) => switch (s.key) {
      'speed' => SensorText(l.sensorSpeed, l.sensorSpeedInfo),
      'rpm' => SensorText(l.sensorRpm, l.sensorRpmInfo),
      'coolant' => SensorText(l.sensorCoolant, l.sensorCoolantInfo),
      'battery' => SensorText(l.sensorBattery, l.sensorBatteryInfo),
      'load' => SensorText(l.sensorLoad, l.sensorLoadInfo),
      'throttle' => SensorText(l.sensorThrottle, l.sensorThrottleInfo),
      'intakeTemp' => SensorText(l.sensorIntakeTemp, l.sensorIntakeTempInfo),
      'fuelLevel' => SensorText(l.sensorFuelLevel, l.sensorFuelLevelInfo),
      'fuelRate' => SensorText(l.sensorFuelRate, l.sensorFuelRateInfo),
      'maf' => SensorText(l.sensorMaf, l.sensorMafInfo),
      'map' => SensorText(l.sensorMap, l.sensorMapInfo),
      'timing' => SensorText(l.sensorTiming, l.sensorTimingInfo),
      'oilTemp' => SensorText(l.sensorOilTemp, l.sensorOilTempInfo),
      'ambientTemp' => SensorText(l.sensorAmbientTemp, l.sensorAmbientTempInfo),
      'moduleVoltage' => SensorText(l.sensorModuleVoltage, l.sensorModuleVoltageInfo),
      'absoluteLoad' => SensorText(l.sensorAbsoluteLoad, l.sensorAbsoluteLoadInfo),
      'relativeThrottle' => SensorText(l.sensorRelativeThrottle, l.sensorRelativeThrottleInfo),
      'pedal' => SensorText(l.sensorPedal, l.sensorPedalInfo),
      'relativePedal' => SensorText(l.sensorRelativePedal, l.sensorPedalInfo),
      'commandedThrottle' => SensorText(l.sensorCommandedThrottle, l.sensorCommandedThrottleInfo),
      'demandTorque' => SensorText(l.sensorDemandTorque, l.sensorDemandTorqueInfo),
      'actualTorque' => SensorText(l.sensorActualTorque, l.sensorActualTorqueInfo),
      'referenceTorque' => SensorText(l.sensorReferenceTorque, l.sensorReferenceTorqueInfo),
      'stft1' => SensorText(l.sensorStft(1), l.sensorStftInfo),
      'ltft1' => SensorText(l.sensorLtft(1), l.sensorLtftInfo),
      'stft2' => SensorText(l.sensorStft(2), l.sensorStftInfo),
      'ltft2' => SensorText(l.sensorLtft(2), l.sensorLtftInfo),
      'fuelPressure' => SensorText(l.sensorFuelPressure, l.sensorFuelPressureInfo),
      'railPressure' => SensorText(l.sensorRailPressure, l.sensorRailPressureInfo),
      'railGaugePressure' => SensorText(l.sensorRailPressure, l.sensorRailPressureInfo),
      'injectionTiming' => SensorText(l.sensorInjectionTiming, l.sensorInjectionTimingInfo),
      'ethanol' => SensorText(l.sensorEthanol, l.sensorEthanolInfo),
      'lambda' => SensorText(l.sensorLambda, l.sensorLambdaInfo),
      'baro' => SensorText(l.sensorBaro, l.sensorBaroInfo),
      'o2b1s1' => SensorText(l.sensorO2Front, l.sensorO2FrontInfo),
      'o2b1s2' => SensorText(l.sensorO2Rear, l.sensorO2RearInfo),
      'catTemp' => SensorText(l.sensorCatTemp, l.sensorCatTempInfo),
      'egr' => SensorText(l.sensorEgr, l.sensorEgrInfo),
      'evapPurge' => SensorText(l.sensorEvapPurge, l.sensorEvapPurgeInfo),
      'hybridBattery' => SensorText(l.sensorHybridBattery, l.sensorHybridBatteryInfo),
      'runTime' => SensorText(l.sensorRunTime, l.sensorRunTimeInfo),
      'distanceWithMil' => SensorText(l.sensorDistanceWithMil, l.sensorDistanceWithMilInfo),
      'distanceSinceClear' => SensorText(l.sensorDistanceSinceClear, l.sensorDistanceSinceClearInfo),
      'warmupsSinceClear' => SensorText(l.sensorWarmups, l.sensorWarmupsInfo),
      'timeWithMil' => SensorText(l.sensorTimeWithMil, l.sensorDistanceWithMilInfo),
      'timeSinceClear' => SensorText(l.sensorTimeSinceClear, l.sensorDistanceSinceClearInfo),
      'odometer' => SensorText(l.sensorOdometer, l.sensorOdometerInfo),
      'mil' => SensorText(l.sensorMil, l.sensorMilInfo),
      'dtcCount' => SensorText(l.sensorDtcCount, l.sensorDtcCountInfo),
      _ => SensorText(s.name, s.name),
    };

IconData sensorIcon(Sensor s) => switch (s.key) {
      'speed' => Icons.speed_rounded,
      'rpm' => Icons.av_timer_rounded,
      'battery' || 'moduleVoltage' => Icons.battery_charging_full_rounded,
      'hybridBattery' => Icons.battery_std_rounded,
      'fuelLevel' || 'fuelRate' || 'ethanol' => Icons.local_gas_station_rounded,
      'throttle' || 'relativeThrottle' || 'commandedThrottle' => Icons.tune_rounded,
      'pedal' || 'relativePedal' => Icons.trending_up_rounded,
      'mil' => Icons.warning_amber_rounded,
      'dtcCount' => Icons.report_gmailerrorred_rounded,
      'odometer' || 'distanceSinceClear' || 'distanceWithMil' => Icons.route_rounded,
      'runTime' || 'timeSinceClear' || 'timeWithMil' => Icons.timer_outlined,
      _ => switch (s.group) {
          SensorGroup.motion => Icons.speed_rounded,
          SensorGroup.engine => Icons.settings_rounded,
          SensorGroup.temperature => Icons.thermostat_rounded,
          SensorGroup.fuel => Icons.local_gas_station_rounded,
          SensorGroup.air => Icons.air_rounded,
          SensorGroup.electrical => Icons.bolt_rounded,
          SensorGroup.emissions => Icons.cloud_outlined,
          SensorGroup.distance => Icons.route_rounded,
        },
    };

String groupLabel(AppLocalizations l, SensorGroup g) => switch (g) {
      SensorGroup.motion => l.groupMotion,
      SensorGroup.engine => l.groupEngine,
      SensorGroup.temperature => l.groupTemperature,
      SensorGroup.fuel => l.groupFuel,
      SensorGroup.air => l.groupAir,
      SensorGroup.electrical => l.groupElectrical,
      SensorGroup.emissions => l.groupEmissions,
      SensorGroup.distance => l.groupDistance,
    };

/// Sensors that make sense as a chart (counters and flags are not).
bool isChartable(Sensor s) => s.unit != SensorUnit.flag && s != Sensors.referenceTorque;

/// Percent-like values get a mini bar on the tile.
bool isPercentLike(Sensor s) => s.unit == SensorUnit.percent && s.min >= 0 && s.max <= 100;

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
