// lib/services/like_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../utils/logger.dart';
import '../config.dart';

class LikeService extends ChangeNotifier {
  // Dipendenza su AuthService
  final AuthService _authService;

  // Cache locale dei likes
  final Map<String, int> _likesCountCache = {};
  final Map<String, bool> _likedStatusCache = {};

  // Lista di listener per aggiornamenti like
  final List<Function(String, bool)> _likeUpdateListeners = [];

  // Stati
  final bool _isLoading = false;
  String? _error;

  // Costruttore che riceve AuthService
  LikeService(this._authService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================
  // LISTENER MANAGEMENT
  // ============================================

  // Aggiungi un listener per aggiornamenti like
  void addLikeUpdateListener(Function(String recipeId, bool isLiked) listener) {
    if (!_likeUpdateListeners.contains(listener)) {
      _likeUpdateListeners.add(listener);
      AppLogger.debug(
          '📡 LikeService: Listener aggiunto, totali: ${_likeUpdateListeners.length}');
    }
  }

  // Rimuovi un listener
  void removeLikeUpdateListener(Function(String, bool) listener) {
    _likeUpdateListeners.remove(listener);
    AppLogger.debug(
        '📡 LikeService: Listener rimosso, totali: ${_likeUpdateListeners.length}');
  }

  // Notifica tutti i listener
  void _notifyLikeUpdate(String recipeId, bool isLiked) {
    AppLogger.debug(
        '📢 LikeService: Notificando ${_likeUpdateListeners.length} listener(s) per $recipeId -> $isLiked');

    for (final listener in _likeUpdateListeners) {
      try {
        listener(recipeId, isLiked);
      } catch (e) {
        AppLogger.error('Errore in like update listener', e);
      }
    }
  }

  // ============================================
  // METODI PUBBLICI
  // ============================================

  // Verifica se una ricetta è stata messa like dall'utente
  bool isLiked(String recipeId) {
    return _likedStatusCache[recipeId] ?? false;
  }

  // Ottieni il conteggio likes per una ricetta
  int getLikesCount(String recipeId) {
    return _likesCountCache[recipeId] ?? 0;
  }

  // Pre-carica i likes count per una lista di ricette
  Future<void> preloadLikesCount(List<String> recipeIds) async {
    if (recipeIds.isEmpty) return;

    AppLogger.debug(
        '📥 Preloading likes count for ${recipeIds.length} recipes');

    try {
      // Filtra solo le ricette non già in cache
      final recipesToLoad =
          recipeIds.where((id) => !_likesCountCache.containsKey(id)).toList();

      if (recipesToLoad.isEmpty) {
        AppLogger.debug('✅ All likes counts already cached');
        return;
      }

      AppLogger.debug('📊 Need to load ${recipesToLoad.length} likes counts');

      // Carica i counts in parallelo
      await Future.wait(
        recipesToLoad.map((recipeId) => getLikesCountFromAPI(recipeId)),
      );

      AppLogger.success(
          '✅ Likes count preloaded for ${recipesToLoad.length} recipes');
    } catch (e) {
      AppLogger.error('Error preloading likes count', e);
    }
  }

  // Ottieni likes count da API (pubblico)
  Future<int> getLikesCountFromAPI(String recipeId) async {
    AppLogger.api('GET /api/recipes/$recipeId/likes');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/api/recipes/$recipeId/likes'),
      );

      AppLogger.debug('📡 Response status: ${response.statusCode}');
      AppLogger.debug('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ DEBUG: Mostra struttura completa
        AppLogger.debug('📊 Parsed data: $data');
        AppLogger.debug('📊 Data keys: ${data.keys}');

        // Il backend ritorna: {"success":true,"data":{"count":1}}
        // Quindi dobbiamo: data['data']['count']

        final count = data['data']?['count'] ?? 0;

        AppLogger.debug('✅ Final count for $recipeId: $count');

        // Aggiorna cache
        _likesCountCache[recipeId] = count;

        return count;
      } else {
        throw Exception('Failed to get likes count: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error getting likes count', e);
      rethrow;
    }
  }

