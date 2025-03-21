import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantPreviewPage extends StatefulWidget {
  const RestaurantPreviewPage({super.key});

  @override
  State<RestaurantPreviewPage> createState() => _RestaurantPreviewPageState();
}

class _RestaurantPreviewPageState extends State<RestaurantPreviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Query Firestore to get the restaurant document for the logged in user.
  Future<String?> getRestaurantId() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('restaurants')
        .where('ownerId', isEqualTo: currentUserId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getRestaurantId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
              child: Text("Restaurant not found. Please create your restaurant."));
        }

        // We found the restaurant ID for the logged in user.
        final String restaurantId = snapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('foodItems')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, foodSnapshot) {
            if (foodSnapshot.hasError) {
              return Center(child: Text("Error: ${foodSnapshot.error}"));
            }
            if (foodSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = foodSnapshot.data?.docs ?? [];
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

                return ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.fastfood),
                  title: Text(name),
                  subtitle: Text('\$${price.toStringAsFixed(2)} \n$description'),
                );
              },
            );
          },
        );
      },
    );
  }
}
