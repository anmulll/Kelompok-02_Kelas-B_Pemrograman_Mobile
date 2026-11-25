import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/booking_model.dart';
import '../../../providers/booking_provider.dart';
import '../../booking/widgets/stitch_ui.dart';
import 'booking_detail_screen.dart';

/// Layar 4 Stitch: `CourtMate — Booking Saya` (`node_9133606343733018130`)
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final items = provider.filteredBookings;

    const filters = <(String, BookingStatus?)>[
      ('Semua', null),
      ('Menunggu Bayar', BookingStatus.pendingPayment),
      ('Terkonfirmasi', BookingStatus.confirmed),
      ('Selesai', BookingStatus.completed),
      ('Dibatalkan', BookingStatus.cancelled),
    ];

    return StitchScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky Header + Pill Status Filter
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: StitchTokens.background,
              border: Border(bottom: BorderSide(color: StitchTokens.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Booking Saya', style: StitchTokens.h2),
                    Text(
                      '${items.length} reservasi',
                      style: StitchTokens.labelSm,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final (label, status) = filters[index];
                      final isActive = provider.historyFilter == status;

                      return InkWell(
                        onTap: () => provider.setHistoryFilter(status),
                        borderRadius: BorderRadius.circular(
                          StitchTokens.radiusPill,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive
                                ? StitchTokens.primary
                                : StitchTokens.surface,
                            borderRadius: BorderRadius.circular(
                              StitchTokens.radiusPill,
                            ),
                            border: isActive
                                ? null
                                : Border.all(color: StitchTokens.border),
                          ),
                          child: Text(
                            label,
                            style: StitchTokens.labelSm.copyWith(
                              color: isActive
                                  ? StitchTokens.onPrimary
                                  : StitchTokens.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Daftar Kartu Booking
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Belum ada riwayat reservasi pada filter ini.',
                        textAlign: TextAlign.center,
                        style: StitchTokens.bodyMd.copyWith(
                          color: StitchTokens.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = items[index];
                      final scheduleStr =
                          '${DateFormat('EEE, dd MMM').format(booking.startAt)} · '
                          '${CurrencyFormatter.formatSlotTimeRange(booking.startAt, booking.endAt)}';

                      return StitchCard(
                        onTap: () {
                          provider.setActiveBooking(booking.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  BookingDetailScreen(bookingId: booking.id),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    booking.id.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: StitchTokens.labelSm,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StitchBookingStatusBadge(
                                  status: booking.bookingStatus,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              booking.courtName ?? booking.courtId,
                              style: StitchTokens.bodyStrong,
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: StitchTokens.border),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(scheduleStr, style: StitchTokens.labelSm),
                                Text(
                                  CurrencyFormatter.formatIdr(booking.amount),
                                  style: StitchTokens.bodyStrong.copyWith(
                                    color: booking.bookingStatus ==
                                            BookingStatus.cancelled
                                        ? StitchTokens.textSecondary
                                        : StitchTokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
