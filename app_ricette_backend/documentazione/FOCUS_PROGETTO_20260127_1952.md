# 🎯 FOCUS PROGETTO RICETTE
# Generato: 27/01/2026 19:52:32

## 🔙 BACKEND

### File nella root:
```
app_ricette_backend/check_recipes.sql
app_ricette_backend/database_info.txt
app_ricette_backend/docker-compose.yml
app_ricette_backend/Dockerfile
app_ricette_backend/.env
app_ricette_backend/.gitignore
app_ricette_backend/nodemon.json
app_ricette_backend/package.json
app_ricette_backend/package-lock.json
app_ricette_backend/start-all.sh
app_ricette_backend/test_persistenza.txt
app_ricette_backend/test_update.json
app_ricette_backend/tsconfig.json
```

### Contenuto di prisma/:
```
app_ricette_backend/prisma
├── migrations
│   ├── 20251231200129_init
│   │   └── migration.sql
│   ├── 20251231222142_add_sessions_complete
│   │   └── migration.sql
│   ├── 20260105205558_add_like_model
│   │   └── migration.sql
│   ├── 20260109171002_add_comments_and_count
│   │   └── migration.sql
│   ├── 20260120201932_add_user_security_fields
│   │   └── migration.sql
│   └── migration_lock.toml
├── prisma.config.ts
├── schema.backup.prisma
├── schema.prisma
└── seed.ts

6 directories, 10 files
```

### Contenuto di src/:
```
app_ricette_backend/src
├── app.ts
├── config
├── controllers
│   ├── auth.controller.ts
│   └── recipe.controller.ts
├── middleware
│   └── auth.ts
├── routes
│   ├── authRoutes.ts
│   ├── categoryRoutes.ts
│   ├── commentRoutes.ts
│   ├── favoriteRoutes.ts
│   └── recipeRoutes.ts
├── server.ts
├── services
│   ├── auth
│   ├── cloudinary.service.ts
│   └── email.service.ts
├── sockets
├── types
│   └── winston-daily-rotate-file.d.ts
└── utils
    ├── auth.ts
    └── logger
        ├── formats.ts
        ├── index.ts
        └── transports.ts

10 directories, 17 files
```

## 📱 FRONTEND

### File nella root:
```
app_ricette_frontend/analysis_options.yaml
app_ricette_frontend/app_ricette_frontend.iml
app_ricette_frontend/app_ricette.iml
app_ricette_frontend/.flutter-plugins-dependencies
app_ricette_frontend/.gitignore
app_ricette_frontend/.metadata
app_ricette_frontend/pubspec.lock
app_ricette_frontend/pubspec.yaml
app_ricette_frontend/README.md
```

### Contenuto di lib/:
```
app_ricette_frontend/lib
├── config.dart
├── main.dart
├── models
│   ├── comment.dart
│   └── recipe.dart
├── navigation
│   └── app_router.dart
├── providers
├── screens
│   ├── auth
│   │   ├── forgot_password_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── register_screen.dart.backup
│   │   ├── reset_password_screen.dart
│   │   └── verify_email_screen.dart
│   ├── home
│   │   ├── home_screen.dart
│   │   ├── viewmodels
│   │   └── widgets
│   │       ├── categories_bar.dart
│   │       ├── empty_state.dart
│   │       ├── recipe_list.dart
│   │       ├── recipe_search_bar.dart
│   │       └── welcome_header.dart
│   ├── profile
│   │   ├── profile_recipes_list.dart
│   │   ├── profile_screen.dart
│   │   ├── profile_stats_widget.dart
│   │   └── widgets
│   │       ├── avatar_picker.dart
│   │       ├── profile_header.dart
│   │       └── profile_tabs.dart
│   └── recipe
│       ├── create_recipe
│       │   ├── create_basic_info.dart
│       │   ├── create_header.dart
│       │   ├── create_image_section.dart
│       │   ├── create_ingredients.dart
│       │   ├── create_instructions.dart
│       │   └── create_tags.dart
│       ├── create_recipe_screen.dart
│       ├── detail_recipe
│       │   ├── constants.dart
│       │   ├── utils
│       │   │   └── detail_helpers.dart
│       │   └── widgets
│       │       ├── comment_input_widget.dart
│       │       ├── comment_item_widget.dart
│       │       ├── comments_list_widget.dart
│       │       ├── detail_comments_section.dart
│       │       ├── detail_header_section.dart
│       │       ├── detail_image_section.dart
│       │       ├── detail_info_section.dart
│       │       ├── detail_ingredients_section.dart
│       │       ├── detail_instructions_section.dart
│       │       ├── detail_tags_section.dart
│       │       └── utils
│       │           └── comment_state_manager.dart
│       ├── detail_recipe_screen.dart
│       ├── edit_recipe
│       │   ├── edit_basic_info.dart
│       │   ├── edit_header.dart
│       │   ├── edit_image_section.dart
│       │   ├── edit_ingredients.dart
│       │   ├── edit_instructions.dart
│       │   └── edit_tags.dart
│       ├── edit_recipe_screen.dart
│       └── widgets
│           ├── favorite_button.dart
│           └── like_button.dart
├── services
│   ├── auth_service.dart
│   ├── avatar_service.dart
│   ├── comment_service.dart
│   ├── favorite_service.dart
│   ├── like_service.dart
│   ├── profile_controller.dart
│   ├── profile_service.dart
│   └── recipe_service.dart
├── utils
│   ├── app_theme.dart
│   ├── logger.dart
│   ├── recipe_helpers.dart
│   └── service_coordinator.dart
└── widgets
    ├── action_menu_button.dart
    ├── loading_indicator.dart
    └── recipe_card.dart

21 directories, 68 files
```
