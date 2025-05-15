// import 'package:camera/camera.dart';
import '../camera_exports.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// Temporarily comment out TensorFlow import
// import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../services/object_detection_service.dart';
import 'dart:async';

// Define a simple loading widget
class LoadingWidget extends StatelessWidget {
  final String message;
  
  const LoadingWidget({Key? key, this.message = 'Loading...'}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// Define string extension
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
  
  String truncate(int maxLength) {
    return length <= maxLength ? this : '${substring(0, maxLength)}...';
  }
}

class ObjectDetectionCameraPage extends StatefulWidget {
  final User user;
  final String itemType; // 'found' or 'lost'
  
  const ObjectDetectionCameraPage({
    Key? key,
    required this.user,
    required this.itemType,
  }) : super(key: key);

  @override
  State<ObjectDetectionCameraPage> createState() => _ObjectDetectionCameraPageState();
}

class _ObjectDetectionCameraPageState extends State<ObjectDetectionCameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isProcessing = false;
  List<Detection> _detections = [];
  bool _isCameraInitialized = false;
  File? _imageFile;
  ui.Size _imageSize = ui.Size(0, 0);
  final ObjectDetectionService _objectDetectionService = ObjectDetectionService();
  bool _isLoading = false;
  String _loadingMessage = 'Loading...';
  String? _capturedImagePath;
  bool _pictureTaken = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _objectDetectionService.initialize();
    await _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    if (_imageFile != null && _imageFile!.existsSync()) {
      _imageFile!.delete();
    }
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _cameraController!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }
  
  Future<void> _initCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }
    
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found')),
          );
        }
        return;
      }
      
      // Initialize the camera with the first available camera
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_pictureTaken && _capturedImagePath != null) {
          _returnWithImage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.itemType.capitalize()} Item Detection'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_pictureTaken && _capturedImagePath != null) {
                _returnWithImage();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: Text('Camera initializing...')),
            if (_detections.isNotEmpty)
              CustomPaint(
                painter: DetectionPainter(
                  _detections,
                  _imageSize.width,
                  _imageSize.height,
                ),
                size: MediaQuery.of(context).size,
              ),
            if (_isLoading) LoadingWidget(message: _loadingMessage),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _isProcessing ? null : _captureAndDetect,
                child: Icon(_isProcessing ? Icons.hourglass_empty : Icons.camera_alt),
                tooltip: 'Take Picture',
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera is not initialized')),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
        _isLoading = true;
        _loadingMessage = 'Capturing image...';
      });
      
      XFile file = await _cameraController!.takePicture();
      _capturedImagePath = file.path;
      _pictureTaken = true;
      
      setState(() {
        _loadingMessage = 'Detecting objects...';
      });
      
      File imageFile = File(file.path);
      var objects = await _detectObjects(imageFile);
      
      setState(() {
        _detections = objects;
        _isLoading = false;
        _isProcessing = false;
      });
      
      if (_detections.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected: ${_detections.map((det) => det.label).join(", ")}'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No objects detected')),
        );
      }
      
      // Upload the image regardless of detection results
      _uploadDetectedImage(file.path, _detections);
      
      // Return to previous screen with the image path
      _returnWithImage();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().truncate(100)}')),
      );
    }
  }
  
  void _returnWithImage() {
    if (_capturedImagePath != null) {
      Navigator.of(context).pop({
        'imagePath': _capturedImagePath,
        'detections': _detections.map((det) => {
          'label': det.label,
          'confidence': det.confidence,
        }).toList(),
      });
    } else {
      Navigator.of(context).pop();
    }
  }
  
  Future<void> _uploadDetectedImage(String imagePath, List<Detection> detections) async {
    try {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Uploading image...';
      });
      
      final File imageFile = File(imagePath);
      final String fileName = 'object_detection_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Use the proper path according to the updated storage rules
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('detections')
          .child(fileName);
      
      // Create metadata with detection results
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'detections': detections.map((det) => '${det.label}: ${(det.confidence * 100).toStringAsFixed(2)}').join(', '),
          'timestamp': DateTime.now().toIso8601String(),
          'userId': widget.user.uid,
          'itemType': widget.itemType,
        },
      );
      
      // Check if user is authenticated before uploading
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Upload the file with metadata
      await storageRef.putFile(imageFile, metadata);
      
      // Get download URL for future reference
      final String downloadUrl = await storageRef.getDownloadURL();
      
      // Save reference to Firestore
      await FirebaseFirestore.instance
          .collection('detections')
          .add({
            'imageUrl': downloadUrl,
            'userId': widget.user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'itemType': widget.itemType,
            'detections': detections.map((det) => {
              'label': det.label,
              'confidence': det.confidence,
            }).toList(),
          });
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Upload error: ${e.toString()}');
      
      // Display a more specific error message
      String errorMessage = 'Upload failed';
      if (e.toString().contains('unauthorized') || e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Check Firebase Storage rules.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage: ${e.toString().truncate(100)}')),
      );
    }
  }
  
  Future<List<Detection>> _detectObjects(File imageFile) async {
    // Load the image
    final imageBytes = await imageFile.readAsBytes();
    
    // Decode the image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      setState(() {
        _imageSize = ui.Size(img.width.toDouble(), img.height.toDouble());
      });
      completer.complete(img);
    });
    
    await completer.future;
    
    // Process the image with TensorFlow Lite
    final detections = await _objectDetectionService.detectObjectsOnImage(imageFile);
    
    setState(() {
      _detections = detections;
    });
    
    // Show detection results
    if (_detections.isNotEmpty) {
      final objectCount = _detections.length;
      final objectNames = _detections.map((det) => det.label).join(', ');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected $objectCount objects: $objectNames')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No objects detected')),
        );
      }
    }
    
    return _detections;
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final double previewWidth;
  final double previewHeight;
  
  DetectionPainter(this.detections, this.previewWidth, this.previewHeight);
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final Paint textBackgroundPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.0,
    );
    
    for (final detection in detections) {
      // Scale bounding box to screen size
      final rect = detection.boundingBox;
      
      // Different scaling logic based on whether this is a camera preview or image display
      final ui.Rect scaledRect = ui.Rect.fromLTWH(
        rect.x * size.width / previewWidth,
        rect.y * size.height / previewHeight,
        rect.width * size.width / previewWidth,
        rect.height * size.height / previewHeight,
      );
      
      // Draw bounding box
      canvas.drawRect(scaledRect, boxPaint);
      
      // Draw label
      final textSpan = TextSpan(
        text: '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Draw text background
      canvas.drawRect(
        ui.Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        textBackgroundPaint,
      );
      
      // Draw text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 