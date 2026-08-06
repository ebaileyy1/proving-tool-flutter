import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      setState(() => _emailSent = true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      logError('Reset password error', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _emailSent
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_read, size: 64, color: Colors.green),
                      const SizedBox(height: 24),
                      const Text(
                        'Reset email sent!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Check your inbox at ${_emailController.text.trim()} and follow the link to reset your password.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.otherText),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to login'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.otherText),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetEmail,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Send Reset Email'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to login'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}