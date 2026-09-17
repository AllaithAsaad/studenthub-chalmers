import 'dart:math';

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff)}';
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);

enum EntryKind {
  exam('Tenta'),
  deadline('Deadline'),
  lecture('Föreläsning'),
  study('Studiepass');

  const EntryKind(this.label);
  final String label;
}

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.code,
    this.credits = 7.5,
    this.color = 0,
    this.grade,
  });
  final String id, name, code;
  final double credits;
  final int color;
  final String? grade;
  bool get passed => ['3', '4', '5', 'G'].contains(grade);
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'code': code,
    'credits': credits,
    'color': color,
    'grade': grade,
  };
  factory Course.fromMap(Map<String, Object?> m) => Course(
    id: m['id'] as String,
    name: m['name'] as String,
    code: m['code'] as String,
    credits: (m['credits'] as num).toDouble(),
    color: m['color'] as int,
    grade: m['grade'] as String?,
  );
}

class StudyEntry {
  const StudyEntry({
    required this.id,
    required this.title,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    this.courseId,
    this.location = '',
    this.done = false,
    this.remindMinutes = 15,
  });
  final String id, title, location;
  final String? courseId;
  final EntryKind kind;
  final DateTime startsAt, endsAt;
  final bool done;
  final int? remindMinutes;
  StudyEntry withDone(bool value) => StudyEntry(
    id: id,
    title: title,
    kind: kind,
    startsAt: startsAt,
    endsAt: endsAt,
    courseId: courseId,
    location: location,
    done: value,
    remindMinutes: remindMinutes,
  );
  bool reminderDue(DateTime now) =>
      !done &&
      remindMinutes != null &&
      !now.isBefore(startsAt.subtract(Duration(minutes: remindMinutes!)));
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'starts_at': startsAt.millisecondsSinceEpoch,
    'ends_at': endsAt.millisecondsSinceEpoch,
    'course_id': courseId,
    'location': location,
    'done': done ? 1 : 0,
    'remind_minutes': remindMinutes,
  };
  factory StudyEntry.fromMap(Map<String, Object?> m) => StudyEntry(
    id: m['id'] as String,
    title: m['title'] as String,
    kind: EntryKind.values.byName(m['kind'] as String),
    startsAt: DateTime.fromMillisecondsSinceEpoch(m['starts_at'] as int),
    endsAt: DateTime.fromMillisecondsSinceEpoch(m['ends_at'] as int),
    courseId: m['course_id'] as String?,
    location: m['location'] as String,
    done: m['done'] == 1,
    remindMinutes: m['remind_minutes'] as int?,
  );
}

class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.meetingAt,
    this.courseId,
    this.location = '',
  });
  final String id, name, members, location;
  final String? courseId;
  final DateTime meetingAt;
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'members': members,
    'meeting_at': meetingAt.millisecondsSinceEpoch,
    'course_id': courseId,
    'location': location,
  };
  factory StudyGroup.fromMap(Map<String, Object?> m) => StudyGroup(
    id: m['id'] as String,
    name: m['name'] as String,
    members: m['members'] as String,
    meetingAt: DateTime.fromMillisecondsSinceEpoch(m['meeting_at'] as int),
    courseId: m['course_id'] as String?,
    location: m['location'] as String,
  );
}

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.courseId,
  });
  final String id, title, body;
  final String? courseId;
  final DateTime updatedAt;
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': updatedAt.millisecondsSinceEpoch,
    'course_id': courseId,
  };
  factory Note.fromMap(Map<String, Object?> m) => Note(
    id: m['id'] as String,
    title: m['title'] as String,
    body: m['body'] as String,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    courseId: m['course_id'] as String?,
  );
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.minutes,
    required this.completedAt,
  });
  final String id;
  final int minutes;
  final DateTime completedAt;
  Map<String, Object?> toMap() => {
    'id': id,
    'minutes': minutes,
    'completed_at': completedAt.millisecondsSinceEpoch,
  };
  factory FocusSession.fromMap(Map<String, Object?> m) => FocusSession(
    id: m['id'] as String,
    minutes: m['minutes'] as int,
    completedAt: DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
  );
}

class StudyStats {
  StudyStats(this.courses, this.entries, this.sessions);
  final List<Course> courses;
  final List<StudyEntry> entries;
  final List<FocusSession> sessions;
  double get earnedCredits =>
      courses.where((c) => c.passed).fold(0, (s, c) => s + c.credits);
  double get totalCredits => courses.fold(0, (s, c) => s + c.credits);
  double? get weightedGrade {
    final numeric = courses.where(
      (c) => c.passed && double.tryParse(c.grade ?? '') != null,
    );
    final credits = numeric.fold<double>(0, (s, c) => s + c.credits);
    return credits == 0
        ? null
        : numeric.fold<double>(
                0,
                (s, c) => s + c.credits * double.parse(c.grade!),
              ) /
              credits;
  }

  int focusOn(DateTime day) => sessions
      .where((s) => sameDay(s.completedAt, day))
      .fold(0, (s, f) => s + f.minutes);
}
