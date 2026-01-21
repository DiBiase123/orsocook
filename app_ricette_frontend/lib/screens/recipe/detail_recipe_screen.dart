import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
import '../../services/like_service.dart';
import '../../utils/logger.dart';
import 'detail_recipe/constants.dart';
import 'detail_recipe/widgets/detail_image_section.dart';
import 'detail_recipe/widgets/detail_header_section.dart';
import 'detail_recipe/widgets/detail_info_section.dart';
import 'detail_recipe/widgets/detail_ingredients_section.dart';
import 'detail_recipe/widgets/detail_instructions_section.dart';
import 'detail_recipe/widgets/detail_tags_section.dart';
import 'detail_recipe/widgets/detail_comments_section.dart';
import '../../navigation/app_router.dart';

class DetailRecipeScreen extends StatefulWidget {
  final String? recipeId;
  final Recipe? recipe;

  const DetailRecipeScreen({
    super.key,
    this.recipeId,
    this.recipe,
  }) : assert(recipeId != null || recipe != null,
            'Deve essere fornito recipeId o recipe');

  @override
  State<DetailRecipeScreen> createState() => _DetailRecipeScreenState();
}

class _DetailRecipeScreenState extends State<DetailRecipeScreen> {
  Recipe? _recipe;
  bool _isLoading = true;
  String? _error;
  bool? _isFavorite;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecipe();
  }

  void _initializeRecipe() {
    AppLogger.debug('🎬 DetailRecipeScreen inizializzata');

    if (widget.recipe != null) {
      AppLogger.debug(
          '✅ Ricetta fornita direttamente: ${widget.recipe!.title}');
      _recipe = widget.recipe;
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadExtraDetails();
        }
      });
    } else if (widget.recipeId != null && widget.recipeId!.isNotEmpty) {
      AppLogger.debug('📥 Caricamento ricetta da ID: ${widget.recipeId}');
      _loadRecipeById(widget.recipeId!);
    } else {
      AppLogger.error('❌ Nessun recipeId o recipe fornito');
      _error = 'Ricetta non valida';
      _isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadRecipeById(String recipeId) async {
    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final recipe = await recipeService.getRecipeById(recipeId);

      AppLogger.debug('📦 Ricetta ricevuta: ${recipe != null ? "SI" : "NO"}');

      if (mounted) {
        setState(() {
          _recipe = recipe;
          _isLoading = false;
          if (recipe == null) {
            _error = 'Ricetta non trovata';
          }
        });
      }

      if (recipe != null) {
        await _loadExtraDetails();
      }
    } catch (e) {
      AppLogger.error('❌ Errore caricamento dettaglio ricetta', e);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Errore: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadExtraDetails() async {
    if (_recipe == null) return;

    try {
      final likeService = Provider.of<LikeService>(context, listen: false);

      // 1. Carica like count - RIMOSSO AWAIT perché getLikesCount() restituisce int
      final likes = likeService.getLikesCount(_recipe!.id);

      // 2. Stato favorite dalla ricetta
      final isFavorite = _recipe!.isFavorite;
      AppLogger.debug('Stato favorite dalla ricetta: $isFavorite');

      if (mounted) {
        setState(() {
          _likeCount = likes;
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      AppLogger.error('❌ Errore caricamento dettagli extra: $e');
      if (mounted) {
        setState(() {
          _isFavorite = _recipe?.isFavorite ?? false;
        });
      }
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: DetailConstants.xlargeSpacing),
          Text('Caricamento ricetta...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: DetailConstants.xlargeSpacing),
          Text(
            _error ?? 'Errore sconosciuto',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DetailConstants.sectionSpacing),
          ElevatedButton(
            onPressed: () {
              if (widget.recipeId != null) {
                _loadRecipeById(widget.recipeId!);
              } else if (widget.recipe != null) {
                setState(() {
                  _recipe = widget.recipe;
                  _isLoading = false;
                });
              }
            },
            child: const Text('RIPROVA'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeDetail() {
    final recipe = _recipe!;

    final updatedRecipe = recipe.copyWith(
      likeCount: _likeCount,
      isFavorite: _isFavorite ?? false,
    );

    return SingleChildScrollView(
      padding: DetailConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailHeaderSection(recipe: updatedRecipe),
          if (updatedRecipe.imageUrl != null &&
              updatedRecipe.imageUrl!.isNotEmpty)
            DetailImageSection(recipe: updatedRecipe),
          DetailInfoSection(recipe: updatedRecipe),
          const SizedBox(height: DetailConstants.xxlargeSpacing),
          DetailIngredientsSection(recipe: updatedRecipe),
          const SizedBox(height: DetailConstants.sectionSpacing),
          DetailInstructionsSection(recipe: updatedRecipe),
          DetailTagsSection(recipe: updatedRecipe),
          const SizedBox(height: DetailConstants.extraSectionSpacing),
          DetailCommentsSection(recipeId: updatedRecipe.id),
          const SizedBox(height: DetailConstants.extraSectionSpacing),
        ],
      ),
    );
  }

  void _navigateToEditScreen(Recipe recipe) {
    AppLogger.debug('✏️ Navigazione a EditRecipeScreen per: ${recipe.title}');

    AppRouter.goToEditRecipe(context, recipe).then((_) {
      // ✅ SEMPLICE: Quando torna dalla schermata di edit, SEMPRE ricarica i dati
      AppLogger.debug('🔙 Ritorno da EditRecipeScreen, ricarico dati...');

      if (widget.recipeId != null) {
        _loadRecipeById(widget.recipeId!);
      } else if (mounted && _recipe != null) {
        // Ricarica la stessa ricetta
        _loadRecipeById(_recipe!.id);
      }
    });
  }

  void _showDeleteDialog(Recipe recipe) {
    AppLogger.debug('🗑️ Mostro dialog eliminazione per: ${recipe.title}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare la ricetta "${recipe.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.debug('❌ Eliminazione annullata');
              Navigator.of(context).pop();
            },
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () {
              AppLogger.debug('✅ Conferma eliminazione');
              Navigator.of(context).pop();
              _deleteRecipe(recipe);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    AppLogger.api('🗑️ Eliminazione ricetta: ${recipe.title}');

    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final success = await recipeService.deleteRecipe(recipe.id);

      if (success) {
        AppLogger.success('✅ Ricetta eliminata: ${recipe.title}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${recipe.title}" eliminata con successo'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppLogger.error('❌ Errore eliminazione ricetta');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'eliminazione'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('❌ Errore eliminazione', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Estrae l'ID autore dalla mappa author
  String? _extractAuthorId(Map<String, dynamic> author) {
    if (author.isEmpty) return null;

    const possibleKeys = ['id', 'userId', '_id', 'authorId', 'user_id'];

    for (final key in possibleKeys) {
      final value = author[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    if (author.containsKey('user') && author['user'] is Map) {
      final userMap = author['user'] as Map<String, dynamic>;
      for (final key in possibleKeys) {
        final value = userMap[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏗️ Building DetailRecipeScreen');

    final authService = Provider.of<AuthService>(context, listen: false);
    bool isOwner = false;

    if (_recipe != null && authService.userId != null) {
      final authorId = _extractAuthorId(_recipe!.author);

      if (authorId != null) {
        final normalizedUserId = authService.userId!.trim().toLowerCase();
        final normalizedAuthorId = authorId.trim().toLowerCase();
        isOwner = normalizedUserId == normalizedAuthorId;

        AppLogger.debug(
            'Ownership check: $isOwner (User: $normalizedUserId, Author: $normalizedAuthorId)');
      } else {
        AppLogger.debug('Could not extract authorId from: ${_recipe!.author}');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe?.title ?? 'Dettaglio Ricetta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppLogger.debug('⬅️ Torna indietro da DetailRecipeScreen');
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (isOwner && _recipe != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87),
              onPressed: () => _navigateToEditScreen(_recipe!),
              tooltip: 'Modifica ricetta',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black87),
              onPressed: () => _showDeleteDialog(_recipe!),
              tooltip: 'Elimina ricetta',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _recipe != null
                  ? _buildRecipeDetail()
                  : _buildError(),
    );
  }
}
