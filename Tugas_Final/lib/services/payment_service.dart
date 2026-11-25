import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../models/payment_model.dart';

class DokuPaymentSession {
  const DokuPaymentSession({
    required this.paymentId,
    required this.providerOrderId,
    required this.paymentUrl,
    this.expiresAt,
  });

  final String paymentId;
  final String providerOrderId;
  final String paymentUrl;
  final DateTime? expiresAt;

  factory DokuPaymentSession.fromMap(Map<String, dynamic> map) {
    final url =
        (map['paymentUrl'] as String?) ?? (map['checkoutUrl'] as String?) ?? '';
    final expiresRaw = map['expiresAt'] as String?;
    return DokuPaymentSession(
      paymentId: (map['paymentId'] as String?) ?? '',
      providerOrderId: (map['providerOrderId'] as String?) ?? '',
      paymentUrl: url,
      expiresAt: expiresRaw != null ? DateTime.tryParse(expiresRaw) : null,
    );
  }
}

typedef UrlLauncherFn = Future<bool> Function(Uri uri);

/// Modul Anmul Bab 5 (`lib/services/payment_service.dart`):
/// Bertanggung jawab memanggil `createDokuPayment`, memantau dokumen `payments`,
/// dan membuka `paymentUrl` DOKU Checkout Sandbox melalui HTTPS tanpa menyentuh Secret Key.
class PaymentService {
  PaymentService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    UrlLauncherFn? urlLauncher,
  }) {
    _firestore = firestore;
    _functions = functions;
    _urlLauncher = urlLauncher;
  }

  late final FirebaseFirestore? _firestore;
  late final FirebaseFunctions? _functions;
  late final UrlLauncherFn? _urlLauncher;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  Future<DokuPaymentSession> createDokuPayment({
    required String bookingId,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnCreateDokuPayment);
    final response = await callable.call<Map<dynamic, dynamic>>({
      'bookingId': bookingId,
    });
    return DokuPaymentSession.fromMap(Map<String, dynamic>.from(response.data));
  }

  /// Mengecek status pembayaran aktual ke DOKU melalui Cloud Function `reconcilePayment`.
  Future<Map<String, dynamic>> reconcilePayment({
    required String bookingId,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnReconcilePayment);
    final response = await callable.call<Map<dynamic, dynamic>>({
      'bookingId': bookingId,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Stream<PaymentModel?> watchPaymentById(String paymentId) {
    return _db
        .collection(AppConstants.paymentsCollection)
        .doc(paymentId)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          if (data == null) return null;
          return PaymentModel.fromMap(data, id: snap.id);
        });
  }

  /// Membuka URL checkout DOKU menggunakan browser/custom tab eksternal.
  /// Penting (AT-11): Kembalinya pengguna dari browser tidak mengubah status booking!
  Future<bool> openCheckoutUrl(String paymentUrl) async {
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null || uri.scheme != 'https') {
      return false;
    }
    final launcher = _urlLauncher;
    if (launcher != null) {
      return launcher(uri);
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
