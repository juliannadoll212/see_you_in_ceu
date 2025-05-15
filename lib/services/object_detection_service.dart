import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:camera/camera.dart';
import '../camera_exports.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// Temporarily comment out TensorFlow import
// import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class Detection {
  final String label;
  final double confidence;
  final Rect boundingBox;

  Detection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });
}

class Rect {
  final double x, y, width, height;

  Rect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;

  @override
  String toString() => 'Rect(x: $x, y: $y, width: $width, height: $height)';
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

class ObjectDetectionService {
  // Model paths
  final String _modelPath1 = 'assets/ml/ssd_mobilenet_v1_1_default_1.tflite';
  final String _modelPath2 = 'assets/ml/mobilenet_v1_1.0_224_quant.tflite';
  final String _labelsPath1 = 'assets/ml/coco_labels.txt';
  final String _labelsPath2 = 'assets/ml/labels.txt';

  // Input sizes for SSD MobileNet model
  static const int _inputSize = 300;
  static const int _numChannels = 3;
  
  // Labels loaded from file
  List<String> _labels = [];
  
  // TensorFlow Lite interpreter
  // Interpreter? _interpreter;
  
  // Flag for initialization
  bool _isInitialized = false;
  String _currentModel = "";

  // Initialize with default model
  Future<void> initialize({String model = 'ssd_mobilenet'}) async {
    try {
      // Load labels
      if (model == 'ssd_mobilenet') {
        _labels = await _loadLabels(_labelsPath1);
        // _interpreter = await Interpreter.fromAsset(_modelPath1);
        _currentModel = 'ssd_mobilenet';
      } else if (model == 'mobilenet') {
        _labels = await _loadLabels(_labelsPath2);
        // _interpreter = await Interpreter.fromAsset(_modelPath2);
        _currentModel = 'mobilenet';
      }
      
      _isInitialized = true;
      if (kDebugMode) {
        print('ObjectDetectionService initialized with model: $_currentModel');
        print('Labels loaded: ${_labels.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing ObjectDetectionService: $e');
      }
      _isInitialized = false;
    }
  }

  // Load label file
  Future<List<String>> _loadLabels(String path) async {
    try {
      final labels = await rootBundle.loadString(path);
      return labels.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading labels: $e');
      }
      return [];
    }
  }

  // Preprocess image for the model
  Future<Float32List> _preProcessImage(CameraImage image) async {
    // Convert YUV to RGB
    img.Image? convertedImage;
    if (image.format.group == ImageFormatGroup.yuv420) {
      convertedImage = _convertYUV420ToImage(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      convertedImage = _convertBGRA8888ToImage(image);
    }

    if (convertedImage == null) {
      throw Exception('Image format not supported');
    }

    // Resize image to fit model input
    final resizedImage = img.copyResize(
      convertedImage,
      width: _inputSize,
      height: _inputSize,
    );

    // Convert to normalized float array
    final inputData = Float32List(_inputSize * _inputSize * _numChannels);
    var index = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Normalize pixel values to [0, 1]
        inputData[index++] = pixel.r.toDouble() / 255.0;
        inputData[index++] = pixel.g.toDouble() / 255.0;
        inputData[index++] = pixel.b.toDouble() / 255.0;
      }
    }
    
