import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartItem extends StatelessWidget {
  final String docId;
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  const CartItem({
    Key? key,
    required this.docId,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  }) : super(key: key);

  /// Remove this specific item from the Firestore cart document.
  Future<void> removeFromCart(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete the document in /users/{uid}/cart/{docId}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name removed from cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing $name: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => removeFromCart(context),
        ),
      ),
    );
  }
}
