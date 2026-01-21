import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import '../../screens/home/home_screen.dart';
import '../../navigation/app_router.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('LoginScreen inizializzata');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
    AppLogger.debug('LoginScreen disposed');
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email è obbligatoria';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Inserisci un\'email valida';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La password è obbligatoria';
    }
    if (value.length < 6) {
      return 'La password deve avere almeno 6 caratteri';
    }
    return null;
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.debug('Form login non valido');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AppLogger.debug('Tentativo login per: ${_emailController.text}');

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // 🔧 CORREZIONE 1: Controlla mounted PRIMA di setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        AppLogger.success('Login riuscito per: ${_emailController.text}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login effettuato con successo!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        AppLogger.error('Login fallito: ${result['message']}');

        // 👇 NUOVA GESTIONE: EMAIL NON VERIFICATA
        if (result['requiresVerification'] == true) {
          _showEmailNotVerifiedDialog(
            context,
            result['email'] ?? _emailController.text.trim(),
          );
          return;
        }

        // 👇 NUOVA GESTIONE: ACCOUNT BLOCCATO
        if (result['locked'] == true) {
          final lockTime = result['lockTime'] ?? 15;
          _showAccountLockedDialog(context, lockTime);
          return;
        }

        if (mounted) {
          setState(() {
            _errorMessage = result['message'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Errore durante il login'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // 🔧 CORREZIONE 2: Controlla mounted PRIMA di setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Errore di connessione';
      });

      AppLogger.error('Errore durante il login', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore di connessione. Verifica la rete.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 👇 NUOVO METODO: Dialog per email non verificata
  void _showEmailNotVerifiedDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📧 Email Non Verificata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Devi verificare la tua email prima di accedere.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Controlla la tua posta e clicca sul link di verifica.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Controlla anche la cartella spam.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Rinvia email di verifica
              _resendVerificationEmail(email);
            },
            child: const Text('RINVIA EMAIL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CHIUDI'),
          ),
        ],
      ),
    );
  }

  // 👇 NUOVO METODO: Rinvia email di verifica
  Future<void> _resendVerificationEmail(String email) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.resendVerificationEmail(email);

      // 🔧 CORREZIONE 3: Controlla mounted PRIMA di setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Nuova email di verifica inviata!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Errore durante l\'invio'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // 🔧 CORREZIONE 4: Controlla mounted PRIMA di setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore di connessione'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 👇 NUOVO METODO: Dialog per account bloccato
  void _showAccountLockedDialog(BuildContext context, int lockTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🔒 Account Temporaneamente Bloccato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Troppi tentativi di login falliti.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'account è bloccato per $lockTime minuti.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Per motivi di sicurezza, riprova più tardi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('HO CAPITO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Naviga a password dimenticata
              _navigateToForgotPassword();
            },
            child: const Text('PASSWORD DIMENTICATA'),
          ),
        ],
      ),
    );
  }

  // 👇 NUOVO METODO: Naviga a password dimenticata
  void _navigateToForgotPassword() {
    AppLogger.debug('Navigazione a ForgotPasswordScreen');

    // 🔧 CORREZIONE 5: Controlla mounted PRIMA di navigare
    if (!mounted) return;
    AppRouter.goToForgotPassword(context);
  }

  void _navigateToHomeWithoutAuth() {
    AppLogger.debug('Navigazione a Home senza autenticazione');

    // 🔧 CORREZIONE 6: Controlla mounted PRIMA di navigare
    if (!mounted) return;

    // Assicurati che l'utente sia logged out
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isLoggedIn) {
      authService.logout();
    }

    // Naviga alla home screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToRegister() {
    AppLogger.debug('Navigazione a RegisterScreen');

    // 🔧 CORREZIONE 7: Controlla mounted PRIMA di navigare
    if (!mounted) return;

    Navigator.pushNamed(context, '/register');
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.restaurant_menu,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        const Text(
          'OrsoCook',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Accedi al tuo account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
        filled: true,
      ),
      validator: _validateEmail,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            AppLogger.debug('Toggle visibilità password');
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: const OutlineInputBorder(),
        filled: true,
      ),
      validator: _validatePassword,
      onFieldSubmitted: (_) => _submitLogin(),
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
      },
    );
  }

  Widget _buildErrorSection() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitLogin,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Text(
              'ACCEDI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildRegisterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Non hai un account? ',
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: _isLoading ? null : _navigateToRegister,
          child: const Text(
            'Registrati',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Oppure accedi con',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.facebook, color: Colors.blue),
              onPressed: () {
                AppLogger.debug('Tentativo login con Facebook');
              },
              iconSize: 40,
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 40),
              onPressed: () {
                AppLogger.debug('Tentativo login con Google');
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building LoginScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToHomeWithoutAuth,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 16),
                // 👇 MODIFICATO: Password dimenticata funzionante
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _navigateToForgotPassword,
                    child: const Text(
                      'Password dimenticata?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildErrorSection(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildRegisterSection(),
                _buildSocialLogin(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _navigateToHomeWithoutAuth,
                  child: const Text(
                    'Continua senza account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
