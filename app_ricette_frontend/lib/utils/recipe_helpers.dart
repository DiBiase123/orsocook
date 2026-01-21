// lib/utils/recipe_helpers.dart
import '../models/recipe.dart';
import '../services/auth_service.dart';

/// Utility per operazioni comuni sulle ricette
class RecipeHelpers {
  /// Garantisce che una ricetta abbia l'oggetto author completo
  /// NECESSARIO PER: Ricette dall'API /api/auth/profile/ che restituiscono author:{}
  /// USO: RecipeHelpers.ensureRecipeHasAuthor(recipe, authService)
  static Recipe ensureRecipeHasAuthor(
    Recipe recipe,
    AuthService authService,
  ) {
    // Se la ricetta ha già un autore, non fare nulla
    if (recipe.author.isNotEmpty) {
      return recipe;
    }

    // Solo se abbiamo un userId valido
    final currentUserId = authService.userId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return recipe;
    }

    // Costruisci l'oggetto author con struttura standard
    final authorData = <String, dynamic>{
      'id': currentUserId,
      'userId': currentUserId, // Doppia chiave per compatibilità
    };

    // Aggiungi username per visualizzazione
    final username = authService.username;
    if (username != null && username.isNotEmpty) {
      authorData['username'] = username;
      authorData['displayName'] = username;
    }

    return recipe.copyWith(author: authorData);
  }

  /// Verifica se l'utente corrente è il proprietario della ricetta
  /// USO: RecipeHelpers.isRecipeOwner(recipe, userId)
  static bool isRecipeOwner(Recipe? recipe, String? userId) {
    if (recipe == null || userId == null || recipe.author.isEmpty) {
      return false;
    }

    final authorId = _extractAuthorId(recipe.author);
    if (authorId.isEmpty) return false;

    // Normalizza entrambi gli ID per confronto case-insensitive
    return _normalizeId(userId) == _normalizeId(authorId);
  }

  /// Estrae l'ID autore da una mappa author
  /// Supporta diverse chiavi: 'id', 'userId', '_id', 'authorId', 'user_id'
  static String _extractAuthorId(Map<String, dynamic> author) {
    if (author.isEmpty) return '';

    // Tutte le chiavi possibili dove potrebbe essere l'ID
    const possibleKeys = ['id', 'userId', '_id', 'authorId', 'user_id'];

    for (final key in possibleKeys) {
      final value = author[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  /// Normalizza un ID per confronto (trim + lowercase)
  static String _normalizeId(String id) {
    return id.trim().toLowerCase();
  }
}
