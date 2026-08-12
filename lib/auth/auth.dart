// lib/auth/auth.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  const AuthState(this.status, [this.token]);
}

class AuthNotifier extends StateNotifier<AuthState> {
  static final _storage = FlutterSecureStorage();
  late final Box _userBox;

  AuthNotifier() : super(const AuthState(AuthStatus.unknown)) {
    _init();
  }

  Future<void> _init() async {
    // Load auth token from secure storage
    final saved = await _storage.read(key: 'auth_token');
    if (saved != null && saved.isNotEmpty) {
      state = AuthState(AuthStatus.authenticated, saved);
    } else {
      state = const AuthState(AuthStatus.unauthenticated);
    }
    // Open Hive box for users
    _userBox = await Hive.openBox('users');
  }

  // Register a new user. Throws if username already exists.
  Future<void> register(String username, String password, String mobile) async {
    if (_userBox.containsKey(username)) {
      throw Exception('Username already exists');
    }
    await _userBox.put(username, {
      'password': password,
      'mobile': mobile,
    });
    // Simulate token generation
    final token = 'demo-token-${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: 'auth_token', value: token);
    state = AuthState(AuthStatus.authenticated, token);
  }

  // Login by checking credentials against Hive storage.
  Future<void> login(String username, String password) async {
    if (!_userBox.containsKey(username)) {
      throw Exception('Invalid username or password');
    }
    final user = _userBox.get(username) as Map;
    if (user['password'] != password) {
      throw Exception('Invalid username or password');
    }
    final token = 'demo-token-${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: 'auth_token', value: token);
    state = AuthState(AuthStatus.authenticated, token);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
