import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin / Pengelola')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.stadium_outlined),
              title: Text('Kelola Data Lapangan (FR-020)'),
              subtitle: Text(
                'Tambah/ubah informasi fasilitas, harga, dan jam operasional (`ownerId`).',
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.calendar_month_outlined),
              title: Text('Kelola Jadwal & Slot (FR-021)'),
              subtitle: Text(
                'Atur ketersediaan slot per tanggal melalui Cloud Function `manageCourt`.',
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.analytics_outlined),
              title: Text('Pantau Reservasi & Ringkasan (FR-022 / FR-025)'),
              subtitle: Text(
                'Lihat daftar booking terkonfirmasi pada lapangan yang dikelola.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
