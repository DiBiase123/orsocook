import 'package:flutter/foundation.dart';

/// 🎯 Logger professionale per l'app Ricette
/// 📍 Si disabilita automaticamente in modalità release
class AppLogger {
  // 📱 LOG GENERICO (solo debug)
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('📱 [APP] $message');
    }
  }

  // 🧭 LOG NAVIGAZIONE
  static void navigation(String message) {
    if (kDebugMode) {
      debugPrint('🧭 [NAV] $message');
    }
  }

  // 🔐 LOG AUTENTICAZIONE
  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('🔐 [AUTH] $message');
    }
  }

  // 🍳 LOG RICETTE
  static void recipe(String message) {
    if (kDebugMode) {
      debugPrint('🍳 [RECIPE] $message');
    }
  }

  // 📡 LOG API/RETE
  static void api(String message) {
    if (kDebugMode) {
      debugPrint('📡 [API] $message');
    }
  }

  // ⚠️ LOG ERRORI (sempre visibili in debug, semplificati in release)
  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message${error != null ? ": $error" : ""}');
    } else {
      // In produzione: messaggio semplice senza dettagli sensibili
      debugPrint('❌ [ERROR] ${message.split(":").first}');
    }
  }

  // 🔧 LOG DEBUG (solo per sviluppo)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔧 [DEBUG] $message');
    }
  }

  // ✅ LOG SUCCESSO
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [SUCCESS] $message');
    }
  }

  // ✅ METODO PER IMMAGINI
  static void image(String message) {
    if (kDebugMode) {
      debugPrint('🖼️ [IMAGE] $message');
    }
  }

  // ✅ METODO PER WARNING
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARNING] $message');
    }
  }
}
