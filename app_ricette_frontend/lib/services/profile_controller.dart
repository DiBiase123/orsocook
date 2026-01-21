import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'avatar_service.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'comment_service.dart';
import '../models/recipe.dart';

class ProfileController extends ChangeNotifier {
  // Dependencies
  final AuthService _authService;
  final ProfileService _profileService;
  final AvatarService _avatarService;
  final CommentService _commentService;

  // State
  File? _selectedAvatar;
  bool _isChangingAvatar = false;
  bool _isPickingAvatar = false;
  int _selectedTabIndex = 0;
  String? _lastSuccessMessage;
  bool _isDisposed = false;

  // Getters
  File? get selectedAvatar => _selectedAvatar;
  bool get isChangingAvatar => _isChangingAvatar;
  bool get isPickingAvatar => _isPickingAvatar;
  int get selectedTabIndex => _selectedTabIndex;
  String? get lastSuccessMessage => _lastSuccessMessage;
  bool get isLoading => _profileService.isLoading;
  String? get error => _profileService.error;
  bool get hasProfile => _profileService.currentProfile != null;
  UserProfile? get userProfile => _profileService.currentProfile?.user;
  UserStats? get userStats => _profileService.currentProfile?.stats;
  List<Recipe>? get recentRecipes =>
      _profileService.currentProfile?.recentRecipes;
  List<Recipe>? get recentFavorites =>
      _profileService.currentProfile?.recentFavorites;
  bool get isShowingTempAvatar => _selectedAvatar != null;
  File? get avatarFile => _selectedAvatar;
  bool get isBusy =>
      _isChangingAvatar || _isPickingAvatar || _profileService.isLoading;

  String? get displayAvatarUrl {
    if (_selectedAvatar != null) return null;
    final profileAvatar = _profileService.currentProfile?.user.avatarUrl;
    final authAvatar = _authService.avatarUrl;
    return profileAvatar ?? authAvatar;
  }

  ProfileController({
    required AuthService authService,
    required ProfileService profileService,
    required AvatarService avatarService,
    required CommentService commentService,
  })  : _authService = authService,
        _profileService = profileService,
        _avatarService = avatarService,
        _commentService = commentService;

  @override
  void dispose() {
    _isDisposed = true; // ← PRIMA le tue pulizie
    super.dispose(); // ← POI la classe parent
  }
  // ================ AVATAR MANAGEMENT ================

  Future<void> pickAvatarImage() async {
    if (_isDisposed || _isPickingAvatar) return;

    _isPickingAvatar = true;
    _safeNotify();

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final image = File(pickedFile.path);
        final sizeInBytes = await image.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > 5.0) {
          throw Exception(
              'L\'immagine è troppo grande (${sizeInMB.toStringAsFixed(1)}MB). Massimo 5MB');
        }

        _selectedAvatar = image;
        _safeNotify();
      }
    } catch (e) {
      if (!_isDisposed) rethrow;
    } finally {
      _isPickingAvatar = false;
      _safeNotify();
    }
  }

  Future<Map<String, dynamic>> uploadAvatar() async {
    if (_isDisposed || _selectedAvatar == null) {
      return {
        'success': false,
        'message': 'Controller dismesso o nessuna immagine'
      };
    }

    _isChangingAvatar = true;
    _lastSuccessMessage = null;
    _safeNotify();

    try {
      final result = await _avatarService.uploadAvatar(_selectedAvatar!);

      if (result['success'] == true) {
        final newAvatarUrl = result['avatarUrl'] as String?;
        final userId = _authService.userId;
        _lastSuccessMessage = result['message'];

        if (newAvatarUrl != null && _authService.isLoggedIn) {
          _authService.updateAvatar(newAvatarUrl);
        }

        if (newAvatarUrl != null) {
          _profileService.updateAvatarLocally(newAvatarUrl);
        }

        if (userId != null && newAvatarUrl != null) {
          try {
            _commentService.updateAvatarInComments(userId, newAvatarUrl);
          } catch (e) {
            // Ignora errori secondari
          }
        }

        _safeNotify();
        await refreshProfile();
        _selectedAvatar = null;

        return {
          'success': true,
          'message': _lastSuccessMessage,
          'avatarUrl': newAvatarUrl,
        };
      } else {
        _lastSuccessMessage = result['message'] ?? 'Errore durante l\'upload';
        _safeNotify();

        return {
          'success': false,
          'message': _lastSuccessMessage,
        };
      }
    } catch (e) {
      if (!_isDisposed) {
        _isChangingAvatar = false;
        _lastSuccessMessage = 'Errore durante l\'upload: $e';
        _safeNotify();
      }

      return {
        'success': false,
        'message': _lastSuccessMessage,
      };
    } finally {
      if (!_isDisposed) {
        _isChangingAvatar = false;
        _safeNotify();
      }
    }
  }

  void clearSelectedAvatar() {
    if (_isDisposed) return;
    _selectedAvatar = null;
    _safeNotify();
  }

  void clearSuccessMessage() {
    if (_isDisposed) return;
    _lastSuccessMessage = null;
    _safeNotify();
  }

  // ================ PROFILE MANAGEMENT ================

  Future<void> loadProfile() async {
    if (_isDisposed) return;

    final userId = _authService.userId;
    if (userId != null) {
      await _profileService.fetchUserProfile(userId);
      _safeNotify();
    }
  }

  Future<void> refreshProfile() async {
    if (_isDisposed) return;
    await loadProfile();
  }

  Future<void> logout() async {
    if (_isDisposed) return;

    try {
      await _authService.logout();
      _profileService.clearProfile();
      _selectedAvatar = null;
      _lastSuccessMessage = null;
      _safeNotify();
    } catch (e) {
      if (!_isDisposed) rethrow;
    }
  }

  void retry() {
    if (_isDisposed) return;
    _profileService.retry();
    _safeNotify();
  }

  // ================ TAB MANAGEMENT ================

  void selectTab(int index) {
    if (_isDisposed) return;
    _selectedTabIndex = index;
    _safeNotify();
  }

  // ================ UTILITY ================

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ================ SAFE NOTIFY ================

  void _safeNotify() {
    if (!_isDisposed && hasListeners) {
      Future.microtask(() {
        if (!_isDisposed && hasListeners) {
          notifyListeners();
        }
      });
    }
  }
}
