import 'package:flutter/material.dart';
import 'package:orsocook/models/comment.dart'; // AGGIUNGI QUESTO IMPORT

mixin CommentStateManager<T extends StatefulWidget> on State<T> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editCommentController = TextEditingController();

  bool _isSubmitting = false;
  bool _isRefreshing = false;
  bool _initialLoadComplete = false;
  String? _editCommentId;
  bool _forceRefresh = false;

  // Getters
  TextEditingController get commentController => _commentController;
  TextEditingController get editCommentController => _editCommentController;
  bool get isSubmitting => _isSubmitting;
  bool get isRefreshing => _isRefreshing;
  bool get initialLoadComplete => _initialLoadComplete;
  String? get editCommentId => _editCommentId;
  bool get forceRefresh => _forceRefresh;

  // Utility per safe state updates
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Safe async operation with mounted checks
  Future<void> safeAsyncOperation({
    required Future<void> Function() operation,
    required VoidCallback onStart,
    required VoidCallback onSuccess,
    required Function(dynamic) onError,
    required VoidCallback onFinally,
  }) async {
    onStart();

    try {
      await operation();
      if (mounted) {
        onSuccess();
      }
    } catch (e) {
      if (mounted) {
        onError(e);
      }
    } finally {
      if (mounted) {
        onFinally();
      }
    }
  }

  // === METODI PER GESTIONE STATI ===

  // Gestione submitting
  void startSubmit() => safeSetState(() => _isSubmitting = true);
  void endSubmit() => safeSetState(() => _isSubmitting = false);

  // Gestione refreshing
  void startRefresh() => safeSetState(() => _isRefreshing = true);
  void endRefresh() => safeSetState(() => _isRefreshing = false);

  // Gestione caricamento iniziale
  void setInitialLoadComplete() =>
      safeSetState(() => _initialLoadComplete = true);

  // Gestione modifica commenti (VERSIONI MULTIPLE PER FLESSIBILITÀ)

  // Versione 1: Con ID e contenuto separati
  void startEdit(String commentId, String content) {
    safeSetState(() {
      _editCommentId = commentId;
      _editCommentController.text = content;
    });
  }

  // Versione 2: Con oggetto Comment (PER IL WIDGET)
  void startEditComment(Comment comment) {
    safeSetState(() {
      _editCommentId = comment.id;
      _editCommentController.text = comment.content;
    });
  }

  // Annulla modifica
  void cancelEdit() {
    safeSetState(() {
      _editCommentId = null;
      _editCommentController.clear();
    });
  }

  // Forza refresh
  void setForceRefresh(bool value) => safeSetState(() => _forceRefresh = value);

  // Cleanup
  @mustCallSuper
  void disposeStateManager() {
    _commentController.dispose();
    _editCommentController.dispose();
  }
}
