import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InsideRestaurant extends StatefulWidget {
  final String restaurantId;
  const InsideRestaurant({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<InsideRestaurant> createState() => _InsideRestaurantState();
}

class _InsideRestaurantState extends State<InsideRestaurant> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to add a food item to the cart.
  Future<void> _addToCart(Map<String, dynamic> foodItem) async {
    try {
      // Add the food item to the "cart" collection.
      await _firestore.collection('cart').add(foodItem);
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
                final foodItem = docs[index].data() as Map<String, dynamic>;
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
                    subtitle: Text('\$${price.toStringAsFixed(2)}\n$description'),
                    trailing: ElevatedButton(
                      onPressed: () => _addToCart(foodItem),
                      child: const Text("Add to Cart"),
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
