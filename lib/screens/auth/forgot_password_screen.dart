import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final message =
          await context.read<AuthProvider>().forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
        ),
      );
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
      subtitle: 'Reset your password',
      card: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Forgot Password?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              "Enter your email and we'll send you a reset code.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'explorer@voyagetour.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Send Reset Code',
              icon: Icons.arrow_forward,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      footer: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Text('Back to Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
