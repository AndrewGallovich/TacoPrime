import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tacoprime/services/messaging_service.dart';

class InsideOrder extends StatefulWidget {
  final String restaurantId;
  final String orderId;

  const InsideOrder({
    Key? key,
    required this.restaurantId,
    required this.orderId,
  }) : super(key: key);

  @override
  State<InsideOrder> createState() => _InsideOrderState();
}

class _InsideOrderState extends State<InsideOrder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MessagingService _messagingService = MessagingService();

  // Store the user's account type.
  String _accountType = '';

  @override
  void initState() {
    super.initState();
    _getAccountType();
  }

  /// Fetch the current user's account type from Firestore.
  Future<void> _getAccountType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _accountType = userDoc.data()!['accountType'] ?? 'customer';
        });
      }
    }
  }

  /// Marks the order as complete by updating its status and sends a push notification.
  Future<void> _markOrderAsComplete() async {
    try {
      // Update the order status to "completed".
      await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': 'completed'});

      // Retrieve the updated order document.
      final orderDoc = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('orders')
          .doc(widget.orderId)
          .get();

      final orderData = orderDoc.data();

      if (orderData == null) {
        print("Order document data is null.");
        return;
      }

      // Ensure the order contains the 'userId' field.
      final userId = orderData['userId'];
      if (userId == null) {
        print("No userId found in the order document.");
      } else {
        // Send the notification using the MessagingService.
        await _messagingService.sendNotificationToUser(
          userId,
          orderId: widget.orderId,
          restaurantId: widget.restaurantId,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order marked as complete!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error marking order complete: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reference to the specific order document.
    final orderRef = _firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('orders')
        .doc(widget.orderId);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.grey[300],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: orderRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found."));
          }

          // Parse order data.
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final total = data['total'] is int
              ? (data['total'] as int).toDouble()
              : data['total'] as double? ?? 0.0;
          final status = data['status'] ?? 'pending';
          final items = data['items'] as List<dynamic>? ?? [];
          final timestamp = data['timestamp'] as Timestamp?;
          final orderDate = timestamp != null
              ? timestamp.toDate().toString()
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Status: $status'),
                const SizedBox(height: 10),
                Text('Ordered on: $orderDate'),
                const SizedBox(height: 20),
                const Text(
                  'Items:',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final name = item['name'] ?? 'No name';
                      final price = item['price'] is int
                          ? (item['price'] as int).toDouble()
                          : item['price'] as double? ?? 0.0;
                      final description = item['description'] ?? '';
                      final imageUrl = item['imageUrl'] ?? '';

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
                          subtitle: Text(
                              '\$${price.toStringAsFixed(2)}\n$description'),
                        ),
                      );
                    },
                  ),
                ),
                // Only show the "Mark as Complete" button if:
                // - The order is not already completed.
                // - The logged-in user's account type is not "customer".
                if (status != 'completed' && _accountType != 'customer')
                  Center(
                    child: ElevatedButton(
                      onPressed: _markOrderAsComplete,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text(
                        "Mark as Complete",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
