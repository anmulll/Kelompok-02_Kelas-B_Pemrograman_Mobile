import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/court_model.dart';
import '../../../providers/court_provider.dart';
import '../../../services/maps_service.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key, this.useMapPlaceholder = false});

  /// Digunakan saat widget testing tanpa platform view Android/iOS.
  final bool useMapPlaceholder;

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapsService _mapsService = MapsService();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  CourtModel? _selectedCourt;

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CourtProvider>();
      if (provider.courts.isNotEmpty && _selectedCourt == null) {
        setState(() => _selectedCourt = provider.courts.first);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<CourtModel> courts) {
    return courts.map((court) {
      final isVerified = court.canBeBooked;
      return Marker(
        markerId: MarkerId(court.id),
        position: LatLng(court.latitude, court.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isVerified ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueViolet,
        ),
        infoWindow: InfoWindow(
          title: court.name,
          snippet: isVerified ? 'Terdaftar CourtMate' : 'Info Google Maps',
          onTap: () => setState(() => _selectedCourt = court),
        ),
        onTap: () => setState(() => _selectedCourt = court),
      );
    }).toSet();
  }

  Future<void> _centerOnUserLocation() async {
    final provider = context.read<CourtProvider>();
    await provider.requestLocation();
    if (!mounted) return;

    if (provider.hasUserLocation) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(provider.userLatitude!, provider.userLongitude!),
          14.5,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi belum aktif. Menampilkan pencarian teks sebagai fallback.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourtProvider>();
    final courts = provider.courts;
    final selected = _selectedCourt != null &&
            courts.any((c) => c.id == _selectedCourt!.id)
        ? _selectedCourt
        : (courts.isNotEmpty ? courts.first : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.useMapPlaceholder
                ? Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.map,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: _mapsService.initialCameraPosition(
                      latitude: provider.userLatitude ?? selected?.latitude,
                      longitude: provider.userLongitude ?? selected?.longitude,
                    ),
                    style: MapsService.darkMapStyle,
                    myLocationEnabled: provider.hasUserLocation,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: _buildMarkers(courts),
                    onMapCreated: (controller) => _mapController = controller,
                  ),
          ),

          // Floating Top Search Bar + Legend
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: provider.setSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Cari di area peta ini...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            fillColor: AppColors.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    children: [
                      _LegendPill(
                        color: AppColors.primary,
                        label: 'Terdaftar CourtMate',
                        textColor: AppColors.textPrimary,
                      ),
                      _LegendPill(
                        color: AppColors.secondary,
                        label: 'Umum (Maps)',
                        textColor: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tombol Lokasi Saya + Preview Bottom Sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _centerOnUserLocation,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Lokasi Saya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 12),
                  _SelectedVenueSheet(
                    court: selected,
                    distanceKm: provider.distanceKmFor(selected),
                    rupiahFormat: _rupiahFormat,
                    onOpenDetail: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.courtDetail,
                        arguments: selected,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedVenueSheet extends StatelessWidget {
  const _SelectedVenueSheet({
    required this.court,
    required this.distanceKm,
    required this.rupiahFormat,
    required this.onOpenDetail,
  });

  final CourtModel court;
  final double? distanceKm;
  final NumberFormat rupiahFormat;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final isVerified = court.canBeBooked;
    final sport = court.sportTypes.isNotEmpty ? court.sportTypes.first : 'Olahraga';
    final dist = distanceKm != null
        ? ' · ${distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km'
        : '';
    final price = court.startingHourlyPrice;
    final priceText = isVerified && price != null
        ? ' · Mulai ${rupiahFormat.format(price)}/jam'
        : ' · Info Google Maps';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderHover,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: isVerified ? AppColors.primary : AppColors.secondary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isVerified
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        isVerified ? 'Terdaftar CourtMate' : 'Info Google Maps',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isVerified
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sport$dist$priceText',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onOpenDetail,
              child: const Text('Lihat Detail'),
            ),
          ),
        ],
      ),
    );
  }
}
