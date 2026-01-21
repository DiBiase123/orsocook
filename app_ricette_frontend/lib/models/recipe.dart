import '../utils/logger.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String slug;
  final String? imageUrl;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final bool isPublic;
  final int views;
  final int favoriteCount;
  final int likeCount;
  final int commentCount; // ← NUOVO CAMPO
  final bool isFavorite;
  final Map<String, dynamic> author;
  final Map<String, dynamic> category;
  final List<dynamic> ingredients;
  final List<dynamic> instructions;
  final List<dynamic> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    required this.id,
    required this.title,
    this.description = '',
    this.slug = '',
    this.imageUrl,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.difficulty = 'MEDIUM',
    this.isPublic = true,
    this.views = 0,
    this.favoriteCount = 0,
    this.likeCount = 0,
    this.commentCount = 0, // ← INIZIALIZZATO
    this.isFavorite = false,
    Map<String, dynamic>? author,
    Map<String, dynamic>? category,
    List<dynamic>? ingredients,
    List<dynamic>? instructions,
    List<dynamic>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : author = author ?? {},
        category = category ?? {},
        ingredients = ingredients ?? [],
        instructions = instructions ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Recipe.simple({
    required String id,
    required String title,
  }) {
    return Recipe(
      id: id,
      title: title,
    );
  }

  // VERSIONE SEMPLIFICATA E SICURA DI FROMJSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    try {
      String parseString(dynamic value, [String defaultValue = '']) {
        if (value == null) return defaultValue;
        return value.toString();
      }

      int parseInt(dynamic value, [int defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? defaultValue;
        if (value is double) return value.toInt();
        return defaultValue;
      }

      bool parseBool(dynamic value, [bool defaultValue = false]) {
        if (value == null) return defaultValue;
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is int) return value != 0;
        return defaultValue;
      }

      Map<String, dynamic> parseMap(dynamic value) {
        if (value == null) return {};
        if (value is Map) {
          // Assicurati che tutte le chiavi siano String
          final Map<String, dynamic> result = {};
          value.forEach((key, val) {
            result[key.toString()] = val;
          });
          return result;
        }
        return {};
      }

      List<dynamic> parseList(dynamic value) {
        if (value == null) return [];
        if (value is List) return List<dynamic>.from(value);
        return [];
      }

      DateTime parseDateTime(dynamic value) {
        if (value == null) return DateTime.now();
        try {
          if (value is DateTime) return value;
          if (value is String) return DateTime.parse(value);
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          return DateTime.now();
        } catch (e) {
          return DateTime.now();
        }
      }

      return Recipe(
        id: parseString(json['id']),
        title: parseString(json['title'], 'Senza titolo'),
        description: parseString(json['description']),
        slug: parseString(json['slug']),
        imageUrl: parseString(json['imageUrl']),
        prepTime: parseInt(json['prepTime']),
        cookTime: parseInt(json['cookTime']),
        servings: parseInt(json['servings'], 1),
        difficulty: parseString(json['difficulty'], 'MEDIUM'),
        isPublic: parseBool(json['isPublic'], true),
        views: parseInt(json['views']),
        favoriteCount: parseInt(json['favoriteCount']),
        likeCount: parseInt(json['likeCount']),
        commentCount: parseInt(json['commentCount']), // ← AGGIUNTO
        isFavorite: parseBool(json['isFavorite']),
        author: parseMap(json['author']),
        category: parseMap(json['category']),
        ingredients: parseList(json['ingredients']),
        instructions: parseList(json['instructions']),
        tags: parseList(json['tags']),
        createdAt: parseDateTime(json['createdAt']),
        updatedAt: parseDateTime(json['updatedAt']),
      );
    } catch (e, stackTrace) {
      AppLogger.error('ERRORE CRITICO in Recipe.fromJson: $e');
      AppLogger.error('Stack trace: $stackTrace');
      AppLogger.error('JSON ricevuto: $json');
      // Restituisci una recipe di fallback
      return Recipe(
        id: json['id']?.toString() ?? 'error',
        title: json['title']?.toString() ?? 'Errore nel parsing',
      );
    }
  }

  String get authorName {
    return author['displayName'] ?? author['username'] ?? 'Autore sconosciuto';
  }

  String get categoryName {
    return category['name'] ?? 'Senza categoria';
  }

  int get totalTime {
    return prepTime + cookTime;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'slug': slug,
      'imageUrl': imageUrl,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'isPublic': isPublic,
      'views': views,
      'favoriteCount': favoriteCount,
      'likeCount': likeCount,
      'commentCount': commentCount, // ← AGGIUNTO
      'isFavorite': isFavorite,
      'author': author,
      'category': category,
      'ingredients': ingredients,
      'instructions': instructions,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? slug,
    String? imageUrl,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    bool? isPublic,
    int? views,
    int? favoriteCount,
    int? likeCount,
    int? commentCount, // ← AGGIUNTO
    bool? isFavorite,
    Map<String, dynamic>? author,
    Map<String, dynamic>? category,
    List<dynamic>? ingredients,
    List<dynamic>? instructions,
    List<dynamic>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      isPublic: isPublic ?? this.isPublic,
      views: views ?? this.views,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount, // ← AGGIUNTO
      isFavorite: isFavorite ?? this.isFavorite,
      author: author ?? Map.from(this.author),
      category: category ?? Map.from(this.category),
      ingredients: ingredients ?? List.from(this.ingredients),
      instructions: instructions ?? List.from(this.instructions),
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, commentCount: $commentCount)';
  }
}
