import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TwColors {
  TwColors._();

  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141F);
  static const card = Color(0xFF1C1C2E);
  static const cardAlt = Color(0xFF16162A);
  static const border = Color(0xFF2A2A3E);

  static const primary = Color(0xFF7B4FFF);
  static const primaryDim = Color(0xFF5E35D4);
  static const secondary = Color(0xFFFF4F8B);

  static const onBg = Color(0xFFF1F1F5);
  static const onSurface = Color(0xFFB0B0C8);
  static const muted = Color(0xFF6B6B8A);

  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFFF6B6B);
}

class TwGradients {
  TwGradients._();

  static const primary = LinearGradient(
    colors: [TwColors.primary, TwColors.primaryDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [TwColors.primary, TwColors.secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const accentDiagonal = LinearGradient(
    colors: [TwColors.primary, TwColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const card = LinearGradient(
    colors: [TwColors.card, TwColors.cardAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surface = LinearGradient(
    colors: [TwColors.surface, TwColors.bg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class TwSpacing {
  TwSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class TwRadius {
  TwRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const pill = 100.0;
}

class TwTheme {
  TwTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final spaceGrotesk = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: TwColors.bg,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: TwColors.primary,
        secondary: TwColors.secondary,
        surface: TwColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: TwColors.onBg,
        surfaceContainerHighest: TwColors.card,
        onSurfaceVariant: TwColors.onSurface,
        outlineVariant: TwColors.border,
        error: TwColors.error,
      ),
      textTheme: spaceGrotesk.copyWith(
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: TwColors.onBg,
          letterSpacing: -0.5,
          height: 1.15,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: TwColors.onBg,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TwColors.onBg,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: TwColors.onBg,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: TwColors.onBg,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: TwColors.onSurface,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: TwColors.muted,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TwColors.onBg,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TwColors.onSurface,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: TwColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TwRadius.xl)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TwColors.bg,
        foregroundColor: TwColors.onBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: TwColors.onBg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TwColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(TwRadius.lg)),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TwColors.primary,
          side: const BorderSide(color: TwColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(TwRadius.md)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TwColors.card,
        selectedColor: TwColors.primary.withValues(alpha: 0.2),
        side: const BorderSide(color: TwColors.border),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: TwColors.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TwRadius.pill)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TwColors.card,
        hintStyle: GoogleFonts.spaceGrotesk(color: TwColors.muted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TwRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TwRadius.md),
          borderSide: const BorderSide(color: TwColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TwRadius.md),
          borderSide: const BorderSide(color: TwColors.primary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TwColors.border,
        thickness: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: TwColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TwRadius.xl)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: TwColors.card,
        contentTextStyle: TextStyle(color: TwColors.onBg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TwRadius.md)),
        ),
      ),
    );
  }
}

/// A gradient button that matches the TinyWorld premium feel.
class TwGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Gradient gradient;
  final double height;

  const TwGradientButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isLoading = false,
    this.gradient = TwGradients.primary,
    this.height = 52,
  });

  @override
  State<TwGradientButton> createState() => _TwGradientButtonState();
}

class _TwGradientButtonState extends State<TwGradientButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _scale = 0.97) : null,
      onTapUp: enabled ? (_) => setState(() => _scale = 1.0) : null,
      onTapCancel: enabled ? () => setState(() => _scale = 1.0) : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TwRadius.lg),
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : TwColors.border,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(TwRadius.lg),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : DefaultTextStyle(
                        style: GoogleFonts.spaceGrotesk(
                          color: enabled ? Colors.white : TwColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        child: widget.child,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
