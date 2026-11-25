import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/court_provider.dart';
import '../../../services/firebase_bootstrap.dart';
import '../../history/screens/booking_history_screen.dart';
import '../../invitations/screens/invitations_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ExploreTabView(),
    BookingHistoryScreen(),
    InvitationsScreen(),
    ProfileScreen(),
  ];

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

class ExploreTabView extends StatelessWidget {
  const ExploreTabView({super.key});

  static const List<String> _sports = [
    'Futsal',
    'Badminton',
    'Basket',
    'Tenis',
    'Mini Soccer',
  ];

  @override
  Widget build(BuildContext context) {
    final courtProvider = context.watch<CourtProvider>();
    final hint = FirebaseBootstrap.configurationHint;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hint != null) ...[
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari lapangan olahraga atau area kampus...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Buka Peta Sekitar',
              onPressed: () {},
              icon: const Icon(Icons.map_outlined),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sports.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = _sports[index];
              final isSelected = courtProvider.selectedSport == sport;
              return FilterChip(
                label: Text(sport),
                selected: isSelected,
                onSelected: (selected) {
                  courtProvider.setSelectedSport(selected ? sport : null);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Lapangan Terverifikasi CourtMate',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              child: Icon(Icons.sports_soccer),
            ),
            title: const Text('Contoh: GOR Kampus Arena (Mitra Terverifikasi)'),
            subtitle: const Text(
              'Futsal • Badminton — Klik untuk melihat kerangka halaman detail & pilih slot',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.courtDetail),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: const Text('Pratinjau Modul Admin / Pengelola'),
        ),
      ],
    );
  }
}
