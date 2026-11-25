import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/court_model.dart';
import '../../../models/slot_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../widgets/stitch_ui.dart';

/// Layar 2 Stitch: `CourtMate — Ringkasan Booking` (`node_6788890688285337913`)
class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({
    super.key,
    this.preselectedCourt,
    this.preselectedSlot,
  });

  final CourtModel? preselectedCourt;
  final SlotModel? preselectedSlot;

  Future<void> _confirmHoldAndPay(BuildContext context) async {
    final bookingProvider = context.read<BookingProvider>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.uid ?? 'mhs_demo';

    if (preselectedCourt != null &&
        preselectedSlot != null &&
        bookingProvider.selectedSlotId != preselectedSlot!.id) {
      bookingProvider.applyPreselectedCourtAndSlot(
        court: preselectedCourt!,
        slot: preselectedSlot!,
      );
    }

    final session = await bookingProvider.createHoldAndPayment(userId: uid);
    if (session != null && context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final slot = preselectedSlot ?? provider.selectedSlot;
    final courtName = preselectedCourt?.name ?? provider.selectedCourtName;
    final courtAddress =
        preselectedCourt?.addressDisplay ?? 'Mitra Resmi CourtMate';
    final sportBadge =
        (preselectedCourt != null && preselectedCourt!.sportTypes.isNotEmpty)
        ? preselectedCourt!.sportTypes.join(' · ')
        : 'Terverifikasi';

    if (slot == null) {
      return StitchScope(
        child: Scaffold(
          backgroundColor: StitchTokens.background,
          body: SafeArea(
            child: Column(
              children: [
                StitchHeaderBar(
                  title: 'Ringkasan Booking',
                  subtitle: 'Konfirmasi sebelum pembayaran',
                  onLeadingTap: () => Navigator.maybePop(context),
                ),
                const Expanded(
                  child: Center(child: Text('Slot belum dipilih.')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StitchScope(
      child: Scaffold(
        backgroundColor: StitchTokens.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StitchHeaderBar(
                title: 'Ringkasan Booking',
                subtitle: 'Konfirmasi sebelum pembayaran',
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Banner Slot Hold sesuai Stitch (bg-tertiary text-background)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: StitchTokens.tertiary,
                        borderRadius: BorderRadius.circular(
                          StitchTokens.radiusLg,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: StitchTokens.onPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Slot dikunci sementara selama ${AppConstants.defaultSlotHoldMinutes}:00 menit saat lanjut pembayaran',
                              style: StitchTokens.bodyStrong.copyWith(
                                color: StitchTokens.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kartu Detail Pesanan
                    StitchCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('DETAIL PESANAN', style: StitchTokens.labelSm),
                              Text(sportBadge, style: StitchTokens.labelSm),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            courtName,
                            style: StitchTokens.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            courtAddress,
                            style: StitchTokens.bodyMd.copyWith(
                              color: StitchTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: StitchTokens.border),
                          _SummaryRow(
                            label: 'Tanggal',
                            value: CurrencyFormatter.formatFullDate(
                              slot.startAt,
                            ),
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _SummaryRow(
                            label: 'Jam Slot',
                            value: CurrencyFormatter.formatSlotTimeRange(
                              slot.startAt,
                              slot.endAt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kartu Rincian Biaya (BR-006: dihitung server)
                    StitchCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RINCIAN BIAYA', style: StitchTokens.labelSm),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Harga slot (server)',
                            value: CurrencyFormatter.formatIdr(slot.price),
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          _SummaryRow(
                            label: 'Biaya layanan',
                            value: 'Termasuk',
                          ),
                          const Divider(height: 1, color: StitchTokens.border),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Bayar',
                                  style: StitchTokens.bodyStrong,
                                ),
                                Text(
                                  CurrencyFormatter.formatIdr(slot.price),
                                  style: StitchTokens.h2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Keamanan DOKU Checkout
                    StitchCard(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: StitchTokens.surfaceElevated,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: StitchTokens.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pembayaran diproses aman dan terenkripsi melalui DOKU Checkout.',
                              style: StitchTokens.bodyMd.copyWith(
                                color: StitchTokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      StitchCard(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: StitchTokens.surfaceElevated,
                        borderColor: StitchTokens.error,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: StitchTokens.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: StitchTokens.labelSm.copyWith(
                                  color: StitchTokens.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Sticky Bottom Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: StitchTokens.surface,
                  border: Border(top: BorderSide(color: StitchTokens.border)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total bayar', style: StitchTokens.labelSm),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatIdr(slot.price),
                          style: StitchTokens.h2,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StitchPrimaryButton(
                        label: 'Bayar Sekarang via DOKU',
                        isLoading: provider.isSubmitting,
                        onPressed: () => _confirmHoldAndPay(context),
                      ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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
