import 'package:flutter/material.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 48),
            SizedBox(height: 12),
            Text(
              'Undangan Bermain Bersama (FR-023)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Modul `lib/features/invitations/`: menampilkan undangan masuk dan keluar '
              'yang terhubung dengan booking aktif.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
