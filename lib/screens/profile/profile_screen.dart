import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/loading_button.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = true;
  bool _isSavingUsername = false;
  bool _isSavingPassword = false;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final profile = await _supabase.from('profiles').select().eq('id', userId).single();
      setState(() {
        _profile = Map<String, dynamic>.from(profile);
        _usernameController.text = profile['username']?.toString() ?? '';
      });
    } catch (e) {
      logError('Error loading profile', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      showMessage(context, 'Username cannot be empty');
      return;
    }

    setState(() => _isSavingUsername = true);
    try {
      await _supabase
          .from('profiles')
          .update({'username': _usernameController.text.trim()})
          .eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        showMessage(context, 'Username updated successfully');
      }
      _loadProfile();
    } catch (e) {
      logError('Error updating username', e);
      if (mounted) {
        showMessage(context, 'Error updating username: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingUsername = false);
    }
  }

  Future<void> _savePassword() async {
    if (_newPasswordController.text.isEmpty) {
      showMessage(context, 'Please enter a new password');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      showMessage(context, 'Passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      showMessage(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: _newPasswordController.text));

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        showMessage(context, 'Password updated successfully');
      }
    } on AuthException catch (e) {
      if (mounted) {
        showMessage(context, e.message);
      }
    } catch (e) {
      logError('Error updating password', e);
      if (mounted) {
        showMessage(context, 'Error updating password: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final isAdmin = _profile['is_admin'] == true;

    return Scaffold(
      appBar: const AppHeader(title: 'My Profile'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.navy,
                                child: Text(
                                  (_profile['username']?.toString() ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _profile['username']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '-',
                                      style: const TextStyle(
                                        color: AppColors.otherText,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ColorPill(
                                      label: isAdmin ? 'Admin' : 'User',
                                      color: isAdmin ? AppColors.warning : AppColors.accent,
                                      dense: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _section('Update Username', 16, [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'Username'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: LoadingButton(
                            isLoading: _isSavingUsername,
                            onPressed: _saveUsername,
                            label: 'Save Username',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _section('Change Password', 16, [
                        TextField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(labelText: 'New Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(labelText: 'Confirm New Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: LoadingButton(
                            isLoading: _isSavingPassword,
                            onPressed: _savePassword,
                            label: 'Update Password',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _section('Account Info', 12, [
                        _infoRow('Email', user?.email ?? '-'),
                        _infoRow(
                          'Member since',
                          _profile['created_at']?.toString().split('T')[0] ?? '-',
                        ),
                        _infoRow('Role', isAdmin ? 'Administrator' : 'Standard User'),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _section(String title, double gap, List<Widget> children) {
    return SectionCard(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: gap),
        ...children,
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.otherText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.navy, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
