import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import '../../../widgets/status_badge.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Reservasi Saat Ini',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(status: BookingStatus.pendingPayment),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Catatan Aturan Bisnis (BR-007 & BR-008): Kembalinya pengguna dari halaman '
                  'DOKU Checkout bukan bukti pembayaran berhasil. Halaman ini memantau dokumen '
                  '`bookings/{bookingId}` secara real-time sampai webhook DOKU terverifikasi oleh backend.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
