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
    this.userName,
    this.userInitials,
    this.onSignOut,
  });

  final String title;
  final Widget sidebar;
  final Widget body;
  final bool isSidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final String? userName;
  final String? userInitials;
  final VoidCallback? onSignOut;

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
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'sign_out') onSignOut?.call();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  userName ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      userInitials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userName ?? 'User',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
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
