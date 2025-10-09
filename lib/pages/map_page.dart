import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  // Firebase stream for robot coordinates
  final DatabaseReference _coordsRef =
      FirebaseDatabase.instance.ref('roboCords');
  late Stream<DatabaseEvent> _coordsStream;

  // Last-known positions
  LatLng? _robotLatLng;

  // Map controller
  GoogleMapController? _mapController;

  // Location service for user GPS
  final Location _locationSvc = Location();

  // Custom marker icon
  BitmapDescriptor? _robotIcon;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _listenRobotLocations();
    _loadCustomMarker();
  }

  /// Loads the custom delivery icon for the robot
  Future<void> _loadCustomMarker() async {
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(4, 4)),
      'lib/images/rsz_delivery.png',
    );
    if (mounted) {
      setState(() {
        _robotIcon = icon;
      });
    }
  }

  /// 1. Request permissions & start listening to device location
  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await _locationSvc.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationSvc.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationSvc.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationSvc.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationSvc.onLocationChanged.listen((LocationData loc) {
      if (loc.latitude == null || loc.longitude == null) return;
    });
  }

  /// 2. Listen to the Firebase RTDB for the robot’s coordinates
  void _listenRobotLocations() {
    _coordsStream = _coordsRef.onValue;
    _coordsStream.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && mounted) {
        final lat = (data['lat'] as num).toDouble();
        final lon = (data['lon'] as num).toDouble();
        final newPos = LatLng(lat, lon);

        setState(() => _robotLatLng = newPos);

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newPos),
        );
      }
    });
  }

  /// 3. Robot marker only
  Set<Marker> get _allMarkers {
    final markers = <Marker>{};
    if (_robotLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('robot'),
          position: _robotLatLng!,
          icon: _robotIcon ?? BitmapDescriptor.defaultMarker, // <-- custom icon
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Robot & Your Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[300],
      ),
      body: _robotLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _robotLatLng!,
                zoom: 16,
              ),
              markers: _allMarkers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
