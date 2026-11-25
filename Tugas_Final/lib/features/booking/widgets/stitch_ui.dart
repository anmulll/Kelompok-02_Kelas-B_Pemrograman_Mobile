import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import '../../../models/invitation_model.dart';

/// Token desain resmi proyek Google Stitch `Courtmate` (`projects/5326591438253845810`),
/// diisolasi khusus untuk modul Anmul (Opsi B) tanpa mengubah `AppTheme` global.
class StitchTokens {
  StitchTokens._();

  // Colors
  static const Color primary = Color(0xFFC3F53C);
  static const Color primaryHover = Color(0xFFD2FF5C);
  static const Color onPrimary = Color(0xFF0F100C);
  static const Color secondary = Color(0xFFA78BFA);
  static const Color tertiary = Color(0xFFF5A65B);
  static const Color background = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF141516);
  static const Color surfaceElevated = Color(0xFF1C1D1F);
  static const Color textPrimary = Color(0xFFF2F3F0);
  static const Color textSecondary = Color(0xFF8B8D88);
  static const Color textMuted = Color(0xFF5A5C58);
  static const Color border = Color(0xFF232528);
  static const Color borderHover = Color(0xFF33363A);
  static const Color success = Color(0xFFC3F53C);
  static const Color warning = Color(0xFFF5A65B);
  static const Color error = Color(0xFFF2705B);

  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusPill = 9999;

  // Typography Styles (Inter / Tabular Figures)
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
    color: textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData scopedDarkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        outline: border,
      ),
      dividerColor: border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: bodyMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: primary),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Pembungkus tema gelap Stitch terisolasi agar tampilan modul Anmul
/// 100% sesuai desain Stitch tanpa memengaruhi layar anggota tim lain.
class StitchScope extends StatelessWidget {
  const StitchScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: StitchTokens.scopedDarkTheme(context),
      child: DefaultTextStyle(
        style: StitchTokens.bodyMd,
        child: ColoredBox(
          color: StitchTokens.background,
          child: child,
        ),
      ),
    );
  }
}

class StitchHeaderBar extends StatelessWidget {
  const StitchHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon = Icons.arrow_back,
    this.onLeadingTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final VoidCallback? onLeadingTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: StitchTokens.background,
        border: Border(bottom: BorderSide(color: StitchTokens.border)),
      ),
      child: Row(
        children: [
          if (onLeadingTap != null) ...[
            InkWell(
              onTap: onLeadingTap,
              borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StitchTokens.surface,
                  borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
                  border: Border.all(color: StitchTokens.border),
                ),
                child: Icon(
                  leadingIcon,
                  size: 20,
                  color: StitchTokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: subtitle == null
                      ? StitchTokens.h2
                      : StitchTokens.bodyStrong,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: StitchTokens.labelSm),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = StitchTokens.surface,
    this.borderColor = StitchTokens.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(StitchTokens.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StitchTokens.radiusLg),
        child: content,
      ),
    );
  }
}

class StitchPrimaryButton extends StatelessWidget {
  const StitchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Material(
      color: enabled ? StitchTokens.primary : StitchTokens.surfaceElevated,
      borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: StitchTokens.onPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: enabled
                            ? StitchTokens.onPrimary
                            : StitchTokens.textMuted,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: StitchTokens.bodyStrong.copyWith(
                          color: enabled
                              ? StitchTokens.onPrimary
                              : StitchTokens.textMuted,
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

class StitchSecondaryButton extends StatelessWidget {
  const StitchSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor = StitchTokens.border,
    this.textColor = StitchTokens.textPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StitchTokens.surfaceElevated,
      borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: StitchTokens.bodyStrong.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StitchBookingStatusBadge extends StatelessWidget {
  const StitchBookingStatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, border, fg) = switch (status) {
      BookingStatus.confirmed => (
        'Terkonfirmasi',
        StitchTokens.primary.withValues(alpha: 0.15),
        Colors.transparent,
        StitchTokens.primary,
      ),
      BookingStatus.pendingPayment => (
        'Menunggu Pembayaran',
        StitchTokens.surfaceElevated,
        StitchTokens.tertiary,
        StitchTokens.tertiary,
      ),
      BookingStatus.completed => (
        'Selesai',
        StitchTokens.surfaceElevated,
        StitchTokens.secondary,
        StitchTokens.secondary,
      ),
      BookingStatus.cancelled => (
        'Dibatalkan',
        StitchTokens.surfaceElevated,
        StitchTokens.error,
        StitchTokens.error,
      ),
      BookingStatus.paymentFailed => (
        'Gagal',
        StitchTokens.surfaceElevated,
        StitchTokens.error,
        StitchTokens.error,
      ),
      BookingStatus.expired => (
        'Kedaluwarsa',
        StitchTokens.surfaceElevated,
        StitchTokens.border,
        StitchTokens.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StitchTokens.radiusPill),
        border: border == Colors.transparent ? null : Border.all(color: border),
      ),
      child: Text(label, style: StitchTokens.labelSm.copyWith(color: fg)),
    );
  }
}

class StitchInvitationBadge extends StatelessWidget {
  const StitchInvitationBadge({super.key, required this.status});

  final InvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      InvitationStatus.pending => (
        'Menunggu',
        StitchTokens.warning.withValues(alpha: 0.15),
        StitchTokens.warning,
      ),
      InvitationStatus.accepted => (
        'Diterima',
        StitchTokens.primary.withValues(alpha: 0.15),
        StitchTokens.primary,
      ),
      InvitationStatus.rejected => (
        'Ditolak',
        StitchTokens.error.withValues(alpha: 0.15),
        StitchTokens.error,
      ),
      InvitationStatus.cancelled => (
        'Dibatalkan',
        StitchTokens.surfaceElevated,
        StitchTokens.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StitchTokens.radiusPill),
      ),
      child: Text(label, style: StitchTokens.labelSm.copyWith(color: fg)),
    );
  }
}
