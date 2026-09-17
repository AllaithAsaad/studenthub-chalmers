import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'store.dart';

/// Wall-clock based: timer throttling or leaving the page never adds study time.
/// Completion and the next timer state are committed in one SQLite transaction.
class FocusTimer extends ChangeNotifier {
  FocusTimer(this.store, {DateTime Function()? clock, bool autoTick = true})
    : clock = clock ?? DateTime.now {
    final saved = store.settings['timer'];
    if (saved != null) {
      try {
        final m = jsonDecode(saved) as Map<String, dynamic>;
        minutes = m['minutes'] as int;
        remaining = m['remaining'] as int;
        isBreak = m['isBreak'] as bool;
        sessionId = m['id'] as String;
        deadline = m['deadline'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['deadline'] as int);
      } catch (_) {
        remaining = 25 * 60;
        minutes = 25;
        deadline = null;
      }
    }
    if (autoTick) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }
  final StudyStore store;
  final DateTime Function() clock;
  Timer? _ticker;
  DateTime? deadline;
  int minutes = 25, remaining = 25 * 60;
  bool isBreak = false, busy = false;
  String sessionId = newId();
  String? error;
  bool get running => deadline != null;
  String get display =>
      '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
  String serialize({
    bool? breakValue,
    int? remainingValue,
    DateTime? end,
    bool useEnd = false,
    String? id,
    int? length,
  }) => jsonEncode({
    'minutes': length ?? minutes,
    'remaining': remainingValue ?? remaining,
    'isBreak': breakValue ?? isBreak,
    'id': id ?? sessionId,
    'deadline': (useEnd ? end : deadline)?.millisecondsSinceEpoch,
  });
  Future<void> toggle() async {
    if (busy) return;
    if (running) {
      await tick();
      // A completed session transitions to a paused break; don't start it here.
      if (!running || busy) return;
    }
    busy = true;
    final target = running ? null : clock().add(Duration(seconds: remaining));
    final value = serialize(end: target, useEnd: true);
    try {
      await store.setSetting('timer', value);
      deadline = target;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> select({required bool rest, required int length}) async {
    if (busy) return;
    if (length <= 0) throw ArgumentError.value(length, 'length');
    busy = true;
    final id = newId();
    try {
      await store.setSetting(
        'timer',
        serialize(
          breakValue: rest,
          remainingValue: length * 60,
          end: null,
          useEnd: true,
          id: id,
          length: length,
        ),
      );
      isBreak = rest;
      minutes = length;
      remaining = length * 60;
      deadline = null;
      sessionId = id;
      error = null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> tick() async {
    if (deadline == null || busy) return;
    remaining = ((deadline!.difference(clock()).inMilliseconds) / 1000)
        .ceil()
        .clamp(0, minutes * 60);
    if (remaining == 0) {
      busy = true;
      final nextId = newId();
      final nextBreak = !isBreak;
      final nextMinutes = nextBreak ? 5 : 25;
      final next = serialize(
        breakValue: nextBreak,
        remainingValue: nextMinutes * 60,
        end: null,
        useEnd: true,
        id: nextId,
        length: nextMinutes,
      );
      try {
        if (!isBreak) {
          await store.repository.completeFocus(
            FocusSession(
              id: sessionId,
              minutes: minutes,
              completedAt: deadline!,
            ),
            next,
          );
        } else {
          await store.repository.setting('timer', next);
        }
        deadline = null;
        isBreak = nextBreak;
        minutes = nextMinutes;
        remaining = nextMinutes * 60;
        sessionId = nextId;
        error = null;
        await store.load();
      } catch (_) {
        error =
            'Passet kunde inte sparas. Försöker igen när lagringen är tillgänglig.';
      } finally {
        busy = false;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
