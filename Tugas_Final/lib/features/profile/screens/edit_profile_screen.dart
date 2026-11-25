import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nimInstitutionController;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _nimInstitutionController = TextEditingController(
      text: user?.nimInstitution ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nimInstitutionController.dispose();
    super.dispose();
  }

  static const Color backgroundColor = Color(0xFF0B0B0C);
  static const Color surfaceColor = Color(0xFF141516);
  static const Color elevatedColor = Color(0xFF1C1D1F);
  static const Color primaryColor = Color(0xFFC3F53C);
  static const Color borderColor = Color(0xFF232528);
  static const Color textColor = Color(0xFFF2F3F0);
  static const Color secondaryColor = Color(0xFF8B8D88);

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      nimInstitution: _nimInstitutionController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: Color(0xFF242A18),
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Gagal menyimpan profil.'),
          backgroundColor: const Color(0xFF6D2822),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? elevatedColor : const Color(0xFF111213),
      hintStyle: const TextStyle(color: secondaryColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
    );
  }

  Widget _buildLabel(String label, {String? optional}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (optional != null) ...[
            const SizedBox(width: 6),
            Text(
              optional,
              style: const TextStyle(color: secondaryColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: elevatedColor,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _avatarFallback(initials),
                  )
                : _avatarFallback(initials),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: backgroundColor,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: textColor),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: Column(
                  children: [
                    _buildAvatar(user?.photoUrl, user?.name ?? ''),
                    const SizedBox(height: 12),
                    const Text(
                      'Ketuk ikon kamera untuk ganti foto',
                      style: TextStyle(color: secondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
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
                    _buildLabel('Nama Lengkap'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: textColor),
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        hint: 'Masukkan nama lengkap',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: secondaryColor,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _buildLabel('Email'),
                    TextFormField(
                      initialValue: user?.email ?? '',
                      enabled: false,
                      style: const TextStyle(color: secondaryColor),
                      decoration: _inputDecoration(
                        hint: 'Email akun',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: secondaryColor,
                        ),
                        suffixIcon: const Icon(
                          Icons.lock_outline,
                          color: secondaryColor,
                          size: 18,
                        ),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Email akun mahasiswa tidak dapat diubah.',
                      style: TextStyle(color: secondaryColor, fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    _buildLabel('Nomor WhatsApp / HP', optional: '(Opsional)'),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: textColor),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        hint: '08xxxxxxxxxx',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildLabel('NIM / Instansi', optional: '(Opsional)'),
                    TextFormField(
                      controller: _nimInstitutionController,
                      style: const TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        hint: 'Masukkan NIM atau instansi',
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: backgroundColor,
                    disabledBackgroundColor: primaryColor.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: backgroundColor,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
