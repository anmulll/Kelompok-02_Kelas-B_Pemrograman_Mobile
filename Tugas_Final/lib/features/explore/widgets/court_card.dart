import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/court_model.dart';

class CourtCard extends StatelessWidget {
  const CourtCard({
    super.key,
    required this.court,
    this.distanceKm,
    required this.onTap,
  });

  final CourtModel court;
  final double? distanceKm;
  final VoidCallback onTap;

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isVerified = court.canBeBooked;
    final sportText = court.sportTypes.isNotEmpty
        ? court.sportTypes.join(', ').toUpperCase()
        : 'OLAHRAGA';
    final distanceText = distanceKm != null
        ? ' · ${distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km'
        : '';
    final price = court.startingHourlyPrice;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBanner(isVerified),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$sportText$distanceText',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(isVerified: isVerified),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    court.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (court.addressDisplay.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      court.addressDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVerified ? 'Mulai dari' : 'Sumber lokasi',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isVerified && price != null
                                  ? '${_rupiahFormat.format(price)}/jam'
                                  : isVerified
                                      ? 'Lihat jadwal & harga'
                                      : 'Belum terdaftar booking',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isVerified
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isVerified)
                        FilledButton(
                          onPressed: onTap,
                          child: const Text('Pesan'),
                        )
                      else
                        OutlinedButton(
                          onPressed: onTap,
                          child: const Text('Lihat Info'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(bool isVerified) {
    final primarySport = court.sportTypes.isNotEmpty
        ? court.sportTypes.first.toLowerCase()
        : '';
    IconData sportIcon = Icons.sports;
    if (primarySport.contains('futsal') || primarySport.contains('soccer')) {
      sportIcon = Icons.sports_soccer;
    } else if (primarySport.contains('badminton')) {
      sportIcon = Icons.sports_tennis;
    } else if (primarySport.contains('basket')) {
      sportIcon = Icons.sports_basketball;
    } else if (primarySport.contains('tenis')) {
      sportIcon = Icons.sports_baseball;
    }

    return Container(
      height: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVerified
              ? const [Color(0xFF1A2210), Color(0xFF141516)]
              : const [Color(0xFF1E1A2E), Color(0xFF141516)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              sportIcon,
              size: 44,
              color: isVerified
                  ? AppColors.primary.withValues(alpha: 0.75)
                  : AppColors.secondary.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isVerified ? Colors.transparent : AppColors.border,
        ),
      ),
      child: Text(
        isVerified ? 'Terdaftar CourtMate' : 'Info Google Maps',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isVerified ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
