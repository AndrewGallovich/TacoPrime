import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantPreviewPage extends StatefulWidget {
  const RestaurantPreviewPage({super.key});

  @override
  State<RestaurantPreviewPage> createState() => _RestaurantPreviewPageState();
}

class _RestaurantPreviewPageState extends State<RestaurantPreviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Replace this with the actual restaurant document ID.
  final String restaurantId = "my_restaurant_id";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('restaurants')
          .doc(restaurantId)
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
            var foodItem = docs[index].data() as Map<String, dynamic>;
            String name = foodItem['name'] ?? '';
            double price = foodItem['price'] ?? 0.0;
            String description = foodItem['description'] ?? '';
            String imageUrl = foodItem['imageUrl'] ?? '';

            return ListTile(
              leading: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.fastfood),
              title: Text(name),
              subtitle: Text('\$${price.toString()} \n$description'),
            );
          },
        );
      },
    );
  }
}
