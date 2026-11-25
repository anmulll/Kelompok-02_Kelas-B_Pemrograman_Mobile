import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/currency_formatter.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart';
import '../models/invitation_model.dart';
import '../models/payment_model.dart';
import '../models/slot_model.dart';
import '../services/booking_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/payment_service.dart';

/// State management utama Modul Anmul (Booking, DOKU Checkout, Riwayat, Pembatalan, Undangan).
/// Mendukung dua mode secara transparan:
/// 1. Mode Cloud (ketika Firebase sudah aktif/dikonfigurasi).
/// 2. Mode Sandbox Lokal (ketika dijalankan pratinjau UI / widget test sebelum Firebase aktif).
class BookingProvider extends ChangeNotifier {
  BookingProvider({
    BookingService? bookingService,
    PaymentService? paymentService,
    bool? useLocalSandbox,
  }) : _bookingService = bookingService ?? BookingService(),
       _paymentService = paymentService ?? PaymentService(),
       _forceLocalSandbox = useLocalSandbox {
    _initializeLocalPreviewData();
  }

  final BookingService _bookingService;
  final PaymentService _paymentService;
  final bool? _forceLocalSandbox;
  final Uuid _uuid = const Uuid();

  bool get isUsingLocalSandbox =>
      _forceLocalSandbox ?? !FirebaseBootstrap.isInitialized;

  String _selectedCourtId = 'court_kampus_arena';
  String _selectedCourtName = 'GOR Kampus Arena';
  DateTime _selectedDate = _stripTime(DateTime.now());
  String? _selectedSlotId;
  SlotModel? _preselectedSlot;
  BookingStatus? _historyFilter;

  List<SlotModel> _slots = [];
  List<BookingModel> _bookings = [];
  List<InvitationModel> _receivedInvitations = [];
  List<InvitationModel> _sentInvitations = [];
  List<NotificationModel> _notifications = [];

  String? _activeBookingId;
  BookingModel? _watchedActiveBooking;
  PaymentModel? _watchedActivePayment;
  DokuPaymentSession? _activePaymentSession;
  bool _hasOpenedCheckoutBrowser = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  StreamSubscription<List<SlotModel>>? _slotsSub;
  StreamSubscription<List<BookingModel>>? _bookingsSub;
  StreamSubscription<BookingModel?>? _activeBookingSub;
  StreamSubscription<PaymentModel?>? _activePaymentSub;
  StreamSubscription<List<InvitationModel>>? _receivedInvitesSub;
  StreamSubscription<List<InvitationModel>>? _sentInvitesSub;
  StreamSubscription<List<NotificationModel>>? _notificationsSub;

  String get selectedCourtId => _selectedCourtId;
  String get selectedCourtName => _selectedCourtName;
  DateTime get selectedDate => _selectedDate;
  String? get selectedSlotId => _selectedSlotId;
  BookingStatus? get historyFilter => _historyFilter;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasOpenedCheckoutBrowser => _hasOpenedCheckoutBrowser;
  DokuPaymentSession? get activePaymentSession => _activePaymentSession;
  PaymentModel? get activePayment => _watchedActivePayment;

  List<SlotModel> get slots => List.unmodifiable(_slots);
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  List<InvitationModel> get receivedInvitations =>
      List.unmodifiable(_receivedInvitations);
  List<InvitationModel> get sentInvitations =>
      List.unmodifiable(_sentInvitations);
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((item) => !item.isRead).length;

  SlotModel? get selectedSlot {
    if (_selectedSlotId == null) return null;
    if (_preselectedSlot != null && _preselectedSlot!.id == _selectedSlotId) {
      return _preselectedSlot;
    }
    for (final s in _slots) {
      if (s.id == _selectedSlotId) return s;
    }
    return null;
  }

  BookingModel? get activeBooking {
    if (_activeBookingId == null) {
      return _bookings.isNotEmpty ? _bookings.first : null;
    }
    if (_watchedActiveBooking != null &&
        _watchedActiveBooking!.id == _activeBookingId) {
      return _watchedActiveBooking;
    }
    for (final b in _bookings) {
      if (b.id == _activeBookingId) return b;
    }
    return null;
  }

  List<BookingModel> get filteredBookings {
    if (_historyFilter == null) return bookings;
    return _bookings
        .where((item) => item.bookingStatus == _historyFilter)
        .toList();
  }

  List<BookingModel> get invitableBookings =>
      _bookings.where((item) => item.canInviteFriends).toList();

