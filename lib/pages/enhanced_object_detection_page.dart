import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:see_you_in_ceu/services/enhanced_detection_service.dart';

class EnhancedObjectDetectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final DetectionModeType initialMode;

  const EnhancedObjectDetectionPage({
    Key? key,
    required this.cameras,
    this.initialMode = DetectionModeType.standard,
  }) : super(key: key);

  @override
  EnhancedObjectDetectionPageState createState() => EnhancedObjectDetectionPageState();
}

class EnhancedObjectDetectionPageState extends State<EnhancedObjectDetectionPage> {
  CameraController? _cameraController;
  EnhancedDetectionService? _detectionService;
  List<DetectedObject> _detectedObjects = [];
  bool _isDetecting = false;
  Size? _previewSize;
  DetectionModeType _currentMode = DetectionModeType.standard;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _setupCamera();
    _initializeDetection();
  }

  Future<void> _setupCamera() async {
    if (widget.cameras.isEmpty) {
      if (kDebugMode) {
        print('No cameras available');
      }
      return;
    }

    // Initialize camera controller with front camera if available
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController?.initialize();
      if (mounted) {
        setState(() {
          _previewSize = Size(
            _cameraController!.value.previewSize!.height,
            _cameraController!.value.previewSize!.width,
          );
        });
        _startDetection();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing camera: $e');
      }
    }
  }

  Future<void> _initializeDetection() async {
    _detectionService = EnhancedDetectionService(mode: _currentMode);
    try {
      await _detectionService?.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing detection service: $e');
      }
    }
  }

  Future<void> _startDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isDetecting) return;
    _isDetecting = true;

    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isDetecting) return;

      try {
        final objects = await _detectionService?.processFrame(image, _previewSize!) ?? [];
        
        if (mounted) {
          setState(() {
            _detectedObjects = objects;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error during detection: $e');
        }
      }
    });
  }

  void _stopDetection() {
    _isDetecting = false;
    _cameraController?.stopImageStream();
  }

  Future<void> _toggleDetectionMode() async {
    // Cycle through detection modes
    DetectionModeType newMode;
    
    switch (_currentMode) {
      case DetectionModeType.standard:
        newMode = DetectionModeType.detailed;
        break;
      case DetectionModeType.detailed:
        newMode = DetectionModeType.comprehensive;
        break;
      case DetectionModeType.comprehensive:
        newMode = DetectionModeType.basic;
        break;
      case DetectionModeType.basic:
      default:
        newMode = DetectionModeType.standard;
        break;
    }
    
    await _changeDetectionMode(newMode);
  }
  
  Future<void> _changeDetectionMode(DetectionModeType mode) async {
    _stopDetection();
    
    setState(() {
      _currentMode = mode;
      _detectedObjects = [];
    });
    
    // Reinitialize detection service with new mode
    await _initializeDetection();
    _startDetection();
  }

  @override
  void dispose() {
    _stopDetection();
    _cameraController?.dispose();
    _detectionService = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Object Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _toggleDetectionMode,
            tooltip: 'Change detection mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: CameraPreview(_cameraController!),
          ),
          
          // Detection overlays
          if (_detectedObjects.isNotEmpty)
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              painter: ObjectDetectionPainter(
                detectedObjects: _detectedObjects,
                previewSize: _previewSize,
                screenSize: MediaQuery.of(context).size,
              ),
            ),
            
          // Detection mode indicator
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mode: ${_currentMode.toString().split('.').last}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          
          // Object list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              color: Colors.black54,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _detectedObjects.length,
                itemBuilder: (context, index) {
                  final object = _detectedObjects[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _getConfidenceColor(object.confidence),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.camera,
                              color: _getConfidenceColor(object.confidence),
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${object.label} (${(object.confidence * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) {
      return Colors.green;
    } else if (confidence > 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

class ObjectDetectionPainter extends CustomPainter {
  final List<DetectedObject> detectedObjects;
  final Size? previewSize;
  final Size screenSize;

  ObjectDetectionPainter({
    required this.detectedObjects,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewSize == null) return;
    
    final double scaleX = screenSize.width / previewSize!.width;
    final double scaleY = screenSize.height / previewSize!.height;

    final Paint boundingBoxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
      
    final Paint transparentFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.2);

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    
    final backgroundPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    for (var object in detectedObjects) {
      if (object.boundingBox == null || object.boundingBox!.length != 4) continue;
      
      // Extract bounding box coordinates [x, y, width, height]
      final x = object.boundingBox![0] * scaleX;
      final y = object.boundingBox![1] * scaleY;
      final w = object.boundingBox![2] * scaleX;
      final h = object.boundingBox![3] * scaleY;
      
      final rect = Rect.fromLTWH(x, y, w, h);
      
      // Set color based on confidence
      boundingBoxPaint.color = _getConfidenceColor(object.confidence);
      
      // Draw the bounding box
      canvas.drawRect(rect, transparentFill);
      canvas.drawRect(rect, boundingBoxPaint);
      
      // Draw the label
      final textSpan = TextSpan(
        text: '${object.label} ${(object.confidence * 100).toStringAsFixed(0)}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Draw background for text
      canvas.drawRect(
        Rect.fromLTWH(x, y - 20, textPainter.width + 8, 20),
        backgroundPaint,
      );
      
      // Draw text
      textPainter.paint(canvas, Offset(x + 4, y - 20));
    }
  }

  @override
  bool shouldRepaint(ObjectDetectionPainter oldDelegate) {
    return oldDelegate.detectedObjects != detectedObjects;
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) {
      return Colors.green;
    } else if (confidence > 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
} 