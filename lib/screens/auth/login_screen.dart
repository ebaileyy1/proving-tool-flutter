import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proving_tool/screens/auth/auth_layout.dart';
import 'package:proving_tool/screens/auth/signup_screen.dart';
import 'package:proving_tool/screens/auth/forgot_password_screen.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      logError('Unknown error', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.navy),
  );

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Image.asset('assets/logo.png', height: 64)),
          const SizedBox(height: 12),
          Text(
            'Prove It',
            style: GoogleFonts.montserrat(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _label('Email'),
          const SizedBox(height: 5),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(hintText: 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _label('Password'),
          const SizedBox(height: 5),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(hintText: 'Enter your password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          LoadingButton(
            isLoading: _isLoading,
            onPressed: _login,
            label: 'Sign In',
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Forgot password?'),
            ),
          ),
          const Divider(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ),
        ],
      ),
    );
  }
}
