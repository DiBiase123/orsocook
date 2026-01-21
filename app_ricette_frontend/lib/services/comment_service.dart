// lib/services/comment_service.dart - VERSIONE FINALE
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/comment.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../config.dart';

class CommentService extends ChangeNotifier {
  final AuthService _authService;

  // Cache locale dei commenti
  final Map<String, List<Comment>> _commentsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = Duration(minutes: 5);

  // Listener per aggiornamenti commenti (SOLUZIONE DART 2)
  final List<Function(String, int)> _commentUpdateListeners = [];

  bool _isLoading = false;
  String? _error;

  CommentService(this._authService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================
  // LISTENER MANAGEMENT (SOLUZIONE DART 2)
  // ============================================

  void addCommentUpdateListener(Function(String, int) listener) {
    _commentUpdateListeners.add(listener);
    AppLogger.debug(
        '🔔 CommentService: Aggiunto listener, totali: ${_commentUpdateListeners.length}');
  }

  void _notifyCommentUpdate(String recipeId) {
    final comments = getCachedComments(recipeId);
    final commentCount = comments.length;

    AppLogger.debug(
        '🔔 CommentService: Notifica update per $recipeId -> $commentCount commenti');

    for (final listener in _commentUpdateListeners) {
      listener(recipeId, commentCount);
    }
  }

  // ============================================
  // METODO PER ACCEDERE ALLA CACHE
  // ============================================

  List<Comment> getCachedComments(String recipeId) {
    return _commentsCache[recipeId] ?? [];
  }

  // ============================================
  // NUOVO METODO: AGGIORNA AVATAR NEI COMMENTI
  // ============================================

  void updateAvatarInComments(String userId, String newAvatarUrl) {
    AppLogger.debug('🔄 CommentService: Aggiornando avatar per utente $userId');

    bool updated = false;

    // Itera su tutte le cache
    _commentsCache.forEach((recipeId, comments) {
      final updatedComments = comments.map((comment) {
        final userMap = comment.user;
        final userUserId = userMap['id']?.toString();

        if (userUserId == userId) {
          // Crea una nuova mappa con l'avatar aggiornato
          final updatedUserMap = Map<String, dynamic>.from(userMap);
          updatedUserMap['avatarUrl'] = newAvatarUrl;

          // Crea nuovo oggetto Comment con user aggiornato
          final updatedComment = comment.copyWith(user: updatedUserMap);
          updated = true;
          return updatedComment;
        }
        return comment;
      }).toList();

      if (updated) {
        _commentsCache[recipeId] = updatedComments;
        AppLogger.debug(
            '✅ Avatar aggiornato nei commenti per ricetta $recipeId');
      }
    });

    if (updated) {
      notifyListeners();
      AppLogger.success(
          '🎯 Avatar aggiornato in tutti i commenti dell\'utente $userId');
    }
  }

  // ============================================
  // METODI PUBBLICI
  // ============================================

  // Ottieni commenti per una ricetta
  Future<List<Comment>> getComments(String recipeId,
      {bool forceRefresh = false}) async {
    // Controlla cache
    if (!forceRefresh &&
        _commentsCache.containsKey(recipeId) &&
        _cacheTimestamps.containsKey(recipeId) &&
        DateTime.now().difference(_cacheTimestamps[recipeId]!) <
            _cacheDuration) {
      AppLogger.debug('✅ Commenti dalla cache per $recipeId');
      return _commentsCache[recipeId]!;
    }

    _isLoading = true;
    notifyListeners();

    try {
      AppLogger.api('GET /api/recipes/$recipeId/comments');

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/api/recipes/$recipeId/comments'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('📊 Commenti ricevuti: ${data['data']?.length ?? 0}');

        final comments = (data['data'] as List)
            .map((json) => Comment.fromJson(json))
            .toList();

        // Aggiorna cache
        _commentsCache[recipeId] = comments;
        _cacheTimestamps[recipeId] = DateTime.now();

        _error = null;
        return comments;
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Errore caricamento commenti', e);
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crea nuovo commento
  Future<Comment> createComment(String recipeId, String content) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      AppLogger.api('POST /api/recipes/$recipeId/comments');

      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/api/recipes/$recipeId/comments'),
        headers: {
          'Content-Type': 'application/json',
          ...await _authService.getAuthHeaders(),
        },
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        AppLogger.success('✅ Commento creato: ${data['data']['id']}');

        final newComment = Comment.fromJson(data['data']);

        // Aggiorna cache
        if (_commentsCache.containsKey(recipeId)) {
          _commentsCache[recipeId] = [newComment, ..._commentsCache[recipeId]!];
          _cacheTimestamps[recipeId] = DateTime.now();
        }

        notifyListeners();
        _notifyCommentUpdate(recipeId); // 🔔 Notifica listener
        return newComment;
      } else {
        throw Exception('Failed to create comment: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Errore creazione commento', e);
      rethrow;
    }
  }

  // Modifica commento
  Future<Comment> updateComment(String commentId, String content) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      AppLogger.api('PUT /api/comments/$commentId');

      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.put(
        Uri.parse('${Config.apiBaseUrl}/api/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          ...authHeaders, // ✅ USA authHeaders
        },
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.success('✅ Commento aggiornato: $commentId');

        final updatedComment = Comment.fromJson(data['data']);

        // Aggiorna cache e trova recipeId
        String? recipeId;
        for (final entry in _commentsCache.entries) {
          final index = entry.value.indexWhere((c) => c.id == commentId);
          if (index != -1) {
            _commentsCache[entry.key]![index] = updatedComment;
            _cacheTimestamps[entry.key] = DateTime.now();
            recipeId = entry.key;
            break;
          }
        }

        notifyListeners();

        // Notifica listener se abbiamo trovato recipeId
        if (recipeId != null) {
          _notifyCommentUpdate(recipeId); // 🔔 Notifica listener
        }

        return updatedComment;
      } else {
        throw Exception('Failed to update comment: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Errore aggiornamento commento', e);
      rethrow;
    }
  }

  // Elimina commento
  Future<bool> deleteComment(String commentId, String recipeId) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      AppLogger.api('DELETE /api/comments/$commentId');

      final response = await http.delete(
        Uri.parse('${Config.apiBaseUrl}/api/comments/$commentId'),
        headers: await _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        AppLogger.success('✅ Commento eliminato: $commentId');

        // Aggiorna cache
        if (_commentsCache.containsKey(recipeId)) {
          _commentsCache[recipeId] = _commentsCache[recipeId]!
              .where((comment) => comment.id != commentId)
              .toList();
          _cacheTimestamps[recipeId] = DateTime.now();
        }

        notifyListeners();
        _notifyCommentUpdate(recipeId); // 🔔 Notifica listener
        return true;
      } else {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Errore eliminazione commento', e);
      rethrow;
    }
  }

  // Svuota cache
  void clearCache() {
    _commentsCache.clear();
    _cacheTimestamps.clear();
    notifyListeners();
  }

  // Svuota cache per una ricetta specifica
  void clearCacheForRecipe(String recipeId) {
    _commentsCache.remove(recipeId);
    _cacheTimestamps.remove(recipeId);
    notifyListeners();
  }
}
