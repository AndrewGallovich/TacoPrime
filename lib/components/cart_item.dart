import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';

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
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(widget.restaurant.imagePath),
      title: Text(widget.restaurant.name),
      subtitle: Text(widget.restaurant.description),
    );
  }
}