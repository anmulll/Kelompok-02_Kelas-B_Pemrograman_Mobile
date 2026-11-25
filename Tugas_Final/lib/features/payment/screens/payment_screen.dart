import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/booking_model.dart';
import '../../../models/payment_model.dart';
import '../../../providers/booking_provider.dart';
import '../../booking/widgets/stitch_ui.dart';

/// Layar 3 Stitch: `CourtMate — Status Pembayaran` (`node_2014579419022524448`)
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final provider = context.read<BookingProvider>();
      if (provider.activeBooking?.bookingStatus ==
          BookingStatus.pendingPayment) {
        provider.reconcileActivePayment();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatRemainingHold(DateTime? expiresAt) {
    if (expiresAt == null) return '--:--';
    final diff = expiresAt.difference(_now);
    if (diff.isNegative) return '00:00 (Habis)';
    final mins = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final booking = provider.activeBooking;
    final session = provider.activePaymentSession;

    if (booking == null) {
      return StitchScope(
        child: Scaffold(
          backgroundColor: StitchTokens.background,
          body: SafeArea(
            child: Column(
              children: [
                StitchHeaderBar(
                  title: 'Status Pembayaran',
                  leadingIcon: Icons.close,
                  onLeadingTap: () => Navigator.maybePop(context),
                ),
                const Expanded(
                  child: Center(child: Text('Tidak ada data pembayaran aktif.')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPending = booking.bookingStatus == BookingStatus.pendingPayment;
    final (icon, accentColor, heading, description) = _statusPresentation(
      booking,
    );

    return StitchScope(
      child: Scaffold(
        backgroundColor: StitchTokens.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StitchHeaderBar(
                title: 'Status Pembayaran',
                leadingIcon: Icons.close,
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Kartu Utama Status Verifikasi (Stitch Hero Card)
                    StitchCard(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: booking.bookingStatus ==
                                      BookingStatus.confirmed
                                  ? StitchTokens.primary.withValues(alpha: 0.15)
                                  : StitchTokens.surfaceElevated,
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor),
                            ),
                            child: Icon(icon, size: 28, color: accentColor),
                          ),
                          const SizedBox(height: 12),
                          StitchBookingStatusBadge(
                            status: booking.bookingStatus,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            heading,
                            textAlign: TextAlign.center,
                            style: StitchTokens.h2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: StitchTokens.bodyMd.copyWith(
                              color: StitchTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Banner Rekonsiliasi Terlambat (Bab 10)
                    if (booking.reconciliationRequired) ...[
                      StitchCard(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: StitchTokens.surfaceElevated,
                        borderColor: StitchTokens.warning,
                        child: Text(
                          'Pembayaran diterima setelah masa hold habis dan slot sudah terisi. '
                          'Transaksi masuk antrean rekonsiliasi manual pengelola.',
                          style: StitchTokens.labelSm.copyWith(
                            color: StitchTokens.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info Proteksi AT-11 saat kembali dari browser
                    if (provider.hasOpenedCheckoutBrowser && isPending) ...[
                      StitchCard(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: StitchTokens.surfaceElevated,
                        borderColor: StitchTokens.tertiary,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: StitchTokens.tertiary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Proteksi AT-11 aktif: kembali dari halaman browser tidak mengubah status menjadi Terkonfirmasi sebelum webhook DOKU diverifikasi server.',
                                style: StitchTokens.labelSm.copyWith(
                                  color: StitchTokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Kartu Detail Transaksi
                    StitchCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DETAIL TRANSAKSI', style: StitchTokens.labelSm),
                          const SizedBox(height: 8),
                          _TxRow(
                            label: 'ID Booking',
                            value:
                                session?.providerOrderId ?? booking.id,
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _TxRow(
                            label: 'Lapangan',
                            value: booking.courtName ?? booking.courtId,
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _TxRow(
                            label: 'Nominal',
                            value: CurrencyFormatter.formatIdr(booking.amount),
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          const _TxRow(
                            label: 'Metode',
                            value: 'DOKU Checkout',
                          ),
                          if (isPending) ...[
                            const Divider(
                              height: 1,
                              color: StitchTokens.border,
                            ),
                            _TxRow(
                              label: 'Sisa Kunci Slot',
                              value: _formatRemainingHold(
                                booking.holdExpiresAt ?? session?.expiresAt,
                              ),
                              valueColor: StitchTokens.tertiary,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Chip simulasi status di mode sandbox lokal (persis desain Stitch)
                    if (provider.isUsingLocalSandbox) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SandboxStateChip(
                            label: 'Simulasi Terkonfirmasi',
                            color: StitchTokens.primary,
                            onTap: () =>
                                provider.simulateServerWebhookInSandbox(
                                  bookingId: booking.id,
                                  webhookPaymentStatus: PaymentStatus.paid,
                                ),
                          ),
                          _SandboxStateChip(
                            label: 'Simulasi Gagal',
                            color: StitchTokens.error,
                            onTap: () =>
                                provider.simulateServerWebhookInSandbox(
                                  bookingId: booking.id,
                                  webhookPaymentStatus: PaymentStatus.failed,
                                ),
                          ),
                          _SandboxStateChip(
                            label: 'Simulasi Kedaluwarsa',
                            color: StitchTokens.textSecondary,
                            onTap: () =>
                                provider.simulateServerWebhookInSandbox(
                                  bookingId: booking.id,
                                  webhookPaymentStatus: PaymentStatus.expired,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Footer Tombol Aksi
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isPending) ...[
                      StitchPrimaryButton(
                        label: 'Buka Halaman DOKU Checkout',
                        icon: Icons.open_in_new,
                        onPressed: () => provider.openActiveCheckoutUrl(),
                      ),
                      const SizedBox(height: 10),
                      StitchSecondaryButton(
                        label: provider.isCheckingPaymentStatus
                            ? 'Memeriksa Status DOKU...'
                            : 'Cek Status Pembayaran',
                        icon: Icons.refresh,
                        onPressed: provider.isCheckingPaymentStatus
                            ? null
                            : () => provider.reconcileActivePayment(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    StitchSecondaryButton(
                      label: 'Ke Booking Saya',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, String, String) _statusPresentation(BookingModel booking) {
    return switch (booking.bookingStatus) {
      BookingStatus.pendingPayment => (
        Icons.hourglass_top_rounded,
        StitchTokens.tertiary,
        'Menunggu Verifikasi Pembayaran',
        'Status booking akan otomatis terkonfirmasi setelah notifikasi pembayaran dari DOKU diverifikasi oleh sistem, bukan sekadar kembali dari halaman bayar.',
      ),
      BookingStatus.confirmed => (
        Icons.check_circle_outline_rounded,
        StitchTokens.primary,
        'Pembayaran Terverifikasi',
        'Notifikasi DOKU telah diverifikasi. Slot lapangan Anda pada ${CurrencyFormatter.formatSlotTimeRange(booking.startAt, booking.endAt)} resmi terkonfirmasi.',
      ),
      BookingStatus.paymentFailed => (
        Icons.error_outline_rounded,
        StitchTokens.error,
        'Pembayaran Gagal',
        'Transaksi tidak berhasil diproses oleh DOKU. Silakan ulangi pemesanan atau pilih metode pembayaran lain.',
      ),
      BookingStatus.expired => (
        Icons.timer_off_outlined,
        StitchTokens.textSecondary,
        'Waktu Pembayaran Habis',
        'Batas waktu kunci slot telah berakhir sebelum pembayaran terverifikasi. Silakan pilih ulang jadwal Anda.',
      ),
      BookingStatus.cancelled => (
        Icons.cancel_outlined,
        StitchTokens.error,
        'Reservasi Dibatalkan',
        'Reservasi ini telah dibatalkan sesuai kebijakan pembatalan CourtMate.',
      ),
      BookingStatus.completed => (
        Icons.verified_outlined,
        StitchTokens.secondary,
        'Jadwal Selesai',
        'Sesi bermain pada reservasi ini telah selesai dilaksanakan.',
      ),
    };
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.label,
    required this.value,
    this.valueColor = StitchTokens.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: StitchTokens.bodyMd.copyWith(
              color: StitchTokens.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: StitchTokens.bodyStrong.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SandboxStateChip extends StatelessWidget {
  const _SandboxStateChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTokens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: StitchTokens.surfaceElevated,
          borderRadius: BorderRadius.circular(StitchTokens.radiusPill),
          border: Border.all(color: color),
        ),
        child: Text(label, style: StitchTokens.labelSm.copyWith(color: color)),
      ),
    );
  }
}
