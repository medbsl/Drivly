import 'dart:io';

import 'package:drivly/core/debug_log.dart';
import 'package:drivly/core/debug_log_io.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStore implements DebugLogStore {
  @override
  Future<void> append(String text) async => throw const FileSystemException('disk full');
  @override
  Future<String> readAll() async => '';
  @override
  Future<int> size() async => 0;
}

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('drivly_debug'));
  tearDown(() async => dir.delete(recursive: true));

  DebugLog enabledLog(DebugLogStore store, {Duration flushEvery = const Duration(seconds: 1)}) =>
      DebugLog(store, flushEvery: flushEvery, clock: () => DateTime(2026, 11, 20, 8, 25, 13, 123))..enabled = true;

  test('disabled: nothing is written', () async {
    final store = MemoryDebugLogStore();
    final log = DebugLog(store);
    log.add('obd', '>> ATZ');
    await log.error('error', 'boom');
    await log.flush();
    expect(await store.size(), 0);
    expect(log.hasContent, isFalse);
  });

  test('buffered lines reach the store after flush, with time and source', () async {
    final store = MemoryDebugLogStore();
    final log = enabledLog(store);
    log.add('obd', '>> ATZ');
    expect(await store.readAll(), isEmpty, reason: 'buffered');
    await log.flush();
    expect(await store.readAll(), '08:25:13.123 [obd] >> ATZ\n');
    expect(log.hasContent, isTrue);
  });

  test('timed flush within flushEvery', () async {
    final store = MemoryDebugLogStore();
    final log = enabledLog(store, flushEvery: const Duration(milliseconds: 20));
    addTearDown(log.dispose);
    log.add('ble', 'connected');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await store.readAll(), contains('[ble] connected'));
  });

  test('an error is written at once', () async {
    final store = MemoryDebugLogStore();
    final log = enabledLog(store);
    log.add('obd', '>> 0100');
    await log.error('error', 'Null check operator used on a null value');
    expect(await store.readAll(), contains('>> 0100'), reason: 'earlier lines go first');
    expect(await store.readAll(), contains('[error] Null check operator'));
  });

  test('VINs are masked', () async {
    final store = MemoryDebugLogStore();
    final log = enabledLog(store);
    log.add('app', 'vehicle WVWZZZ1KZ5W123456');
    await log.flush();
    final text = await store.readAll();
    expect(text, contains('WVW••••••••••••••'));
    expect(text, isNot(contains('1KZ5W123456')));
  });

  test('survives a new instance (the app was closed)', () async {
    final first = enabledLog(FileDebugLogStore(dir));
    first.add('conn', 'carNotResponding · UNABLE TO CONNECT');
    await first.flush();

    final second = await DebugLog.open(FileDebugLogStore(dir));
    expect(second.hasContent, isTrue);
    expect(await second.export(), contains('carNotResponding · UNABLE TO CONNECT'));
  });

  test('rotation keeps the newest lines and caps the size', () async {
    final store = FileDebugLogStore(dir, halfBytes: 1000);
    final log = enabledLog(store);
    for (var i = 0; i < 100; i++) {
      log.add('obd', 'line $i ${'x' * 30}');
      await log.flush();
    }
    expect(await store.size(), lessThanOrEqualTo(2000));
    final text = await log.export();
    expect(text, contains('line 99 '));
    expect(text, isNot(contains('line 0 ')));
    final lines = text.trim().split('\n');
    final numbers = [for (final l in lines) int.parse(RegExp(r'line (\d+)').firstMatch(l)!.group(1)!)];
    expect(numbers, orderedEquals([...numbers]..sort()), reason: 'older half first');
  });

  test('a failing store never throws into the app', () async {
    final log = enabledLog(_BrokenStore());
    log.add('obd', '>> ATZ');
    await expectLater(log.flush(), completes);
    await expectLater(log.error('error', 'x'), completes);
  });
}
