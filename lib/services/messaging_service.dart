// messaging_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// A service class for sending push notifications using the FCM HTTP v1 API.
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Replace with your own Firebase project ID.
  final String _projectId = 'tacoprime-bdb43';
  
  // Replace with your OAuth2 access token.
  // Note: This token must be generated securely using your service account credentials.
  final String _accessToken = 'ya29.c.c0ASRK0Ga_cNKdgNjHoGq9McoKR5XoSKPcJzDIHHKO3Kmf-TKJ5zNt91Avs2qwXCDyP76LqnK7a1gO1I3LPYDFuuCf8k0UYvHVrWunn_N2cEPp_Qgyh7a8rgD3_77I_YEDncbav4F3MvBtEOf58Bz-qDWp_JWTV6w5utxfg-8Ac8qLad2_3g6AbIIiE2j-Lr4gCeqWmqA_YDbSi-vpqq1do49p3TuW5-FiF7qSidxdxlmhJJ2bBxHvprWPOGs1-pfrVLxLG2fD6hZqjzoBGUgsVoah8xJFjKSGJJbD6VHTnpENNFKnNgGb4GIZeu1Vp0mP3q8Xn87oSz3sfykXBgHeA1mODjdPbYPeb8OcNuc2ESn681cGXDnF_fIMH385Dk7k__vtZWc8wxFWuyf2dtJglk_tbpe6Q4qxk0WdiIbJh7ydOYg5s0RhVI2XrcqaoIh-f5hSplY_6i4Zm7pdY-ljv0Jd11S8mV8S8wYpcgeBeIce5h4kIiYZlzxh-0yWj3R63es3lgeIbXfQzsuyW49eyh5JglW88a1dofxknopsibJe1z2vkJ0qJ-XY8Qq3YMrfs2dod-Ux8a3nQSUaVReZjbYUUz4tfl8hVWcM3tfenUc0n1i_nB5viF_aJBI27t3W06ydkR435xwjyhaJ7vBBaX6eRU1Rwm-4kvQb-p2qZ4OM9pnkfl8xcz7hvkv0wkunkxi2v5_iQs8ckUtwnOMfw0ke8Jb7Ws3lJnf0p6l-v6d-rlzlt7z8rk0-w-fUygwxhWdMxl0sa0_nt1gmcJpO1rM3zWkeyJ-sjyupeg-y6qkgJXwbbRxo37RqoVS3fQ7m7UtzZwz24mvecmm1fBV8b9jmRsQk6f8OwM31nOZ3VR59yur0X2VJ4byrklkvkfIzOkdc4rd82nUtnmkXftohQe4x-2oWnxdI4g-7jB-ehkqcwus4dd_fpYiOd7F9YYiyIk5_pq9SBQ0gjvOwuRnj9fzn2_0ns8p7RRho-kY61bI6-epOfVslm1Q';

  /// Sends a push notification to the user whose [userId] is specified.
  ///
  /// [orderId] and [restaurantId] are included in the data payload of the notification.
  Future<void> sendNotificationToUser(String userId,
      {required String orderId, required String restaurantId}) async {
    try {
      // Retrieve the user's document from Firestore to get the FCM token.
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print("User document for userId '$userId' not found.");
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];
      if (fcmToken == null) {
        print("No FCM token found for user '$userId'.");
        return;
      }

      // Create the notification payload in the HTTP v1 format.
      final Map<String, dynamic> notificationPayload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': 'Order Completed',
            'body': 'Your order has been marked as complete by the restaurant.',
          },
          'data': {
            'orderId': orderId,
            'restaurantId': restaurantId,
          },
        },
      };

      // Construct the HTTP v1 API endpoint URL.
      final uri = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

      // Send the notification using the FCM HTTP v1 endpoint.
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(notificationPayload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully.");
      } else {
        print(
            "Failed to send notification: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
