import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Servicio centralizado para gestionar la autenticación y usuario actual
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentUsername;

  /// Obtiene el nombre de usuario actual desde SharedPreferences
  Future<String?> getCurrentUsername() async {
    if (_currentUsername != null) {
      return _currentUsername;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('username');
      AppLogger.info('Current username: $_currentUsername');
      return _currentUsername;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current username: $e', e, stackTrace);
      return null;
    }
  }

  /// Obtiene el username actual o lanza excepción si no hay usuario logueado
  /// Útil para evitar null checks en cada llamada
  Future<String> requireUsername() async {
    final username = await getCurrentUsername();
    if (username == null || username.isEmpty) {
      AppLogger.error('Attempted to access data without logged in user');
      throw Exception('Usuario no autenticado. Por favor inicie sesión.');
    }
    return username;
  }

  /// Establece el nombre de usuario actual
  Future<void> setCurrentUsername(String username) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      _currentUsername = username;
      AppLogger.info('Username set to: $username');
    } catch (e, stackTrace) {
      AppLogger.error('Error setting username: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Limpia la sesión del usuario
  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      _currentUsername = null;
      AppLogger.info('User logged out');
    } catch (e, stackTrace) {
      AppLogger.error('Error logging out: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Verifica si hay un usuario logueado
  Future<bool> isLoggedIn() async {
    final username = await getCurrentUsername();
    return username != null && username.isNotEmpty;
  }
}
","structuredPatch":[]}}
{"parentUuid":"e2219e13-3b67-4d63-a2dd-eec82e967ecb","isSidechain":false,"userType":"external","cwd":"/home/mpeirano","sessionId":"ce016d53-11d3-4207-a452-db14f53687bc","version":"2.0.14","gitBranch":"","message":{"model":"claude-sonnet-4-5-20250929","id":"msg_01Cm1nVBboJMbQ37NvDqsiJ9