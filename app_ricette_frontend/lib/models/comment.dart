import '../utils/logger.dart';

class Comment {
  final String id;
  final String content;
  final Map<String, dynamic> user;
  final String recipeId;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.content,
    required this.user,
    required this.recipeId,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      String parseString(dynamic value, [String defaultValue = '']) {
        if (value == null) return defaultValue;
        return value.toString();
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
          final Map<String, dynamic> result = {};
          value.forEach((key, val) {
            result[key.toString()] = val;
          });
          return result;
        }
        return {};
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

      return Comment(
        id: parseString(json['id']),
        content: parseString(json['content']),
        user: parseMap(json['user']),
        recipeId: parseString(json['recipeId']),
        isEdited: parseBool(json['isEdited']),
        createdAt: parseDateTime(json['createdAt']),
        updatedAt: parseDateTime(json['updatedAt']),
      );
    } catch (e, stackTrace) {
      AppLogger.error('ERRORE in Comment.fromJson: $e');
      AppLogger.error('Stack trace: $stackTrace');
      AppLogger.error('JSON ricevuto: $json');

      // Return a default comment to avoid crashes
      return Comment(
        id: 'error',
        content: 'Errore nel parsing del commento',
        user: {'username': 'System'},
        recipeId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Helper getters
  String get userName => user['username'] ?? 'Utente sconosciuto';
  String? get userAvatar => user['avatarUrl'];
  String get userId => user['id'] ?? '';

  // Check if comment belongs to current user
  bool isOwner(String? currentUserId) {
    if (currentUserId == null) return false;
    return userId == currentUserId;
  }

  // Format time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years anno${years > 1 ? 'i' : ''} fa';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months mese${months > 1 ? 'i' : ''} fa';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} giorno${difference.inDays > 1 ? 'i' : ''} fa';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} ora${difference.inHours > 1 ? 'e' : ''} fa';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 'i' : ''} fa';
    }
    return 'Pochi secondi fa';
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user': user,
      'recipeId': recipeId,
      'isEdited': isEdited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  Comment copyWith({
    String? id,
    String? content,
    Map<String, dynamic>? user,
    String? recipeId,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      user: user ?? Map.from(this.user),
      recipeId: recipeId ?? this.recipeId,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, content: $content, user: $userName)';
  }
}

// Helper class for creating new comments
class CommentCreateRequest {
  final String content;
  final String recipeId;

  CommentCreateRequest({
    required this.content,
    required this.recipeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  @override
  String toString() {
    return 'CommentCreateRequest(content: $content, recipeId: $recipeId)';
  }
}

// Helper class for updating comments
class CommentUpdateRequest {
  final String content;

  CommentUpdateRequest({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  @override
  String toString() {
    return 'CommentUpdateRequest(content: $content)';
  }
}
