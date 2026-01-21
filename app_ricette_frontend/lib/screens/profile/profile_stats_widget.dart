import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

class ProfileStatsWidget extends StatelessWidget {
  final UserStats stats;

  const ProfileStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(10), // ~0.05 opacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withAlpha(50), // ~0.2 opacity
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                icon: Icons.restaurant_menu,
                value: stats.recipesCount.toString(),
                label: 'Ricette',
                color: Colors.blue,
              ),
              _buildStatItem(
                context,
                icon: Icons.favorite,
                value: stats.favoritesCount.toString(),
                label: 'Preferiti',
                color: Colors.red,
              ),
              _buildStatItem(
                context,
                icon: Icons.visibility,
                value: stats.totalViews.toString(),
                label: 'Visualizzazioni',
                color: Colors.green,
              ),
              _buildStatItem(
                context,
                icon: Icons.trending_up,
                value: '${stats.averageViewsPerRecipe}',
                label: 'Media/ricetta',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25), // ~0.1 opacity
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withAlpha(75), // ~0.3 opacity
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
