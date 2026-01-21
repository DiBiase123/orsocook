import 'package:flutter/material.dart';
import 'package:orsocook/models/recipe.dart';
import 'package:orsocook/utils/logger.dart';

class DetailTagsSection extends StatelessWidget {
  final Recipe recipe;

  const DetailTagsSection({super.key, required this.recipe});

  // METODO PRINCIPALE PER ESTRARRE I NOMI DEI TAG
  List<String> _extractTagNames(List<dynamic> tags) {
    final List<String> tagNames = [];

    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i];
      String tagName = '';

      // DEBUG: utile per troubleshooting
      AppLogger.debug('   🔍 Tag $i: ${tag.runtimeType}');

      // CASO 1: Tag è una stringa semplice
      if (tag is String) {
        tagName = tag;
        AppLogger.debug('     → Stringa diretta: "$tagName"');
      }
      // CASO 2: Tag è una mappa/oggetto
      else if (tag is Map) {
        // STRUTTURA PRIMARIA: tag['tag']['name'] (quello che hai nei log)
        if (tag.containsKey('tag') &&
            tag['tag'] is Map &&
            tag['tag']['name'] != null) {
          tagName = tag['tag']['name'].toString();
          AppLogger.debug('     → Da tag[\'tag\'][\'name\']: "$tagName"');
        }
        // STRUTTURA ALTERNATIVA 1: tag['name'] diretto
        else if (tag['name'] != null) {
          tagName = tag['name'].toString();
          AppLogger.debug('     → Da tag[\'name\'] diretto: "$tagName"');
        }
        // STRUTTURA ALTERNATIVA 2: altre chiavi comuni
        else {
          // Prova tutte le chiavi possibili
          final possibleKeys = ['label', 'title', 'value', 'text', 'tagName'];
          for (final key in possibleKeys) {
            if (tag[key] != null) {
              tagName = tag[key].toString();
              AppLogger.debug('     → Da tag[\'$key\']: "$tagName"');
              break;
            }
          }

          // Se ancora vuoto, prova a convertire l'intero oggetto
          if (tagName.isEmpty) {
            tagName = tag.toString();
            AppLogger.debug('     → Da toString(): "$tagName"');
          }
        }
      }
      // CASO 3: Altri tipi (int, double, ecc.)
      else {
        tagName = tag.toString();
        AppLogger.debug('     → Altro tipo: "$tagName"');
      }

      // Pulisci e valida il nome
      tagName = tagName.trim();

      if (tagName.isEmpty) {
        AppLogger.debug('     ⚠️ Nome vuoto, salto');
        continue;
      }

      // Rimuovi caratteri non desiderati (opzionale)
      tagName = tagName.replaceAll('{', '').replaceAll('}', '');

      if (!tagNames.contains(tagName)) {
        tagNames.add(tagName);
        AppLogger.debug('     ✅ Aggiunto: "$tagName"');
      } else {
        AppLogger.debug('     🔄 Duplicato, salto: "$tagName"');
      }
    }

    AppLogger.debug('🎯 Tag estratti finali (${tagNames.length}): $tagNames');
    return tagNames;
  }

  @override
  Widget build(BuildContext context) {
    final tagNames = _extractTagNames(recipe.tags);

    if (tagNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Tag',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tagNames.map((tagName) {
            return Chip(
              label: Text(
                tagName,
                style: const TextStyle(fontSize: 14),
              ),
              backgroundColor: Colors.orange[50],
              side: BorderSide(color: Colors.orange[300]!),
              labelStyle: TextStyle(
                color: Colors.orange[900],
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
