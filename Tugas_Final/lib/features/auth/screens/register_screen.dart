import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _feedbackMessage;

  static const Color _background = Color(0xFF0B0B0C);
  static const Color _primary = Color(0xFFC3F53C);
  static const Color _surface = Color(0xFF141516);
  static const Color _surfaceElevated = Color(0xFF1C1D1F);
  static const Color _border = Color(0xFF232528);
  static const Color _textPrimary = Color(0xFFF2F3F0);
  static const Color _textSecondary = Color(0xFF8B8D88);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _feedbackMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _feedbackMessage = 'Mohon lengkapi semua data pendaftaran.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _feedbackMessage = 'Konfirmasi password tidak cocok.';
      });
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.registerStudent(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() {
        _feedbackMessage =
            auth.errorMessage ?? 'Pendaftaran gagal. Silakan coba lagi.';
      });
    }
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
      filled: true,
      fillColor: _surfaceElevated,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF2705B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF2705B)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(10),
      child: CustomPaint(painter: _CourtLogoPainter()),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          textInputAction: textInputAction,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: _inputDecoration(
            hint: hint,
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textSecondary,
                size: 20,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildLogo(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CourtMate',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'AKUN MAHASISWA',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Mahasiswa',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Buat akun baru',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Daftar untuk mulai booking lapangan olahraga.',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    color: _primary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pendaftaran ini khusus untuk akun Mahasiswa menggunakan email kampus aktif.',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 11,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Nama Lengkap'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 14,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'Budi Santoso',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nama lengkap wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  _buildLabel('Email'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 14,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'budi@mahasiswa.ac.id',
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';

                                      if (email.isEmpty) {
                                        return 'Email wajib diisi';
                                      }

                                      if (!email.contains('@') ||
                                          !email.contains('.')) {
                                        return 'Masukkan email yang valid';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  _buildPasswordField(
                                    label: 'Password',
                                    hint: 'Minimal 8 karakter',
                                    controller: _passwordController,
                                    visible: _passwordVisible,
                                    onToggle: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password wajib diisi';
                                      }

                                      if (value.length < 8) {
                                        return 'Password minimal 8 karakter';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  _buildPasswordField(
                                    label: 'Konfirmasi Password',
                                    hint: 'Ulangi password',
                                    controller: _confirmPasswordController,
                                    visible: _confirmPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    onToggle: () {
                                      setState(() {
                                        _confirmPasswordVisible =
                                            !_confirmPasswordVisible;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Konfirmasi password wajib diisi';
                                      }

                                      if (value != _passwordController.text) {
                                        return 'Konfirmasi password tidak cocok';
                                      }

                                      return null;
                                    },
                                  ),

                                  if (_feedbackMessage != null ||
                                      auth.errorMessage != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _border),
                                      ),
                                      child: Text(
                                        _feedbackMessage ??
                                            auth.errorMessage ??
                                            '',
                                        style: const TextStyle(
                                          color: _textPrimary,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: _background,
                                        disabledBackgroundColor: _primary
                                            .withOpacity(0.5),
                                        disabledForegroundColor: _background,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: _background,
                                              ),
                                            )
                                          : const Text(
                                              'Daftar Akun',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun?',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: _textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _primary,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CourtLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC3F53C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final rect = Rect.fromLTWH(1, 2, size.width - 2, size.height - 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      paint,
    );

    canvas.drawLine(
      Offset(size.width / 2, 2),
      Offset(size.width / 2, size.height - 2),
      paint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.12,
      Paint()
        ..color = const Color(0xFFC3F53C)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
