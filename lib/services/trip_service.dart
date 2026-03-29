import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import 'dart:async';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSub;
  String? _currentTripId;

  // Start a new trip
  Future<String> startTrip(String driverId, String busId, String routeId) async {
    final tripRef = _firestore.collection('trips').doc();
    
    final newTrip = TripModel(
      tripId: tripRef.id,
      driverId: driverId,
      busId: busId,
      routeId: routeId,
      isActive: true,
      lastUpdated: DateTime.now(),
    );

    await tripRef.set(newTrip.toMap());
    _currentTripId = tripRef.id;

    _startLocationUpdates(tripRef.id, driverId);
    return tripRef.id;
  }

  // Stop the current trip
  Future<void> stopTrip() async {
    if (_currentTripId != null) {
      await _firestore.collection('trips').doc(_currentTripId).update({
        'isActive': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _positionStreamSub?.cancel();
      _currentTripId = null;
    }
  }

  // Internal: listen to GPS and update Firestore
  void _startLocationUpdates(String tripId, String driverId) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 meters 
      // or we can use time limit if needed
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        _firestore.collection('trips').doc(tripId).update({
          'currentLocation': GeoPoint(position.latitude, position.longitude),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
