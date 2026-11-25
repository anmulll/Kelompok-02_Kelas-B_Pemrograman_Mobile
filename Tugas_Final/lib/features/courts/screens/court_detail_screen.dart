import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/court_model.dart';
import '../../../services/court_repository.dart';
import '../../../services/maps_service.dart';

class CourtDetailScreen extends StatelessWidget {
  const CourtDetailScreen({super.key, this.court});

  final CourtModel? court;

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    final resolvedCourt = court ??
        (routeArg is CourtModel ? routeArg : CourtRepository.demoCourts.first);

    final isVerified = resolvedCourt.canBeBooked;
    final price = resolvedCourt.startingHourlyPrice;
    final sportText = resolvedCourt.sportTypes.isNotEmpty
        ? resolvedCourt.sportTypes.join(' · ').toUpperCase()
        : 'OLAHRAGA';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header banner Stitch + Back + Badge Status
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isVerified
                          ? const [Color(0xFF1D2810), Color(0xFF141516)]
                          : const [Color(0xFF211C36), Color(0xFF141516)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.sports_soccer,
                            size: 56,
                            color: isVerified
                                ? AppColors.primary.withValues(alpha: 0.7)
                                : AppColors.secondary.withValues(alpha: 0.7),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isVerified
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.verified
                                          : Icons.info_outline,
                                      size: 16,
                                      color: isVerified
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isVerified
                                          ? 'Aktif & Terverifikasi'
                                          : 'Info Google Maps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isVerified
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card 1: Nama, Kategori, Alamat + Buka di Maps
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sportText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              resolvedCourt.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              resolvedCourt.addressDisplay.isNotEmpty
                                  ? resolvedCourt.addressDisplay
                                  : 'Alamat belum tersedia',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final ok = await MapsService()
                                      .openInExternalMaps(
                                        latitude: resolvedCourt.latitude,
                                        longitude: resolvedCourt.longitude,
                                        label: resolvedCourt.name,
                                      );
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tidak dapat membuka aplikasi peta.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                label: const Text('Buka di Maps'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!isVerified)
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.secondary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'BELUM TERDAFTAR DI COURTMATE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Lokasi ini berasal dari penemuan Google Places dan belum diverifikasi pengelola di CourtMate. Pemesanan slot online belum tersedia untuk tempat ini.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Card 2: Informasi Sewa
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'INFORMASI SEWA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: 'Jam Operasional',
                                value: resolvedCourt.openingHoursLabel,
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              _InfoRow(
                                label: 'Hari Buka',
                                value: resolvedCourt.openDaysLabel,
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              _InfoRow(
                                label: 'Harga per Jam',
                                value: price != null
                                    ? '${_rupiahFormat.format(price)} / jam'
                                    : 'Sesuai slot',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Card 3: Fasilitas Lapangan
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FASILITAS LAPANGAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (resolvedCourt.facilities.isEmpty)
                                const Text(
                                  'Belum ada data fasilitas dari pengelola.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: resolvedCourt.facilities
                                      .map((f) => _FacilityChip(label: f))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar hanya jika court.canBeBooked (BR-003)
          if (isVerified)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Mulai dari',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          price != null
                              ? _rupiahFormat.format(price)
                              : 'Lihat Slot',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.slotSelection,
                            arguments: resolvedCourt,
                          );
                        },
                        child: const Text('Pilih Jadwal & Slot'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.label});

  final String label;

  IconData _iconFor(String facility) {
    final lower = facility.toLowerCase();
    if (lower.contains('parkir')) return Icons.local_parking;
    if (lower.contains('mushola') || lower.contains('masjid')) {
      return Icons.mosque;
    }
    if (lower.contains('toilet') || lower.contains('wc')) return Icons.wc;
    if (lower.contains('kantin') || lower.contains('makan')) {
      return Icons.restaurant;
    }
    if (lower.contains('wi-fi') || lower.contains('wifi')) return Icons.wifi;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
