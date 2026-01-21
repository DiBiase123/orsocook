import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../config.dart';
import '../utils/logger.dart';

class AvatarService extends ChangeNotifier {
  bool _isUploading = false;
  String? _uploadError;

  // Getters
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  // Helper per determinare il MediaType in base all'estensione
  MediaType _getMediaType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // Reset error
  void _resetError() {
    if (_uploadError != null) {
      _uploadError = null;
      notifyListeners();
    }
  }

  // Upload avatar
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    _isUploading = true;
    _resetError();
    notifyListeners();

    AppLogger.log("AvatarService: Upload avatar iniziato");

    try {
      // Prepara la richiesta multipart
      final url = Config.buildUrl('/api/auth/avatar');

      // Ottieni il token da SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Utente non autenticato');
      }

      // DEBUG ESTESO
      AppLogger.debug("=== AVATAR SERVICE DEBUG ===");
      AppLogger.debug("1. File path: ${imageFile.path}");

      try {
        final exists = await imageFile.exists();
        AppLogger.debug("2. File exists: $exists");

        if (exists) {
          final size = await imageFile.length();
          AppLogger.debug("3. File size: $size bytes");
        }
      } catch (e) {
        AppLogger.debug("2-3. File check error: $e");
      }

      AppLogger.debug("4. Token length: ${token.length}");
      AppLogger.debug(
          "5. Token (first 20): ${token.substring(0, token.length < 20 ? token.length : 20)}...");
      AppLogger.debug("6. URL: $url");

      // Crea la richiesta multipart
      final request = http.MultipartRequest('PUT', Uri.parse(url));

      // Aggiungi header Authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Aggiungi il file immagine
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      // Ottieni l'estensione del file per determinare il content-type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final contentType = _getMediaType(extension);

      AppLogger.debug("11. File extension: $extension");
      AppLogger.debug("12. Content-Type: ${contentType.mimeType}");

      final multipartFile = http.MultipartFile(
        'avatar',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
        contentType: contentType,
      );

      request.files.add(multipartFile);

      // DEBUG aggiuntivo
      AppLogger.debug("7. Field name: '${multipartFile.field}'");
      AppLogger.debug("8. Filename: '${multipartFile.filename}'");
      AppLogger.debug("9. File length: ${multipartFile.length}");
      AppLogger.debug("10. Request files count: ${request.files.length}");
      AppLogger.debug("=== END AVATAR DEBUG ===");

      // Invia la richiesta
      AppLogger.debug("Invio richiesta multipart...");
      final streamedResponse = await request.send();

      // DEBUG streaming response
      AppLogger.debug("StreamedResponse ricevuto");
      AppLogger.debug(
          "Content-Type: ${streamedResponse.headers['content-type']}");
      AppLogger.debug(
          "Content-Length: ${streamedResponse.headers['content-length']}");

      final response = await http.Response.fromStream(streamedResponse);

      _isUploading = false;

      // Debug della risposta
      AppLogger.debug("Avatar upload response status: ${response.statusCode}");
      AppLogger.debug("Avatar upload response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          AppLogger.success("Avatar upload completato con successo");

          // Estrai l'URL del nuovo avatar dalla risposta
          final userData = responseData['data']['user'];
          final newAvatarUrl = userData['avatarUrl'];
          final successMessage =
              responseData['message'] ?? 'Avatar aggiornato con successo';

          // Salva l'avatar URL in SharedPreferences
          await prefs.setString('avatarUrl', newAvatarUrl);
          AppLogger.debug(
              "Avatar URL salvato in SharedPreferences: $newAvatarUrl");

          // Aggiorna il token se presente nella risposta (opzionale)
          if (responseData['data']['token'] != null) {
            await prefs.setString('token', responseData['data']['token']);
          }

          notifyListeners();

          return {
            'success': true,
            'message': successMessage,
            'avatarUrl': newAvatarUrl,
            'user': userData,
          };
        } else {
          _uploadError = responseData['message'] ?? 'Errore sconosciuto';
          AppLogger.error("Avatar upload fallito: $_uploadError");
          notifyListeners();

          return {
            'success': false,
            'message': _uploadError,
          };
        }
      } else {
        String errorMsg;
        try {
          final errorData = jsonDecode(response.body);
          errorMsg =
              errorData['message'] ?? 'Errore HTTP ${response.statusCode}';
        } catch (e) {
          errorMsg = 'Errore HTTP ${response.statusCode}';
        }

        _uploadError = errorMsg;
        AppLogger.error("Avatar upload HTTP error: $_uploadError");
        notifyListeners();

        return {
          'success': false,
          'message': _uploadError,
        };
      }
    } catch (e) {
      _isUploading = false;
      _uploadError = e.toString();

      AppLogger.error("Avatar upload exception", e);
      notifyListeners();

      return {
        'success': false,
        'message': 'Errore durante l\'upload: ${e.toString()}',
      };
    }
  }

  // Delete avatar (opzionale)
  Future<Map<String, dynamic>> deleteAvatar() async {
    AppLogger.log("AvatarService: deleteAvatar non implementato nel backend");

    return {
      'success': false,
      'message': 'Eliminazione avatar non supportata',
    };
  }

  // Reset stato
  void reset() {
    _isUploading = false;
    _uploadError = null;
    notifyListeners();
  }
}
