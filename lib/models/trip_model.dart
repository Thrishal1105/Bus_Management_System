import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String tripId;
  final String driverId;
  final String busId;
  final String routeId;
  final bool isActive;
  final GeoPoint? currentLocation;
  final DateTime? lastUpdated;

  TripModel({
    required this.tripId,
    required this.driverId,
    required this.busId,
    required this.routeId,
    required this.isActive,
    this.currentLocation,
    this.lastUpdated,
  });

  factory TripModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TripModel(
      tripId: documentId,
      driverId: data['driverId'] ?? '',
      busId: data['busId'] ?? '',
      routeId: data['routeId'] ?? '',
      isActive: data['isActive'] ?? false,
      currentLocation: data['currentLocation'] as GeoPoint?,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'busId': busId,
      'routeId': routeId,
      'isActive': isActive,
      'currentLocation': currentLocation,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
    };
  }
}
