import 'package:flutter/material.dart';
import 'package:tacoprime/components/bottom_nav_bar.dart';
import 'package:tacoprime/pages/customer/cart_page.dart';
import 'package:tacoprime/pages/map_page.dart';
import 'package:tacoprime/pages/customer/shop_page.dart';
import 'package:tacoprime/pages/customer/user_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  void navigateBottomBar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final List<Widget> pages = [
    const ShopPage(),
    const CartPage(),
    const UserSettingsPage(),
    const MapPage(key: PageStorageKey('map')), // stable key for map
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (index) => navigateBottomBar(index),
      ),
      // IndexedStack keeps each page alive, preventing map reloads
      body: IndexedStack(index: selectedIndex, children: pages),
    );
  }
}
