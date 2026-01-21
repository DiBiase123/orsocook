import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../config.dart';

class FavoriteService extends ChangeNotifier {
  // Dipendenza su AuthService
  final AuthService _authService;

  // Cache locale dei preferiti
  final Map<String, Recipe> _favoritesCache = {};
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = Duration(minutes: 5);

  // Stati
  bool _isLoading = false;
  String? _error;

  // Costruttore che riceve AuthService
  FavoriteService(this._authService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Recipe> get favorites => _favoritesCache.values.toList();

  // Verifica se una ricetta è nei preferiti
  bool isFavorite(String recipeId) {
    return _favoritesCache.containsKey(recipeId);
  }

  // Ottieni i preferiti dell'utente
  Future<List<Recipe>> getFavorites({bool forceRefresh = false}) async {
    // Controlla cache se non forzato
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      AppLogger.debug(
          'Using cached favorites (${_favoritesCache.length} items)');
      return favorites;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      AppLogger.api('GET /api/favorites');
      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/api/favorites'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Svuota cache
        _favoritesCache.clear();

        // Popola cache
        for (var item in data) {
          final recipe = Recipe.fromJson(item);
          _favoritesCache[recipe.id] = recipe;
        }

        _lastFetchTime = DateTime.now();
        _isLoading = false;

        AppLogger.success(
            'Loaded ${_favoritesCache.length} favorites from API');
        notifyListeners();

        return favorites;
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      AppLogger.error('Error loading favorites', e);
      notifyListeners();
      rethrow;
    }
  }

  // Aggiungi ai preferiti
  Future<bool> addFavorite(String recipeId) async {
    AppLogger.api('POST /api/favorites/$recipeId');

    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/api/favorites/$recipeId'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      if (response.statusCode == 201) {
        // Aggiorna cache con placeholder (se non già presente)
        if (!_favoritesCache.containsKey(recipeId)) {
          _favoritesCache[recipeId] = _createPlaceholderRecipe(recipeId);
        }

        AppLogger.success('Added recipe $recipeId to favorites');
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to add favorite: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error adding favorite', e);
      rethrow;
    }
  }

  // Rimuovi dai preferiti
  Future<bool> removeFavorite(String recipeId) async {
    AppLogger.api('DELETE /api/favorites/$recipeId');

    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Utente non autenticato');
      }

      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('${Config.apiBaseUrl}/api/favorites/$recipeId'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      if (response.statusCode == 200) {
        // Rimuovi dalla cache
        _favoritesCache.remove(recipeId);

        AppLogger.success('Removed recipe $recipeId from favorites');
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to remove favorite: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error removing favorite', e);
      rethrow;
    }
  }

  // Controlla se una ricetta è preferita
  Future<Map<String, dynamic>> checkFavorite(String recipeId) async {
    try {
      if (!_authService.isLoggedIn) {
        return {'isFavorite': false, 'favoritedAt': null};
      }

      AppLogger.api('GET /api/favorites/check/$recipeId');

      final authHeaders = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/api/favorites/check/$recipeId'),
        headers: authHeaders, // ✅ USA authHeaders
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Aggiorna cache se necessario
        if (data['isFavorite'] == true &&
            !_favoritesCache.containsKey(recipeId)) {
          _favoritesCache[recipeId] = _createPlaceholderRecipe(recipeId);
          notifyListeners();
        } else if (data['isFavorite'] == false) {
          _favoritesCache.remove(recipeId);
          notifyListeners();
        }

        return data;
      } else {
        throw Exception('Failed to check favorite: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error checking favorite status', e);
      return {'isFavorite': false, 'favoritedAt': null};
    }
  }

  // Toggle preferito (aggiunge/rimuove) - VERSIONE CORRETTA
  Future<bool> toggleFavorite(String recipeId, Recipe? recipe) async {
    final isCurrentlyFavorite = isFavorite(recipeId);
    bool operationSuccess = false;

    try {
      if (isCurrentlyFavorite) {
        AppLogger.debug('🔄 Removing favorite: $recipeId');
        operationSuccess = await removeFavorite(recipeId);
      } else {
        AppLogger.debug('🔄 Adding favorite: $recipeId');

        // Prima aggiorna cache ottimisticamente per UI responsiva
        if (recipe != null) {
          _favoritesCache[recipeId] = recipe;
        } else {
          _favoritesCache[recipeId] = _createPlaceholderRecipe(recipeId);
        }
        notifyListeners();

        operationSuccess = await addFavorite(recipeId);

        // Se l'operazione è fallita, rimuovi dalla cache
        if (!operationSuccess) {
          _favoritesCache.remove(recipeId);
          notifyListeners();
        }
      }

      return operationSuccess;
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);

      // Revert cache in caso di errore
      if (isCurrentlyFavorite) {
        // Stava rimuovendo, ma fallito -> riaggiungi alla cache
        if (recipe != null) {
          _favoritesCache[recipeId] = recipe;
        } else {
          _favoritesCache[recipeId] = _createPlaceholderRecipe(recipeId);
        }
      } else {
        // Stava aggiungendo, ma fallito -> rimuovi dalla cache
        _favoritesCache.remove(recipeId);
      }
      notifyListeners();

      rethrow;
    }
  }

  // Helper per creare recipe placeholder
  Recipe _createPlaceholderRecipe(String id) {
    return Recipe(
      id: id,
      title: 'Loading...',
      description: '',
      slug: '',
      imageUrl: null,
      prepTime: 0,
      cookTime: 0,
      servings: 0,
      difficulty: 'MEDIUM',
      isPublic: true,
      views: 0,
      author: {},
      category: {},
      ingredients: [],
      instructions: [],
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Svuota cache
  void clearCache() {
    _favoritesCache.clear();
    _lastFetchTime = null;
    notifyListeners();
  }
}
