// lib/screens/recipe/widgets/like_button.dart - VERSIONE FINALE (BADGE IN BASSO A DESTRA)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/like_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/logger.dart';

class LikeButton extends StatefulWidget {
  final String recipeId;
  final double size;
  final Color? color;
  final bool showLoading;
  final VoidCallback? onToggle;

  const LikeButton({
    super.key,
    required this.recipeId,
    this.size = 24.0,
    this.color,
    this.showLoading = true,
    this.onToggle,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _isProcessing = false;
  bool _hasCheckedInitialState = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!authService.isLoggedIn) {
        AppLogger.debug('User not logged in, like button disabled');
        setState(() {
          _hasCheckedInitialState = true;
        });
        return;
      }

      final likeService = Provider.of<LikeService>(context, listen: false);

      // Carica il count dei likes
      await likeService.getLikesCountFromAPI(widget.recipeId);

      // Controlla se l'utente ha già messo like
      final result = await likeService.checkLiked(widget.recipeId);

      AppLogger.debug(
          'Recipe ${widget.recipeId} liked status from API: ${result['liked']}');

      if (mounted) {
        setState(() {
          _hasCheckedInitialState = true;
        });
      }
    } catch (e) {
      AppLogger.error('Error checking liked status', e);
      if (mounted) {
        setState(() {
          _hasCheckedInitialState = true;
        });
      }
    }
  }

  Future<void> _toggleLike(LikeService likeService) async {
    if (_isProcessing) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await likeService.toggleLike(widget.recipeId);

      if (!success) {
        _showErrorSnackbar('Errore durante l\'operazione');
      } else {
        // Notifica callback se fornito
        widget.onToggle?.call();

        // Mostra feedback
        final isNowLiked = likeService.isLiked(widget.recipeId);
        _showSuccessSnackbar(
            isNowLiked ? 'Mi piace aggiunto!' : 'Mi piace rimosso!');

        AppLogger.success(isNowLiked
            ? 'Recipe ${widget.recipeId} liked'
            : 'Recipe ${widget.recipeId} unliked');
      }
    } catch (e) {
      AppLogger.error('Error toggling like', e);
      _showErrorSnackbar('Errore: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLoginPrompt() {
    AppLogger.auth('User not logged in, showing login prompt');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Accedi per mettere "Mi piace" alle ricette'),
        backgroundColor: Colors.orange[800],
        action: SnackBarAction(
          label: 'ACCEDI',
          textColor: Colors.white,
          onPressed: () {
            AppLogger.navigation('Navigate to login from like button');
          },
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LikeService>(
      builder: (context, likeService, child) {
        final isLiked = likeService.isLiked(widget.recipeId);
        final likesCount = likeService.getLikesCount(widget.recipeId);

        // Se non abbiamo ancora controllato lo stato, mostra loading
        if (!_hasCheckedInitialState && widget.showLoading) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final authService = Provider.of<AuthService>(context);
        final isLoggedIn = authService.isLoggedIn;

        // Se non loggato, bottone disabilitato (COME FAVORITE_BUTTON)
        if (!isLoggedIn) {
          return Stack(
            children: [
              IconButton(
                iconSize: widget.size,
                icon: Icon(
                  Icons.thumb_up_outlined,
                  color: widget.color ?? Colors.grey,
                ),
                onPressed: _showLoginPrompt,
                tooltip: 'Accedi per mettere "Mi piace"',
              ),
              // Badge disabilitato (solo numero)
              if (likesCount > 0)
                Positioned(
                  bottom: 4, // Basso a destra
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      likesCount > 99 ? '99+' : likesCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }

        // Se in processing, mostra loading
        if (_isProcessing && widget.showLoading) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Colore basato su stato
        Color getIconColor() {
          if (!isLoggedIn) return Colors.grey;
          if (isLiked) return Colors.blue;
          return widget.color ?? Colors.grey[700]!;
        }

        // Bottone normale CON BADGE (COME FAVORITE_BUTTON + BADGE)
        return Stack(
          children: [
            IconButton(
              iconSize: widget.size,
              icon: Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: getIconColor(),
              ),
              onPressed: () => _toggleLike(likeService),
              tooltip: isLiked ? 'Rimuovi mi piace' : 'Metti mi piace',
            ),

            // BADGE con numero (solo se > 0) - POSIZIONE: BASSO A DESTRA
            if (likesCount > 0)
              Positioned(
                bottom: 4, // Angolo in basso a destra
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isLiked ? Colors.blue : Colors.grey[600],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    likesCount > 99 ? '99+' : likesCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
