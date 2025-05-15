import 'package:flutter/material.dart';

enum DetectionMode {
  basic, // Simple detection with ML Kit labeling
  standard, // Object detection with bounding boxes
  detailed, // Object detection + text recognition
  comprehensive, // Object detection + text + barcode + cloud
}

class CameraControlsWidget extends StatelessWidget {
  // Function callbacks
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final Function(DetectionMode) onChangeMode;
  final Function(double) onChangeConfidence;
  
  // State properties
  final bool isProcessing;
  final DetectionMode currentMode;
  final double confidenceThreshold;
  
  const CameraControlsWidget({
    Key? key,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.onChangeMode,
    required this.onChangeConfidence,
    required this.isProcessing,
    this.currentMode = DetectionMode.standard,
    this.confidenceThreshold = 0.6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode selection row
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeButton(
                  context, 
                  DetectionMode.basic, 
                  'Basic', 
                  Icons.image_search,
                ),
                _buildModeButton(
                  context, 
                  DetectionMode.standard, 
                  'Objects', 
                  Icons.view_in_ar,
                ),
                _buildModeButton(
                  context, 
                  DetectionMode.detailed, 
                  'Text+', 
                  Icons.text_fields,
                ),
                _buildModeButton(
                  context, 
                  DetectionMode.comprehensive, 
                  'All', 
                  Icons.auto_awesome,
                ),
              ],
            ),
          ),
          
          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Confidence slider
              Expanded(
                child: Slider(
                  value: confidenceThreshold,
                  min: 0.1,
                  max: 0.9,
                  divisions: 8,
                  label: '${(confidenceThreshold * 100).toInt()}%',
                  onChanged: onChangeConfidence,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
              
              // Capture button
              GestureDetector(
                onTap: isProcessing ? null : onCapture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isProcessing 
                        ? Colors.grey 
                        : Theme.of(context).primaryColor,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: isProcessing
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
              ),
              
              // Switch camera button
              IconButton(
                onPressed: onSwitchCamera,
                icon: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton(
    BuildContext context, 
    DetectionMode mode, 
    String label, 
    IconData icon,
  ) {
    final isSelected = mode == currentMode;
    
    return GestureDetector(
      onTap: () => onChangeMode(mode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade800,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade300,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 