import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.pendingPayment => ('Menunggu Pembayaran', Colors.orange),
      BookingStatus.confirmed => ('Terkonfirmasi', Colors.green),
      BookingStatus.paymentFailed => ('Pembayaran Gagal', Colors.red),
      BookingStatus.expired => ('Kedaluwarsa', Colors.grey),
      BookingStatus.cancelled => ('Dibatalkan', Colors.redAccent),
      BookingStatus.completed => ('Selesai', Colors.teal),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }
}
