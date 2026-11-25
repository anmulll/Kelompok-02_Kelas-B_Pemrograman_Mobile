import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/invitation_model.dart';
import '../../../providers/booking_provider.dart';
import '../../booking/widgets/stitch_ui.dart';

/// Layar 6 Stitch: `CourtMate — Notifikasi` (`node_3789748499225142689`)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final items = provider.notifications;
    final unreadCount = provider.unreadNotificationCount;

    return StitchScope(
      child: Scaffold(
        backgroundColor: StitchTokens.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StitchHeaderBar(
                title: 'Notifikasi',
                onLeadingTap: () => Navigator.maybePop(context),
                trailing: TextButton(
                  onPressed: unreadCount == 0
                      ? null
                      : () => provider.markAllNotificationsRead(),
                  child: Text(
                    'Tandai semua dibaca',
                    style: StitchTokens.bodyStrong.copyWith(
                      color: unreadCount == 0
                          ? StitchTokens.textMuted
                          : StitchTokens.textPrimary,
                      decoration: TextDecoration.underline,
                      decorationColor: StitchTokens.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TERBARU', style: StitchTokens.labelSm),
                        Text(
                          '$unreadCount belum dibaca',
                          style: StitchTokens.labelSm,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Belum ada notifikasi aktivitas booking.',
                          textAlign: TextAlign.center,
                          style: StitchTokens.bodyMd.copyWith(
                            color: StitchTokens.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...items.map((notif) {
                        final isUnread = !notif.isRead;
                        final icon = _iconForType(notif.type);
                        final isErrorType =
                            notif.type == 'payment_failed_or_expired' ||
                            notif.type == 'booking_cancelled';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StitchCard(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: isUnread
                                ? StitchTokens.surfaceElevated
                                : StitchTokens.surface,
                            borderColor: isUnread
                                ? StitchTokens.primary
                                : StitchTokens.border,
                            onTap: isUnread
                                ? () => provider.markNotificationRead(notif.id)
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isUnread
                                        ? StitchTokens.primary.withValues(
                                            alpha: 0.15,
                                          )
                                        : StitchTokens.surfaceElevated,
                                    borderRadius: BorderRadius.circular(
                                      StitchTokens.radiusMd,
                                    ),
                                    border: isUnread
                                        ? null
                                        : Border.all(
                                            color: StitchTokens.border,
                                          ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 20,
                                    color: isUnread
                                        ? StitchTokens.primary
                                        : (isErrorType
                                              ? StitchTokens.error
                                              : StitchTokens.textSecondary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: StitchTokens.bodyStrong
                                                  .copyWith(
                                                    color: isUnread
                                                        ? StitchTokens
                                                              .textPrimary
                                                        : StitchTokens
                                                              .textSecondary,
                                                  ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: StitchTokens.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.body,
                                        style: StitchTokens.bodyMd.copyWith(
                                          color: StitchTokens.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat(
                                          'dd MMM, HH:mm',
                                        ).format(notif.createdAt),
                                        style: StitchTokens.labelSm,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'booking_confirmed' => Icons.check_circle_outline,
      'payment_failed_or_expired' => Icons.timer_off_outlined,
      'booking_cancelled' => Icons.cancel_outlined,
      'payment_reconciliation' => Icons.warning_amber_rounded,
      _ => Icons.notifications_outlined,
    };
  }
}

/// Alias bottom sheet ringan apabila dipanggil sebagai modal.
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 520, child: NotificationsScreen());
  }
}

// Re-export agar kode lama yang mengimpor NotificationModel via layar tetap bersih
typedef StitchNotificationItem = NotificationModel;
