import 'package:flutter/material.dart';

import 'package:kawangizi_mobile/features/auth/data/auth_repository.dart';
import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _bootstrap();
  }

  final AuthRepository _authRepository;

  BackendUser? _user;
  List<String> _permissions = [];
  bool _loading = true;

  BackendUser? get user => _user;
  List<String> get permissions => _permissions;
  bool get loading => _loading;
  bool get isGuest => _user?.isGuest == true;
  bool get isAuthenticated => _user != null;

  Future<void> _bootstrap() async {
    _loading = true;
    notifyListeners();
    try {
      final payload = await _authRepository.bootstrap();
      if (payload != null) {
        _user = payload.user;
        _permissions = payload.permissions;
      }
    } catch (_) {
      _user = null;
      _permissions = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final payload = await _authRepository.login(email.trim(), password);
    _user = payload.user;
    _permissions = payload.permissions;
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    final payload = await _authRepository.loginAsGuest();
    _user = payload.user;
    _permissions = payload.permissions;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _permissions = [];
    notifyListeners();
  }

  bool hasPermission(String permission) => _permissions.contains(permission);
}
