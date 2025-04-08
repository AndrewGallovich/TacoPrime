import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database package
import 'package:flutter/material.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  // Reference to the Firebase Realtime Database.
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optional display of current emergency stop status.
              Text(
                "Emergency Stop is ${_stopValue == 0 ? 'Inactive' : 'Active'}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Big red emergency stop button.
              ElevatedButton(
                onPressed: _toggleStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
            ],
          ),
        ),
      ),
    );
  }
}
