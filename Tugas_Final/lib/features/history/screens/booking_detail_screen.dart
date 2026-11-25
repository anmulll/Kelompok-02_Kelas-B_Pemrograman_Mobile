import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/booking_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../booking/widgets/stitch_ui.dart';

/// Layar 5 Stitch: `CourtMate — Detail Booking` (`node_16860468909755274940`)
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _inviteEmailController = TextEditingController();

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendInvite(BookingModel booking) async {
    final provider = context.read<BookingProvider>();
    final auth = context.read<AuthProvider>();
    final ok = await provider.sendInvitation(
      bookingId: booking.id,
      recipientEmail: _inviteEmailController.text,
      senderId: auth.currentUser?.uid ?? 'mhs_demo',
      senderName: auth.currentUser?.name ?? 'Mahasiswa CourtMate',
    );
    if (ok && mounted) {
      _inviteEmailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undangan bermain telah dikirim.')),
      );
    }
  }

  Future<void> _confirmCancel(BookingModel booking) async {
    final reasonController = TextEditingController();
    final isConfirmed = booking.bookingStatus == BookingStatus.confirmed;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StitchScope(
          child: AlertDialog(
            backgroundColor: StitchTokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StitchTokens.radiusLg),
              side: const BorderSide(color: StitchTokens.border),
            ),
            title: const Text('Ajukan Pembatalan?', style: StitchTokens.h2),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfirmed
                      ? 'Booking ini telah lunas. Sesuai kebijakan MVP CourtMate (A-10), pengembalian dana diproses manual oleh pengelola lapangan.'
                      : 'Kunci sementara slot akan langsung dilepas kembali.',
                  style: StitchTokens.bodyMd.copyWith(
                    color: StitchTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  style: StitchTokens.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Alasan pembatalan (opsional)',
                    hintStyle: StitchTokens.bodyMd.copyWith(
                      color: StitchTokens.textSecondary,
                    ),
                    filled: true,
                    fillColor: StitchTokens.surfaceElevated,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
                      borderSide: const BorderSide(color: StitchTokens.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
                      borderSide: const BorderSide(color: StitchTokens.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(
                  'Batal',
                  style: StitchTokens.bodyStrong.copyWith(
                    color: StitchTokens.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(
                  'Ya, Batalkan',
                  style: StitchTokens.bodyStrong.copyWith(
                    color: StitchTokens.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (proceed == true && mounted) {
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
    BookingModel? booking;
    for (final item in provider.bookings) {
      if (item.id == widget.bookingId) {
        booking = item;
        break;
      }
    }

    if (booking == null) {
      return StitchScope(
        child: Scaffold(
          backgroundColor: StitchTokens.background,
          body: SafeArea(
            child: Column(
              children: [
                StitchHeaderBar(
                  title: 'Detail Booking',
                  onLeadingTap: () => Navigator.maybePop(context),
                ),
                const Expanded(
                  child: Center(child: Text('Booking tidak ditemukan.')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentBooking = booking;
    final linkedInvites = provider.sentInvitations
        .where((inv) => inv.bookingId == currentBooking.id)
        .toList();
    final paymentStatusText = switch (currentBooking.bookingStatus) {
      BookingStatus.confirmed || BookingStatus.completed => 'Lunas (DOKU)',
      BookingStatus.pendingPayment => 'Menunggu Verifikasi (DOKU)',
      BookingStatus.cancelled =>
        currentBooking.refundStatus == 'manual_review_required'
            ? 'Menunggu Refund Manual'
            : 'Dibatalkan',
      BookingStatus.paymentFailed => 'Gagal',
      BookingStatus.expired => 'Kedaluwarsa',
    };

    return StitchScope(
      child: Scaffold(
        backgroundColor: StitchTokens.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StitchHeaderBar(
                title: 'Detail Booking',
                subtitle: currentBooking.id.toUpperCase(),
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Kartu Informasi Lengkap Booking
                    StitchCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'INFORMASI BOOKING',
                                style: StitchTokens.labelSm,
                              ),
                              StitchBookingStatusBadge(
                                status: currentBooking.bookingStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentBooking.courtName ?? currentBooking.courtId,
                            style: StitchTokens.h2,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Kode Referensi',
                            value: currentBooking.id.toUpperCase(),
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _DetailRow(
                            label: 'Jadwal Main',
                            value:
                                '${DateFormat('EEE, dd MMM').format(currentBooking.startAt)} · '
                                '${CurrencyFormatter.formatSlotTimeRange(currentBooking.startAt, currentBooking.endAt)}',
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _DetailRow(
                            label: 'Status Pembayaran',
                            value: paymentStatusText,
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _DetailRow(
                            label: 'Total Bayar',
                            value: CurrencyFormatter.formatIdr(
                              currentBooking.amount,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: StitchTokens.surfaceElevated,
                              borderRadius: BorderRadius.circular(
                                StitchTokens.radiusMd,
                              ),
                              border: Border.all(color: StitchTokens.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: StitchTokens.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Kebijakan pembatalan: pengajuan pembatalan sebelum jadwal main dimulai. Pengembalian dana booking terkonfirmasi ditangani manual oleh pengelola.',
                                    style: StitchTokens.labelSm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kartu Undang Teman Bermain (Stitch Detail Booking)
                    if (currentBooking.canInviteFriends) ...[
                      StitchCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'UNDANG TEMAN BERMAIN',
                                  style: StitchTokens.labelSm,
                                ),
                                Text(
                                  '${linkedInvites.length} diundang',
                                  style: StitchTokens.labelSm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _inviteEmailController,
                              keyboardType: TextInputType.emailAddress,
                              style: StitchTokens.bodyMd,
                              decoration: InputDecoration(
                                hintText: 'Email teman (@mahasiswa.ac.id)',
                                hintStyle: StitchTokens.bodyMd.copyWith(
                                  color: StitchTokens.textSecondary,
                                ),
                                filled: true,
                                fillColor: StitchTokens.surfaceElevated,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    StitchTokens.radiusMd,
                                  ),
                                  borderSide: const BorderSide(
                                    color: StitchTokens.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    StitchTokens.radiusMd,
                                  ),
                                  borderSide: const BorderSide(
                                    color: StitchTokens.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            StitchPrimaryButton(
                              label: 'Undang Teman',
                              onPressed: () =>
                                  _sendFriendInvite(currentBooking),
                            ),
                            if (linkedInvites.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...linkedInvites.map((inv) {
                                final friendLabel =
                                    inv.recipientIdentifier.split('@').first;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: StitchTokens.border,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              friendLabel,
                                              style: StitchTokens.bodyStrong,
                                            ),
                                            Text(
                                              inv.recipientIdentifier,
                                              overflow: TextOverflow.ellipsis,
                                              style: StitchTokens.labelSm,
                                            ),
                                          ],
                                        ),
                                      ),
                                      StitchInvitationBadge(status: inv.status),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (currentBooking.bookingStatus ==
                        BookingStatus.pendingPayment) ...[
                      StitchPrimaryButton(
                        label: 'Lihat Status Pembayaran DOKU',
                        icon: Icons.payment,
                        onPressed: () {
                          provider.setActiveBooking(currentBooking.id);
                          Navigator.pushNamed(context, AppRoutes.payment);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (currentBooking.canRequestCancel)
                      StitchSecondaryButton(
                        label: 'Ajukan Pembatalan',
                        icon: Icons.cancel_outlined,
                        borderColor: StitchTokens.error,
                        textColor: StitchTokens.error,
                        onPressed: provider.isSubmitting
                            ? null
                            : () => _confirmCancel(currentBooking),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: StitchTokens.bodyMd.copyWith(
              color: StitchTokens.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: StitchTokens.bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}
