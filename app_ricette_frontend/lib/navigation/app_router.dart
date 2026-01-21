import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/recipe/detail_recipe_screen.dart';
import '../screens/recipe/create_recipe_screen.dart';
import '../screens/recipe/edit_recipe_screen.dart';
import '../models/recipe.dart';
import '../utils/logger.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Estrai query parameters per verificare token
    final uri = Uri.parse(settings.name ?? '/');
    final token = uri.queryParameters['token'];

    switch (settings.name?.split('?')[0]) {
      // ==================== ROUTE PRINCIPALE ====================
      case '/':
        return MaterialPageRoute(
          builder: (context) {
            // Pulisci eventuali credenziali residue all'avvio
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                await authService.logout(); // Forza logout all'avvio
                AppLogger.debug('✅ Sessione precedente pulita all\'avvio');
              } catch (e) {
                AppLogger.error('Errore durante la pulizia all\'avvio', e);
              }
            });

            return const LoginScreen();
          },
          settings: settings,
        );

      // ==================== ROUTES AUTH ====================
      case '/login':
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );

      case '/register':
        return MaterialPageRoute(
          builder: (context) => const RegisterScreen(),
          settings: settings,
        );

      // 👇 NUOVA ROUTE: VERIFICA EMAIL (con o senza token)
      case '/verify-email':
        return MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(token: token),
          settings: settings,
        );

      // 👇 NUOVA ROUTE: PASSWORD DIMENTICATA
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordScreen(),
          settings: settings,
        );

      // 👇 NUOVA ROUTE: RESET PASSWORD (con token)
      case '/reset-password':
        if (token == null || token.isEmpty) {
          return _errorRoute(settings, 'Token di reset mancante');
        }
        return MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(token: token),
          settings: settings,
        );

      // ==================== ROUTES APP ====================
      case '/home':
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: settings,
        );

      case '/profile':
        return MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
          settings: settings,
        );

      case '/recipe/detail':
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => DetailRecipeScreen(recipeId: args),
            settings: settings,
          );
        }
        return _errorRoute(settings, 'Recipe ID mancante');

      case '/create-recipe':
        return MaterialPageRoute(
          builder: (context) => const CreateRecipeScreen(),
          settings: settings,
        );

      case '/recipe/edit':
        final args = settings.arguments;
        if (args is Recipe) {
          return MaterialPageRoute(
            builder: (context) => EditRecipeScreen(recipe: args),
            settings: settings,
          );
        }
        return _errorRoute(settings, 'Devi passare una Recipe');

      // ==================== ROUTE NON TROVATA ====================
      default:
        return _errorRoute(settings, 'Route non trovata');
    }
  }

  // METODO PER ERRORI
  static MaterialPageRoute _errorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Errore')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Errore di navigazione',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Route: ${settings.name}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Torna alla home
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                child: const Text('TORNA ALLA HOME'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }

  // METODO PUBBLICO PER EDIT RICETTA
  static Future<dynamic> goToEditRecipe(
    BuildContext context,
    Recipe recipe,
  ) {
    return Navigator.of(context).pushNamed(
      '/recipe/edit',
      arguments: recipe,
    );
  }

  // 👇 NUOVO METODO: Naviga alla verifica email
  static Future<dynamic> goToVerifyEmail(
    BuildContext context, {
    String? token,
  }) {
    final route =
        token != null ? '/verify-email?token=$token' : '/verify-email';

    return Navigator.of(context).pushNamed(route);
  }

  // 👇 NUOVO METODO: Naviga a password dimenticata
  static Future<dynamic> goToForgotPassword(BuildContext context) {
    return Navigator.of(context).pushNamed('/forgot-password');
  }

  // 👇 NUOVO METODO: Naviga a reset password
  static Future<dynamic> goToResetPassword(BuildContext context, String token) {
    return Navigator.of(context).pushNamed(
      '/reset-password?token=$token',
    );
  }
}
