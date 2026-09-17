import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const forest = Color(0xFF173F35);
const green = Color(0xFF25735A);
const ink = Color(0xFF243B33);
const muted = Color(0xFF738078);
const canvas = Color(0xFFF5F6F2);
const line = Color(0xFFE5E9E2);
const lime = Color(0xFFE4EFAF);
const courseColors = [
  Color(0xFF4C8871),
  Color(0xFFBA8C54),
  Color(0xFF8580B1),
  Color(0xFF648CAB),
  Color(0xFFC0746C),
];
String dateLabel(DateTime d) => DateFormat('d MMM', 'sv').format(d);
String timeLabel(DateTime d) => DateFormat('HH:mm', 'sv').format(d);
String numberLabel(num d) => NumberFormat('0.#', 'sv').format(d);
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forest,
      primary: forest,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: canvas,
    fontFamily: 'Manrope',
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: forest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 24,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line),
    ),
    child: child,
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = green, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 7),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 14)),
          ],
        ),
        ?action,
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.detail, {
    super.key,
    this.icon = Icons.eco_outlined,
    this.action,
  });
  final String title, detail;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 36, color: green),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(color: muted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 2,
  });
  final Widget left, right;
  final int leftFlex;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => size.maxWidth >= 800
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 22),
              Expanded(child: right),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 22), right],
          ),
  );
}

Future<void> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kunde inte spara. Dina tidigare uppgifter finns kvar. Försök igen.',
          ),
        ),
      );
    }
  }
}
