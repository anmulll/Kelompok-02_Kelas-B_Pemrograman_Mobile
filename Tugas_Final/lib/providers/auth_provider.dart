import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_bootstrap.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({required String email, required String password}) async {
    if (!FirebaseBootstrap.isInitialized) {
      _errorMessage = FirebaseBootstrap.configurationHint;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _errorMessage = null;
      return _currentUser != null;
    } catch (error) {
      _errorMessage = 'Gagal masuk. Periksa kembali email dan kata sandi Anda.';
      debugPrint('AuthProvider.signIn error: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerStudent({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (!FirebaseBootstrap.isInitialized) {
      _errorMessage = FirebaseBootstrap.configurationHint;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _currentUser = await _authService.registerStudent(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = 'Registrasi gagal diproses. Silakan coba lagi.';
      debugPrint('AuthProvider.registerStudent error: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? nimInstitution,
  }) async {
    final user = _currentUser;

    if (user == null) {
      _errorMessage = 'Pengguna belum login.';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      _currentUser = await _authService.updateUserProfile(
        uid: user.uid,
        name: name,
        phone: phone,
        nimInstitution: nimInstitution,
      );

      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = 'Gagal memperbarui profil. Silakan coba lagi.';
      debugPrint('AuthProvider.updateProfile error: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (FirebaseBootstrap.isInitialized) {
      await _authService.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
