import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../inside_order.dart';

class RestaurantPastOrdersPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantPastOrdersPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<RestaurantPastOrdersPage> createState() => _RestaurantPastOrdersPageState();
}

class _RestaurantPastOrdersPageState extends State<RestaurantPastOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper function to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'en route':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Query all orders for this restaurant, ordered by timestamp descending
    Query ordersQuery = _firestore
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('orders')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'All Orders',
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
                final address = orderData['address'] ?? 'No address';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Order Total: \$${total.toStringAsFixed(2)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Items: ${items.length}'),
                        const SizedBox(height: 4),
                        Text('Address: $address', 
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Status: '),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Time: $dateString'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Navigate to the InsideOrder page.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InsideOrder(
                              restaurantId: widget.restaurantId,
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