// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabHistory => 'History';

  @override
  String get tabCodes => 'Codes';

  @override
  String get tabCar => 'Car';

  @override
  String get settings => 'Settings';

  @override
  String get connect => 'Connect';

  @override
  String get connectAdapter => 'Connect adapter';

  @override
  String get tryDemo => 'Try demo';

  @override
  String get tryAgain => 'Try again';

  @override
  String get chooseAnother => 'Choose another adapter';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get getStarted => 'Get started';

  @override
  String get stop => 'Stop';

  @override
  String get none => 'None';

  @override
  String get live => 'Live';

  @override
  String get now => 'Now';

  @override
  String get stateOn => 'On';

  @override
  String get stateOff => 'Off';

  @override
  String get allow => 'Allow';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get turnOn => 'Turn on';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get notConnected => 'Not connected';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String get pillConnected => 'Connected';

  @override
  String get pillConnecting => 'Connecting…';

  @override
  String get pillReconnecting => 'Reconnecting…';

  @override
  String get pillNotConnected => 'Not connected';

  @override
  String get pillDemo => 'DEMO';

  @override
  String get bannerReconnecting => 'Connection lost: reconnecting…';

  @override
  String get bannerReconnected => 'Reconnected';

  @override
  String get passengerStrip => 'Passenger view: don\'t use while driving';

  @override
  String get homeNotConnectedTitle => 'Not connected';

  @override
  String get homeNotConnectedBody =>
      'Plug in your adapter, turn the ignition on and tap Connect.';

  @override
  String get homeNoAdapterTitle => 'Connect your adapter to see live data';

  @override
  String get homeNoAdapterBody =>
      'Every value your car shares appears here in real time, and is saved on this phone so you can look back at it later.';

  @override
  String get healthChecking => 'Not checked yet';

  @override
  String get healthCheckingBody => 'Checking your car…';

  @override
  String get healthGood => 'All good';

  @override
  String get healthNoProblems => 'No problems';

  @override
  String healthBattery(String value) {
    return 'Battery $value';
  }

  @override
  String get healthCheckSoon => 'Check soon';

  @override
  String get healthNeedsAttention => 'Needs attention';

  @override
  String healthProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems to check',
      one: '1 problem to check',
    );
    return '$_temp0';
  }

  @override
  String get healthEngineHot => 'Engine is hot';

  @override
  String get healthEngineTooHot => 'Engine is too hot';

  @override
  String get healthBatteryLow => 'Battery charging low';

  @override
  String get healthBatteryVeryLow => 'Battery very low';

  @override
  String get healthMilOn => 'Engine light is on';

  @override
  String get tripRecording => 'Recording trip';

  @override
  String liveFooter(String rate, String count) {
    return '$rate updates/s · $count readings this session';
  }

  @override
  String unsupportedFootnote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count values not supported by your car',
      one: '1 value not supported by your car',
    );
    return '$_temp0';
  }

  @override
  String get unsupportedTitle => 'Not supported by your car';

  @override
  String get unsupportedBody =>
      'Your car said it has these values, but never answered when asked. That\'s normal, especially on older cars. They\'re hidden for this session.';

  @override
  String get statusWarmingUp => 'Warming up';

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusHot => 'Hot';

  @override
  String get statusTooHot => 'Too hot';

  @override
  String get statusCharging => 'Charging';

  @override
  String get statusLowCharging => 'Low charging';

  @override
  String get statusTooHigh => 'Too high';

  @override
  String get statusGood => 'Good';

  @override
  String get statusLow => 'Low';

  @override
  String get statusVeryLow => 'Very low';

  @override
  String lastUpdated(String age) {
    return 'Last updated $age ago';
  }

  @override
  String get statMin => 'Min';

  @override
  String get statAvg => 'Avg';

  @override
  String get statMax => 'Max';

  @override
  String get whatItMeans => 'What it means';

  @override
  String get openHistory => 'Open full history';

  @override
  String get coolantGuidance =>
      'General guidance: 70–109 °C is normal once warm. 110–115 °C is hot. Above 115 °C, stop safely and let the engine cool.';

  @override
  String get batteryGuidance =>
      'General guidance: 13.2–14.8 V while the engine runs means it\'s charging. With the engine off, 12.4 V or more is a healthy battery.';

  @override
  String get rangeLive => 'Live';

  @override
  String get range1h => '1H';

  @override
  String get range24h => '24H';

  @override
  String get range7d => '7D';

  @override
  String get range30d => '30D';

  @override
  String get rangeAll => 'All';

  @override
  String get allValues => 'All values';

  @override
  String get noDataInRange => 'No data in this time range';

  @override
  String readingsCount(String count) {
    return '$count readings';
  }

  @override
  String get liveEmptyTitle => 'Nothing live right now';

  @override
  String get liveEmptyBody =>
      'Connect to your car to watch every value move in real time.';

  @override
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptyBody =>
      'Connect to start recording. Every value is saved on this phone, so you can look back at any drive.';

  @override
  String get recentTrips => 'Recent trips';

  @override
  String avgSpeed(String speed) {
    return 'avg $speed';
  }

  @override
  String storageFooter(String count, String size) {
    return '$count readings · $size · stored only on this phone';
  }

  @override
  String get demoCar => 'Demo car';

  @override
  String get yourCar => 'Your car';

  @override
  String likelyYear(int year) {
    return '$year (likely)';
  }

  @override
  String get tripDuration => 'Duration';

  @override
  String get tripDistance => 'Distance';

  @override
  String get tripAvgSpeed => 'Avg speed';

  @override
  String get tripMaxSpeed => 'Max speed';

  @override
  String get tripMaxTemp => 'Max engine temp';

  @override
  String get tripIdle => 'Idle time';

  @override
  String get tripFuel => 'Fuel used';

  @override
  String get tripConsumption => 'Consumption';

  @override
  String get tripDistanceNote =>
      'Distance is calculated from your car\'s speed and may differ slightly from your odometer.';

  @override
  String get tripGapNote => 'Part of this trip had no data and isn\'t counted.';

  @override
  String get deleteTrip => 'Delete trip';

  @override
  String get deleteTripConfirm =>
      'Delete this trip? Its readings stay in your history.';

  @override
  String get askingYourCar => 'Asking your car…';

  @override
  String get codesNeverTitle => 'Connect to check your car for problems';

  @override
  String get codesNeverBody =>
      'Drivly reads fault codes automatically every time you connect, and keeps every scan.';

  @override
  String get scanNow => 'Check now';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get noProblemsTitle => 'No problems found';

  @override
  String noProblemsBody(String time) {
    return 'Your car didn\'t report any fault codes. Checked $time.';
  }

  @override
  String get milNoCodes =>
      'Your engine light is on, but your car didn\'t share a code. Some problems are only visible with a manufacturer tool.';

  @override
  String confirmedProblems(int count) {
    return 'Confirmed problems ($count)';
  }

  @override
  String developingProblems(int count) {
    return 'Developing problems ($count)';
  }

  @override
  String get pendingExplainTitle => 'What\'s a developing problem?';

  @override
  String get pendingExplainBody =>
      'Your car noticed something once but hasn\'t confirmed it yet. If it happens again on the next drives, it becomes a confirmed problem and may turn the engine light on.';

  @override
  String get scanHistory => 'Scan history';

  @override
  String get scanHistoryEmpty => 'No scans yet';

  @override
  String get milOn => 'Engine light is ON';

  @override
  String problemsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems found',
      one: '1 problem found',
    );
    return '$_temp0';
  }

  @override
  String problemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems',
      one: '1 problem',
      zero: 'No codes',
    );
    return '$_temp0';
  }

  @override
  String checkedAt(String time) {
    return 'Checked $time';
  }

  @override
  String get readFailedNotConnected => 'Couldn\'t read codes: not connected.';

  @override
  String get readFailedCar =>
      'Couldn\'t read codes: your car isn\'t answering.';

  @override
  String get readFailedBusy =>
      'Couldn\'t read codes: the adapter is busy. Try again.';

  @override
  String get readFailed => 'Couldn\'t read codes. Try again.';

  @override
  String get severityHigh => 'High';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityMinor => 'Minor';

  @override
  String get actionHigh => 'Get it checked today';

  @override
  String get actionMedium => 'Check soon';

  @override
  String get actionMinor => 'Not urgent';

  @override
  String get whatYouMightNotice => 'What you might notice';

  @override
  String get safeToDrive => 'Is it safe to drive?';

  @override
  String get commonCauses => 'Common causes';

  @override
  String get whatToDo => 'What to do';

  @override
  String get forYourMechanic => 'For your mechanic';

  @override
  String get kindStored => 'Confirmed (mode 03)';

  @override
  String get kindPending => 'Pending (mode 07)';

  @override
  String get manufacturerSpecific => 'Manufacturer-specific';

  @override
  String get searchOnline => 'Search online';

  @override
  String get pendingBadge => 'Developing problem: not confirmed yet';

  @override
  String get noCodes => 'No codes';

  @override
  String get reasonAuto => 'Automatic check';

  @override
  String get reasonManual => 'Manual scan';

  @override
  String get reasonBeforeClear => 'Before clearing';

  @override
  String get reasonAfterClear => 'After clearing';

  @override
  String get carEmptyTitle => 'No car yet';

  @override
  String get carEmptyBody =>
      'Connect once and Drivly reads your car\'s VIN, make and likely year, all offline.';

  @override
  String get adapterSection => 'Adapter';

  @override
  String carSupports(int count) {
    return 'Data your car shares ($count)';
  }

  @override
  String get editCar => 'Edit';

  @override
  String get nickname => 'Nickname';

  @override
  String get model => 'Model';

  @override
  String get modelYear => 'Model year';

  @override
  String get vinNotShared =>
      'Your car doesn\'t share its VIN over OBD. You\'ll find it on your registration document or at the bottom of the windshield.';

  @override
  String get enterVin => 'Enter VIN';

  @override
  String get enterVinHint => '17 characters, no I, O or Q.';

  @override
  String get vinInvalid => 'That doesn\'t look like a VIN.';

  @override
  String get madeIn => 'Made in';

  @override
  String get connectionType => 'Connection';

  @override
  String get protocolCan => 'CAN (modern)';

  @override
  String get protocolLegacy => 'K-Line (older)';

  @override
  String get valuesAvailable => 'Values available';

  @override
  String get lastSeen => 'Last connected';

  @override
  String get batteryAtPort => 'Battery at port';

  @override
  String get protocol => 'Protocol';

  @override
  String get fastMode => 'Fast mode (multi-value requests)';

  @override
  String get updatesPerSecond => 'Requests per second';

  @override
  String get changeAdapter => 'Change adapter';

  @override
  String get groupMotion => 'Motion';

  @override
  String get groupEngine => 'Engine';

  @override
  String get groupTemperature => 'Temperatures';

  @override
  String get groupFuel => 'Fuel';

  @override
  String get groupAir => 'Air intake';

  @override
  String get groupElectrical => 'Electrical';

  @override
  String get groupEmissions => 'Emissions';

  @override
  String get groupDistance => 'Distance & time';

  @override
  String get general => 'General';

  @override
  String get unitsSpeed => 'Speed';

  @override
  String get unitsTemp => 'Temperature';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get keepScreenOn => 'Keep screen on';

  @override
  String get keepScreenOnHint => 'While connected';

  @override
  String get savedAdapter => 'Saved adapter';

  @override
  String get forget => 'Forget';

  @override
  String get connectAutomatically => 'Connect automatically';

  @override
  String get adapterLog => 'Adapter log';

  @override
  String get adapterLogHint => 'Raw adapter messages, for bug reports';

  @override
  String get logEmpty => 'Nothing logged yet.';

  @override
  String get historyAndTrips => 'History & trips';

  @override
  String get recordTrips => 'Record trips automatically';

  @override
  String get storedHistory => 'Stored history';

  @override
  String storageDetail(
    String readings,
    String trips,
    String size,
    String since,
  ) {
    return '$readings readings · $trips trips · $size · since $since';
  }

  @override
  String get deleteOlder => 'Delete history older than 90 days';

  @override
  String get deleteOlderConfirm =>
      'Delete all readings older than 90 days? This can\'t be undone.';

  @override
  String get deleteAllHistory => 'Delete all history';

  @override
  String get deleteAllConfirm =>
      'Delete every reading, trip and scan? This can\'t be undone.';

  @override
  String get demo => 'Demo';

  @override
  String get startDemo => 'Start demo mode';

  @override
  String get demoRunning => 'Demo mode is running';

  @override
  String get demoHint => 'Simulated data, no car needed';

  @override
  String get simulateDrop => 'Simulate connection loss';

  @override
  String get simulateIgnitionOff => 'Simulate ignition off (6 s)';

  @override
  String get safetyPrivacy => 'Safety & privacy';

  @override
  String get safetyNotice => 'Safety notice';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Everything stays on this phone. No account, no tracking.';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get sourceCode => 'Source code';

  @override
  String get licenses => 'Open-source licenses';

  @override
  String get showOnboarding => 'Show onboarding again';

  @override
  String get safetyTitle => 'Eyes on the road';

  @override
  String get safetyBody =>
      'Drivly is for passengers and parked use. Don\'t look at your phone while driving.';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get likelyAdapters => 'Likely OBD adapters';

  @override
  String otherDevices(int count) {
    return 'Other Bluetooth devices ($count)';
  }

  @override
  String get lastUsed => 'Last used';

  @override
  String get lookingForAdapters => 'Looking for adapters…';

  @override
  String get scanFinished => 'Scan finished';

  @override
  String get noAdapterFound => 'No adapter found';

  @override
  String get troubleshootShort =>
      'Check the adapter\'s light is on, the ignition is on, and that it\'s a Bluetooth LE adapter.';

  @override
  String get cantFindAdapter => 'Can\'t find your adapter?';

  @override
  String get trouble1 =>
      'Is the adapter\'s light on? If not, it isn\'t getting power. Check that it\'s pushed in fully.';

  @override
  String get trouble2 => 'Is the ignition on?';

  @override
  String get trouble3 =>
      'Is it a Bluetooth LE adapter? Classic-Bluetooth adapters don\'t work with iPhone, or with Drivly yet.';

  @override
  String get trouble4 =>
      'Is it connected to another phone or app? Close the other app or turn off Bluetooth on that phone.';

  @override
  String get trouble5 =>
      'Unplug the adapter for 10 seconds and plug it back in.';

  @override
  String get btOffTitle => 'Bluetooth is off';

  @override
  String get btOffBody => 'Turn on Bluetooth to connect to your adapter.';

  @override
  String get permTitle => 'Drivly needs Bluetooth access';

  @override
  String get permBody =>
      'It\'s only used to talk to your adapter. Nothing leaves your phone.';

  @override
  String connectingTo(String name) {
    return 'Connecting to $name';
  }

  @override
  String get stageAdapter => 'Connecting to adapter';

  @override
  String get stageTalkAdapter => 'Talking to adapter';

  @override
  String get stageTalkCar => 'Talking to your car';

  @override
  String get mayTake15s => 'This can take up to 15 s';

  @override
  String errTransportTitle(String name) {
    return 'Couldn\'t connect to $name';
  }

  @override
  String get errTransportBody => 'It may be connected to another phone or app.';

  @override
  String get errAdapterTitle => 'The adapter isn\'t answering';

  @override
  String get errAdapterBody => 'Unplug it, wait 10 seconds, plug it back in.';

  @override
  String get errCarTitle => 'Your car isn\'t answering';

  @override
  String get errCarBody =>
      'Turn the ignition on, or start the engine, and try again.';

  @override
  String get errGenericTitle => 'Something went wrong';

  @override
  String get errGenericBody =>
      'Try again. If it keeps happening, share the adapter log with us.';

  @override
  String get onbWelcomeTitle => 'Welcome to Drivly';

  @override
  String get onbWelcomeBody =>
      'Understand your car in plain words. Live data, fault codes and full history. Everything stays on your phone.';

  @override
  String get onbPlugTitle => 'Plug in your adapter';

  @override
  String get onbPlugBody =>
      'The port is usually under the dashboard, near your knees.';

  @override
  String get onbIgnitionTitle => 'Turn on the ignition';

  @override
  String get onbIgnitionBody =>
      'Turn the key or press Start without your foot on the brake. Some cars need the engine running.';

  @override
  String get onbConnectTitle => 'Connect';

  @override
  String get onbConnectBody =>
      'We\'ll look for your adapter. Your phone will ask for Bluetooth access: it\'s only used to talk to the adapter.';

  @override
  String get whereIsPort => 'Where is my port?';

  @override
  String get whereIsPortBody =>
      'Most cars: under the dashboard on the driver\'s side, near the steering column. Sometimes behind a small cover, near the fuse box, or under the center console.';

  @override
  String get whichAdapter => 'Which adapter do I need?';

  @override
  String get whichAdapterBody =>
      'An ELM327-compatible adapter with Bluetooth LE (often labeled \"Bluetooth 4.0\" or \"for iOS\"). Classic Bluetooth adapters don\'t work with iPhone, or with Drivly yet.';

  @override
  String get sensorSpeed => 'Speed';

  @override
  String get sensorSpeedInfo =>
      'How fast the car is going, as measured by the car itself.';

  @override
  String get sensorRpm => 'Engine speed';

  @override
  String get sensorRpmInfo =>
      'How many times per minute the engine turns. Around 800 at idle, higher when you accelerate.';

  @override
  String get sensorCoolant => 'Engine temperature';

  @override
  String get sensorCoolantInfo =>
      'The temperature of the engine\'s coolant. It rises to about 90 °C once the engine is warm.';

  @override
  String get sensorBattery => 'Battery';

  @override
  String get sensorBatteryInfo =>
      'Voltage at the OBD port. With the engine running, it shows whether the battery is being charged.';

  @override
  String get sensorLoad => 'Engine load';

  @override
  String get sensorLoadInfo =>
      'How hard the engine is working right now. High when accelerating or climbing, low when cruising.';

  @override
  String get sensorThrottle => 'Throttle';

  @override
  String get sensorThrottleInfo =>
      'How far the throttle is open, which controls how much air the engine gets.';

  @override
  String get sensorIntakeTemp => 'Intake air';

  @override
  String get sensorIntakeTempInfo =>
      'Temperature of the air going into the engine. Cooler air gives a little more power.';

  @override
  String get sensorFuelLevel => 'Fuel';

  @override
  String get sensorFuelLevelInfo => 'How full the tank is, as a percentage.';

  @override
  String get sensorFuelRate => 'Fuel use';

  @override
  String get sensorFuelRateInfo =>
      'How much fuel the engine is burning right now, in liters per hour.';

  @override
  String get sensorMaf => 'Air flow';

  @override
  String get sensorMafInfo =>
      'How much air flows into the engine each second. It goes up with engine speed and load.';

  @override
  String get sensorMap => 'Intake pressure';

  @override
  String get sensorMapInfo =>
      'Air pressure in the intake. Low at idle, close to outside pressure at full throttle (higher with a turbo).';

  @override
  String get sensorTiming => 'Ignition timing';

  @override
  String get sensorTimingInfo =>
      'How early the spark fires before the piston reaches the top. The engine adjusts it constantly.';

  @override
  String get sensorOilTemp => 'Oil temperature';

  @override
  String get sensorOilTempInfo =>
      'Temperature of the engine oil. It warms up more slowly than the coolant.';

  @override
  String get sensorAmbientTemp => 'Outside air';

  @override
  String get sensorAmbientTempInfo =>
      'Temperature outside the car, as measured by the car.';

  @override
  String get sensorModuleVoltage => 'Computer voltage';

  @override
  String get sensorModuleVoltageInfo =>
      'Voltage reaching the engine computer. Usually close to the battery voltage.';

  @override
  String get sensorAbsoluteLoad => 'Absolute load';

  @override
  String get sensorAbsoluteLoadInfo =>
      'Engine load relative to its best breathing. Can exceed 100% on turbo engines.';

  @override
  String get sensorRelativeThrottle => 'Relative throttle';

  @override
  String get sensorRelativeThrottleInfo =>
      'Throttle opening measured from its learned closed position.';

  @override
  String get sensorPedal => 'Accelerator pedal';

  @override
  String get sensorPedalInfo => 'How far the accelerator pedal is pressed.';

  @override
  String get sensorRelativePedal => 'Relative pedal';

  @override
  String get sensorCommandedThrottle => 'Throttle command';

  @override
  String get sensorCommandedThrottleInfo =>
      'How far the engine computer is asking the throttle to open.';

  @override
  String get sensorDemandTorque => 'Requested torque';

  @override
  String get sensorDemandTorqueInfo =>
      'The torque you\'re asking for with the pedal, as a percentage of the engine\'s maximum.';

  @override
  String get sensorActualTorque => 'Actual torque';

  @override
  String get sensorActualTorqueInfo =>
      'The torque the engine is delivering, as a percentage of its maximum.';

  @override
  String get sensorReferenceTorque => 'Reference torque';

  @override
  String get sensorReferenceTorqueInfo =>
      'The engine\'s reference (maximum) torque, used to scale the torque percentages.';

  @override
  String get sensorFuelPressure => 'Fuel pressure';

  @override
  String get sensorFuelPressureInfo => 'Pressure in the fuel system.';

  @override
  String get sensorRailPressure => 'Fuel rail pressure';

  @override
  String get sensorRailPressureInfo =>
      'Pressure in the fuel rail that feeds the injectors. Very high on direct-injection and diesel engines.';

  @override
  String get sensorInjectionTiming => 'Injection timing';

  @override
  String get sensorInjectionTimingInfo =>
      'When fuel is injected relative to the piston position.';

  @override
  String get sensorEthanol => 'Ethanol content';

  @override
  String get sensorEthanolInfo =>
      'How much ethanol is in the fuel (flex-fuel cars).';

  @override
  String get sensorLambda => 'Air-fuel target';

  @override
  String get sensorLambdaInfo =>
      'The air-fuel mixture the engine is aiming for. 1.00 is the ideal (stoichiometric) mix.';

  @override
  String get sensorBaro => 'Air pressure';

  @override
  String get sensorBaroInfo => 'Outside air pressure. Lower at altitude.';

  @override
  String get sensorO2Front => 'Oxygen sensor (front)';

  @override
  String get sensorO2FrontInfo =>
      'Measures oxygen in the exhaust before the catalytic converter. It swings quickly when the engine is warm, which is normal.';

  @override
  String get sensorO2Rear => 'Oxygen sensor (rear)';

  @override
  String get sensorO2RearInfo =>
      'Measures oxygen after the catalytic converter. A steady value means the converter is working.';

  @override
  String get sensorCatTemp => 'Catalyst temperature';

  @override
  String get sensorCatTempInfo =>
      'Temperature of the catalytic converter, which cleans the exhaust.';

  @override
  String get sensorEgr => 'Exhaust recirculation';

  @override
  String get sensorEgrInfo =>
      'How much exhaust gas is fed back into the engine to reduce emissions.';

  @override
  String get sensorEvapPurge => 'Fuel vapor purge';

  @override
  String get sensorEvapPurgeInfo =>
      'How much fuel vapor from the tank is being burned by the engine.';

  @override
  String get sensorHybridBattery => 'Hybrid battery';

  @override
  String get sensorHybridBatteryInfo =>
      'Remaining charge of the hybrid battery pack.';

  @override
  String get sensorRunTime => 'Engine run time';

  @override
  String get sensorRunTimeInfo =>
      'How long the engine has been running since it was started.';

  @override
  String get sensorDistanceWithMil => 'Distance with engine light';

  @override
  String get sensorDistanceWithMilInfo =>
      'How far the car has driven with the engine light on.';

  @override
  String get sensorDistanceSinceClear => 'Distance since codes cleared';

  @override
  String get sensorDistanceSinceClearInfo =>
      'How far the car has driven since fault codes were last cleared.';

  @override
  String get sensorWarmups => 'Warm-ups since codes cleared';

  @override
  String get sensorWarmupsInfo =>
      'How many times the engine has warmed up since codes were last cleared.';

  @override
  String get sensorTimeWithMil => 'Time with engine light';

  @override
  String get sensorTimeSinceClear => 'Time since codes cleared';

  @override
  String get sensorOdometer => 'Odometer';

  @override
  String get sensorOdometerInfo =>
      'Total distance the car has driven, reported by the car.';

  @override
  String get sensorMil => 'Engine light';

  @override
  String get sensorMilInfo => 'Whether the engine (check engine) light is on.';

  @override
  String get sensorDtcCount => 'Stored codes';

  @override
  String get sensorDtcCountInfo =>
      'How many confirmed fault codes the car has stored.';

  @override
  String sensorStft(int bank) {
    return 'Short-term fuel trim (bank $bank)';
  }

  @override
  String sensorLtft(int bank) {
    return 'Long-term fuel trim (bank $bank)';
  }

  @override
  String get sensorStftInfo =>
      'Quick fuel corrections the engine makes right now. Values near 0% are ideal; large swings are normal.';

  @override
  String get sensorLtftInfo =>
      'Fuel corrections the engine has learned over time. Beyond about ±10% can point to a leak or a sensor problem.';

  @override
  String get webChooseTitle => 'Pick your adapter';

  @override
  String get webChooseBody =>
      'Your browser shows nearby Bluetooth devices in its own window. Choose your OBD adapter (often called OBDII, Vlink or Vgate).';

  @override
  String get webChooseAdapter => 'Choose adapter';

  @override
  String get bleUnsupportedTitle => 'Bluetooth isn\'t available here';

  @override
  String get bleUnsupportedBody =>
      'This browser can\'t use Bluetooth. Open Drivly in Chrome or Edge on a computer with Bluetooth, or try demo mode.';
}
