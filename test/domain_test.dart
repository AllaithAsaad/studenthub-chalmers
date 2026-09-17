import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studenthub_chalmers/domain/models.dart';
import 'package:studenthub_chalmers/domain/note_assistant.dart';

void main() {
  test(
    'credits and weighted grades exclude U, unfinished and G from numeric mean',
    () {
      final stats = StudyStats(
        [
          const Course(id: '1', name: 'A', code: 'A', credits: 15, grade: '5'),
          const Course(id: '2', name: 'B', code: 'B', credits: 7.5, grade: '3'),
          const Course(id: '3', name: 'C', code: 'C', grade: 'G'),
          const Course(id: '4', name: 'D', code: 'D', grade: 'U'),
          const Course(id: '5', name: 'E', code: 'E'),
        ],
        [],
        [],
      );
      expect(stats.earnedCredits, 30);
      expect(stats.weightedGrade, closeTo(4.33333, .0001));
      expect(StudyStats([], [], []).weightedGrade, isNull);
    },
  );
  test('reminders respect threshold, completion and disabled state', () {
    final start = DateTime(2026, 9, 17, 10);
    final e = StudyEntry(
      id: '1',
      title: 'Tenta',
      kind: EntryKind.exam,
      startsAt: start,
      endsAt: start,
      remindMinutes: 15,
    );
    expect(e.reminderDue(start.subtract(const Duration(minutes: 16))), isFalse);
    expect(e.reminderDue(start.subtract(const Duration(minutes: 15))), isTrue);
    expect(e.withDone(true).reminderDue(start), isFalse);
    final off = StudyEntry(
      id: '2',
      title: 'Tenta',
      kind: EntryKind.exam,
      startsAt: start,
      endsAt: start,
      remindMinutes: null,
    );
    expect(off.reminderDue(start), isFalse);
  });
  final notes = [
    Note(
      id: 'n',
      title: 'Träd',
      body:
          'Ett binärt sökträd har högst två barn.\n\nBalanserad sökning tar O(log n).',
      updatedAt: DateTime(2026),
      courseId: 'c1',
    ),
    Note(
      id: 'm',
      title: 'Matriser',
      body: 'Egenvärden löser den karakteristiska ekvationen.',
      updatedAt: DateTime(2026),
      courseId: 'c2',
    ),
  ];
  test(
    'retrieval cites actual passages, filters courses and refuses unrelated questions',
    () {
      final helper = NoteAssistant();
      final sources = helper.retrieve('Vad är ett binärt sökträd?', notes);
      expect(sources.single.note.id, 'n');
      expect(notes.first.body, contains(sources.single.passage));
      expect(helper.retrieve('Kvantmekanik?', notes), isEmpty);
      expect(helper.retrieve('Vad är det?', notes), isEmpty);
      expect(helper.retrieve('binärt sökträd', notes, courseId: 'c2'), isEmpty);
    },
  );
  test(
    'Ollama sends only retrieved context to localhost, not all notes',
    () async {
      final helper = NoteAssistant();
      final sources = helper.retrieve('binärt sökträd', notes);
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:11434/api/chat');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['stream'], isFalse);
        expect(request.body, contains('högst två barn'));
        expect(request.body, isNot(contains('karakteristiska')));
        return http.Response(
          jsonEncode({
            'message': {'content': 'Ett träd med högst två barn [1].'},
          }),
          200,
        );
      });
      expect(
        await helper.askLocalAi(
          'binärt sökträd',
          sources,
          model: 'test-model',
          client: client,
        ),
        contains('[1]'),
      );
      client.close();
    },
  );
  test(
    'Ollama failures are surfaced and empty sources never call network',
    () async {
      final helper = NoteAssistant();
      final client = MockClient((_) async => http.Response('{}', 500));
      expect(
        () => helper.askLocalAi(
          'binärt',
          helper.retrieve('binärt', notes),
          model: 'x',
          client: client,
        ),
        throwsFormatException,
      );
      expect(
        await helper.askLocalAi('unrelated', [], model: 'x', client: client),
        contains('inget relevant'),
      );
      client.close();
    },
  );
}
