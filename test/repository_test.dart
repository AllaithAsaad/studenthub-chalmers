import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studenthub_chalmers/data/repository.dart';
import 'package:studenthub_chalmers/domain/models.dart';
import 'package:studenthub_chalmers/domain/store.dart';
import 'package:studenthub_chalmers/domain/focus_timer.dart';

void main() {
  late StudyRepository repo;
  late Directory directory;
  late String path;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('studenthub-test-');
    path = '${directory.path}/test.db';
    repo = StudyRepository(
      await databaseFactoryFfi.openDatabase(
        path,
        options: StudyRepository.options,
      ),
    );
  });
  tearDown(() async {
    await repo.db.close();
    await directory.delete(recursive: true);
  });
  test(
    'data persists after close and reopen, demo is opt-in and idempotent',
    () async {
      expect(await repo.courses(), isEmpty);
      await repo.start(demo: true, now: DateTime(2026, 9, 17));
      await repo.start(demo: true);
      expect(await repo.courses(), hasLength(4));
      final original = (await repo.entries()).first;
      await repo.save('entries', original.withDone(true).toMap());
      await repo.db.close();
      repo = StudyRepository(
        await databaseFactoryFfi.openDatabase(
          path,
          options: StudyRepository.options,
        ),
      );
      expect(
        (await repo.entries()).firstWhere((e) => e.id == original.id).done,
        isTrue,
      );
      expect(await repo.notes(), hasLength(2));
      expect(await repo.groups(), hasLength(1));
    },
  );
  test(
    'editing course preserves links; deleting it preserves child data without dangling IDs',
    () async {
      await repo.start(demo: true);
      final c = (await repo.courses()).firstWhere((c) => c.id == 'demo-1');
      await repo.save(
        'courses',
        Course(id: c.id, name: 'Changed', code: c.code, grade: '4').toMap(),
      );
      expect(
        (await repo.entries()).where((e) => e.courseId == c.id),
        isNotEmpty,
      );
      await repo.remove('courses', c.id);
      expect((await repo.entries()).where((e) => e.courseId == c.id), isEmpty);
      expect(
        (await repo.entries()).firstWhere((e) => e.id == 'demo-e1').courseId,
        isNull,
      );
      expect(
        (await repo.notes()).firstWhere((n) => n.id == 'demo-n1').body,
        isNotEmpty,
      );
    },
  );
  test('blank start and reset do not repopulate demo data', () async {
    await repo.start(demo: false);
    expect(await repo.courses(), isEmpty);
    await repo.clearAll();
    await repo.start(demo: true);
    expect(await repo.courses(), isEmpty);
    expect((await repo.settings())['onboarded'], 'true');
  });
  test('database rejects invalid date range atomically', () async {
    final now = DateTime.now();
    final e = StudyEntry(
      id: 'bad',
      title: 'Invalid',
      kind: EntryKind.study,
      startsAt: now,
      endsAt: now.subtract(const Duration(hours: 1)),
    );
    await expectLater(
      repo.save('entries', e.toMap()),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repo.entries(), isEmpty);
  });
  test('restored timer uses wall clock and completes exactly once', () async {
    final store = StudyStore(repo);
    await store.load();
    var now = DateTime(2026, 9, 17, 10);
    final timer = FocusTimer(store, clock: () => now, autoTick: false);
    await timer.toggle();
    now = now.add(const Duration(minutes: 12));
    await timer.tick();
    expect(timer.remaining, 13 * 60);
    timer.dispose();
    await store.load();
    final restored = FocusTimer(store, clock: () => now, autoTick: false);
    await restored.tick();
    expect(restored.remaining, 13 * 60);
    now = now.add(const Duration(hours: 1));
    await restored.tick();
    await restored.tick();
    expect(await repo.sessions(), hasLength(1));
    expect((await repo.sessions()).single.minutes, 25);
    expect(restored.isBreak, isTrue);
    expect(restored.running, isFalse);
    await restored.toggle();
    now = now.add(const Duration(minutes: 5));
    await restored.tick();
    expect(await repo.sessions(), hasLength(1));
    restored.dispose();
    store.dispose();
  });
  test(
    'pause excludes break time and resume preserves remaining duration',
    () async {
      final store = StudyStore(repo);
      await store.load();
      var now = DateTime(2026, 9, 17, 10);
      final timer = FocusTimer(store, clock: () => now, autoTick: false);
      await timer.toggle();
      now = now.add(const Duration(minutes: 5));
      await timer.tick();
      await timer.toggle();
      now = now.add(const Duration(hours: 2));
      await timer.tick();
      expect(timer.remaining, 20 * 60);
      await timer.toggle();
      now = now.add(const Duration(minutes: 20));
      await timer.tick();
      expect(await repo.sessions(), hasLength(1));
      timer.dispose();
      store.dispose();
    },
  );
}
