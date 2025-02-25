import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacoprime/models/restaurant.dart';

import '../models/cart.dart';

class CartItem extends StatefulWidget {
  final Restaurant restaurant;
  CartItem({
    super.key,
    required this.restaurant
    });

  @override
  State<CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<CartItem> {

// remove item from cart
void removeFromCart() {
  Provider.of<Cart>(context, listen: false).removeFromCart(widget.restaurant);

// alert user that item was removed from cart successfully
  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title: Text('Successfully removed'),
    ),
    );
}


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Image.asset(widget.restaurant.imagePath),
        title: Text(widget.restaurant.name),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => removeFromCart(),
          ),
      ),
    );
  }
}