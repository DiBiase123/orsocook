// lib/screens/home/widgets/welcome_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/logger.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ Building WelcomeHeader');

    final authService = Provider.of<AuthService>(context);

    String welcomeText = 'Benvenuto in OrsoCook!';
    if (authService.isLoggedIn && authService.username != null) {
      welcomeText = 'Bentornato, ${authService.username}!';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            welcomeText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scopri, crea e condividi le tue ricette preferite',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
