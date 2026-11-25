import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _feedbackMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _feedbackMessage =
            'Mohon lengkapi email dan kata sandi terlebih dahulu.';
      });
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() {
        _feedbackMessage =
            auth.errorMessage ?? 'Gagal masuk. Silakan coba lagi.';
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(painter: _CourtLogoPainter()),
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
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 8),

                      Column(
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 12),
                          const Text(
                            'CourtMate',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'BOOKING LAPANGAN OLAHRAGA',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

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
                              'Masuk ke akun',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kelola jadwal dan pemesanan lapangan kampusmu.',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),

                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                      hint: 'nama@mahasiswa.ac.id',
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

                                  const SizedBox(height: 20),

                                  _buildLabel('Kata Sandi'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 14,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'Masukkan kata sandi',
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Kata sandi wajib diisi';
                                      }

                                      if (value.length < 6) {
                                        return 'Kata sandi minimal 6 karakter';
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
                                          : _handleLogin,
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
                                              'Masuk',
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

                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun?',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.register,
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
                                'Daftar',
                                style: const TextStyle(
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
