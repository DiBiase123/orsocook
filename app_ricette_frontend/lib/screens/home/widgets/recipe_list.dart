// lib/screens/home/widgets/recipe_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orsocook/models/recipe.dart';
import 'package:orsocook/widgets/recipe_card.dart';
import 'package:orsocook/utils/logger.dart';
import 'package:orsocook/services/recipe_service.dart';

class RecipeList extends StatefulWidget {
  final void Function(Recipe) onRecipeTap;

  const RecipeList({
    super.key,
    required this.onRecipeTap,
  });

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final recipeService = Provider.of<RecipeService>(context, listen: false);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !recipeService.isLoading &&
        recipeService.hasMore) {
      _loadMoreRecipes(recipeService);
    }
  }

  Future<void> _loadMoreRecipes(RecipeService recipeService) async {
    AppLogger.debug('📥 Caricamento altre ricette...');
    await recipeService.loadMoreRecipes();
  }

  // METODO PER CALCOLARE COLONNE IN BASE ALLA LARGHEZZA
  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 900) {
      return 3; // Desktop/large tablet
    } else if (width > 600) {
      return 2; // Tablet/landscape mobile
    } else {
      return 1; // Mobile portrait
    }
  }

  // METODO PER CALCOLARE PADDING DINAMICO
  EdgeInsets _calculatePadding(BuildContext context) {
    final crossAxisCount = _calculateCrossAxisCount(context);

    double horizontalPadding;

    if (crossAxisCount == 3) {
      horizontalPadding = 24.0;
    } else if (crossAxisCount == 2) {
      horizontalPadding = 20.0;
    } else {
      horizontalPadding = 16.0;
    }

    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: 16.0,
    );
  }

  // METODO PER CALCOLARE SPAZIO TRA CARD
  double _calculateSpacing(int crossAxisCount) {
    if (crossAxisCount == 3) {
      return 20.0;
    } else if (crossAxisCount == 2) {
      return 16.0;
    } else {
      return 12.0;
    }
  }

  Widget _buildLoadingMore() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Caricamento altre ricette...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Text(
            'Tutte le ricette caricate',
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeService>(
      builder: (context, recipeService, child) {
        final recipes = recipeService.cachedRecipes;

        AppLogger.debug('📦 RecipeList: ${recipes.length} ricette, '
            'hasMore: ${recipeService.hasMore}, loading: ${recipeService.isLoading}');

        if (recipes.isEmpty && !recipeService.isLoading) {
          return const SizedBox.shrink(); // EmptyState gestirà questo
        }

        // CALCOLA PARAMETRI DINAMICI
        final crossAxisCount = _calculateCrossAxisCount(context);
        final padding = _calculatePadding(context);
        final spacing = _calculateSpacing(crossAxisCount);

        final itemCount = recipes.length +
            (recipeService.hasMore && recipeService.isLoading ? 1 : 0);

        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Gestisce anche il RefreshIndicator
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    // 👈 CORRETTO: await e poi return void
                    await recipeService.fetchRecipes(
                        forceRefresh: true, page: 1);
                    return; // Ritorna Future<void>
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: padding,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // LOADING INDICATOR IN FONDO
                      if (index >= recipes.length) {
                        return _buildLoadingMore();
                      }

                      // CARD NORMALE
                      final recipe = recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () => widget.onRecipeTap(recipe),
                      );
                    },
                  ),
                ),
              ),
            ),

            // MESSAGGIO FINE LISTA
            if (!recipeService.hasMore && recipes.isNotEmpty) _buildEndOfList(),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
