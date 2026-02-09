import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a web admin page with common keyboard shortcuts.
class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onNew,
    this.onSave,
    this.onSearch,
    this.onRefresh,
  });

  final Widget child;
  final VoidCallback? onNew;
  final VoidCallback? onSave;
  final VoidCallback? onSearch;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        if (onNew != null)
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): onNew!,
        if (onSave != null)
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              onSave!,
        if (onSearch != null)
          const SingleActivator(LogicalKeyboardKey.keyK, control: true):
              onSearch!,
        if (onRefresh != null)
          const SingleActivator(LogicalKeyboardKey.keyR, control: true):
              onRefresh!,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
