import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../domain/store.dart';
import 'design.dart';

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Fyll i fältet.' : null;
Widget field(
  TextEditingController controller,
  String label, {
  int lines = 1,
  String? Function(String?)? validate,
  TextInputType? keyboardType,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    controller: controller,
    maxLines: lines,
    keyboardType: keyboardType,
    validator: validate,
    decoration: InputDecoration(labelText: label),
  ),
);
Widget coursePicker(
  StudyStore store,
  String? value,
  void Function(String?) change, {
  String emptyLabel = 'Ingen kurs',
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: DropdownButtonFormField<String>(
    initialValue: value ?? '',
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Kurs'),
    items: [
      DropdownMenuItem(value: '', child: Text(emptyLabel)),
      ...store.courses.map(
        (c) => DropdownMenuItem(
          value: c.id,
          child: Text('${c.code} · ${c.name}', overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: (v) => change(v == '' ? null : v),
  ),
);

class EditorDialog extends StatefulWidget {
  const EditorDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.controllers = const [],
  });
  final String title;
  final List<TextEditingController> controllers;
  final List<Widget> Function(StateSetter) fields;
  final Future<void> Function() onSave;
  @override
  State<EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends State<EditorDialog> {
  final _key = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        Expanded(child: Text(widget.title)),
        IconButton(
          tooltip: 'Stäng',
          onPressed: busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.fields(setState),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Avbryt'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                if (!_key.currentState!.validate()) return;
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  await widget.onSave();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      error = e is FormatException
                          ? e.message
                          : 'Kunde inte spara. Försök igen.';
                      busy = false;
                    });
                  }
                }
              },
        child: Text(busy ? 'Sparar…' : 'Spara'),
      ),
    ],
  );
}

Future<void> editCourse(
  BuildContext context,
  StudyStore store, [
  Course? old,
]) async {
  final name = TextEditingController(text: old?.name),
      code = TextEditingController(text: old?.code),
      credits = TextEditingController(text: numberLabel(old?.credits ?? 7.5));
  var color = old?.color ?? 0;
  String? grade = old?.grade;
  await showDialog<void>(
    context: context,
    builder: (context) => EditorDialog(
      title: old == null ? 'Lägg till kurs' : 'Redigera kurs',
      controllers: [name, code, credits],
      fields: (set) => [
        field(name, 'Kursnamn', validate: requiredText),
        field(code, 'Kurskod', validate: requiredText),
        field(
          credits,
          'Högskolepoäng',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validate: (v) {
            final n = double.tryParse((v ?? '').replaceAll(',', '.'));
            return n == null || !n.isFinite || n <= 0 || n > 300
                ? 'Ange ett tal mellan 0 och 300.'
                : null;
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: grade ?? '',
          decoration: const InputDecoration(labelText: 'Resultat'),
          items: ['', 'U', '3', '4', '5', 'G']
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(g.isEmpty ? 'Pågående' : 'Betyg $g'),
                ),
              )
              .toList(),
          onChanged: (v) => set(() => grade = v == '' ? null : v),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          children: courseColors.indexed
              .map(
                (c) => IconButton.filledTonal(
                  tooltip: 'Kursfärg ${c.$1 + 1}',
                  style: IconButton.styleFrom(
                    backgroundColor: c.$2.withValues(alpha: .15),
                  ),
                  onPressed: () => set(() => color = c.$1),
                  icon: Icon(
                    color == c.$1 ? Icons.check_circle : Icons.circle,
                    color: c.$2,
                  ),
                ),
              )
              .toList(),
        ),
      ],
      onSave: () => store.saveCourse(
        Course(
          id: old?.id ?? newId(),
          name: name.text.trim(),
          code: code.text.trim().toUpperCase(),
          credits: double.parse(credits.text.replaceAll(',', '.')),
          color: color,
          grade: grade,
        ),
      ),
    ),
  );
}

class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text('$label · ${dateLabel(value)} ${value.year}'),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onChanged(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    value.hour,
                    value.minute,
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(value),
            );
            if (time != null) {
              onChanged(
                DateTime(
                  value.year,
                  value.month,
                  value.day,
                  time.hour,
                  time.minute,
                ),
              );
            }
          },
          child: Text(timeLabel(value)),
        ),
      ],
    ),
  );
}

