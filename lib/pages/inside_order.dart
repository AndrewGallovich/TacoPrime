import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  /// Marks the order as complete by updating its status.
  Future<void> _markOrderAsComplete() async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': 'completed'});
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

          // Parse order data
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
            padding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
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
                      final item =
                          items[index] as Map<String, dynamic>;
                      final name = item['name'] ?? 'No name';
                      final price = item['price'] is int
                          ? (item['price'] as int).toDouble()
                          : item['price'] as double? ?? 0.0;
                      final description = item['description'] ?? '';
                      final imageUrl = item['imageUrl'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8),
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
                // Show the "Mark as Complete" button only if the order isn't already completed.
                if (status != 'completed')
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
