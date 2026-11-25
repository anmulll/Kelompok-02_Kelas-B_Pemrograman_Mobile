import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddCourtScreen extends StatefulWidget {
  const AddCourtScreen({super.key});

  @override
  State<AddCourtScreen> createState() => _AddCourtScreenState();
}

class _AddCourtScreenState extends State<AddCourtScreen> {
  static const Color background = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF141516);
  static const Color elevated = Color(0xFF1C1D1F);
  static const Color primary = Color(0xFFC3F53C);
  static const Color border = Color(0xFF232528);
  static const Color textPrimary = Color(0xFFF2F3F0);
  static const Color textSecondary = Color(0xFF8B8D88);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

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

  String _selectedSport = 'Futsal';
  final Set<String> _selectedFacilities = {'Parkir', 'Toilet'};

  int _slotDuration = 60;
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRupiah(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return '';

    final number = int.tryParse(digits) ?? 0;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  Future<void> _selectTime(bool isOpening) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openTime : _closeTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primary,
              surface: surface,
              onPrimary: background,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (isOpening) {
        _openTime = selected;
      } else {
        _closeTime = selected;
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: elevated));
  }

  void _saveCourt() {
    if (!_formKey.currentState!.validate()) return;

    if (_closeTime.hour < _openTime.hour ||
        (_closeTime.hour == _openTime.hour &&
            _closeTime.minute <= _openTime.minute)) {
      _showMessage('Jam tutup harus lebih besar dari jam buka.');
      return;
    }

    setState(() => _isSaving = true);

    final courtData = {
      'name': _nameController.text.trim(),
      'sport': _selectedSport,
      'price': int.parse(
        _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ),
      'active': false,
      'verified': false,
      'image': '',
      'address': _addressController.text.trim(),
      'slotDuration': _slotDuration,
      'openTime': _formatTime(_openTime),
      'closeTime': _formatTime(_closeTime),
      'facilities': _selectedFacilities.toList(),
      'description': _descriptionController.text.trim(),
    };

    Navigator.pop(context, courtData);
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textSecondary),
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
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: textPrimary, fontSize: 14),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _sportChip(String sport) {
    final selected = _selectedSport == sport;

    return GestureDetector(
      onTap: () => setState(() => _selectedSport = sport),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : elevated,
          borderRadius: BorderRadius.circular(30),
          border: selected ? null : Border.all(color: border),
        ),
        child: Text(
          sport,
          style: TextStyle(
            color: selected ? background : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _facilityChip(String facility) {
    final selected = _selectedFacilities.contains(facility);

    return GestureDetector(
      onTap: () => _toggleFacility(facility),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : elevated,
          borderRadius: BorderRadius.circular(30),
          border: selected ? null : Border.all(color: border),
        ),
        child: Text(
          facility,
          style: TextStyle(
            color: selected ? background : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _timeButton({
    required String label,
    required TimeOfDay value,
    required bool isOpening,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          InkWell(
            onTap: () => _selectTime(isOpening),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: elevated,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 17, color: primary),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(value),
                    style: const TextStyle(color: textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Tambah Lapangan Baru',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: surface,
            side: const BorderSide(color: border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Photo placeholder
            InkWell(
              onTap: () {
                _showMessage('Fitur unggah foto akan ditambahkan selanjutnya.');
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: elevated,
                  border: Border.all(color: border, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: surface,
                      child: Icon(Icons.add_a_photo_outlined, color: primary),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tambah Foto Lapangan',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Kamera atau Galeri · Maks. 5 MB',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic information
            _sectionCard(
              title: 'Informasi Dasar',
              children: [
                _textField(
                  controller: _nameController,
                  label: 'Nama Lapangan',
                  hint: 'GOR Futsal Unhas A',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lapangan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _fieldLabel('Jenis Olahraga'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sports.map(_sportChip).toList(),
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _addressController,
                  label: 'Alamat Lengkap',
                  hint: 'Jl. Perintis Kemerdekaan KM 10, Makassar',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    _showMessage(
                      'Pemilihan titik Google Maps akan diintegrasikan nanti.',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_location_alt_outlined, color: primary),
                      SizedBox(width: 8),
                      Expanded(child: Text('Pilih Titik Lokasi di Peta')),
                      Text(
                        'Google Maps',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Operational details
            _sectionCard(
              title: 'Operasional & Harga',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _priceController,
                        label: 'Harga per Slot',
                        hint: '100000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                          _fieldLabel('Durasi Slot'),
                          DropdownButtonFormField<int>(
                            value: _slotDuration,
                            dropdownColor: elevated,
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                            ),
                            decoration: _inputDecoration('Durasi'),
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
                                setState(() => _slotDuration = value);
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
                    _timeButton(
                      label: 'Jam Buka',
                      value: _openTime,
                      isOpening: true,
                    ),
                    const SizedBox(width: 12),
                    _timeButton(
                      label: 'Jam Tutup',
                      value: _closeTime,
                      isOpening: false,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Facilities and description
            _sectionCard(
              title: 'Fasilitas & Deskripsi',
              children: [
                _fieldLabel('Fasilitas'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _facilities.map(_facilityChip).toList(),
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _descriptionController,
                  label: 'Deskripsi Singkat',
                  hint: 'Lapangan dengan fasilitas lengkap dan pencahayaan LED malam hari...',
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 24),
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
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveCourt,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: background,
                disabledBackgroundColor: primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: background,
                      ),
                    )
                  : const Text(
                      'Simpan Lapangan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
