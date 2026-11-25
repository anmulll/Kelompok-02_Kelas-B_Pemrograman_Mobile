import 'package:courtmate/core/routes/app_routes.dart';
import 'package:courtmate/core/theme/app_theme.dart';
import 'package:courtmate/features/history/screens/booking_history_screen.dart';
import 'package:courtmate/features/invitation/screens/invitations_screen.dart';
import 'package:courtmate/providers/auth_provider.dart';
import 'package:courtmate/providers/booking_provider.dart';
import 'package:courtmate/providers/court_provider.dart';
import 'package:courtmate/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget wrapWithProviders(
    BookingProvider bookingProvider, {
    String? initialRoute,
    Widget? home,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourtProvider()),
        ChangeNotifierProvider.value(value: bookingProvider),
      ],
      child: home != null
          ? MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: home))
          : MaterialApp(
              theme: AppTheme.lightTheme,
              initialRoute: initialRoute ?? AppRoutes.booking,
              routes: AppRoutes.routes,
            ),
    );
  }

  testWidgets(
    'Alur Stitch 1-3: Pilih Jadwal & Slot -> Ringkasan Booking -> Status Pembayaran & AT-11',
    (WidgetTester tester) async {
      final bookingProvider = BookingProvider(
        paymentService: PaymentService(urlLauncher: (_) async => true),
        useLocalSandbox: true,
      );
      bookingProvider.selectDate(DateTime.now().add(const Duration(days: 1)));

      await tester.pumpWidget(wrapWithProviders(bookingProvider));
      await tester.pumpAndSettle();

      // Layar 1 Stitch: Pilih Jadwal & Slot
      expect(find.text('Pilih Jadwal & Slot'), findsOneWidget);
      expect(find.text('08:00 - 09:00'), findsOneWidget);

      await tester.tap(find.text('08:00 - 09:00'));
      await tester.pump();
      expect(find.textContaining('· Dipilih'), findsOneWidget);

      await tester.tap(find.text('Lanjut Booking'));
      await tester.pumpAndSettle();

      // Layar 2 Stitch: Ringkasan Booking
      expect(find.text('Ringkasan Booking'), findsOneWidget);
      expect(find.text('DETAIL PESANAN'), findsOneWidget);
      expect(find.text('RINCIAN BIAYA'), findsOneWidget);

      await tester.tap(find.text('Bayar Sekarang via DOKU'));
      await tester.pumpAndSettle();

      // Layar 3 Stitch: Status Pembayaran
      expect(find.text('Status Pembayaran'), findsOneWidget);
      expect(find.text('Menunggu Verifikasi Pembayaran'), findsOneWidget);

      // Buka DOKU Checkout -> pastikan status tetap Menunggu Pembayaran (AT-11)
      await tester.tap(find.text('Buka Halaman DOKU Checkout'));
      await tester.pump();

      expect(find.text('Menunggu Pembayaran'), findsOneWidget);
      expect(find.textContaining('Proteksi AT-11 aktif'), findsOneWidget);

      bookingProvider.dispose();
    },
  );

  testWidgets(
    'Alur Stitch 4-5: Booking Saya -> buka Detail Booking -> form Undang Teman & Ajukan Pembatalan',
    (WidgetTester tester) async {
      final bookingProvider = BookingProvider(useLocalSandbox: true);

      await tester.pumpWidget(
        wrapWithProviders(bookingProvider, home: const BookingHistoryScreen()),
      );
      await tester.pumpAndSettle();

      // Layar 4 Stitch: Booking Saya
      expect(find.text('Booking Saya'), findsOneWidget);
      expect(find.text('GOR Kampus Arena'), findsOneWidget);

      await tester.tap(find.text('GOR Kampus Arena'));
      await tester.pumpAndSettle();

      // Layar 5 Stitch: Detail Booking
      expect(find.text('Detail Booking'), findsOneWidget);
      expect(find.text('INFORMASI BOOKING'), findsOneWidget);
      expect(find.text('UNDANG TEMAN BERMAIN'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Ajukan Pembatalan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ajukan Pembatalan'), findsOneWidget);

      bookingProvider.dispose();
    },
  );

  testWidgets(
    'Alur Stitch 6-7: Undangan Bermain -> Terima Undangan -> buka Notifikasi & Tandai semua dibaca',
    (WidgetTester tester) async {
      final bookingProvider = BookingProvider(useLocalSandbox: true);

      await tester.pumpWidget(
        wrapWithProviders(bookingProvider, home: const InvitationsScreen()),
      );
      await tester.pumpAndSettle();

      // Layar 7 Stitch: Undangan Bermain
      expect(find.text('Undangan Bermain'), findsOneWidget);
      expect(find.text('Terima Undangan'), findsOneWidget);

      await tester.tap(find.text('Terima Undangan'));
      await tester.pumpAndSettle();

      // Buka Layar 6 Stitch: Notifikasi melalui ikon lonceng
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Tandai semua dibaca'), findsOneWidget);
      expect(bookingProvider.unreadNotificationCount, greaterThan(0));

      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(bookingProvider.unreadNotificationCount, 0);

      bookingProvider.dispose();
    },
  );
}
