import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

class RestaurantPreviewPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantPreviewPage({super.key, required this.restaurantId});

  @override
  State<RestaurantPreviewPage> createState() => _RestaurantPreviewPageState();
}

class _RestaurantPreviewPageState extends State<RestaurantPreviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper function to pick and upload an image.
  Future<void> _pickAndUploadFoodImage(TextEditingController controller) async {
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
    controller.text = downloadUrl;
  }

  // Shows the dialog for editing an existing food item, including the delete action.
  void _showEditDialog(DocumentSnapshot doc) {
    final foodItem = doc.data() as Map<String, dynamic>;
    final name = foodItem['name'] ?? '';
    final price = foodItem['price'] ?? 0.0;
    final description = foodItem['description'] ?? '';
    final imageUrl = foodItem['imageUrl'] ?? '';

    final nameController = TextEditingController(text: name);
    final priceController = TextEditingController(text: price.toString());
    final descriptionController = TextEditingController(text: description);
    final imageUrlController = TextEditingController(text: imageUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Food Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: "Image URL"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: () async {
                      await _pickAndUploadFoodImage(imageUrlController);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Custom layout for action buttons.
          Container(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Delete button with red text.
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Are you sure you want to delete this food item?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _firestore
                          .collection('restaurants')
                          .doc(widget.restaurantId)
                          .collection('foodItems')
                          .doc(doc.id)
                          .delete();
                      Navigator.of(context).pop(); // close the edit dialog
                    }
                  },
                  child: const Text("Delete"),
                ),
                // Right side: Cancel and Save buttons grouped together.
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text;
                        final newPrice = double.tryParse(priceController.text) ?? price;
                        final newDescription = descriptionController.text;
                        final newImageUrl = imageUrlController.text;

                        await _firestore
                            .collection('restaurants')
                            .doc(widget.restaurantId)
                            .collection('foodItems')
                            .doc(doc.id)
                            .update({
                          'name': newName,
                          'price': newPrice,
                          'description': newDescription,
                          'imageUrl': newImageUrl,
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shows the dialog for adding a new food item.
  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Food Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: "Image URL"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: () async {
                      await _pickAndUploadFoodImage(imageUrlController);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final price = double.tryParse(priceController.text) ?? 0.0;
              final description = descriptionController.text;
              final imageUrl = imageUrlController.text;

              await _firestore
                  .collection('restaurants')
                  .doc(widget.restaurantId)
                  .collection('foodItems')
                  .add({
                'name': name,
                'price': price,
                'description': description,
                'imageUrl': imageUrl,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.of(context).pop();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text(
          "Restaurant Preview",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
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
                      onPressed: () => _showEditDialog(docs[index]),
                      child: const Text("Edit"),
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
