import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../services/profile_service.dart';
import '../../services/favorite_service.dart';
import '../../services/auth_service.dart';
import '../../utils/recipe_helpers.dart'; // ✅ NUOVO IMPORT
import '../../widgets/recipe_card.dart';
import '../../utils/logger.dart';
import '../recipe/detail_recipe_screen.dart';

class ProfileRecipesList extends StatefulWidget {
  final List<Recipe> recipes;
  final String userId;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isUserRecipes;

  const ProfileRecipesList({
    super.key,
    required this.recipes,
    required this.userId,
    required this.emptyMessage,
    required this.emptyIcon,
    this.isUserRecipes = false,
  });

  @override
  State<ProfileRecipesList> createState() => _ProfileRecipesListState();
}

class _ProfileRecipesListState extends State<ProfileRecipesList> {
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final List<Recipe> _loadedRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadedRecipes.addAll(widget.recipes);
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final profileService =
          Provider.of<ProfileService>(context, listen: false);
      final nextPage = _currentPage + 1;

      final newRecipes = await profileService.fetchUserRecipes(
        widget.userId,
        page: nextPage,
        limit: 10,
      );

      if (newRecipes.isNotEmpty) {
        setState(() {
          _loadedRecipes.addAll(newRecipes);
          _currentPage = nextPage;
        });
        _logSuccess('Caricate ${newRecipes.length} ricette aggiuntive');
      }
    } catch (e) {
      _logError('Errore caricamento ricette aggiuntive: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _logSuccess(String message) {
    AppLogger.success('Profile: $message');
  }

  void _logError(String message) {
    AppLogger.error('Profile: $message');
  }

  void _logNavigation(String text) {
    AppLogger.navigation('Profile: $text');
  }

  /// Correggi l'autore mancante usando RecipeHelpers
  Recipe _ensureRecipeHasAuthor(Recipe originalRecipe) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return RecipeHelpers.ensureRecipeHasAuthor(originalRecipe, authService);
  }

  void _handleRecipeTap(Recipe recipe) {
    _logNavigation('Navigazione a ${recipe.title}');

    final recipeWithAuthor = _ensureRecipeHasAuthor(recipe);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailRecipeScreen(
          recipe: recipeWithAuthor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.emptyIcon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (widget.isUserRecipes)
              ElevatedButton(
                onPressed: () {
                  _logNavigation('Navigazione a crea ricetta');
                  Navigator.pushNamed(context, '/create-recipe');
                },
                child: const Text('Crea la tua prima ricetta'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeItem(Recipe recipe) {
    final recipeWithAuthor = _ensureRecipeHasAuthor(recipe);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: RecipeCard(
        recipe: recipeWithAuthor,
        onTap: () => _handleRecipeTap(recipeWithAuthor),
        showAuthor: !widget.isUserRecipes,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _loadMoreRecipes,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: const Text('Carica altre ricette'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteService>(
      builder: (context, favoriteService, child) {
        final recipesWithAuthor =
            _loadedRecipes.map(_ensureRecipeHasAuthor).toList();

        final updatedRecipes = recipesWithAuthor.map((recipe) {
          return Recipe.fromJson({
            ...recipe.toJson(),
            'isFavorite': favoriteService.isFavorite(recipe.id),
          });
        }).toList();

        if (updatedRecipes.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                itemCount: updatedRecipes.length,
                itemBuilder: (context, index) {
                  return _buildRecipeItem(updatedRecipes[index]);
                },
              ),
            ),
            if (updatedRecipes.length >= 10) _buildLoadMoreIndicator(),
          ],
        );
      },
    );
  }
}
