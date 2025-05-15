import 'package:flutter/material.dart';
import '../services/enhanced_detection_service.dart' as detection_service;

class EnhancedDetectionPainter extends CustomPainter {
  final List<detection_service.DetectedObject> detections;
  final Size imageSize;
  final Size previewSize;
  final bool showLabels;
  
  EnhancedDetectionPainter({
    required this.detections,
    required this.imageSize,
    required this.previewSize,
    this.showLabels = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;
    
    // Calculate scaling factors
    final double scaleX = size.width / previewSize.width;
    final double scaleY = size.height / previewSize.height;

    for (final detection in detections) {
      if (detection.boundingBox == null || detection.boundingBox!.length < 4) continue;
      
      // Set up paint styles based on confidence
      final boxColor = _getBoxColorByConfidence(detection.confidence);
      
      final boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      final textBgPaint = Paint()
        ..color = boxColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      // Extract values from the boundingBox list [left, top, right, bottom]
      final left = detection.boundingBox![0];
      final top = detection.boundingBox![1];
      final right = detection.boundingBox![2];
      final bottom = detection.boundingBox![3];
      
      // Create a Rect from the boundingBox values
      final rect = Rect.fromLTRB(
        left * scaleX,
        top * scaleY,
        right * scaleX,
        bottom * scaleY,
      );
      
      // Draw bounding box with animation effects
      _drawAnimatedBox(canvas, rect, boxPaint);
      
      // Draw label if needed
      if (showLabels) {
        _drawDetectionLabel(
          canvas, 
          rect, 
          detection.label, 
          detection.confidence, 
          textBgPaint,
        );
      }
    }
  }
  
  // Helper to draw animated bounding box
  void _drawAnimatedBox(Canvas canvas, Rect rect, Paint paint) {
    // Draw main rectangle
    canvas.drawRect(rect, paint);
    
    // Draw corner accents
    final cornerSize = rect.width * 0.1;
    final cornerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth + 1.0;
    
    // Top-left corner
    canvas.drawLine(
      rect.topLeft, 
      rect.topLeft.translate(cornerSize, 0), 
      cornerPaint,
    );
    canvas.drawLine(
      rect.topLeft, 
      rect.topLeft.translate(0, cornerSize), 
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      rect.topRight, 
      rect.topRight.translate(-cornerSize, 0), 
      cornerPaint,
    );
    canvas.drawLine(
      rect.topRight, 
      rect.topRight.translate(0, cornerSize), 
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      rect.bottomLeft, 
      rect.bottomLeft.translate(cornerSize, 0), 
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft, 
      rect.bottomLeft.translate(0, -cornerSize), 
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      rect.bottomRight, 
      rect.bottomRight.translate(-cornerSize, 0), 
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomRight, 
      rect.bottomRight.translate(0, -cornerSize), 
      cornerPaint,
    );
  }
  
  // Helper to draw detection label
  void _drawDetectionLabel(
    Canvas canvas, 
    Rect rect, 
    String label, 
    double confidence, 
    Paint bgPaint,
  ) {
    final labelText = '$label ${(confidence * 100).toStringAsFixed(0)}%';
    
    // Prepare text style
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    
    // Create text painter
    final textSpan = TextSpan(
      text: labelText,
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw text background
    final textBgRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 8,
      textPainter.width + 16,
      textPainter.height + 8,
    );
    
    final bgRRect = RRect.fromRectAndRadius(
      textBgRect,
      Radius.circular(4),
    );
    
    canvas.drawRRect(bgRRect, bgPaint);
    
    // Draw text
    textPainter.paint(
      canvas,
      Offset(rect.left + 8, rect.top - textPainter.height - 4),
    );
  }
  
  // Helper to get box color based on confidence
  Color _getBoxColorByConfidence(double confidence) {
    if (confidence >= 0.7) {
      return Colors.green;
    } else if (confidence >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  @override
  bool shouldRepaint(covariant EnhancedDetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
           oldDelegate.showLabels != showLabels;
  }
} 