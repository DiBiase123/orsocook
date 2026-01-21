// lib/screens/profile/widgets/profile_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_controller.dart';
import 'avatar_picker.dart';
import '../../../services/auth_service.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);
    final user = controller.userProfile;
    final auth = Provider.of<AuthService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primary
                .withAlpha((255 * 0.1).round()),
            Theme.of(context)
                .colorScheme
                .secondary
                .withAlpha((255 * 0.05).round()),
          ],
        ),
      ),
      child: Row(
        children: [
          // Avatar con pulsante cambia
          const AvatarPickerWidget(),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (auth.username != null)
                  Text(
                    auth.username!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    'Caricamento...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                if (user != null)
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (auth.isLoggedIn)
                  Text(
                    'Utente registrato',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                if (user != null)
                  Text(
                    'Membro dal ${controller.formatDate(user.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
