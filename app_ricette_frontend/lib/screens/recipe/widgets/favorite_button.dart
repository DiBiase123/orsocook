import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/favorite_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/logger.dart';
import '../../../models/recipe.dart';

class FavoriteButton extends StatefulWidget {
  final String recipeId;
  final Recipe? recipe;
  final double size;
  final Color? color;
  final bool showLoading;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.recipeId,
    this.recipe,
    this.size = 24.0,
    this.color,
    this.showLoading = true,
    this.onToggle,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
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
        AppLogger.debug('User not logged in, favorite button disabled');
        setState(() {
          _hasCheckedInitialState = true;
        });
        return;
      }

      final favoriteService =
          Provider.of<FavoriteService>(context, listen: false);

      // Prima controlla la cache locale
      if (favoriteService.isFavorite(widget.recipeId)) {
        AppLogger.debug('Recipe ${widget.recipeId} is favorite (from cache)');
        setState(() {
          _hasCheckedInitialState = true;
        });
        return;
      }

      // Se non in cache, chiama l'API
      final result = await favoriteService.checkFavorite(widget.recipeId);

      AppLogger.debug(
          'Recipe ${widget.recipeId} favorite status from API: ${result['isFavorite']}');

      if (mounted) {
        setState(() {
          _hasCheckedInitialState = true;
        });
      }
    } catch (e) {
      AppLogger.error('Error checking favorite status', e);
      if (mounted) {
        setState(() {
          _hasCheckedInitialState = true;
        });
      }
    }
  }

  Future<void> _toggleFavorite(FavoriteService favoriteService) async {
    if (_isProcessing) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await favoriteService.toggleFavorite(
        widget.recipeId,
        widget.recipe,
      );

      if (!success) {
        _showErrorSnackbar('Errore durante l\'operazione');
      } else {
        // Notifica callback se fornito
        widget.onToggle?.call();

        // Mostra feedback
        final isNowFavorite = favoriteService.isFavorite(widget.recipeId);
        _showSuccessSnackbar(
            isNowFavorite ? 'Aggiunto ai preferiti' : 'Rimosso dai preferiti');

        AppLogger.success(isNowFavorite
            ? 'Recipe ${widget.recipeId} added to favorites'
            : 'Recipe ${widget.recipeId} removed from favorites');
      }
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);
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
        content: const Text('Accedi per salvare le ricette preferite'),
        backgroundColor: Colors.orange[800],
        action: SnackBarAction(
          label: 'ACCEDI',
          textColor: Colors.white,
          onPressed: () {
            // Qui potresti navigare alla login screen
            AppLogger.navigation('Navigate to login from favorite button');
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
    // USA CONSUMER PER FAVORITE SERVICE
    return Consumer<FavoriteService>(
      builder: (context, favoriteService, child) {
        final isFavorite = favoriteService.isFavorite(widget.recipeId);

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

        // Se non loggato, bottone disabilitato
        if (!isLoggedIn) {
          return IconButton(
            iconSize: widget.size,
            icon: Icon(
              Icons.favorite_border,
              color: widget.color ?? Colors.grey,
            ),
            onPressed: _showLoginPrompt,
            tooltip: 'Accedi per aggiungere ai preferiti',
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

        // Bottone normale
        return IconButton(
          iconSize: widget.size,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : widget.color ?? Colors.grey[700],
          ),
          onPressed: () => _toggleFavorite(favoriteService),
          tooltip:
              isFavorite ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
        );
      },
    );
  }
}