Future<void> editEntry(
  BuildContext context,
  StudyStore store, {
  StudyEntry? old,
  EntryKind? initialKind,
  DateTime? initialDate,
}) async {
  final title = TextEditingController(text: old?.title),
      location = TextEditingController(text: old?.location);
  var kind = old?.kind ?? initialKind ?? EntryKind.study;
  var start =
      old?.startsAt ??
      initialDate ??
      DateTime.now().add(const Duration(hours: 1));
  var end = old?.endsAt ?? start.add(const Duration(hours: 1));
  var course = old?.courseId;
  int? remind = old == null ? 15 : old.remindMinutes;
  await showDialog<void>(
    context: context,
    builder: (context) => EditorDialog(
      title: old == null ? 'Ny aktivitet' : 'Redigera aktivitet',
      controllers: [title, location],
      fields: (set) => [
        field(title, 'Titel', validate: requiredText),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<EntryKind>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Typ'),
            items: EntryKind.values
                .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                .toList(),
            onChanged: (v) => set(() => kind = v!),
          ),
        ),
        coursePicker(store, course, (v) => set(() => course = v)),
        DateTimeField(
          label: 'Start',
          value: start,
          onChanged: (v) => set(() {
            final duration = end.difference(start);
            start = v;
            end = v.add(duration);
          }),
        ),
        if (kind != EntryKind.deadline)
          DateTimeField(
            label: 'Slut',
            value: end,
            onChanged: (v) => set(() => end = v),
          ),
        field(location, 'Plats / länk'),
        DropdownButtonFormField<int>(
          initialValue: remind ?? -1,
          decoration: const InputDecoration(labelText: 'Påminnelse i appen'),
          items: const [
            DropdownMenuItem(value: -1, child: Text('Ingen påminnelse')),
            DropdownMenuItem(value: 0, child: Text('Vid start')),
            DropdownMenuItem(value: 15, child: Text('15 minuter innan')),
            DropdownMenuItem(value: 60, child: Text('1 timme innan')),
            DropdownMenuItem(value: 1440, child: Text('1 dag innan')),
          ],
          onChanged: (v) => set(() => remind = v == -1 ? null : v),
        ),
        const SizedBox(height: 12),
        const Text(
          'Påminnelser visas när appen är öppen.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
      onSave: () async {
        if (kind != EntryKind.deadline && end.isBefore(start)) {
          throw const FormatException('Sluttiden måste vara efter starttiden.');
        }
        await store.saveEntry(
          StudyEntry(
            id: old?.id ?? newId(),
            title: title.text.trim(),
            kind: kind,
            startsAt: start,
            endsAt: kind == EntryKind.deadline ? start : end,
            courseId: course,
            location: location.text.trim(),
            done: old?.done ?? false,
            remindMinutes: remind,
          ),
        );
      },
    ),
  );
}

Future<void> editGroup(
  BuildContext context,
  StudyStore store, [
  StudyGroup? old,
]) async {
  final name = TextEditingController(text: old?.name),
      members = TextEditingController(text: old?.members),
      location = TextEditingController(text: old?.location);
  var course = old?.courseId;
  var meeting = old?.meetingAt ?? DateTime.now().add(const Duration(days: 1));
  await showDialog<void>(
    context: context,
    builder: (context) => EditorDialog(
      title: old == null ? 'Ny studiegrupp' : 'Redigera studiegrupp',
      controllers: [name, members, location],
      fields: (set) => [
        field(name, 'Gruppnamn', validate: requiredText),
        coursePicker(store, course, (v) => set(() => course = v)),
        field(
          members,
          'Medlemmar (separera med komma)',
          validate: requiredText,
        ),
        field(location, 'Mötesplats'),
        DateTimeField(
          label: 'Nästa träff',
          value: meeting,
          onChanged: (v) => set(() => meeting = v),
        ),
        const Text(
          'Gruppen sparas hos dig. Version 1 skickar inga inbjudningar.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
      onSave: () => store.saveGroup(
        StudyGroup(
          id: old?.id ?? newId(),
          name: name.text.trim(),
          members: members.text.trim(),
          meetingAt: meeting,
          courseId: course,
          location: location.text.trim(),
        ),
      ),
    ),
  );
}

Future<void> editNote(
  BuildContext context,
  StudyStore store, [
  Note? old,
]) async {
  final title = TextEditingController(text: old?.title),
      body = TextEditingController(text: old?.body);
  var course = old?.courseId;
  await showDialog<void>(
    context: context,
    builder: (context) => EditorDialog(
      title: old == null ? 'Ny anteckning' : 'Redigera anteckning',
      controllers: [title, body],
      fields: (set) => [
        field(title, 'Rubrik', validate: requiredText),
        coursePicker(store, course, (v) => set(() => course = v)),
        field(body, 'Dina anteckningar', lines: 12, validate: requiredText),
      ],
      onSave: () => store.saveNote(
        Note(
          id: old?.id ?? newId(),
          title: title.text.trim(),
          body: body.text.trim(),
          updatedAt: DateTime.now(),
          courseId: course,
        ),
      ),
    ),
  );
}

Future<void> confirmDelete(
  BuildContext context,
  StudyStore store,
  String table,
  String id,
  String title,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ta bort?'),
      content: Text(
        '“$title” tas bort från denna enhet.${table == 'courses' ? ' Aktiviteter och anteckningar behålls utan kurskoppling.' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Behåll'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ta bort'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await runAction(context, () => store.remove(table, id));
  }
}
