import 'package:courtmate/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman utama CourtMate menampilkan navigasi utama dan form login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CourtMateApp());

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

    expect(find.text('Masuk ke CourtMate'), findsOneWidget);

    // Validasi input kosong pada form login
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter.'), findsOneWidget);
  });
}
