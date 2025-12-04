import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../components/cart_item.dart';
import 'past_orders_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _realtimeDatabase = FirebaseDatabase.instance.ref();

  String _userAddress = '';

  @override
  void initState() {
    super.initState();
    _subscribeToAddress();
  }

  // Listen to address changes in real-time
  void _subscribeToAddress() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          setState(() {
            _userAddress = (doc.data()!['address'] ?? '') as String;
          });
        }
      });
    }
  }

  Future<void> _orderNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to place an order.")),
      );
      return;
    }
    
    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final cartSnapshot = await cartRef.get();

    if (cartSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty.")),
      );
      return;
    }
    
    final firstData = cartSnapshot.docs.first.data();
    final restaurantId = firstData['restaurantId'];
    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant information missing in cart items.")),
      );
      return;
    }
    
    final restaurantDoc = await _firestore.collection('restaurants').doc(restaurantId).get();
    if (!restaurantDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant not found.")),
      );
      return;
    }
    
    final restaurantData = restaurantDoc.data();
    final restaurantAddress = restaurantData?['address'];
    if (restaurantAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant address not found.")),
      );
      return;
    }

    try {
      await _realtimeDatabase.child("restaurant_address").set({"address": restaurantAddress});
      await _realtimeDatabase.child("standby").set(0);
      print("Restaurant address and Standby successfully written to Realtime Database.");
    } catch (e) {
      print("Error writing to Realtime Database: $e");
    }
    
    List<Map<String, dynamic>> items = [];
    double total = 0;
    for (var doc in cartSnapshot.docs) {
      final data = doc.data();
      items.add(data);
      total += (data['price'] is int
          ? (data['price'] as int).toDouble()
          : data['price'] as double);
    }
    
    final orderData = {
      'userId': user.uid,
      'items': items,
      'total': total,
      'status': 'pending',
      'address': _userAddress.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      final orderRef = _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .doc();
      await orderRef.set(orderData);

      final pointsToAdd = total.floor();
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({'points': FieldValue.increment(pointsToAdd)}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to update points: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed, but points could not be updated right now.")),
        );
      }

      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your cart.')),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('cart')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Your cart is empty.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return CartItem(
                        docId: doc.id,
                        name: data['name'] ?? 'No Name',
                        price: data['price'] ?? 0.0,
                        description: data['description'] ?? '',
                        imageUrl: data['imageUrl'] ?? '',
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _userAddress.trim().isNotEmpty ? _orderNow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userAddress.trim().isNotEmpty ? Colors.green : Colors.grey,
                ),
                child: Text(
                  _userAddress.trim().isNotEmpty ? 'Order Now' : 'Please input address',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        elevation: 0,
        child: const Icon(
          Icons.shopping_bag,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PastOrdersPage()),
          );
        },
      ),
    );
  }
}