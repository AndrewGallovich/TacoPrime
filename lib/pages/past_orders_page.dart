import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'inside_order.dart';  // Import the inside order page

class PastOrdersPage extends StatefulWidget {
  const PastOrdersPage({Key? key}) : super(key: key);

  @override
  State<PastOrdersPage> createState() => _PastOrdersPageState();
}

class _PastOrdersPageState extends State<PastOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Ensure the user is logged in.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view your orders.")),
      );
    }

    // Use a collection group query on 'orders' collections.
    // This query filters by userId and accepts orders that are either "completed" or "pending".
    Query ordersQuery = _firestore
        .collectionGroup('orders')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['completed', 'pending'])
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'Past & Pending Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: StreamBuilder<QuerySnapshot>(
          stream: ordersQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No orders found.'));
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                // Extract the order data.
                final orderData = docs[index].data() as Map<String, dynamic>;
                final total = orderData['total'] is int
                    ? (orderData['total'] as int).toDouble()
                    : orderData['total'] as double? ?? 0.0;
                final status = orderData['status'] ?? '';
                final items = orderData['items'] as List<dynamic>? ?? [];
                final timestamp = orderData['timestamp'] as Timestamp?;
                final dateString = timestamp != null
                    ? timestamp.toDate().toString()
                    : 'N/A';

                // Extract restaurantId from the document reference.
                // For a document in a collection group query, the reference path is:
                // restaurants/{restaurantId}/orders/{orderId}
                // So, the restaurantId is the parent of the parent of the document.
                final restaurantId = docs[index].reference.parent.parent?.id ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Order Total: \$${total.toStringAsFixed(2)}'),
                    subtitle: Text(
                      'Items: ${items.length}\nStatus: $status\nTime: $dateString',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Navigate to the InsideOrder page.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InsideOrder(
                              restaurantId: restaurantId,
                              orderId: docs[index].id,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Order'),
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
