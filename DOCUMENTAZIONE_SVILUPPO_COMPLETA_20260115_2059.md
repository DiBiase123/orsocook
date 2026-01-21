# 🍳 PROGETTO RICETTE - Struttura per sviluppo
# Generato: 15/01/2026 20:59

## 🔙 BACKEND (Node.js - API)
```
app_ricette_backend/
├── docs
├── logs
│   ├── api-2026-01-08.log
│   ├── api-2026-01-09.log
│   ├── api-2026-01-10.log
│   ├── api-2026-01-12.log
│   ├── api-2026-01-13.log
│   ├── api-2026-01-14.log
│   ├── api-2026-01-15.log
│   ├── combined-2026-01-05.log
│   ├── combined-2026-01-06.log
│   ├── combined-2026-01-07.log
│   ├── combined-2026-01-08.log
│   ├── combined-2026-01-09.log
│   ├── combined-2026-01-10.log
│   ├── combined-2026-01-12.log
│   ├── combined-2026-01-13.log
│   ├── combined-2026-01-14.log
│   ├── combined-2026-01-15.log
│   ├── error-2026-01-05.log
│   ├── error-2026-01-06.log
│   ├── error-2026-01-07.log
│   ├── error-2026-01-08.log
│   ├── error-2026-01-09.log
│   ├── error-2026-01-10.log
│   ├── error-2026-01-12.log
│   ├── error-2026-01-14.log
│   └── error-2026-01-15.log
├── prisma
│   ├── migrations
│   │   ├── 20251231200129_init
│   │   │   └── migration.sql
│   │   ├── 20251231222142_add_sessions_complete
│   │   │   └── migration.sql
│   │   ├── 20260105205558_add_like_model
│   │   │   └── migration.sql
│   │   ├── 20260109171002_add_comments_and_count
│   │   │   └── migration.sql
│   │   └── migration_lock.toml
│   ├── prisma.config.ts
│   ├── schema.backup.prisma
│   ├── schema.prisma
│   └── seed.ts
├── scripts
│   └── dev-with-services.sh
├── src
│   ├── config
│   │   └── storage.ts
│   ├── controllers
│   │   ├── auth.controller.ts
│   │   └── recipe.controller.ts
│   ├── middleware
│   │   └── auth.ts
│   ├── routes
│   │   ├── authRoutes.ts
│   │   ├── categoryRoutes.ts
│   │   ├── commentRoutes.ts
│   │   ├── favoriteRoutes.ts
│   │   └── recipeRoutes.ts
│   ├── services
│   │   └── auth
│   ├── sockets
│   ├── utils
│   │   ├── logger
│   │   │   ├── formats.ts
│   │   │   ├── index.ts
│   │   │   └── transports.ts
│   │   ├── auth.ts
│   │   └── minio.ts
│   ├── app.ts
│   └── server.ts
├── tests
├── uploads
│   ├── avatars
│   │   ├── avatar-1768417662192-76939491.png
│   │   ├── avatar-1768417796010-69259223.png
│   │   ├── avatar-1768418387595-159492757.png
│   │   ├── avatar-1768418695211-347024364.png
│   │   ├── avatar-1768419885972-801265713.png
│   │   ├── avatar-1768419984275-899979426.png
│   │   ├── avatar-1768420507634-351837626.png
│   │   ├── avatar-1768421052742-456994985.png
│   │   ├── avatar-1768421104823-784983191.png
│   │   ├── avatar-1768421196742-68593859.png
│   │   ├── avatar-1768422044662-195884202.png
│   │   ├── avatar-1768422108622-599609529.png
│   │   ├── avatar-1768422121542-977217184.png
│   │   ├── avatar-1768422160685-699554035.png
│   │   ├── avatar-1768422206807-827485839.png
│   │   ├── avatar-1768422220838-141106464.png
│   │   ├── avatar-1768422460427-353075.png
│   │   ├── avatar-1768422474552-863857889.png
│   │   ├── avatar-1768422485781-649528426.png
│   │   ├── avatar-1768422523900-270052694.png
│   │   ├── avatar-1768422543250-132135948.png
│   │   ├── avatar-1768422561580-328229231.png
│   │   ├── avatar-1768422574831-924494256.png
│   │   ├── avatar-1768422926157-358827474.png
│   │   ├── avatar-1768422977124-211790921.png
│   │   ├── avatar-1768423878833-98199361.png
│   │   ├── avatar-1768431074176-162738138.png
│   │   ├── avatar-1768434283714-97623255.png
│   │   └── avatar-1768434455856-148691173.png
│   ├── recipes
│   │   └── recipe-1767564034466-735926888.png
│   ├── image-1767740755839-216719075.png
│   ├── image-1767741400314-831296536.png
│   ├── image-1767741735191-13958090.png
│   ├── image-1767741798996-728945637.png
│   ├── image-1767741979472-220951018.png
│   ├── image-1767785130219-503031958.png
│   ├── image-1767798465254-593676548.png
│   ├── image-1767798482772-196985705.png
│   ├── image-1767798739582-646816846.png
│   ├── image-1767800462981-232913138.png
│   ├── image-1767805226799-19347088.png
│   ├── image-1767819379180-897902749.png
│   ├── image-1767819423967-41340253.png
│   ├── image-1767971640376-928395226.png
│   ├── image-1767971838241-442438249.png
│   ├── image-1767971858478-865357496.jpg
│   ├── image-1767993275608-422227429.png
│   ├── image-1768503672611-790053578.png
│   ├── image-1768504070136-793969494.png
│   ├── image-1768504735233-775631588.png
│   ├── image-1768505000115-412265957.png
│   ├── image-1768505178191-946566201.png
│   └── image-1768505332277-258595319.png
├── check_recipes.sql
├── database_info.txt
├── docker-compose.yml
├── Dockerfile
├── nodemon.json
├── package.json
├── package-lock.json
├── start-all.sh
├── test_persistenza.txt
├── test_update.json
└── tsconfig.json

23 directories, 116 files
```

