import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../inside_order.dart';

class OrdersPage extends StatefulWidget {
  final String restaurantId;

  const OrdersPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of only "pending" orders under
  /// restaurants/{restaurantId}/orders ordered by timestamp desc.
  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingOrdersStream() {
    return _db
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('orders')
        .where('status', isEqualTo: 'pending') // must match your stored value
        .orderBy('timestamp', descending: true) // Changed from 'createdAt' to 'timestamp'
        .snapshots();
  }

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
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _pendingOrdersStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No pending orders found.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();

                // Safely parse common fields
                final orderId = doc.id;
                final status = (data['status'] ?? '').toString();
                
                // Changed from 'createdAt' to 'timestamp' to match cart_page.dart
                final timestampTs = data['timestamp'];
                final timestamp = timestampTs is Timestamp ? timestampTs.toDate() : null;

                // Optional fields (defensive casts)
                final totalNum = data['total'];
                final total = totalNum is int
                    ? totalNum.toDouble()
                    : (totalNum is double ? totalNum : null);

                final customerName = data['customerName']?.toString();
                final address = data['address']?.toString();

                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: basic info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OrderID: $orderId',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (customerName != null && customerName.isNotEmpty)
                                Text('Customer: $customerName'),
                              if (address != null && address.isNotEmpty)
                                Text('Address: $address'),
                              if (total != null)
                                Text('Total: \$${total.toStringAsFixed(2)}'),
                              const SizedBox(height: 6),
                              Text(
                                'Status: $status',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (timestamp != null)
                                Text('Created: ${timestamp.toLocal()}'),
                            ],
                          ),
                        ),

                        // Right: Action
                        TextButton(
                          onPressed: () {
                            // Navigate to your inside order page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InsideOrder(
                                  restaurantId: widget.restaurantId,
                                  orderId: orderId,
                                ),
                              ),
                            );
                          },
                          child: const Text('View Order'),
                        ),
                      ],
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