import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:tacoprime/components/points_status_card.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _users = FirebaseFirestore.instance.collection('users');

  // Separate controllers for each address field
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  bool _emergencyStop = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserFields();
    _subscribeEmergencyStop();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _buildingController.dispose();
    _roomController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _loadUserFields() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snap = await _users.doc(user.uid).get();
      final data = snap.data();
      if (data != null && data['address'] != null) {
        // Parse the combined address back into fields (simple split by comma)
        final address = data['address'] as String;
        final parts = address.split(',').map((e) => e.trim()).toList();
        
        // Try to populate fields based on what we can parse
        if (parts.isNotEmpty) _streetController.text = parts[0];
        if (parts.length > 1) _buildingController.text = parts[1];
        if (parts.length > 2) _roomController.text = parts[2];
        if (parts.length > 3) _cityController.text = parts[3];
        if (parts.length > 4) _stateController.text = parts[4];
        if (parts.length > 5) _zipController.text = parts[5];
      }
    } catch (e) {
      debugPrint('Error loading user fields: $e');
    }
  }

  void _subscribeEmergencyStop() {
    final stream = _db.child('emergency_stop').onValue;
    stream.listen((event) {
      final val = event.snapshot.value;
      if (val is bool) {
        setState(() => _emergencyStop = val);
      } else if (val is int) {
        setState(() => _emergencyStop = val == 1);
      }
    }, onError: (e) {
      debugPrint('Error listening emergency_stop: $e');
    });
  }

  String _combineAddress() {
    // Combine all non-empty fields with commas
    final parts = [
      _streetController.text.trim(),
      _buildingController.text.trim(),
      _roomController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _zipController.text.trim(),
    ].where((part) => part.isNotEmpty).toList();
    
    return parts.join(', ');
  }

  Future<void> _saveAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final combinedAddress = _combineAddress();
      
      if (combinedAddress.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter at least one address field')),
          );
        }
        return;
      }

      setState(() => _saving = true);
      await _users.doc(user.uid).set(
        {
          'address': combinedAddress,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved')),
        );
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleEmergencyStop(bool value) async {
    try {
      await _db.child('emergency_stop').set(value);
    } catch (e) {
      debugPrint('Error updating emergency_stop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update emergency stop: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const PointsStatusCard(),
          const SizedBox(height: 8),

          // Basic profile info
          if (user != null) Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      (user.displayName?.isNotEmpty == true
                              ? user.displayName!.substring(0, 1).toUpperCase()
                              : (user.email?.substring(0, 1).toUpperCase() ?? 'U')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'Aggie',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(user.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Address editor with separate fields
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery address',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      hintText: 'e.g., 123 Main St',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _buildingController,
                          decoration: const InputDecoration(
                            labelText: 'Building',
                            hintText: 'Building name/number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                            labelText: 'Room',
                            hintText: 'Room #',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g., College Station',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            hintText: 'TX',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _zipController,
                          decoration: const InputDecoration(
                            labelText: 'ZIP Code',
                            hintText: '77840',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveAddress,
                      icon: _saving
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Emergency stop switch
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Emergency stop'),
              subtitle: const Text('Immediately stop the robot'),
              value: _emergencyStop,
              onChanged: _toggleEmergencyStop,
              secondary: const Icon(Icons.warning_amber_outlined),
            ),
          ),

          const SizedBox(height: 8),

          // Sign out
          Card(
            color: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: const Center(
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              onTap: _signOut,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}