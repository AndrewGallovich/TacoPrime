import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({super.key});

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Controllers for restaurant creation.
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _restaurantAddressController = TextEditingController();

  // Controllers for adding food items.
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _foodPriceController = TextEditingController();
  final TextEditingController _foodDescriptionController = TextEditingController();
  final TextEditingController _foodImageUrlController = TextEditingController();

  // The restaurant document's ID (if it exists).
  String? restaurantId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  // Query Firestore to check if a restaurant exists for the current user.
  Future<void> _loadRestaurant() async {
    final querySnapshot = await _firestore
        .collection('restaurants')
        .where('ownerId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        restaurantId = querySnapshot.docs.first.id;
        _isLoading = false;
      });
    } else {
      setState(() {
        restaurantId = null;
        _isLoading = false;
      });
    }
  }

  // Create a new restaurant document with an auto-generated ID.
  Future<void> _createRestaurant() async {
    if (_restaurantNameController.text.isEmpty || _restaurantAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in restaurant name and address")),
      );
      return;
    }

    DocumentReference docRef = await _firestore.collection('restaurants').add({
      'name': _restaurantNameController.text,
      'address': _restaurantAddressController.text,
      'ownerId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      restaurantId = docRef.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restaurant created")),
    );
  }

  // Add a food item to the restaurant's subcollection.
  Future<void> _addFoodItem() async {
    if (restaurantId == null) return;

    double? price = double.tryParse(_foodPriceController.text);
    if (_foodNameController.text.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid food name and price")),
      );
      return;
    }

    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('foodItems')
        .add({
      'name': _foodNameController.text,
      'price': price,
      'description': _foodDescriptionController.text,
      'imageUrl': _foodImageUrlController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Clear the input fields.
    _foodNameController.clear();
    _foodPriceController.clear();
    _foodDescriptionController.clear();
    _foodImageUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Food item added")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sign Out Button
            MaterialButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              color: Colors.black,
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            // If restaurant doesn't exist, show form to create it.
            if (restaurantId == null) ...[
              const Text(
                'Create Your Restaurant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _restaurantNameController,
                decoration: const InputDecoration(labelText: 'Restaurant Name'),
              ),
              TextField(
                controller: _restaurantAddressController,
                decoration: const InputDecoration(labelText: 'Restaurant Address'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createRestaurant,
                child: const Text("Create Restaurant"),
              ),
            ] else ...[
              // Once the restaurant exists, show form to add food items.
              const Text(
                'Add Food Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _foodNameController,
                decoration: const InputDecoration(labelText: 'Food Name'),
              ),
              TextField(
                controller: _foodPriceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _foodDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _foodImageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addFoodItem,
                child: const Text("Add Food Item"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
