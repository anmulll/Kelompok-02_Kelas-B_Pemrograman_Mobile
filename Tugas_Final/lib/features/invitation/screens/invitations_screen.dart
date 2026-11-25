import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invitation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../booking/widgets/stitch_ui.dart';
import 'notifications_screen.dart';

/// Layar 7 Stitch: `CourtMate — Undangan Bermain` (`node_9094396179186302412`)
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  InvitationStatus _activeTab = InvitationStatus.pending;
  final _emailController = TextEditingController();
  String? _selectedBookingId;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendQuickInvite() async {
    final provider = context.read<BookingProvider>();
    final auth = context.read<AuthProvider>();
    final invitable = provider.invitableBookings;
    final targetId =
        _selectedBookingId ?? (invitable.isNotEmpty ? invitable.first.id : null);
    if (targetId == null) return;

    final ok = await provider.sendInvitation(
      bookingId: targetId,
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CM';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final filteredIncoming = provider.receivedInvitations
        .where((item) => item.status == _activeTab)
        .toList();
    final invitable = provider.invitableBookings;
    final currentBookingId =
        _selectedBookingId ?? (invitable.isNotEmpty ? invitable.first.id : null);

    const tabs = <(String, InvitationStatus)>[
      ('Menunggu', InvitationStatus.pending),
      ('Diterima', InvitationStatus.accepted),
      ('Ditolak', InvitationStatus.rejected),
    ];

    return StitchScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky Header + Segmented 3-Column Tab Filter (Stitch)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                    const Expanded(
                      child: Text(
                        'Undangan Bermain',
                        style: StitchTokens.h2,
                      ),
                    ),
                    Text(
                      '${filteredIncoming.length} ${_tabWord(_activeTab)}',
                      style: StitchTokens.labelSm,
                    ),
                    const SizedBox(width: 10),
                    // Pintasan ke layar penuh Notifikasi Stitch
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(
                        StitchTokens.radiusMd,
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: StitchTokens.surface,
                          borderRadius: BorderRadius.circular(
                            StitchTokens.radiusMd,
                          ),
                          border: Border.all(color: StitchTokens.border),
                        ),
                        alignment: Alignment.center,
                        child: Badge(
                          backgroundColor: StitchTokens.primary,
                          textColor: StitchTokens.onPrimary,
                          isLabelVisible: provider.unreadNotificationCount > 0,
                          label: Text('${provider.unreadNotificationCount}'),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: StitchTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Segmented Control 3 Kolom (`rounded-pill` `bg-surface-elevated`)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: StitchTokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      StitchTokens.radiusPill,
                    ),
                  ),
                  child: Row(
                    children: tabs.map((entry) {
                      final (label, status) = entry;
                      final selected = _activeTab == status;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeTab = status),
                          borderRadius: BorderRadius.circular(
                            StitchTokens.radiusPill,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 36),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? StitchTokens.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                StitchTokens.radiusPill,
                              ),
                            ),
                            child: Text(
                              label,
                              style: StitchTokens.labelSm.copyWith(
                                color: selected
                                    ? StitchTokens.onPrimary
                                    : StitchTokens.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (filteredIncoming.isEmpty)
                  StitchCard(
                    child: Text(
                      'Tidak ada undangan masuk berstatus ${_tabWord(_activeTab)}.',
                      textAlign: TextAlign.center,
                      style: StitchTokens.bodyMd.copyWith(
                        color: StitchTokens.textSecondary,
                      ),
                    ),
                  )
                else
                  ...filteredIncoming.map((inv) {
                    final senderLabel = inv.senderName ?? inv.senderId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StitchCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: StitchTokens.surfaceElevated,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: StitchTokens.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _initials(senderLabel),
                                    style: StitchTokens.bodyStrong.copyWith(
                                      color: StitchTokens.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Diundang oleh',
                                        style: StitchTokens.labelSm,
                                      ),
                                      Text(
                                        senderLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: StitchTokens.bodyStrong,
                                      ),
                                    ],
                                  ),
                                ),
                                StitchInvitationBadge(status: inv.status),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: StitchTokens.surfaceElevated,
                                borderRadius: BorderRadius.circular(
                                  StitchTokens.radiusMd,
                                ),
                                border: Border.all(color: StitchTokens.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.courtName ?? 'Lapangan CourtMate',
                                    style: StitchTokens.bodyStrong,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: StitchTokens.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          inv.scheduleLabel ?? inv.bookingId,
                                          style: StitchTokens.labelSm,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (inv.status == InvitationStatus.pending) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  StitchSecondaryButton(
                                    label: 'Tolak',
                                    onPressed: () =>
                                        provider.respondToInvitation(
                                          invitationId: inv.id,
                                          decision: InvitationStatus.rejected,
                                        ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: StitchPrimaryButton(
                                      label: 'Terima Undangan',
                                      onPressed: () =>
                                          provider.respondToInvitation(
                                            invitationId: inv.id,
                                            decision: InvitationStatus.accepted,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 12),

                // Kartu Kirim Undangan dari Booking Aktif
                if (invitable.isNotEmpty)
                  StitchCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AJAK TEMAN MAIN',
                              style: StitchTokens.labelSm,
                            ),
                            Text(
                              '${provider.sentInvitations.length} terkirim',
                              style: StitchTokens.labelSm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: invitable.map((b) {
                            final chosen = b.id == currentBookingId;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedBookingId = b.id),
                              borderRadius: BorderRadius.circular(
                                StitchTokens.radiusPill,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: chosen
                                      ? StitchTokens.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : StitchTokens.surfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                    StitchTokens.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: chosen
                                        ? StitchTokens.primary
                                        : StitchTokens.border,
                                  ),
                                ),
                                child: Text(
                                  '${b.courtName ?? b.courtId} · ${CurrencyFormatter.formatSlotTimeRange(b.startAt, b.endAt)}',
                                  style: StitchTokens.labelSm.copyWith(
                                    color: chosen
                                        ? StitchTokens.primary
                                        : StitchTokens.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
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
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            provider.errorMessage!,
                            style: StitchTokens.labelSm.copyWith(
                              color: StitchTokens.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        StitchPrimaryButton(
                          label: 'Undang Teman',
                          onPressed: _sendQuickInvite,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tabWord(InvitationStatus status) {
    return switch (status) {
      InvitationStatus.pending => 'menunggu',
      InvitationStatus.accepted => 'diterima',
      InvitationStatus.rejected => 'ditolak',
      InvitationStatus.cancelled => 'dibatalkan',
    };
  }
}
