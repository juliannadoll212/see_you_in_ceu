import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
import '../camera_exports.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import '../services/enhanced_detection_service.dart' as detection_service;
import '../services/detection_fallback.dart';
import '../widgets/camera_controls_widget.dart';
import '../widgets/detection_results_widget.dart';
import '../widgets/enhanced_detection_painter.dart';
import '../widgets/loading_widget.dart';

class EnhancedObjectDetectionPage extends StatefulWidget {
  final User user;
  final String itemType; // 'found' or 'lost'
  
  const EnhancedObjectDetectionPage({
    Key? key,
    required this.user,
    required this.itemType,
  }) : super(key: key);
  
  @override
  _EnhancedObjectDetectionPageState createState() => _EnhancedObjectDetectionPageState();
}

class _EnhancedObjectDetectionPageState extends State<EnhancedObjectDetectionPage> 
    with WidgetsBindingObserver {
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  
  // Detection service
  late detection_service.EnhancedDetectionService _detectionService;
  List<detection_service.DetectedObject> _detections = [];
  
  // UI state
  bool _isProcessing = false;
  bool _isLoading = false;
  String _loadingMessage = 'Initializing...';
  DetectionMode _currentMode = DetectionMode.standard;
  double _confidenceThreshold = 0.6;
  bool _showControls = true;
  File? _capturedImage;
  Size _previewSize = Size(0, 0);
  
  // Detection results state
  bool _showResults = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Initializing camera...';
    });
    
    try {
      // Initialize camera
      await _initCamera();
      
      // Initialize detection service only if not using fallback
      if (!DetectionFallback.useSimulatedDetection) {
        // Initialize real detection service
        _detectionService = detection_service.EnhancedDetectionService(
          mode: _currentDetectionMode
        );
        
        setState(() {
          _loadingMessage = 'Loading detection models...';
        });
        
        await _detectionService.initialize();
      } else {
        // Create a dummy service instance without initializing models
        _detectionService = detection_service.EnhancedDetectionService(
          mode: _currentDetectionMode
        );
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Start real-time detection if camera is initialized
      if (_isCameraInitialized) {
        _startRealTimeDetection();
      }
    } catch (e) {
      print('Error initializing services: $e');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('Failed to initialize: $e');
    }
  }
  
  // Helper to convert UI DetectionMode to Service DetectionMode
  detection_service.DetectionModeType get _currentDetectionMode {
    switch (_currentMode) {
      case DetectionMode.basic:
        return detection_service.DetectionModeType.basic;
      case DetectionMode.standard:
        return detection_service.DetectionModeType.standard;
      case DetectionMode.detailed:
        return detection_service.DetectionModeType.detailed;
      case DetectionMode.comprehensive:
        return detection_service.DetectionModeType.comprehensive;
    }
  }
  
  Future<void> _initCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showErrorSnackBar('Camera permission is required');
      return;
    }
    
    try {
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showErrorSnackBar('No cameras found');
        return;
      }
      
      // Select camera
      final cameraIndex = _selectedCameraIndex.clamp(0, _cameras.length - 1);
      
      // Initialize camera controller
      _cameraController = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      // Initialize the controller
      await _cameraController!.initialize();
      
      // Get preview size for bounding box scaling
      _previewSize = Size(
        _cameraController!.value.previewSize!.width,
        _cameraController!.value.previewSize!.height,
      );
      
      // Enable flash mode auto
      await _cameraController!.setFlashMode(FlashMode.auto);
      
      // Enable auto focus mode
      await _cameraController!.setFocusMode(FocusMode.auto);
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }
  
  // Start real-time detection
  void _startRealTimeDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    // Use fallback detection if enabled
    if (DetectionFallback.useSimulatedDetection) {
      // Set up periodic timer for simulated detections
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && _isCameraInitialized && !_isProcessing) {
          setState(() {
            _detections = DetectionFallback.getSimulatedRealTimeDetections();
          });
          
          // Continue with more detections if still active
          if (_isCameraInitialized && mounted && !_showResults) {
            _startRealTimeDetection();
          }
        }
      });
      return;
    }
    
    // Original ML detection code
    _cameraController!.startImageStream((CameraImage cameraImage) {
      if (!_isProcessing && _isCameraInitialized && mounted) {
        _isProcessing = true;
        
        // Process image frame for real-time detection
        _detectionService.processFrame(cameraImage, _previewSize).then((results) {
          if (mounted) {
            setState(() {
              _detections = results;
              _isProcessing = false;
            });
          }
        }).catchError((e) {
          print('Error processing frame: $e');
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });
      }
    });
  }
  
  // Stop real-time detection
  void _stopRealTimeDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    _cameraController!.stopImageStream();
  }
  
  // Capture and detect objects
  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorSnackBar('Camera is not initialized');
      return;
    }
    
    // Stop image stream to ensure we can take a photo
    _stopRealTimeDetection();
    
    setState(() {
      _isProcessing = true;
      _showControls = false;
    });
    
    try {
      // Capture the image
      final XFile photo = await _cameraController!.takePicture();
      
      // Process captured image
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Processing image...';
        _capturedImage = File(photo.path);
      });
      
      // Use simulated detections
      List<detection_service.DetectedObject> detectedObjects;
      if (DetectionFallback.useSimulatedDetection) {
        detectedObjects = DetectionFallback.getSimulatedDetections(_capturedImage!);
      } else {
        // Original code for real ML detection (keep as fallback)
        detectedObjects = <detection_service.DetectedObject>[
          detection_service.DetectedObject(
            label: 'Detected Object',
            confidence: 0.85,
            boundingBox: [0.2, 0.2, 0.7, 0.7],
            description: 'Object detected in image',
            relatedTags: ['object', 'detected'],
          ),
          detection_service.DetectedObject(
            label: 'TF Disabled',
            confidence: 0.95,
            boundingBox: [0.1, 0.5, 0.3, 0.7],
            description: 'TensorFlow functionality disabled',
            relatedTags: ['tensorflow', 'disabled'],
          ),
        ];
      }
      
      // Show results
      setState(() {
        _detections = detectedObjects;
        _isLoading = false;
        _isProcessing = false;
        _showResults = true;
      });
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _isLoading = false;
        _isProcessing = false;
        _showControls = true;
      });
      
      _showErrorSnackBar('Failed to process image: $e');
      
      // Restart real-time detection
      _startRealTimeDetection();
    }
  }
  
  // Upload captured image and detection results
  Future<void> _uploadDetection() async {
    if (_capturedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Uploading...';
    });
    
    try {
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'detection_${timestamp}.jpg';
      
      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('detections')
          .child(fileName);
      
      // Upload image
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': widget.user.uid,
          'timestamp': DateTime.now().toString(),
          'detectionMode': _currentMode.toString(),
          'detectionCount': _detections.length.toString(),
          'itemType': widget.itemType,
        },
      );
      
      // Upload file
      await storageRef.putFile(_capturedImage!, metadata);
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Save to Firestore
      await FirebaseFirestore.instance.collection('detections').add({
        'imageUrl': downloadUrl,
        'userId': widget.user.uid,
        'itemType': widget.itemType,
        'timestamp': FieldValue.serverTimestamp(),
        'detections': _detections.map((detection) => detection.toJson()).toList(),
      });
      
      setState(() {
        _isLoading = false;
      });
      
      // Return to previous screen with results
      _returnWithResults();
    } catch (e) {
      print('Error uploading detection: $e');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('Failed to upload: $e');
    }
  }
  
  // Switch camera
  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) {
      _showErrorSnackBar('No other cameras available');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Switching camera...';
      _isCameraInitialized = false;
    });
    
    // Dispose previous controller
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    
    // Update selected camera index
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    
    // Initialize new camera
    await _initCamera();
    
    setState(() {
      _isLoading = false;
    });
    
    // Restart real-time detection
    _startRealTimeDetection();
  }
  
  // Change detection mode
  Future<void> _changeDetectionMode(DetectionMode mode) async {
    if (mode == _currentMode) return;
    
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Changing detection mode...';
    });
    
    try {
      // Convert UI mode to service mode
      detection_service.DetectionModeType serviceMode;
      switch (mode) {
        case DetectionMode.basic:
          serviceMode = detection_service.DetectionModeType.basic;
          break;
        case DetectionMode.standard:
          serviceMode = detection_service.DetectionModeType.standard;
          break;
        case DetectionMode.detailed:
          serviceMode = detection_service.DetectionModeType.detailed;
          break;
        case DetectionMode.comprehensive:
          serviceMode = detection_service.DetectionModeType.comprehensive;
          break;
      }
      
      // Update mode in service
      await _detectionService.setDetectionMode(serviceMode);
      
      setState(() {
        _currentMode = mode;
        _isLoading = false;
      });
    } catch (e) {
      print('Error changing detection mode: $e');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('Failed to change mode: $e');
    }
  }
  
  // Change confidence threshold
  void _changeConfidenceThreshold(double value) {
    setState(() {
      _confidenceThreshold = value;
    });
    
    _detectionService.setConfidenceThreshold(value);
  }
  
  // Close results and restart camera
  void _closeResults() {
    setState(() {
      _showResults = false;
      _showControls = true;
    });
    
    // Restart real-time detection
    _startRealTimeDetection();
  }
  
  // Retake photo
  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _showResults = false;
      _showControls = true;
    });
    
    // Restart real-time detection
    _startRealTimeDetection();
  }
  
  // Return to previous screen with results
  void _returnWithResults() {
    if (_capturedImage != null) {
      Navigator.of(context).pop({
        'imagePath': _capturedImage!.path,
        'detections': _detections.map((detection) => detection.toJson()).toList(),
      });
    } else {
      Navigator.of(context).pop();
    }
  }
  
  // Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      // Free up resources
      if (_cameraController != null) {
        _cameraController!.dispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize camera
      _initCamera().then((_) {
        if (_isCameraInitialized) {
          _startRealTimeDetection();
        }
      });
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionService.dispose();
    
    // Fix for dispose method
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showResults && _capturedImage != null) {
          _returnWithResults();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? Center(child: LoadingWidget(message: _loadingMessage))
            : _buildCameraView(),
      ),
    );
  }
  
  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return Center(
        child: Text(
          'Camera initializing...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Stack(
      children: [
        // Camera preview
        CameraPreview(_cameraController!),
        
        // Bounding box overlay for real-time detection
        if (_detections.isNotEmpty && !_showResults)
          CustomPaint(
            painter: EnhancedDetectionPainter(
              detections: _detections,
              imageSize: _previewSize,
              previewSize: _previewSize,
              showLabels: true,
            ),
            size: MediaQuery.of(context).size,
          ),
        
        // Camera UI overlay
        if (_showControls)
          _buildCameraOverlay(),
        
        // Results view
        if (_showResults)
          _buildResultsView(),
          
        // Guide overlay
        if (!_showResults && _showControls)
          _buildGuideOverlay(),
      ],
    );
  }
  
  Widget _buildCameraOverlay() {
    return SafeArea(
      child: Column(
        children: [
          // App bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  '${widget.itemType.toUpperCase()} Item Lens',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help_outline, color: Colors.white),
                  onPressed: _showHelpDialog,
                ),
              ],
            ),
          ),
          
          Spacer(),
          
          // Status text
          if (_detections.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              margin: EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Found ${_detections.length} object${_detections.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Camera controls
          CameraControlsWidget(
            onCapture: _captureAndDetect,
            onSwitchCamera: _switchCamera,
            onChangeMode: _changeDetectionMode,
            onChangeConfidence: _changeConfidenceThreshold,
            isProcessing: _isProcessing,
            currentMode: _currentMode,
            confidenceThreshold: _confidenceThreshold,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsView() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _capturedImage != null
                ? Stack(
                    children: [
                      // Image
                      Image.file(
                        _capturedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                      
                      // Detection bounding boxes
                      if (_detections.isNotEmpty)
                        CustomPaint(
                          painter: EnhancedDetectionPainter(
                            detections: _detections,
                            imageSize: Size(
                              _capturedImage!.readAsBytesSync().lengthInBytes.toDouble(),
                              _capturedImage!.readAsBytesSync().lengthInBytes.toDouble(),
                            ),
                            previewSize: MediaQuery.of(context).size,
                            showLabels: true,
                          ),
                          size: MediaQuery.of(context).size,
                        ),
                    ],
                  )
                : Center(
                    child: Text(
                      'No image captured',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
          
          // Results panel
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            child: DetectionResultsWidget(
              detectedObjects: _detections,
              onClose: _closeResults,
              onRetake: _retakePhoto,
              onUseResults: _uploadDetection,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGuideOverlay() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.center_focus_strong,
              color: Colors.white.withOpacity(0.5),
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              'Position object in frame',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Object Detection Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Position your object within the guide'),
            SizedBox(height: 8),
            Text('• Ensure good lighting for best results'),
            SizedBox(height: 8),
            Text('• Try different detection modes for different objects'),
            SizedBox(height: 8),
            Text('• Use the confidence slider to adjust sensitivity'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
} 