  static DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _initializeLocalPreviewData() {
    if (!isUsingLocalSandbox) return;
    _slots = _generatePreviewSlotsFor(_selectedCourtId, _selectedDate);

    final now = DateTime.now();
    final tomorrow = _stripTime(now).add(const Duration(days: 1));
    final confirmedBooking = BookingModel(
      id: 'bk_confirmed_demo',
      userId: 'mhs_demo',
      courtId: 'court_kampus_arena',
      courtName: 'GOR Kampus Arena',
      slotId: 'slot_besok_19',
      startAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19),
      endAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20),
      amount: 150000,
      bookingStatus: BookingStatus.confirmed,
      paymentId: 'pay_demo_01',
      idempotencyKey: 'demo-idem-01',
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      confirmedAt: now.subtract(const Duration(hours: 3)),
    );

    _bookings = [confirmedBooking];
    _receivedInvitations = [
      InvitationModel(
        id: 'inv_in_01',
        bookingId: 'bk_caca_09',
        senderId: 'uid_caca',
        senderName: 'Caca',
        recipientIdentifier: 'mahasiswa@kampus.ac.id',
        courtName: 'Lapangan Badminton Teknik',
        scheduleLabel: 'Sabtu, 16:00 - 17:00',
        status: InvitationStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
    _notifications = [
      NotificationModel(
        id: 'notif_01',
        userId: 'mhs_demo',
        title: 'Booking Terkonfirmasi',
        body:
            'Pembayaran DOKU untuk GOR Kampus Arena berhasil diverifikasi server.',
        type: 'booking_confirmed',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
        relatedId: confirmedBooking.id,
      ),
    ];
  }

  List<SlotModel> _generatePreviewSlotsFor(String courtId, DateTime date) {
    final day = _stripTime(date);
    final now = DateTime.now();
    final hours = [8, 9, 10, 15, 16, 17, 19, 20];

    return List.generate(hours.length, (index) {
      final startHour = hours[index];
      final startAt = DateTime(day.year, day.month, day.day, startHour);
      final endAt = startAt.add(const Duration(hours: 1));
      final isWeekendOrNight = startHour >= 19;
      final price = isWeekendOrNight ? 150000 : 120000;

      var status = SlotStatus.available;
      DateTime? holdExp;
      String? bId;

      if (index == 2) {
        status = SlotStatus.booked;
        bId = 'other_booked_01';
      } else if (index == 5) {
        status = SlotStatus.held;
        bId = 'other_held_01';
        holdExp = now.add(const Duration(minutes: 6));
      }

      // Pertahankan status slot bila sudah dipesan pada sesi lokal ini
      final slotId = '${courtId}_${day.year}${day.month}${day.day}_$startHour';
      for (final existing in _bookings) {
        if (existing.slotId == slotId) {
          if (existing.bookingStatus == BookingStatus.pendingPayment) {
            status = SlotStatus.held;
            bId = existing.id;
            holdExp = existing.holdExpiresAt;
          } else if (existing.bookingStatus == BookingStatus.confirmed) {
            status = SlotStatus.booked;
            bId = existing.id;
            holdExp = null;
          }
        }
      }

      return SlotModel(
        id: slotId,
        courtId: courtId,
        startAt: startAt,
        endAt: endAt,
        price: price,
        status: status,
        bookingId: bId,
        holdExpiresAt: holdExp,
        updatedAt: now,
      );
    });
  }

  /// Dipanggil saat membuka `/booking` dari `SlotSelectionScreen` milik Caca
  /// dengan membawa `court` dan `slot` yang sudah dipilih agar tidak memilih 2x.
  void applyPreselectedCourtAndSlot({
    required CourtModel court,
    required SlotModel slot,
  }) {
    _selectedCourtId = court.id;
    _selectedCourtName = court.name;
    _selectedDate = _stripTime(slot.startAt);
    _preselectedSlot = slot;
    _selectedSlotId = slot.id;
    _errorMessage = null;
    notifyListeners();
  }

  /// Dipanggil saat membuka halaman pemilihan slot dari modul Caca (`courtId`, `courtName`).
  void setCourtContext({
    required String courtId,
    required String courtName,
    DateTime? date,
  }) {
    _selectedCourtId = courtId;
    _selectedCourtName = courtName;
    if (date != null) {
      _selectedDate = _stripTime(date);
    }
    _preselectedSlot = null;
    _selectedSlotId = null;
    _errorMessage = null;
    _loadSlots();
  }

  void selectDate(DateTime date) {
    _selectedDate = _stripTime(date);
    _selectedSlotId = null;
    _errorMessage = null;
    _loadSlots();
  }

  void selectSlot(SlotModel slot) {
    if (!slot.isSelectableAt(DateTime.now())) {
      _errorMessage =
          'Slot ini sedang ditahan pengguna lain atau sudah terisi.';
      notifyListeners();
      return;
    }
    _selectedSlotId = slot.id;
    _errorMessage = null;
    notifyListeners();
  }

  void setHistoryFilter(BookingStatus? filter) {
    _historyFilter = filter;
    notifyListeners();
  }

  void setActiveBooking(String bookingId) {
    _activeBookingId = bookingId;
    _hasOpenedCheckoutBrowser = false;
    _watchActiveBooking(bookingId);
    notifyListeners();
  }

  /// Menghubungkan seluruh stream real-time Firestore milik pengguna yang login
  /// (`bookings`, `invitations` masuk & terkirim, serta `notifications`).
  void bindUserStreams(String userId, {String? email}) {
    if (isUsingLocalSandbox) return;

    _bookingsSub?.cancel();
    _bookingsSub = _bookingService.watchUserBookings(userId).listen((items) {
      _bookings = items;
      notifyListeners();
    });

    _sentInvitesSub?.cancel();
    _sentInvitesSub = _bookingService.watchSentInvitations(userId).listen((
      items,
    ) {
      _sentInvitations = items;
      notifyListeners();
    });

    _notificationsSub?.cancel();
    _notificationsSub = _bookingService.watchUserNotifications(userId).listen((
      items,
    ) {
      _notifications = items;
      notifyListeners();
    });

    _receivedInvitesSub?.cancel();
    if (email != null && email.trim().isNotEmpty) {
      _receivedInvitesSub = _bookingService
          .watchReceivedInvitations(email)
          .listen((items) {
            _receivedInvitations = items;
            notifyListeners();
          });
    }
  }

  void unbindUserStreams() {
    _bookingsSub?.cancel();
    _activeBookingSub?.cancel();
    _activePaymentSub?.cancel();
    _receivedInvitesSub?.cancel();
    _sentInvitesSub?.cancel();
    _notificationsSub?.cancel();
    _watchedActiveBooking = null;
    _watchedActivePayment = null;
    _activeBookingId = null;
    _activePaymentSession = null;
    notifyListeners();
  }

  void _watchActiveBooking(String bookingId) {
    if (isUsingLocalSandbox) return;

    _activeBookingSub?.cancel();
    _activeBookingSub = _bookingService.watchBookingById(bookingId).listen((
      booking,
    ) {
      _watchedActiveBooking = booking;
      final paymentId = booking?.paymentId;
      if (paymentId != null &&
          paymentId.isNotEmpty &&
          _watchedActivePayment?.id != paymentId) {
        _watchActivePayment(paymentId);
      }
      notifyListeners();
    });
  }

  void _watchActivePayment(String paymentId) {
    if (isUsingLocalSandbox) return;

    _activePaymentSub?.cancel();
    _activePaymentSub = _paymentService.watchPaymentById(paymentId).listen((
      payment,
    ) {
      _watchedActivePayment = payment;
      notifyListeners();
    });
  }

  void _loadSlots() {
    if (isUsingLocalSandbox) {
      _slots = _generatePreviewSlotsFor(_selectedCourtId, _selectedDate);
      notifyListeners();
      return;
    }

    _slotsSub?.cancel();
    _slotsSub = _bookingService
        .watchSlotsForCourtAndDate(
          courtId: _selectedCourtId,
          date: _selectedDate,
        )
        .listen((items) {
          _slots = items;
          notifyListeners();
        });
  }

  /// Alur kritis A-02, A-03, A-04:
  /// Membuat hold slot atomik + meminta URL DOKU Checkout Sandbox dari backend.
  Future<DokuPaymentSession?> createHoldAndPayment({
    String userId = 'mhs_demo',
  }) async {
    final slot = selectedSlot;
    if (slot == null) {
      _errorMessage = 'Pilih salah satu slot jadwal yang tersedia terlebih dahulu.';
      notifyListeners();
      return null;
    }

    final now = DateTime.now();
    if (!slot.isSelectableAt(now)) {
      _errorMessage = 'Slot baru saja diambil pengguna lain. Silakan pilih slot lain.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _hasOpenedCheckoutBrowser = false;
    notifyListeners();

    try {
      final idempotencyKey = _uuid.v4();

      if (isUsingLocalSandbox) {
        final holdExpiresAt = now.add(
          const Duration(minutes: AppConstants.defaultSlotHoldMinutes),
        );
        final bookingId = '${userId}_${idempotencyKey.substring(0, 8)}';
        final orderId = 'CM-${idempotencyKey.substring(0, 8).toUpperCase()}';
        final paymentId = 'pay_${idempotencyKey.substring(0, 8)}';
        final session = DokuPaymentSession(
          paymentId: paymentId,
          providerOrderId: orderId,
          paymentUrl: 'https://sandbox.doku.com/checkout-link/$orderId',
          expiresAt: holdExpiresAt,
        );

        final newBooking = BookingModel(
          id: bookingId,
          userId: userId,
          courtId: _selectedCourtId,
          courtName: _selectedCourtName,
          slotId: slot.id,
          startAt: slot.startAt,
          endAt: slot.endAt,
          amount: slot.price, // Harga otoritatif slot, bukan input bebas
          bookingStatus: BookingStatus.pendingPayment,
          paymentId: paymentId,
          idempotencyKey: idempotencyKey,
          createdAt: now,
          updatedAt: now,
          holdExpiresAt: holdExpiresAt,
        );

        _bookings = [newBooking, ..._bookings];
        _activeBookingId = bookingId;
        _activePaymentSession = session;
        _selectedSlotId = null;
        _slots = _generatePreviewSlotsFor(_selectedCourtId, _selectedDate);
        return session;
      }

      // Mode Cloud Functions (trusted backend)
      final bookingResult = await _bookingService.createBooking(
        courtId: _selectedCourtId,
        slotId: slot.id,
        idempotencyKey: idempotencyKey,
      );

      final session = await _paymentService.createDokuPayment(
        bookingId: bookingResult.bookingId,
      );

      _activeBookingId = bookingResult.bookingId;
      _activePaymentSession = session;
      _selectedSlotId = null;
      _watchActiveBooking(bookingResult.bookingId);
      if (session.paymentId.isNotEmpty) {
        _watchActivePayment(session.paymentId);
      }
      return session;
    } catch (error) {
      _errorMessage =
          'Gagal mengunci slot atau membuat sesi DOKU Checkout. Silakan coba lagi.';
      debugPrint('BookingProvider.createHoldAndPayment error: $error');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Membuka URL pembayaran DOKU Checkout (A-04 & AT-11).
  /// AT-11: Membuka/kembali dari browser SAMA SEKALI TIDAK mengubah booking menjadi `confirmed`.
  Future<bool> openActiveCheckoutUrl() async {
    final url =
        _activePaymentSession?.paymentUrl ??
        'https://sandbox.doku.com/checkout-link/${activeBooking?.id ?? 'demo'}';
    final launched = await _paymentService.openCheckoutUrl(url);
    _hasOpenedCheckoutBrowser = true;
    notifyListeners();
    return launched;
  }

  /// Khusus mode pratinjau lokal tanpa server: menyimulasikan masuknya webhook DOKU ke backend
  /// untuk keperluan demo presentasi kelas & pengujian transisi UI.
  void simulateServerWebhookInSandbox({
    required String bookingId,
    required PaymentStatus webhookPaymentStatus,
  }) {
    if (!isUsingLocalSandbox) return;
    final now = DateTime.now();

    _bookings = _bookings.map((b) {
      if (b.id != bookingId) return b;
      if (webhookPaymentStatus == PaymentStatus.paid) {
        _notifications = [
          NotificationModel(
            id: 'notif_${now.millisecondsSinceEpoch}',
            userId: b.userId,
            title: 'Booking Terkonfirmasi',
            body:
                'Webhook DOKU terverifikasi untuk ${b.courtName ?? b.courtId} (${CurrencyFormatter.formatIdr(b.amount)}).',
            type: 'booking_confirmed',
            createdAt: now,
            relatedId: b.id,
          ),
          ..._notifications,
        ];
        return b.copyWith(
          bookingStatus: BookingStatus.confirmed,
          confirmedAt: now,
          updatedAt: now,
        );
      }
      if (webhookPaymentStatus == PaymentStatus.expired) {
        return b.copyWith(
          bookingStatus: BookingStatus.expired,
          updatedAt: now,
        );
      }
      return b.copyWith(
        bookingStatus: BookingStatus.paymentFailed,
        updatedAt: now,
      );
    }).toList();

    _slots = _generatePreviewSlotsFor(_selectedCourtId, _selectedDate);
    notifyListeners();
  }

  /// Pembatalan booking sesuai kebijakan (A-10).
  Future<bool> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isUsingLocalSandbox) {
        final now = DateTime.now();
        BookingModel? target;
        for (final b in _bookings) {
          if (b.id == bookingId) target = b;
        }
        if (target == null || !target.canRequestCancel) {
          _errorMessage = 'Booking ini tidak dapat dibatalkan.';
          return false;
        }

        final isConfirmed = target.bookingStatus == BookingStatus.confirmed;
        _bookings = _bookings.map((b) {
          if (b.id != bookingId) return b;
          return b.copyWith(
            bookingStatus: BookingStatus.cancelled,
            cancelReason: reason,
            refundStatus: isConfirmed ? 'manual_review_required' : null,
            updatedAt: now,
          );
        }).toList();

        _notifications = [
          NotificationModel(
            id: 'notif_cancel_${now.millisecondsSinceEpoch}',
            userId: target.userId,
            title: 'Reservasi Dibatalkan',
            body: isConfirmed
                ? 'Reservasi dibatalkan. Pengembalian dana diproses manual oleh pengelola lapangan.'
                : 'Reservasi dibatalkan dan slot telah dilepas kembali.',
            type: 'booking_cancelled',
            createdAt: now,
            relatedId: bookingId,
          ),
          ..._notifications,
        ];

        _slots = _generatePreviewSlotsFor(_selectedCourtId, _selectedDate);
        return true;
      }

      await _bookingService.cancelBooking(bookingId: bookingId, reason: reason);
      return true;
    } catch (error) {
      _errorMessage = 'Pembatalan gagal diproses. Silakan coba lagi.';
      debugPrint('BookingProvider.cancelBooking error: $error');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Mengirim undangan teman bermain terkait booking aktif (A-11).
  Future<bool> sendInvitation({
    required String bookingId,
    required String recipientEmail,
    String senderId = 'mhs_demo',
    String senderName = 'Anmul',
  }) async {
    final email = recipientEmail.trim().toLowerCase();
    if (!email.contains('@')) {
      _errorMessage = 'Masukkan alamat email teman yang valid.';
      notifyListeners();
      return false;
    }

    BookingModel? booking;
    for (final b in _bookings) {
      if (b.id == bookingId) booking = b;
    }
    if (booking == null || !booking.canInviteFriends) {
      _errorMessage = 'Pilih booking yang masih aktif untuk mengirim undangan.';
      notifyListeners();
      return false;
    }

    final scheduleLabel =
        '${CurrencyFormatter.formatFullDate(booking.startAt)} • ${CurrencyFormatter.formatSlotTimeRange(booking.startAt, booking.endAt)}';

    if (isUsingLocalSandbox) {
      final inv = InvitationModel(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId,
        senderId: senderId,
        senderName: senderName,
        recipientIdentifier: email,
        courtName: booking.courtName ?? booking.courtId,
        scheduleLabel: scheduleLabel,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
      );
      _sentInvitations = [inv, ..._sentInvitations];
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    try {
      await _bookingService.sendInvitation(
        bookingId: bookingId,
        senderId: senderId,
        senderName: senderName,
        recipientEmail: email,
        courtName: booking.courtName,
        scheduleLabel: scheduleLabel,
      );
      return true;
    } catch (error) {
      _errorMessage = 'Gagal mengirim undangan.';
      notifyListeners();
      return false;
    }
  }

  Future<void> respondToInvitation({
    required String invitationId,
    required InvitationStatus decision,
  }) async {
    if (isUsingLocalSandbox) {
      _receivedInvitations = _receivedInvitations.map((inv) {
        if (inv.id != invitationId) return inv;
        return inv.copyWith(status: decision);
      }).toList();
      notifyListeners();
      return;
    }
    await _bookingService.updateInvitationStatus(
      invitationId: invitationId,
      status: decision,
    );
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (isUsingLocalSandbox) {
      _notifications = _notifications.map((n) {
        if (n.id != notificationId) return n;
        return n.copyWith(isRead: true);
      }).toList();
      notifyListeners();
      return;
    }
    await _bookingService.markNotificationAsRead(notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final item in unread) {
      await markNotificationRead(item.id);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _slotsSub?.cancel();
    _bookingsSub?.cancel();
    _activeBookingSub?.cancel();
    _activePaymentSub?.cancel();
    _receivedInvitesSub?.cancel();
    _sentInvitesSub?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }
}
