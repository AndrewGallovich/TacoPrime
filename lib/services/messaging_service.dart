// messaging_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// A service class for working with FCM and Cloud Functions from the client.
///
/// Responsibilities:
/// 1) Save this device's FCM token under users/{userId}/tokens/{token}.
/// 2) Call the backend callable function to send notifications.
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Call this after login (or when the user changes) to register the device token
  /// in Firestore under: users/{userId}/tokens/{token}.
  Future<void> saveDeviceTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('MessagingService: No FCM token available');
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': 'flutter',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('MessagingService: Saved FCM token for user $userId: $token');
    } catch (e) {
      print('MessagingService: Error saving FCM token: $e');
    }
  }

  /// Ask the backend to send a push notification to all devices for [userId].
  ///
  /// The actual FCM send is done in Cloud Functions (sendOrderNotification),
  /// so there are no secrets or access tokens in the client.
  Future<void> sendOrderNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final callable =
          _functions.httpsCallable('sendOrderNotification'); // must match export name in index.ts

      final result = await callable.call(<String, dynamic>{
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? <String, String>{},
      });

      print('MessagingService: sendOrderNotification result: ${result.data}');
    } catch (e) {
      print('MessagingService: Error calling sendOrderNotification: $e');
    }
  }

  /// Sends a notification to a user about their order status change.
  Future<void> sendNotificationToUser(
    String userId, {
    required String orderId,
    required String restaurantId,
  }) async {
    await sendOrderNotification(
      userId: userId,
      title: 'Order Update',
      body: 'Your order is now en route!',
      data: {
        'orderId': orderId,
        'restaurantId': restaurantId,
        'status': 'en route',
      },
    );
  }
}