import '../../../../models/recipe.dart';

class DetailHelpers {
  /// Verifica se l'utente corrente è il proprietario della ricetta
  static bool isRecipeOwner(String? currentUserId, Recipe recipe) {
    if (currentUserId == null || recipe.author.isEmpty) {
      return false;
    }

    // ✅ Estrae l'ID dell'autore dalla ricetta
    final recipeAuthorId = _extractAuthorId(recipe.author);
    if (recipeAuthorId.isEmpty) return false;

    // ✅ Normalizza entrambi gli ID per confronto case-insensitive
    final normalizedCurrentId = currentUserId.trim().toLowerCase();
    final normalizedAuthorId = recipeAuthorId.trim().toLowerCase();

    return normalizedCurrentId == normalizedAuthorId;
  }

  /// Estrae l'ID dell'autore da diverse strutture possibili
  static String _extractAuthorId(Map<String, dynamic> author) {
    if (author.isEmpty) return '';

    // Prova tutte le chiavi possibili per l'ID
    const possibleKeys = ['id', 'userId', '_id', 'authorId', 'user_id'];

    for (final key in possibleKeys) {
      final value = author[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    // Fallback: cerca in oggetti annidati
    if (author.containsKey('user') && author['user'] is Map) {
      final userMap = author['user'] as Map<String, dynamic>;
      for (final key in possibleKeys) {
        final value = userMap[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return '';
  }

  /// Costruisce URL completo per l'immagine
  static String getFullImageUrl(String? imageUrl, String baseUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // Se è già un URL completo, restituiscilo
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    // Altrimenti aggiungi la base URL
    return '$baseUrl$imageUrl';
  }

  /// Formatta il tempo totale (prepTime + cookTime)
  static String formatTotalTime(int prepTime, int cookTime) {
    final totalTime = prepTime + cookTime;

    if (totalTime < 60) {
      return '$totalTime min';
    }

    final hours = totalTime ~/ 60;
    final minutes = totalTime % 60;

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}min';
  }

  /// Estrae nomi dei tag da diverse strutture
  static List<String> extractTagNames(List<dynamic> tags) {
    final List<String> tagNames = [];

    for (final tag in tags) {
      String tagName = '';

      if (tag is String) {
        tagName = tag;
      } else if (tag is Map) {
        // Prova le diverse strutture possibili
        if (tag.containsKey('tag') &&
            tag['tag'] is Map &&
            tag['tag']['name'] != null) {
          tagName = tag['tag']['name'].toString();
        } else if (tag['name'] != null) {
          tagName = tag['name'].toString();
        } else {
          // Fallback: prova altre chiavi comuni
          const possibleKeys = ['label', 'title', 'value', 'text', 'tagName'];
          for (final key in possibleKeys) {
            if (tag[key] != null) {
              tagName = tag[key].toString();
              break;
            }
          }

          // Ultimo fallback
          if (tagName.isEmpty) {
            tagName = tag.toString();
          }
        }
      } else {
        tagName = tag.toString();
      }

      // Pulisci e aggiungi se valido
      tagName = tagName.trim().replaceAll('{', '').replaceAll('}', '');

      if (tagName.isNotEmpty && !tagNames.contains(tagName)) {
        tagNames.add(tagName);
      }
    }

    return tagNames;
  }
}
