import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'neu_shadows.dart';
import '../localization/app_localizations.dart';

/// Tactile Spring Wrapper: scale reacts with spring physics on touch
class SpringTouch extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const SpringTouch({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<SpringTouch> createState() => _SpringTouchState();
}

class _SpringTouchState extends State<SpringTouch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      HapticFeedback.selectionClick();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Apple Keynote Bento Card / Modern Glass Card
class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isPressed;
  final bool isFlat;
  final Color? customSurfaceColor;
  final double elevation;
  final Border? border;
  final bool useGlass;

  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.isPressed = false,
    this.isFlat = false,
    this.customSurfaceColor,
    this.elevation = 8.0,
    this.border,
    this.useGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = customSurfaceColor ??
        (useGlass
            ? (isDark ? AppColors.darkSurfaceGlass : AppColors.lightSurfaceGlass)
            : (isDark
                ? (isPressed ? AppColors.darkSurfacePressed : AppColors.darkSurface)
                : (isPressed ? AppColors.lightSurfacePressed : AppColors.lightSurface)));

    final defaultBorder = Border.all(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 0.8,
    );

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
        boxShadow: isFlat
            ? null
            : NeuShadows.elevation(
                isDark: isDark,
                isPressed: isPressed,
                distance: elevation,
                blur: elevation * 2,
              ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: useGlass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      return SpringTouch(
        onTap: onTap,
        scaleDown: 0.98,
        child: content,
      );
    }
    return content;
  }
}

/// iOS Liquid Glass Card
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double blur;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 22,
    this.onTap,
    this.blur = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x99161619)
            : const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderHighlightDark
              : AppColors.glassBorderHighlightLight,
          width: 1.0,
        ),
        boxShadow: NeuShadows.glassGlow(isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return SpringTouch(
        onTap: onTap,
        scaleDown: 0.97,
        child: card,
      );
    }
    return card;
  }
}

/// Keynote Button Variant
enum NeuButtonVariant {
  primary,    // Solid Keynote Jet Black (or pure white in dark mode)
  secondary,  // Bento Surface pill with hairline border
  destructive,// Crimson pill
  success,    // Emerald pill
  glass,      // Frosted Liquid Glass pill
}

/// Apple Keynote Pill Button with Tactile Spring Physics
class NeuButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final NeuButtonVariant variant;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const NeuButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = NeuButtonVariant.primary,
    this.isPrimary = false,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.borderRadius = 100, // Apple Keynote full pill radius
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Border? border;

    final effectiveVariant = widget.isPrimary ? NeuButtonVariant.primary : widget.variant;
    switch (effectiveVariant) {
      case NeuButtonVariant.primary:
        bg = isDark ? Colors.white : AppColors.primary;
        fg = isDark ? const Color(0xFF0D0D0E) : Colors.white;
        break;
      case NeuButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        );
        break;
      case NeuButtonVariant.destructive:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case NeuButtonVariant.success:
        bg = AppColors.success;
        fg = Colors.white;
        break;
      case NeuButtonVariant.glass:
        bg = isDark ? const Color(0x33FFFFFF) : const Color(0xB3FFFFFF);
        fg = isDark ? Colors.white : AppColors.primary;
        border = Border.all(
          color: isDark ? const Color(0x40FFFFFF) : const Color(0x66FFFFFF),
          width: 1,
        );
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.selectionClick();
              _springController.forward();
            }
          : null,
      onTapUp: isEnabled ? (_) => _springController.reverse() : null,
      onTapCancel: isEnabled ? () => _springController.reverse() : null,
      onTap: isEnabled
          ? () {
              _springController.reverse();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border,
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x4D000000) : const Color(0x14000000),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Inset Input Field
class NeuInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const NeuInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hintColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.neuElevation(
              isDark: isDark,
              isPressed: true,
              distance: 3.0,
              blur: 6.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validator,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: hintColor, size: 18)
                  : null,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Neumorphic Toggle Switch
class NeuToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeuToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value
              ? (isDark ? Colors.white : AppColors.primary)
              : (isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.neuElevation(
            isDark: isDark,
            isPressed: true,
            distance: 2,
            blur: 4,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Top Bar
class NeuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const NeuAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          if (showBack)
            NeuIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: fg,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// Neumorphic Icon Button
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final bool isSelected;

  const NeuIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 42,
    this.iconSize = 18,
    this.color,
    this.isSelected = false,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pressed = _isDown || widget.isSelected;
    final fg = widget.color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isDown = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isDown = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isDown = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: isDark
              ? (pressed ? AppColors.darkSurfacePressed : AppColors.darkSurface)
              : (pressed ? AppColors.lightSurfacePressed : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.neuElevation(
            isDark: isDark,
            isPressed: pressed,
            distance: 4,
            blur: 8,
          ),
        ),
        child: Center(
          child: Icon(widget.icon, size: widget.iconSize, color: fg),
        ),
      ),
    );
  }
}

/// Neumorphic Bottom Navigation Bar
class NeuBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NeuNavItem> items;

  const NeuBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: NeuCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 24,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? AppColors.neuElevation(
                          isDark: isDark,
                          isPressed: true,
                          distance: 2,
                          blur: 4,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class NeuNavItem {
  final IconData icon;
  final String label;

  const NeuNavItem({required this.icon, required this.label});
}

/// Apple Keynote & iOS Status Pill Badge
class NeuBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool showDot;

  const NeuBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = color ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(100), // Apple pill standard
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.28 : 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: badgeColor),
            const SizedBox(width: 5),
          ] else if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple Keynote Chip (Bento Pill Chip)
class NeuChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;

  const NeuChip({
    super.key,
    required this.label,
    this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.white : AppColors.primary)
            : (isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected
              ? (isDark ? const Color(0xFF0D0D0E) : Colors.white)
              : chipColor,
          letterSpacing: -0.2,
        ),
      ),
    );

    if (onTap != null) {
      return SpringTouch(
        onTap: onTap,
        scaleDown: 0.95,
        child: chip,
      );
    }
    return chip;
  }
}

/// Neumorphic Pulse Skeleton Loader
class NeuSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const NeuSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<NeuSkeleton> createState() => _NeuSkeletonState();
}

class _NeuSkeletonState extends State<NeuSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (_controller.value * 0.4);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: AppColors.neuElevation(
              isDark: isDark,
              distance: 3,
              blur: 6,
            ),
          ),
        );
      },
    );
  }
}

/// Neumorphic Dialog Modal
class NeuDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const NeuDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NeuDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: NeuCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Neumorphic Empty State Widget (Consistent Icon, Message, Action)
class NeuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const NeuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: NeuCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
                  shape: BoxShape.circle,
                  boxShadow: NeuShadows.inset(isDark: isDark),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 20),
                NeuButton(
                  text: actionText!,
                  onPressed: onAction,
                  variant: NeuButtonVariant.primary,
                  height: 44,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Error State with Retry Button
class NeuErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? retryText;

  const NeuErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: NeuCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
                  shape: BoxShape.circle,
                  boxShadow: NeuShadows.inset(isDark: isDark),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 30,
                  color: AppColors.rose,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              NeuButton(
                text: retryText ?? 'common.retry'.tr(),
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: NeuButtonVariant.secondary,
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

