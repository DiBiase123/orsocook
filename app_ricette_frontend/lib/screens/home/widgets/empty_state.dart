// lib/screens/home/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/recipe_service.dart';
import '../../../utils/logger.dart';

class EmptyState extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback onRetry;
  final VoidCallback onCreateRecipe;

  const EmptyState({
    super.key,
    this.searchQuery,
    required this.onRetry,
    required this.onCreateRecipe,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏜️ Building EmptyState');

    final recipeService = Provider.of<RecipeService>(context);

    // Se sta caricando, mostra loading
    if (recipeService.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento ricette...'),
          ],
        ),
      );
    }

    // Se c'è un errore, mostra errore
    if (recipeService.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Errore nel caricamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              recipeService.lastError ?? 'Errore sconosciuto',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('RIPROVA'),
            ),
          ],
        ),
      );
    }

    // Se c'è una ricerca ma nessun risultato
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nessuna ricetta trovata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nessun risultato per "$searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Questa logica sarà gestita dal parent
              },
              child: const Text('Cancella ricerca'),
            ),
          ],
        ),
      );
    }

    // Stato vuoto normale
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nessuna ricetta disponibile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sii il primo a creare una ricetta!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onCreateRecipe,
            child: const Text('CREA LA TUA PRIMA RICETTA'),
          ),
        ],
      ),
    );
  }
}
