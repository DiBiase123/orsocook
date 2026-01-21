import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({super.key, this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    AppLogger.auth('🔐 RegisterScreen inizializzata');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
    AppLogger.debug('♻️ RegisterScreen disposed');
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Il nome utente è obbligatorio';
    }
    if (value.length < 3) {
      return 'Almeno 3 caratteri';
    }
    if (value.length > 20) {
      return 'Massimo 20 caratteri';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo lettere, numeri e underscore';
    }
    return null;
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La password è obbligatoria';
    }
    if (value.length < 8) {
      return 'Almeno 8 caratteri';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Almeno una lettera maiuscola';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Almeno un numero';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Conferma la password';
    }
    if (value != _passwordController.text) {
      return 'Le password non corrispondono';
    }
    return null;
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.debug('❌ Form registrazione non valido');
      return;
    }

    // Salva context localmente prima di operazioni async
    final currentContext = context;

    if (!_acceptTerms) {
      AppLogger.debug('❌ Termini non accettati');

      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Devi accettare i termini e condizioni'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AppLogger.auth(
        '🔄 Tentativo registrazione: ${_usernameController.text} (${_emailController.text})');

    try {
      final authService =
          Provider.of<AuthService>(currentContext, listen: false);

      final result = await authService.registerWithVerification(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (currentContext.mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (result['success'] == true) {
        AppLogger.success(
            '✅ Registrazione riuscita per: ${_usernameController.text}');

        final String email = _emailController.text.trim();

        // 👇 MOSTRA SOLO IL DIALOG - NO SNACKBAR
        if (result['requiresVerification'] == true && currentContext.mounted) {
          await _showVerificationDialog(currentContext, email);
        } else {
          // Caso raro: registrazione senza verifica (dovrebbe accadere solo in test)
          if (currentContext.mounted) {
            await _showSuccessDialog(currentContext);
          }
        }

        // Callback per successo
        widget.onRegisterSuccess?.call();
      } else {
        AppLogger.error('❌ Registrazione fallita: ${result['message']}');

        if (currentContext.mounted) {
          setState(() {
            _errorMessage = result['message'];
          });

          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Errore durante la registrazione'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore di connessione';
        });
      }

      AppLogger.error('❌ Errore durante la registrazione', e);

      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Errore di connessione. Verifica la rete.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // 👇 DIALOG PER VERIFICA EMAIL (caso principale)
  Future<void> _showVerificationDialog(
      BuildContext context, String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // L'utente DEVE cliccare
      builder: (context) => AlertDialog(
        title: const Text(
          '🎉 Registrazione Completata!',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_unread, size: 70, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Abbiamo inviato un\'email di verifica a:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Per attivare il tuo account:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildStep('1️⃣ Controlla la tua casella email', Icons.inbox),
              _buildStep('2️⃣ Cerca l\'email di OrsoCook', Icons.search),
              _buildStep('3️⃣ Clicca sul link di verifica', Icons.link),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: const Text(
                  '⚠️ Se non trovi l\'email, controlla la cartella SPAM/Posta indesiderata',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Chiude il dialog
              Navigator.of(context)
                  .pop(true); // Torna alla schermata precedente
            },
            child: const Text('HO CAPITO',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 👇 DIALOG PER SUCCESSO SENZA VERIFICA (solo per test/backup)
  Future<void> _showSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Registrazione Completata!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 70, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Il tuo account è stato creato con successo!\n\n'
              'Ora puoi accedere con le tue credenziali.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Chiude il dialog
              Navigator.of(context)
                  .pop(true); // Torna alla schermata precedente
            },
            child: const Text('ACCEDI'),
          ),
        ],
      ),
    );
  }

  // 👇 Widget per i passaggi nel dialog
  Widget _buildStep(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
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
          'Unisciti a OrsoCook',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Crea il tuo account gratuito',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nome utente',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
        filled: true,
        hintText: 'es. chef_mario',
      ),
      validator: _validateUsername,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
      },
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
        hintText: 'es. mario@esempio.com',
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
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            AppLogger.debug('👁️ Toggle visibilità password');
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: const OutlineInputBorder(),
        filled: true,
        helperText: 'Minimo 8 caratteri, 1 maiuscola, 1 numero',
      ),
      validator: _validatePassword,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
        // Valida anche la conferma password
        if (_confirmPasswordController.text.isNotEmpty) {
          _formKey.currentState?.validate();
        }
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Conferma Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            AppLogger.debug('👁️ Toggle visibilità conferma password');
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: const OutlineInputBorder(),
        filled: true,
      ),
      validator: _validateConfirmPassword,
      onFieldSubmitted: (_) => _submitRegistration(),
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            AppLogger.debug('📝 Termini accettati: $value');
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              AppLogger.debug('📄 Apri termini e condizioni');
              final currentContext = context;
              showDialog(
                context: currentContext,
                builder: (context) => AlertDialog(
                  title: const Text('Termini e Condizioni'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Benvenuto in OrsoCook!\n\n'
                      '1. Le ricette devono essere originali o debitamente attribuite\n'
                      '2. Non sono ammessi contenuti offensivi o illegali\n'
                      '3. Rispetta la privacy degli altri utenti\n'
                      '4. I contenuti pubblicati rimangono di proprietà degli autori\n'
                      '5. Ci riserviamo il diritto di rimuovere contenuti inappropriati\n\n'
                      'Utilizzando l\'app, accetti questi termini.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        final dialogContext = context;
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      child: const Text('CHIUDI'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Accetto i termini e condizioni',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
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

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitRegistration,
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
              'REGISTRATI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Hai già un account? ',
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  AppLogger.navigation('⬅️ Torna a LoginScreen');
                  final currentContext = context;
                  if (currentContext.mounted) {
                    Navigator.of(currentContext).pop();
                  }
                },
          child: const Text(
            'Accedi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    final password = _passwordController.text;

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    Color color;
    String text;

    switch (strength) {
      case 0:
      case 1:
        color = Colors.red;
        text = 'Debole';
        break;
      case 2:
        color = Colors.orange;
        text = 'Media';
        break;
      case 3:
        color = Colors.lightGreen;
        text = 'Buona';
        break;
      case 4:
        color = Colors.green;
        text = 'Forte';
        break;
      default:
        color = Colors.grey;
        text = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Forza password: $text',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey[300],
          color: color,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ Building RegisterScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppLogger.navigation('⬅️ Torna indietro da RegisterScreen');
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
                const SizedBox(height: 32),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                _buildPasswordStrength(),
                const SizedBox(height: 16),
                _buildConfirmPasswordField(),
                const SizedBox(height: 16),
                _buildTermsCheckbox(),
                const SizedBox(height: 16),
                _buildErrorSection(),
                const SizedBox(height: 24),
                _buildRegisterButton(),
                const SizedBox(height: 24),
                _buildLoginLink(),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Registrandoti, potrai:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildFeatureItem('Creare e salvare le tue ricette'),
                _buildFeatureItem('Commentare altre ricette'),
                _buildFeatureItem('Salvare ricette preferite'),
                _buildFeatureItem('Ricevere notifiche personalizzate'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
