import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../domain/store.dart';
import '../domain/focus_timer.dart';
import 'design.dart';
import 'editors.dart';

class EntryRow extends StatelessWidget {
  const EntryRow(this.entry, this.store, {super.key, this.showDate = false});
  final StudyEntry entry;
  final StudyStore store;
  final bool showDate;
  @override
  Widget build(BuildContext context) {
    final course = store.course(entry.courseId);
    final color = courseColors[(course?.color ?? 0) % courseColors.length];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          if (showDate)
            SizedBox(
              width: 53,
              child: Column(
                children: [
                  Text(
                    '${entry.startsAt.day}',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMM',
                      'sv',
                    ).format(entry.startsAt).toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 49,
              child: Text(
                timeLabel(entry.startsAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            width: 3,
            height: 49,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: entry.done ? line : color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => editEntry(context, store, old: entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: entry.done ? muted : ink,
                        decoration: entry.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (course != null) course.code,
                        if (entry.location.isNotEmpty) entry.location,
                        if (showDate) timeLabel(entry.startsAt),
                      ].join('  ·  '),
                      style: const TextStyle(fontSize: 11, color: muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Checkbox(
            value: entry.done,
            semanticLabel:
                '${entry.done ? 'Markera som ej klar' : 'Markera klar'}: ${entry.title}',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (v) =>
                runAction(context, () => store.saveEntry(entry.withDone(v!))),
          ),
          PopupMenuButton<String>(
            tooltip: 'Alternativ för ${entry.title}',
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Redigera')),
              PopupMenuItem(value: 'delete', child: Text('Ta bort')),
            ],
            onSelected: (v) => v == 'edit'
                ? editEntry(context, store, old: entry)
                : confirmDelete(
                    context,
                    store,
                    'entries',
                    entry.id,
                    entry.title,
                  ),
            iconSize: 17,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.store,
    required this.timer,
    required this.navigate,
  });
  final StudyStore store;
  final FocusTimer timer;
  final ValueChanged<int> navigate;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = store.entries.where((e) => sameDay(e.startsAt, now)).toList();
    final upcoming = store.entries
        .where(
          (e) =>
              !e.done && [EntryKind.exam, EntryKind.deadline].contains(e.kind),
        )
        .take(3)
        .toList();
    final firstName = store.settings['name']?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          firstName == null || firstName.isEmpty
              ? 'Din dag, lite enklare.'
              : 'Hej, $firstName.',
          'Här får dina studier lite mer struktur.',
          action: OutlinedButton.icon(
            onPressed: () => editEntry(context, store),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Lägg till aktivitet'),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: forest,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -18,
                bottom: -20,
                width: 360,
                child: Opacity(
                  opacity: MediaQuery.sizeOf(context).width < 650 ? .12 : 1,
                  child: const IgnorePointer(
                    child: CustomPaint(painter: _OrbitPainter()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: lime),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'PLATS FÖR BÅDE STUDIER OCH LIVET',
                            style: TextStyle(
                              color: lime,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Lite struktur.\nMer studentliv.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        height: 1.13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'En sak i taget. Du har det här.',
                      style: TextStyle(color: Color(0xFFB7CEC0), fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: forest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () => navigate(1),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Planera min vecka'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, box) {
            final metrics = [
              MetricCard(
                'Aktiva kurser',
                '${store.courses.where((c) => !c.passed).length}',
                'Nyfikenhet i rörelse',
                Icons.menu_book_outlined,
                green,
              ),
              MetricCard(
                'Dagens aktiviteter',
                '${today.where((e) => e.done).length}/${today.length}',
                'Avklarade idag',
                Icons.check_circle_outline,
                const Color(0xFFB48D4D),
              ),
              MetricCard(
                'Fokus idag',
                '${store.stats.focusOn(now)}',
                'Minuter för dina mål',
                Icons.timelapse_outlined,
                const Color(0xFF7D76A6),
              ),
              MetricCard(
                'Avklarade poäng',
                numberLabel(store.stats.earnedCredits),
                'Högskolepoäng hittills',
                Icons.school_outlined,
                const Color(0xFF6585A0),
              ),
            ];
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: metrics
                  .map(
                    (w) => SizedBox(
                      width:
                          (box.maxWidth - (box.maxWidth > 850 ? 42 : 14)) /
                          (box.maxWidth > 850 ? 4 : 2),
                      child: w,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        ResponsiveColumns(
          left: Column(
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      'På schemat idag',
                      subtitle: DateFormat('EEEE d MMMM', 'sv').format(now),
                      action: TextButton(
                        onPressed: () => navigate(1),
                        child: const Text(
                          'Visa schema →',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (today.isEmpty)
                      EmptyState(
                        'En öppen dag',
                        'Planera något litet som tar dig framåt.',
                        action: OutlinedButton(
                          onPressed: () => editEntry(context, store),
                          child: const Text('Planera ett studiepass'),
                        ),
                      )
                    else
                      ...today.map((e) => EntryRow(e, store)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      'Nästa hållpunkter',
                      action: TextButton(
                        onPressed: () => navigate(1),
                        child: const Text(
                          'Visa alla →',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (upcoming.isEmpty)
                      const EmptyState(
                        'Inget att jaga just nu',
                        'Dina tentor och deadlines dyker upp här.',
                      )
                    else
                      ...upcoming.map(
                        (e) => EntryRow(e, store, showDate: true),
                      ),
                  ],
                ),
              ),
            ],
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusCard(timer: timer, compact: true),
              const SizedBox(height: 22),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: green,
                      size: 24,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Bättre tillsammans',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      store.groups.isEmpty
                          ? 'Hitta tid för ett gemensamt studiepass.'
                          : '${store.groups.length} studiegrupp${store.groups.length == 1 ? '' : 'er'} att tänka högt med.',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => navigate(3),
                      child: const Text('Mina studiegrupper  ↗'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spa_outlined, size: 14, color: muted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Små steg räknas också. Kom ihåg att ta en paus.',
                style: const TextStyle(color: muted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
    this.label,
    this.value,
    this.caption,
    this.icon,
    this.color, {
    super.key,
  });
  final String label, value, caption;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    padding: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ),
            Icon(icon, size: 18, color: color),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 5),
        Text(caption, style: const TextStyle(fontSize: 10, color: muted)),
      ],
    ),
  );
}

class FocusCard extends StatelessWidget {
  const FocusCard({super.key, required this.timer, this.compact = false});
  final FocusTimer timer;
  final bool compact;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: timer,
    builder: (context, _) => Panel(
      color: const Color(0xFFF1F1E7),
      padding: compact ? 22 : 32,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_center_focus, size: 18, color: green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dags för lite fokus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Pill(timer.isBreak ? 'PAUS' : 'POMODORO'),
            ],
          ),
          const SizedBox(height: 24),
          Semantics(
            label: '${timer.isBreak ? 'Paus' : 'Fokus'}: ${timer.display}',
            child: SizedBox(
              width: compact ? 178 : 230,
              height: compact ? 178 : 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1 - timer.remaining / (timer.minutes * 60),
                      strokeWidth: 5,
                      color: green,
                      backgroundColor: const Color(0xFFDBE0CE),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timer.display,
                        style: TextStyle(
                          fontSize: compact ? 39 : 53,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.7,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timer.running
                            ? 'En sak i taget'
                            : timer.isBreak
                            ? 'Andas ut en stund'
                            : 'Redo när du är',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: timer.busy
                    ? null
                    : () => runAction(context, timer.toggle),
                icon: Icon(
                  timer.running ? Icons.pause : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(
                  timer.running
                      ? 'Pausa'
                      : timer.isBreak
                      ? 'Starta paus'
                      : 'Starta fokus',
                ),
              ),
              const SizedBox(width: 9),
              IconButton(
                tooltip: 'Återställ timer',
                onPressed: timer.busy
                    ? null
                    : () => runAction(
                        context,
                        () => timer.select(
                          rest: timer.isBreak,
                          length: timer.minutes,
                        ),
                      ),
                icon: const Icon(Icons.restart_alt, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children:
                [
                      (false, 25, '25 min'),
                      (false, 50, '50 min'),
                      (true, 5, 'Kort paus'),
                    ]
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m.$3, style: const TextStyle(fontSize: 10)),
                        selected:
                            timer.minutes == m.$2 && timer.isBreak == m.$1,
                        showCheckmark: false,
                        onSelected: timer.running || timer.busy
                            ? null
                            : (_) => runAction(
                                context,
                                () => timer.select(rest: m.$1, length: m.$2),
                              ),
                      ),
                    )
                    .toList(),
          ),
          if (timer.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                timer.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .62, size.height * .5);
    final paint = Paint()
      ..color = const Color(0xFF3A6252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, 60.0 + i * 35, paint);
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.25);
    for (var i = 0; i < 3; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-15 + i * 15.0, 35 - i * 35.0),
          width: 124,
          height: 37,
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = [const Color(0xFF527968), const Color(0xFFB5C994), lime][i],
      );
      canvas.drawLine(
        Offset(-65 + i * 15.0, 34 - i * 35.0),
        Offset(30 + i * 15.0, 34 - i * 35.0),
        Paint()
          ..color = forest.withValues(alpha: .2)
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
    for (final a in [0.3, 2.4, 4.4]) {
      final p = center + Offset(math.cos(a) * 132, math.sin(a) * 132);
      canvas.drawCircle(p, 4, Paint()..color = lime.withValues(alpha: .65));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
