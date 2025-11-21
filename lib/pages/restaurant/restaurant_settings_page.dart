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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _restaurantDescriptionController.dispose();
    _restaurantImageUrlController.dispose();
    super.dispose();
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

    setState(() => _isSaving = true);

    try {
      final newId = await _restaurantService.createRestaurant(
        name: _restaurantNameController.text,
        address: _restaurantAddressController.text,
        description: _restaurantDescriptionController.text,
        imagePath: _restaurantImageUrlController.text,
      );

      setState(() {
        restaurantId = newId;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restaurant created successfully")),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating restaurant: $e")),
        );
      }
    }
  }

  // Update restaurant tile
  Future<void> _updateRestaurantTile() async {
    if (restaurantId == null) return;

    setState(() => _isSaving = true);

    try {
      await _restaurantService.updateRestaurantTile(
        restaurantId: restaurantId!,
        description: _restaurantDescriptionController.text,
        imagePath: _restaurantImageUrlController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restaurant tile updated")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating: $e")),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[300],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'Restaurant Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Profile info card
          if (user != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green,
                      child: Text(
                        (user.displayName?.isNotEmpty == true
                            ? user.displayName!.substring(0, 1).toUpperCase()
                            : (user.email?.substring(0, 1).toUpperCase() ?? 'R')),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName ?? 'Restaurant Owner',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(user.email ?? '',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Conditionally show the restaurant creation form or update tile section
          if (restaurantId == null) ...[
            // Create Restaurant Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Your Restaurant',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _restaurantNameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _restaurantAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _restaurantDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _restaurantImageUrlController.text.isEmpty
                                ? Icons.image_outlined
                                : Icons.check_circle_outline,
                            color: _restaurantImageUrlController.text.isEmpty
                                ? Colors.grey[600]
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _restaurantImageUrlController.text.isEmpty
                                  ? 'No image uploaded'
                                  : 'Image uploaded successfully',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                            onPressed: _pickAndUploadRestaurantImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _createRestaurant,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ))
                            : const Icon(Icons.add_business),
                        label: Text(_isSaving ? 'Creating...' : 'Create Restaurant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Update Restaurant Tile Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update Restaurant Tile',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _restaurantDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _restaurantImageUrlController.text.isEmpty
                                ? Icons.image_outlined
                                : Icons.check_circle_outline,
                            color: _restaurantImageUrlController.text.isEmpty
                                ? Colors.grey[600]
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _restaurantImageUrlController.text.isEmpty
                                  ? 'No image uploaded'
                                  : 'Image uploaded successfully',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                            onPressed: _pickAndUploadRestaurantImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _updateRestaurantTile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ))
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Sign out card
          Card(
            color: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: const Center(
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              onTap: _signOut,
            ),
          ),
        ],
      ),
    );
  }
}