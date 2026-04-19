import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

// Maps step number (1-based) to which of the 4 named phases it belongs to.
// Phases: 1=Você (steps 1-4), 2=Rosto (steps 5-6), 3=Estilo (step 7), 4=Vibe (steps 8-9)
const _phaseLabels = ['Você', 'Rosto', 'Estilo', 'Vibe'];
const _phaseStepRanges = [
  (1, 4), // Você
  (5, 6), // Rosto
  (7, 7), // Estilo
  (8, 9), // Vibe
];

int _stepToPhase(int step) {
  for (int i = 0; i < _phaseStepRanges.length; i++) {
    final (start, end) = _phaseStepRanges[i];
    if (step >= start && step <= end) return i;
  }
  return _phaseStepRanges.length - 1;
}

class OnboardingScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;

  const OnboardingScaffold({
    super.key,
    required this.step,
    this.totalSteps = 9,
    this.title,
    this.subtitle,
    required this.child,
    this.bottom,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: child),
            if (bottom != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final currentPhase = _stepToPhase(step);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack && step > 1)
                Material(
                  color: TwColors.card,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 16, color: TwColors.onBg),
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: TwColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TwColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$step / $totalSteps',
                  style: GoogleFonts.spaceGrotesk(
                    color: TwColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4-phase named progress bar
          Row(
            children: List.generate(_phaseLabels.length, (i) {
              final isDone = i < currentPhase;
              final isCurrent = i == currentPhase;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _phaseLabels.length - 1 ? 6 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: (isDone || isCurrent)
                              ? TwGradients.accent
                              : null,
                          color: (isDone || isCurrent)
                              ? null
                              : TwColors.border,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: TwColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phaseLabels[i],
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isCurrent
                              ? TwColors.primary
                              : isDone
                                  ? TwColors.onSurface
                                  : TwColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (title != null) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title!,
                style: GoogleFonts.spaceGrotesk(
                  color: TwColors.onBg,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: GoogleFonts.spaceGrotesk(
                  color: TwColors.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class OnboardingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const OnboardingButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  State<OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton> {
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
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TwRadius.lg),
            gradient: enabled ? TwGradients.primary : null,
            color: enabled ? null : TwColors.border,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
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

class OnboardingInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const OnboardingInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.spaceGrotesk(
              color: TwColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: GoogleFonts.spaceGrotesk(
            color: TwColors.onBg,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(color: TwColors.muted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: TwColors.card,
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
              borderSide:
                  const BorderSide(color: TwColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
