import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantPreviewPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantPreviewPage({super.key, required this.restaurantId});

  @override
  State<RestaurantPreviewPage> createState() => _RestaurantPreviewPageState();
}

class _RestaurantPreviewPageState extends State<RestaurantPreviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text("Restaurant Preview"),
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
                    subtitle: Text('\$${price.toStringAsFixed(2)}\n$description'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Add the food item to the cart.
                        // This is where you connect your "add to cart" logic.
                      },
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
