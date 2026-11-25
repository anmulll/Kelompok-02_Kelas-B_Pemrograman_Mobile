import 'package:flutter/material.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48),
            SizedBox(height: 12),
            Text(
              'Riwayat & Status Booking (FR-018 / FR-019)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Modul `lib/features/history/`: menampilkan daftar reservasi milik mahasiswa '
              'dan tombol pengajuan pembatalan sesuai kebijakan.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
