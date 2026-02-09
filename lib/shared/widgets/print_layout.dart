import 'package:flutter/material.dart';

/// Wrapper that applies print-friendly styles when printing.
/// Hides navigation, uses white background, and optimizes for paper.
class PrintLayout extends StatelessWidget {
  const PrintLayout({
    super.key,
    required this.child,
    this.title,
    this.showHeader = true,
  });

  final Widget child;
  final String? title;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader && title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title!,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    'MPYC RaceDay — Printed ${DateTime.now().toString().split('.').first}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Divider(),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Utility to build a print-friendly version of a report or form.
class PrintableContent extends StatelessWidget {
  const PrintableContent({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<PrintSection> sections;

  @override
  Widget build(BuildContext context) {
    return PrintLayout(
      title: title,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              if (section.heading != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(section.heading!,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              section.content,
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class PrintSection {
  const PrintSection({this.heading, required this.content});
  final String? heading;
  final Widget content;
}
