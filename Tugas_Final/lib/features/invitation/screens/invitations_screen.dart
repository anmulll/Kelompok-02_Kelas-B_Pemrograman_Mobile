import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invitation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../widgets/notifications_sheet.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final _emailController = TextEditingController();
  String? _selectedBookingId;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final provider = context.read<BookingProvider>();
    final auth = context.read<AuthProvider>();
    final invitable = provider.invitableBookings;
    final targetBookingId =
        _selectedBookingId ?? (invitable.isNotEmpty ? invitable.first.id : null);

    if (targetBookingId == null) return;

    final ok = await provider.sendInvitation(
      bookingId: targetBookingId,
      recipientEmail: _emailController.text,
      senderId: auth.currentUser?.uid ?? 'mhs_demo',
      senderName: auth.currentUser?.name ?? 'Mahasiswa CourtMate',
    );
    if (ok && mounted) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undangan bermain berhasil dikirim!')),
      );
    }
  }

  void _openNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final invitable = provider.invitableBookings;
    final activeBookingId =
        _selectedBookingId ?? (invitable.isNotEmpty ? invitable.first.id : null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Undangan Main Bareng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _openNotificationsSheet,
              icon: Badge(
                isLabelVisible: provider.unreadNotificationCount > 0,
                label: Text('${provider.unreadNotificationCount}'),
                child: const Icon(Icons.notifications_outlined, size: 18),
              ),
              label: const Text('Notifikasi'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Form kirim undangan teman berdasarkan booking aktif (A-11)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kirim Undangan ke Teman',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (invitable.isEmpty)
                  const Text(
                    'Buat booking lapangan terlebih dahulu untuk mengundang teman bermain.',
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: invitable.map((b) {
                      final selected = b.id == activeBookingId;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(
                          '${b.courtName ?? b.courtId} (${CurrencyFormatter.formatSlotTimeRange(b.startAt, b.endAt)})',
                        ),
                        onSelected: (_) {
                          setState(() => _selectedBookingId = b.id);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Teman',
                      hintText: 'contoh: teman@kampus.ac.id',
                      prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sendInvite,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Kirim Undangan'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Undangan Masuk (${provider.receivedInvitations.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (provider.receivedInvitations.isEmpty)
          const Text('Belum ada undangan masuk.')
        else
          ...provider.receivedInvitations.map((inv) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inv.senderName ?? inv.senderId} mengundang Anda bermain',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${inv.courtName ?? 'Lapangan CourtMate'} • ${inv.scheduleLabel ?? inv.bookingId}',
                    ),
                    const SizedBox(height: 8),
                    if (inv.status == InvitationStatus.pending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => provider.respondToInvitation(
                              invitationId: inv.id,
                              decision: InvitationStatus.rejected,
                            ),
                            child: const Text('Tolak'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => provider.respondToInvitation(
                              invitationId: inv.id,
                              decision: InvitationStatus.accepted,
                            ),
                            child: const Text('Terima'),
                          ),
                        ],
                      )
                    else
                      Chip(label: Text('Status: ${inv.status.value}')),
                  ],
                ),
              ),
            );
          }),

        if (provider.sentInvitations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Undangan Terkirim (${provider.sentInvitations.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...provider.sentInvitations.map(
            (inv) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.outbox_outlined),
                title: Text(inv.recipientIdentifier),
                subtitle: Text(
                  '${inv.courtName ?? ''} • Status: ${inv.status.value}',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
