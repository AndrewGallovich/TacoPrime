import 'package:flutter/material.dart';

class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({super.key});

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text('Restaurant Settings Page'),
    );
  }
}