import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../utils/logger.dart';
import 'edit_recipe/edit_image_section.dart';
import 'edit_recipe/edit_basic_info.dart';
import 'edit_recipe/edit_ingredients.dart';
import 'edit_recipe/edit_instructions.dart';
import 'edit_recipe/edit_tags.dart';
import 'edit_recipe/edit_header.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => EditRecipeScreenState();
}

class EditRecipeScreenState extends State<EditRecipeScreen> {
  late Recipe _editedRecipe;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _ingredientNameController =
      TextEditingController();
  final TextEditingController _ingredientQuantityController =
      TextEditingController();
  final TextEditingController _ingredientUnitController =
      TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  bool _isSaving = false;
  bool _hasChanges = false;
  File? _selectedImage;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    AppLogger.recipe('✏️ EditRecipeScreen per: ${widget.recipe.title}');

    // Crea una copia sicura della ricetta
    _editedRecipe = Recipe.fromJson(widget.recipe.toJson());

    // Inizializza immagine
    _imageUrl = widget.recipe.imageUrl ?? '';

    // DEBUG: Log della struttura dei tag
    AppLogger.debug('🏷️ Tags originali (${widget.recipe.tags.length}):');
    for (var i = 0; i < widget.recipe.tags.length; i++) {
      final tag = widget.recipe.tags[i];
      AppLogger.debug('   • Tag $i: ${tag.runtimeType}');
      if (tag is Map) {
        final tagMap = tag as Map<String, dynamic>;
        AppLogger.debug('     - Keys: ${tagMap.keys.toList()}');
        if (tagMap.containsKey('tag')) {
          AppLogger.debug('     - tag[tag]: ${tagMap['tag']}');
        }
      }
    }

    // Inizializza controller
    _titleController.text = _editedRecipe.title;
    _descriptionController.text = _editedRecipe.description;
    _prepTimeController.text = _editedRecipe.prepTime.toString();
    _cookTimeController.text = _editedRecipe.cookTime.toString();
    _servingsController.text = _editedRecipe.servings.toString();

