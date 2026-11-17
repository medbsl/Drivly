import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabCodes.
  ///
  /// In en, this message translates to:
  /// **'Codes'**
  String get tabCodes;

  /// No description provided for @tabCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get tabCar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectAdapter.
  ///
  /// In en, this message translates to:
  /// **'Connect adapter'**
  String get connectAdapter;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try demo'**
  String get tryDemo;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another adapter'**
  String get chooseAnother;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @stateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get stateOn;

  /// No description provided for @stateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get stateOff;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutes(int n);

  /// No description provided for @pillConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get pillConnected;

  /// No description provided for @pillConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get pillConnecting;

  /// No description provided for @pillReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get pillReconnecting;

  /// No description provided for @pillNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get pillNotConnected;

  /// No description provided for @pillDemo.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get pillDemo;

  /// No description provided for @bannerReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connection lost: reconnecting…'**
  String get bannerReconnecting;

  /// No description provided for @bannerReconnected.
  ///
  /// In en, this message translates to:
  /// **'Reconnected'**
  String get bannerReconnected;

  /// No description provided for @passengerStrip.
  ///
  /// In en, this message translates to:
  /// **'Passenger view: don\'t use while driving'**
  String get passengerStrip;

  /// No description provided for @homeNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get homeNotConnectedTitle;

  /// No description provided for @homeNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Plug in your adapter, turn the ignition on and tap Connect.'**
  String get homeNotConnectedBody;

  /// No description provided for @homeNoAdapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your adapter to see live data'**
  String get homeNoAdapterTitle;

  /// No description provided for @homeNoAdapterBody.
  ///
  /// In en, this message translates to:
  /// **'Every value your car shares appears here in real time, and is saved on this phone so you can look back at it later.'**
  String get homeNoAdapterBody;

  /// No description provided for @healthChecking.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get healthChecking;

  /// No description provided for @healthCheckingBody.
  ///
  /// In en, this message translates to:
  /// **'Checking your car…'**
  String get healthCheckingBody;

  /// No description provided for @healthGood.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get healthGood;

  /// No description provided for @healthNoProblems.
  ///
  /// In en, this message translates to:
  /// **'No problems'**
  String get healthNoProblems;

  /// No description provided for @healthBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery {value}'**
  String healthBattery(String value);

  /// No description provided for @healthCheckSoon.
  ///
  /// In en, this message translates to:
  /// **'Check soon'**
  String get healthCheckSoon;

  /// No description provided for @healthNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get healthNeedsAttention;

  /// No description provided for @healthProblems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 problem to check} other{{count} problems to check}}'**
  String healthProblems(int count);

  /// No description provided for @healthEngineHot.
  ///
  /// In en, this message translates to:
  /// **'Engine is hot'**
  String get healthEngineHot;

  /// No description provided for @healthEngineTooHot.
  ///
  /// In en, this message translates to:
  /// **'Engine is too hot'**
  String get healthEngineTooHot;

  /// No description provided for @healthBatteryLow.
  ///
  /// In en, this message translates to:
  /// **'Battery charging low'**
  String get healthBatteryLow;

  /// No description provided for @healthBatteryVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Battery very low'**
  String get healthBatteryVeryLow;

  /// No description provided for @healthMilOn.
  ///
  /// In en, this message translates to:
  /// **'Engine light is on'**
  String get healthMilOn;

  /// No description provided for @tripRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording trip'**
  String get tripRecording;

  /// No description provided for @liveFooter.
  ///
  /// In en, this message translates to:
  /// **'{rate} updates/s · {count} readings this session'**
  String liveFooter(String rate, String count);

  /// No description provided for @unsupportedFootnote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 value not supported by your car} other{{count} values not supported by your car}}'**
  String unsupportedFootnote(int count);

  /// No description provided for @unsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not supported by your car'**
  String get unsupportedTitle;

  /// No description provided for @unsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Your car said it has these values, but never answered when asked. That\'s normal, especially on older cars. They\'re hidden for this session.'**
  String get unsupportedBody;

  /// No description provided for @statusWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming up'**
  String get statusWarmingUp;

  /// No description provided for @statusNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get statusNormal;

  /// No description provided for @statusHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get statusHot;

  /// No description provided for @statusTooHot.
  ///
  /// In en, this message translates to:
  /// **'Too hot'**
  String get statusTooHot;

  /// No description provided for @statusCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get statusCharging;

  /// No description provided for @statusLowCharging.
  ///
  /// In en, this message translates to:
  /// **'Low charging'**
  String get statusLowCharging;

  /// No description provided for @statusTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Too high'**
  String get statusTooHigh;

  /// No description provided for @statusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get statusGood;

  /// No description provided for @statusLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get statusLow;

  /// No description provided for @statusVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very low'**
  String get statusVeryLow;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {age} ago'**
  String lastUpdated(String age);

  /// No description provided for @statMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statMin;

  /// No description provided for @statAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get statAvg;

  /// No description provided for @statMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statMax;

  /// No description provided for @whatItMeans.
  ///
  /// In en, this message translates to:
  /// **'What it means'**
  String get whatItMeans;

  /// No description provided for @openHistory.
  ///
  /// In en, this message translates to:
  /// **'Open full history'**
  String get openHistory;

  /// No description provided for @coolantGuidance.
  ///
  /// In en, this message translates to:
  /// **'General guidance: 70–109 °C is normal once warm. 110–115 °C is hot. Above 115 °C, stop safely and let the engine cool.'**
  String get coolantGuidance;

  /// No description provided for @batteryGuidance.
  ///
  /// In en, this message translates to:
  /// **'General guidance: 13.2–14.8 V while the engine runs means it\'s charging. With the engine off, 12.4 V or more is a healthy battery.'**
  String get batteryGuidance;

  /// No description provided for @rangeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get rangeLive;

  /// No description provided for @range1h.
  ///
  /// In en, this message translates to:
  /// **'1H'**
  String get range1h;

  /// No description provided for @range24h.
  ///
  /// In en, this message translates to:
  /// **'24H'**
  String get range24h;

  /// No description provided for @range7d.
  ///
  /// In en, this message translates to:
  /// **'7D'**
  String get range7d;

  /// No description provided for @range30d.
  ///
  /// In en, this message translates to:
  /// **'30D'**
  String get range30d;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @allValues.
  ///
  /// In en, this message translates to:
  /// **'All values'**
  String get allValues;

  /// No description provided for @noDataInRange.
  ///
  /// In en, this message translates to:
  /// **'No data in this time range'**
  String get noDataInRange;

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} readings'**
  String readingsCount(String count);

  /// No description provided for @liveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing live right now'**
  String get liveEmptyTitle;

  /// No description provided for @liveEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to your car to watch every value move in real time.'**
  String get liveEmptyBody;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to start recording. Every value is saved on this phone, so you can look back at any drive.'**
  String get historyEmptyBody;

  /// No description provided for @recentTrips.
  ///
  /// In en, this message translates to:
  /// **'Recent trips'**
  String get recentTrips;

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'avg {speed}'**
  String avgSpeed(String speed);

  /// No description provided for @storageFooter.
  ///
  /// In en, this message translates to:
  /// **'{count} readings · {size} · stored only on this phone'**
  String storageFooter(String count, String size);

  /// No description provided for @demoCar.
  ///
  /// In en, this message translates to:
  /// **'Demo car'**
  String get demoCar;

  /// No description provided for @yourCar.
  ///
  /// In en, this message translates to:
  /// **'Your car'**
  String get yourCar;

  /// No description provided for @likelyYear.
  ///
  /// In en, this message translates to:
  /// **'{year} (likely)'**
  String likelyYear(int year);

  /// No description provided for @tripDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tripDuration;

  /// No description provided for @tripDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get tripDistance;

  /// No description provided for @tripAvgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get tripAvgSpeed;

  /// No description provided for @tripMaxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max speed'**
  String get tripMaxSpeed;

  /// No description provided for @tripMaxTemp.
  ///
  /// In en, this message translates to:
  /// **'Max engine temp'**
  String get tripMaxTemp;

  /// No description provided for @tripIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle time'**
  String get tripIdle;

  /// No description provided for @tripFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel used'**
  String get tripFuel;

  /// No description provided for @tripConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get tripConsumption;

  /// No description provided for @tripDistanceNote.
  ///
  /// In en, this message translates to:
  /// **'Distance is calculated from your car\'s speed and may differ slightly from your odometer.'**
  String get tripDistanceNote;

  /// No description provided for @tripGapNote.
  ///
  /// In en, this message translates to:
  /// **'Part of this trip had no data and isn\'t counted.'**
  String get tripGapNote;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTrip;

  /// No description provided for @deleteTripConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip? Its readings stay in your history.'**
  String get deleteTripConfirm;

  /// No description provided for @askingYourCar.
  ///
  /// In en, this message translates to:
  /// **'Asking your car…'**
  String get askingYourCar;

  /// No description provided for @codesNeverTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to check your car for problems'**
  String get codesNeverTitle;

  /// No description provided for @codesNeverBody.
  ///
  /// In en, this message translates to:
  /// **'Drivly reads fault codes automatically every time you connect, and keeps every scan.'**
  String get codesNeverBody;

  /// No description provided for @scanNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get scanNow;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @noProblemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No problems found'**
  String get noProblemsTitle;

  /// No description provided for @noProblemsBody.
  ///
  /// In en, this message translates to:
  /// **'Your car didn\'t report any fault codes. Checked {time}.'**
  String noProblemsBody(String time);

  /// No description provided for @milNoCodes.
  ///
  /// In en, this message translates to:
  /// **'Your engine light is on, but your car didn\'t share a code. Some problems are only visible with a manufacturer tool.'**
  String get milNoCodes;

  /// No description provided for @confirmedProblems.
  ///
  /// In en, this message translates to:
  /// **'Confirmed problems ({count})'**
  String confirmedProblems(int count);

  /// No description provided for @developingProblems.
  ///
  /// In en, this message translates to:
  /// **'Developing problems ({count})'**
  String developingProblems(int count);

  /// No description provided for @pendingExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s a developing problem?'**
  String get pendingExplainTitle;

  /// No description provided for @pendingExplainBody.
  ///
  /// In en, this message translates to:
  /// **'Your car noticed something once but hasn\'t confirmed it yet. If it happens again on the next drives, it becomes a confirmed problem and may turn the engine light on.'**
  String get pendingExplainBody;

  /// No description provided for @scanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan history'**
  String get scanHistory;

  /// No description provided for @scanHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get scanHistoryEmpty;

  /// No description provided for @milOn.
  ///
  /// In en, this message translates to:
  /// **'Engine light is ON'**
  String get milOn;

  /// No description provided for @problemsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 problem found} other{{count} problems found}}'**
  String problemsFound(int count);

  /// No description provided for @problemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No codes} =1{1 problem} other{{count} problems}}'**
  String problemsCount(int count);

  /// No description provided for @checkedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked {time}'**
  String checkedAt(String time);

  /// No description provided for @readFailedNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read codes: not connected.'**
  String get readFailedNotConnected;

  /// No description provided for @readFailedCar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read codes: your car isn\'t answering.'**
  String get readFailedCar;

  /// No description provided for @readFailedBusy.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read codes: the adapter is busy. Try again.'**
  String get readFailedBusy;

  /// No description provided for @readFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read codes. Try again.'**
  String get readFailed;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get severityMinor;

  /// No description provided for @actionHigh.
  ///
  /// In en, this message translates to:
  /// **'Get it checked today'**
  String get actionHigh;

  /// No description provided for @actionMedium.
  ///
  /// In en, this message translates to:
  /// **'Check soon'**
  String get actionMedium;

  /// No description provided for @actionMinor.
  ///
  /// In en, this message translates to:
  /// **'Not urgent'**
  String get actionMinor;

  /// No description provided for @clearCodes.
  ///
  /// In en, this message translates to:
  /// **'Clear codes'**
  String get clearCodes;

  /// No description provided for @stopCarFirst.
  ///
  /// In en, this message translates to:
  /// **'Stop the car first'**
  String get stopCarFirst;

  /// No description provided for @clearTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Clear 1 fault code?} other{Clear {count} fault codes?}}'**
  String clearTitle(int count);

  /// No description provided for @clearWarn1.
  ///
  /// In en, this message translates to:
  /// **'This turns the engine light off but doesn\'t fix anything. If the problem is still there, the codes will come back.'**
  String get clearWarn1;

  /// No description provided for @clearWarn2.
  ///
  /// In en, this message translates to:
  /// **'Your car\'s inspection checks reset. It may fail an emissions test (TÜV/AU, MOT, contrôle technique) until you\'ve driven for a few days.'**
  String get clearWarn2;

  /// No description provided for @clearWarn3.
  ///
  /// In en, this message translates to:
  /// **'Engine off, ignition on.'**
  String get clearWarn3;

  /// No description provided for @clearSnapshotNote.
  ///
  /// In en, this message translates to:
  /// **'A copy of these codes is saved to your scan history.'**
  String get clearSnapshotNote;

  /// No description provided for @clearDone.
  ///
  /// In en, this message translates to:
  /// **'Codes cleared. No problems right now.'**
  String get clearDone;

  /// No description provided for @clearCameBack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code came back straight away: the problem is still there.} other{{count} codes came back straight away: the problem is still there.}}'**
  String clearCameBack(int count);

  /// No description provided for @clearFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear the codes. Try again with the engine off and ignition on.'**
  String get clearFailed;

  /// No description provided for @whatYouMightNotice.
  ///
  /// In en, this message translates to:
  /// **'What you might notice'**
  String get whatYouMightNotice;

  /// No description provided for @safeToDrive.
  ///
  /// In en, this message translates to:
  /// **'Is it safe to drive?'**
  String get safeToDrive;

  /// No description provided for @commonCauses.
  ///
  /// In en, this message translates to:
  /// **'Common causes'**
  String get commonCauses;

  /// No description provided for @whatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get whatToDo;

  /// No description provided for @forYourMechanic.
  ///
  /// In en, this message translates to:
  /// **'For your mechanic'**
  String get forYourMechanic;

  /// No description provided for @kindStored.
  ///
  /// In en, this message translates to:
  /// **'Confirmed (mode 03)'**
  String get kindStored;

  /// No description provided for @kindPending.
  ///
  /// In en, this message translates to:
  /// **'Pending (mode 07)'**
  String get kindPending;

  /// No description provided for @manufacturerSpecific.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer-specific'**
  String get manufacturerSpecific;

  /// No description provided for @searchOnline.
  ///
  /// In en, this message translates to:
  /// **'Search online'**
  String get searchOnline;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Developing problem: not confirmed yet'**
  String get pendingBadge;

  /// No description provided for @noCodes.
  ///
  /// In en, this message translates to:
  /// **'No codes'**
  String get noCodes;

  /// No description provided for @reasonAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic check'**
  String get reasonAuto;

  /// No description provided for @reasonManual.
  ///
  /// In en, this message translates to:
  /// **'Manual scan'**
  String get reasonManual;

  /// No description provided for @reasonBeforeClear.
  ///
  /// In en, this message translates to:
  /// **'Before clearing'**
  String get reasonBeforeClear;

  /// No description provided for @reasonAfterClear.
  ///
  /// In en, this message translates to:
  /// **'After clearing'**
  String get reasonAfterClear;

  /// No description provided for @carEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No car yet'**
  String get carEmptyTitle;

  /// No description provided for @carEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect once and Drivly reads your car\'s VIN, make and likely year, all offline.'**
  String get carEmptyBody;

  /// No description provided for @adapterSection.
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get adapterSection;

  /// No description provided for @carSupports.
  ///
  /// In en, this message translates to:
  /// **'Data your car shares ({count})'**
  String carSupports(int count);

  /// No description provided for @editCar.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editCar;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @modelYear.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get modelYear;

  /// No description provided for @vinNotShared.
  ///
  /// In en, this message translates to:
  /// **'Your car doesn\'t share its VIN over OBD. You\'ll find it on your registration document or at the bottom of the windshield.'**
  String get vinNotShared;

  /// No description provided for @enterVin.
  ///
  /// In en, this message translates to:
  /// **'Enter VIN'**
  String get enterVin;

  /// No description provided for @enterVinHint.
  ///
  /// In en, this message translates to:
  /// **'17 characters, no I, O or Q.'**
  String get enterVinHint;

  /// No description provided for @vinInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a VIN.'**
  String get vinInvalid;

  /// No description provided for @madeIn.
  ///
  /// In en, this message translates to:
  /// **'Made in'**
  String get madeIn;

  /// No description provided for @connectionType.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionType;

  /// No description provided for @protocolCan.
  ///
  /// In en, this message translates to:
  /// **'CAN (modern)'**
  String get protocolCan;

  /// No description provided for @protocolLegacy.
  ///
  /// In en, this message translates to:
  /// **'K-Line (older)'**
  String get protocolLegacy;

  /// No description provided for @valuesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Values available'**
  String get valuesAvailable;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last connected'**
  String get lastSeen;

  /// No description provided for @batteryAtPort.
  ///
  /// In en, this message translates to:
  /// **'Battery at port'**
  String get batteryAtPort;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @fastMode.
  ///
  /// In en, this message translates to:
  /// **'Fast mode (multi-value requests)'**
  String get fastMode;

  /// No description provided for @updatesPerSecond.
  ///
  /// In en, this message translates to:
  /// **'Requests per second'**
  String get updatesPerSecond;

  /// No description provided for @changeAdapter.
  ///
  /// In en, this message translates to:
  /// **'Change adapter'**
  String get changeAdapter;

  /// No description provided for @groupMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get groupMotion;

  /// No description provided for @groupEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get groupEngine;

  /// No description provided for @groupTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperatures'**
  String get groupTemperature;

  /// No description provided for @groupFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get groupFuel;

  /// No description provided for @groupAir.
  ///
  /// In en, this message translates to:
  /// **'Air intake'**
  String get groupAir;

  /// No description provided for @groupElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get groupElectrical;

  /// No description provided for @groupEmissions.
  ///
  /// In en, this message translates to:
  /// **'Emissions'**
  String get groupEmissions;

  /// No description provided for @groupDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance & time'**
  String get groupDistance;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @unitsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get unitsSpeed;

  /// No description provided for @unitsTemp.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get unitsTemp;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get keepScreenOn;

  /// No description provided for @keepScreenOnHint.
  ///
  /// In en, this message translates to:
  /// **'While connected'**
  String get keepScreenOnHint;

  /// No description provided for @savedAdapter.
  ///
  /// In en, this message translates to:
  /// **'Saved adapter'**
  String get savedAdapter;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @connectAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Connect automatically'**
  String get connectAutomatically;

  /// No description provided for @adapterLog.
  ///
  /// In en, this message translates to:
  /// **'Adapter log'**
  String get adapterLog;

  /// No description provided for @adapterLogHint.
  ///
  /// In en, this message translates to:
  /// **'Raw adapter messages, for bug reports'**
  String get adapterLogHint;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet.'**
  String get logEmpty;

  /// No description provided for @historyAndTrips.
  ///
  /// In en, this message translates to:
  /// **'History & trips'**
  String get historyAndTrips;

  /// No description provided for @recordTrips.
  ///
  /// In en, this message translates to:
  /// **'Record trips automatically'**
  String get recordTrips;

  /// No description provided for @storedHistory.
  ///
  /// In en, this message translates to:
  /// **'Stored history'**
  String get storedHistory;

  /// No description provided for @storageDetail.
  ///
  /// In en, this message translates to:
  /// **'{readings} readings · {trips} trips · {size} · since {since}'**
  String storageDetail(
    String readings,
    String trips,
    String size,
    String since,
  );

  /// No description provided for @deleteOlder.
  ///
  /// In en, this message translates to:
  /// **'Delete history older than 90 days'**
  String get deleteOlder;

  /// No description provided for @deleteOlderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all readings older than 90 days? This can\'t be undone.'**
  String get deleteOlderConfirm;

  /// No description provided for @deleteAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete all history'**
  String get deleteAllHistory;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete every reading, trip and scan? This can\'t be undone.'**
  String get deleteAllConfirm;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @startDemo.
  ///
  /// In en, this message translates to:
  /// **'Start demo mode'**
  String get startDemo;

  /// No description provided for @demoRunning.
  ///
  /// In en, this message translates to:
  /// **'Demo mode is running'**
  String get demoRunning;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Simulated data, no car needed'**
  String get demoHint;

  /// No description provided for @simulateDrop.
  ///
  /// In en, this message translates to:
  /// **'Simulate connection loss'**
  String get simulateDrop;

  /// No description provided for @simulateIgnitionOff.
  ///
  /// In en, this message translates to:
  /// **'Simulate ignition off (6 s)'**
  String get simulateIgnitionOff;

  /// No description provided for @safetyPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Safety & privacy'**
  String get safetyPrivacy;

  /// No description provided for @safetyNotice.
  ///
  /// In en, this message translates to:
  /// **'Safety notice'**
  String get safetyNotice;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this phone. No account, no tracking.'**
  String get privacyBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get licenses;

  /// No description provided for @showOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Show onboarding again'**
  String get showOnboarding;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Eyes on the road'**
  String get safetyTitle;

  /// No description provided for @safetyBody.
  ///
  /// In en, this message translates to:
  /// **'Drivly is for passengers and parked use. Don\'t look at your phone while driving.'**
  String get safetyBody;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get iUnderstand;

  /// No description provided for @likelyAdapters.
  ///
  /// In en, this message translates to:
  /// **'Likely OBD adapters'**
  String get likelyAdapters;

  /// No description provided for @otherDevices.
  ///
  /// In en, this message translates to:
  /// **'Other Bluetooth devices ({count})'**
  String otherDevices(int count);

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @lookingForAdapters.
  ///
  /// In en, this message translates to:
  /// **'Looking for adapters…'**
  String get lookingForAdapters;

  /// No description provided for @scanFinished.
  ///
  /// In en, this message translates to:
  /// **'Scan finished'**
  String get scanFinished;

  /// No description provided for @noAdapterFound.
  ///
  /// In en, this message translates to:
  /// **'No adapter found'**
  String get noAdapterFound;

  /// No description provided for @troubleshootShort.
  ///
  /// In en, this message translates to:
  /// **'Check the adapter\'s light is on, the ignition is on, and that it\'s a Bluetooth LE adapter.'**
  String get troubleshootShort;

  /// No description provided for @cantFindAdapter.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your adapter?'**
  String get cantFindAdapter;

  /// No description provided for @trouble1.
  ///
  /// In en, this message translates to:
  /// **'Is the adapter\'s light on? If not, it isn\'t getting power. Check that it\'s pushed in fully.'**
  String get trouble1;

  /// No description provided for @trouble2.
  ///
  /// In en, this message translates to:
  /// **'Is the ignition on?'**
  String get trouble2;

  /// No description provided for @trouble3.
  ///
  /// In en, this message translates to:
  /// **'Is it a Bluetooth LE adapter? Classic-Bluetooth adapters don\'t work with iPhone, or with Drivly yet.'**
  String get trouble3;

  /// No description provided for @trouble4.
  ///
  /// In en, this message translates to:
  /// **'Is it connected to another phone or app? Close the other app or turn off Bluetooth on that phone.'**
  String get trouble4;

  /// No description provided for @trouble5.
  ///
  /// In en, this message translates to:
  /// **'Unplug the adapter for 10 seconds and plug it back in.'**
  String get trouble5;

  /// No description provided for @btOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get btOffTitle;

  /// No description provided for @btOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth to connect to your adapter.'**
  String get btOffBody;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivly needs Bluetooth access'**
  String get permTitle;

  /// No description provided for @permBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s only used to talk to your adapter. Nothing leaves your phone.'**
  String get permBody;

  /// No description provided for @connectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}'**
  String connectingTo(String name);

  /// No description provided for @stageAdapter.
  ///
  /// In en, this message translates to:
  /// **'Connecting to adapter'**
  String get stageAdapter;

  /// No description provided for @stageTalkAdapter.
  ///
  /// In en, this message translates to:
  /// **'Talking to adapter'**
  String get stageTalkAdapter;

  /// No description provided for @stageTalkCar.
  ///
  /// In en, this message translates to:
  /// **'Talking to your car'**
  String get stageTalkCar;

  /// No description provided for @mayTake15s.
  ///
  /// In en, this message translates to:
  /// **'This can take up to 15 s'**
  String get mayTake15s;

  /// No description provided for @errTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to {name}'**
  String errTransportTitle(String name);

  /// No description provided for @errTransportBody.
  ///
  /// In en, this message translates to:
  /// **'It may be connected to another phone or app.'**
  String get errTransportBody;

  /// No description provided for @errAdapterTitle.
  ///
  /// In en, this message translates to:
  /// **'The adapter isn\'t answering'**
  String get errAdapterTitle;

  /// No description provided for @errAdapterBody.
  ///
  /// In en, this message translates to:
  /// **'Unplug it, wait 10 seconds, plug it back in.'**
  String get errAdapterBody;

  /// No description provided for @errCarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your car isn\'t answering'**
  String get errCarTitle;

  /// No description provided for @errCarBody.
  ///
  /// In en, this message translates to:
  /// **'Turn the ignition on, or start the engine, and try again.'**
  String get errCarBody;

  /// No description provided for @errGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errGenericTitle;

  /// No description provided for @errGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Try again. If it keeps happening, share the adapter log with us.'**
  String get errGenericBody;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Drivly'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Understand your car in plain words. Live data, fault codes and full history. Everything stays on your phone.'**
  String get onbWelcomeBody;

  /// No description provided for @onbPlugTitle.
  ///
  /// In en, this message translates to:
  /// **'Plug in your adapter'**
  String get onbPlugTitle;

  /// No description provided for @onbPlugBody.
  ///
  /// In en, this message translates to:
  /// **'The port is usually under the dashboard, near your knees.'**
  String get onbPlugBody;

  /// No description provided for @onbIgnitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on the ignition'**
  String get onbIgnitionTitle;

  /// No description provided for @onbIgnitionBody.
  ///
  /// In en, this message translates to:
  /// **'Turn the key or press Start without your foot on the brake. Some cars need the engine running.'**
  String get onbIgnitionBody;

  /// No description provided for @onbConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get onbConnectTitle;

  /// No description provided for @onbConnectBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll look for your adapter. Your phone will ask for Bluetooth access: it\'s only used to talk to the adapter.'**
  String get onbConnectBody;

  /// No description provided for @whereIsPort.
  ///
  /// In en, this message translates to:
  /// **'Where is my port?'**
  String get whereIsPort;

  /// No description provided for @whereIsPortBody.
  ///
  /// In en, this message translates to:
  /// **'Most cars: under the dashboard on the driver\'s side, near the steering column. Sometimes behind a small cover, near the fuse box, or under the center console.'**
  String get whereIsPortBody;

  /// No description provided for @whichAdapter.
  ///
  /// In en, this message translates to:
  /// **'Which adapter do I need?'**
  String get whichAdapter;

  /// No description provided for @whichAdapterBody.
  ///
  /// In en, this message translates to:
  /// **'An ELM327-compatible adapter with Bluetooth LE (often labeled \"Bluetooth 4.0\" or \"for iOS\"). Classic Bluetooth adapters don\'t work with iPhone, or with Drivly yet.'**
  String get whichAdapterBody;

  /// No description provided for @sensorSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get sensorSpeed;

  /// No description provided for @sensorSpeedInfo.
  ///
  /// In en, this message translates to:
  /// **'How fast the car is going, as measured by the car itself.'**
  String get sensorSpeedInfo;

  /// No description provided for @sensorRpm.
  ///
  /// In en, this message translates to:
  /// **'Engine speed'**
  String get sensorRpm;

  /// No description provided for @sensorRpmInfo.
  ///
  /// In en, this message translates to:
  /// **'How many times per minute the engine turns. Around 800 at idle, higher when you accelerate.'**
  String get sensorRpmInfo;

  /// No description provided for @sensorCoolant.
  ///
  /// In en, this message translates to:
  /// **'Engine temperature'**
  String get sensorCoolant;

  /// No description provided for @sensorCoolantInfo.
  ///
  /// In en, this message translates to:
  /// **'The temperature of the engine\'s coolant. It rises to about 90 °C once the engine is warm.'**
  String get sensorCoolantInfo;

  /// No description provided for @sensorBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get sensorBattery;

  /// No description provided for @sensorBatteryInfo.
  ///
  /// In en, this message translates to:
  /// **'Voltage at the OBD port. With the engine running, it shows whether the battery is being charged.'**
  String get sensorBatteryInfo;

  /// No description provided for @sensorLoad.
  ///
  /// In en, this message translates to:
  /// **'Engine load'**
  String get sensorLoad;

  /// No description provided for @sensorLoadInfo.
  ///
  /// In en, this message translates to:
  /// **'How hard the engine is working right now. High when accelerating or climbing, low when cruising.'**
  String get sensorLoadInfo;

  /// No description provided for @sensorThrottle.
  ///
  /// In en, this message translates to:
  /// **'Throttle'**
  String get sensorThrottle;

  /// No description provided for @sensorThrottleInfo.
  ///
  /// In en, this message translates to:
  /// **'How far the throttle is open, which controls how much air the engine gets.'**
  String get sensorThrottleInfo;

  /// No description provided for @sensorIntakeTemp.
  ///
  /// In en, this message translates to:
  /// **'Intake air'**
  String get sensorIntakeTemp;

  /// No description provided for @sensorIntakeTempInfo.
  ///
  /// In en, this message translates to:
  /// **'Temperature of the air going into the engine. Cooler air gives a little more power.'**
  String get sensorIntakeTempInfo;

  /// No description provided for @sensorFuelLevel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get sensorFuelLevel;

  /// No description provided for @sensorFuelLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'How full the tank is, as a percentage.'**
  String get sensorFuelLevelInfo;

  /// No description provided for @sensorFuelRate.
  ///
  /// In en, this message translates to:
  /// **'Fuel use'**
  String get sensorFuelRate;

  /// No description provided for @sensorFuelRateInfo.
  ///
  /// In en, this message translates to:
  /// **'How much fuel the engine is burning right now, in liters per hour.'**
  String get sensorFuelRateInfo;

  /// No description provided for @sensorMaf.
  ///
  /// In en, this message translates to:
  /// **'Air flow'**
  String get sensorMaf;

  /// No description provided for @sensorMafInfo.
  ///
  /// In en, this message translates to:
  /// **'How much air flows into the engine each second. It goes up with engine speed and load.'**
  String get sensorMafInfo;

  /// No description provided for @sensorMap.
  ///
  /// In en, this message translates to:
  /// **'Intake pressure'**
  String get sensorMap;

  /// No description provided for @sensorMapInfo.
  ///
  /// In en, this message translates to:
  /// **'Air pressure in the intake. Low at idle, close to outside pressure at full throttle (higher with a turbo).'**
  String get sensorMapInfo;

  /// No description provided for @sensorTiming.
  ///
  /// In en, this message translates to:
  /// **'Ignition timing'**
  String get sensorTiming;

  /// No description provided for @sensorTimingInfo.
  ///
  /// In en, this message translates to:
  /// **'How early the spark fires before the piston reaches the top. The engine adjusts it constantly.'**
  String get sensorTimingInfo;

  /// No description provided for @sensorOilTemp.
  ///
  /// In en, this message translates to:
  /// **'Oil temperature'**
  String get sensorOilTemp;

  /// No description provided for @sensorOilTempInfo.
  ///
  /// In en, this message translates to:
  /// **'Temperature of the engine oil. It warms up more slowly than the coolant.'**
  String get sensorOilTempInfo;

  /// No description provided for @sensorAmbientTemp.
  ///
  /// In en, this message translates to:
  /// **'Outside air'**
  String get sensorAmbientTemp;

  /// No description provided for @sensorAmbientTempInfo.
  ///
  /// In en, this message translates to:
  /// **'Temperature outside the car, as measured by the car.'**
  String get sensorAmbientTempInfo;

  /// No description provided for @sensorModuleVoltage.
  ///
  /// In en, this message translates to:
  /// **'Computer voltage'**
  String get sensorModuleVoltage;

  /// No description provided for @sensorModuleVoltageInfo.
  ///
  /// In en, this message translates to:
  /// **'Voltage reaching the engine computer. Usually close to the battery voltage.'**
  String get sensorModuleVoltageInfo;

  /// No description provided for @sensorAbsoluteLoad.
  ///
  /// In en, this message translates to:
  /// **'Absolute load'**
  String get sensorAbsoluteLoad;

  /// No description provided for @sensorAbsoluteLoadInfo.
  ///
  /// In en, this message translates to:
  /// **'Engine load relative to its best breathing. Can exceed 100% on turbo engines.'**
  String get sensorAbsoluteLoadInfo;

  /// No description provided for @sensorRelativeThrottle.
  ///
  /// In en, this message translates to:
  /// **'Relative throttle'**
  String get sensorRelativeThrottle;

  /// No description provided for @sensorRelativeThrottleInfo.
  ///
  /// In en, this message translates to:
  /// **'Throttle opening measured from its learned closed position.'**
  String get sensorRelativeThrottleInfo;

  /// No description provided for @sensorPedal.
  ///
  /// In en, this message translates to:
  /// **'Accelerator pedal'**
  String get sensorPedal;

  /// No description provided for @sensorPedalInfo.
  ///
  /// In en, this message translates to:
  /// **'How far the accelerator pedal is pressed.'**
  String get sensorPedalInfo;

  /// No description provided for @sensorRelativePedal.
  ///
  /// In en, this message translates to:
  /// **'Relative pedal'**
  String get sensorRelativePedal;

  /// No description provided for @sensorCommandedThrottle.
  ///
  /// In en, this message translates to:
  /// **'Throttle command'**
  String get sensorCommandedThrottle;

  /// No description provided for @sensorCommandedThrottleInfo.
  ///
  /// In en, this message translates to:
  /// **'How far the engine computer is asking the throttle to open.'**
  String get sensorCommandedThrottleInfo;

  /// No description provided for @sensorDemandTorque.
  ///
  /// In en, this message translates to:
  /// **'Requested torque'**
  String get sensorDemandTorque;

  /// No description provided for @sensorDemandTorqueInfo.
  ///
  /// In en, this message translates to:
  /// **'The torque you\'re asking for with the pedal, as a percentage of the engine\'s maximum.'**
  String get sensorDemandTorqueInfo;

  /// No description provided for @sensorActualTorque.
  ///
  /// In en, this message translates to:
  /// **'Actual torque'**
  String get sensorActualTorque;

  /// No description provided for @sensorActualTorqueInfo.
  ///
  /// In en, this message translates to:
  /// **'The torque the engine is delivering, as a percentage of its maximum.'**
  String get sensorActualTorqueInfo;

  /// No description provided for @sensorReferenceTorque.
  ///
  /// In en, this message translates to:
  /// **'Reference torque'**
  String get sensorReferenceTorque;

  /// No description provided for @sensorReferenceTorqueInfo.
  ///
  /// In en, this message translates to:
  /// **'The engine\'s reference (maximum) torque, used to scale the torque percentages.'**
  String get sensorReferenceTorqueInfo;

  /// No description provided for @sensorFuelPressure.
  ///
  /// In en, this message translates to:
  /// **'Fuel pressure'**
  String get sensorFuelPressure;

  /// No description provided for @sensorFuelPressureInfo.
  ///
  /// In en, this message translates to:
  /// **'Pressure in the fuel system.'**
  String get sensorFuelPressureInfo;

  /// No description provided for @sensorRailPressure.
  ///
  /// In en, this message translates to:
  /// **'Fuel rail pressure'**
  String get sensorRailPressure;

  /// No description provided for @sensorRailPressureInfo.
  ///
  /// In en, this message translates to:
  /// **'Pressure in the fuel rail that feeds the injectors. Very high on direct-injection and diesel engines.'**
  String get sensorRailPressureInfo;

  /// No description provided for @sensorInjectionTiming.
  ///
  /// In en, this message translates to:
  /// **'Injection timing'**
  String get sensorInjectionTiming;

  /// No description provided for @sensorInjectionTimingInfo.
  ///
  /// In en, this message translates to:
  /// **'When fuel is injected relative to the piston position.'**
  String get sensorInjectionTimingInfo;

  /// No description provided for @sensorEthanol.
  ///
  /// In en, this message translates to:
  /// **'Ethanol content'**
  String get sensorEthanol;

  /// No description provided for @sensorEthanolInfo.
  ///
  /// In en, this message translates to:
  /// **'How much ethanol is in the fuel (flex-fuel cars).'**
  String get sensorEthanolInfo;

  /// No description provided for @sensorLambda.
  ///
  /// In en, this message translates to:
  /// **'Air-fuel target'**
  String get sensorLambda;

  /// No description provided for @sensorLambdaInfo.
  ///
  /// In en, this message translates to:
  /// **'The air-fuel mixture the engine is aiming for. 1.00 is the ideal (stoichiometric) mix.'**
  String get sensorLambdaInfo;

  /// No description provided for @sensorBaro.
  ///
  /// In en, this message translates to:
  /// **'Air pressure'**
  String get sensorBaro;

  /// No description provided for @sensorBaroInfo.
  ///
  /// In en, this message translates to:
  /// **'Outside air pressure. Lower at altitude.'**
  String get sensorBaroInfo;

  /// No description provided for @sensorO2Front.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor (front)'**
  String get sensorO2Front;

  /// No description provided for @sensorO2FrontInfo.
  ///
  /// In en, this message translates to:
  /// **'Measures oxygen in the exhaust before the catalytic converter. It swings quickly when the engine is warm, which is normal.'**
  String get sensorO2FrontInfo;

  /// No description provided for @sensorO2Rear.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor (rear)'**
  String get sensorO2Rear;

  /// No description provided for @sensorO2RearInfo.
  ///
  /// In en, this message translates to:
  /// **'Measures oxygen after the catalytic converter. A steady value means the converter is working.'**
  String get sensorO2RearInfo;

  /// No description provided for @sensorCatTemp.
  ///
  /// In en, this message translates to:
  /// **'Catalyst temperature'**
  String get sensorCatTemp;

  /// No description provided for @sensorCatTempInfo.
  ///
  /// In en, this message translates to:
  /// **'Temperature of the catalytic converter, which cleans the exhaust.'**
  String get sensorCatTempInfo;

  /// No description provided for @sensorEgr.
  ///
  /// In en, this message translates to:
  /// **'Exhaust recirculation'**
  String get sensorEgr;

  /// No description provided for @sensorEgrInfo.
  ///
  /// In en, this message translates to:
  /// **'How much exhaust gas is fed back into the engine to reduce emissions.'**
  String get sensorEgrInfo;

  /// No description provided for @sensorEvapPurge.
  ///
  /// In en, this message translates to:
  /// **'Fuel vapor purge'**
  String get sensorEvapPurge;

  /// No description provided for @sensorEvapPurgeInfo.
  ///
  /// In en, this message translates to:
  /// **'How much fuel vapor from the tank is being burned by the engine.'**
  String get sensorEvapPurgeInfo;

  /// No description provided for @sensorHybridBattery.
  ///
  /// In en, this message translates to:
  /// **'Hybrid battery'**
  String get sensorHybridBattery;

  /// No description provided for @sensorHybridBatteryInfo.
  ///
  /// In en, this message translates to:
  /// **'Remaining charge of the hybrid battery pack.'**
  String get sensorHybridBatteryInfo;

  /// No description provided for @sensorRunTime.
  ///
  /// In en, this message translates to:
  /// **'Engine run time'**
  String get sensorRunTime;

  /// No description provided for @sensorRunTimeInfo.
  ///
  /// In en, this message translates to:
  /// **'How long the engine has been running since it was started.'**
  String get sensorRunTimeInfo;

  /// No description provided for @sensorDistanceWithMil.
  ///
  /// In en, this message translates to:
  /// **'Distance with engine light'**
  String get sensorDistanceWithMil;

  /// No description provided for @sensorDistanceWithMilInfo.
  ///
  /// In en, this message translates to:
  /// **'How far the car has driven with the engine light on.'**
  String get sensorDistanceWithMilInfo;

  /// No description provided for @sensorDistanceSinceClear.
  ///
  /// In en, this message translates to:
  /// **'Distance since codes cleared'**
  String get sensorDistanceSinceClear;

  /// No description provided for @sensorDistanceSinceClearInfo.
  ///
  /// In en, this message translates to:
  /// **'How far the car has driven since fault codes were last cleared.'**
  String get sensorDistanceSinceClearInfo;

  /// No description provided for @sensorWarmups.
  ///
  /// In en, this message translates to:
  /// **'Warm-ups since codes cleared'**
  String get sensorWarmups;

  /// No description provided for @sensorWarmupsInfo.
  ///
  /// In en, this message translates to:
  /// **'How many times the engine has warmed up since codes were last cleared.'**
  String get sensorWarmupsInfo;

  /// No description provided for @sensorTimeWithMil.
  ///
  /// In en, this message translates to:
  /// **'Time with engine light'**
  String get sensorTimeWithMil;

  /// No description provided for @sensorTimeSinceClear.
  ///
  /// In en, this message translates to:
  /// **'Time since codes cleared'**
  String get sensorTimeSinceClear;

  /// No description provided for @sensorOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get sensorOdometer;

  /// No description provided for @sensorOdometerInfo.
  ///
  /// In en, this message translates to:
  /// **'Total distance the car has driven, reported by the car.'**
  String get sensorOdometerInfo;

  /// No description provided for @sensorMil.
  ///
  /// In en, this message translates to:
  /// **'Engine light'**
  String get sensorMil;

  /// No description provided for @sensorMilInfo.
  ///
  /// In en, this message translates to:
  /// **'Whether the engine (check engine) light is on.'**
  String get sensorMilInfo;

  /// No description provided for @sensorDtcCount.
  ///
  /// In en, this message translates to:
  /// **'Stored codes'**
  String get sensorDtcCount;

  /// No description provided for @sensorDtcCountInfo.
  ///
  /// In en, this message translates to:
  /// **'How many confirmed fault codes the car has stored.'**
  String get sensorDtcCountInfo;

  /// No description provided for @sensorStft.
  ///
  /// In en, this message translates to:
  /// **'Short-term fuel trim (bank {bank})'**
  String sensorStft(int bank);

  /// No description provided for @sensorLtft.
  ///
  /// In en, this message translates to:
  /// **'Long-term fuel trim (bank {bank})'**
  String sensorLtft(int bank);

  /// No description provided for @sensorStftInfo.
  ///
  /// In en, this message translates to:
  /// **'Quick fuel corrections the engine makes right now. Values near 0% are ideal; large swings are normal.'**
  String get sensorStftInfo;

  /// No description provided for @sensorLtftInfo.
  ///
  /// In en, this message translates to:
  /// **'Fuel corrections the engine has learned over time. Beyond about ±10% can point to a leak or a sensor problem.'**
  String get sensorLtftInfo;

  /// No description provided for @webChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your adapter'**
  String get webChooseTitle;

  /// No description provided for @webChooseBody.
  ///
  /// In en, this message translates to:
  /// **'Your browser shows nearby Bluetooth devices in its own window. Choose your OBD adapter (often called OBDII, Vlink or Vgate).'**
  String get webChooseBody;

  /// No description provided for @webChooseAdapter.
  ///
  /// In en, this message translates to:
  /// **'Choose adapter'**
  String get webChooseAdapter;

  /// No description provided for @bleUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth isn\'t available here'**
  String get bleUnsupportedTitle;

  /// No description provided for @bleUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'This browser can\'t use Bluetooth. Open Drivly in Chrome or Edge on a computer with Bluetooth, or try demo mode.'**
  String get bleUnsupportedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
