import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/booking_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../widgets/status_badge.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  Future<void> _showCancelDialog(
    BuildContext context,
    BookingModel booking,
  ) async {
    final reasonController = TextEditingController();
    final isConfirmed = booking.bookingStatus == BookingStatus.confirmed;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Batalkan Reservasi?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConfirmed
                    ? 'Booking ini sudah terkonfirmasi. Sesuai kebijakan MVP CourtMate (A-10), pengembalian dana ditangani secara manual oleh pengelola lapangan.'
                    : 'Slot yang sedang ditahan akan langsung dilepas kembali untuk pengguna lain.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan pembatalan (opsional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Tutup'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<BookingProvider>().cancelBooking(
        bookingId: booking.id,
        reason: reasonController.text,
      );
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final items = provider.filteredBookings;

    const filters = <(String, BookingStatus?)>[
      ('Semua', null),
      ('Menunggu Bayar', BookingStatus.pendingPayment),
      ('Terkonfirmasi', BookingStatus.confirmed),
      ('Dibatalkan', BookingStatus.cancelled),
      ('Kedaluwarsa', BookingStatus.expired),
    ];

    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (label, status) = filters[index];
              return FilterChip(
                label: Text(label),
                selected: provider.historyFilter == status,
                onSelected: (_) => provider.setHistoryFilter(status),
              );
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada riwayat booking pada kategori ini.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.courtName ?? booking.courtId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: booking.bookingStatus),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${CurrencyFormatter.formatFullDate(booking.startAt)} • '
                              '${CurrencyFormatter.formatSlotTimeRange(booking.startAt, booking.endAt)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatIdr(booking.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (booking.refundStatus ==
                                'manual_review_required') ...[
                              const SizedBox(height: 6),
                              Text(
                                'Status Refund: Menunggu proses manual pengelola',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                            if (booking.canRequestCancel) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (booking.bookingStatus ==
                                      BookingStatus.pendingPayment)
                                    TextButton.icon(
                                      onPressed: () {
                                        provider.setActiveBooking(booking.id);
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.payment,
                                        );
                                      },
                                      icon: const Icon(Icons.payment, size: 18),
                                      label: const Text('Lanjut Bayar'),
                                    ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: provider.isSubmitting
                                        ? null
                                        : () => _showCancelDialog(
                                            context,
                                            booking,
                                          ),
                                    child: const Text('Batalkan'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
