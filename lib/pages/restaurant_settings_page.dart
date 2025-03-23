// lib/pages/restaurant_settings_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/restaurant_service.dart';
import '../services/image_service.dart';

class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  final _restaurantService = RestaurantService(); // for Firestore ops

  // Text controllers for restaurant creation
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _restaurantAddressController = TextEditingController();

  // Controllers for restaurant tile updates
  final TextEditingController _restaurantDescriptionController = TextEditingController();
  final TextEditingController _restaurantImageUrlController = TextEditingController();

  // Controllers for adding food items
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _foodPriceController = TextEditingController();
  final TextEditingController _foodDescriptionController = TextEditingController();
  final TextEditingController _foodImageUrlController = TextEditingController();

  // The restaurant doc ID (if it exists)
  String? restaurantId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    // 1. Check if there's already a restaurant for this user
    final existingId = await _restaurantService.getRestaurantIdForOwner();
    if (existingId == null) {
      // No restaurant yet
      setState(() {
        restaurantId = null;
        _isLoading = false;
      });
      return;
    }

    // 2. If yes, load existing data
    final data = await _restaurantService.getRestaurantData(existingId);
    setState(() {
      restaurantId = existingId;
      _restaurantDescriptionController.text = data?['description'] ?? '';
      _restaurantImageUrlController.text = data?['imagePath'] ?? '';
      _isLoading = false;
    });
  }

  // Create a new restaurant doc
  Future<void> _createRestaurant() async {
    if (_restaurantNameController.text.isEmpty ||
        _restaurantAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in restaurant details")),
      );
      return;
    }

    final newId = await _restaurantService.createRestaurant(
      name: _restaurantNameController.text,
      address: _restaurantAddressController.text,
      description: _restaurantDescriptionController.text,
      imagePath: _restaurantImageUrlController.text,
    );

    setState(() {
      restaurantId = newId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restaurant created")),
    );
  }

  // Update restaurant tile
  Future<void> _updateRestaurantTile() async {
    if (restaurantId == null) return;

    await _restaurantService.updateRestaurantTile(
      restaurantId: restaurantId!,
      description: _restaurantDescriptionController.text,
      imagePath: _restaurantImageUrlController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restaurant tile updated")),
    );
  }

  // Add a new food item
  Future<void> _addFoodItem() async {
    if (restaurantId == null) return;

    final price = double.tryParse(_foodPriceController.text);
    if (_foodNameController.text.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid name and price")),
      );
      return;
    }

    await _restaurantService.addFoodItem(
      restaurantId: restaurantId!,
      name: _foodNameController.text,
      price: price,
      description: _foodDescriptionController.text,
      imageUrl: _foodImageUrlController.text,
    );

    // Clear fields
    _foodNameController.clear();
    _foodPriceController.clear();
    _foodDescriptionController.clear();
    _foodImageUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Food item added")),
    );
  }

  // Pick & upload a restaurant image
  Future<void> _pickAndUploadRestaurantImage() async {
    final file = await ImageService.pickImage();
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    final downloadUrl = await ImageService.uploadImage(file, 'restaurantImages');
    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
      return;
    }

    // Update the text field so user can see the new URL
    setState(() {
      _restaurantImageUrlController.text = downloadUrl;
    });
  }

  // Pick & upload a food image
  Future<void> _pickAndUploadFoodImage() async {
    final file = await ImageService.pickImage();
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    final downloadUrl = await ImageService.uploadImage(file, 'foodImages');
    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
      return;
    }

    // Update the text field
    setState(() {
      _foodImageUrlController.text = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sign Out button
          MaterialButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            color: Colors.black,
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),

          // If no restaurant, show creation form
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
            // Update existing restaurant
            const Text(
              'Update Restaurant Tile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _restaurantDescriptionController,
              decoration: const InputDecoration(labelText: 'Restaurant Description'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _restaurantImageUrlController,
                    decoration:
                        const InputDecoration(labelText: 'Restaurant Image URL'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _pickAndUploadRestaurantImage,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateRestaurantTile,
              child: const Text("Update Restaurant Tile"),
            ),
            const SizedBox(height: 40),

            // Add food items
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _foodImageUrlController,
                    decoration:
                        const InputDecoration(labelText: 'Food Image URL'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _pickAndUploadFoodImage,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addFoodItem,
              child: const Text("Add Food Item"),
            ),
          ],
        ],
      ),
    );
  }
}
