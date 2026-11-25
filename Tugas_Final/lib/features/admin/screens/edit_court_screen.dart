import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditCourtScreen extends StatefulWidget {
  final Map<String, dynamic> court;

  const EditCourtScreen({super.key, required this.court});

  @override
  State<EditCourtScreen> createState() => _EditCourtScreenState();
}

class _EditCourtScreenState extends State<EditCourtScreen> {
  static const Color bg = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF141516);
  static const Color elevated = Color(0xFF1C1D1F);
  static const Color primary = Color(0xFFC3F53C);
  static const Color border = Color(0xFF232528);
  static const Color text = Color(0xFFF2F3F0);
  static const Color secondary = Color(0xFF8B8D88);
  static const Color error = Color(0xFFF2705B);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  final List<String> _sports = [
    'Futsal',
    'Badminton',
    'Basket',
    'Tenis',
    'Voli',
  ];

  final List<String> _facilities = [
    'Parkir',
    'Mushola',
    'Toilet',
    'Kantin',
    'Wi-Fi',
    'Ruang Ganti',
    'Tribun',
  ];

  late String _sport;
  late bool _isActive;
  late int _duration;
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;
  late Set<String> _selectedFacilities;

  @override
  void initState() {
    super.initState();

    final court = widget.court;

    _nameController = TextEditingController(
      text: court['name']?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: court['address']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: court['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: court['description']?.toString() ?? '',
    );

    _sport = _sports.contains(court['sport']) ? court['sport'] : 'Futsal';

    _isActive = court['active'] == true;
    _duration = int.tryParse(court['slotDuration']?.toString() ?? '') ?? 60;

    _openTime = _parseTime(court['openTime']?.toString(), '07:00');
    _closeTime = _parseTime(court['closeTime']?.toString(), '23:00');

    final existingFacilities = court['facilities'];

    _selectedFacilities = existingFacilities is List
        ? existingFacilities.map((e) => e.toString()).toSet()
        : {'Parkir', 'Mushola', 'Toilet', 'Kantin', 'Wi-Fi'};
  }

  TimeOfDay _parseTime(String? value, String fallback) {
    final parts = (value ?? fallback).split(':');

    if (parts.length != 2) {
      return const TimeOfDay(hour: 7, minute: 0);
    }

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 7,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool opening) async {
    final result = await showTimePicker(
      context: context,
      initialTime: opening ? _openTime : _closeTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: primary,
            surface: surface,
            onPrimary: bg,
            onSurface: text,
          ),
        ),
        child: child!,
      ),
    );

    if (result == null) return;

    setState(() {
      if (opening) {
        _openTime = result;
      } else {
        _closeTime = result;
      }
    });
  }

  void _toggleFacility(String facility) {
    setState(() {
      if (_selectedFacilities.contains(facility)) {
        _selectedFacilities.remove(facility);
      } else {
        _selectedFacilities.add(facility);
      }
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: secondary),
      filled: true,
      fillColor: elevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary),
      ),
    );
  }

  Widget _label(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        value.toUpperCase(),
        style: const TextStyle(
          color: secondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: text, fontSize: 14),
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_label(title), const SizedBox(height: 16), ...children],
      ),
    );
  }

  Widget _sportChip(String value) {
    final selected = _sport == value;

    return GestureDetector(
      onTap: () => setState(() => _sport = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : elevated,
          borderRadius: BorderRadius.circular(30),
          border: selected ? null : Border.all(color: border),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected ? bg : secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _facilityChip(String value) {
    final selected = _selectedFacilities.contains(value);

    return GestureDetector(
      onTap: () => _toggleFacility(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : elevated,
          borderRadius: BorderRadius.circular(30),
          border: selected ? null : Border.all(color: border),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected ? bg : secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay time, bool opening) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          InkWell(
            onTap: () => _pickTime(opening),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: elevated,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: primary, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(time),
                    style: const TextStyle(color: text, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_closeTime.hour < _openTime.hour ||
        (_closeTime.hour == _openTime.hour &&
            _closeTime.minute <= _openTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam tutup harus lebih besar dari jam buka.'),
        ),
      );
      return;
    }

    final updatedCourt = Map<String, dynamic>.from(widget.court);

    updatedCourt.addAll({
      'name': _nameController.text.trim(),
      'sport': _sport,
      'address': _addressController.text.trim(),
      'price': int.parse(
        _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ),
      'active': _isActive,
      'slotDuration': _duration,
      'openTime': _formatTime(_openTime),
      'closeTime': _formatTime(_closeTime),
      'facilities': _selectedFacilities.toList(),
      'description': _descriptionController.text.trim(),
    });

    Navigator.pop(context, updatedCourt);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.court['image']?.toString() ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text(
          'Edit Data Lapangan',
          style: TextStyle(color: text, fontSize: 16),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isActive ? primary.withValues(alpha: 0.12) : elevated,
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: Text(
              _isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: _isActive ? primary : secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Operational status
            _card('Status Operasional', [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktifkan Lapangan untuk Reservasi',
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Jika dinonaktifkan, mahasiswa tidak dapat melihat atau memesan slot baru.',
                          style: TextStyle(
                            color: secondary,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: bg,
                    activeTrackColor: primary,
                    inactiveThumbColor: secondary,
                    inactiveTrackColor: elevated,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),

            // Photo preview
            Container(
              decoration: BoxDecoration(
                color: surface,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.sports_soccer,
                                color: secondary,
                                size: 48,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.sports_soccer,
                              color: secondary,
                              size: 48,
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Foto utama lapangan',
                            style: TextStyle(color: secondary, fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fitur ganti foto akan ditambahkan nanti.',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Ganti',
                            style: TextStyle(color: text),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              widget.court['image'] = '';
                            });
                          },
                          child: const Text(
                            'Hapus',
                            style: TextStyle(color: error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Basic information
            _card('Informasi Dasar', [
              _field(
                label: 'Nama Lapangan',
                controller: _nameController,
                hint: 'Nama lapangan',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama lapangan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Jenis Olahraga'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sports.map(_sportChip).toList(),
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Alamat Lengkap',
                controller: _addressController,
                hint: 'Alamat lapangan',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Integrasi Google Maps akan ditambahkan.'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: primary),
                    SizedBox(width: 8),
                    Expanded(child: Text('Ubah Titik Lokasi')),
                    Text(
                      'Google Maps',
                      style: TextStyle(color: secondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Operational details
            _card('Operasional & Fasilitas', [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'Harga per Slot',
                      controller: _priceController,
                      hint: '120000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga wajib diisi';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Harga tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Durasi Slot'),
                        DropdownButtonFormField<int>(
                          value: _duration,
                          dropdownColor: elevated,
                          style: const TextStyle(color: text, fontSize: 13),
                          decoration: _decoration('Durasi'),
                          items: const [
                            DropdownMenuItem(
                              value: 60,
                              child: Text('60 Menit'),
                            ),
                            DropdownMenuItem(
                              value: 90,
                              child: Text('90 Menit'),
                            ),
                            DropdownMenuItem(
                              value: 120,
                              child: Text('120 Menit'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _duration = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _timeField('Jam Buka', _openTime, true),
                  const SizedBox(width: 12),
                  _timeField('Jam Tutup', _closeTime, false),
                ],
              ),
              const SizedBox(height: 16),
              _label('Fasilitas Terpilih'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _facilities.map(_facilityChip).toList(),
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Deskripsi Singkat',
                controller: _descriptionController,
                hint: 'Deskripsi fasilitas dan kondisi lapangan',
                maxLines: 4,
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: text,
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: border),
                  ),
                  child: const Text('Batalkan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: bg,
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
