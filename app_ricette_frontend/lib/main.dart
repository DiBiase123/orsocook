import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orsocook/services/auth_service.dart';
import 'package:orsocook/services/recipe_service.dart';
import 'package:orsocook/services/comment_service.dart';
import 'package:orsocook/services/profile_service.dart';
import 'package:orsocook/services/avatar_service.dart';
import 'package:orsocook/services/profile_controller.dart';
import 'package:orsocook/services/like_service.dart';
import 'package:orsocook/services/favorite_service.dart';
import 'package:orsocook/navigation/app_router.dart';
import 'package:orsocook/utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(),
        ),
        ChangeNotifierProvider<LikeService>(
          create: (context) => LikeService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<FavoriteService>(
          create: (context) => FavoriteService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<RecipeService>(
          create: (context) => RecipeService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<ProfileService>(
          create: (context) => ProfileService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<AvatarService>(
          create: (context) => AvatarService(),
        ),
        ChangeNotifierProvider<CommentService>(
          create: (context) => CommentService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(
            authService: context.read<AuthService>(),
            profileService: context.read<ProfileService>(),
            avatarService: context.read<AvatarService>(),
            commentService: context.read<CommentService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'OrsoCook',
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
