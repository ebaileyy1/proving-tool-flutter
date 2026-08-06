import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';

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
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() => _isSavingUsername = true);
    try {
      await _supabase
          .from('profiles')
          .update({'username': _usernameController.text.trim()})
          .eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      }
      _loadProfile();
    } catch (e) {
      logError('Error updating username', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingUsername = false);
    }
  }

  Future<void> _savePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      logError('Error updating password', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
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
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
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
                      // Profile header
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? Colors.orange.withValues(alpha: 0.15)
                                            : Colors.blue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isAdmin ? 'Admin' : 'User',
                                        style: TextStyle(
                                          color: isAdmin ? Colors.orange : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Update username
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Update Username',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSavingUsername ? null : _saveUsername,
                                  child: _isSavingUsername
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Save Username'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Change password
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Change Password',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _newPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm New Password',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSavingPassword ? null : _savePassword,
                                  child: _isSavingPassword
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Update Password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Account info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Info',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _infoRow('Email', user?.email ?? '-'),
                              _infoRow('Member since', _profile['created_at']?.toString().split('T')[0] ?? '-'),
                              _infoRow('Role', isAdmin ? 'Administrator' : 'Standard User'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}