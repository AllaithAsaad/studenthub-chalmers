import 'package:sqflite_common/sqlite_api.dart';
import 'database_native.dart'
    if (dart.library.js_interop) 'database_web.dart'
    as platform;
import '../domain/models.dart';

class StudyRepository {
  StudyRepository(this.db);
  final Database db;
  static OpenDatabaseOptions get options => OpenDatabaseOptions(
    version: 1,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE courses (id TEXT PRIMARY KEY, name TEXT NOT NULL, code TEXT NOT NULL, credits REAL NOT NULL CHECK(credits > 0), color INTEGER NOT NULL, grade TEXT)',
      );
      await db.execute(
        'CREATE TABLE entries (id TEXT PRIMARY KEY, title TEXT NOT NULL, kind TEXT NOT NULL, starts_at INTEGER NOT NULL, ends_at INTEGER NOT NULL CHECK(ends_at >= starts_at), course_id TEXT REFERENCES courses(id) ON DELETE SET NULL, location TEXT NOT NULL, done INTEGER NOT NULL, remind_minutes INTEGER)',
      );
      await db.execute('CREATE INDEX entries_start ON entries(starts_at)');
      await db.execute(
        'CREATE TABLE groups_local (id TEXT PRIMARY KEY, name TEXT NOT NULL, members TEXT NOT NULL, meeting_at INTEGER NOT NULL, course_id TEXT REFERENCES courses(id) ON DELETE SET NULL, location TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, updated_at INTEGER NOT NULL, course_id TEXT REFERENCES courses(id) ON DELETE SET NULL)',
      );
      await db.execute(
        'CREATE TABLE focus_sessions (id TEXT PRIMARY KEY, minutes INTEGER NOT NULL, completed_at INTEGER NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
    },
  );
  static Future<StudyRepository> open() async =>
      StudyRepository(await platform.openPlatformDatabase(options));
  Future<List<Course>> courses() async =>
      (await db.query('courses', orderBy: 'name')).map(Course.fromMap).toList();
  Future<List<StudyEntry>> entries() async => (await db.query(
    'entries',
    orderBy: 'starts_at',
  )).map(StudyEntry.fromMap).toList();
  Future<List<StudyGroup>> groups() async => (await db.query(
    'groups_local',
    orderBy: 'meeting_at',
  )).map(StudyGroup.fromMap).toList();
  Future<List<Note>> notes() async => (await db.query(
    'notes',
    orderBy: 'updated_at DESC',
  )).map(Note.fromMap).toList();
  Future<List<FocusSession>> sessions() async => (await db.query(
    'focus_sessions',
    orderBy: 'completed_at',
  )).map(FocusSession.fromMap).toList();
  Future<Map<String, String>> settings() async => {
    for (final m in await db.query('settings'))
      m['key'] as String: m['value'] as String,
  };
  // UPDATE preserves foreign-key relationships; INSERT OR REPLACE would delete the parent.
  Future<void> save(String table, Map<String, Object?> values) =>
      db.transaction((txn) async {
        final count = await txn.update(
          table,
          values,
          where: 'id = ?',
          whereArgs: [values['id']],
        );
        if (count == 0) await txn.insert(table, values);
      });
  Future<void> remove(String table, String id) async {
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setting(String key, String value) async {
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> completeFocus(FocusSession session, String nextTimer) =>
      db.transaction((txn) async {
        await txn.insert(
          'focus_sessions',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await txn.insert('settings', {
          'key': 'timer',
          'value': nextTimer,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
  Future<void> start({required bool demo, DateTime? now}) => db.transaction((
    txn,
  ) async {
    // Demo is explicitly opted into, once, and never overwrites existing records.
    if ((await txn.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['onboarded'],
    )).isNotEmpty) {
      return;
    }
    if (demo) {
      final day = dayOf(now ?? DateTime.now());
      final courses = [
        const Course(
          id: 'demo-1',
          name: 'Datastrukturer & algoritmer',
          code: 'TDA417',
          color: 0,
        ),
        const Course(
          id: 'demo-2',
          name: 'Linjär algebra',
          code: 'MVE225',
          color: 1,
        ),
        const Course(
          id: 'demo-3',
          name: 'Objektorienterad programmering',
          code: 'TDA553',
          color: 2,
        ),
        const Course(
          id: 'demo-4',
          name: 'Introduktion till programmering',
          code: 'TDA548',
          color: 3,
          grade: '5',
        ),
      ];
      for (final c in courses) {
        await txn.insert('courses', c.toMap());
      }
      final examples = [
        StudyEntry(
          id: 'demo-e1',
          title: 'Föreläsning · Träd & grafer',
          kind: EntryKind.lecture,
          startsAt: day.add(const Duration(hours: 10)),
          endsAt: day.add(const Duration(hours: 11, minutes: 45)),
          courseId: 'demo-1',
          location: 'HC2, Hörsalsvägen',
        ),
        StudyEntry(
          id: 'demo-e2',
          title: 'Räkna tillsammans',
          kind: EntryKind.study,
          startsAt: day.add(const Duration(hours: 13)),
          endsAt: day.add(const Duration(hours: 14, minutes: 30)),
          courseId: 'demo-2',
          location: 'Biblioteket, grupprum 4',
        ),
        StudyEntry(
          id: 'demo-e3',
          title: 'Lab 3 · Binära sökträd',
          kind: EntryKind.deadline,
          startsAt: day.add(const Duration(days: 2, hours: 23, minutes: 59)),
          endsAt: day.add(const Duration(days: 2, hours: 23, minutes: 59)),
          courseId: 'demo-1',
          remindMinutes: 1440,
        ),
        StudyEntry(
          id: 'demo-e4',
          title: 'Tenta · Linjär algebra',
          kind: EntryKind.exam,
          startsAt: day.add(const Duration(days: 8, hours: 8, minutes: 30)),
          endsAt: day.add(const Duration(days: 8, hours: 12, minutes: 30)),
          courseId: 'demo-2',
          location: 'Johanneberg',
          remindMinutes: 1440,
        ),
        StudyEntry(
          id: 'demo-e5',
          title: 'Läs kapitel 4',
          kind: EntryKind.study,
          startsAt: day.add(const Duration(hours: 8)),
          endsAt: day.add(const Duration(hours: 9)),
          courseId: 'demo-3',
          done: true,
        ),
        StudyEntry(
          id: 'demo-e6',
          title: 'Workshop · Designmönster',
          kind: EntryKind.lecture,
          startsAt: day.add(const Duration(days: 1, hours: 10)),
          endsAt: day.add(const Duration(days: 1, hours: 12)),
          courseId: 'demo-3',
          location: 'EDIT, sal 3364',
        ),
      ];
      for (final e in examples) {
        await txn.insert('entries', e.toMap());
      }
      await txn.insert(
        'groups_local',
        StudyGroup(
          id: 'demo-g1',
          name: 'Linjär algebra-klubben',
          members: 'Du, Alex, Kim, Sam',
          meetingAt: day.add(const Duration(days: 1, hours: 15)),
          courseId: 'demo-2',
          location: 'Biblioteket · grupprum 4',
        ).toMap(),
      );
      await txn.insert(
        'notes',
        Note(
          id: 'demo-n1',
          title: 'Binära sökträd & komplexitet',
          body:
              'Ett binärt sökträd lagrar mindre värden i vänster delträd och större värden i höger delträd. Varje nod har högst två barn.\n\nSökning i ett balanserat binärt sökträd har tidskomplexiteten O(log n). I ett obalanserat träd kan sökning ta O(n) i värsta fall.\n\nInorder-traversering besöker vänster delträd, noden och sedan höger delträd. Resultatet är värdena i sorterad ordning.\n\nEn hashtabell har förväntad söktid O(1), men garanterar inte sorterad iteration.',
          updatedAt: day,
          courseId: 'demo-1',
        ).toMap(),
      );
      await txn.insert(
        'notes',
        Note(
          id: 'demo-n2',
          title: 'Egenvärden – repetition',
          body:
              'En egenvektor v till en kvadratisk matris A uppfyller Av = λv, där λ är ett egenvärde och v inte är nollvektorn.\n\nEgenvärden hittas genom att lösa den karakteristiska ekvationen det(A − λI) = 0.\n\nEn matris är diagonaliserbar om den har en bas av egenvektorer. Då kan den skrivas A = PDP⁻¹.',
          updatedAt: day,
          courseId: 'demo-2',
        ).toMap(),
      );
      for (var i = 0; i < 7; i++) {
        await txn.insert(
          'focus_sessions',
          FocusSession(
            id: 'demo-f$i',
            minutes: [25, 50, 75, 25, 100, 50, 50][i],
            completedAt: day
                .subtract(Duration(days: 6 - i))
                .add(const Duration(hours: 8)),
          ).toMap(),
        );
      }
    }
    await txn.insert('settings', {'key': 'onboarded', 'value': 'true'});
    await txn.insert('settings', {'key': 'demo', 'value': '$demo'});
  });
  Future<void> clearAll() => db.transaction((txn) async {
    for (final table in [
      'entries',
      'groups_local',
      'notes',
      'focus_sessions',
      'courses',
      'settings',
    ]) {
      await txn.delete(table);
    }
    await txn.insert('settings', {'key': 'onboarded', 'value': 'true'});
  });
}
