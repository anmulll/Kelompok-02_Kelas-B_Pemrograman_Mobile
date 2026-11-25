import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/booking_provider.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final items = provider.notifications;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notifikasi Reservasi & Pembayaran',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada notifikasi.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notif = items[index];
                    return ListTile(
                      leading: Icon(
                        notif.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notif.body),
                      trailing: notif.isRead
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  provider.markNotificationRead(notif.id),
                              child: const Text('Tandai Dibaca'),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
