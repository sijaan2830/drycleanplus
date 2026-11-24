import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'persistent_footer_app.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigation: smooth fade + slide route
// ─────────────────────────────────────────────────────────────────────────────

Route<T> smoothRoute<T>(Widget page, {String? name}) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: name),
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Bubble(size: 260, opacity: 0.08),
          ),
          Positioned(
            top: 220,
            left: -110,
            child: _Bubble(size: 220, opacity: 0.06),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: _Bubble(size: 240, opacity: 0.07),
          ),
          child,
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scaffold with header, optional step progress and a bottom bar that rides
// above the keyboard (so "Next" never gets hidden while typing).
// ─────────────────────────────────────────────────────────────────────────────

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottom;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final int? step;
  final int? totalSteps;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.step,
    this.totalSteps,
  });

  void _defaultBack(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      final state = persistentFooterAppState ?? persistentFooterKey.currentState;
      if (state != null && state.tabHistory.length > 1) {
        state.tabHistory.removeLast();
        final prevTab = state.tabHistory.last;
        state.setTab(prevTab, addToHistory: false);
      } else {
        nav.pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This context is ABOVE the Scaffold, so viewInsets is the real keyboard.
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final bottomPad = keyboardOpen ? 12.0 : (mq.viewPadding.bottom > 12 ? mq.viewPadding.bottom : 12.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (onBack != null) {
            onBack!();
          } else {
            _defaultBack(context);
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.primaryBlue,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: showBack
                            ? _GlassIconButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: onBack ?? () => _defaultBack(context),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: actions == null
                            ? null
                            : Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
                      ),
                    ],
                  ),
                ),
                if (step != null && totalSteps != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: StepProgress(current: step!, total: totalSteps!),
                  ),
                Expanded(child: body),
                if (bottom != null)
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
                    child: bottom!,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step progress (e.g. Time → Address → Details → Review)
// ─────────────────────────────────────────────────────────────────────────────

class StepProgress extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const StepProgress({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 5,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: done ? AppColors.gold : Colors.white.withOpacity(0.22),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────────

/// Translucent card for the blue background (white text inside).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool selected;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final deco = selected ? AppCardDecoration.selectedCardDecoration : AppCardDecoration.blueCardDecoration;
    return Container(
      margin: margin,
      decoration: deco,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// White card (dark text inside) — used for the most important info.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: AppCardDecoration.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

enum AppButtonStyle { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final AppButtonStyle style;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.style = AppButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    Color fg;
    BoxDecoration deco;
    switch (style) {
      case AppButtonStyle.primary:
        fg = enabled ? AppColors.primaryBlueDeep : Colors.white.withOpacity(0.55);
        deco = BoxDecoration(
          gradient: enabled ? AppColors.ctaGradient : null,
          color: enabled ? null : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlueDeep.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        );
        break;
      case AppButtonStyle.secondary:
        fg = AppColors.white;
        deco = BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.3),
        );
        break;
      case AppButtonStyle.ghost:
        fg = AppColors.white;
        deco = BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md));
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.9,
      child: DecoratedBox(
        decoration: deco,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                : null,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: fg, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: fg,
                              ),
                            ),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(trailingIcon, color: fg, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small building blocks
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onEdit;
  const SectionHeader({super.key, required this.title, this.subtitle, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withOpacity(0.7)),
                  ),
                ),
            ],
          ),
        ),
        if (onEdit != null)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, size: 13, color: AppColors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Edit',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isDiscount;
  final bool onLight; // render for white SurfaceCard

  const PriceRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
    this.onLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = onLight ? AppColors.ink : AppColors.white;
    final labelColor = isDiscount ? (onLight ? AppColors.success : const Color(0xFF7CFFB0)) : baseText.withOpacity(isTotal ? 1 : 0.8);
    final valueColor = isDiscount ? (onLight ? AppColors.success : const Color(0xFF7CFFB0)) : baseText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: labelColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small circular icon badge used inside cards.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? background;
  final Color? color;
  const IconBadge({super.key, required this.icon, this.size = 44, this.background, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background ?? Colors.white.withOpacity(0.16),
      ),
      child: Icon(icon, color: color ?? AppColors.white, size: size * 0.5),
    );
  }
}

/// Styled text field for the blue background.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final bool readOnly;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      cursorColor: AppColors.gold,
      scrollPadding: const EdgeInsets.only(bottom: 140),
      style: GoogleFonts.inter(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: Colors.white.withOpacity(0.8), size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? const Color(0xFFFF8A80) : const Color(0xFF7CFFB0), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}
