import 'package:flutter/material.dart';

class RestaurantPreviewPage extends StatefulWidget {
  const RestaurantPreviewPage({super.key});

  @override
  State<RestaurantPreviewPage> createState() => _RestaurantPreviewPageState();
}

class _RestaurantPreviewPageState extends State<RestaurantPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Restaurant Preview Page'),
    );
  }
}