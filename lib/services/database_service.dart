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
  // Exactly 16 chars for IV
  final _fixedIv = crypto_enc.IV.fromUtf8('secureed_fixediv'); 

  final Random _random = Random.secure();

  // --- PUBLIC ADMIN ACCESS ---
  Future<Map<String, String>> getDecryptedUsersForAdmin() async {
    return await _loadUsers();
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
    return '$salt:$hash'; // Format is salt:hash
  }

  bool _verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final storedHash = parts[1];
    return _hashPassword(password, salt) == storedHash;
  }

  // --- ENCRYPTED STORAGE ---
  Future<Map<String, String>> _loadUsers() async {
    try {
      final encryptedBase64 = await _storage.read(key: _usersKey);
      if (encryptedBase64 == null) return {};

      final encrypter = crypto_enc.Encrypter(crypto_enc.AES(_encryptionKey, mode: crypto_enc.AESMode.gcm));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _fixedIv);
      
      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      print('Decryption Error: $e');
      return {};
    }
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final rawJson = jsonEncode(users);
    final encrypter = crypto_enc.Encrypter(crypto_enc.AES(_encryptionKey, mode: crypto_enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(rawJson, iv: _fixedIv);
    await _storage.write(key: _usersKey, value: encrypted.base64);
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
    } catch (e) { return 'Error: $e'; }
  }

  Future<String?> loginUser(String email, String password) async {
    try {
      final users = await _loadUsers();
      final key = email.toLowerCase().trim();
      if (!users.containsKey(key) || !_verifyPassword(password, users[key]!)) {
        return 'Invalid credentials.';
      }
      return null;
    } catch (e) { return 'Error: $e'; }
  }

  // FIXED: Now correctly inside the class braces
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

      // 3. Re-encrypt the entire map with AES-GCM and save
      await _saveUsers(users);
      return null;
    } catch (e) {
      return 'Password reset failed: $e';
    }
  }
} // The ONLY closing brace for the class