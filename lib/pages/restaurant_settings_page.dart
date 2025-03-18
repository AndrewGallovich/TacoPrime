import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({super.key});

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: MaterialButton(
              onPressed: () {
              FirebaseAuth.instance.signOut(); 
            },
            color: Colors.black,
            child: Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}