import 'package:flutter/material.dart';
import '../domain/store.dart';
import '../domain/note_assistant.dart';
import 'design.dart';
import 'editors.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.store});
  final StudyStore store;
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final question = TextEditingController();
  final assistant = NoteAssistant();
  String? course;
  String answer = '';
  String? error;
  List<NoteSource> sources = [];
  bool useAi = false, busy = false, searched = false;
  @override
  void dispose() {
    question.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    if (question.text.trim().isEmpty || busy) return;
    final matches = assistant.retrieve(
      question.text,
      widget.store.notes,
      courseId: course,
    );
    setState(() {
      sources = matches;
      busy = useAi && matches.isNotEmpty;
      searched = true;
      answer = '';
      error = null;
    });
    if (!useAi || matches.isEmpty) return;
    try {
      final result = await assistant.askLocalAi(
        question.text,
        matches,
        model: widget.store.settings['ollamaModel'] ?? 'gemma3',
      );
      if (mounted) setState(() => answer = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Kunde inte nå lokal AI. Kontrollera att Ollama körs, modellen finns och webbläsaren tillåts ansluta. Dina källutdrag finns nedan.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.store.notes
        .where((n) => course == null || n.courseId == course)
        .toList();
    // A course can be removed while this page is in use.
    final selectedCourse = widget.store.course(course) == null ? null : course;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Från anteckning till förståelse.',
          'Samla dina tankar. Hitta svar i det du har skrivit.',
          action: FilledButton.icon(
            onPressed: () => editNote(context, widget.store),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Ny anteckning'),
          ),
        ),
        ResponsiveColumns(
          leftFlex: 1,
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              coursePicker(
                widget.store,
                selectedCourse,
                (v) => setState(() {
                  course = v;
                  sources = [];
                  answer = '';
                  searched = false;
                }),
                emptyLabel: 'Alla kurser',
              ),
              if (notes.isEmpty)
                const Panel(
                  child: EmptyState(
                    'En tanke börjar här',
                    'Skriv eller klistra in dina föreläsningsanteckningar.',
                    icon: Icons.edit_note_outlined,
                  ),
                )
              else
                ...notes.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 17),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Pill(
                                widget.store.course(n.courseId)?.code ??
                                    'ANTECKNING',
                              ),
                              const Spacer(),
                              PopupMenuButton<String>(
                                tooltip: 'Alternativ för ${n.title}',
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Redigera'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Ta bort'),
                                  ),
                                ],
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    await editNote(context, widget.store, n);
                                  } else {
                                    await confirmDelete(
                                      context,
                                      widget.store,
                                      'notes',
                                      n.id,
                                      n.title,
                                    );
                                  }
                                  if (mounted) {
                                    setState(() {
                                      sources = [];
                                      answer = '';
                                      searched = false;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 19,
                              letterSpacing: -.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            n.body,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: muted,
                              height: 1.7,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Uppdaterad ${dateLabel(n.updatedAt)}',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  await editNote(context, widget.store, n);
                                  if (mounted) {
                                    setState(() {
                                      sources = [];
                                      answer = '';
                                      searched = false;
                                    });
                                  }
                                },
                                child: const Text('Öppna →'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          right: Panel(
            color: const Color(0xFFEDF2E9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeading(
                  'Fråga dina anteckningar',
                  subtitle: 'Ditt eget material, i centrum.',
                ),
                const Icon(Icons.auto_awesome, size: 32, color: green),
                const SizedBox(height: 18),
                const Text(
                  'Vad vill du förstå bättre?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Skriv en fråga med ord som finns i dina anteckningar. Du får relevanta utdrag med källor.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 23),
                TextField(
                  controller: question,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Din fråga',
                    hintText: 'Hur fungerar ett binärt sökträd?',
                  ),
                  onSubmitted: (_) => ask(),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Lokal AI (Ollama)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    useAi
                        ? 'Frågan och källutdragen skickas till din dator.'
                        : 'Av · endast lokal källsökning',
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                  value: useAi,
                  onChanged: busy ? null : (v) => setState(() => useAi = v),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : ask,
                  icon: Icon(
                    useAi ? Icons.auto_awesome : Icons.search,
                    size: 17,
                  ),
                  label: Text(
                    busy
                        ? 'Tänker med dina anteckningar…'
                        : useAi
                        ? 'Fråga lokal AI'
                        : 'Hitta i anteckningar',
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFF9A522F),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                if (answer.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'AI-svar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    answer,
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Kontrollera svaret mot källorna. AI kan göra fel.',
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                ],
                if (searched && sources.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Text(
                      'Inga relevanta utdrag hittades. Prova ett mer konkret begrepp eller lägg till fler anteckningar.',
                      style: TextStyle(color: muted, height: 1.6),
                    ),
                  ),
                if (sources.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'Källor i dina anteckningar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...sources.indexed.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Panel(
                        padding: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[${s.$1 + 1}] ${s.$2.note.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              s.$2.passage,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
