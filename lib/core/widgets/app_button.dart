import 'package:flutter/material.dart';
import '../theme/neu_design_system.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  ghost,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height = 48,
    this.borderRadius = 100, // Apple Keynote full pill standard
  });

  @override
  Widget build(BuildContext context) {
    NeuButtonVariant neuVariant;
    switch (variant) {
      case AppButtonVariant.primary:
        neuVariant = NeuButtonVariant.primary;
        break;
      case AppButtonVariant.destructive:
        neuVariant = NeuButtonVariant.destructive;
        break;
      case AppButtonVariant.ghost:
        neuVariant = NeuButtonVariant.glass;
        break;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        neuVariant = NeuButtonVariant.secondary;
        break;
    }

    return NeuButton(
      text: text,
      onPressed: onPressed,
      variant: neuVariant,
      isLoading: isLoading,
      icon: prefixIcon ?? suffixIcon,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
