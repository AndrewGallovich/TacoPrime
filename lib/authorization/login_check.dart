import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tacoprime/pages/customer/home_page.dart';
import 'package:tacoprime/pages/restaurant/restaurant_home_page.dart';
import '../authorization/auth_page.dart';

class LoginCheck extends StatefulWidget {
  const LoginCheck({Key? key}) : super(key: key);

  @override
  _LoginCheckState createState() => _LoginCheckState();
}

class _LoginCheckState extends State<LoginCheck> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _tokenSaved = false;

  /// Requests permission and saves FCM token to Firestore under the user's document.
  Future<void> _saveTokenToFirestore(String userId) async {
    try {
      // Request notification permissions (especially for iOS)
      await _messaging.requestPermission();
      // Get the token
      final token = await _messaging.getToken();
        await FirebaseFirestore.instance.collection('users').doc(userId)
            .update({'fcmToken': token});
        print('FCM token saved to Firestore for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AuthPage();
          }

          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Center(child: Text('User data not found.'));
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final accountType = userData['accountType'];

              // Save FCM token once per login
              if (!_tokenSaved) {
                _saveTokenToFirestore(user.uid);
                _tokenSaved = true;
              }

              if (accountType == 'customer') {
                return const HomePage();
              } else if (accountType == 'restaurant') {
                return const RestaurantHomePage();
              } else {
                return const Center(child: Text('Unknown account type.'));
              }
            },
          );
        },
      ),
    );
  }
}
