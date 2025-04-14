import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database package (still used for emergency stop)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package for updating address
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth to get current user
import 'package:flutter/material.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  // Reference to the Firebase Realtime Database.
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Controller for the address input field.
  final TextEditingController _addressController = TextEditingController();

  // Local state to track the current stop value.
  int _stopValue = 0;

  @override
  void initState() {
    super.initState();
    // Listen to changes in the "stop" value from the Realtime Database.
    _dbRef.child("stop").onValue.listen((event) {
      final newStopValue = event.snapshot.value;
      if (newStopValue != null) {
        setState(() {
          _stopValue = newStopValue as int;
        });
      }
    });
    // Load the current address from Firestore and display it in the text field.
    _loadAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Function to fetch the user's current address from Firestore.
  Future<void> _loadAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!['address'] != null) {
          _addressController.text = doc.data()!['address'];
        }
      }
    } catch (e) {
      print("Error loading address: $e");
    }
  }

  // Function to toggle the stop value between 0 and 1.
  Future<void> _toggleStop() async {
    try {
      int newValue = (_stopValue == 0) ? 1 : 0;
      await _dbRef.child("stop").set(newValue);
      print("Stop value toggled to: $newValue");
    } catch (e) {
      print("Error toggling stop value: $e");
    }
  }

  // Function to update the user's address in Firebase Cloud Firestore.
  Future<void> _updateAddress() async {
    try {
      // Retrieve the entered address and trim any extra spaces.
      final String address = _addressController.text.trim();
      
      // Get the current user from Firebase Authentication.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update the address field in the user's document under 'users' collection.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'address': address,
        }, SetOptions(merge: true));
        print("Address updated to: $address");

        // Show a snackbar confirming the address update.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Address updated to: $address")),
        );
      } else {
        print("No user signed in");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No user signed in")),
        );
      }
    } catch (e) {
      print("Error updating address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating address: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'User Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display of current emergency stop status.
                Text(
                  "Emergency Stop is ${_stopValue == 0 ? 'Inactive' : 'Active'}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                // Big emergency stop button.
                ElevatedButton(
                  onPressed: _toggleStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stopValue == 0 ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 80), // Full width and 80-pixel height.
                  ),
                  child: Text(
                    _stopValue == 0 ? "Activate Emergency Stop" : "Deactivate Emergency Stop",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Text field for the user to input an address, pre-filled with the current address.
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter your address",
                    hintText: "e.g., 123 Main Street, City, Country",
                  ),
                ),
                const SizedBox(height: 20),
                // Button to update the address in Firestore.
                ElevatedButton(
                  onPressed: _updateAddress,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Update Address",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                // Sign Out button moved from the Cart page.
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
