import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';
import 'package:mpyc_raceday/features/auth/data/auth_providers.dart';
import 'package:mpyc_raceday/features/auth/data/models/member.dart';

class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});

  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _roleDisplayName(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return 'Administrator';
      case MemberRole.pro:
        return 'PRO';
      case MemberRole.rcCrew:
        return 'RC Crew';
      case MemberRole.member:
        return 'Member';
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      setState(() => _passwordError = 'All fields are required.');
      return;
    }
    if (newPw.length < 8) {
      setState(
          () => _passwordError = 'New password must be at least 8 characters.');
      return;
    }
    if (newPw != confirmPw) {
      setState(() => _passwordError = 'New passwords do not match.');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updatePassword(currentPw, newPw);
      setState(() {
        _passwordSuccess = 'Password updated successfully.';
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      setState(() {
        _passwordError = e.toString().contains('wrong-password')
            ? 'Current password is incorrect.'
            : 'Failed to update password.';
      });
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentUserProvider);

    return memberAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (member) {
        if (member == null) {
          return const Center(child: Text('Not signed in'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Profile info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${member.firstName.isNotEmpty ? member.firstName[0] : ''}${member.lastName.isNotEmpty ? member.lastName[0] : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${member.firstName} ${member.lastName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _InfoChip(
                                  label: _roleDisplayName(member.role),
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                _InfoChip(
                                  label: 'Member #${member.memberNumber}',
                                  color: AppColors.accent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Change password card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 400,
                        child: Column(
                          children: [
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Current Password',
                                prefixIcon: Icon(Icons.lock_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: Icon(Icons.lock_reset),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm New Password',
                                prefixIcon: Icon(Icons.lock_reset),
                              ),
                              onSubmitted: (_) => _handleChangePassword(),
                            ),
                          ],
                        ),
                      ),
                      if (_passwordError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _passwordError!,
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ],
                      if (_passwordSuccess != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _passwordSuccess!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            _isChangingPassword ? null : _handleChangePassword,
                        child: _isChangingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update Password'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
