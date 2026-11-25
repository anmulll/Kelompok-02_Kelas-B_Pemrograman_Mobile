import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../services/firebase_bootstrap.dart';
import '../services/functions_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({FunctionsService? functionsService})
    : _functionsService = functionsService ?? FunctionsService();

  final FunctionsService _functionsService;
  final Uuid _uuid = const Uuid();

  final List<BookingModel> _bookings = [];
  bool _isSubmitting = false;
  String? _activeCheckoutUrl;
  String? _errorMessage;

  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  bool get isSubmitting => _isSubmitting;
  String? get activeCheckoutUrl => _activeCheckoutUrl;
  String? get errorMessage => _errorMessage;

  /// Alur aman (CM-ARCH-DB-001 Bab 6):
  /// 1. `createBooking` -> hold slot atomik + `pending_payment`
  /// 2. `createDokuPayment` -> terima `checkoutUrl` DOKU Sandbox
  Future<String?> createHoldAndCheckout({
    required String courtId,
    required String slotId,
  }) async {
    if (!FirebaseBootstrap.isInitialized) {
      _errorMessage = FirebaseBootstrap.configurationHint;
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idempotencyKey = _uuid.v4();
      final bookingResult = await _functionsService.createBooking(
        courtId: courtId,
        slotId: slotId,
        idempotencyKey: idempotencyKey,
      );

      final bookingId = bookingResult['bookingId'] as String?;
      if (bookingId == null || bookingId.isEmpty) {
        throw StateError('bookingId tidak ditemukan dari respons server.');
      }

      final paymentResult = await _functionsService.createDokuPayment(
        bookingId: bookingId,
      );

      _activeCheckoutUrl = paymentResult['checkoutUrl'] as String?;
      return _activeCheckoutUrl;
    } catch (error) {
      _errorMessage =
          'Slot tidak dapat dipesan saat ini. Silakan pilih slot lain atau coba lagi.';
      debugPrint('BookingProvider.createHoldAndCheckout error: $error');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Membuka URL DOKU Checkout (FR-013).
  /// Penting (BR-007 & BR-008): kembalinya pengguna dari browser BUKAN bukti lunas;
  /// status `confirmed` hanya diperbarui oleh webhook backend.
  Future<bool> launchCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
