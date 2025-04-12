// map_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final DatabaseReference _coordsRef =
      FirebaseDatabase.instance.ref('roboCords');
  LatLng? _currentLatLng;
  late Stream<DatabaseEvent> _coordsStream;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _coordsStream = _coordsRef.onValue;
    _coordsStream.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && mounted) {
        final lat = data['lat'] as num;
        final lon = data['lon'] as num;
        final newPos = LatLng(lat.toDouble(), lon.toDouble());
        setState(() => _currentLatLng = newPos);

        // optionally animate camera
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newPos),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Location', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[300],
      ),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('robot'),
                  position: _currentLatLng!,
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
