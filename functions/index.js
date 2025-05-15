const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function that sends a notification to all users when a new item is approved
 * This is triggered by a write to a specific document in Firestore
 */
exports.sendApprovalNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notificationData = snapshot.data();
      
      // Ensure this is the right kind of notification
      if (!notificationData || !notificationData.title || !notificationData.body) {
        console.log('Invalid notification data:', notificationData);
        return null;
      }
      
      // Get all user tokens
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      if (usersSnapshot.empty) {
        console.log('No users found to send notifications to');
        return null;
      }
      
      // Prepare notification message
      const message = {
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: {
          itemType: notificationData.itemType || '',
          itemName: notificationData.itemName || '',
          timestamp: notificationData.timestamp 
            ? notificationData.timestamp.toString() 
            : Date.now().toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            icon: 'ic_launcher',
            color: '#FF4081',
            channelId: 'lost_found_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };
      
      // Collect all user tokens
      const tokens = [];
      usersSnapshot.forEach(userDoc => {
        const userData = userDoc.data();
        if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
          tokens.push(...userData.fcmTokens);
        }
      });
      
      // Remove duplicates
      const uniqueTokens = [...new Set(tokens)];
      
      if (uniqueTokens.length === 0) {
        console.log('No FCM tokens found to send notifications');
        return null;
      }
      
      console.log(`Sending notification to ${uniqueTokens.length} devices`);
      
      // Send notification to all users
      const response = await admin.messaging().sendMulticast({
        tokens: uniqueTokens,
        ...message
      });
      
      console.log(`Successfully sent notifications: ${response.successCount}/${uniqueTokens.length}`);
      
      // Update the notification document with delivery status
      await snapshot.ref.update({
        deliveryStatus: {
          sent: response.successCount,
          failed: response.failureCount,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        }
      });
      
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  }); 