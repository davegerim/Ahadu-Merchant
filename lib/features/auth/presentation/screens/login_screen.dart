import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../../../core/theme/colors.dart';
import '../providers/auth_providers.dart';
import '../providers/merchant_session_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _merchantIdController = TextEditingController();
  final _secretController = TextEditingController();
  bool _obscureSecret = true;
  bool _isLoading = false;

  void _login() async {
    if (_merchantIdController.text.isEmpty || _secretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Merchant ID and Secret'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final merchantCode = _merchantIdController.text.trim();
      final merchantSecret = _secretController.text.trim();
      await ref.read(authRepositoryProvider).validateMerchant(
            merchantCode: merchantCode,
            merchantSecret: merchantSecret,
          );

      ref.read(merchantSessionProvider.notifier).setCredentials(
            merchantCode: merchantCode,
            merchantSecret: merchantSecret,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('/dashboard');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e.response?.data?.toString() ??
          e.message ??
          'Unable to validate merchant credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error while trying to log in.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _merchantIdController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Logo
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                  const SizedBox(height: 32),
                  Text(
                    'Ahadu Merchant',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back, log in to your business',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _merchantIdController,
                    decoration: const InputDecoration(
                      labelText: 'Merchant ID',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secretController,
                    obscureText: _obscureSecret,
                    decoration: InputDecoration(
                      labelText: 'Merchant Secret',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecret
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureSecret = !_obscureSecret),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
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
