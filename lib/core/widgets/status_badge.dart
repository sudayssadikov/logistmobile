import 'package:flutter/material.dart';
import '../theme/neu_design_system.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.icon,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return NeuBadge(
      label: label,
      color: color,
      icon: icon,
      showDot: showDot,
    );
  }
}
