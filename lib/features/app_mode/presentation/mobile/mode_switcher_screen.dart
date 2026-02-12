import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_mode.dart';

class ModeSwitcherScreen extends ConsumerWidget {
  const ModeSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appModeProvider).value ?? currentAppMode();

    return Scaffold(
      appBar: AppBar(title: const Text('Switch Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select your role for today',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'The app will adapt its navigation and features to match your role.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ...AppMode.values.map((mode) {
            final selected = mode == currentMode;
            return Card(
              color: selected ? mode.color.withValues(alpha: 0.1) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: selected
                    ? BorderSide(color: mode.color, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  setAppMode(ref, mode);
                  context.go('/home');
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: mode.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(mode.icon, color: mode.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mode.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: selected ? mode.color : null,
                                )),
                            const SizedBox(height: 2),
                            Text(mode.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? mode.color.withValues(alpha: 0.8)
                                      : Colors.grey,
                                )),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: mode.color),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
