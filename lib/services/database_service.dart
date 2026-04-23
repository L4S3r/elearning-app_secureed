import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _usersKey = 'elearning_users';
  final Random _random = Random.secure();

  String _generateSalt() {
    final saltBytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _saltAndHash(String password) {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    return '$salt:$hash';
  }
  bool _verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final storedHash = parts[1];
    return _hashPassword(password, salt) == storedHash;
  }

  Future<Map<String, String>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<String?> registerUser(String email, String password) async {
    try {
      final users = await _loadUsers();
      final key = email.toLowerCase().trim();

      if (users.containsKey(key)) {
        return 'An account with this email already exists.';
      }

      users[key] = _saltAndHash(password);
      await _saveUsers(users);
      return null;
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  Future<String?> loginUser(String emailOrUsername, String password) async {
    try {
      final users = await _loadUsers();
      final key = emailOrUsername.toLowerCase().trim();

      if (!users.containsKey(key)) {
        return 'Invalid password or email, try again';
      }

      if (!_verifyPassword(password, users[key]!)) {
        return 'Invalid password or email, try again';
      }

      return null;
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<String?> resetPassword(String email, String newPassword) async {
    try {
      final users = await _loadUsers();
      final key = email.toLowerCase().trim();

      if (!users.containsKey(key)) {
        return 'No account found with this email.';
      }

      users[key] = _saltAndHash(newPassword);
      await _saveUsers(users);
      return null;
    } catch (e) {
      return 'Password reset failed: $e';
    }
  }
}
