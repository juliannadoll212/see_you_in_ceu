import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' 
//     hide DetectionMode;
// import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' 
//     as ml_kit show DetectionMode;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

// Firebase packages
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Model packages
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:camera/camera.dart';
import '../camera_exports.dart';

// Detection mode types for API compatibility
enum DetectionModeType {
  basic,
  standard,
  detailed,
  comprehensive
}

// Compatibility class to match old interface
class DetectedObject {
  final String label;
  final double confidence;
  final List<double>? boundingBox;
  final String? description;
  final List<String>? relatedTags;

  DetectedObject({
    required this.label,
    required this.confidence,
    this.boundingBox,
    this.description,
    this.relatedTags,
  });
  
  // Convert from DetectionResult
  factory DetectedObject.fromDetectionResult(DetectionResult result) {
    return DetectedObject(
      label: result.label,
      confidence: result.confidence,
      boundingBox: result.boundingBox,
      description: "Detection feature temporarily disabled",
      relatedTags: ["disabled", "temporary"],
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'boundingBox': boundingBox,
      'description': description,
      'relatedTags': relatedTags,
    };
  }
}

class DetectionResult {
  final String label;
  final double confidence;
  final List<double>? boundingBox;

  DetectionResult({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  @override
  String toString() {
    return 'DetectionResult(label: $label, confidence: ${confidence.toStringAsFixed(2)})';
  }
}

class EnhancedDetectionService {
  // Available model types
  static const String SSD_MOBILENET = 'assets/ml/ssd_mobilenet_v1_1_default_1.tflite';
  static const String MOBILE_NET = 'assets/ml/mobilenet_v1_1.0_224_quant.tflite';
  static const String EFFICIENT_DET = 'assets/ml/efficientdet_lite0.tflite';
  static const String MOBILE_OBJECT_LOCALIZER = 'assets/ml/mobile_object_localizer.tflite';
  
  // Label paths
  static const String COCO_LABELS = 'assets/ml/coco_labels.txt';
  static const String IMAGENET_LABELS = 'assets/ml/labels.txt';
  
  // Resolution for input images
  static const int INPUT_SIZE = 300;
  
  // Currently loaded model and its configuration
  String _currentModel = SSD_MOBILENET;
  Map<String, dynamic> _modelConfig = {};
  
  // Loaded labels
  List<String> _labels = [];
  
  // Current detection mode
  DetectionModeType _currentMode = DetectionModeType.standard;
  
  // TensorFlow Lite interpreter
  // Interpreter? _interpreter;
  
  // Initialization state
  bool _isInitialized = false;
  
  // Constructor with optional mode parameter
  EnhancedDetectionService({DetectionModeType mode = DetectionModeType.standard}) {
    _currentMode = mode;
  }
  
  // Initialize with a specific model
  Future<void> initialize({String? modelPath}) async {
    try {
      // Use specified model or default to SSD MobileNet
      final modelToLoad = modelPath ?? SSD_MOBILENET;
      
      // Configure model parameters
      _configureModel(modelToLoad);
      
      // Load labels for the model
      await _loadLabels();
      
      // Load the TensorFlow Lite model
      // _interpreter = await Interpreter.fromAsset(modelToLoad);
      
      _currentModel = modelToLoad;
      _isInitialized = true;
      
      if (kDebugMode) {
        print('Enhanced detection service initialized with model: $_currentModel');
        print('Labels loaded: ${_labels.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing detection service: $e');
      }
      _isInitialized = false;
      rethrow;
    }
  }
  
  // Configure model-specific parameters
  void _configureModel(String modelPath) {
    switch (modelPath) {
      case SSD_MOBILENET:
        _modelConfig = {
          'inputSize': 300,
          'isQuantized': false,
          'labelsPath': COCO_LABELS,
          'inputChannels': 3,
          'outputSize': 10, // Number of detected objects
          'threshold': 0.5,
        };
        break;
      case MOBILE_NET:
        _modelConfig = {
          'inputSize': 224,
          'isQuantized': true,
          'labelsPath': IMAGENET_LABELS,
          'inputChannels': 3,
          'outputSize': 1001, // Number of classes
          'threshold': 0.3,
        };
        break;
      case EFFICIENT_DET:
        _modelConfig = {
          'inputSize': 320,
          'isQuantized': false,
          'labelsPath': COCO_LABELS,
          'inputChannels': 3,
          'outputSize': 25, // Number of detected objects
          'threshold': 0.4,
        };
        break;
      case MOBILE_OBJECT_LOCALIZER:
        _modelConfig = {
          'inputSize': 320,
          'isQuantized': false,
          'labelsPath': COCO_LABELS,
          'inputChannels': 3,
          'outputSize': 100, // Number of detected objects
          'threshold': 0.3,
        };
        break;
      default:
        // Default to SSD MobileNet configuration
        _modelConfig = {
          'inputSize': 300,
          'isQuantized': false,
          'labelsPath': COCO_LABELS,
          'inputChannels': 3,
          'outputSize': 10,
          'threshold': 0.5,
        };
    }
  }
  
  // Load labels for current model
  Future<void> _loadLabels() async {
    try {
      final labelsPath = _modelConfig['labelsPath'] as String;
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading labels: $e');
      }
      _labels = [];
    }
  }
  
  // Process camera image for object detection
  Future<List<DetectionResult>> detectObjects(CameraImage image) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // We'll fake results until we re-enable TensorFlow
      await Future.delayed(Duration(milliseconds: 300)); // Simulate processing time
      
      // Generate some random fake results
      final random = math.Random();
      final resultCount = random.nextInt(3) + 1; // 1-3 random results
      
      final results = <DetectionResult>[];
      
      final possibleLabels = [
        "Person", "Car", "Chair", "TV", "Bottle", "Book", 
        "Enhanced detection disabled", "Enable TensorFlow for real detection"
      ];
      
      for (var i = 0; i < resultCount; i++) {
        final labelIndex = random.nextInt(possibleLabels.length);
        results.add(
          DetectionResult(
            label: possibleLabels[labelIndex],
            confidence: 0.5 + random.nextDouble() * 0.5, // 0.5-1.0
            boundingBox: [
              random.nextDouble() * 0.5,      // left (0-0.5)
              random.nextDouble() * 0.5,      // top (0-0.5)
              0.5 + random.nextDouble() * 0.5, // right (0.5-1.0)
              0.5 + random.nextDouble() * 0.5, // bottom (0.5-1.0)
            ],
          )
        );
      }
      
      return results;
      
      /*
      // Convert camera image to the format needed by the model
      final inputData = await _prepareInputData(image);
      
      // Allocate output tensors based on model type
      final outputs = _allocateOutputTensors();
      
      // Run inference
      _interpreter!.run(inputData, outputs);
      
      // Process results based on model type
      return _processOutputs(outputs);
      */
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting objects: $e');
      }
      return [];
    }
  }
  
  // Prepare input data for the TensorFlow model
  /*
  Future<dynamic> _prepareInputData(CameraImage image) async {
    // Convert camera image to RGB format
    final rgbImage = _convertCameraImageToRgb(image);
    
    // Resize to match model input size
    final inputSize = _modelConfig['inputSize'] as int;
    final resizedImage = img.copyResize(
      rgbImage,
      width: inputSize,
      height: inputSize,
    );
    
    // Create input tensor
    final isQuantized = _modelConfig['isQuantized'] as bool;
    final inputChannels = _modelConfig['inputChannels'] as int;
    
    if (isQuantized) {
      // Quantized models use uint8 input
      final inputData = Uint8List(1 * inputSize * inputSize * inputChannels);
      var index = 0;
      
      for (var y = 0; y < inputSize; y++) {
        for (var x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputData[index++] = img.getRed(pixel);
          inputData[index++] = img.getGreen(pixel);
          inputData[index++] = img.getBlue(pixel);
        }
      }
      
      return inputData;
    } else {
      // Float models use normalized [0,1] input
      final inputData = Float32List(1 * inputSize * inputSize * inputChannels);
      var index = 0;
      
      for (var y = 0; y < inputSize; y++) {
        for (var x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputData[index++] = img.getRed(pixel) / 255.0;
          inputData[index++] = img.getGreen(pixel) / 255.0;
          inputData[index++] = img.getBlue(pixel) / 255.0;
        }
      }
      
      // Reshape for the model
      return inputData.reshape([1, inputSize, inputSize, inputChannels]);
    }
  }
  */
  
  // Convert camera image to RGB format
  img.Image _convertCameraImageToRgb(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToRgb(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToRgb(image);
    }
    
    throw Exception('Unsupported image format: ${image.format.group}');
  }
  
  // Convert YUV420 image to RGB
  img.Image _convertYUV420ToRgb(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final rgbImage = img.Image(width: width, height: height);
    
    for (var h = 0; h < height; h++) {
      for (var w = 0; w < width; w++) {
        final yIndex = h * yRowStride + w;
        final y = image.planes[0].bytes[yIndex];
        
        final uvIndex = (h ~/ 2) * uvRowStride + (w ~/ 2) * uvPixelStride;
        final u = image.planes[1].bytes[uvIndex];
        final v = image.planes[2].bytes[uvIndex];
        
        // YUV to RGB conversion
        final r = (y + 1.370705 * (v - 128)).round().clamp(0, 255);
        final g = (y - 0.698001 * (v - 128) - 0.337633 * (u - 128)).round().clamp(0, 255);
        final b = (y + 1.732446 * (u - 128)).round().clamp(0, 255);
        
        rgbImage.setPixelRgba(w, h, r, g, b, 255);
      }
    }
    
    return rgbImage;
  }
  
  // Convert BGRA8888 image to RGB
  img.Image _convertBGRA8888ToRgb(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }
  
  // Allocate output tensors based on model type
  /*
  dynamic _allocateOutputTensors() {
    // Different output formats based on model
    switch (_currentModel) {
      case SSD_MOBILENET:
        // SSD MobileNet outputs detection boxes, classes, scores, and count
        return {
          0: List<List<List<double>>>.filled(
            1, List<List<double>>.filled(10, List<double>.filled(4, 0.0)),
          ), // Locations
          1: List<List<int>>.filled(
            1, List<int>.filled(10, 0),
          ), // Classes
          2: List<List<double>>.filled(
            1, List<double>.filled(10, 0.0),
          ), // Scores
          3: List<double>.filled(1, 0.0), // Number of detections
        };
        
      case MOBILE_NET:
        // MobileNet outputs classification scores
        return [List<List<double>>.filled(1, List<double>.filled(1001, 0.0))];
        
      case EFFICIENT_DET:
        // EfficientDet outputs similar to SSD, but with more detections
        return {
          0: List<List<List<double>>>.filled(
            1, List<List<double>>.filled(25, List<double>.filled(4, 0.0)),
          ), // Boxes
          1: List<List<int>>.filled(
            1, List<int>.filled(25, 0),
          ), // Classes
          2: List<List<double>>.filled(
            1, List<double>.filled(25, 0.0),
          ), // Scores
          3: List<double>.filled(1, 0.0), // Number of detections
        };
        
      default:
        // Default to SSD-like output format
        return {
          0: List<List<List<double>>>.filled(
            1, List<List<double>>.filled(10, List<double>.filled(4, 0.0)),
          ),
          1: List<List<int>>.filled(
            1, List<int>.filled(10, 0),
          ),
          2: List<List<double>>.filled(
            1, List<double>.filled(10, 0.0),
          ),
          3: List<double>.filled(1, 0.0),
        };
    }
  }
  */
  
  // Process outputs from the model to detection results
  /*
  List<DetectionResult> _processOutputs(dynamic outputs) {
    final threshold = _modelConfig['threshold'] as double;
    final results = <DetectionResult>[];
    
    switch (_currentModel) {
      case SSD_MOBILENET:
      case EFFICIENT_DET:
      case MOBILE_OBJECT_LOCALIZER:
        // Process detection model outputs (SSD, EfficientDet, etc.)
        final locations = outputs[0] as List<List<List<double>>>;
        final classes = outputs[1] as List<List<int>>;
        final scores = outputs[2] as List<List<double>>;
        final numDetections = (outputs[3] as List<double>)[0].toInt();
        
        for (var i = 0; i < numDetections; i++) {
          final score = scores[0][i];
          
          if (score >= threshold) {
            final classId = classes[0][i];
            final label = classId < _labels.length ? _labels[classId] : 'Unknown';
            final box = locations[0][i];
            
            results.add(DetectionResult(
              label: label,
              confidence: score,
              boundingBox: box,
            ));
          }
        }
        break;
        
      case MOBILE_NET:
        // Process classification model outputs
        final scores = outputs[0][0] as List<double>;
        
        // Find top class
        var maxScore = 0.0;
        var maxIndex = 0;
        
        for (var i = 0; i < scores.length; i++) {
          if (scores[i] > maxScore) {
            maxScore = scores[i];
            maxIndex = i;
          }
        }
        
        if (maxScore >= threshold) {
          final label = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
          
          results.add(DetectionResult(
            label: label,
            confidence: maxScore,
            // No bounding box for classification models
          ));
        }
        break;
    }
    
    return results;
  }
  */
  
  // Save image to a file for processing or display
  Future<String> saveImage(CameraImage image) async {
    try {
      final convertedImage = _convertCameraImageToRgb(image);
      
      // Encode as PNG
      final pngBytes = img.encodePng(convertedImage);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/detection_image_$timestamp.png');
      await file.writeAsBytes(Uint8List.fromList(pngBytes));
      
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image: $e');
      }
      return '';
    }
  }
  
  // Clean up resources
  void dispose() {
    /*
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }
    */
    _isInitialized = false;
  }
  
  // For compatibility with old code
  void close() {
    dispose();
  }
  
  // Switch to a different model
  Future<void> switchModel(String modelPath) async {
    dispose();
    await initialize(modelPath: modelPath);
  }
  
  // For compatibility with existing code
  Future<void> setDetectionMode(DetectionModeType mode) async {
    // No-op stub implementation
    print('Setting detection mode: $mode');
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  // For compatibility with existing code
  void setConfidenceThreshold(double threshold) {
    // No-op stub implementation
    print('Setting confidence threshold: $threshold');
  }
  
  // Process camera image frame for real-time detection
  Future<List<DetectedObject>> processFrame(CameraImage image, Size previewSize) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Detect objects in the camera frame
      final results = await detectObjects(image);
      
      // Convert results to DetectedObject instances
      return results.map((result) => 
          DetectedObject.fromDetectionResult(result)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error processing frame: $e');
      }
      return [];
    }
  }
} 