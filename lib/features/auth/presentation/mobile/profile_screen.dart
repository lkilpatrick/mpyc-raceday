import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/core/theme.dart';
import 'package:mpyc_raceday/features/app_mode/data/app_mode.dart';
import 'package:mpyc_raceday/features/auth/data/auth_providers.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _openMemberPortal() async {
    // This would call the createMemberPortalSession Cloud Function
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening member portal...')),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      if (mounted) context.go('/login');
    }
  }

  void _editEmergencyContact(Member member) {
    final nameController =
        TextEditingController(text: member.emergencyContact.name);
    final phoneController =
        TextEditingController(text: member.emergencyContact.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(authRepositoryProvider);
              await repo.updateEmergencyContact(
                EmergencyContact(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _roleColor(MemberRole role) {
    switch (role) {
      case MemberRole.webAdmin:
        return Colors.red;
      case MemberRole.clubBoard:
        return Colors.purple;
      case MemberRole.rcChair:
        return Colors.blue;
      case MemberRole.skipper:
        return Colors.teal;
      case MemberRole.crew:
        return Colors.grey;
    }
  }

  String _roleDisplayName(MemberRole role) {
    switch (role) {
      case MemberRole.webAdmin:
        return 'Web Admin';
      case MemberRole.clubBoard:
        return 'Club Board';
      case MemberRole.rcChair:
        return 'RC Chair';
      case MemberRole.skipper:
        return 'Skipper';
      case MemberRole.crew:
        return 'Crew';
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: memberAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (member) {
        if (member == null) {
          return const Center(child: Text('Not signed in'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${member.firstName.isNotEmpty ? member.firstName[0] : ''}${member.lastName.isNotEmpty ? member.lastName[0] : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${member.firstName} ${member.lastName}',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member #${member.memberNumber}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: member.roles.map((role) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roleDisplayName(role),
                          style: TextStyle(
                            color: _roleColor(role),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.membershipStatus,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // App Mode switcher
            _AppModeCard(),
            const SizedBox(height: 12),

            // Member Portal
            Card(
              child: ListTile(
                leading:
                    Icon(Icons.open_in_browser, color: AppColors.primary),
                title: const Text('Open Member Portal'),
                subtitle: const Text('View your Clubspot member profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openMemberPortal,
              ),
            ),
            const SizedBox(height: 12),

            // Notification preferences
            Card(
              child: SwitchListTile(
                secondary:
                    Icon(Icons.notifications_outlined, color: AppColors.primary),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive race day reminders'),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  final repo = ref.read(authRepositoryProvider);
                  await repo.updateNotificationPreferences(value);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Emergency contact
            Card(
              child: ListTile(
                leading: Icon(Icons.emergency, color: AppColors.secondary),
                title: const Text('Emergency Contact'),
                subtitle: Text(
                  '${member.emergencyContact.name} — ${member.emergencyContact.phone}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _editEmergencyContact(member),
              ),
            ),
            const SizedBox(height: 24),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }
}

class _AppModeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider).value ?? currentAppMode();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: mode.color.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(mode.icon, color: mode.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Mode',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${mode.label} Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: mode.color,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/mode-switcher'),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Switch'),
                  style: FilledButton.styleFrom(
                    backgroundColor: mode.color,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          // Quick-switch row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: AppMode.values.map((m) {
                final isActive = m == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color: isActive
                          ? m.color.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isActive
                            ? null
                            : () => setAppMode(ref, m),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Icon(m.icon,
                                  size: 20,
                                  color: isActive ? m.color : Colors.grey),
                              const SizedBox(height: 2),
                              Text(
                                m == AppMode.raceCommittee ? 'RC' : m.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isActive ? m.color : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
