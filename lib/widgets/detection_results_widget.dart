import 'package:flutter/material.dart';
import '../services/enhanced_detection_service.dart' as detection_service;

class DetectionResultsWidget extends StatelessWidget {
  final List<detection_service.DetectedObject> detectedObjects;
  final VoidCallback onClose;
  final VoidCallback onRetake;
  final VoidCallback? onUseResults;
  
  const DetectionResultsWidget({
    Key? key,
    required this.detectedObjects,
    required this.onClose,
    required this.onRetake,
    this.onUseResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detection Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          
          // Results list
          Expanded(
            child: detectedObjects.isEmpty
                ? _buildNoResultsMessage()
                : _buildResultsList(),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Retake'),
                    onPressed: onRetake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text('Use Results'),
                    onPressed: detectedObjects.isEmpty ? null : onUseResults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResultsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 16.0),
          Text(
            'No objects detected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'Try taking another photo or adjusting the confidence threshold',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: detectedObjects.length,
      padding: EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final item = detectedObjects[index];
        return _buildDetectionCard(item, context);
      },
    );
  }
  
  Widget _buildDetectionCard(detection_service.DetectedObject item, BuildContext context) {
    final hasDetails = item.description != null || 
                     (item.relatedTags != null && item.relatedTags!.isNotEmpty);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ExpansionTile(
        initiallyExpanded: index < 2, // Expand first two items by default
        title: Row(
          children: [
            _buildItemTypeIcon(item),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDetails)
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
              ),
          ],
        ),
        children: hasDetails
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.description != null) ...[
                        Divider(color: Colors.grey.shade700),
                        Text(
                          item.description!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (item.relatedTags != null && item.relatedTags!.isNotEmpty) ...[
                        Divider(color: Colors.grey.shade700),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: item.relatedTags!.map((tag) {
                            return Chip(
                              label: Text(
                                tag,
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }
  
  Widget _buildItemTypeIcon(detection_service.DetectedObject item) {
    IconData iconData;
    Color iconColor;
    
    if (item.label.toLowerCase().contains('text')) {
      iconData = Icons.text_fields;
      iconColor = Colors.blue;
    } else if (item.label.toLowerCase().contains('barcode')) {
      iconData = Icons.qr_code;
      iconColor = Colors.amber;
    } else {
      iconData = Icons.view_in_ar;
      iconColor = Colors.green;
    }
    
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
  
  // Returns the first index for use in the ExpansionTile
  int get index => 0;
} 