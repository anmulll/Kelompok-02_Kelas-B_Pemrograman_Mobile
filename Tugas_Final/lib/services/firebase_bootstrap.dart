import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static const bool _useEmulatorFlag = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );
  static const String _emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static bool _isInitialized = false;
  static bool _isUsingEmulator = false;
  static String? _configurationHint;

  static bool get isInitialized => _isInitialized;
  static bool get isUsingEmulator => _isUsingEmulator;
  static String? get configurationHint => _configurationHint;

  /// Menginisialisasi Firebase dengan aman.
  /// - Jika dijalankan dengan `--dart-define=USE_FIREBASE_EMULATOR=true`,
  ///   aplikasi terhubung ke Firebase Emulator Suite lokal (`demo-courtmate`)
  ///   sehingga dapat menguji Cloud Functions + DOKU Sandbox nyata tanpa Blaze Plan.
  /// - Jika tanpa emulator dan `flutterfire configure` belum dijalankan,
  ///   aplikasi tetap terbuka dalam mode pratinjau UI lokal.
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    if (_useEmulatorFlag) {
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyDemoCourtMateLocalEmulator0000000',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-courtmate',
          ),
        );
        await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
        FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, 5001);

        _isInitialized = true;
        _isUsingEmulator = true;
        _configurationHint = null;
        debugPrint(
          'FirebaseBootstrap: Terhubung ke Firebase Emulator ($_emulatorHost)',
        );
        return;
      } catch (error) {
        debugPrint('FirebaseBootstrap emulator error: $error');
      }
    }

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      _isUsingEmulator = false;
      _configurationHint = null;
    } catch (error) {
      _isInitialized = false;
      _isUsingEmulator = false;
      _configurationHint =
          'Firebase belum dikonfigurasi pada perangkat ini. '
          'Jalankan `flutterfire configure` atau aktifkan mode Emulator (`--dart-define=USE_FIREBASE_EMULATOR=true`).';
      debugPrint('FirebaseBootstrap info: $error');
    }
  }
}
