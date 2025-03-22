import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';
import '../components/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Cart is empty.'));
          }
          // Map each Firestore document to a Restaurant object.
          List<Restaurant> cartItems = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Restaurant(
              id: doc.id,
              name: data['name'] ?? 'No Name',
              description: data['description'] ?? '',
              imagePath: data['imageUrl'] ?? '',
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Cart',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return CartItem(restaurant: cartItems[index]);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: MaterialButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    color: Colors.black,
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
