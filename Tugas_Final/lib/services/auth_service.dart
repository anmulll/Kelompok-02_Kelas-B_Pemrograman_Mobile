import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) {
    _firebaseAuth = firebaseAuth;
    _firestore = firestore;
  }

  late final FirebaseAuth? _firebaseAuth;
  late final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    return fetchUserProfile(user.uid);
  }

  /// Registrasi mahasiswa baru (FR-001 & BR-002: role selalu `student`).
  Future<UserModel> registerStudent({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());

    final now = DateTime.now();
    final docRef = _db.collection(AppConstants.usersCollection).doc(user.uid);
    await docRef.set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone?.trim(),
      'role': UserRole.student.value,
      'photoUrl': null,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return UserModel(
      uid: user.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone?.trim(),
      role: UserRole.student,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<UserModel?> fetchUserProfile(String uid) async {
    final snapshot = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    final data = snapshot.data();
    if (data == null) return null;
    return UserModel.fromMap(data, docId: snapshot.id);
  }

  Future<void> signOut() => _auth.signOut();
}
