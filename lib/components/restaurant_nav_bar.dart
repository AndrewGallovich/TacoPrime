import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class RestaurantNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;
  const RestaurantNavBar({super.key, required this.onTabChange});

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
            icon: Icons.store,
            text: ' Restaurant',
          ),
          GButton(
            icon: Icons.assignment,
            text: ' Orders',
          ),
          GButton(
            icon: Icons.settings,
            text: ' Settings',
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