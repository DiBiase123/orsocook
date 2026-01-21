import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/recipe.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class RecipeService extends ChangeNotifier {
  final Dio _dio = Dio();
  final AuthService _authService;

  List<Recipe> _cachedRecipes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _lastError;

  RecipeService(this._authService) {
    _dio.options.baseUrl = 'http://localhost:5000/api';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  List<Recipe> get cachedRecipes => _cachedRecipes;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get hasError => _lastError != null;
  String? get lastError => _lastError;

  Future<Map<String, String>> _getAuthHeaders() async {
    return await _authService.getAuthHeaders();
  }

  Future<List<Recipe>> fetchRecipes(
      {bool forceRefresh = false, int page = 1}) async {
    if (_isLoading && !forceRefresh) return _cachedRecipes;

    AppLogger.api('Fetch ricette pagina $page');

    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      final authHeaders = await _getAuthHeaders();

      final response = await _dio.get(
        '/recipes',
        queryParameters: {'page': page, 'limit': 10},
        options: Options(headers: authHeaders),
      );

      if (response.data['success'] != true) {
        final error = response.data['message'] ?? 'Errore sconosciuto';
        throw Exception(error);
      }

      final List<Recipe> recipes = _parseRecipesResponse(response.data['data']);

      if (forceRefresh || page == 1) {
        _cachedRecipes = recipes;
      } else {
        _cachedRecipes.addAll(recipes);
      }

      _hasMore = recipes.isNotEmpty;
      _currentPage = page;

      AppLogger.success('${recipes.length} ricette caricate');
      return _cachedRecipes;
    } catch (e) {
      _lastError = e.toString();
      AppLogger.error('Errore fetch ricette', e);
      return _cachedRecipes;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Recipe> _parseRecipesResponse(dynamic data) {
    List<dynamic> recipesData = [];

    if (data is Map) {
      if (data.containsKey('recipes')) {
        recipesData = data['recipes'] as List<dynamic>;
      } else if (data.containsKey('data')) {
        final nested = data['data'];
        if (nested is Map && nested.containsKey('recipes')) {
          recipesData = nested['recipes'] as List<dynamic>;
        } else if (nested is List) {
          recipesData = nested;
        }
      }
    } else if (data is List) {
      recipesData = data;
    }

    final List<Recipe> recipes = [];

    for (var json in recipesData) {
      if (json is Map) {
        try {
          recipes.add(Recipe.fromJson(Map<String, dynamic>.from(json)));
        } catch (e) {
          AppLogger.error('Errore conversione ricetta', e);
        }
      }
    }

    return recipes;
  }

  Future<Recipe?> getRecipeById(String id) async {
    // Cerca nella cache
    for (var recipe in _cachedRecipes) {
      if (recipe.id == id) return recipe;
    }

    // Se non trovato in cache, fetch dal server
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await _dio.get(
        '/recipes/$id',
        options: Options(headers: authHeaders),
      );

      if (response.data['success'] == true) {
        final json = response.data['data'] as Map<String, dynamic>;
        final recipe = Recipe.fromJson(json);

        _cachedRecipes.add(recipe);
        notifyListeners();

        return recipe;
      }
    } catch (e) {
      AppLogger.error('Errore fetch dettaglio', e);
    }

    return null;
  }

  Future<Recipe?> createRecipe(Recipe recipe) async {
    AppLogger.api('Creazione ricetta: ${recipe.title}');

    try {
      final authHeaders = await _getAuthHeaders();
      final response = await _dio.post(
        '/recipes',
        data: recipe.toJson(),
        options: Options(headers: authHeaders),
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Errore creazione');
      }

      final json = response.data['data'] as Map<String, dynamic>;
      final newRecipe = Recipe.fromJson(json);

      if (newRecipe.id.isEmpty) {
        throw Exception('Recipe ID vuoto dopo creazione');
      }

      _cachedRecipes.insert(0, newRecipe);
      notifyListeners();

      AppLogger.success('Ricetta creata: ${newRecipe.title}');
      return newRecipe;
    } catch (e) {
      AppLogger.error('Errore creazione ricetta', e);
      return null;
    }
  }

  Future<Recipe?> updateRecipe(String id, Recipe recipe) async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await _dio.put(
        '/recipes/$id',
        data: recipe.toJson(),
        options: Options(headers: authHeaders),
      );

      if (response.data['success'] != true) return null;

      final json = response.data['data'] as Map<String, dynamic>;
      final updatedRecipe = Recipe.fromJson(json);

      final index = _cachedRecipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _cachedRecipes[index] = updatedRecipe;
        notifyListeners();
      }

      return updatedRecipe;
    } catch (e) {
      AppLogger.error('Errore aggiornamento', e);
      return null;
    }
  }

  Future<bool> deleteRecipe(String id) async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await _dio.delete(
        '/recipes/$id',
        options: Options(headers: authHeaders),
      );

      if (response.data['success'] != true) return false;

      _cachedRecipes.removeWhere((recipe) => recipe.id == id);
      notifyListeners();

      AppLogger.success('Ricetta eliminata');
      return true;
    } catch (e) {
      AppLogger.error('Errore eliminazione', e);
      return false;
    }
  }

  Future<String?> uploadRecipeImage(String recipeId, File imageFile) async {
    try {
      final authHeaders = await _authService.getAuthHeaders();
      final token = authHeaders['Authorization']?.replaceFirst('Bearer ', '');

      if (token == null || token.isEmpty) {
        AppLogger.error('Token non disponibile per upload immagine');
        return null;
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      });

      final response = await _dio.post(
        '/recipes/$recipeId/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success'] != true) {
        AppLogger.error('Errore upload: ${response.data['message']}');
        return null;
      }

      final imageUrl = response.data['imageUrl'] as String?;

      // Aggiorna cache con nuova immagine
      final index = _cachedRecipes.indexWhere((r) => r.id == recipeId);
      if (index != -1 && imageUrl != null && imageUrl.isNotEmpty) {
        final existingRecipe = _cachedRecipes[index];
        final updatedRecipe = existingRecipe.copyWith(imageUrl: imageUrl);
        _cachedRecipes[index] = updatedRecipe;
        notifyListeners();
      }

      // Forza refresh per sincronizzazione completa
      await fetchRecipes(forceRefresh: true);

      return imageUrl;
    } catch (e) {
      AppLogger.error('Errore upload immagine', e);
      return null;
    }
  }

  Future<bool> removeRecipeImage(String recipeId) async {
    try {
      final authHeaders = await _authService.getAuthHeaders();
      final token = authHeaders['Authorization']?.replaceFirst('Bearer ', '');

      if (token == null) return false;

      final response = await _dio.delete(
        '/recipes/$recipeId/remove-image',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] != true) return false;

      final index = _cachedRecipes.indexWhere((r) => r.id == recipeId);
      if (index != -1) {
        final existingRecipe = _cachedRecipes[index];
        final updatedRecipe = existingRecipe.copyWith(imageUrl: '');
        _cachedRecipes[index] = updatedRecipe;
        notifyListeners();
      }

      AppLogger.success('Immagine rimossa');
      return true;
    } catch (e) {
      AppLogger.error('Errore rimozione immagine', e);
      return false;
    }
  }

  void updateRecipeLikedStatus(String recipeId, bool isLiked) {
    _refreshRecipesAfterInteraction(recipeId, 'like');
  }

  void updateRecipeCommentCount(String recipeId, int commentCount) {
    _refreshRecipesAfterInteraction(recipeId, 'commento');
  }

  void _refreshRecipesAfterInteraction(String recipeId, String action) {
    fetchRecipes(forceRefresh: true).then((_) {
      AppLogger.success('Lista ricette aggiornata dopo $action su $recipeId');
    }).catchError((error) {
      AppLogger.error('Errore aggiornamento lista dopo $action', error);
    });
  }

  Future<void> loadMoreRecipes() async {
    if (_isLoading || !_hasMore) return;
    await fetchRecipes(page: _currentPage + 1);
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void clearCache() {
    _cachedRecipes.clear();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
