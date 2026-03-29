import 'package:cloud_firestore/cloud_firestore.dart';

class PassModel {
  final String passId;
  final String userId;
  final String status; // "active" or "expired"
  final DateTime validUntil;

  PassModel({
    required this.passId,
    required this.userId,
    required this.status,
    required this.validUntil,
  });

  factory PassModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PassModel(
      passId: documentId,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'expired',
      validUntil: (data['validUntil'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'validUntil': Timestamp.fromDate(validUntil),
    };
  }
}
