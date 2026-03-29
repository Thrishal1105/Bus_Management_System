import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/trip_service.dart';

class DriverMapTab extends StatefulWidget {
  final TripService tripService;
  final String busId;
  final String routeName;

  const DriverMapTab({super.key, required this.tripService, required this.busId, required this.routeName});

  @override
  State<DriverMapTab> createState() => _DriverMapTabState();
}

class _DriverMapTabState extends State<DriverMapTab> {
  bool _isTripActive = false;
  bool _isLoading = false;
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkLocationAndCenter();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationAndCenter() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
    
    // Automatically center the map if mounted
    if (mounted) {
      _mapController.move(_currentLocation!, 16.0);
    }
  }

  void _toggleTrip() async {
    setState(() => _isLoading = true);
    
    // 1. Ask for and verify Location Permissions before tracking starts
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS Permissions are required to start trip.')));
      }
      return;
    }

    if (_isTripActive) {
      // End Trip
      await widget.tripService.stopTrip();
      _positionStream?.cancel();
      setState(() {
        _isTripActive = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Ended. Live location stopped.')));
      }
    } else {
      // Start Trip
      final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      await widget.tripService.startTrip(driverId, widget.busId, widget.routeName);
      
      // Start local stream for centering the driver's map
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
      ).listen((Position position) {
        if (mounted) {
          setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        }
      });
      
      setState(() {
        _isTripActive = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip Started! Sharing Location.'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Background
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(28.6139, 77.2090),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.busapp.bus_app',
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF0052D4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  )
                ],
              ),
          ],
        ),

        // Floating Action Button to recenter map manually
        Positioned(
          bottom: 240, 
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Color(0xFF0052D4)),
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 16.0);
              }
            },
          )
        ),

        // Live Status Banner
        if (_isTripActive)
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors, color: Colors.black87, size: 20),
                  SizedBox(width: 8),
                  Text('BROADCASTING LOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87, letterSpacing: 1.2)),
                ],
              ),
            ),
          ),

        // Bottom Dashboard Card
        Positioned(
          bottom: 24, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark theme for driver focus
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT ASSIGNMENT', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(widget.routeName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isTripActive ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_bus, color: _isTripActive ? Colors.greenAccent : Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(widget.busId, style: TextStyle(color: _isTripActive ? Colors.greenAccent : Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Huge Start/Stop Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripActive ? Colors.redAccent : const Color(0xFF0052D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isTripActive ? Icons.stop_circle : Icons.play_arrow, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            _isTripActive ? 'End Trip & Stop Tracking' : 'Start Trip',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
