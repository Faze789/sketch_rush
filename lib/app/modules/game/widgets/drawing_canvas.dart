import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/stroke_utils.dart';
import '../../../data/models/stroke_model.dart';
import '../drawing_controller.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DrawingController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        controller.canvasWidth = constraints.maxWidth;
        controller.canvasHeight = constraints.maxHeight;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.canvasBg,
            border: Border.all(color: AppColors.canvasBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Obx(() {
              final isDrawing = controller.isEnabled.value;
              // Touch observables to trigger repaint
              controller.strokes.length;
              final activeStroke = controller.currentStroke.value;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: isDrawing && controller.isFillMode.value
                    ? (_) => controller.fillCanvas(controller.selectedColor.value)
                    : null,
                onPanStart: isDrawing && !controller.isFillMode.value
                    ? controller.onPanStart
                    : null,
                onPanUpdate: isDrawing && !controller.isFillMode.value
                    ? controller.onPanUpdate
                    : null,
                onPanEnd: isDrawing && !controller.isFillMode.value
                    ? controller.onPanEnd
                    : null,
                child: CustomPaint(
                  painter: _CanvasPainter(
                    strokes: controller.strokes.toList(),
                    currentStroke: activeStroke,
                    canvasWidth: constraints.maxWidth,
                    canvasHeight: constraints.maxHeight,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<StrokeModel> strokes;
  final StrokeModel? currentStroke;
  final double canvasWidth;
  final double canvasHeight;

  _CanvasPainter({
    required this.strokes,
    this.currentStroke,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, StrokeModel stroke) {
    // Fill stroke — paint the entire canvas with this color
    if (stroke.isFill) {
      final paint = Paint()..color = Color(stroke.color);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        paint,
      );
      return;
    }

    if (stroke.points.isEmpty) return;

    // Convert normalized points to canvas coordinates as PointVector
    final inputPoints = stroke.points.map((p) {
      final pos = StrokeUtils.denormalizePoint(
        point: p,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
      );
      return PointVector(pos.x, pos.y, p.p);
    }).toList();

    final options = StrokeOptions(
      size: stroke.width,
      thinning: 0.4,
      smoothing: 0.5,
      streamline: 0.5,
      simulatePressure: true,
    );

    // getStroke returns List<PointVector>
    final outlinePoints = getStroke(inputPoints, options: options);

    if (outlinePoints.isEmpty) return;

    final paint = Paint()
      ..color = Color(stroke.color)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (stroke.isEraser) {
      paint.blendMode = BlendMode.clear;
    }

    if (outlinePoints.length < 2) {
      final p = outlinePoints.first;
      canvas.drawCircle(
        Offset(p.dx, p.dy),
        stroke.width / 2,
        paint,
      );
      return;
    }

    // Build path from outline points (Offset objects with .dx/.dy)
    final path = Path();
    path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
    for (var i = 1; i < outlinePoints.length - 1; i++) {
      final p0 = outlinePoints[i];
      final p1 = outlinePoints[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }
    path.lineTo(outlinePoints.last.dx, outlinePoints.last.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return strokes.length != oldDelegate.strokes.length ||
        currentStroke != oldDelegate.currentStroke ||
        canvasWidth != oldDelegate.canvasWidth ||
        canvasHeight != oldDelegate.canvasHeight;
  }
}
