// This file conditionally exports either the real camera package or mock implementation
// based on what's available in the project

export 'mock/camera_mock.dart';
// Uncomment the line below and comment the mock export when camera package is available
// export 'package:camera/camera.dart'; 