## 📱 FRONTEND (Flutter - App)
```
app_ricette_frontend/
├── android
│   ├── app
│   │   ├── src
│   │   │   ├── debug
│   │   │   │   └── AndroidManifest.xml
│   │   │   ├── main
│   │   │   │   ├── java
│   │   │   │   │   └── io
│   │   │   │   │       └── flutter
│   │   │   │   │           └── plugins
│   │   │   │   │               └── GeneratedPluginRegistrant.java
│   │   │   │   ├── kotlin
│   │   │   │   │   └── com
│   │   │   │   │       └── example
│   │   │   │   │           └── app_ricette
│   │   │   │   │               └── MainActivity.kt
│   │   │   │   ├── res
│   │   │   │   │   ├── drawable
│   │   │   │   │   │   └── launch_background.xml
│   │   │   │   │   ├── drawable-v21
│   │   │   │   │   │   └── launch_background.xml
│   │   │   │   │   ├── mipmap-hdpi
│   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   ├── mipmap-mdpi
│   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   ├── mipmap-xhdpi
│   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   ├── mipmap-xxhdpi
│   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   ├── mipmap-xxxhdpi
│   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   ├── values
│   │   │   │   │   │   └── styles.xml
│   │   │   │   │   └── values-night
│   │   │   │   │       └── styles.xml
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── profile
│   │   │       └── AndroidManifest.xml
│   │   └── build.gradle.kts
│   ├── gradle
│   │   └── wrapper
│   │       ├── gradle-wrapper.jar
│   │       └── gradle-wrapper.properties
│   ├── app_ricette_android.iml
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── local.properties
│   └── settings.gradle.kts
├── ios
│   ├── Flutter
│   │   ├── ephemeral
│   │   │   ├── flutter_lldb_helper.py
│   │   │   └── flutter_lldbinit
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   ├── flutter_export_environment.sh
│   │   ├── Generated.xcconfig
│   │   └── Release.xcconfig
│   ├── Runner
│   │   ├── Assets.xcassets
│   │   │   ├── AppIcon.appiconset
│   │   │   │   ├── Contents.json
│   │   │   │   ├── Icon-App-1024x1024@1x.png
│   │   │   │   ├── Icon-App-20x20@1x.png
│   │   │   │   ├── Icon-App-20x20@2x.png
│   │   │   │   ├── Icon-App-20x20@3x.png
│   │   │   │   ├── Icon-App-29x29@1x.png
│   │   │   │   ├── Icon-App-29x29@2x.png
│   │   │   │   ├── Icon-App-29x29@3x.png
│   │   │   │   ├── Icon-App-40x40@1x.png
│   │   │   │   ├── Icon-App-40x40@2x.png
│   │   │   │   ├── Icon-App-40x40@3x.png
│   │   │   │   ├── Icon-App-60x60@2x.png
│   │   │   │   ├── Icon-App-60x60@3x.png
│   │   │   │   ├── Icon-App-76x76@1x.png
│   │   │   │   ├── Icon-App-76x76@2x.png
│   │   │   │   └── Icon-App-83.5x83.5@2x.png
│   │   │   └── LaunchImage.imageset
│   │   │       ├── Contents.json
│   │   │       ├── LaunchImage@2x.png
│   │   │       ├── LaunchImage@3x.png
│   │   │       ├── LaunchImage.png
│   │   │       └── README.md
│   │   ├── Base.lproj
│   │   │   ├── LaunchScreen.storyboard
│   │   │   └── Main.storyboard
│   │   ├── AppDelegate.swift
│   │   ├── GeneratedPluginRegistrant.h
│   │   ├── GeneratedPluginRegistrant.m
│   │   ├── Info.plist
│   │   └── Runner-Bridging-Header.h
│   ├── RunnerTests
│   │   └── RunnerTests.swift
│   ├── Runner.xcodeproj
│   │   ├── project.xcworkspace
│   │   │   ├── xcshareddata
│   │   │   │   ├── IDEWorkspaceChecks.plist
│   │   │   │   └── WorkspaceSettings.xcsettings
│   │   │   └── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── xcschemes
│   │   │       └── Runner.xcscheme
│   │   └── project.pbxproj
│   └── Runner.xcworkspace
│       ├── xcshareddata
│       │   ├── IDEWorkspaceChecks.plist
│       │   └── WorkspaceSettings.xcsettings
│       └── contents.xcworkspacedata
├── lib
│   ├── models
│   │   ├── comment.dart
│   │   └── recipe.dart
│   ├── navigation
│   │   └── app_router.dart
│   ├── providers
│   ├── screens
│   │   ├── auth
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── register_screen.dart.backup
│   │   ├── home
│   │   │   ├── viewmodels
│   │   │   ├── widgets
│   │   │   │   ├── categories_bar.dart
│   │   │   │   ├── empty_state.dart
│   │   │   │   ├── recipe_list.dart
│   │   │   │   ├── recipe_search_bar.dart
│   │   │   │   └── welcome_header.dart
│   │   │   └── home_screen.dart
│   │   ├── profile
│   │   │   ├── widgets
│   │   │   │   ├── avatar_picker.dart
│   │   │   │   ├── profile_header.dart
│   │   │   │   └── profile_tabs.dart
│   │   │   ├── profile_recipes_list.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── profile_stats_widget.dart
│   │   └── recipe
│   │       ├── create_recipe
│   │       │   ├── create_basic_info.dart
│   │       │   ├── create_header.dart
│   │       │   ├── create_image_section.dart
│   │       │   ├── create_ingredients.dart
│   │       │   ├── create_instructions.dart
│   │       │   └── create_tags.dart
│   │       ├── detail_recipe
│   │       │   ├── utils
│   │       │   │   └── detail_helpers.dart
│   │       │   ├── widgets
│   │       │   │   ├── utils
│   │       │   │   │   └── comment_state_manager.dart
│   │       │   │   ├── comment_input_widget.dart
│   │       │   │   ├── comment_item_widget.dart
│   │       │   │   ├── comments_list_widget.dart
│   │       │   │   ├── detail_comments_section.dart
│   │       │   │   ├── detail_header_section.dart
│   │       │   │   ├── detail_image_section.dart
│   │       │   │   ├── detail_info_section.dart
│   │       │   │   ├── detail_ingredients_section.dart
│   │       │   │   ├── detail_instructions_section.dart
│   │       │   │   └── detail_tags_section.dart
│   │       │   └── constants.dart
│   │       ├── edit_recipe
│   │       │   ├── edit_basic_info.dart
│   │       │   ├── edit_header.dart
│   │       │   ├── edit_image_section.dart
│   │       │   ├── edit_ingredients.dart
│   │       │   ├── edit_instructions.dart
│   │       │   └── edit_tags.dart
│   │       ├── widgets
│   │       │   ├── favorite_button.dart
│   │       │   └── like_button.dart
		    action_menu_button.dart <-- aggiunto
│   │       ├── create_recipe_screen.dart
│   │       ├── detail_recipe_screen.dart
│   │       └── edit_recipe_screen.dart
│   ├── services
│   │   ├── auth_service.dart
│   │   ├── avatar_service.dart
│   │   ├── comment_service.dart
│   │   ├── favorite_service.dart
│   │   ├── like_service.dart
│   │   ├── profile_controller.dart
│   │   ├── profile_service.dart
│   │   └── recipe_service.dart
│   ├── utils
│   │   ├── logger.dart
│   │   ├── recipe_helpers.dart
│   │   └── service_coordinator.dart
	    app_theme.dart <-- aggiunto;
│   ├── widgets
│   │   ├── loading_indicator.dart
│   │   └── recipe_card.dart
│   ├── config.dart
│   └── main.dart
├── linux
│   ├── flutter
│   │   ├── ephemeral
│   │   │   ├── flutter_linux
│   │   │   │   ├── fl_application.h
│   │   │   │   ├── fl_basic_message_channel.h
│   │   │   │   ├── fl_binary_codec.h
│   │   │   │   ├── fl_binary_messenger.h
│   │   │   │   ├── fl_dart_project.h
│   │   │   │   ├── fl_engine.h
│   │   │   │   ├── fl_event_channel.h
│   │   │   │   ├── fl_json_message_codec.h
│   │   │   │   ├── fl_json_method_codec.h
│   │   │   │   ├── fl_message_codec.h
│   │   │   │   ├── fl_method_call.h
│   │   │   │   ├── fl_method_channel.h
│   │   │   │   ├── fl_method_codec.h
│   │   │   │   ├── fl_method_response.h
│   │   │   │   ├── fl_pixel_buffer_texture.h
│   │   │   │   ├── fl_plugin_registrar.h
│   │   │   │   ├── fl_plugin_registry.h
│   │   │   │   ├── fl_standard_message_codec.h
│   │   │   │   ├── fl_standard_method_codec.h
│   │   │   │   ├── fl_string_codec.h
│   │   │   │   ├── fl_texture_gl.h
│   │   │   │   ├── fl_texture.h
│   │   │   │   ├── fl_texture_registrar.h
│   │   │   │   ├── flutter_linux.h
│   │   │   │   ├── fl_value.h
│   │   │   │   └── fl_view.h
│   │   │   ├── generated_config.cmake
│   │   │   ├── icudtl.dat
│   │   │   └── libflutter_linux_gtk.so
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   ├── runner
│   │   ├── CMakeLists.txt
│   │   ├── main.cc
│   │   ├── my_application.cc
│   │   └── my_application.h
│   └── CMakeLists.txt
├── macos
│   ├── Flutter
│   │   ├── ephemeral
│   │   │   ├── flutter_export_environment.sh
│   │   │   └── Flutter-Generated.xcconfig
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   └── GeneratedPluginRegistrant.swift
│   ├── Runner
│   │   ├── Assets.xcassets
│   │   │   └── AppIcon.appiconset
│   │   │       ├── app_icon_1024.png
│   │   │       ├── app_icon_128.png
│   │   │       ├── app_icon_16.png
│   │   │       ├── app_icon_256.png
│   │   │       ├── app_icon_32.png
│   │   │       ├── app_icon_512.png
│   │   │       ├── app_icon_64.png
│   │   │       └── Contents.json
│   │   ├── Base.lproj
│   │   │   └── MainMenu.xib
│   │   ├── Configs
│   │   │   ├── AppInfo.xcconfig
│   │   │   ├── Debug.xcconfig
│   │   │   ├── Release.xcconfig
│   │   │   └── Warnings.xcconfig
│   │   ├── AppDelegate.swift
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   └── Release.entitlements
│   ├── RunnerTests
│   │   └── RunnerTests.swift
│   ├── Runner.xcodeproj
│   │   ├── project.xcworkspace
│   │   │   └── xcshareddata
│   │   │       └── IDEWorkspaceChecks.plist
│   │   ├── xcshareddata
│   │   │   └── xcschemes
│   │   │       └── Runner.xcscheme
│   │   └── project.pbxproj
│   └── Runner.xcworkspace
│       ├── xcshareddata
│       │   └── IDEWorkspaceChecks.plist
│       └── contents.xcworkspacedata
├── test
├── web
│   ├── icons
│   │   ├── Icon-192.png
│   │   ├── Icon-512.png
│   │   ├── Icon-maskable-192.png
│   │   └── Icon-maskable-512.png
│   ├── favicon.png
│   ├── index.html
│   └── manifest.json
├── windows
│   ├── flutter
│   │   ├── ephemeral
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   ├── runner
│   │   ├── resources
│   │   │   └── app_icon.ico
│   │   ├── CMakeLists.txt
│   │   ├── flutter_window.cpp
│   │   ├── flutter_window.h
│   │   ├── main.cpp
│   │   ├── resource.h
│   │   ├── runner.exe.manifest
│   │   ├── Runner.rc
│   │   ├── utils.cpp
│   │   ├── utils.h
│   │   ├── win32_window.cpp
│   │   └── win32_window.h
│   └── CMakeLists.txt
├── analysis_options.yaml
├── app_ricette_frontend.iml
├── app_ricette.iml
├── pubspec.lock
├── pubspec.yaml
└── README.md

93 directories, 228 files
```

## 📊 STATISTICHE
- File backend totali: 6268
- File frontend totali: 339
- File frontend Dart: 64
- Data generazione: jeu. 15 janv. 2026 20:59:44 CET
