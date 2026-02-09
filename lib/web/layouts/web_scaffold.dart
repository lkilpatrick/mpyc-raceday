import 'package:flutter/material.dart';
import 'package:mpyc_raceday/core/theme.dart';

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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        toolbarHeight: 56,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/burgee.png',
              height: 36,
              errorBuilder: (_, __, ___) => const Icon(Icons.sailing, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text(
              'MPYC Raceday',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.sidebarSelected,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                SizedBox(width: 8),
                Text('RC Admin', style: TextStyle(fontSize: 13)),
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
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              border: Border(
                right: BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
            child: Column(
              children: [
                // Collapse toggle
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onToggleSidebar,
                    icon: Icon(
                      isSidebarCollapsed
                          ? Icons.chevron_right
                          : Icons.chevron_left,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(child: sidebar),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: Padding(padding: const EdgeInsets.all(16), child: body),
            ),
          ),
        ],
      ),
    );
  }
}
