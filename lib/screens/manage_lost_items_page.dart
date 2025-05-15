import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/notification_service.dart';

class ManageLostItemsPage extends StatefulWidget {
  final User user;

  const ManageLostItemsPage({Key? key, required this.user}) : super(key: key);

  @override
  _ManageLostItemsPageState createState() => _ManageLostItemsPageState();
}

class _ManageLostItemsPageState extends State<ManageLostItemsPage> {
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, bool> _loadingItems = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Manage Lost Items',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              // Force refresh the stream
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.tune, color: Colors.black),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search lost items...',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Items list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lost_items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final items = snapshot.data?.docs ?? [];
                
                // Sort the items manually to handle documents with or without createdAt
                final sortedItems = List.from(items);
                sortedItems.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  final aTimestamp = aData['createdAt'] as Timestamp?;
                  final bTimestamp = bData['createdAt'] as Timestamp?;
                  
                  // If both have timestamps, compare them
                  if (aTimestamp != null && bTimestamp != null) {
                    return bTimestamp.compareTo(aTimestamp); // Descending order
                  }
                  
                  // If only one has a timestamp, prioritize the one with timestamp
                  if (aTimestamp != null) return -1;
                  if (bTimestamp != null) return 1;
                  
                  // If neither has a timestamp, fallback to document ID
                  return b.id.compareTo(a.id);
                });
                
                if (sortedItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No lost items available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Filter items based on search query if provided
                final filteredItems = _searchQuery.isEmpty
                    ? sortedItems
                    : sortedItems.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toLowerCase();
                        final description = (data['description'] ?? '').toLowerCase();
                        final email = (data['reportedByEmail'] ?? '').toLowerCase();
                        
                        return name.contains(_searchQuery) || 
                               description.contains(_searchQuery) ||
                               email.contains(_searchQuery);
                      }).toList();
                
                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No matching items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final data = item.data() as Map<String, dynamic>;
                    final String itemId = item.id;
                    final bool isLoading = _loadingItems[itemId] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'LOST ITEM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          
                          // Item image
                          if (data['imageUrl'] != null)
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(data['imageUrl']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unnamed Item',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Description: ${data['description'] ?? 'No description'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Reported by: ${data['reportedByEmail'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Status: ${data['status'] ?? 'lost'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Edit button
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.edit),
                                      label: Text('Edit'),
                                      onPressed: isLoading
                                          ? null
                                          : () => _editItem(context, item),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Toggle approval button
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.check_circle),
                                      label: Text('Approve'),
                                      onPressed: isLoading
                                          ? null
                                          : () => _toggleApprovalStatus(itemId, data),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Delete button
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.delete),
                                      label: isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Delete'),
                                      onPressed: isLoading
                                          ? null
                                          : () => _confirmDelete(context, itemId),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _confirmDelete(BuildContext context, String itemId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    setState(() {
      _loadingItems[itemId] = true;
    });
    
    try {
      // Get the document reference to check for image URL
      final docRef = FirebaseFirestore.instance.collection('lost_items').doc(itemId);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final String? imageUrl = data['imageUrl'];
        
        // Delete the document from Firestore
        await docRef.delete();
        
        // If there's an image URL, also delete from Storage
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            // Extract the path from the URL
            final uri = Uri.parse(imageUrl);
            final path = uri.path;
            final storagePath = path.split('/o/')[1].split('?')[0];
            final decodedPath = Uri.decodeComponent(storagePath);
            
            // Delete from Firebase Storage
            await FirebaseStorage.instance.ref(decodedPath).delete();
            print('Image deleted from storage: $decodedPath');
          } catch (storageError) {
            print('Error deleting image: $storageError');
            // Continue even if image deletion fails
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingItems[itemId] = false;
        });
      }
    }
  }
  
  // Edit an item
  Future<void> _editItem(BuildContext context, DocumentSnapshot item) async {
    final data = item.data() as Map<String, dynamic>;
    
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    
    // Show edit dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Lost Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    // Dispose of controllers
    if (result != true) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }
    
    setState(() {
      _loadingItems[item.id] = true;
    });
    
    try {
      // Update the document in Firestore
      await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(item.id)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      if (mounted) {
        setState(() {
          _loadingItems[item.id] = false;
        });
      }
    }
  }

  // Toggle the approval status of an item
  Future<void> _toggleApprovalStatus(String itemId, Map<String, dynamic> itemData) async {
    setState(() {
      _loadingItems[itemId] = true;
    });
    
    try {
      final bool currentStatus = itemData['approved'] ?? false;
      final String itemName = itemData['name'] ?? 'Unknown Item';
      
      // Update approval status
      await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(itemId)
          .update({'approved': !currentStatus});
      
      // Send notification if we're approving the item
      if (!currentStatus) {
        await NotificationService().sendItemApprovedNotification(
          itemType: 'lost',
          itemName: itemName,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item approved successfully and notification sent'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item unapproved successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error toggling approval: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingItems[itemId] = false;
        });
      }
    }
  }
} 