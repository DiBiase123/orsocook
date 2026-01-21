import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../utils/logger.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _username;
  String? _avatarUrl;
  bool _isLoading = false;
  DateTime? _tokenExpiry;
  bool _isVerified = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  bool get isVerified => _isVerified;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String? get avatarUrl => _avatarUrl;
  String? get refreshToken => _refreshToken;

  AuthService() {
    _clearCredentialsOnStartup();
  }

  // Pulisce credenziali all'avvio (per forzare sempre il login)
  Future<void> _clearCredentialsOnStartup() async {
    try {
      await _clearCredentials();
      AppLogger.success('Credenziali rimosse all\'avvio');
    } catch (e) {
      AppLogger.error('Errore nella pulizia all\'avvio', e);
    }
    notifyListeners();
  }

  // Salva credenziali dopo login
  Future<void> _saveCredentials({
    required String token,
    required String refreshToken,
    required String userId,
    required String username,
    required bool isVerified,
    String? avatarUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', token);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('userId', userId);
      await prefs.setString('username', username);
      await prefs.setBool('isVerified', isVerified);

      if (avatarUrl != null) {
        await prefs.setString('avatarUrl', avatarUrl);
      }

      // Scadenza token: 15 minuti - 1 minuto margine
      final expiry = DateTime.now().add(const Duration(minutes: 14));
      await prefs.setString('tokenExpiry', expiry.toIso8601String());
      _tokenExpiry = expiry;

      _token = token;
      _refreshToken = refreshToken;
      _userId = userId;
      _username = username;
      _avatarUrl = avatarUrl;
      _isVerified = isVerified;

      AppLogger.success(
          'Credenziali salvate per: $username (Verificato: $isVerified)');
    } catch (e) {
      AppLogger.error('Errore salvataggio credenziali', e);
    }
  }

  // Carica credenziali salvate
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _token = prefs.getString('token');
      _refreshToken = prefs.getString('refreshToken');
      _userId = prefs.getString('userId');
      _username = prefs.getString('username');
      _avatarUrl = prefs.getString('avatarUrl');
      _isVerified = prefs.getBool('isVerified') ?? false;

      final expiryString = prefs.getString('tokenExpiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }

      if (_token != null) {
        AppLogger.debug(
            'Credenziali caricate per: $_username (Verificato: $_isVerified)');
      }
    } catch (e) {
      AppLogger.error('Errore caricamento credenziali salvate', e);
    }
  }

  // Rimuove tutte le credenziali
  Future<void> _clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('avatarUrl');
      await prefs.remove('tokenExpiry');
      await prefs.remove('isVerified');

      _token = null;
      _refreshToken = null;
      _userId = null;
      _username = null;
      _avatarUrl = null;
      _tokenExpiry = null;
      _isVerified = false;
    } catch (e) {
      AppLogger.error('Errore rimozione credenziali', e);
    }
  }

  // Prova a refreshare il token
  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      AppLogger.error('Refresh token non disponibile');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.buildUrl()}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData.containsKey('data')) {
          final Map<String, dynamic> data = responseData['data'];
          final String newToken = data['token'] as String;

          await _saveCredentials(
            token: newToken,
            refreshToken: _refreshToken!,
            userId: _userId!,
            username: _username!,
            isVerified: _isVerified,
            avatarUrl: _avatarUrl,
          );

          AppLogger.success('Token refreshato con successo');
          notifyListeners();
          return true;
        }
      }

      AppLogger.error('Refresh token fallito: ${response.statusCode}');
      return false;
    } catch (e) {
      AppLogger.error('Errore durante refresh token', e);
      return false;
    }
  }

  // ==================== REGISTRAZIONE CON VERIFICA EMAIL ====================

  Future<Map<String, dynamic>> registerWithVerification(
      String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.auth(
        '🔄 Tentativo registrazione con verifica: $username ($email)');

    try {
      // 🔧 CORREZIONE: usa '/api/auth/register' invece di '/api/auth/register-with-verification'
      final response = await http.post(
        Uri.parse('${Config.buildUrl()}/api/auth/register'), // 👈 CORRETTO
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          AppLogger.success(
              '✅ Registrazione con verifica riuscita per: $username');

          return {
            'success': true,
            'message': responseData['message'] ??
                'Registrazione completata! Verifica la tua email per attivare l\'account.',
            'requiresVerification': true,
            'email': email,
          };
        }

        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Errore durante la registrazione',
        };
      }

      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Errore HTTP ${response.statusCode}';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      AppLogger.error('❌ Errore durante la registrazione con verifica', e);

      return {
        'success': false,
        'message': 'Errore di connessione. Verifica la rete.',
      };
    }
  }

  // ==================== VERIFICA EMAIL ====================

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.auth(
        '🔐 Tentativo verifica email con token: ${token.substring(0, 10)}...');

    try {
      final response = await http.get(
        Uri.parse('${Config.buildUrl()}/api/auth/verify-email/$token'),
        headers: {'Content-Type': 'application/json'},
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData.containsKey('data')) {
          final Map<String, dynamic> data = responseData['data'];

          if (data.containsKey('token') &&
              data.containsKey('refreshToken') &&
              data.containsKey('user')) {
            final String token = data['token'] as String;
            final String refreshToken = data['refreshToken'] as String;
            final Map<String, dynamic> user = data['user'];

            await _saveCredentials(
              token: token,
              refreshToken: refreshToken,
              userId: user['id'] as String,
              username: user['username'] as String? ?? user['email'] as String,
              isVerified: user['isVerified'] as bool? ?? true,
              avatarUrl: user['avatarUrl'] as String?,
            );

            notifyListeners();

            return {
              'success': true,
              'message': responseData['message'] ??
                  '🎉 Account verificato con successo!',
              'user': user,
            };
          }
        }

        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Errore nel formato della risposta',
        };
      }

      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Errore HTTP ${response.statusCode}';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      AppLogger.error('❌ Errore durante la verifica email', e);

      return {
        'success': false,
        'message': 'Errore di connessione. Verifica la rete.',
      };
    }
  }

  // ==================== RICHIESTA RESET PASSWORD ====================

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.auth('🔑 Richiesta reset password per: $email');

    try {
      final response = await http.post(
        Uri.parse('${Config.buildUrl()}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return {
          'success': responseData['success'] == true,
          'message': responseData['message'] ??
              'Se l\'email è registrata, riceverai istruzioni per il reset della password.',
        };
      }

      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Errore HTTP ${response.statusCode}';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      AppLogger.error('❌ Errore durante la richiesta reset password', e);

      return {
        'success': false,
        'message': 'Errore di connessione. Verifica la rete.',
      };
    }
  }

  // ==================== RESET PASSWORD ====================

  Future<Map<String, dynamic>> resetPassword(
      String token, String password, String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.auth('🔑 Reset password con token: ${token.substring(0, 10)}...');

    try {
      final response = await http.post(
        Uri.parse('${Config.buildUrl()}/api/auth/reset-password/$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return {
          'success': responseData['success'] == true,
          'message':
              responseData['message'] ?? 'Password reimpostata con successo!',
        };
      }

      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Errore HTTP ${response.statusCode}';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      AppLogger.error('❌ Errore durante il reset password', e);

      return {
        'success': false,
        'message': 'Errore di connessione. Verifica la rete.',
      };
    }
  }

  // ==================== RINVIA EMAIL DI VERIFICA ====================

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.auth('📧 Rinvio email di verifica per: $email');

    try {
      final response = await http.post(
        Uri.parse('${Config.buildUrl()}/api/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return {
          'success': responseData['success'] == true,
          'message':
              responseData['message'] ?? 'Nuova email di verifica inviata',
        };
      }

      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Errore HTTP ${response.statusCode}';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      AppLogger.error('❌ Errore durante il rinvio email di verifica', e);

      return {
        'success': false,
        'message': 'Errore di connessione. Verifica la rete.',
      };
    }
  }

  // ==================== LOGIN MIGLIORATO ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.auth('🔐 Tentativo login per: $email');

    try {
      final response = await http.post(
        Uri.parse('${Config.buildUrl()}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      _isLoading = false;
      notifyListeners();

      // Gestione account bloccato (423 Locked)
      if (response.statusCode == 423) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);

        return {
          'success': false,
          'message': errorData['message'] ?? 'Account temporaneamente bloccato',
          'locked': true,
          'lockTime': errorData['lockTime'] ?? 15,
        };
      }

      // Gestione email non verificata (403 Forbidden)
      if (response.statusCode == 403) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);

        return {
          'success': false,
          'message': errorData['message'] ??
              'Devi verificare la tua email prima di accedere',
          'requiresVerification': true,
          'email': errorData['email'] ?? email,
        };
      }

      // Login fallito (401 Unauthorized)
      if (response.statusCode == 401) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);

        return {
          'success': false,
          'message': errorData['message'] ?? 'Credenziali non valide',
          'attemptsLeft': errorData['attemptsLeft'],
        };
      }

      // Login riuscito (200 OK)
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData.containsKey('data')) {
          final Map<String, dynamic> data = responseData['data'];

          if (data.containsKey('token') &&
              data.containsKey('refreshToken') &&
              data.containsKey('user')) {
            final String token = data['token'] as String;
            final String refreshToken = data['refreshToken'] as String;
            final Map<String, dynamic> user = data['user'];

            await _saveCredentials(
              token: token,
              refreshToken: refreshToken,
              userId: user['id'] as String,
              username: user['username'] as String? ?? email,
              isVerified: user['isVerified'] as bool? ?? true,
              avatarUrl: user['avatarUrl'] as String?,
            );

            notifyListeners();

            return {
              'success': true,
              'message':
                  responseData['message'] ?? 'Login effettuato con successo!',
              'user': user,
            };
          }

          return {
            'success': false,
            'message': 'Errore nel formato della risposta dal server',
          };
        }

        final errorMsg = responseData['message'] ?? 'Credenziali non valide';
        return {
          'success': false,
          'message': errorMsg,
        };
      }

      // Altri errori HTTP
      String errorMsg;
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Errore HTTP ${response.statusCode}';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      AppLogger.error('❌ Errore durante il login', e);

      return {
        'success': false,
        'message': 'Errore di connessione. Verifica la rete.',
      };
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    // Logout sul backend (opzionale)
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('${Config.buildUrl()}/api/auth/logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      }
    } catch (e) {
      // Ignora errori backend, procedi con logout locale
    }

    await _clearCredentials();
    AppLogger.success('Logout completato');
    notifyListeners();
  }

  // ==================== VERIFICA AUTENTICAZIONE ====================

  Future<bool> checkAuth() async {
    await _loadSavedCredentials();

    if (_token == null) return false;

    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      AppLogger.warning('Token scaduto, tentativo refresh...');
      final refreshed = await _tryRefreshToken();
      if (!refreshed) return false;
    }

    return true;
  }

  // ==================== HEADERS PER RICHIESTE AUTENTICATE ====================

  Future<Map<String, String>> getAuthHeaders() async {
    await _loadSavedCredentials();

    if (_token != null &&
        _tokenExpiry != null &&
        DateTime.now().isAfter(_tokenExpiry!)) {
      await _tryRefreshToken();
    }

    final headers = {'Content-Type': 'application/json'};

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // ==================== AGGIORNA AVATAR ====================

  void updateAvatar(String newAvatarUrl) {
    _avatarUrl = newAvatarUrl;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('avatarUrl', newAvatarUrl);
    });

    AppLogger.success('Avatar aggiornato');
    notifyListeners();
  }

  // ==================== AGGIORNA STATO VERIFICA ====================

  void updateVerificationStatus(bool isVerified) {
    _isVerified = isVerified;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isVerified', isVerified);
    });

    AppLogger.debug('Stato verifica aggiornato: $isVerified');
    notifyListeners();
  }

  // ==================== PULISCI ERRORI ====================

  void clearError() {
    // Metodo per future implementazioni
    notifyListeners();
  }
}
