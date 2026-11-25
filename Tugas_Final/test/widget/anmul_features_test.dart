import 'package:courtmate/core/routes/app_routes.dart';
import 'package:courtmate/core/theme/app_theme.dart';
import 'package:courtmate/features/courts/screens/slot_selection_screen.dart';
import 'package:courtmate/features/history/screens/booking_history_screen.dart';
import 'package:courtmate/features/invitation/screens/invitations_screen.dart';
import 'package:courtmate/providers/auth_provider.dart';
import 'package:courtmate/providers/booking_provider.dart';
import 'package:courtmate/providers/court_provider.dart';
import 'package:courtmate/services/court_repository.dart';
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
      expect(find.text('Menunggu (1)'), findsOneWidget);
      expect(find.text('Diterima (0)'), findsOneWidget);
      expect(find.text('Terima Undangan'), findsOneWidget);

      await tester.tap(find.text('Terima Undangan'));
      await tester.pumpAndSettle();

      expect(find.text('Menunggu (0)'), findsOneWidget);
      expect(find.text('Diterima (1)'), findsOneWidget);

      // Kirim undangan keluar -> harus langsung ikut menambah count Menunggu
      await bookingProvider.sendInvitation(
        bookingId: bookingProvider.invitableBookings.first.id,
        recipientEmail: 'teman@kampus.ac.id',
      );
      await tester.pumpAndSettle();

      expect(find.text('Menunggu (1)'), findsOneWidget);
      expect(find.text('Mengundang'), findsOneWidget);
      expect(find.text('teman@kampus.ac.id'), findsOneWidget);

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

  testWidgets(
    'Integrasi Caca -> Anmul: pilih slot 1x di SlotSelectionScreen langsung masuk Ringkasan Booking (tidak 2x pilih)',
    (WidgetTester tester) async {
      final bookingProvider = BookingProvider(
        paymentService: PaymentService(urlLauncher: (_) async => true),
        useLocalSandbox: true,
      );
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final fixedMorning = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 7, 0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CourtProvider()),
            ChangeNotifierProvider.value(value: bookingProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: SlotSelectionScreen(
              court: CourtRepository.demoCourts.first,
              referenceNow: fixedMorning,
            ),
            routes: {
              AppRoutes.booking: AppRoutes.routes[AppRoutes.booking]!,
              AppRoutes.payment: AppRoutes.routes[AppRoutes.payment]!,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pilih 1 slot tersedia pada layar Caca
      await tester.tap(find.text('10:00–11:00'));
      await tester.pump();

      // Tekan Lanjut Booking -> WAJIB langsung ke Ringkasan Booking, bukan Pilih Jadwal lagi
      await tester.tap(find.text('Lanjut Booking'));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan Booking'), findsOneWidget);
      expect(find.text('Pilih Jadwal & Slot'), findsNothing);
      expect(find.text('Bayar Sekarang via DOKU'), findsOneWidget);

      bookingProvider.dispose();
    },
  );

  testWidgets(
    'Tombol Ke Booking Saya di PaymentScreen langsung membuka tab Booking Saya dan membersihkan stack',
    (WidgetTester tester) async {
      final bookingProvider = BookingProvider(
        paymentService: PaymentService(urlLauncher: (_) async => true),
        useLocalSandbox: true,
      );
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final fixedMorning = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 7, 0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CourtProvider()),
            ChangeNotifierProvider.value(value: bookingProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.slotSelection,
            routes: {
              AppRoutes.home: AppRoutes.routes[AppRoutes.home]!,
              AppRoutes.slotSelection: (_) => SlotSelectionScreen(
                court: CourtRepository.demoCourts.first,
                referenceNow: fixedMorning,
              ),
              AppRoutes.booking: AppRoutes.routes[AppRoutes.booking]!,
              AppRoutes.payment: AppRoutes.routes[AppRoutes.payment]!,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('10:00–11:00'));
      await tester.pump();
      await tester.tap(find.text('Lanjut Booking'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bayar Sekarang via DOKU'));
      await tester.pumpAndSettle();
      expect(find.text('Status Pembayaran'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Ke Booking Saya'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ke Booking Saya'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingHistoryScreen), findsOneWidget);
      expect(find.text('Booking Saya'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.byType(SlotSelectionScreen), findsNothing);

      bookingProvider.dispose();
    },
  );
}
