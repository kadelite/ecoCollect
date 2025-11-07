import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TrackTrucksScreen extends StatefulWidget {
  const TrackTrucksScreen({super.key});

  @override
  State<TrackTrucksScreen> createState() => _TrackTrucksScreenState();
}

class _TrackTrucksScreenState extends State<TrackTrucksScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _setupTruckListener();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _userPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupTruckListener() {
    // Listen to truck locations from Firestore
    FirebaseFirestore.instance
        .collection('truck_locations')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _markers.clear();
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;
          final truckId = data['truckId'] as String? ?? doc.id;
          
          if (lat != null && lng != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(truckId),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: 'Waste Truck $truckId',
                  snippet: 'Active collection vehicle',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Default to a city center if user location is not available
    final initialPosition = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : const LatLng(37.7749, -122.4194); // San Francisco default

    // Note: Google Maps requires an API key to be configured in AndroidManifest.xml
    // For Android: Replace YOUR_API_KEY in android/app/src/main/AndroidManifest.xml
    // For iOS: Add API key in ios/Runner/AppDelegate.swift
    // For Web: Add API key in index.html or web/index.html

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 13,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Truck Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_markers.length} active truck${_markers.length != 1 ? 's' : ''} on route',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Green markers show active waste collection vehicles in your area.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userPosition != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(_userPosition!.latitude, _userPosition!.longitude),
              ),
            );
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

