import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:tacoprime/components/points_status_card.dart'; // <-- make sure this path matches your project

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _users = FirebaseFirestore.instance.collection('users');

  final _addressController = TextEditingController();
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
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserFields() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snap = await _users.doc(user.uid).get();
      final data = snap.data();
      if (data != null && data['address'] != null) {
        _addressController.text = data['address'] as String;
      }
    } catch (e) {
      debugPrint('Error loading user fields: $e');
    }
  }

  void _subscribeEmergencyStop() {
    // Listen to /emergency_stop in Realtime Database
    final stream = _db.child('emergency_stop').onValue;
    stream.listen((event) {
      final val = event.snapshot.value;
      if (val is bool) {
        setState(() => _emergencyStop = val);
      } else if (val is int) {
        // some setups store as 0/1
        setState(() => _emergencyStop = val == 1);
      }
    }, onError: (e) {
      debugPrint('Error listening emergency_stop: $e');
    });
  }

  Future<void> _saveAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _saving = true);
      await _users.doc(user.uid).set(
        {
          'address': _addressController.text.trim(),
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
          // NEW: Points and status bar card
          const PointsStatusCard(),

          const SizedBox(height: 8),

          // Basic profile info (read-only)
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

          // Address editor
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
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Dorm, building, room, or meeting point',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 2,
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
