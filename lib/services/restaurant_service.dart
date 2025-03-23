// lib/services/restaurant_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  /// Check if a restaurant exists for the current user.
  /// Returns the restaurant document ID if found, otherwise null.
  Future<String?> getRestaurantIdForOwner() async {
    final querySnapshot = await _firestore
        .collection('restaurants')
        .where('ownerId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  /// Load existing restaurant data fields (like description, imagePath).
  /// Returns a Map or null if not found.
  Future<Map<String, dynamic>?> getRestaurantData(String restaurantId) async {
    final doc = await _firestore.collection('restaurants').doc(restaurantId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Create a new restaurant document in Firestore.
  /// Returns the newly created doc ID.
  Future<String> createRestaurant({
    required String name,
    required String address,
    required String description,
    required String imagePath,
  }) async {
    final docRef = await _firestore.collection('restaurants').add({
      'name': name,
      'address': address,
      'ownerId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'description': description,
      'imagePath': imagePath,
    });
    return docRef.id;
  }

  /// Update restaurant tile fields (description + imagePath).
  Future<void> updateRestaurantTile({
    required String restaurantId,
    required String description,
    required String imagePath,
  }) async {
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'description': description,
      'imagePath': imagePath,
    });
  }

  /// Add a new food item to the restaurant's subcollection.
  Future<void> addFoodItem({
    required String restaurantId,
    required String name,
    required double price,
    required String description,
    required String imageUrl,
  }) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('foodItems')
        .add({
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
