import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class SignaturePadCanvas extends StatefulWidget {
  final ValueChanged<List<List<Offset>>> onSignatureChanged;

  const SignaturePadCanvas({
    super.key,
    required this.onSignatureChanged,
  });

  @override
  State<SignaturePadCanvas> createState() => SignaturePadCanvasState();
}

class SignaturePadCanvasState extends State<SignaturePadCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onSignatureChanged(_strokes);
  }

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Background Baseline Guideline
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            child: Text(
              'Sign above line (Digital Legal Consignee Signature)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),

          // Interactive Gesture Drawing Canvas
          GestureDetector(
            onPanStart: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localPos = box.globalToLocal(details.globalPosition);
                setState(() {
                  _currentStroke = [localPos];
                });
              }
            },
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localPos = box.globalToLocal(details.globalPosition);
                setState(() {
                  _currentStroke.add(localPos);
                });
              }
            },
            onPanEnd: (details) {
              setState(() {
                if (_currentStroke.isNotEmpty) {
                  _strokes.add(List.from(_currentStroke));
                  _currentStroke.clear();
                }
              });
              widget.onSignatureChanged(_strokes);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _SignaturePainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
                strokeColor: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),

          // Clear Button
          Positioned(
            top: 8,
            right: 8,
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.rose,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: clear,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> points) {
      if (points.isEmpty) return;
      if (points.length == 1) {
        canvas.drawCircle(points.first, 1.5, Paint()..color = strokeColor);
        return;
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