  // Controlla se l'utente ha messo like (privato)
  Future<Map<String, dynamic>> checkLiked(String recipeId) async {
    try {
      if (!_authService.isLoggedIn) {
        return {'liked': false, 'likedAt': null};
      }

      AppLogger.api('GET /api/recipes/$recipeId/liked');

      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/api/recipes/$recipeId/liked'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ CORRETTO: Accedi a data['data']['liked']
        final likedStatus = data['data']?['liked'] ?? false;

        AppLogger.debug('Recipe $recipeId liked status from API: $likedStatus');

        // Aggiorna cache
        _likedStatusCache[recipeId] = likedStatus;
        notifyListeners();

        return {'liked': likedStatus, 'likedAt': null};
      } else {
        throw Exception('Failed to check liked status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error checking liked status', e);
      return {'liked': false, 'likedAt': null};
    }
  }

  // ============================================
  // METODI HELPER
  // ============================================

  // Aggiorna la conta likes dal backend (REALE)
  Future<int> _refreshLikesCount(String recipeId) async {
    try {
      AppLogger.debug('🔄 Aggiornamento conta likes per $recipeId da API');
      final count = await getLikesCountFromAPI(recipeId);
      _likesCountCache[recipeId] = count;
      AppLogger.debug('✅ Nuova conta likes per $recipeId: $count');
      return count;
    } catch (e) {
      AppLogger.error('❌ Errore aggiornamento conta likes', e);
      return _likesCountCache[recipeId] ?? 0;
    }
  }

  // ============================================
  // METODI PER AGGIUNTA/RIMOZIONE LIKE
  // ============================================

  // Aggiungi like (privato)
  Future<bool> addLike(String recipeId) async {
    AppLogger.api('POST /api/recipes/$recipeId/like');

    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }
      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/api/recipes/$recipeId/like'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      // ✅ ACCETTA sia 200 che 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        AppLogger.debug('Add like response: $data');

        // 1. Aggiorna cache stato liked
        _likedStatusCache[recipeId] = true;

        // 2. OTTIENI CONTA REALE DAL BACKEND (NON usare incremento locale)
        await _refreshLikesCount(recipeId);

        AppLogger.success(
            '✅ Like aggiunto a ricetta $recipeId (status: ${response.statusCode})');

        // 3. Notifica UI
        notifyListeners();

        // 4. Notifica altri servizi
        _notifyLikeUpdate(recipeId, true);

        return true;
      } else {
        throw Exception('Failed to add like: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error adding like', e);
      rethrow;
    }
  }

  // Rimuovi like (privato)
  Future<bool> removeLike(String recipeId) async {
    AppLogger.api('DELETE /api/recipes/$recipeId/like');

    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('${Config.apiBaseUrl}/api/recipes/$recipeId/like'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      // ✅ ACCETTA 200
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('Remove like response: $data');

        // 1. Aggiorna cache stato liked
        _likedStatusCache[recipeId] = false;

        // 2. OTTIENI CONTA REALE DAL BACKEND (NON usare decremento locale)
        await _refreshLikesCount(recipeId);

        AppLogger.success('✅ Like rimosso da ricetta $recipeId');

        // 3. Notifica UI
        notifyListeners();

        // 4. Notifica altri servici
        _notifyLikeUpdate(recipeId, false);

        return true;
      } else {
        throw Exception('Failed to remove like: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error removing like', e);
      rethrow;
    }
  }

  // Toggle like (aggiunge/rimuove)
  Future<bool> toggleLike(String recipeId) async {
    final isCurrentlyLiked = isLiked(recipeId);

    try {
      if (isCurrentlyLiked) {
        return await removeLike(recipeId);
      } else {
        return await addLike(recipeId);
      }
    } catch (e) {
      AppLogger.error('Error toggling like', e);
      rethrow;
    }
  }

  // Svuota cache
  void clearCache() {
    _likesCountCache.clear();
    _likedStatusCache.clear();
    notifyListeners();
  }
}
