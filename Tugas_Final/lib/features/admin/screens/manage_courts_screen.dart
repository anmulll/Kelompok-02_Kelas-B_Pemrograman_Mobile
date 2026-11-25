import 'package:flutter/material.dart';

import 'add_court_screen.dart';
import 'edit_court_screen.dart';

class ManageCourtsScreen extends StatefulWidget {
  const ManageCourtsScreen({super.key});

  @override
  State<ManageCourtsScreen> createState() => _ManageCourtsScreenState();
}

class _ManageCourtsScreenState extends State<ManageCourtsScreen> {
  static const Color backgroundColor = Color(0xFF0B0B0C);
  static const Color surfaceColor = Color(0xFF141516);
  static const Color elevatedColor = Color(0xFF1C1D1F);
  static const Color primaryColor = Color(0xFFC3F53C);
  static const Color textColor = Color(0xFFF2F3F0);
  static const Color secondaryColor = Color(0xFF8B8D88);
  static const Color borderColor = Color(0xFF232528);
  static const Color orangeColor = Color(0xFFF5A65B);

  final List<Map<String, dynamic>> _courts = [
    {
      'name': 'Arena Futsal Kampus Merdeka',
      'sport': 'Futsal',
      'price': 120000,
      'active': true,
      'verified': true,
      'image': 'https://lh3.googleusercontent.com/aida/ALJJyrDDY9qeCWtzzmFULjRHf_Sz26gE6ffbt5EnF_1rrP80KEC1ojYHqitXb9-FKhXS5s9QJLDolAitNslBaCp0aFZbnymBdNbCDTN-Vh09vWRUA2_PgMOZbN4yhWyvx6v2SqZzns4_L502R4hpcAL6ISTFBrpvL_h1C46jQqHRuR0z0eWIn6WFpumvSY-b2hoUCi6wVj0hMtoV1Jff9lJEHQL6NUqsCrRZWA34C9gdAFCfi-q6rn7n',
    },
    {
      'name': 'GOR Badminton Nusantara',
      'sport': 'Badminton',
      'price': 65000,
      'active': true,
      'verified': false,
      'image': 'https://lh3.googleusercontent.com/aida/ALJJyrA8Je9myBc5VOkhSN9zA-bl82aTxtLV5myi5i9yWD6Rg22CAE14DGt7eu9u2EBEpl2xVIb_y29YigFCQwN79fKfjrdb7bwNF_E5787l5lOws5HEESOssDlCj79SWMaJfGctRPhTSGGRBi5zTZPbuWZc-5Bnk4DXT_GbFjGhUVVmO34fItXmNJX3HJc9Bi2Ky1VpmvOffsMol-SkeIl4olvmIDdQMMZiKMpabaRwYQO-gMoHNXC7v2d5rQ',
    },
    {
      'name': 'Tenis Club Senayan',
      'sport': 'Tenis',
      'price': 150000,
      'active': false,
      'verified': true,
      'image': 'https://lh3.googleusercontent.com/aida/ALJJyrBhbPG7mx4lQs7CYnfoLciz4pRiEDfw2WQDdDx3ALzecpQGGxKHsauAdIBr-GZScB6t5EsI7QmxDPFHaeztc5swX_f5E6c7LXPEiDdnBG0GCnBsMbJiRpaaQ5H3_5BS7ctP5iQCJSVcI3ym97aoJvR7984l5vSwqRhuJHGTt7Hu7N1zeB20pOhL3qv5KjbIXOly2nFbKTuM-Vjci5I-32k9U9WnDtQ7JYAP_vJ8TaPd0kqZ5w',
    },
  ];

  String _formatPrice(int price) {
    final digits = price.toString();
    final result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(digits[i]);
    }

    return 'Rp $result';
  }

  void _toggleCourt(int index) {
    setState(() {
      _courts[index]['active'] = !_courts[index]['active'];
    });
  }

  Future<void> _addCourt() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddCourtScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _courts.add(result);
      });
    }
  }

  Future<void> _editCourt(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditCourtScreen(court: Map<String, dynamic>.from(_courts[index])),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _courts[index] = result;
      });
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic> court) {
    final active = court['active'] as bool? ?? false;
    final verified = court['verified'] as bool? ?? false;

    if (!verified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: orangeColor),
        ),
        child: const Text(
          'Menunggu Verifikasi',
          style: TextStyle(
            color: orangeColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? primaryColor.withValues(alpha: 0.12) : elevatedColor,
        borderRadius: BorderRadius.circular(999),
        border: active ? null : Border.all(color: borderColor),
      ),
      child: Text(
        active ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: active ? primaryColor : secondaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCourtCard(int index) {
    final court = _courts[index];
    final active = court['active'] as bool? ?? false;
    final verified = court['verified'] as bool? ?? false;
    final image = court['image'] as String? ?? '';
    final price = court['price'] as int? ?? 0;
    final sport = court['sport'] as String? ?? 'Olahraga';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildImageFallback(sport),
                  )
                : _buildImageFallback(sport),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sport.toUpperCase(),
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    _buildStatusBadge(court),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  court['name']?.toString() ?? '',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: borderColor, height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tarif sewa',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatPrice(price)}/jam',
                            style: TextStyle(
                              color: active ? textColor : secondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (verified) ...[
                      GestureDetector(
                        onTap: () => _toggleCourt(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: active ? primaryColor : elevatedColor,
                            borderRadius: BorderRadius.circular(999),
                            border: active
                                ? null
                                : Border.all(color: borderColor),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 180),
                            alignment: active
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: active
                                    ? backgroundColor
                                    : secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _editCourt(index),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        backgroundColor: elevatedColor,
                        side: const BorderSide(color: borderColor),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(String sport) {
    IconData icon;

    switch (sport) {
      case 'Badminton':
      case 'Tenis':
        icon = Icons.sports_tennis;
        break;
      case 'Basket':
        icon = Icons.sports_basketball;
        break;
      case 'Voli':
        icon = Icons.sports_volleyball;
        break;
      default:
        icon = Icons.sports_soccer;
    }

    return Container(
      color: elevatedColor,
      child: Center(
        child: Icon(icon, color: primaryColor.withValues(alpha: 0.6), size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _courts
        .where((court) => court['active'] == true)
        .length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_courts.length} lapangan dikelola',
                  style: const TextStyle(color: secondaryColor, fontSize: 12),
                ),
              ),
              Text(
                '$activeCount aktif',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_courts.length, _buildCourtCard),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCourt,
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Lapangan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
