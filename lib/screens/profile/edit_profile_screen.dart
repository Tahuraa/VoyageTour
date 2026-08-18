import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not save changes. Please try again.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user!.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Alex Rivera',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                hint: '+1 (555) 012-3456',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().length < 6) ? 'Enter a valid phone number' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'EMAIL ADDRESS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 20, color: Colors.black38),
                    const SizedBox(width: 10),
                    Expanded(child: Text(email, style: const TextStyle(color: Colors.black54))),
                    const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Email address cannot be changed.',
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Save Changes',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
