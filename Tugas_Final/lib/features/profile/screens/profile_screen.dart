import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _background = Color(0xFF0B0B0C);
  static const Color _primary = Color(0xFFC3F53C);
  static const Color _surface = Color(0xFF141516);
  static const Color _surfaceElevated = Color(0xFF1C1D1F);
  static const Color _border = Color(0xFF232528);
  static const Color _textPrimary = Color(0xFFF2F3F0);
  static const Color _textSecondary = Color(0xFF8B8D88);
  static const Color _error = Color(0xFFF2705B);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Container(
      color: _background,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileCard(context, user),
              const SizedBox(height: 16),
              _buildSettingsCard(context, auth),
              const SizedBox(height: 24),
              if (auth.isAuthenticated)
                _buildLogoutButton(context, auth)
              else
                _buildLoginButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    final isLoggedIn = user != null;
    final name = user?.name ?? 'Pengguna Tamu';
    final email = user?.email ?? 'Silakan masuk untuk menggunakan CourtMate';
    final photoUrl = user?.photoUrl;
    final role = user?.role.value ?? 'guest';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildAvatar(name, photoUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleBadge(role, isLoggedIn),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String? photoUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: _primary, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl.isNotEmpty
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildInitials(name),
            )
          : _buildInitials(name),
    );
  }

  Widget _buildInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    String initials;

    if (name.trim().isEmpty || name == 'Pengguna Tamu') {
      initials = '?';
    } else if (words.length >= 2) {
      initials = '${words[0][0]}${words[1][0]}';
    } else {
      initials = words.first.substring(0, 1);
    }

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: _primary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, bool isLoggedIn) {
    final label = !isLoggedIn
        ? 'Guest'
        : role == 'admin'
        ? 'Admin'
        : 'Mahasiswa';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'PENGATURAN AKUN',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.edit_outlined,
            title: 'Edit Profil',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
          ),
          const Divider(color: _border, height: 1),
          _buildMenuItem(
            icon: Icons.policy_outlined,
            title: 'Kebijakan Pembatalan',
            onTap: () => _showCancellationPolicy(context),
          ),
          const Divider(color: _border, height: 1),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Bantuan',
            onTap: () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _surfaceElevated,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _textPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return OutlinedButton.icon(
      onPressed: () => _showLogoutConfirmation(context, auth),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Keluar (Logout)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _error,
        side: const BorderSide(color: _error),
        backgroundColor: _surfaceElevated,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
      icon: const Icon(Icons.login),
      label: const Text('Masuk / Registrasi'),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _background,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surfaceElevated,
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(color: _textPrimary),
        ),
        content: const Text(
          'Anda akan keluar dari akun CourtMate. '
          'Anda perlu masuk kembali untuk melakukan booking.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await auth.signOut();
            },
            child: const Text('Keluar', style: TextStyle(color: _error)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;

    if (user == null) {
      _showInfoDialog(
        context,
        title: 'Edit Profil',
        message: 'Silakan masuk ke akun terlebih dahulu.',
      );
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surfaceElevated,
        title: const Text('Edit Profil', style: TextStyle(color: _textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: _textPrimary),
                decoration: _inputDecoration('Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _textPrimary),
                decoration: _inputDecoration('Nomor Telepon'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Formulir edit profil ditampilkan. Penyimpanan perubahan '
                'belum terhubung ke Firebase.',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup', style: TextStyle(color: _textSecondary)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSecondary),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }

  void _showCancellationPolicy(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Kebijakan Pembatalan',
      message:
          'Kebijakan pembatalan booking CourtMate:\n\n'
          '• Pembatalan mengikuti ketentuan pengelola lapangan.\n'
          '• Status dan ketentuan pembatalan dapat berbeda pada setiap lapangan.\n'
          '• Periksa detail booking sebelum melakukan pembatalan.\n\n'
          'Informasi ini merupakan tampilan awal dan dapat disesuaikan '
          'dengan kebijakan resmi sistem booking.',
    );
  }

  void _showHelpDialog(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Bantuan CourtMate',
      message:
          'CourtMate membantu mahasiswa menemukan lapangan olahraga '
          'dan melakukan reservasi.\n\n'
          'Cara menggunakan:\n'
          '1. Pilih lapangan dari menu Jelajah.\n'
          '2. Pilih tanggal dan waktu yang tersedia.\n'
          '3. Ikuti proses booking dan pembayaran.\n'
          '4. Lihat booking Anda melalui menu Booking Saya.\n\n'
          'Jika mengalami kendala, hubungi pengelola aplikasi.',
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surfaceElevated,
        title: Text(title, style: const TextStyle(color: _textPrimary)),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(color: _textSecondary, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
  }
}
