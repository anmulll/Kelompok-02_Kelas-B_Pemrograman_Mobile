import 'package:courtmate/core/routes/app_routes.dart';
import 'package:courtmate/core/theme/app_theme.dart';
import 'package:courtmate/providers/auth_provider.dart';
import 'package:courtmate/providers/booking_provider.dart';
import 'package:courtmate/providers/court_provider.dart';
import 'package:courtmate/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestApp(BookingProvider bookingProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourtProvider()),
        ChangeNotifierProvider.value(value: bookingProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.booking,
        routes: AppRoutes.routes,
      ),
    );
  }

  testWidgets('Alur UI Modul Anmul: pilih slot besok -> tahan slot -> halaman DOKU Checkout & proteksi AT-11', (
    WidgetTester tester,
  ) async {
    final bookingProvider = BookingProvider(
      paymentService: PaymentService(urlLauncher: (_) async => true),
      useLocalSandbox: true,
    );
    bookingProvider.selectDate(DateTime.now().add(const Duration(days: 1)));

    await tester.pumpWidget(buildTestApp(bookingProvider));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Jadwal Slot'), findsOneWidget);
    expect(find.text('08:00 - 09:00'), findsOneWidget);

    // Pilih slot 08:00 - 09:00
    await tester.tap(find.text('08:00 - 09:00'));
    await tester.pump();

    // Tekan tombol Tahan Slot & Lanjut ke DOKU Checkout
    await tester.tap(find.text('Tahan Slot & Lanjut ke DOKU Checkout'));
    await tester.pumpAndSettle();

    // Berpindah ke layar PaymentScreen
    expect(find.text('Pembayaran DOKU Checkout'), findsOneWidget);
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.text('Buka Halaman DOKU Checkout'), findsOneWidget);

    // Klik Buka Halaman DOKU Checkout -> pastikan status tetap Menunggu Pembayaran (AT-11)
    await tester.tap(find.text('Buka Halaman DOKU Checkout'));
    await tester.pump();

    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.textContaining('AT-11'), findsOneWidget);

    bookingProvider.dispose();
  });
}
