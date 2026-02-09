import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpyc_raceday/core/theme.dart';
import 'package:mpyc_raceday/features/auth/data/auth_providers.dart';

class NoAccessPage extends ConsumerWidget {
  const NoAccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Access Restricted',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The web dashboard is only available to administrators and PROs. '
                    'If you believe you should have access, please contact the club.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Members can use the MPYC Raceday mobile app to view schedules, '
                    'check in, and manage their profile.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final repo = ref.read(authRepositoryProvider);
                        await repo.signOut();
                        if (context.mounted) context.go('/web-login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
