import 'package:flutter/material.dart';
import 'package:tacoprime/components/bottom_nav_bar.dart';
import 'package:tacoprime/pages/cart_page.dart';
import 'package:tacoprime/pages/shop_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

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
    const ShopPage(),

    // Cart Page
    const CartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      bottomNavigationBar: MyBottomNavBar(
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