import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacoprime/components/restaurant_tile.dart';
import 'package:tacoprime/models/cart.dart';
import 'package:tacoprime/models/restaurant.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {

// add restaurant to cart
void addToCart(Restaurant restaurant) {
  Provider.of<Cart>(context, listen: false).addToCart(restaurant);

  // alert user that item was added to cart successfully
  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title: Text('Successfully added to cart'),
      content: Text('Check your cart'),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(builder: (context, value, child) => Column(
      children: [
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
          itemCount: 4,
          itemBuilder: (context, index) {
            // Create a Restaurant object
            Restaurant restaurant = value.getRestaurantList()[index];
            return RestaurantTile(
              restaurant: restaurant,
              onTap: () => addToCart(restaurant),
              );
            },
          )
        ),
      ],
    ),
    );
  }
}