import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database package
import 'package:flutter/material.dart';
import '../components/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Create a reference to the Realtime Database.
  final DatabaseReference _realtimeDatabase = FirebaseDatabase.instance.ref();

  Future<void> _orderNow() async {
    // Check if the user is signed in.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to place an order.")),
      );
      return;
    }
    
    // Reference to the current user's cart.
    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final cartSnapshot = await cartRef.get();

    // Check if the cart is empty.
    if (cartSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty.")),
      );
      return;
    }
    
    // Retrieve the restaurant ID from the first item in the cart.
    final firstData = cartSnapshot.docs.first.data();
    final restaurantId = firstData['restaurantId'];
    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant information missing in cart items.")),
      );
      return;
    }
    
    // Retrieve the restaurant document from Firestore.
    final restaurantDoc = await _firestore.collection('restaurants').doc(restaurantId).get();
    if (!restaurantDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant not found.")),
      );
      return;
    }
    
    final restaurantData = restaurantDoc.data();
    final restaurantAddress = restaurantData?['address'];
    if (restaurantAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant address not found.")),
      );
      return;
    }

    // Write the restaurant address to the Firebase Realtime Database.
    try {
      await _realtimeDatabase.child("restaurant_address").set({"address": restaurantAddress});
      print("Restaurant address successfully written to Realtime Database.");
    } catch (e) {
      print("Error writing restaurant address to Realtime Database: $e");
    }
    
    // Build a list of items and calculate the total.
    List<Map<String, dynamic>> items = [];
    double total = 0;
    for (var doc in cartSnapshot.docs) {
      final data = doc.data();
      items.add(data);
      total += (data['price'] is int
          ? (data['price'] as int).toDouble()
          : data['price'] as double);
    }
    
    // Prepare the order data for Firestore.
    final orderData = {
      'userId': user.uid,
      'items': items,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // initial order status
    };

    try {
      // Add order to the restaurant's orders collection in Firestore.
      final orderRef = _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .doc();
      await orderRef.set(orderData);

      // Clear the user's cart after placing the order.
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If the user isn't signed in, show a message or redirect.
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your cart.')),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('cart')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Your cart is empty.'));
                  }

                  // Build a list of cart items.
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return CartItem(
                        docId: doc.id,
                        name: data['name'] ?? 'No Name',
                        price: data['price'] ?? 0.0,
                        description: data['description'] ?? '',
                        imageUrl: data['imageUrl'] ?? '',
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Order Now button.
            Center(
              child: ElevatedButton(
                onPressed: _orderNow,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Order Now',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Sign Out button (optional).
            Center(
              child: ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
