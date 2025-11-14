import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Tạo singleton instance
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _sessionKey = 'session_active';

  Future<void> saveToken(String token) async {
    print('💾 Saving token: ${token.substring(0, 20)}...');
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    print('🔍 Retrieved token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    return token;
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    print('💾 Refresh token saved');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> setSessionActive() async {
    print('💾 Setting session as active');
    await _storage.write(key: _sessionKey, value: 'true');
  }

  Future<bool> isSessionActive() async {
    final session = await _storage.read(key: _sessionKey);
    return session == 'true';
  }

  Future<void> saveUserData(String userData) async {
    print('💾 Saving user data');
    await _storage.write(key: _userDataKey, value: userData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  Future<void> clearAll() async {
    print('🗑️ Clearing all storage data');
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _sessionKey);
  }

  // Debug method to check all stored data
  Future<void> debugStorage() async {
    final token = await getToken();
    final userData = await getUserData();
    final sessionActive = await isSessionActive();
    print('🔍 DEBUG STORAGE:');
    print('   Token: ${token != null ? "PRESENT (${token.substring(0, 20)}...)" : "NULL"}');
    print('   UserData: ${userData != null ? "PRESENT" : "NULL"}');
    print('   Session Active: $sessionActive');
  }
}