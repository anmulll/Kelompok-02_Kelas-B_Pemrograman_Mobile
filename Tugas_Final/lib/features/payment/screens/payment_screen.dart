import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/booking_model.dart';
import '../../../models/payment_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../widgets/status_badge.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatRemainingHold(DateTime? expiresAt) {
    if (expiresAt == null) return '--:--';
    final diff = expiresAt.difference(_now);
    if (diff.isNegative) return '00:00 (Kedaluwarsa)';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran Reservasi')),
        body: const Center(
          child: Text('Tidak ada data booking aktif yang dipilih.'),
        ),
      );
    }

    final isPending = booking.bookingStatus == BookingStatus.pendingPayment;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran DOKU Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Reservasi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      StatusBadge(status: booking.bookingStatus),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Lapangan',
                    value: booking.courtName ?? booking.courtId,
                  ),
                  _InfoRow(
                    label: 'Jadwal',
                    value:
                        '${CurrencyFormatter.formatFullDate(booking.startAt)} • '
                        '${CurrencyFormatter.formatSlotTimeRange(booking.startAt, booking.endAt)}',
                  ),
                  _InfoRow(
                    label: 'Order ID DOKU',
                    value: session?.providerOrderId ?? booking.paymentId ?? '-',
                  ),
                  _InfoRow(
                    label: 'Total Tagihan',
                    value: CurrencyFormatter.formatIdr(booking.amount),
                    isBold: true,
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Batas waktu hold slot: ${_formatRemainingHold(booking.holdExpiresAt ?? session?.expiresAt)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Peringatan Rekonsiliasi (Bab 10) bila pembayaran masuk terlambat
          if (booking.reconciliationRequired)
            Card(
              color: Colors.amber.shade100,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Pembayaran Anda diterima setelah masa hold habis ketika slot sudah terisi. '
                  'Transaksi ini masuk antrean rekonsiliasi manual pengelola.',
                ),
              ),
            ),

          // Proteksi AT-11: Redirect dari browser BUKAN bukti lunas!
          if (provider.hasOpenedCheckoutBrowser && isPending) ...[
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Halaman pembayaran telah dibuka. Sesuai aturan keamanan CourtMate (AT-11), '
                        'kembalinya aplikasi dari browser tidak mengubah status menjadi Terkonfirmasi. '
                        'Status diperbarui otomatis setelah backend memverifikasi webhook DOKU.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (isPending) ...[
            FilledButton.icon(
              onPressed: () => provider.openActiveCheckoutUrl(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka Halaman DOKU Checkout'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cek Nanti di Riwayat Booking'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Selesai & Kembali'),
            ),
          ],

          // Panel simulasi khusus saat mode sandbox lokal agar mudah didemokan tanpa cloud
          if (provider.isUsingLocalSandbox && isPending) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Simulasi Webhook Server (Mode Pratinjau Lokal)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gunakan tombol ini saat demo offline untuk menyimulasikan notifikasi server-to-server DOKU:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              provider.simulateServerWebhookInSandbox(
                                bookingId: booking.id,
                                webhookPaymentStatus: PaymentStatus.paid,
                              ),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Webhook SUCCESS'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              provider.simulateServerWebhookInSandbox(
                                bookingId: booking.id,
                                webhookPaymentStatus: PaymentStatus.expired,
                              ),
                          icon: const Icon(Icons.timer_off_outlined),
                          label: const Text('Webhook EXPIRED'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
