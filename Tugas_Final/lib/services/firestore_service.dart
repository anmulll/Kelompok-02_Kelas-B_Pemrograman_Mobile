import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart';
import '../models/slot_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) {
    _firestore = firestore;
  }

  late final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<CourtModel>> watchVerifiedCourts({String? sportType}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.courtsCollection)
        .where('isActive', isEqualTo: true)
        .where(
          'verificationStatus',
          isEqualTo: CourtVerificationStatus.verified.value,
        );

    if (sportType != null && sportType.isNotEmpty) {
      query = query.where('sportTypes', arrayContains: sportType);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => CourtModel.fromMap(doc.data(), id: doc.id))
          .toList(),
    );
  }

  Stream<List<SlotModel>> watchCourtSlotsForDate({
    required String courtId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(AppConstants.slotsCollection)
        .where('courtId', isEqualTo: courtId)
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SlotModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<BookingModel>> watchUserBookings(String userId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }
}
