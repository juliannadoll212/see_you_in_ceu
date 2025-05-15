import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math';
import 'object_detection_camera_page.dart';
import 'enhanced_object_detection_page.dart';

class ReportFoundItemPage extends StatefulWidget {
  final User user;

  const ReportFoundItemPage({Key? key, required this.user}) : super(key: key);

  @override
  _ReportFoundItemPageState createState() => _ReportFoundItemPageState();
}

class _ReportFoundItemPageState extends State<ReportFoundItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _officeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isImageUploaded = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  
  // Add a list to store detected objects
  List<Map<String, dynamic>> _detections = [];
  
  @override
  void initState() {
    super.initState();
    _checkStorageAccess();
    _verifyUserPermissions();
  }
  
  // Check if Firebase Storage is properly initialized and accessible
  Future<void> _checkStorageAccess() async {
    try {
      // Create test references to check if Firebase Storage is accessible
      print('Testing Firebase Storage access...');
      
      // 1. Test if Firebase Storage is initialized
      print('Firebase Storage instance: ${FirebaseStorage.instance}');
      print('Storage bucket: ${FirebaseStorage.instance.bucket}');
      
      // 2. Test if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('WARNING: No authenticated user found when checking storage access');
      } else {
        print('User authenticated as: ${currentUser.email} (${currentUser.uid})');
      }
      
      // 3. Attempt to list files instead of directly uploading
      // This is a less demanding permission check
      try {
        final storageRef = FirebaseStorage.instance.ref().child('found_items');
        print('Trying to list items in: ${storageRef.fullPath}');
        
        // Attempt to list instead of writing first
        final listResult = await storageRef.list(const ListOptions(maxResults: 1));
        if (listResult.items.isNotEmpty) {
          print('Found ${listResult.items.length} items in storage folder');
        } else {
          print('Storage folder exists but is empty');
        }
        
        print('Storage access check successful');
      } catch (e) {
        print('Storage access check failed: $e');
        
        // Don't show the error message immediately, as this might be a false alarm
        // We'll only show errors during actual upload attempts
      }
    } catch (e) {
      print('Firebase Storage initialization error: $e');
    }
  }

  // Verify if the current user has permission to upload files
  Future<void> _verifyUserPermissions() async {
    try {
      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('ERROR: No authenticated user found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You must be signed in to upload images'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      print('Current user: ${currentUser.email} (${currentUser.uid})');
      
      // Attempt a test upload to verify permissions
      try {
        // Create a tiny test file
        final List<int> bytes = utf8.encode('Permission test');
        final testBlob = Uint8List.fromList(bytes);
        
        // Create a temporary path for testing
        final tempFileName = 'permission_test_${DateTime.now().millisecondsSinceEpoch}.txt';
        final testRef = FirebaseStorage.instance
            .ref()
            .child('permission_tests')
            .child(tempFileName);
        
        print('Testing upload permissions with file: ${testRef.fullPath}');
        
        // Attempt to upload the test file
        final testTask = testRef.putData(
          testBlob,
          SettableMetadata(
            contentType: 'text/plain',
            customMetadata: {
              'purpose': 'permission_test',
              'user': currentUser.uid,
              'timestamp': DateTime.now().toString(),
            }
          )
        );
        
        // Wait for upload to complete
        await testTask;
        print('✅ Permission test successful: User can upload files');
        
        // Get the URL to verify accessibility
        final testUrl = await testRef.getDownloadURL();
        print('Test file accessible at: $testUrl');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have permission to upload images'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Delete the test file
        await testRef.delete();
        print('Test file deleted');
        
      } catch (e) {
        print('❌ Permission test failed: $e');
        
        String errorMessage = 'You don\'t have permission to upload images';
        if (e.toString().contains('unauthorized') || 
            e.toString().contains('permission-denied')) {
          errorMessage = 'Storage permission denied. Please contact the app administrator.';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'Storage location not found. The app may not be properly configured.';
        } else if (e.toString().contains('quota-exceeded')) {
          errorMessage = 'Storage quota exceeded. Please try again later.';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _verifyUserPermissions,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking user permissions: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress image for faster uploads
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isImageUploaded = true;
      });
      
      // Show a snackbar confirming image selection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image selected successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Helper method to take a photo with camera
  Future<void> _takePhoto() async {
    // Navigate to Enhanced Object Detection Page
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedObjectDetectionPage(
          user: widget.user,
          itemType: 'found',
        ),
      ),
    );
    
    // If a result was returned, use it
    if (result != null && result['imagePath'] != null) {
      setState(() {
        _selectedImage = File(result['imagePath']);
        _isImageUploaded = true;
        
        // Store detections if available
        if (result['detections'] != null) {
          _detections = List<Map<String, dynamic>>.from(result['detections']);
          
          // Auto-fill name field if not already filled and we have detections
          if (_nameController.text.isEmpty && _detections.isNotEmpty) {
            _nameController.text = _detections.first['label'] ?? '';
          }
          
          // Add detections to description if not already filled
          if (_descriptionController.text.isEmpty && _detections.isNotEmpty) {
            final detectionLabels = _detections.map((det) => 
                "${det['label']} (${(det['confidence'] * 100).toStringAsFixed(0)}%)").join(', ');
            _descriptionController.text = "Detected objects: $detectionLabels";
            
            // Add any additional description if available
            if (_detections.first['description'] != null) {
              _descriptionController.text += "\n\n${_detections.first['description']}";
            }
          }
        }
      });
      
      // Show a snackbar confirming image capture with rich detection results
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_detections.isNotEmpty 
            ? 'Enhanced detection found: ${_detections.map((d) => d['label']).join(', ')}'
            : 'Photo captured successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Simplified method to handle image upload and Firestore document creation
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });
      
      try {
        // Check if user is authenticated before attempting upload
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          print('ERROR: Not authenticated when trying to submit report');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You must be signed in to submit a report'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        print('User authenticated as: ${currentUser.email} (${currentUser.uid})');
        
        // Get form data
        final String itemName = _nameController.text;
        final String itemOffice = _officeController.text;
        final String itemDescription = _descriptionController.text;
        
        // Handle image upload first if an image was selected
        String? imageUrl;
        if (_selectedImage != null) {
          setState(() {
            _isUploading = true;
          });
          
          // Create storage reference with timestamp to ensure unique filenames
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('found_items/${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          print('Uploading image to: ${storageRef.fullPath}');
          
          try {
            // Upload the image and track progress
            final uploadTask = storageRef.putFile(
              _selectedImage!,
              SettableMetadata(
                contentType: 'image/jpeg',
                customMetadata: {
                  'uploadedBy': currentUser.uid,
                  'email': currentUser.email ?? 'unknown',
                  'timestamp': DateTime.now().toString()
                }
              )
            );
            
            // Listen to upload progress updates
            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              final progress = snapshot.bytesTransferred / snapshot.totalBytes;
              print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
              
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            });
            
            // Wait until upload is complete
            final snapshot = await uploadTask.whenComplete(() {
              print('Upload complete');
            });
            
            // Get the image URL
            imageUrl = await snapshot.ref.getDownloadURL();
            print('Image URL obtained: $imageUrl');
            
          } catch (uploadError) {
            print('Error uploading image: $uploadError');
            
            // Determine error type
            String errorMessage = 'Failed to upload image';
            if (uploadError.toString().contains('unauthorized')) {
              errorMessage = 'You don\'t have permission to upload images';
              print('PERMISSION ERROR: User lacks required permissions');
            }
            
            // Ask user if they want to continue without image
            bool continueWithoutImage = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Image Upload Failed'),
                content: Text('$errorMessage. Do you want to continue without the image?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Continue Without Image'),
                  ),
                ],
              ),
            ) ?? false; // Default to false if dialog is dismissed
            
            if (!continueWithoutImage) {
              // User chose to cancel
              setState(() {
                _isLoading = false;
                _isUploading = false;
              });
              return;
            }
            
            // Continue without image (imageUrl remains null)
            print('Continuing without image by user choice');
          } finally {
            if (mounted) {
              setState(() {
                _isUploading = false;
              });
            }
          }
        }
        
        // THEN save to Firestore (only after image upload is complete or skipped)
        try {
          print('Saving to Firestore: name=$itemName, office=$itemOffice, hasImage=${imageUrl != null}');
          
          final docRef = await FirebaseFirestore.instance.collection('found_items').add({
            'name': itemName,
            'office': itemOffice,
            'description': itemDescription,
            'imageUrl': imageUrl, // This won't be null if an image was uploaded successfully
            'foundBy': currentUser.uid,
            'foundByEmail': currentUser.email,
            'status': 'found',
            'approved': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('Document created with ID: ${docRef.id}');
          
          // Reset UI state
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isUploading = false;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(imageUrl != null 
                    ? 'Report submitted successfully with image!' 
                    : 'Report submitted successfully without image.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Reset form
            _nameController.clear();
            _officeController.clear();
            _descriptionController.clear();
            setState(() {
              _selectedImage = null;
              _isImageUploaded = false;
            });
            
            // Navigate back
            Navigator.pop(context);
          }
        } catch (firestoreError) {
          print('Error saving to Firestore: $firestoreError');
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isUploading = false;
            });
            
            // Show specific error for Firestore
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving report: $firestoreError'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        print('Error during submit: $e');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF0F5), // Light pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Report found item',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              // User profile action
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _isUploading && _uploadProgress > 0 ? _uploadProgress : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading
                        ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(1)}%'
                        : 'Submitting report...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Form container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name field
                            const Text(
                              'Name of Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Value',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the item name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Office field
                            const Text(
                              'Office surrendered',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _officeController,
                              decoration: InputDecoration(
                                hintText: 'Value',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the office';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Description field
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                hintText: 'Value',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              maxLines: 1, // Changed to match the design
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Image preview section
                            if (_selectedImage != null) ...[
                              Text(
                                'Selected Image',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (_detections.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Detected Objects:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 4.0,
                                  runSpacing: 4.0,
                                  children: _detections.map((detection) => Chip(
                                    label: Text(
                                      '${detection['label']} ${(detection['confidence'] * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.pink.shade100,
                                  )).toList(),
                                ),
                              ],
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: _pickImage,
                                    icon: Icon(Icons.photo_library),
                                    label: Text('Gallery'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFFFF4081),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  TextButton.icon(
                                    onPressed: _takePhoto,
                                    icon: Icon(Icons.camera_alt),
                                    label: Text('Retake'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFFFF4081),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                            ],
                            
                            // Upload image options
                            if (_selectedImage == null) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _pickImage,
                                      icon: Icon(Icons.photo_library),
                                      label: Text('Gallery'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFFF4081),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _takePhoto,
                                      icon: Icon(Icons.camera_alt),
                                      label: Text('Camera'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFFF4081),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                            ],
                            
                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF4081), // Pink color from design
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: _isUploading 
                                                ? CircularProgressIndicator(
                                                    value: _uploadProgress,
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  )
                                                : CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            _isUploading 
                                                ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%' 
                                                : 'Submitting...',
                                            style: TextStyle(fontSize: 16)
                                          ),
                                        ],
                                      )
                                    : Text('Submit', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _officeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 