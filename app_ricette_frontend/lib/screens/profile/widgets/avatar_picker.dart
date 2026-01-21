// lib/screens/profile/widgets/avatar_picker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_controller.dart';
import '../../../services/auth_service.dart';

class AvatarPickerWidget extends StatelessWidget {
  const AvatarPickerWidget({super.key});

  void _showAvatarConfirmDialog(BuildContext context) {
    final controller = Provider.of<ProfileController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambia avatar'),
        content: const Text('Vuoi salvare questa immagine come avatar?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearSelectedAvatar();
            },
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await controller.uploadAvatar();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] as String),
                    backgroundColor:
                        result['success'] == true ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _pickAvatarImage(BuildContext context) async {
    final controller = Provider.of<ProfileController>(context, listen: false);

    try {
      await controller.pickAvatarImage();

      if (controller.selectedAvatar != null && context.mounted) {
        _showAvatarConfirmDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Stack(
      children: [
        // Avatar container
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: controller.isChangingAvatar
              ? const Center(child: CircularProgressIndicator())
              : ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: _buildAvatarImage(controller, authService, context),
                ),
        ),

        // Pulsante cambia avatar
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
              onPressed:
                  controller.isBusy ? null : () => _pickAvatarImage(context),
              tooltip: 'Cambia avatar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(
    ProfileController controller,
    AuthService authService,
    BuildContext context,
  ) {
    // Priorità 1: File temporaneo selezionato
    if (controller.selectedAvatar != null) {
      return Image.file(
        controller.selectedAvatar!,
        fit: BoxFit.cover,
      );
    }

    // Priorità 2: Avatar dal profilo
    final profileAvatarUrl = controller.displayAvatarUrl;
    if (profileAvatarUrl != null && profileAvatarUrl.isNotEmpty) {
      return Image.network(
        profileAvatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderIcon(context),
      );
    }

    // Priorità 3: Avatar da AuthService (cache)
    final authAvatarUrl = authService.avatarUrl;
    if (authAvatarUrl != null && authAvatarUrl.isNotEmpty) {
      return Image.network(
        authAvatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderIcon(context),
      );
    }

    // Fallback: icona placeholder
    return _buildPlaceholderIcon(context);
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Icon(
      Icons.person,
      size: 40,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