    // Reshape to match model input
    // final reshapedInput = inputData.reshape([1, 300, 300, 3]);
    // return reshapedInput;
    return inputData;
  }

  // Convert YUV420 camera image to RGB Image
  img.Image _convertYUV420ToImage(CameraImage image) {
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

  // Convert BGRA8888 camera image to RGB Image
  img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  // Detect objects in the image
  Future<List<DetectionResult>> processImage(CameraImage image) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // We'll fake results until we re-enable TensorFlow
      await Future.delayed(Duration(milliseconds: 300)); // Simulate processing time
      
      return [
        DetectionResult(
          label: "Object detection disabled",
          confidence: 0.85,
        ),
        DetectionResult(
          label: "Re-enable TensorFlow for real detection",
          confidence: 0.75,
        ),
      ];
      
      /*
      // Preprocess image
      final input = await _preProcessImage(image);
      
      // Output tensors
      final outputShapes = _interpreter!.getOutputTensors();
      final outputSize = _currentModel == 'ssd_mobilenet' 
          ? [1, 10, 4] // SSD MobileNet has 10 detections with 4 values per detection
          : [1, 1001]; // MobileNet has 1001 class probabilities
      
      // Allocate output tensors
      final outputs = List.generate(
        outputShapes.length, 
        (i) => _currentModel == 'ssd_mobilenet'
            ? List.filled(10 * 4, 0.0) // SSD MobileNet outputs
            : List.filled(1001, 0.0)   // MobileNet outputs
      );

      // Run inference
      _interpreter!.run(input, outputs);
      
      // Process results
      if (_currentModel == 'ssd_mobilenet') {
        // Process SSD MobileNet output
        final locations = outputs[0] as List<List<double>>;
        final classes = outputs[1] as List<double>;
        final scores = outputs[2] as List<double>;
        final numDetections = outputs[3].first.toInt();
        
        final results = <DetectionResult>[];
        for (var i = 0; i < numDetections; i++) {
          final score = scores[i];
          if (score >= 0.5) { // Threshold for confidence
            final classId = classes[i].toInt();
            final label = _labels[classId];
            final location = locations[i];
            
            results.add(DetectionResult(
              label: label,
              confidence: score,
              boundingBox: location,
            ));
          }
        }
        return results;
      } else {
        // Process MobileNet output
        final probs = outputs[0] as List<double>;
        
        // Find top prediction
        var maxProb = 0.0;
        var maxIndex = 0;
        for (var i = 0; i < probs.length; i++) {
          if (probs[i] > maxProb) {
            maxProb = probs[i];
            maxIndex = i;
          }
        }
        
        if (maxProb >= 0.3) { // Threshold for confidence
          return [
            DetectionResult(
              label: _labels[maxIndex],
              confidence: maxProb,
            )
          ];
        }
      }
      */
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error processing image: $e');
      }
      return [];
    }
  }

  // Save image to temporary file for processing
  Future<String> saveImage(CameraImage image) async {
    try {
      img.Image? convertedImage;
      if (image.format.group == ImageFormatGroup.yuv420) {
        convertedImage = _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        convertedImage = _convertBGRA8888ToImage(image);
      }

      if (convertedImage == null) {
        throw Exception('Image format not supported');
      }

      // Encode as PNG
      final pngBytes = img.encodePng(convertedImage);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/detection_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(Uint8List.fromList(pngBytes));
      
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image: $e');
      }
      return '';
    }
  }

  // Process image for results
  Future<List<Detection>> detectObjectsOnImage(File imageFile) async {
    // This is a stub implementation since we commented out TensorFlow
    if (kDebugMode) {
      print('Using stub implementation of detectObjectsOnImage with file: ${imageFile.path}');
    }
    
    // Just return some fake results
    return [
      Detection(
        label: "Detection disabled",
        confidence: 0.9,
        boundingBox: Rect(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
      ),
      Detection(
        label: "Re-enable TensorFlow",
        confidence: 0.8,
        boundingBox: Rect(x: 0.6, y: 0.6, width: 0.3, height: 0.3),
      ),
    ];
  }

  // Cleanup resources
  void dispose() {
    // if (_interpreter != null) {
    //   _interpreter!.close();
    //   _interpreter = null;
    // }
    _isInitialized = false;
  }

  // For compatibility with old API
  void close() {
    dispose();
  }
}

// Mock implementation of rootBundle for testing
class rootBundle {
  static Future<String> loadString(String path) async {
    // Mock implementation for labels
    if (path.contains('coco_labels.txt')) {
      return 'person\ncar\ndog\ncat\nchair\ntable\nphone';
    } else if (path.contains('labels.txt')) {
      return 'background\nperson\ncar\ndog\ncat\nchair\ntable\nphone';
    }
    throw Exception('File not found: $path');
  }
} 