    // Listener per tracciare modifiche
    _titleController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _prepTimeController.addListener(_markAsChanged);
    _cookTimeController.addListener(_markAsChanged);
    _servingsController.addListener(_markAsChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _ingredientNameController.dispose();
    _ingredientQuantityController.dispose();
    _ingredientUnitController.dispose();
    _instructionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // ========== GESTIONE IMMAGINI ==========
  Future<void> _pickImage() async {
    final currentContext = context;
    if (!currentContext.mounted) return;

    showModalBottomSheet(
      context: currentContext,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galleria'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Fotocamera'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectImageFromCamera();
                },
              ),
              if (_imageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Rimuovi immagine',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _hasChanges = true;
      });
    }
  }

  Future<void> _removeImage() async {
    final currentContext = context;
    if (!currentContext.mounted) return;

    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi immagine'),
        content: const Text('Vuoi rimuovere l\'immagine della ricetta?'),
        actions: [
          TextButton(
            onPressed: () {
              final dialogContext = context;
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () async {
              final dialogContext = context;
              if (dialogContext.mounted) Navigator.pop(dialogContext);

              setState(() {
                _selectedImage = null;
                _imageUrl = '';
                _hasChanges = true;
              });
            },
            child: const Text('RIMUOVI', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImageIfNeeded(RecipeService recipeService) async {
    final currentContext = context;
    if (!currentContext.mounted) return;

    if (_selectedImage != null) {
      final newImageUrl = await recipeService.uploadRecipeImage(
        _editedRecipe.id,
        _selectedImage!,
      );

      if (newImageUrl != null) {
        setState(() => _imageUrl = newImageUrl);
      }
    } else if (_imageUrl.isEmpty && widget.recipe.imageUrl != null) {
      await recipeService.removeRecipeImage(_editedRecipe.id);
    }
  }

  // ========== VALIDAZIONI ==========
  String? _validateRequired(String? value, String fieldName) {
    return (value == null || value.isEmpty)
        ? '$fieldName è obbligatorio'
        : null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName è obbligatorio';
    final num = int.tryParse(value);
    return (num == null || num <= 0) ? 'Inserisci un numero valido' : null;
  }

  // ========== GESTIONE INGREDIENTI ==========
  void _addIngredient() {
    final name = _ingredientNameController.text.trim();
    if (name.isEmpty) return;

    final ingredient = {
      'name': name,
      'quantity': _ingredientQuantityController.text.isNotEmpty
          ? _ingredientQuantityController.text
          : '1',
      'unit': _ingredientUnitController.text.isNotEmpty
          ? _ingredientUnitController.text
          : 'pz',
    };

    setState(() {
      _editedRecipe.ingredients.add(ingredient);
      _hasChanges = true;
    });

    _ingredientNameController.clear();
    _ingredientQuantityController.clear();
    _ingredientUnitController.clear();
  }

  void _removeIngredient(int index) {
    if (index >= 0 && index < _editedRecipe.ingredients.length) {
      setState(() {
        _editedRecipe.ingredients.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  // ========== GESTIONE ISTRUZIONI ==========
  void _addInstruction() {
    final text = _instructionController.text.trim();
    if (text.isEmpty) return;

    final instruction = {
      'step': _editedRecipe.instructions.length + 1,
      'description': text,
    };

    setState(() {
      _editedRecipe.instructions.add(instruction);
      _hasChanges = true;
    });

    _instructionController.clear();
  }

  void _removeInstruction(int index) {
    if (index >= 0 && index < _editedRecipe.instructions.length) {
      setState(() {
        _editedRecipe.instructions.removeAt(index);
        for (var i = 0; i < _editedRecipe.instructions.length; i++) {
          _editedRecipe.instructions[i]['step'] = i + 1;
        }
        _hasChanges = true;
      });
    }
  }

  // ========== GESTIONE TAG ==========
  String _extractTagName(dynamic tag) {
    try {
      if (tag is Map) {
        final tagMap = tag as Map<String, dynamic>;
        if (tagMap.containsKey('tag') && tagMap['tag'] is Map) {
          final tagData = tagMap['tag'] as Map<String, dynamic>;
          return tagData['name']?.toString() ?? 'Tag';
        }
        if (tagMap.containsKey('name')) {
          return tagMap['name']?.toString() ?? 'Tag';
        }
        return tagMap.toString();
      }
      if (tag is String) return tag;
      return tag?.toString() ?? 'Tag';
    } catch (e) {
      return 'Tag';
    }
  }

  String? _extractTagId(dynamic tag) {
    try {
      if (tag is Map) {
        final tagMap = tag as Map<String, dynamic>;
        if (tagMap.containsKey('tagId')) {
          return tagMap['tagId']?.toString();
        }
        if (tagMap.containsKey('tag') && tagMap['tag'] is Map) {
          final tagData = tagMap['tag'] as Map<String, dynamic>;
          if (tagData.containsKey('id')) {
            return tagData['id']?.toString();
          }
        }
        if (tagMap.containsKey('id')) {
          return tagMap['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isEmpty) return;

    bool exists = _editedRecipe.tags.any((t) {
      final tagName = _extractTagName(t);
      return tagName.toLowerCase() == tag.toLowerCase();
    });

    if (!exists) {
      setState(() {
        _editedRecipe.tags.add({'name': tag});
        _hasChanges = true;
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tagNameToRemove) {
    setState(() {
      _editedRecipe.tags.removeWhere((t) {
        final tagName = _extractTagName(t);
        return tagName == tagNameToRemove;
      });
      _hasChanges = true;
    });
  }

  // ========== SALVATAGGIO ==========
  Future<void> _saveChanges() async {
    final currentContext = context;
    if (!currentContext.mounted) return;

    if (!_formKey.currentState!.validate()) return;
    if (_editedRecipe.ingredients.isEmpty) {
      _showSnackBar('Aggiungi almeno un ingrediente', Colors.orange);
      return;
    }
    if (_editedRecipe.instructions.isEmpty) {
      _showSnackBar('Aggiungi almeno un passo del procedimento', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    final recipeService =
        Provider.of<RecipeService>(currentContext, listen: false);

    try {
      await _uploadImageIfNeeded(recipeService);

      final updatedRecipe = Recipe.fromJson({
        'id': _editedRecipe.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrl,
        'prepTime': int.tryParse(_prepTimeController.text) ?? 0,
        'cookTime': int.tryParse(_cookTimeController.text) ?? 0,
        'servings': int.tryParse(_servingsController.text) ?? 1,
        'difficulty': _editedRecipe.difficulty,
        'isPublic': _editedRecipe.isPublic,
        'ingredients': _editedRecipe.ingredients,
        'instructions': _editedRecipe.instructions,
        'tags': _editedRecipe.tags,
      });

      final savedRecipe = await recipeService.updateRecipe(
        updatedRecipe.id,
        updatedRecipe,
      );

      if (currentContext.mounted) {
        setState(() => _isSaving = false);
      }

      if (savedRecipe != null) {
        _showSnackBar(
            '"${savedRecipe.title}" aggiornata con successo!', Colors.green);
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop(savedRecipe);
        }
      } else {
        _showSnackBar('Errore durante l\'aggiornamento', Colors.red);
      }
    } catch (e) {
      if (currentContext.mounted) {
        setState(() => _isSaving = false);
      }
      AppLogger.error('❌ Errore aggiornamento ricetta', e);

      if (e is DioException) {
        String errorMsg = 'Errore del server';
        if (e.response?.data is Map && e.response!.data['message'] != null) {
          errorMsg = e.response!.data['message'];
        }
        _showSnackBar('Errore: $errorMsg', Colors.red);
      } else {
        _showSnackBar('Errore: ${e.toString().split(".")[0]}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    final currentContext = context;
    if (currentContext.mounted) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _confirmExit() async {
    if (!_hasChanges) return true;

    final currentContext = context;
    if (!currentContext.mounted) return true;

    return await showDialog<bool>(
          context: currentContext,
          builder: (context) => AlertDialog(
            title: const Text('Modifiche non salvate'),
            content: const Text(
                'Le modifiche andranno perse. Vuoi uscire comunque?'),
            actions: [
              TextButton(
                onPressed: () {
                  final dialogContext = context;
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                },
                child: const Text('ANNULLA'),
              ),
              TextButton(
                onPressed: () {
                  final dialogContext = context;
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('ESCI'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ========== WIDGETS ==========
  Widget _buildHeader() {
    return EditHeader(
      recipeTitle: widget.recipe.title,
      recipeId: widget.recipe.id,
      hasChanges: _hasChanges,
    );
  }

  Widget _buildImageSection() {
    return EditImageSection(
      selectedImage: _selectedImage,
      imageUrl: _imageUrl,
      onImageSelected: (File? image) {
        setState(() {
          _selectedImage = image;
          _hasChanges = true;
        });
      },
      onImageRemoved: _removeImage,
      pickImage: _pickImage,
    );
  }

  Widget _buildBasicInfoForm() {
    return EditBasicInfo(
      titleController: _titleController,
      descriptionController: _descriptionController,
      prepTimeController: _prepTimeController,
      cookTimeController: _cookTimeController,
      servingsController: _servingsController,
      difficulty: _editedRecipe.difficulty,
      isPublic: _editedRecipe.isPublic,
      onDifficultyChanged: (value) {
        setState(() {
          _editedRecipe = Recipe.fromJson({
            ..._editedRecipe.toJson(),
            'difficulty': value,
          });
          _hasChanges = true;
        });
      },
      onIsPublicChanged: (value) {
        setState(() {
          _editedRecipe = Recipe.fromJson({
            ..._editedRecipe.toJson(),
            'isPublic': value,
          });
          _hasChanges = true;
        });
      },
      validateRequired: _validateRequired,
      validateNumber: _validateNumber,
    );
  }

  Widget _buildIngredientsEditor() {
    return EditIngredients(
      ingredients: _editedRecipe.ingredients,
      nameController: _ingredientNameController,
      quantityController: _ingredientQuantityController,
      unitController: _ingredientUnitController,
      onAddIngredient: _addIngredient,
      onRemoveIngredient: _removeIngredient,
    );
  }

  Widget _buildInstructionsEditor() {
    return EditInstructions(
      instructions: _editedRecipe.instructions,
      instructionController: _instructionController,
      onAddInstruction: _addInstruction,
      onRemoveInstruction: _removeInstruction,
    );
  }

  Widget _buildTagsEditor() {
    return EditTags(
      tags: _editedRecipe.tags,
      tagController: _tagController,
      onAddTag: _addTag,
      onRemoveTag: _removeTag,
      extractTagName: _extractTagName,
      extractTagId: _extractTagId,
    );
  }

  // ========== BUILD PRINCIPALE ==========
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          final shouldPop = await _confirmExit();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modifica Ricetta'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit()) {
                final currentContext = context;
                if (!currentContext.mounted) return;
                Navigator.of(currentContext).pop();
              }
            },
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 16),
              _buildBasicInfoForm(),
              const SizedBox(height: 16),
              _buildIngredientsEditor(),
              const SizedBox(height: 16),
              _buildInstructionsEditor(),
              const SizedBox(height: 16),
              _buildTagsEditor(),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                  onPressed: () async {
                    final currentContext = context;
                    if (await _confirmExit() && currentContext.mounted) {
                      Navigator.of(currentContext).pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('ANNULLA'),
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                  onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('SALVA MODIFICHE',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}
