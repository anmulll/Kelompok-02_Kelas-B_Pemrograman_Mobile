import 'package:flutter/material.dart';

import 'manage_courts_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const Color backgroundColor = Color(0xFF0B0B0C);
  static const Color surfaceColor = Color(0xFF141516);
  static const Color elevatedColor = Color(0xFF1C1D1F);
  static const Color primaryColor = Color(0xFFC3F53C);
  static const Color secondaryColor = Color(0xFF8B8D88);
  static const Color textColor = Color(0xFFF2F3F0);
  static const Color borderColor = Color(0xFF232528);
  static const Color orangeColor = Color(0xFFF5A65B);
  static const Color errorColor = Color(0xFFF2705B);

  final List<Map<String, dynamic>> _reservations = [
    {
      'court': 'Arena Futsal Merdeka',
      'customer': 'Budi S.',
      'time': '19:00–20:00',
      'status': 'Terkonfirmasi',
      'statusType': 'success',
    },
    {
      'court': 'GOR Badminton Nusantara',
      'customer': 'Dina L.',
      'time': '16:00–17:00',
      'status': 'Menunggu Bayar',
      'statusType': 'warning',
    },
    {
      'court': 'Tenis Club Senayan',
      'customer': 'Raka P.',
      'time': '08:00–09:00',
      'status': 'Dibatalkan',
      'statusType': 'error',
    },
  ];

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    IconData icon = Icons.analytics_outlined,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(icon, size: 17, color: secondaryColor),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: secondaryColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String statusType) {
    Color color;
    Color background;

    switch (statusType) {
      case 'warning':
        color = orangeColor;
        background = elevatedColor;
        break;
      case 'error':
        color = errorColor;
        background = elevatedColor;
        break;
      default:
        color = primaryColor;
        background = primaryColor.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: statusType == 'success'
            ? null
            : Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReservationItem(Map<String, dynamic> reservation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stadium_outlined,
              color: secondaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation['court'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${reservation['customer']} · ${reservation['time']}',
                  style: const TextStyle(color: secondaryColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(reservation['status'], reservation['statusType']),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _buildMetricCard(
              title: 'Booking Hari Ini',
              value: '18',
              subtitle: '+4 dari kemarin',
              icon: Icons.calendar_today_outlined,
            ),
            _buildMetricCard(
              title: 'Transaksi Lunas',
              value: 'Rp 2,4 jt',
              subtitle: '16 terkonfirmasi',
              icon: Icons.payments_outlined,
            ),
            _buildMetricCard(
              title: 'Lapangan Aktif',
              value: '4 / 5',
              subtitle: '1 nonaktif',
              icon: Icons.stadium_outlined,
            ),
            _buildMetricCard(
              title: 'Tingkat Okupansi',
              value: '78%',
              subtitle: 'Puncak 19:00',
              icon: Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RESERVASI TERBARU',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Pantauan langsung',
                    style: TextStyle(color: secondaryColor, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_reservations.length, (index) {
                return Column(
                  children: [
                    _buildReservationItem(_reservations[index]),
                    if (index != _reservations.length - 1)
                      const Divider(color: borderColor, height: 1),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent() {
    final titles = ['Dashboard', 'Kelola Lapangan', 'Jadwal', 'Reservasi'];

    final descriptions = [
      '',
      'Kelola informasi, fasilitas, harga, dan status lapangan.',
      'Atur jadwal operasional dan ketersediaan slot lapangan.',
      'Pantau dan kelola seluruh reservasi pengguna.',
    ];

    final icons = [
      Icons.dashboard_outlined,
      Icons.stadium_outlined,
      Icons.schedule_outlined,
      Icons.receipt_long_outlined,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icons[_selectedIndex], color: primaryColor, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              titles[_selectedIndex],
              style: const TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descriptions[_selectedIndex],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: const Text(
                'Modul belum tersedia',
                style: TextStyle(color: secondaryColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {
        'label': 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'activeIcon': Icons.dashboard,
      },
      {
        'label': 'Lapangan',
        'icon': Icons.stadium_outlined,
        'activeIcon': Icons.stadium,
      },
      {
        'label': 'Jadwal',
        'icon': Icons.schedule_outlined,
        'activeIcon': Icons.schedule,
      },
      {
        'label': 'Reservasi',
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = items[index];

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          isSelected
                              ? item['activeIcon'] as IconData
                              : item['icon'] as IconData,
                          color: isSelected ? backgroundColor : secondaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSelected ? textColor : secondaryColor,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Halo, Pengelola',
      'Kelola Lapangan',
      'Jadwal',
      'Reservasi',
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel Pengelola',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              titles[_selectedIndex],
              style: const TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Admin Pengelola',
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboardContent()
          : _selectedIndex == 1
          ? const ManageCourtsScreen()
          : _buildPlaceholderContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}
