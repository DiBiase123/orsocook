// lib/config.dart - VERSIONE CORRETTA CON PARAMETRO OPZIONALE

class Config {
  // 🔧 SELEZIONA QUI LA MODALITÀ:
  static const String environment = 'local';

  static const Map<String, String> apiUrls = {
    'dev': 'http://10.0.2.2:5000',
    'local': 'http://localhost:5000',
    'prod': 'https://tuodominio.com',
  };

  static String get apiBaseUrl {
    final url = apiUrls[environment];
    if (url == null) {
      throw Exception('Ambiente "$environment" non configurato');
    }
    return url;
  }

  // 🛠️ **METODO buildUrl con parametro OPZIONALE**
  static String buildUrl([String endpoint = '']) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    if (endpoint.isEmpty) {
      return base; // Restituisce solo la base URL
    }

    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base/$path';
  }

  // 🛠️ **METODO buildApiUrl per API** (facoltativo, per chiarezza)
  static String buildApiUrl(String endpoint) {
    return buildUrl('/api/$endpoint');
  }
}
