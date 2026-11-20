/// File-backed debug log on the phone, in memory on the web.
library;

export 'debug_log_stub.dart' if (dart.library.io) 'debug_log_io.dart';
