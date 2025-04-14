import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tacoprime/components/restaurant_nav_bar.dart';
import 'package:tacoprime/pages/map_page.dart';
import 'package:tacoprime/pages/restaurant/orders_page.dart';
import 'package:tacoprime/pages/restaurant/restaurant_preview_page.dart';
import 'package:tacoprime/pages/restaurant/restaurant_settings_page.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  // Bottom Navigation Bar, this selected index will be used to navigate between the tabs
  int selectedIndex = 0;
  String? restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantId();
  }

  // Fetch the restaurant document ID for the logged-in user
  Future<void> _fetchRestaurantId() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('ownerId', isEqualTo: currentUserId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        restaurantId = querySnapshot.docs.first.id;
      });
    }
  }

  // pages to display; we use a FutureBuilder to ensure restaurantId is fetched
  @override
  Widget build(BuildContext context) {
    if (restaurantId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final List<Widget> pages = [
      // Pass the fetched restaurantId into the preview page.
      RestaurantPreviewPage(restaurantId: restaurantId!),
      OrdersPage(restaurantId: restaurantId!),
      const RestaurantSettingsPage(),
      const MapPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[300],
      bottomNavigationBar: RestaurantNavBar(
        onTabChange: (index) => setState(() {
          selectedIndex = index;
        }),
      ),
      body: pages[selectedIndex],
    );
  }
}
