import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _isInitialized = false;
  static String? _configurationHint;

  static bool get isInitialized => _isInitialized;
  static String? get configurationHint => _configurationHint;

  /// Menginisialisasi Firebase dengan aman.
  /// Jika rekan tim baru melakukan `git clone` dan belum menjalankan
  /// `flutterfire configure`, aplikasi tetap bisa terbuka dalam mode pratinjau UI.
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      _configurationHint = null;
    } catch (error) {
      _isInitialized = false;
      _configurationHint =
          'Firebase belum dikonfigurasi pada perangkat ini. '
          'Jalankan `flutterfire configure` atau tambahkan `google-services.json`.';
      debugPrint('FirebaseBootstrap info: $error');
    }
  }
}
