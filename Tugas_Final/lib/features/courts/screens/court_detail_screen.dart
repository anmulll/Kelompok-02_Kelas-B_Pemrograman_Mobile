import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class CourtDetailScreen extends StatelessWidget {
  const CourtDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Lapangan')),
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
                    children: [
                      const Icon(Icons.verified, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Terdaftar di CourtMate (FR-006 / FR-007)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'GOR Kampus Arena',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Modul ini dikerjakan pada folder `lib/features/courts/`. '
                    'Menampilkan alamat, jenis olahraga, fasilitas, jam operasional, '
                    'serta daftar slot dari koleksi `slots` berdasarkan tanggal (FR-008).',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
            icon: const Icon(Icons.schedule),
            label: const Text('Pilih Slot & Lanjut Booking'),
          ),
        ],
      ),
    );
  }
}
