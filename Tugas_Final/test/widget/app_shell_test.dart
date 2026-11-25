import 'package:courtmate/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman utama CourtMate menampilkan navigasi utama dan form login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CourtMateApp());
    // Lewati animasi SplashScreen (3500ms) menuju HomeShellScreen
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle();

    expect(find.text('CourtMate'), findsOneWidget);
    expect(find.text('Eksplor'), findsOneWidget);
    expect(find.text('Booking'), findsOneWidget);
    expect(find.text('Undangan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Navigasi ke tab Profil lalu buka halaman Login
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk / Registrasi'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke akun'), findsOneWidget);

    // Validasi input kosong pada form login
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });
}
