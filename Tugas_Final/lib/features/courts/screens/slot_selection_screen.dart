import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/court_model.dart';
import '../../../models/slot_model.dart';
import '../../../services/court_repository.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({
    super.key,
    this.court,
    this.repository,
    this.referenceNow,
  });

  final CourtModel? court;
  final CourtRepository? repository;
  final DateTime? referenceNow;

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  late final CourtRepository _repository;
  late final DateTime _baseDate;
  late DateTime _selectedDate;
  SlotModel? _selectedSlot;

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const List<String> _shortDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CourtRepository();
    final now = widget.referenceNow ?? DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);
    _selectedDate = _baseDate;
  }

  String _formatTimeRange(SlotModel slot) {
    final start =
        '${slot.startAt.hour.toString().padLeft(2, '0')}:${slot.startAt.minute.toString().padLeft(2, '0')}';
    final end =
        '${slot.endAt.hour.toString().padLeft(2, '0')}:${slot.endAt.minute.toString().padLeft(2, '0')}';
    return '$start–$end';
  }

  @override
  Widget build(BuildContext context) {
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    final resolvedCourt = widget.court ??
        (routeArg is CourtModel ? routeArg : CourtRepository.demoCourts.first);
    final now = widget.referenceNow ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Jadwal & Slot',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              resolvedCourt.name,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'PILIH TANGGAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final date = _baseDate.add(Duration(days: index));
                      final isSelected = date == _selectedDate;
                      final dayName = _shortDays[date.weekday - 1];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlot = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Legenda Status Slot Stitch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _SlotLegendItem(
                        color: AppColors.primary,
                        label: 'Tersedia / Dipilih',
                      ),
                      _SlotLegendItem(
                        color: AppColors.tertiary,
                        label: 'Sedang Dipesan',
                      ),
                      _SlotLegendItem(
                        color: AppColors.secondary,
                        label: 'Terisi',
                      ),
                      _SlotLegendItem(
                        color: AppColors.textMuted,
                        label: 'Tidak Tersedia',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'PILIH SLOT WAKTU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                StreamBuilder<List<SlotModel>>(
                  stream: _repository.watchCourtSlotsForDate(
                    courtId: resolvedCourt.id,
                    date: _selectedDate,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Gagal memuat slot: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      );
                    }

                    final slots = snapshot.data ?? const [];
                    if (slots.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'Belum ada slot tersedia pada tanggal ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.1,
                          ),
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final selectable = slot.isSelectableAt(now);
                        final isSelected = _selectedSlot?.id == slot.id;

                        return _SlotTile(
                          timeRange: _formatTimeRange(slot),
                          priceText: _rupiahFormat.format(slot.price),
                          status: slot.status,
                          selectable: selectable,
                          isSelected: isSelected,
                          onTap: selectable
                              ? () => setState(() => _selectedSlot = slot)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedSlot != null
                              ? '${_formatTimeRange(_selectedSlot!)} (1 slot)'
                              : 'Belum ada slot dipilih',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _selectedSlot != null
                              ? _rupiahFormat.format(_selectedSlot!.price)
                              : 'Rp 0',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _selectedSlot == null
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.booking,
                              arguments: {
                                'court': resolvedCourt,
                                'slot': _selectedSlot,
                              },
                            );
                          },
                    child: const Text('Lanjut Booking'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotLegendItem extends StatelessWidget {
  const _SlotLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.timeRange,
    required this.priceText,
    required this.status,
    required this.selectable,
    required this.isSelected,
    this.onTap,
  });

  final String timeRange;
  final String priceText;
  final SlotStatus status;
  final bool selectable;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.border;
    Color textColor = AppColors.textPrimary;
    Color? dotColor;
    String statusLabel = priceText;

    if (isSelected) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = AppColors.background;
      statusLabel = '$priceText · Dipilih';
    } else if (selectable) {
      dotColor = AppColors.primary;
    } else if (status == SlotStatus.held) {
      borderColor = AppColors.tertiary;
      dotColor = AppColors.tertiary;
      statusLabel = 'Sedang Dipesan';
    } else if (status == SlotStatus.booked) {
      borderColor = AppColors.secondary;
      dotColor = AppColors.secondary;
      statusLabel = 'Terisi';
    } else {
      bgColor = AppColors.surfaceElevated;
      textColor = AppColors.textSecondary;
      statusLabel = 'Tidak Tersedia';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              timeRange,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Row(
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
