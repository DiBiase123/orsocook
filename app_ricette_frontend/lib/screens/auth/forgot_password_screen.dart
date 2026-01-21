// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🔑 ForgotPasswordScreen inizializzata');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email è obbligatoria';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Inserisci un\'email valida';
    }
    return null;
  }

  Future<void> _submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.debug('❌ Form non valido');
      return;
    }

    final currentContext = context;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    AppLogger.debug('🔑 Richiesta reset password per: ${_emailController.text}');

    try {
      final authService = Provider.of<AuthService>(currentContext, listen: false);
      final result = await authService.forgotPassword(_emailController.text.trim());

      if (currentContext.mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (result['success'] == true) {
        AppLogger.success('✅ Richiesta reset password inviata');
        
        if (currentContext.mounted) {
          setState(() {
            _isSuccess = true;
            _successMessage = result['message'];
          });
        }
      } else {
        AppLogger.error('❌ Richiesta reset password fallita: ${result['message']}');
        
        if (currentContext.mounted) {
          setState(() {
            _isSuccess = false;
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = 'Errore di connessione';
        });
      }

      AppLogger.error('❌ Errore durante la richiesta reset password', e);
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.lock_reset,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        const Text(
          'Password dimenticata?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inserisci la tua email per reimpostare la password',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
        filled: true,
        hintText: 'es. mario@esempio.com',
      ),
      validator: _validateEmail,
      onChanged: (_) {
        if (_errorMessage != null || _successMessage != null) {
          setState(() {
            _errorMessage = null;
            _successMessage = null;
          });
        }
      },
      onFieldSubmitted: (_) => _submitForgotPassword(),
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

  Widget _buildSuccessSection() {
    if (!_isSuccess) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email inviata!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _successMessage ?? 
            'Se l\'email è registrata, riceverai istruzioni per reimpostare la password.',
            style: const TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Text(
            '⚠️ Controlla la cartella spam se non trovi l\'email nella posta in arrivo.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForgotPassword,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.deepOrange,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'INVIA ISTRUZIONI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Torna al ',
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  AppLogger.navigation('⬅️ Torna a LoginScreen');
                  final currentContext = context;
                  if (currentContext.mounted) {
                    Navigator.of(currentContext).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
          child: const Text(
            'Login',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ Building ForgotPasswordScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Dimenticata'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppLogger.navigation('⬅️ Torna indietro da ForgotPasswordScreen');
            final currentContext = context;
            if (currentContext.mounted) {
              Navigator.of(currentContext).pop();
            }
          },
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
                const SizedBox(height: 16),
                _buildErrorSection(),
                _buildSuccessSection(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 24),
                _buildLoginLink(),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Cosa succede dopo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildStepItem('1. Riceverai un\'email con un link di reset'),
                _buildStepItem('2. Clicca sul link (valido per 1 ora)'),
                _buildStepItem('3. Imposta una nuova password'),
                _buildStepItem('4. Accedi con la nuova password'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, color: Colors.deepOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
