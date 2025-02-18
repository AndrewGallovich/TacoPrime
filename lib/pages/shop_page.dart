import 'package:flutter/material.dart';
import 'package:tacoprime/components/restaurant_tile.dart';
import 'package:tacoprime/models/restaurant.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            // Create a Restaurant object
            Restaurant restaurant = Restaurant(
              name: 'Restaurant Name',
              imagePath: 'lib/images/restaurant.jpg',
              description: 'Restaurant Description',
            );
            return RestaurantTile(
              restaurant: restaurant,
            );
          },
        )),
      ],
    );
  }
}