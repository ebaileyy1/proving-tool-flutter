import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/screens/auth/auth_layout.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/loading_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      showMessage(context, 'Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showMessage(context, 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      showMessage(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      // For an already-registered email Supabase can return a normal-looking
      // response (even with a session) instead of throwing, to avoid leaking
      // which emails exist. No new identity in the response is the tell.
      final isExistingAccount = user != null && (user.identities?.isEmpty ?? true);

      if (isExistingAccount) {
        try {
          await _supabase.auth.signOut();
        } catch (_) {}
        if (mounted) {
          showMessage(context, 'An account with this email already exists. Please log in instead.');
        }
        return;
      }

      if (user != null) {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'username': _usernameController.text.trim(),
          'is_admin': false,
        });
      }
    } on AuthException catch (e) {
      // Make sure no session survives a failed signup.
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      logError('Signup error', e);
      if (mounted) showMessage(context, 'Error creating account: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Image.asset('assets/logo.png', height: 56)),
          const SizedBox(height: 12),
          const Text(
            'Create Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          LoadingButton(
            isLoading: _isLoading,
            onPressed: _signup,
            label: 'Create Account',
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Login'),
            ),
          ),
        ],
      ),
    );
  }
}
