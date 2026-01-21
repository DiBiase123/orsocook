import 'package:flutter/material.dart';

class CreateHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final VoidCallback onBackPressed;

  const CreateHeader({
    super.key,
    required this.isLoading,
    required this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Crea Nuova Ricetta'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ),
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}
