import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyBottomNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;
  MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: GNav(
        color: Colors.grey[400],
        activeColor: Colors.grey[900],
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.grey.shade100,
        mainAxisAlignment: MainAxisAlignment.center,
        tabBorderRadius: 16,
        onTabChange: (value) => onTabChange!(value),
        tabs: [
          GButton(
            icon: Icons.fastfood,
            text: ' Eat',
          ),
          GButton(
            icon: Icons.shopping_bag_rounded,
            text: ' Cart',
          ),
          GButton(
            icon: Icons.account_circle,
            text: ' Profile',
          ),
          GButton(
            icon: Icons.map,
            text: ' Map',
          ),
        ],
        )
    );
  }
}