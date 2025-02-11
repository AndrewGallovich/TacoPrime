import 'package:flutter/material.dart';
import 'package:tacoprime/components/restaurant_nav_bar.dart';
import 'package:tacoprime/pages/restaurant_preview_page.dart';
import 'package:tacoprime/pages/restaurant_settings_page.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
 // Bottom Navigation Bar, this selected index will be used to navigate between the tabs
  int selectedIndex = 0;

  // this method updates the selected index
  // when user taps on the bottom navigation bar
  void navigateBottomBar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // pages to display
  final List<Widget> pages = [
    // Shop Page
    const RestaurantPreviewPage(),

    // Cart Page
    const RestaurantSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      bottomNavigationBar: RestaurantNavBar(
        onTabChange: (index) => navigateBottomBar(index),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: pages[selectedIndex],
    );
  }
}