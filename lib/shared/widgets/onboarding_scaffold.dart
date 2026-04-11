import 'package:flutter/material.dart';

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
    this.totalSteps = 5,
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
      backgroundColor: const Color(0xFFFAFDFB),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack && step > 1)
                IconButton(
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A2E),
                  ),
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B76F2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$step / $totalSteps',
                  style: const TextStyle(
                    color: Color(0xFF1B76F2),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(totalSteps, (i) {
              final isActive = i < step;
              final isCurrent = i == step - 1;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(left: i > 0 ? 4 : 0, right: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1B76F2)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF1B76F2).withValues(alpha: 0.3),
                              blurRadius: 6,
                            )
                          ]
                        : null,
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
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: widget.onPressed != null
                ? const LinearGradient(
                    colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)],
                  )
                : null,
            color: widget.onPressed == null
                ? const Color(0xFFE5E7EB)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(14),
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
                        style: TextStyle(
                          color: widget.onPressed != null
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
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
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
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
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC4C9D0)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1B76F2), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
