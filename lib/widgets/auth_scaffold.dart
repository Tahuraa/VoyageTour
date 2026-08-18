import 'package:flutter/material.dart';

/// Shared shell for the auth screens (login/register/forgot/reset): a
/// sunset-toned gradient background with the VoyageTour brand mark, and a
/// frosted card that hosts the actual form content.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget card;
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.card,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB9713F), Color(0xFF6B4A4F), Color(0xFF20222E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flight, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: card,
                ),
                const SizedBox(height: 20),
                ?footer,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
