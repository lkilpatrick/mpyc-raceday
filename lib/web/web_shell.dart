import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/shared/widgets/placeholder_page.dart';
import 'package:mpyc_raceday/web/layouts/web_scaffold.dart';
import 'package:mpyc_raceday/web/navigation/web_sidebar.dart';

class WebShell extends StatefulWidget {
  const WebShell({super.key, required this.activeRoute});

  final String activeRoute;

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  bool _isCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = webNavItems.firstWhere(
      (item) => item.route == widget.activeRoute,
      orElse: () => webNavItems.first,
    );

    return WebScaffold(
      title: 'MPYC Admin',
      isSidebarCollapsed: _isCollapsed,
      onToggleSidebar: _toggleSidebar,
      sidebar: WebSidebar(
        activeRoute: activeItem.route,
        isCollapsed: _isCollapsed,
        onSelected: (item) => context.go(item.route),
      ),
      body: PlaceholderPage(
        title: activeItem.label,
        subtitle: 'Web admin dashboard',
      ),
    );
  }
}
