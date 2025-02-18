import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';

class RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  RestaurantTile({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        // Restaurant Image
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(restaurant.imagePath)),
        // Restaurant Name

        // Restaurant Description

        // Add to Cart Button
      ],),
    );
  }
}