import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/court_model.dart';
import '../../../models/slot_model.dart';
import '../../../providers/booking_provider.dart';
import '../widgets/stitch_ui.dart';
import 'booking_summary_screen.dart';

/// Kontrak argumen navigasi dari halaman Detail Lapangan milik modul Caca (Bab 14).
class BookingScreenArgs {
  const BookingScreenArgs({
    required this.courtId,
    required this.courtName,
  });

  final String courtId;
  final String courtName;
}

/// Layar 1 Stitch: `CourtMate — Pilih Jadwal & Slot` (`node_1672783808461408232`)
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _didInitArgs = false;
  CourtModel? _preselectedCourt;
  SlotModel? _preselectedSlot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final court = args['court'];
      final slot = args['slot'];
      if (court is CourtModel && slot is SlotModel) {
        _preselectedCourt = court;
        _preselectedSlot = slot;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<BookingProvider>().applyPreselectedCourtAndSlot(
            court: court,
            slot: slot,
          );
        });
        return;
      }
    }

    if (args is BookingScreenArgs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BookingProvider>().setCourtContext(
          courtId: args.courtId,
          courtName: args.courtName,
        );
      });
    }
  }

  void _openBookingSummary() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const BookingSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika dipanggil dari SlotSelectionScreen (modul Caca) dengan membawa court & slot,
    // langsung tampilkan Ringkasan Booking agar pengguna tidak memilih jadwal 2 kali.
    if (_preselectedCourt != null && _preselectedSlot != null) {
      return BookingSummaryScreen(
        preselectedCourt: _preselectedCourt,
        preselectedSlot: _preselectedSlot,
      );
    }

    final provider = context.watch<BookingProvider>();
    final selectedSlot = provider.selectedSlot;
    final today = DateTime.now();
    final now = DateTime.now();

    return StitchScope(
      child: Scaffold(
        backgroundColor: StitchTokens.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StitchHeaderBar(
                title: 'Pilih Jadwal & Slot',
                subtitle: provider.selectedCourtName,
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // Pemilih Tanggal Horizontal (7 Hari ke Depan)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PILIH TANGGAL',
                          style: StitchTokens.labelSm,
                        ),
                        Text(
                          DateFormat('MMM yyyy').format(provider.selectedDate),
                          style: StitchTokens.labelSm,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final date = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          ).add(Duration(days: index));
                          final isSelected =
                              date.year == provider.selectedDate.year &&
                              date.month == provider.selectedDate.month &&
                              date.day == provider.selectedDate.day;

                          return InkWell(
                            key: ValueKey('date_tile_$index'),
                            onTap: () => provider.selectDate(date),
                            borderRadius: BorderRadius.circular(
                              StitchTokens.radiusMd,
                            ),
                            child: Container(
                              width: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? StitchTokens.primary
                                    : StitchTokens.surface,
                                borderRadius: BorderRadius.circular(
                                  StitchTokens.radiusMd,
                                ),
                                border: isSelected
                                    ? null
                                    : Border.all(color: StitchTokens.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(date),
                                    style: StitchTokens.labelSm.copyWith(
                                      color: isSelected
                                          ? StitchTokens.onPrimary
                                          : StitchTokens.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd').format(date),
                                    style: StitchTokens.bodyStrong.copyWith(
                                      color: isSelected
                                          ? StitchTokens.onPrimary
                                          : StitchTokens.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Legenda Status Slot (Stitch 2x2 Grid)
                    StitchCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: const [
                          Row(
                            children: [
                              Expanded(
                                child: _LegendItem(
                                  color: StitchTokens.primary,
                                  label: 'Tersedia / Dipilih',
                                ),
                              ),
                              Expanded(
                                child: _LegendItem(
                                  color: StitchTokens.tertiary,
                                  label: 'Sedang Dipesan',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _LegendItem(
                                  color: StitchTokens.secondary,
                                  label: 'Terisi',
                                ),
                              ),
                              Expanded(
                                child: _LegendItem(
                                  color: StitchTokens.textMuted,
                                  label: 'Tidak Tersedia',
                                  mutedText: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      StitchCard(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: StitchTokens.surfaceElevated,
                        borderColor: StitchTokens.error,
                        child: Text(
                          provider.errorMessage!,
                          style: StitchTokens.labelSm.copyWith(
                            color: StitchTokens.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Text('PILIH SLOT WAKTU', style: StitchTokens.labelSm),
                    const SizedBox(height: 8),

                    if (provider.slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Belum ada slot jadwal pada tanggal ini.'),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 74,
                            ),
                        itemCount: provider.slots.length,
                        itemBuilder: (context, index) {
                          final slot = provider.slots[index];
                          final isSelected = provider.selectedSlotId == slot.id;
                          return _SlotTile(
                            slot: slot,
                            now: now,
                            isSelected: isSelected,
                            onTap: () => provider.selectSlot(slot),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // Sticky Bottom Bar sesuai desain Stitch
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedSlot != null
                                ? '${CurrencyFormatter.formatSlotTimeRange(selectedSlot.startAt, selectedSlot.endAt)} (1 slot)'
                                : 'Belum ada slot dipilih',
                            style: StitchTokens.labelSm,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedSlot != null
                                ? CurrencyFormatter.formatIdr(
                                    selectedSlot.price,
                                  )
                                : 'Rp 0',
                            style: StitchTokens.h2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StitchPrimaryButton(
                      label: 'Lanjut Booking',
                      onPressed: selectedSlot == null
                          ? null
                          : _openBookingSummary,
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.mutedText = false,
  });

  final Color color;
  final String label;
  final bool mutedText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: StitchTokens.labelSm.copyWith(
              color: mutedText
                  ? StitchTokens.textSecondary
                  : StitchTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.now,
    required this.isSelected,
    required this.onTap,
  });

  final SlotModel slot;
  final DateTime now;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectable = slot.isSelectableAt(now);
    final timeText = CurrencyFormatter.formatSlotTimeRange(
      slot.startAt,
      slot.endAt,
    );

    Color bgColor = StitchTokens.surface;
    Color borderColor = StitchTokens.border;
    Color titleColor = StitchTokens.textPrimary;
    Widget bottomStatus;

    if (isSelected) {
      bgColor = StitchTokens.primary;
      borderColor = StitchTokens.primary;
      titleColor = StitchTokens.onPrimary;
      bottomStatus = Text(
        '${CurrencyFormatter.formatIdr(slot.price)} · Dipilih',
        style: StitchTokens.labelSm.copyWith(color: StitchTokens.onPrimary),
      );
    } else if (selectable) {
      bottomStatus = Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: StitchTokens.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              CurrencyFormatter.formatIdr(slot.price),
              overflow: TextOverflow.ellipsis,
              style: StitchTokens.labelSm,
            ),
          ),
        ],
      );
    } else if (slot.status == SlotStatus.booked) {
      borderColor = StitchTokens.secondary;
      bottomStatus = Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: StitchTokens.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('Terisi', style: StitchTokens.labelSm),
        ],
      );
    } else if (slot.status == SlotStatus.held &&
        slot.holdExpiresAt != null &&
        now.isBefore(slot.holdExpiresAt!)) {
      borderColor = StitchTokens.tertiary;
      bottomStatus = Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: StitchTokens.tertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Sedang Dipesan',
              overflow: TextOverflow.ellipsis,
              style: StitchTokens.labelSm,
            ),
          ),
        ],
      );
    } else {
      bgColor = StitchTokens.surfaceElevated;
      titleColor = StitchTokens.textSecondary;
      bottomStatus = Text('Tidak Tersedia', style: StitchTokens.labelSm);
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeText,
                style: StitchTokens.bodyStrong.copyWith(color: titleColor),
              ),
              bottomStatus,
            ],
          ),
        ),
      ),
    );
  }
}
