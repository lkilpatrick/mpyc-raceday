import 'package:flutter/material.dart';

class WebScaffold extends StatelessWidget {
  const WebScaffold({
    super.key,
    required this.title,
    required this.sidebar,
    required this.body,
    required this.isSidebarCollapsed,
    required this.onToggleSidebar,
  });

  final String title;
  final Widget sidebar;
  final Widget body;
  final bool isSidebarCollapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: const [
                CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                SizedBox(width: 8),
                Text('RC Admin'),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSidebarCollapsed ? 72 : 260,
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onToggleSidebar,
                    icon: Icon(
                      isSidebarCollapsed
                          ? Icons.chevron_right
                          : Icons.chevron_left,
                    ),
                  ),
                ),
                Expanded(child: sidebar),
              ],
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(16), child: body),
          ),
        ],
      ),
    );
  }
}
