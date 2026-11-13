import 'package:flutter/material.dart';
import '../theme/neu_design_system.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return NeuSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
