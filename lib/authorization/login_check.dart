import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tacoprime/pages/home_page.dart';
import 'package:tacoprime/pages/restaurant_home_page.dart';
import '../authorization/auth_page.dart';

class LoginCheck extends StatelessWidget {
  const LoginCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Listen to the auth state.
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user is not logged in, go to AuthPage.
          if (!snapshot.hasData) {
            return const AuthPage();
          }

          // 2. If logged in, get user’s Firestore document.
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

              // 3. Check the accountType field.
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final accountType = userData['accountType'];

              if (accountType == 'customer') {
                // Navigate to the Customer’s home page
                return const HomePage();
              } else if (accountType == 'restaurant') {
                // Navigate to the Restaurant’s home page
                return const RestaurantHomePage();
              } else {
                // Handle unexpected account types
                return const Center(child: Text('Unknown account type.'));
              }
            },
          );
        },
      ),
    );
  }
}
