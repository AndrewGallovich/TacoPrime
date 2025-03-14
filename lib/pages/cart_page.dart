import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacoprime/models/restaurant.dart';

import '../components/cart_item.dart';
import '../models/cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, value, child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // heading
        children: [
          const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),

          const SizedBox(height: 20),

          Expanded(child: ListView.builder(
            itemCount: value.getCart().length,
            itemBuilder: (context, index) {
            // get each restaurant
            Restaurant indivRestaurant = value.getCart()[index];

            // return the cart item
            return CartItem(restaurant: indivRestaurant,);

          }),
          ),

          SizedBox(height: 20),

          Center(
            child: MaterialButton(
              onPressed: () {
              FirebaseAuth.instance.signOut(); 
            },
            color: Colors.black,
            child: Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    )
    );
  }
}