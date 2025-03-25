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

  // This function picks an image and uploads it to the 'foodImages' folder.
  // On successful upload, it sets the provided controller's text to the download URL.
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
                    subtitle:
                        Text('\$${price.toStringAsFixed(2)}\n$description'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        final nameController =
                            TextEditingController(text: name);
                        final priceController =
                            TextEditingController(text: price.toString());
                        final descriptionController =
                            TextEditingController(text: description);
                        final imageUrlController =
                            TextEditingController(text: imageUrl);

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
                                    decoration: const InputDecoration(
                                        labelText: "Name"),
                                  ),
                                  TextField(
                                    controller: priceController,
                                    decoration: const InputDecoration(
                                        labelText: "Price"),
                                    keyboardType: TextInputType.number,
                                  ),
                                  TextField(
                                    controller: descriptionController,
                                    decoration: const InputDecoration(
                                        labelText: "Description"),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: imageUrlController,
                                          decoration: const InputDecoration(
                                              labelText: "Image URL"),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.upload_file),
                                        onPressed: () async {
                                          await _pickAndUploadFoodImage(
                                              imageUrlController);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final newName = nameController.text;
                                  final newPrice =
                                      double.tryParse(priceController.text) ??
                                          price;
                                  final newDescription =
                                      descriptionController.text;
                                  final newImageUrl = imageUrlController.text;

                                  await _firestore
                                      .collection('restaurants')
                                      .doc(widget.restaurantId)
                                      .collection('foodItems')
                                      .doc(docs[index].id)
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
                        );
                      },
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
