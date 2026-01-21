import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
import '../../services/like_service.dart';
import '../../utils/logger.dart';
import '../recipe/detail_recipe_screen.dart';
import 'widgets/welcome_header.dart';
import 'widgets/recipe_search_bar.dart';
import 'widgets/categories_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/recipe_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🎬 HomeScreen inizializzata');

    // Carica ricette usando Future.microtask
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialLoad();
    });
  }

  // Metodo helper per caricamento iniziale
  void _handleInitialLoad() {
    _loadInitialRecipes().catchError((e) {
      AppLogger.error('Errore nel caricamento iniziale', e);
    });
  }

  Future<void> _loadInitialRecipes() async {
    if (!mounted) return;

    AppLogger.api('📥 Caricamento ricette iniziali');

    await Future.microtask(() {
      if (!mounted) return null;

      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final likeService = Provider.of<LikeService>(context, listen: false);

      return recipeService.fetchRecipes(forceRefresh: true, page: 1).then((_) {
        final recipeIds = recipeService.cachedRecipes.map((r) => r.id).toList();
        likeService.preloadLikesCount(recipeIds);
        AppLogger.success('✅ Ricette iniziali caricate');
      });
    }).catchError((e) {
      AppLogger.error('❌ Errore caricamento ricette iniziali', e);
    });
  }

  void _navigateToCreateRecipe() {
    AppLogger.debug('➡️ Navigazione a CreateRecipeScreen');

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn) {
      AppLogger.debug('🔒 Utente non autenticato, mostra dialog login');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Accesso richiesto'),
          content:
              const Text('Devi effettuare il login per creare una ricetta.'),
          actions: [
            TextButton(
              onPressed: () {
                AppLogger.debug(
                    '❌ Creazione ricetta annullata (non autenticato)');
                Navigator.of(context).pop();
              },
              child: const Text('ANNULLA'),
            ),
            TextButton(
              onPressed: () {
                AppLogger.debug('➡️ Navigazione a LoginScreen');
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('LOGIN'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pushNamed(context, '/create-recipe');
  }

  void _navigateToProfile() {
    AppLogger.debug('➡️ Navigazione a profilo');

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn) {
      AppLogger.debug('🔒 Utente non autenticato, mostra dialog login');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Accesso richiesto'),
          content:
              const Text('Devi effettuare il login per accedere al profilo.'),
          actions: [
            TextButton(
              onPressed: () {
                AppLogger.debug(
                    '❌ Accesso profilo annullato (non autenticato)');
                Navigator.of(context).pop();
              },
              child: const Text('ANNULLA'),
            ),
            TextButton(
              onPressed: () {
                AppLogger.debug('➡️ Navigazione a LoginScreen');
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('LOGIN'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pushNamed(context, '/profile');
  }

  void _onRecipeTap(Recipe recipe) {
    AppLogger.debug('➡️ TAP RICEVUTO per: ${recipe.title}');
    AppLogger.debug('🔍 Recipe ID: "${recipe.id}"');

    // VERIFICA CHE L'ID NON SIA VUOTO
    if (recipe.id.isEmpty) {
      AppLogger.error('❌ Recipe ID è vuoto!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore: ID ricetta non valido')),
      );
      return;
    }

    // NAVIGAZIONE ALLA SCHERMATA DI DETTAGLIO REALE
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailRecipeScreen(recipeId: recipe.id),
      ),
    );
  }

  void _onSearchChanged(String query) {
    AppLogger.debug('🔍 Ricerca: "$query"');
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
  }

  List<Recipe> _getFilteredRecipes(List<Recipe> recipes) {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return recipes;
    }

    final filtered = recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          recipe.description
              .toLowerCase()
              .contains(_searchQuery!.toLowerCase()) ||
          recipe.ingredients.any((ing) => ing['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery!.toLowerCase()));
    }).toList();

    AppLogger.debug(
        '🔍 Risultati ricerca: ${filtered.length}/${recipes.length} ricette');
    return filtered;
  }

  // Widget per l'avatar nell'AppBar - VERSIONE MIGLIORATA CON TOOLTIP
  Widget _buildAvatarButton(AuthService authService) {
    if (!authService.isLoggedIn) {
      return IconButton(
        icon: const Icon(Icons.account_circle),
        onPressed: _navigateToProfile,
        tooltip: 'Accedi al profilo',
      );
    }

    // Tooltip dinamico con nome utente
    String tooltipMessage = 'Profilo';
    if (authService.username != null) {
      tooltipMessage = 'Profilo di ${authService.username!}';
    }

    // Se l'utente è loggato, mostra l'avatar se presente
    if (authService.avatarUrl != null && authService.avatarUrl!.isNotEmpty) {
      return Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _navigateToProfile,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(authService.avatarUrl!),
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: authService.avatarUrl == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    // Se loggato ma senza avatar
    return IconButton(
      icon: const Icon(Icons.account_circle),
      onPressed: _navigateToProfile,
      tooltip: tooltipMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ Building HomeScreen');

    return Consumer2<RecipeService, AuthService>(
      builder: (context, recipeService, authService, child) {
        final theme = Theme.of(context);

        AppLogger.debug('🎯 BUILD CON CONSUMER:');
        AppLogger.debug(
            '   • cachedRecipes: ${recipeService.cachedRecipes.length}');
        AppLogger.debug('   • isLoading: ${recipeService.isLoading}');
        AppLogger.debug('   • hasMore: ${recipeService.hasMore}');
        AppLogger.debug('   • user logged in: ${authService.isLoggedIn}');

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'OrsoCook',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _navigateToCreateRecipe,
                tooltip: 'Crea ricetta',
              ),
              _buildAvatarButton(authService),
            ],
          ),
          body: Column(
            children: [
              const WelcomeHeader(),
              RecipeSearchBar(onSearchChanged: _onSearchChanged),
              CategoriesBar(onCategorySelected: (category) {
                AppLogger.debug('🎯 Categoria selezionata: $category');
              }),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<RecipeService>(
                  builder: (context, recipeService, child) {
                    final recipes =
                        _getFilteredRecipes(recipeService.cachedRecipes);

                    return recipes.isNotEmpty
                        ? RecipeList(
                            onRecipeTap:
                                _onRecipeTap, // 👈 SOLO QUESTO PARAMETRO
                          )
                        : EmptyState(
                            searchQuery: _searchQuery,
                            onRetry: () => _loadInitialRecipes(),
                            onCreateRecipe: _navigateToCreateRecipe,
                          );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToCreateRecipe,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 12,
            highlightElevation: 16,
            tooltip: 'Crea nuova ricetta',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    Color.lerp(theme.colorScheme.primary, Colors.white, 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    AppLogger.debug('♻️ HomeScreen disposed');
    super.dispose();
  }
}
