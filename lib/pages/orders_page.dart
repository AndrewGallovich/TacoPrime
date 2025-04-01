import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'inside_order.dart';

class OrdersPage extends StatefulWidget {
  final String restaurantId;

  const OrdersPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'Pending Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('restaurants')
              .doc(widget.restaurantId)
              .collection('orders')
              .where('status', isEqualTo: 'pending')
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
              return const Center(child: Text('No pending orders found.'));
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final orderDoc = docs[index];
                final orderData = orderDoc.data() as Map<String, dynamic>;
                final total = orderData['total'] is int
                    ? (orderData['total'] as int).toDouble()
                    : orderData['total'] as double? ?? 0.0;
                final status = orderData['status'] ?? 'Pending';
                final items = orderData['items'] as List<dynamic>? ?? [];
                final timestamp = orderData['timestamp'] as Timestamp?;
                final dateString = timestamp != null
                    ? timestamp.toDate().toString()
                    : 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Order Total: \$${total.toStringAsFixed(2)}'),
                    subtitle: Text(
                      'Items: ${items.length}\nStatus: $status\nTime: $dateString',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Navigate to the inside order page for this order.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InsideOrder(
                              restaurantId: widget.restaurantId,
                              orderId: orderDoc.id,
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
