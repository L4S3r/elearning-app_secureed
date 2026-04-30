import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as crypto_enc;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _usersKey = 'secureed_encrypted_users';

  // Exactly 32 chars for AES-256
  final _encryptionKey = crypto_enc.Key.fromUtf8('my_ultra_secure_key_for_secureed');

  final Random _random = Random.secure();

  // --- RATE LIMITING ---
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get _isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  void _recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      // Exponential backoff: 1min, 2min, 4min, 8min ...
      final minutes = pow(2, _failedAttempts - 5).toInt().clamp(1, 60);
      _lockoutUntil = DateTime.now().add(Duration(minutes: minutes));
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  // --- PUBLIC ADMIN ACCESS ---
  // Returns the full user map (email -> salt:hash) for the admin panel display.
  Future<Map<String, String>> getDecryptedUsersForAdmin() async {
    return await _loadUsers();
  }

  // --- DEDICATED EXISTENCE CHECK (avoids exposing full map to callers) ---
  Future<bool> userExists(String email) async {
    final users = await _loadUsers();
    return users.containsKey(email.toLowerCase().trim());
  }

  // --- PASSWORD HASHING LOGIC ---
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
    return '$salt:$hash'; // Format: salt:hash
  }

  bool _verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final storedHash = parts[1];
    return _hashPassword(password, salt) == storedHash;
  }

  // --- ENCRYPTED STORAGE ---
  // Storage format: base64(iv) + ':' + base64(ciphertext)
  // A fresh 96-bit IV is generated on every save, fixing the fixed-IV vulnerability.
  Future<Map<String, String>> _loadUsers() async {
    try {
      final stored = await _storage.read(key: _usersKey);
      if (stored == null) return {};

      // Split stored value into IV and ciphertext
      final parts = stored.split(':');
      if (parts.length != 2) return {};

      final iv = crypto_enc.IV.fromBase64(parts[0]);
      final encrypter = crypto_enc.Encrypter(
          crypto_enc.AES(_encryptionKey, mode: crypto_enc.AESMode.gcm));

      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      // Do not print sensitive error details in production
      return {};
    }
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final rawJson = jsonEncode(users);

    // Generate a fresh random 96-bit IV for every save
    final iv = crypto_enc.IV.fromSecureRandom(12);
    final encrypter = crypto_enc.Encrypter(
        crypto_enc.AES(_encryptionKey, mode: crypto_enc.AESMode.gcm));

    final encrypted = encrypter.encrypt(rawJson, iv: iv);

    // Persist as: base64(iv):base64(ciphertext)
    await _storage.write(
        key: _usersKey, value: '${iv.base64}:${encrypted.base64}');
  }

  // --- AUTH METHODS ---
  Future<String?> registerUser(String email, String password) async {
    try {
      final users = await _loadUsers();
      final key = email.toLowerCase().trim();
      if (users.containsKey(key)) return 'User already exists.';
      users[key] = _saltAndHash(password);
      await _saveUsers(users);
      return null;
    } catch (e) {
      return 'Registration failed. Please try again.';
    }
  }

  Future<String?> loginUser(String email, String password) async {
    // Check lockout before doing any work
    if (_isLockedOut) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      return 'Too many failed attempts. Try again in $remaining minute(s).';
    }

    try {
      final users = await _loadUsers();
      final key = email.toLowerCase().trim();

      if (!users.containsKey(key) || !_verifyPassword(password, users[key]!)) {
        _recordFailedAttempt();
        return 'Invalid credentials.';
      }

      _resetFailedAttempts();
      return null;
    } catch (e) {
      return 'Login failed. Please try again.';
    }
  }

  Future<String?> resetPassword(String email, String newPassword) async {
    try {
      // 1. Decrypt current user list from hardware storage
      final users = await _loadUsers();
      final key = email.toLowerCase().trim();

      if (!users.containsKey(key)) {
        return 'No account found with this email.';
      }

      // 2. Generate new salt and hash the new password
      users[key] = _saltAndHash(newPassword);

      // 3. Re-encrypt the entire map with a fresh IV and save
      await _saveUsers(users);
      return null;
    } catch (e) {
      return 'Password reset failed. Please try again.';
    }
  }
}