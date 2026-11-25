import 'package:courtmate/core/theme/app_theme.dart';
import 'package:courtmate/features/courts/screens/court_detail_screen.dart';
import 'package:courtmate/features/courts/screens/slot_selection_screen.dart';
import 'package:courtmate/features/explore/screens/explore_screen.dart';
import 'package:courtmate/features/explore/screens/map_view_screen.dart';
import 'package:courtmate/providers/court_provider.dart';
import 'package:courtmate/services/court_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrapWithProvider(Widget child, CourtProvider provider) {
  return ChangeNotifierProvider<CourtProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  group('Widget Test Modul Caca (CT-01..CT-07)', () {
    testWidgets('ExploreTabView menampilkan filter, pencarian, dan empty state (CT-01, CT-02)', (
      WidgetTester tester,
    ) async {
      final provider = CourtProvider(
        repository: CourtRepository(useDemoFallbackWhenOffline: true),
      );
      provider.updateCourts(CourtRepository.demoCourts);
      provider.updatePlacesResults(CourtRepository.demoPlacesOnly);

      await tester.pumpWidget(
        _wrapWithProvider(
          const Scaffold(body: ExploreTabView(autoInitialize: false)),
          provider,
        ),
      );

      expect(find.text('Jelajah'), findsOneWidget);
      expect(find.text('Arena Futsal Kampus Merdeka'), findsOneWidget);
      expect(find.text('4 lokasi'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Lapangan Basket Taman Kota'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Lapangan Basket Taman Kota'), findsOneWidget);

      // Kembali ke atas agar search bar dan chip filter terlihat
      await tester.scrollUntilVisible(
        find.text('Badminton'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );

      // Filter kategori Badminton
      await tester.tap(find.text('Badminton'));
      await tester.pump();
      expect(find.text('GOR Badminton Nusantara'), findsOneWidget);
      expect(find.text('Arena Futsal Kampus Merdeka'), findsNothing);

      // Pencarian tanpa hasil -> Empty state
      await tester.scrollUntilVisible(
        find.byType(TextField),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'Tidak Ditemukan');
      await tester.pump();
      expect(find.text('Tidak ada lapangan yang sesuai pencarian'), findsOneWidget);

      // Reset filter mengembalikan daftar
      await tester.tap(find.text('Reset Filter'));
      await tester.pump();
      expect(find.text('Arena Futsal Kampus Merdeka'), findsOneWidget);
    });

    testWidgets('MapViewScreen menampilkan legend, pencarian, dan ringkasan tempat', (
      WidgetTester tester,
    ) async {
      final provider = CourtProvider(
        repository: CourtRepository(useDemoFallbackWhenOffline: true),
      );
      provider.updateCourts(CourtRepository.demoCourts);

      await tester.pumpWidget(
        _wrapWithProvider(const MapViewScreen(useMapPlaceholder: true), provider),
      );
      await tester.pump();

      expect(find.text('Terdaftar CourtMate'), findsWidgets);
      expect(find.text('Umum (Maps)'), findsOneWidget);
      expect(find.text('Lokasi Saya'), findsOneWidget);
      expect(find.text('Lihat Detail'), findsOneWidget);
    });

    testWidgets('CT-05: CourtDetailScreen untuk Places umum tidak menampilkan tombol booking', (
      WidgetTester tester,
    ) async {
      final placesCourt = CourtRepository.demoPlacesOnly.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CourtDetailScreen(court: placesCourt),
        ),
      );

      expect(find.text('Lapangan Basket Taman Kota'), findsOneWidget);
      expect(find.text('Info Google Maps'), findsOneWidget);
      expect(find.text('BELUM TERDAFTAR DI COURTMATE'), findsOneWidget);
      expect(find.text('Pilih Jadwal & Slot'), findsNothing);
    });

    testWidgets('CT-06: CourtDetailScreen untuk court verified menampilkan info sewa & tombol slot', (
      WidgetTester tester,
    ) async {
      final verifiedCourt = CourtRepository.demoCourts.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CourtDetailScreen(court: verifiedCourt),
        ),
      );

      expect(find.text('Arena Futsal Kampus Merdeka'), findsOneWidget);
      expect(find.text('Aktif & Terverifikasi'), findsOneWidget);
      expect(find.text('INFORMASI SEWA'), findsOneWidget);
      expect(find.text('FASILITAS LAPANGAN'), findsOneWidget);
      expect(find.text('Pilih Jadwal & Slot'), findsOneWidget);
    });

    testWidgets('SlotSelectionScreen menampilkan legenda & mengaktifkan tombol setelah pilih slot', (
      WidgetTester tester,
    ) async {
      final verifiedCourt = CourtRepository.demoCourts.first;
      final referenceNow = DateTime(2026, 11, 25, 7, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: SlotSelectionScreen(
            court: verifiedCourt,
            repository: CourtRepository(useDemoFallbackWhenOffline: true),
            referenceNow: referenceNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tersedia / Dipilih'), findsOneWidget);
      expect(find.text('Sedang Dipesan'), findsWidgets);
      expect(find.text('Terisi'), findsWidgets);

      // Tombol Lanjut Booking disabled sebelum slot dipilih
      final buttonBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Lanjut Booking'),
      );
      expect(buttonBefore.onPressed, isNull);

      // Pilih slot 10:00–11:00 yang tersedia
      await tester.tap(find.text('10:00–11:00'));
      await tester.pump();

      final buttonAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Lanjut Booking'),
      );
      expect(buttonAfter.onPressed, isNotNull);
    });
  });
}
