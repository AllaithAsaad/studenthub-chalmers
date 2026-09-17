import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../domain/store.dart';
import '../domain/focus_timer.dart';
import 'design.dart';
import 'editors.dart';
import 'overview.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key, required this.store});
  final StudyStore store;
  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  DateTime anchor = dayOf(DateTime.now());
  DateTime? selected;
  EntryKind? filter;
  bool list = false, showDone = true;
  @override
  Widget build(BuildContext context) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final end = DateTime(monday.year, monday.month, monday.day + 7);
    final entries = widget.store.entries
        .where(
          (e) =>
              (filter == null || e.kind == filter) &&
              (showDone || !e.done) &&
              (list ||
                  (!e.startsAt.isBefore(monday) && e.startsAt.isBefore(end))) &&
              (selected == null || list || sameDay(e.startsAt, selected!)),
        )
        .toList();
    final days = entries.map((e) => dayOf(e.startsAt)).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Gör plats för det viktiga.',
          'Tentor, deadlines och allt däremellan.',
          action: FilledButton.icon(
            onPressed: () =>
                editEntry(context, widget.store, initialDate: selected),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Ny aktivitet'),
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 16,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Föregående vecka',
                        onPressed: () => setState(() {
                          anchor = DateTime(
                            anchor.year,
                            anchor.month,
                            anchor.day - 7,
                          );
                          selected = null;
                          list = false;
                        }),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Flexible(
                        child: Text(
                          '${dateLabel(monday)} – ${dateLabel(end.subtract(const Duration(days: 1)))}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Nästa vecka',
                        onPressed: () => setState(() {
                          anchor = DateTime(
                            anchor.year,
                            anchor.month,
                            anchor.day + 7,
                          );
                          selected = null;
                          list = false;
                        }),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Vecka')),
                      ButtonSegment(value: true, label: Text('Alla datum')),
                    ],
                    selected: {list},
                    onSelectionChanged: (v) => setState(() {
                      list = v.first;
                      selected = null;
                    }),
                  ),
                ],
              ),
              if (!list) ...[
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, box) => Row(
                    children: List.generate(7, (i) {
                      final date = DateTime(
                        monday.year,
                        monday.month,
                        monday.day + i,
                      );
                      final active =
                          selected != null && sameDay(selected!, date);
                      final today = sameDay(date, DateTime.now());
                      final count = widget.store.entries
                          .where((e) => sameDay(e.startsAt, date))
                          .length;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 6 ? 0 : 5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () =>
                                setState(() => selected = active ? null : date),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: active
                                    ? forest
                                    : today
                                    ? const Color(0xFFEAF0E6)
                                    : canvas,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat(
                                      box.maxWidth < 440 ? 'EEEEE' : 'EEE',
                                      'sv',
                                    ).format(date).toUpperCase(),
                                    style: TextStyle(
                                      color: active ? Colors.white70 : muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: active ? Colors.white : ink,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: count > 0
                                          ? active
                                                ? lime
                                                : green
                                          : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Alla'),
                    selected: filter == null,
                    onSelected: (_) => setState(() => filter = null),
                  ),
                  ...EntryKind.values.map(
                    (k) => ChoiceChip(
                      label: Text(k.label),
                      selected: filter == k,
                      onSelected: (_) => setState(() => filter = k),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Visa klara'),
                    selected: showDone,
                    onSelected: (v) => setState(() => showDone = v),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      anchor = dayOf(DateTime.now());
                      selected = anchor;
                      list = false;
                    }),
                    child: const Text('Idag'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (entries.isEmpty)
          Panel(
            child: EmptyState(
              'Lite luft i planeringen',
              'Inga aktiviteter matchar den här vyn.',
              icon: Icons.event_available_outlined,
              action: OutlinedButton(
                onPressed: () =>
                    editEntry(context, widget.store, initialDate: selected),
                child: const Text('Lägg till en aktivitet'),
              ),
            ),
          )
        else
          ...days.map(
            (day) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(DateFormat('EEEE d MMMM', 'sv').format(day)),
                    ...entries
                        .where((e) => sameDay(e.startsAt, day))
                        .map((e) => EntryRow(e, widget.store)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key, required this.store});
  final StudyStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeading(
        'Dina kurser. Din riktning.',
        'Samla kurser, högskolepoäng och resultat.',
        action: FilledButton.icon(
          onPressed: () => editCourse(context, store),
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Lägg till kurs'),
        ),
      ),
      if (store.courses.isEmpty)
        const Panel(
          child: EmptyState(
            'Första kursen är början',
            'Lägg till en kurs för att samla din planering.',
            icon: Icons.menu_book_outlined,
          ),
        )
      else
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 20,
            runSpacing: 20,
            children: store.courses.map((c) {
              final color = courseColors[c.color % courseColors.length];
              final entries = store.entries.where((e) => e.courseId == c.id);
              final completed = entries.where((e) => e.done).length;
              return SizedBox(
                width: box.maxWidth > 780
                    ? (box.maxWidth - 20) / 2
                    : box.maxWidth,
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(Icons.menu_book_outlined, color: color),
                          ),
                          const Spacer(),
                          Pill(c.code, color: color),
                          PopupMenuButton<String>(
                            tooltip: 'Alternativ för ${c.name}',
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Redigera / sätt betyg'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Ta bort'),
                              ),
                            ],
                            onSelected: (v) => v == 'edit'
                                ? editCourse(context, store, c)
                                : confirmDelete(
                                    context,
                                    store,
                                    'courses',
                                    c.id,
                                    c.name,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 23),
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Text(
                            '${numberLabel(c.credits)} hp',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Pill(
                            c.passed
                                ? 'Avklarad · ${c.grade}'
                                : c.grade == 'U'
                                ? 'Resultat U'
                                : 'Pågående',
                            color: c.passed ? green : color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          const Text(
                            'Aktiviteter',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                          const Spacer(),
                          Text(
                            '$completed av ${entries.length} klara',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: entries.isEmpty ? 0 : completed / entries.length,
                        color: color,
                        backgroundColor: canvas,
                        borderRadius: BorderRadius.circular(5),
                        minHeight: 5,
                      ),
                      const SizedBox(height: 17),
                      TextButton(
                        onPressed: () => editCourse(context, store, c),
                        child: const Text('Visa och redigera kurs  →'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
    ],
  );
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key, required this.store});
  final StudyStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeading(
        'Tänk högt. Tillsammans.',
        'Planera era träffar och samla gruppen.',
        action: FilledButton.icon(
          onPressed: () => editGroup(context, store),
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Ny studiegrupp'),
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Text(
          'Dina grupper är lokala. Medlemmar och träffar läggs in manuellt.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ),
      if (store.groups.isEmpty)
        const Panel(
          child: EmptyState(
            'Vem pluggar du med?',
            'Skapa en grupp och planera er första träff.',
            icon: Icons.groups_outlined,
          ),
        )
      else
        ...store.groups.map((g) {
          final members = g.members
              .split(',')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty)
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Alternativ för ${g.name}',
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Redigera')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Ta bort'),
                          ),
                        ],
                        onSelected: (v) => v == 'edit'
                            ? editGroup(context, store, g)
                            : confirmDelete(
                                context,
                                store,
                                'groups_local',
                                g.id,
                                g.name,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Pill(
                    store.course(g.courseId)?.name ?? 'Fristående studiegrupp',
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members
                        .map(
                          (m) => Chip(
                            avatar: CircleAvatar(
                              backgroundColor: const Color(0xFFE4EAD7),
                              child: Text(
                                m.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: forest,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            label: Text(m),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      Text(
                        'Nästa träff · ${dateLabel(g.meetingAt)}, ${timeLabel(g.meetingAt)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (g.location.isNotEmpty)
                        Text(
                          g.location,
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => editGroup(context, store, g),
                    child: const Text('Planera nästa träff →'),
                  ),
                ],
              ),
            ),
          );
        }),
    ],
  );
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.store});
  final StudyStore store;
  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Se hur långt du har kommit.',
          'Små steg blir stora framsteg över tid.',
        ),
        LayoutBuilder(
          builder: (context, box) {
            final cards = [
              MetricCard(
                'Avklarade poäng',
                '${numberLabel(stats.earnedCredits)} hp',
                'Av ${numberLabel(stats.totalCredits)} registrerade hp',
                Icons.school_outlined,
                green,
              ),
              MetricCard(
                'Betygssnitt',
                stats.weightedGrade == null
                    ? '—'
                    : NumberFormat('0.00', 'sv').format(stats.weightedGrade!),
                'Poängviktat · betyg 3–5',
                Icons.insights,
                const Color(0xFFB48D4D),
              ),
              MetricCard(
                'Fokus totalt',
                '${store.sessions.fold<int>(0, (s, f) => s + f.minutes)} min',
                '${store.sessions.length} slutförda pass',
                Icons.timelapse,
                const Color(0xFF8580B1),
              ),
            ];
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: cards
                  .map(
                    (c) => SizedBox(
                      width: box.maxWidth >= 700
                          ? (box.maxWidth - 32) / 3
                          : box.maxWidth,
                      child: c,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading(
                'En vecka av fokus',
                subtitle: 'Slutförda fokusminuter per dag · senaste 7 dagarna',
              ),
              FocusChart(store: store, now: now),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading(
                'Dina kursresultat',
                subtitle: 'Registrera resultat genom att redigera en kurs.',
              ),
              if (store.courses.isEmpty)
                const EmptyState(
                  'Här växer dina framsteg fram',
                  'Lägg till kurser för att komma igång.',
                )
              else
                ...store.courses.map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      c.passed
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      color: c.passed ? green : muted,
                    ),
                    title: Text(c.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${c.code} · ${numberLabel(c.credits)} hp',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    trailing: Text(
                      c.grade ?? 'Pågående',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => editCourse(context, store, c),
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'Betygssnittet väger godkända sifferbetyg efter kursens hp. G ger avklarade poäng, men ingår inte i snittet. Uppgifterna är självrapporterade.',
                style: TextStyle(color: muted, height: 1.5, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FocusChart extends StatelessWidget {
  const FocusChart({super.key, required this.store, required this.now});
  final StudyStore store;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final values = days.map(store.stats.focusOn).toList();
    final max = values.fold<int>(25, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.indexed
            .map(
              (d) => Expanded(
                child: Semantics(
                  label: '${dateLabel(d.$2)}: ${values[d.$1]} fokusminuter',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[d.$1]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 8 + 130 * values[d.$1] / max,
                          constraints: const BoxConstraints(maxWidth: 64),
                          decoration: BoxDecoration(
                            color: d.$1 == 6 ? forest : const Color(0xFFDDE6D9),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('EEE', 'sv').format(d.$2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class FocusPage extends StatelessWidget {
  const FocusPage({super.key, required this.store, required this.timer});
  final StudyStore store;
  final FocusTimer timer;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PageHeading(
        'En sak i taget.',
        'Ge din uppmärksamhet lite utrymme.',
      ),
      ResponsiveColumns(
        leftFlex: 1,
        left: FocusCard(timer: timer),
        right: Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading('Din fokusvecka'),
              FocusChart(store: store, now: DateTime.now()),
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Så funkar det',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
              ),
              const SizedBox(height: 15),
              const Text(
                '1. Välj en tydlig, lagom stor uppgift.\n\n2. Fokusera i 25 minuter.\n\n3. Ta en kort paus och börja om.',
                style: TextStyle(color: muted, height: 1.6, fontSize: 13),
              ),
              const SizedBox(height: 22),
              const Text(
                'Timern sparas när du navigerar eller stänger appen. Ett avslutat fokuspass registreras när appen körs igen. Pauser startar du själv.',
                style: TextStyle(color: muted, fontSize: 11, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store, required this.timer});
  final StudyStore store;
  final FocusTimer timer;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final name = TextEditingController(
    text: widget.store.settings['name'] ?? '',
  );
  late final model = TextEditingController(
    text: widget.store.settings['ollamaModel'] ?? 'gemma3',
  );
  @override
  void dispose() {
    name.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PageHeading(
        'Ditt StudentHub.',
        'Små inställningar för en personlig studieplats.',
      ),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading('Om dig'),
            field(name, 'Förnamn (valfritt)'),
            FilledButton(
              onPressed: () => runAction(
                context,
                () => widget.store.setSetting('name', name.text.trim()),
                success: 'Ditt namn har sparats.',
              ),
              child: const Text('Spara profil'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              'Lokal AI med Ollama',
              subtitle: 'Valfritt · källsökning fungerar utan AI',
            ),
            const Text(
              'Frågehjälpen kan använda en AI-modell på din dator. Installera Ollama och en modell, ange modellnamnet nedan och välj sedan Lokal AI i Anteckningar. Endast frågan och relevanta källutdrag skickas till localhost:11434.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 18),
            field(model, 'Installerad Ollama-modell'),
            FilledButton(
              onPressed: () => runAction(context, () async {
                if (model.text.trim().isEmpty) {
                  throw const FormatException('Modellnamn krävs');
                }
                await widget.store.setSetting('ollamaModel', model.text.trim());
              }, success: 'Modellnamnet har sparats.'),
              child: const Text('Spara AI-inställning'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Rekommenderat på macOS eller localhost i webbläsaren. På mobilen avser localhost själva telefonen. Se README för installation och webbläsarens CORS-inställning.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading('Din data stannar här'),
            Text(
              'Kurser, anteckningar och planering sparas lokalt i SQLite. Ingen inloggning och ingen automatisk synkronisering. Webbläsarens lagring hör till adressen och porten och kan raderas av webbläsaren.\n\nPåminnelser visas i appen. Studiegrupper hanteras manuellt och är inte delade mellan användare.\n\nStudentHub är ett självständigt studentprojekt och är inte anslutet till eller godkänt av Chalmers tekniska högskola.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.7),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading('Börja om'),
            const Text(
              'Radera all lokal data, inklusive egna ändringar och exempeldata.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () async {
                final accepted = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Radera all lokal data?'),
                    content: const Text(
                      'Alla kurser, anteckningar, grupper och fokuspass tas bort. Det går inte att ångra.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Behåll mina data'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Radera och börja om'),
                      ),
                    ],
                  ),
                );
                if (accepted == true && context.mounted) {
                  await runAction(
                    context,
                    () async {
                      await widget.timer.select(rest: false, length: 25);
                      await widget.store.repository.clearAll();
                      await widget.store.load();
                      name.clear();
                      model.text = 'gemma3';
                    },
                    success: 'Klart. Nu börjar du med ett tomt StudentHub.',
                  );
                }
              },
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Radera lokal data'),
            ),
          ],
        ),
      ),
    ],
  );
}
