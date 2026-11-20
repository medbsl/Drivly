import 'package:share_plus/share_plus.dart';

import 'debug_log.dart';

// The browser has no files to keep: the debug log lives in memory.

Future<DebugLogStore> openDebugLogStore() async => MemoryDebugLogStore();

String platformDescription() => 'web';

Future<void> shareDebugLog(DebugLog log) async => SharePlus.instance.share(ShareParams(text: await log.export()));
