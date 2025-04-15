import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/restaurant_service.dart';
import '../../services/image_service.dart';

class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  final _restaurantService = RestaurantService(); // for Firestore operations

  // Text controllers for restaurant creation
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _restaurantAddressController = TextEditingController();

  // Controllers for restaurant tile updates
  final TextEditingController _restaurantDescriptionController = TextEditingController();
  final TextEditingController _restaurantImageUrlController = TextEditingController();

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

    // Update the text field so the user can see the new URL
    setState(() {
      _restaurantImageUrlController.text = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text(
          "Restaurant Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
      ),
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Conditionally show the restaurant creation form or update tile section
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
              // Update existing restaurant tile section
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
                      decoration: const InputDecoration(labelText: 'Restaurant Image URL'),
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
            ],
            const SizedBox(height: 20),
            // Sign Out button placed at the bottom
            MaterialButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              color: Colors.black,
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
