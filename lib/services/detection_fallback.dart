import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'enhanced_detection_service.dart';

/// This class provides a fallback implementation when there are issues with 
/// the main detection service. It simulates detections without using 
/// any actual ML model.
class DetectionFallback {
  // Set to true to use this fallback instead of the real detection service
  static bool useSimulatedDetection = true;
  
  /// Get simulated detections for an image
  static List<DetectedObject> getSimulatedDetections(File imageFile) {
    // Generate random number of detections (1-5)
    final Random random = Random();
    final int count = random.nextInt(4) + 1;
    
    // Generate random detections
    List<DetectedObject> detections = [];
    for (int i = 0; i < count; i++) {
      // Random confidence between 0.6 and 0.95
      final double confidence = 0.6 + random.nextDouble() * 0.35;
      
      // Random position for bounding box
      final double x1 = random.nextDouble() * 0.5;
      final double y1 = random.nextDouble() * 0.5;
      final double width = 0.2 + random.nextDouble() * 0.3;
      final double height = 0.2 + random.nextDouble() * 0.3;
      
      // Create a detection
      detections.add(
        DetectedObject(
          label: _getRandomLabel(),
          confidence: confidence,
          boundingBox: [x1, y1, x1 + width, y1 + height],
          description: 'Simulated detection - ML temporarily disabled',
          relatedTags: ['simulated', 'temporary'],
        ),
      );
    }
    
    return detections;
  }
  
  /// Get simulated real-time detections
  static List<DetectedObject> getSimulatedRealTimeDetections() {
    // Generate random number of detections (0-3)
    final Random random = Random();
    final int count = random.nextInt(3);
    
    // Generate random detections
    List<DetectedObject> detections = [];
    for (int i = 0; i < count; i++) {
      // Random confidence between 0.6 and 0.95
      final double confidence = 0.6 + random.nextDouble() * 0.35;
      
      // Random position for bounding box
      final double x1 = random.nextDouble() * 0.5;
      final double y1 = random.nextDouble() * 0.5;
      final double width = 0.2 + random.nextDouble() * 0.3;
      final double height = 0.2 + random.nextDouble() * 0.3;
      
      // Create a detection
      detections.add(
        DetectedObject(
          label: _getRandomLabel(),
          confidence: confidence,
          boundingBox: [x1, y1, x1 + width, y1 + height],
        ),
      );
    }
    
    return detections;
  }
  
  /// Get a random object label
  static String _getRandomLabel() {
    final labels = [
      'Backpack',
      'Book',
      'Bottle',
      'Phone',
      'Laptop',
      'Keys',
      'Wallet',
      'Glasses',
      'Notebook',
      'Headphones',
      'ID Card',
      'USB Drive'
    ];
    
    return labels[Random().nextInt(labels.length)];
  }
} 