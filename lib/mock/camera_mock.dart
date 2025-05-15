// This file provides mock implementations of camera classes
// to allow the app to compile without the camera dependency

import 'dart:typed_data';
import 'package:flutter/material.dart';

// Mock classes
class CameraController {
  bool initialized = false;
  late CameraValue value;
  
  CameraController(CameraDescription description, ResolutionPreset preset, {bool enableAudio = false, ImageFormatGroup? imageFormatGroup}) {
    value = CameraValue(
      isInitialized: false,
      previewSize: Size(640, 480),
    );
  }
  
  Future<void> initialize() async {
    initialized = true;
    value = CameraValue(
      isInitialized: true,
      previewSize: Size(640, 480),
    );
    return;
  }
  
  bool get isInitialized => initialized;
  
  Future<void> startImageStream(Function(CameraImage) onLatestImageAvailable) async {
    // Mock implementation
    onLatestImageAvailable(CameraImage());
    return;
  }
  
  Future<void> stopImageStream() async {
    // Mock implementation
    return;
  }
  
  Future<XFile> takePicture() async {
    // Return a mock XFile
    return XFile('mock_path.jpg');
  }
  
  Future<void> setFlashMode(FlashMode mode) async {
    // Mock implementation
    return;
  }
  
  Future<void> setFocusMode(FocusMode mode) async {
    // Mock implementation
    return;
  }
  
  void dispose() {
    // Mock implementation
  }
}

class CameraValue {
  final bool isInitialized;
  final Size? previewSize;
  
  CameraValue({
    required this.isInitialized,
    this.previewSize,
  });
}

class CameraImage {
  final int width = 640;
  final int height = 480;
  final List<Plane> planes = [
    Plane(bytes: Uint8List(640 * 480), bytesPerRow: 640, bytesPerPixel: 1), // Y plane
    Plane(bytes: Uint8List(320 * 240), bytesPerRow: 320, bytesPerPixel: 1), // U plane
    Plane(bytes: Uint8List(320 * 240), bytesPerRow: 320, bytesPerPixel: 1), // V plane
  ];
  final CameraImageFormat format = CameraImageFormat();
}

class Plane {
  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
  
  Plane({
    required this.bytes, 
    required this.bytesPerRow, 
    required this.bytesPerPixel
  });
}

class CameraImageFormat {
  final ImageFormatGroup group = ImageFormatGroup.yuv420;
}

class CameraDescription {
  final String name;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  
  CameraDescription({
    this.name = 'mock_camera',
    this.lensDirection = CameraLensDirection.back,
    this.sensorOrientation = 0,
  });
}

enum CameraLensDirection {
  front,
  back,
  external,
}

enum ImageFormatGroup {
  yuv420,
  bgra8888,
  jpeg,
}

enum FlashMode {
  off,
  auto,
  always,
  torch,
}

enum FocusMode {
  auto,
  locked,
}

enum ResolutionPreset {
  low,
  medium,
  high,
  veryHigh,
  ultraHigh,
  max,
}

class XFile {
  final String path;
  XFile(this.path);
  
  Future<Uint8List> readAsBytes() async {
    // Return mock empty image data
    return Uint8List(0);
  }
  
  String get name => path.split('/').last;
}

// Mock function to return camera list
Future<List<CameraDescription>> availableCameras() async {
  return [
    CameraDescription(
      name: 'mock_back_camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    ),
    CameraDescription(
      name: 'mock_front_camera',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    ),
  ];
}

// Mock UI widget
class CameraPreview extends StatelessWidget {
  final CameraController controller;
  
  const CameraPreview(this.controller);
  
  @override
  Widget build(BuildContext context) {
    // Return an empty container or a placeholder
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Camera preview unavailable',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}