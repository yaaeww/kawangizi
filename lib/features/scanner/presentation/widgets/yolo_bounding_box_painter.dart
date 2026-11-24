import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/yolo_service.dart';

/// CustomPainter untuk menggambar bounding box YOLOv8 di atas gambar piring nampan
class YoloBoundingBoxPainter extends CustomPainter {
  const YoloBoundingBoxPainter({
    required this.detections,
    this.selectedDetection,
  });

  final List<YoloDetection> detections;
  final YoloDetection? selectedDetection;

  Color _parseHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final isSelected = selectedDetection?.classId == det.classId;
      final baseColor = _parseHex(det.colorHex);

      final rect = Rect.fromLTRB(
        det.left * size.width,
        det.top * size.height,
        det.right * size.width,
        det.bottom * size.height,
      );

      // 1. Shaded Background
      final fillPaint = Paint()
        ..color = baseColor.withValues(alpha: isSelected ? 0.28 : 0.14)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), fillPaint);

      // 2. Stroke Border
      final borderPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.5 : 2.0;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

      // 3. Label Text Badge
      final labelText = '${det.label.toUpperCase()} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      final badgeWidth = textPainter.width + badgePadding.horizontal;
      final badgeHeight = textPainter.height + badgePadding.vertical;

      final badgeTop = max(0.0, rect.top - badgeHeight);
      final badgeRect = Rect.fromLTWH(
        rect.left,
        badgeTop,
        badgeWidth,
        badgeHeight,
      );

      final badgePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)),
        badgePaint,
      );

      textPainter.paint(
        canvas,
        Offset(badgeRect.left + badgePadding.left, badgeRect.top + badgePadding.top),
      );
    }
  }

  @override
  bool shouldRepaint(covariant YoloBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.selectedDetection != selectedDetection;
  }
}
