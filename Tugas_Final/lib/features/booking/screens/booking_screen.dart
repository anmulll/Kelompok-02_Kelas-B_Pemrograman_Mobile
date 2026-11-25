import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/slot_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';

/// Kontrak argumen navigasi dari halaman Detail Lapangan milik modul Caca (Bab 14).
class BookingScreenArgs {
  const BookingScreenArgs({
    required this.courtId,
    required this.courtName,
  });

  final String courtId;
  final String courtName;
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _didInitArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
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

  Future<void> _handleProceedToPayment() async {
    final bookingProvider = context.read<BookingProvider>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.uid ?? 'mhs_demo';

    final session = await bookingProvider.createHoldAndPayment(userId: uid);
    if (session != null && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final selectedSlot = provider.selectedSlot;
    final today = DateTime.now();
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Jadwal Slot'),
            Text(
              provider.selectedCourtName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pemilih tanggal 7 hari ke depan (FR-008)
          SizedBox(
            height: 78,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                return ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) => provider.selectDate(date),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index == 0 ? 'Hari Ini' : DateFormat('EEE').format(date),
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        DateFormat('dd MMM').format(date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Slot Tersedia • ${CurrencyFormatter.formatFullDate(provider.selectedDate)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: provider.slots.isEmpty
                ? const Center(
                    child: Text('Belum ada slot jadwal pada tanggal ini.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.slots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final slot = provider.slots[index];
                      final selectable = slot.isSelectableAt(now);
                      final isChosen = provider.selectedSlotId == slot.id;
                      final statusLabel = _slotStatusLabel(slot, now);

                      return Card(
                        color: isChosen
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          enabled: selectable,
                          onTap: selectable
                              ? () => provider.selectSlot(slot)
                              : null,
                          leading: Icon(
                            isChosen
                                ? Icons.check_circle
                                : (selectable
                                      ? Icons.access_time
                                      : Icons.lock_clock_outlined),
                          ),
                          title: Text(
                            CurrencyFormatter.formatSlotTimeRange(
                              slot.startAt,
                              slot.endAt,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(statusLabel),
                          trailing: Text(
                            CurrencyFormatter.formatIdr(slot.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total (dihitung server):'),
                      Text(
                        selectedSlot != null
                            ? CurrencyFormatter.formatIdr(selectedSlot.price)
                            : '-',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Slot akan dikunci sementara selama ${AppConstants.defaultSlotHoldMinutes} menit saat pembayaran dibuat.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (selectedSlot == null || provider.isSubmitting)
                        ? null
                        : _handleProceedToPayment,
                    icon: provider.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_outline),
                    label: const Text('Tahan Slot & Lanjut ke DOKU Checkout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _slotStatusLabel(SlotModel slot, DateTime now) {
    if (!slot.endAt.isAfter(now)) return 'Waktu sudah lewat';
    if (slot.status == SlotStatus.booked) return 'Sudah dipesan';
    if (slot.status == SlotStatus.held &&
        slot.holdExpiresAt != null &&
        now.isBefore(slot.holdExpiresAt!)) {
      return 'Sedang ditahan pengguna lain';
    }
    if (slot.status == SlotStatus.unavailable) return 'Tidak tersedia';
    return 'Tersedia untuk dipesan';
  }
}
