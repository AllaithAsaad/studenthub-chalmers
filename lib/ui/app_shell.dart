import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../domain/store.dart';
import '../domain/focus_timer.dart';
import 'design.dart';
import 'editors.dart';
import 'overview.dart';
import 'pages.dart';
import 'notes_page.dart';

const destinations = [
  (Icons.grid_view_rounded, 'Översikt'),
  (Icons.calendar_month_outlined, 'Planering'),
  (Icons.menu_book_outlined, 'Mina kurser'),
  (Icons.people_outline, 'Studiegrupper'),
  (Icons.auto_stories_outlined, 'Anteckningar'),
  (Icons.timelapse_outlined, 'Fokus & Pomodoro'),
  (Icons.bar_chart_rounded, 'Statistik'),
  (Icons.settings_outlined, 'Inställningar'),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final StudyStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int selected = 0;
  late final FocusTimer timer;
  Timer? reminders;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    timer = FocusTimer(widget.store);
    WidgetsBinding.instance.addObserver(this);
    reminders = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      timer.tick();
      setState(() {});
    }
  }

  @override
  void dispose() {
    timer.dispose();
    reminders?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void navigate(int index) {
    setState(() => selected = index);
  }

  List<StudyEntry> get due =>
      widget.store.entries.where((e) => e.reminderDue(DateTime.now())).toList();
  Future<void> showReminders() => showDialog(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => AlertDialog(
        title: const Text('Dina påminnelser'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Aktiviteter vars påminnelsetid har passerat visas tills de markeras klara.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 16),
                if (due.isEmpty)
                  const EmptyState('Du är i fas', 'Inga påminnelser just nu.')
                else
                  ...due.map((e) => EntryRow(e, widget.store, showDate: true)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stäng'),
          ),
        ],
      ),
    ),
  );
  Widget sidebar({bool drawer = false}) => Container(
    width: 225,
    color: forest,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 31, 24, 36),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lime,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: forest,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'studenthub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.8,
                          ),
                        ),
                        Text(
                          'C H A L M E R S',
                          style: TextStyle(
                            color: Color(0xFFB5C6B9),
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 26),
            child: Text(
              'DIN STUDIEPLATS',
              style: TextStyle(
                color: Color(0xFF96B1A2),
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              children: destinations.indexed
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: selected == d.$1
                            ? const Color(0xFF36594A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            d.$2.$1,
                            size: 19,
                            color: selected == d.$1
                                ? lime
                                : const Color(0xFFB2C6B9),
                          ),
                          minLeadingWidth: 21,
                          title: Text(
                            d.$2.$2,
                            style: TextStyle(
                              color: selected == d.$1
                                  ? Colors.white
                                  : const Color(0xFFB2C6B9),
                              fontSize: 12,
                              fontWeight: selected == d.$1
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          selected: selected == d.$1,
                          onTap: () {
                            navigate(d.$1);
                            if (drawer) Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF23483C),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa_outlined, color: lime, size: 20),
                  SizedBox(height: 12),
                  Text(
                    'Ett steg i taget.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Din framtid börjar\nmed det du gör idag.',
                    style: TextStyle(
                      color: Color(0xFFB2C6B9),
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 0, 25, 22),
            child: Text(
              'MANUELL V1   ·   SPARAS LOKALT',
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF96B1A2),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      if (widget.store.settings['onboarded'] != 'true') {
        return WelcomeScreen(store: widget.store);
      }
      final desktop = MediaQuery.sizeOf(context).width >= 1050;
      final compact = MediaQuery.sizeOf(context).width < 650;
      final page = switch (selected) {
        0 => OverviewPage(
          store: widget.store,
          timer: timer,
          navigate: navigate,
        ),
        1 => PlanningPage(store: widget.store),
        2 => CoursesPage(store: widget.store),
        3 => GroupsPage(store: widget.store),
        4 => NotesPage(store: widget.store),
        5 => FocusPage(store: widget.store, timer: timer),
        6 => StatisticsPage(store: widget.store),
        _ => SettingsPage(store: widget.store, timer: timer),
      };
      return Scaffold(
        key: scaffoldKey,
        drawer: desktop
            ? null
            : Drawer(width: 250, child: sidebar(drawer: true)),
        bottomNavigationBar: desktop
            ? null
            : NavigationBar(
                height: 65,
                selectedIndex: [0, 1, 2, 5].contains(selected)
                    ? [0, 1, 2, 5].indexOf(selected)
                    : 4,
                onDestinationSelected: (i) => i == 4
                    ? scaffoldKey.currentState!.openDrawer()
                    : navigate([0, 1, 2, 5][i]),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    label: 'Översikt',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    label: 'Planering',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    label: 'Kurser',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timelapse_outlined),
                    label: 'Fokus',
                  ),
                  NavigationDestination(icon: Icon(Icons.menu), label: 'Mer'),
                ],
              ),
        body: Row(
          children: [
            if (desktop) sidebar(),
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 77,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 16 : 34,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: line)),
                      ),
                      child: Row(
                        children: [
                          if (!desktop)
                            IconButton(
                              tooltip: 'Öppna meny',
                              onPressed: () =>
                                  scaffoldKey.currentState!.openDrawer(),
                              icon: const Icon(Icons.menu, size: 20),
                            ),
                          Text(
                            'Min studieplats',
                            style: TextStyle(
                              fontSize: 12,
                              color: compact ? ink : muted,
                            ),
                          ),
                          if (!compact) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('/', style: TextStyle(color: line)),
                            ),
                            Text(
                              destinations[selected].$2,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (!compact)
                            Text(
                              DateFormat(
                                'd MMMM yyyy',
                                'sv',
                              ).format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          const SizedBox(width: 16),
                          IconButton(
                            tooltip: 'Sök i StudentHub',
                            onPressed: () => showSearch(
                              context: context,
                              delegate: HubSearch(widget.store),
                            ),
                            icon: const Icon(Icons.search, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Påminnelser',
                            onPressed: showReminders,
                            icon: Badge(
                              isLabelVisible: due.isNotEmpty,
                              label: Text('${due.length}'),
                              child: const Icon(
                                Icons.notifications_none_outlined,
                                size: 21,
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 13),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFFE5ECD9),
                              child: Text(
                                (widget.store.settings['name']?.isNotEmpty ??
                                        false)
                                    ? widget
                                          .store
                                          .settings['name']!
                                          .characters
                                          .first
                                          .toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: forest,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.store.settings['demo'] == 'true')
                      Container(
                        color: const Color(0xFFEAF0DD),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 20 : 36,
                          vertical: 9,
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: green,
                            ),
                            const Text(
                              'Exempeldata · fiktiva aktiviteter och resultat',
                              style: TextStyle(fontSize: 11, color: forest),
                            ),
                            InkWell(
                              onTap: () => navigate(7),
                              child: const Text(
                                'Börja om i inställningar →',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: green,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: PageStorageKey(selected),
                        padding: EdgeInsets.all(compact ? 20 : 34),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1250),
                            child: page,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.store});
  final StudyStore store;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool busy = false;
  String? error;
  Future<void> start(bool demo) async {
    setState(() => busy = true);
    try {
      await widget.store.start(demo);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Kunde inte skapa din studieplats. Försök igen.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Panel(
            padding: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: forest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: lime,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 30),
                const Pill('STUDENTHUB CHALMERS'),
                const SizedBox(height: 18),
                const Text(
                  'Lite struktur.\nMer studentliv.',
                  style: TextStyle(
                    fontSize: 39,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'En lugn plats för ditt studentliv. Samla tentor, planera veckan och hitta fokus – på dina villkor.',
                  style: TextStyle(fontSize: 15, height: 1.7, color: muted),
                ),
                const SizedBox(height: 28),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pill('Utan konto', icon: Icons.person_outline),
                    Pill('Lokal lagring', icon: Icons.lock_outline),
                    Pill('Ditt tempo', icon: Icons.eco_outlined),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : () => start(false),
                    child: const Text('Skapa min studieplats'),
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: busy ? null : () => start(true),
                    child: const Text('Utforska med exempeldata'),
                  ),
                ),
                const SizedBox(height: 19),
                const Text(
                  'Självständigt studentprojekt. Ingen koppling till Chalmers system. Du lägger själv in dina uppgifter.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.6),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class HubSearch extends SearchDelegate<void> {
  HubSearch(this.store)
    : super(searchFieldLabel: 'Sök kurser, aktiviteter och anteckningar…');
  final StudyStore store;
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      tooltip: 'Rensa',
      onPressed: () => query = '',
      icon: const Icon(Icons.close),
    ),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Tillbaka',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      return const EmptyState(
        'Vad letar du efter?',
        'Sök bland dina egna uppgifter.',
        icon: Icons.search,
      );
    }
    final results = <Widget>[
      ...store.courses
          .where((c) => '${c.name} ${c.code}'.toLowerCase().contains(q))
          .map(
            (c) => ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(c.name),
              subtitle: Text(c.code),
              onTap: () => editCourse(context, store, c),
            ),
          ),
      ...store.entries
          .where((e) => e.title.toLowerCase().contains(q))
          .map(
            (e) => ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(e.title),
              subtitle: Text('${e.kind.label} · ${dateLabel(e.startsAt)}'),
              onTap: () => editEntry(context, store, old: e),
            ),
          ),
      ...store.notes
          .where((n) => '${n.title} ${n.body}'.toLowerCase().contains(q))
          .map(
            (n) => ListTile(
              leading: const Icon(Icons.notes_outlined),
              title: Text(n.title),
              subtitle: const Text('Anteckning'),
              onTap: () => editNote(context, store, n),
            ),
          ),
      ...store.groups
          .where((g) => g.name.toLowerCase().contains(q))
          .map(
            (g) => ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(g.name),
              subtitle: const Text('Studiegrupp'),
              onTap: () => editGroup(context, store, g),
            ),
          ),
    ];
    return results.isEmpty
        ? const EmptyState('Ingen träff ännu', 'Prova ett annat sökord.')
        : ListView(children: results);
  }
}
