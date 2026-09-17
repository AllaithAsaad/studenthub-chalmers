import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/repository.dart';
import 'domain/store.dart';
import 'ui/app_shell.dart';
import 'ui/design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('sv');
  // Keep semantic controls available to screen readers and browser automation.
  // Flutter renders to canvas on web; this also provides accessible DOM controls.
  WidgetsBinding.instance.ensureSemantics();
  runApp(const StudentHubApp());
}

class StudentHubApp extends StatefulWidget {
  const StudentHubApp({super.key, this.store});
  final StudyStore? store;
  @override
  State<StudentHubApp> createState() => _StudentHubAppState();
}

class _StudentHubAppState extends State<StudentHubApp> {
  StudyStore? store;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = widget.store ?? StudyStore(await StudyRepository.open());
      await data.load();
      if (mounted) {
        setState(() {
          store = data;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Din lokala databas kunde inte öppnas. Kontrollera att webbläsaren tillåter lagring och ladda om.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StudentHub Chalmers',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('sv'),
    supportedLocales: const [Locale('sv')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: store != null
        ? AppShell(store: store!)
        : Scaffold(
            body: Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: load,
                            child: const Text('Försök igen'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
  );
}
