import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InsideRestaurant extends StatefulWidget {
  final String restaurantId;

  const InsideRestaurant({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  State<InsideRestaurant> createState() => _InsideRestaurantState();
}

class _InsideRestaurantState extends State<InsideRestaurant> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a food item to the currently logged-in user's cart.
  /// Ensures that the cart contains items only from one restaurant.
  Future<void> _addToCart(Map<String, dynamic> foodItem) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Optionally handle the case when user is not signed in.
        return;
      }

      // Reference to the current user's cart subcollection.
      final cartRef =
          _firestore.collection('users').doc(user.uid).collection('cart');

      // Check existing items in the cart.
      final cartSnapshot = await cartRef.get();
      if (cartSnapshot.docs.isNotEmpty) {
        // Get the restaurantId from the first cart item.
        final existingData = cartSnapshot.docs.first.data();
        final existingRestaurantId = existingData['restaurantId'];

        // If the current restaurant does not match the one in the cart,
        // prompt the user to clear the cart.
        if (existingRestaurantId != widget.restaurantId) {
          final shouldClear = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Different Restaurant"),
              content: const Text(
                  "Your cart contains items from a different restaurant. Would you like to clear your cart and add items from this restaurant?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Clear Cart",
                    style: TextStyle(color: Colors.red),
                    ),
                ),
              ],
            ),
          );

          if (shouldClear != true) {
            // If the user cancels, do not add the new item.
            return;
          } else {
            // Clear all existing items from the cart.
            for (var doc in cartSnapshot.docs) {
              await doc.reference.delete();
            }
          }
        }
      }

      // Add the food item to the cart with the restaurantId.
      await cartRef.add({
        'name': foodItem['name'],
        'price': foodItem['price'],
        'description': foodItem['description'],
        'imageUrl': foodItem['imageUrl'],
        'restaurantId': widget.restaurantId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${foodItem['name']} added to cart!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text("Food Items"),
        backgroundColor: Colors.grey[300],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('restaurants')
              .doc(widget.restaurantId)
              .collection('foodItems')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("No food items available."));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final foodItem =
                    docs[index].data() as Map<String, dynamic>;
                final name = foodItem['name'] ?? '';
                final price = foodItem['price'] ?? 0.0;
                final description = foodItem['description'] ?? '';
                final imageUrl = foodItem['imageUrl'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.fastfood),
                    title: Text(name),
                    subtitle:
                        Text('\$${price.toStringAsFixed(2)}\n$description'),
                    trailing: ElevatedButton(
                      onPressed: () => _addToCart(foodItem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
