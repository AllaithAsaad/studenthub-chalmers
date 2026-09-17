import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studenthub_chalmers/data/repository.dart';
import 'package:studenthub_chalmers/domain/store.dart';
import 'package:studenthub_chalmers/domain/focus_timer.dart';
import 'package:studenthub_chalmers/ui/app_shell.dart';
import 'package:studenthub_chalmers/ui/design.dart';
import 'package:studenthub_chalmers/ui/overview.dart';
import 'package:studenthub_chalmers/ui/pages.dart';
import 'package:studenthub_chalmers/ui/notes_page.dart';

void main() {
  late StudyStore store;
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('sv');
  });
  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: StudyRepository.options,
    );
    store = StudyStore(StudyRepository(db));
    await store.start(true);
  });
  tearDown(() async {
    await store.repository.db.close();
    store.dispose();
  });
  Widget app(Widget child) => MaterialApp(
    theme: buildTheme(),
    locale: const Locale('sv'),
    supportedLocales: const [Locale('sv')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );
  for (final width in [360.0, 1440.0]) {
    testWidgets('All product screens fit a $width px viewport', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final timer = FocusTimer(store, autoTick: false);
      final pages = [
        OverviewPage(store: store, timer: timer, navigate: (_) {}),
        PlanningPage(store: store),
        CoursesPage(store: store),
        GroupsPage(store: store),
        NotesPage(store: store),
        FocusPage(store: store, timer: timer),
        StatisticsPage(store: store),
        SettingsPage(store: store, timer: timer),
      ];
      for (final page in pages) {
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: page,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: page.runtimeType.toString(),
        );
      }
      await tester.pumpWidget(const SizedBox());
      timer.dispose();
    });
  }
  testWidgets('Course form validates and creates a persisted course', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(Scaffold(body: CoursesPage(store: store))));
    await tester.tap(find.text('Lägg till kurs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spara'));
    await tester.pumpAndSettle();
    expect(find.text('Fyll i fältet.'), findsNWidgets(2));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kursnamn'),
      'Testkurs',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kurskod'),
      'ABC123',
    );
    await tester.runAsync(() async {
      final changed = Future<void>(() async {
        while (!store.courses.any((c) => c.code == 'ABC123')) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.tap(find.text('Spara'));
      await changed.timeout(const Duration(seconds: 3));
    });
    await tester.pumpAndSettle();
    expect(store.courses.any((c) => c.code == 'ABC123'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Notes helper shows sources and a useful no-match state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(child: NotesPage(store: store)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'binärt sökträd');
    await tester.tap(find.text('Hitta i anteckningar'));
    await tester.pumpAndSettle();
    expect(find.text('Källor i dina anteckningar'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'kvantmekanik');
    await tester.tap(find.text('Hitta i anteckningar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Inga relevanta utdrag'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Mobile shell opens navigation and shows groups', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(AppShell(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Öppna meny'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studiegrupper'));
    await tester.pumpAndSettle();
    expect(find.text('Tänk högt. Tillsammans.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
