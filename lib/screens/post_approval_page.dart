import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class PostApprovalPage extends StatefulWidget {
  final User user;

  const PostApprovalPage({Key? key, required this.user}) : super(key: key);

  @override
  _PostApprovalPageState createState() => _PostApprovalPageState();
}

class _PostApprovalPageState extends State<PostApprovalPage> with SingleTickerProviderStateMixin {
  Map<String, bool> _loadingItems = {};
  late TabController _tabController;
  bool _isVerifiedAdmin = false;
  bool _isVerifying = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Print and verify user authentication details
    final user = FirebaseAuth.instance.currentUser;
    print("Logged in as: ${user?.email}, UID: ${user?.uid}");
    
    // Verify UID matches expected value
    final expectedUid = "5V18pkO7okfjVBVO5sGwaMCvU9C2";
    if (user?.uid == expectedUid) {
      print("SUCCESS: UID matches expected value ($expectedUid)");
    } else {
      print("WARNING: UID does not match expected value");
      print("Current UID: ${user?.uid}");
      print("Expected UID: $expectedUid");
    }
    
    // Verify user is not null
    if (user != null) {
      print("SUCCESS: User is authenticated");
    } else {
      print("ERROR: User is null (not authenticated)");
    }
    
    _verifyAdminAccess();
  }
  
  Future<void> _verifyAdminAccess() async {
    // Get current user UID
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    print('Current admin UID: $currentUserUid');
    
    if (currentUserUid == null) {
      print('ERROR: No authenticated user found');
      if (mounted) {
        setState(() {
          _isVerifiedAdmin = false;
          _isVerifying = false;
        });
      }
      return;
    }
    
    // Check if user document exists in Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();
      
      if (!userDoc.exists) {
        print('ERROR: No matching user document found in Firestore');
        print('User UID: $currentUserUid');
        print('This must exactly match a document ID in the users collection');
        
        // Uncomment the line below to create admin user document if needed
        // await _createAdminUserIfNeeded(currentUserUid);
        
        if (mounted) {
          setState(() {
            _isVerifiedAdmin = false;
            _isVerifying = false;
          });
        }
        return;
      }
      
      // User document exists, now check if they have admin role
      final userData = userDoc.data();
      final bool isAdmin = userData?['isAdmin'] == true;
      
      if (mounted) {
        setState(() {
          _isVerifiedAdmin = isAdmin;
          _isVerifying = false;
        });
      }
      
      if (isAdmin) {
        print('VERIFIED: User is an admin according to Firestore');
      } else {
        print('WARNING: User exists but does not have admin privileges');
      }
      
    } catch (e) {
      print('ERROR checking Firestore: $e');
      if (mounted) {
        setState(() {
          _isVerifiedAdmin = false;
          _isVerifying = false;
        });
      }
    }
  }
  
  // Helper to create admin user document in Firestore
  Future<void> _createAdminUserIfNeeded(String uid) async {
    try {
      // Get the current user
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Create a document for this user in the users collection
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'isAdmin': true, // Set as admin
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('SUCCESS: Created admin user document in Firestore');
      setState(() {
        _isVerifiedAdmin = true;
      });
    } catch (e) {
      print('ERROR creating admin user: $e');
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveItem(String itemId, String collection) async {
    setState(() {
      _loadingItems[itemId] = true;
    });
    
    try {
      // Get the item data to use for the notification
      final itemDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(itemId)
          .get();
      
      if (!itemDoc.exists) {
        throw Exception('Item not found');
      }
      
      final itemData = itemDoc.data() as Map<String, dynamic>;
      final String itemName = itemData['name'] ?? 'Unknown Item';
      
      // Update the approval status
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(itemId)
          .update({'approved': true});
      
      // Determine if this is a lost or found item
      final String itemType = collection == 'found_items' ? 'found' : 'lost';
      
      // Send a notification to all users
      await NotificationService().sendItemApprovedNotification(
        itemType: itemType,
        itemName: itemName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item approved successfully and notification sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _loadingItems.remove(itemId);
        });
      }
    }
  }

  Future<void> _rejectItem(String itemId, String collection) async {
    setState(() {
      _loadingItems[itemId] = true;
    });
    
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(itemId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item rejected and removed'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _loadingItems.remove(itemId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Post Approval'),
        bottom: _isVerifiedAdmin ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Found Items', icon: Icon(Icons.check_circle)),
            Tab(text: 'Lost Items', icon: Icon(Icons.search_off)),
          ],
        ) : null,
      ),
      body: _isVerifying
          ? Center(child: CircularProgressIndicator())
          : (_isVerifiedAdmin 
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItemsList('found_items'),
                    _buildItemsList('lost_items'),
                  ],
                )
              : _buildAccessRestrictedView()),
    );
  }
  
  Widget _buildAccessRestrictedView() {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 80,
            color: Colors.red[300],
          ),
          SizedBox(height: 24),
          Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your account does not have admin privileges. This could be because:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReasonItem('Your UID does not match any document in the users collection'),
                SizedBox(height: 8),
                _buildReasonItem('Your user document exists but does not have admin privileges'),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (currentUserUid != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your User ID:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    currentUserUid,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This UID must exactly match a document ID in the users collection with admin privileges.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Go Back'),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  // This button would only be activated if you want to allow
                  // the current user to create an admin document
                  if (currentUserUid != null) {
                    await _createAdminUserIfNeeded(currentUserUid);
                    // Refresh admin verification
                    await _verifyAdminAccess();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('Request Access'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildReasonItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.arrow_right, size: 20, color: Colors.red[700]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildItemsList(String collection) {
    // Print and verify user authentication details before querying
    final user = FirebaseAuth.instance.currentUser;
    print("Before querying $collection - Logged in as: ${user?.email}, UID: ${user?.uid}");
    
    // Verify UID matches expected value
    final expectedUid = "5V18pkO7okfjVBVO5sGwaMCvU9C2";
    if (user?.uid == expectedUid) {
      print("SUCCESS: UID matches expected value ($expectedUid)");
    } else {
      print("WARNING: UID does not match expected value");
      print("Current UID: ${user?.uid}");
      print("Expected UID: $expectedUid");
    }
    
    // Verify user is not null
    if (user != null) {
      print("SUCCESS: User is authenticated before querying $collection");
    } else {
      print("ERROR: User is null (not authenticated) before querying $collection");
    }
    
    print("DEBUG: Querying $collection with filter approved=false");
    
    // First check if the collection has any documents at all
    FirebaseFirestore.instance.collection(collection).get().then((querySnapshot) {
      print("DEBUG: Total documents in $collection: ${querySnapshot.docs.length}");
      
      // Check specifically for unapproved items
      int unapprovedCount = 0;
      int approvedCount = 0;
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        bool isApproved = data['approved'] == true;
        
        if (isApproved) {
          approvedCount++;
        } else {
          unapprovedCount++;
          print("DEBUG: Found unapproved item in $collection: ${data['name']} (ID: ${doc.id})");
        }
      }
      
      print("DEBUG: $collection - approved items: $approvedCount, unapproved items: $unapprovedCount");
    }).catchError((error) {
      print("ERROR querying $collection: $error");
    });
    
    return StreamBuilder<QuerySnapshot>(
      // Fetch all items from the collection without filtering
      stream: FirebaseFirestore.instance
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("ERROR in StreamBuilder for $collection: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allItems = snapshot.data?.docs ?? [];
        print("DEBUG: StreamBuilder found ${allItems.length} total items in $collection");
        
        // Filter for unapproved items in code
        final items = allItems.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Include items where approved is explicitly false or missing/null
          return data['approved'] != true;
        }).toList();
        
        print("DEBUG: After filtering, found ${items.length} unapproved items in $collection");
        
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
                Icon(Icons.check_circle, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No pending items for approval',
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
          padding: EdgeInsets.all(16),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            final data = item.data() as Map<String, dynamic>;
            final bool isLoading = _loadingItems[item.id] ?? false;
            
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item image
                  if (data['imageUrl'] != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Loading image...')
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.red[300],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Image failed to load',
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'URL: ${data['imageUrl']}',
                                    style: TextStyle(fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        color: Colors.grey[300],
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[500],
                      ),
                    ),
                  
                  // Item details
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'No name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (data['office'] != null) ...[
                          Text(
                            'Office: ${data['office']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                        Text(
                          data['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          collection == 'found_items' 
                              ? 'Found by: ${data['foundByEmail'] ?? 'Unknown'}'
                              : 'Reported by: ${data['reportedByEmail'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (data['createdAt'] != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Date: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        
                        // Approval buttons
                        isLoading
                            ? Center(child: CircularProgressIndicator())
                            : Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _rejectItem(item.id, collection),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('Reject'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _approveItem(item.id, collection),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('Approve'),
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
    );
  }
} 