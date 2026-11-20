import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'debug_log.dart';

/// The debug log on disk: `debug.log`, and `debug.1.log` for the older half.
/// When `debug.log` would grow past [halfBytes] it becomes `debug.1.log`, so
/// the total stays around twice [halfBytes] and the newest lines are kept.
class FileDebugLogStore implements DebugLogStore {
  FileDebugLogStore(this.dir, {this.halfBytes = 1024 * 1024});

  final Directory dir;
  final int halfBytes;

  File get _current => File(p.join(dir.path, 'debug.log'));
  File get _older => File(p.join(dir.path, 'debug.1.log'));

  @override
  Future<void> append(String text) async {
    await dir.create(recursive: true);
    final current = _current;
    final length = await current.exists() ? await current.length() : 0;
    if (length > 0 && length + utf8.encode(text).length > halfBytes) {
      await current.rename(_older.path);
    }
    await _current.writeAsString(text, mode: FileMode.append, flush: true);
  }

  @override
  Future<String> readAll() async {
    final out = StringBuffer();
    for (final f in [_older, _current]) {
      if (await f.exists()) out.write(await f.readAsString());
    }
    return out.toString();
  }

  @override
  Future<int> size() async {
    var total = 0;
    for (final f in [_older, _current]) {
      if (await f.exists()) total += await f.length();
    }
    return total;
  }
}

Future<DebugLogStore> openDebugLogStore() async {
  final base = await getApplicationSupportDirectory();
  return FileDebugLogStore(Directory(p.join(base.path, 'debug')));
}

String platformDescription() => '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

/// Shares the whole log as one text file (AirDrop, Files, Mail…).
Future<void> shareDebugLog(DebugLog log) async {
  final name = 'drivly-debug-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.txt';
  final file = File(p.join((await getTemporaryDirectory()).path, name));
  await file.writeAsString(await log.export());
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/plain')], subject: name));
}
