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
  final String _accessToken = 'ya29.c.c0ASRK0GZliHPKHG_fH_aLk7210bDo_diUSmVxsjmE3LxtbsZjZpN4SnRJadywDmTSpYg-28wYLKAfHqvvr5iUgtMFYJt8aV9ylrtbQrCSj8mfWRb1KJf188Uw0Nylyq5cL6IjHWonLdYSBL33tuAvauX1RP94EcG4DvbNKf_ibya_LGZwtNqiblzb4tkDAi5n9YQSJguSPmrlC_Lmn8NY9M8ObsbYmrOoHxuNhaS9qN6lqPkp4EyuWsqPKsQAhCmmnVebY1uVpGx7O6ejQKT9ZtMGlBTPKRSg9F-gGx9U547OpBghLru5sEYGn39lUlFmu8xSTKhATIIdhRMlzKyR06OdxIrtaNjfTPF1Fess6OSfBT1_oCSO8FveN385KJOJ6B7iakvpVJmt8tXuIjXVnedcQwQM1-iYIhRs9uY7aIk5Fq67Rf2Y88jUjjXhwv8o_2jo4rm5sk9pbae9csSXZMV0ziY0ScuBJo6O7uxi6-ShZzIJsgmFuzh-cu6vF_o1tO0cq6Q0jxIV27fXvU0tk9S_xfhX7FiFUpldMhsxiI7W0kcbr_YjyOdgRe7JO_QJ980uYhd_34gS0omRuBd6h0beB3um4t_6te_c6ib4Zjgp0hgcpiVnipxZ9wzp_raV3xps4ov-yns0h9J66xpp4oYskSJ6pX8ek2WpiUVVIxBS9Xs1sfUViqgOnJYJ78bVt7ms1cI5kmItb6mlbJwQOilXpF6Oy-gR4W0trpavkW00w7Uaz06gbgOojQ_m9yB1vbyYbMFcMO7U3QpZZIpyRe_pRRZxJRuIn7lWsQ55didkOqd_ejO1-toB5qio7F3F6kzXqMujWB--xyR3hUtvURws1w9m35tuYaox6x-sUr6y_wh-934v9-51fqa48jI0_j7esQMfjS595BzqwkXBq-Wj0qw1Japkf-VpqfX6ozMMujme61eyrenQiXachXrnFs7k5ZuQY6XIqMXz9Unx-itJ84tidZaR81vwdo1OkS0te0eg6cg4l_s';

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
