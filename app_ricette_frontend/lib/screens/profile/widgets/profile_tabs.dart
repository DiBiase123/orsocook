// lib/screens/profile/widgets/profile_tabs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/profile_controller.dart';
import '../../../screens/profile/profile_recipes_list.dart';

class ProfileTabs extends StatefulWidget {
  const ProfileTabs({super.key});

  @override
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);
    final tabTitles = ['Le Mie Ricette', 'Preferiti'];

    return Column(
      children: [
        // Tab bar
        Container(
          color: Theme.of(context).colorScheme.primary.withAlpha(25),
          child: TabBar(
            controller: _tabController,
            tabs: tabTitles.map((title) => Tab(text: title)).toList(),
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            onTap: (index) {
              controller.selectTab(index);
            },
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(controller, 0),
              _buildTabContent(controller, 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(ProfileController controller, int tabIndex) {
    if (controller.isLoading && !controller.hasProfile) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento dati...'),
          ],
        ),
      );
    }

    if (!controller.hasProfile) {
      return _buildEmptyProfile(controller);
    }

    switch (tabIndex) {
      case 0: // Le Mie Ricette
        return ProfileRecipesList(
          recipes: controller.recentRecipes!,
          userId: controller.userProfile!.id,
          emptyMessage: 'Non hai ancora creato ricette',
          emptyIcon: Icons.restaurant_menu_outlined,
          isUserRecipes: true,
        );
      case 1: // Preferiti
        return ProfileRecipesList(
          recipes: controller.recentFavorites!,
          userId: controller.userProfile!.id,
          emptyMessage: 'Non hai ricette preferite',
          emptyIcon: Icons.favorite_border,
          isUserRecipes: false,
        );
      default:
        return const Center(child: Text('Tab non valido'));
    }
  }

  Widget _buildEmptyProfile(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessun profilo caricato',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF757575), // Colors.grey[600]
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.refreshProfile,
            child: const Text('Ricarica'),
          ),
        ],
      ),
    );
  }
}
