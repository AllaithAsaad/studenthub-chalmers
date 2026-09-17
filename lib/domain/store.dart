import 'package:flutter/foundation.dart';
import '../data/repository.dart';
import 'models.dart';

class StudyStore extends ChangeNotifier {
  StudyStore(this.repository);
  final StudyRepository repository;
  List<Course> courses = [];
  List<StudyEntry> entries = [];
  List<StudyGroup> groups = [];
  List<Note> notes = [];
  List<FocusSession> sessions = [];
  Map<String, String> settings = {};
  StudyStats get stats => StudyStats(courses, entries, sessions);
  Course? course(String? id) => courses.where((c) => c.id == id).firstOrNull;
  Future<void> load() async {
    courses = await repository.courses();
    entries = await repository.entries();
    groups = await repository.groups();
    notes = await repository.notes();
    sessions = await repository.sessions();
    settings = await repository.settings();
    notifyListeners();
  }

  Future<void> saveCourse(Course value) async {
    await repository.save('courses', value.toMap());
    await load();
  }

  Future<void> saveEntry(StudyEntry value) async {
    await repository.save('entries', value.toMap());
    await load();
  }

  Future<void> saveGroup(StudyGroup value) async {
    await repository.save('groups_local', value.toMap());
    await load();
  }

  Future<void> saveNote(Note value) async {
    await repository.save('notes', value.toMap());
    await load();
  }

  Future<void> remove(String table, String id) async {
    await repository.remove(table, id);
    await load();
  }

  Future<void> setSetting(String key, String value) async {
    await repository.setting(key, value);
    settings[key] = value;
    notifyListeners();
  }

  Future<void> start(bool demo) async {
    await repository.start(demo: demo);
    await load();
  }
}
