import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // ───── CONFIGURACIÓN ────────────────────────────────────────────────────

  /// Cambia a `true` para usar el backend de Render (producción)
  /// Cambia a `false` para desarrollar contra tu backend local
  static const bool useProduction = true; // <── AQUÍ CONTROLAS EL ENTORNO

  /// URL de producción en Render
  static const String _productionUrl = 'https://zombies-app.onrender.com/api';

  /// IP local para desarrollo
  static const String _localIp = '192.168.1.75';
  static const int _port = 8080;

  // ────────────────────────────────────────────────────────────────────────

  static String get baseUrl {
    // Si está activado producción, siempre usa Render
    if (useProduction) {
      return _productionUrl;
    }

    // ── Desarrollo local ──
    if (kIsWeb) {
      return 'http://localhost:$_port/api';
    }
    if (Platform.isIOS) {
      return 'http://localhost:$_port/api';
    }
    if (Platform.isAndroid) {
      if (_localIp == '192.168.1.X' || _localIp.toLowerCase().contains('x')) {
        return 'http://10.0.2.2:$_port/api';
      }
      return 'http://$_localIp:$_port/api';
    }

    return 'http://localhost:$_port/api';
  }
}