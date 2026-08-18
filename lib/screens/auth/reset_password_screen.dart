import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final message = await context.read<AuthProvider>().resetPassword(
            token: _codeController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not reach the server. Please try again.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'VoyageTour',
      subtitle: 'Enter your reset code',
      card: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'We sent a reset code to ${widget.email}.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _codeController,
              label: 'Reset Code',
              hint: 'Paste the code you received',
              icon: Icons.pin_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Reset code is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'New Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Reset Password',
              icon: Icons.check,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
