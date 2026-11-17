import 'dart:async';
import 'dart:convert';

import '../adapter/adapter_log.dart';
import '../transport/obd_transport.dart';
import 'elm_error.dart';
import 'read_only_guard.dart';
import 'response_framer.dart';
import 'sanitizer.dart';

/// One reply to one command.
class ElmResponse {
  const ElmResponse({
    required this.command,
    required this.raw,
    required this.lines,
    required this.error,
    this.timedOut = false,
  });

  const ElmResponse.timeout(this.command)
      : raw = '',
        lines = const [],
        error = null,
        timedOut = true;

  final String command;
  final String raw;
  final List<String> lines;
  final ElmError? error;
  final bool timedOut;

  bool get ok => !timedOut && error == null;

  @override
  String toString() => timedOut ? '$command → TIMEOUT' : '$command → ${lines.join(' | ')}';
}

/// Serialises commands to an ELM327: exactly one command in flight, FIFO.
///
/// After a timeout the session waits for (and discards) the late prompt so a
/// stale reply is never mistaken for the next command's reply.
class ElmSession {
  ElmSession(this.transport, {AdapterLog? log, this.timeoutScale = 1.0}) : log = log ?? AdapterLog();

  final double timeoutScale;

  final ObdTransport transport;
  final AdapterLog log;
  final ResponseFramer _framer = ResponseFramer();

  StreamSubscription<List<int>>? _sub;
  Completer<String>? _pending;
  Future<void> _tail = Future<void>.value();
  bool _closed = false;
  int _consecutiveTimeouts = 0;

  /// Number of timeouts in a row; reset by any reply.
  int get consecutiveTimeouts => _consecutiveTimeouts;

  void start() {
    _sub ??= transport.incoming.listen(_onBytes);
  }

  void _onBytes(List<int> bytes) {
    for (final reply in _framer.add(bytes)) {
      final p = _pending;
      if (p != null && !p.isCompleted) {
        p.complete(reply);
      } else {
        final text = reply.trim();
        if (text.isNotEmpty) log.add(LogDirection.info, 'discarded stale reply: ${text.replaceAll('\r', ' ')}');
      }
    }
  }

  /// Queues [command] and resolves with its reply. Never throws for protocol
  /// problems: a hung adapter yields [ElmResponse.timeout].
  ///
  /// Read-only: a command that isn't a read is logged, never sent, and throws
  /// [ReadOnlyViolation].
  Future<ElmResponse> send(String command, {Duration timeout = const Duration(milliseconds: 1500)}) {
    if (!isReadOnlyCommand(command)) {
      log.add(LogDirection.info, 'blocked (read-only): $command');
      throw ReadOnlyViolation(command);
    }
    final result = Completer<ElmResponse>();
    _tail = _tail.then((_) async {
      result.complete(await _execute(command, timeout));
    }).catchError((Object e) {
      if (!result.isCompleted) result.complete(ElmResponse.timeout(command));
    });
    return result.future;
  }

  Future<ElmResponse> _execute(String command, Duration timeout) async {
    if (_closed) return ElmResponse.timeout(command);
    start();
    final completer = Completer<String>();
    _pending = completer;
    log.add(LogDirection.tx, command);
    try {
      await transport.write(ascii.encode('$command\r'));
    } catch (e) {
      _pending = null;
      log.add(LogDirection.info, 'write failed: $e');
      return ElmResponse.timeout(command);
    }
    String raw;
    try {
      raw = await completer.future.timeout(timeout);
    } on TimeoutException {
      _pending = null;
      _consecutiveTimeouts++;
      log.add(LogDirection.rx, '(no reply after ${timeout.inMilliseconds} ms)');
      await _flushAfterTimeout();
      return ElmResponse.timeout(command);
    }
    _pending = null;
    _consecutiveTimeouts = 0;
    final isAt = command.toUpperCase().startsWith('AT');
    final lines = sanitizeResponse(raw, command: command);
    log.add(LogDirection.rx, lines.isEmpty ? '(empty)' : lines.join(' | '));
    return ElmResponse(
      command: command,
      raw: raw,
      lines: lines,
      error: classifyReply(lines, isAtCommand: isAt),
    );
  }

  /// Waits up to [wait] for a late prompt and drops it.
  Future<void> _flushAfterTimeout() async {
    final wait = Duration(microseconds: (600000 * timeoutScale).round());
    final drain = Completer<String>();
    _pending = drain;
    try {
      await drain.future.timeout(wait);
    } on TimeoutException {
      // Nothing came back. Nudge the adapter so it ends whatever it is doing.
      // A bare CR interrupts the adapter or repeats the last command, which
      // already passed the read-only check.
      try {
        await transport.write(ascii.encode('\r'));
        final second = Completer<String>();
        _pending = second;
        await second.future.timeout(wait);
      } catch (_) {}
    } finally {
      _pending = null;
      _framer.reset();
    }
  }

  Future<void> close() async {
    _closed = true;
    await _sub?.cancel();
    _sub = null;
    final p = _pending;
    if (p != null && !p.isCompleted) p.complete('');
  }
}
