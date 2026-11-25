import 'package:cloud_functions/cloud_functions.dart';
import '../core/constants/app_constants.dart';

/// Wrapper komunikasi ke Firebase Cloud Functions (trusted backend boundary).
/// Seluruh kalkulasi harga, slot hold atomik, dan DOKU Checkout diproses server.
class FunctionsService {
  FunctionsService({FirebaseFunctions? functions}) {
    _functions = functions;
  }

  late final FirebaseFunctions? _functions;
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createBooking({
    required String courtId,
    required String slotId,
    required String idempotencyKey,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnCreateBooking);
    final result = await callable.call<Map<dynamic, dynamic>>({
      'courtId': courtId,
      'slotId': slotId,
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> createDokuPayment({
    required String bookingId,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnCreateDokuPayment);
    final result = await callable.call<Map<dynamic, dynamic>>({
      'bookingId': bookingId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnCancelBooking);
    final result = await callable.call<Map<dynamic, dynamic>>({
      'bookingId': bookingId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> manageCourt(Map<String, dynamic> payload) async {
    final callable = _fn.httpsCallable(AppConstants.fnManageCourt);
    final result = await callable.call<Map<dynamic, dynamic>>(payload);
    return Map<String, dynamic>.from(result.data);
  }
}
