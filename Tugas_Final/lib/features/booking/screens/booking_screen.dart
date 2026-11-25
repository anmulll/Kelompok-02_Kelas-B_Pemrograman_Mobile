import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Slot & Hold')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alur Aman Pemesanan (FR-009 s.d. FR-012)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Klien mengirim `courtId`, `slotId`, dan `idempotencyKey` ke Cloud Function `createBooking`.\n'
                      '2. Server memvalidasi ketersediaan & menahan slot (`held`) selama '
                      '${AppConstants.defaultSlotHoldMinutes} menit secara atomik.\n'
                      '3. Server menghitung harga dari Firestore (BR-006) dan memanggil `createDokuPayment`.',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.payment),
              icon: const Icon(Icons.payment),
              label: const Text('Lanjut ke Pembayaran DOKU Sandbox'),
            ),
          ],
        ),
      ),
    );
  }
}
