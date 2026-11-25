import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/court_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/court_provider.dart';
import '../../../services/firebase_bootstrap.dart';
import '../../../services/location_service.dart';
import '../../history/screens/booking_history_screen.dart';
import '../../invitation/screens/invitations_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/court_card.dart';
import '../widgets/sport_category_list.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  late int _selectedIndex;
  bool _didInitRouteTab = false;

  static const List<Widget> _pages = [
    ExploreTabView(),
    BookingHistoryScreen(),
    InvitationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, _pages.length - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitRouteTab) {
      _didInitRouteTab = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < _pages.length) {
        _selectedIndex = args;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CourtMate'),
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Panel Admin',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: auth.isAuthenticated ? 'Profil' : 'Masuk',
            onPressed: () {
              if (!auth.isAuthenticated) {
                Navigator.pushNamed(context, AppRoutes.login);
              } else {
                setState(() => _selectedIndex = 3);
              }
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Eksplor',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_add_outlined),
            selectedIcon: Icon(Icons.group_add),
            label: 'Undangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class ExploreTabView extends StatefulWidget {
  const ExploreTabView({super.key, this.autoInitialize = true});

  final bool autoInitialize;

  @override
  State<ExploreTabView> createState() => _ExploreTabViewState();
}

class _ExploreTabViewState extends State<ExploreTabView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<CourtProvider>();
        if (provider.verifiedCourts.isEmpty && !provider.isLoading) {
          provider.initializeDiscovery();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCourtDetail(CourtModel court) {
    Navigator.pushNamed(
      context,
      AppRoutes.courtDetail,
      arguments: court,
    );
  }

  @override
  Widget build(BuildContext context) {
    final courtProvider = context.watch<CourtProvider>();
    final courts = courtProvider.courts;
    final hint = FirebaseBootstrap.configurationHint;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => courtProvider.initializeDiscovery(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (hint != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Header Stitch: Brand + "Jelajah" + Tombol Peta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.sports_handball,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Jelajah',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.exploreMap),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Peta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar Stitch
          TextField(
            controller: _searchController,
            onChanged: courtProvider.setSearchQuery,
            onSubmitted: (_) => courtProvider.refreshPlaces(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari lapangan, futsal, badminton...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              suffixIcon: courtProvider.searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        courtProvider.setSearchQuery('');
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Filter kategori olahraga
          SportCategoryList(
            selectedSport: courtProvider.selectedSport,
            onSelected: courtProvider.setSelectedSport,
          ),
          const SizedBox(height: 12),

          // Bar lokasi & filter jarak (C-04, C-05)
          _LocationFilterBar(provider: courtProvider),

          if (courtProvider.placesErrorMessage != null) ...[
            const SizedBox(height: 10),
            _PlacesFallbackBanner(
              message: courtProvider.placesErrorMessage!,
              onRetry: courtProvider.refreshPlaces,
            ),
          ],

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                courtProvider.hasUserLocation
                    ? 'LAPANGAN TERDEKAT'
                    : 'DAFTAR LAPANGAN',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${courts.length} lokasi',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (courtProvider.isLoading && courts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (courtProvider.errorMessage != null && courts.isEmpty)
            _ErrorStateBox(
              message: courtProvider.errorMessage!,
              onRetry: courtProvider.initializeDiscovery,
            )
          else if (courts.isEmpty)
            _EmptyStateBox(
              onResetFilter: () {
                _searchController.clear();
                courtProvider.setSearchQuery('');
                courtProvider.setSelectedSport(null);
                courtProvider.setMaxDistanceKm(null);
              },
            )
          else
            ...courts.map(
              (court) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CourtCard(
                  court: court,
                  distanceKm: courtProvider.distanceKmFor(court),
                  onTap: () => _openCourtDetail(court),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationFilterBar extends StatelessWidget {
  const _LocationFilterBar({required this.provider});

  final CourtProvider provider;

  @override
  Widget build(BuildContext context) {
    final denied =
        provider.locationStatus == LocationAccessStatus.denied ||
        provider.locationStatus == LocationAccessStatus.deniedForever ||
        provider.locationStatus == LocationAccessStatus.serviceDisabled;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: provider.isRequestingLocation
                ? null
                : provider.requestLocation,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.hasUserLocation
                        ? Icons.my_location
                        : Icons.location_searching,
                    size: 16,
                    color: provider.hasUserLocation
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.isRequestingLocation
                          ? 'Mencari lokasi...'
                          : provider.hasUserLocation
                              ? 'Lokasi aktif · Urut terdekat'
                              : denied
                                  ? 'Izin lokasi ditolak · Pencarian teks aktif'
                                  : 'Aktifkan lokasi untuk urutkan jarak',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (provider.hasUserLocation) ...[
          const SizedBox(width: 8),
          PopupMenuButton<double?>(
            tooltip: 'Filter jarak',
            onSelected: provider.setMaxDistanceKm,
            itemBuilder: (_) => const [
              PopupMenuItem<double?>(value: null, child: Text('Semua jarak')),
              PopupMenuItem<double?>(value: 3, child: Text('Dalam 3 km')),
              PopupMenuItem<double?>(value: 5, child: Text('Dalam 5 km')),
              PopupMenuItem<double?>(value: 10, child: Text('Dalam 10 km')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: provider.maxDistanceKm != null
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: provider.maxDistanceKm != null
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text(
                provider.maxDistanceKm != null
                    ? '≤ ${provider.maxDistanceKm!.round()} km'
                    : 'Jarak',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: provider.maxDistanceKm != null
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlacesFallbackBanner extends StatelessWidget {
  const _PlacesFallbackBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _ErrorStateBox extends StatelessWidget {
  const _ErrorStateBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36, color: AppColors.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateBox extends StatelessWidget {
  const _EmptyStateBox({required this.onResetFilter});

  final VoidCallback onResetFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          const Text(
            'Tidak ada lapangan yang sesuai pencarian',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba ubah kata kunci atau reset filter kategori olahraga.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onResetFilter,
            child: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }
}
