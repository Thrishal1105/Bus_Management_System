import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildMetricCard('Active Buses', _getActiveTripsStream(), Icons.directions_bus, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Today\'s Scans', _getTodayScansStream(), Icons.qr_code_scanner, Colors.green)),
            ],
          ),

          const SizedBox(height: 24),
          _buildGraphSection(), // New Graph Widget

          const SizedBox(height: 32),
          const Text('LIVE FLEET STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildActiveBusesList(),
        ],
      ),
    );
  }

  Widget _buildGraphSection() {
    return StreamBuilder<int>(
      stream: _getActiveTripsStream(),
      builder: (context, activeSnapshot) {
        return StreamBuilder<int>(
          stream: _getTodayScansStream(),
          builder: (context, scansSnapshot) {
            final activeBuses = activeSnapshot.data ?? 0;
            final todayScans = scansSnapshot.data ?? 0;
            
            // Normalize for visual graph
            int maxVal = (activeBuses > todayScans ? activeBuses : todayScans);
            if (maxVal < 10) maxVal = 10; // baseline to prevent huge blocks for small numbers

            double busHeight = (activeBuses / maxVal) * 120.0;
            double scanHeight = (todayScans / maxVal) * 120.0;

            return Container(
              height: 240,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACTIVITY GRAPH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(busHeight, activeBuses.toString(), 'Active Buses', Colors.blue),
                        _buildBar(scanHeight, todayScans.toString(), 'QR Scans', Colors.green),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildBar(double height, String value, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastLinearToSlowEaseIn,
          height: height.clamp(4.0, 120.0), // minimum 4px height so empty values are visible 
          width: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Stream<int> _getActiveTripsStream() {
    return FirebaseFirestore.instance.collection('trips').where('isActive', isEqualTo: true).snapshots().map((s) => s.docs.length);
  }

  Stream<int> _getTodayScansStream() {
    // Only get scans from today (approximation for MVP)
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return FirebaseFirestore.instance.collection('scan_logs')
      .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
      .snapshots().map((s) => s.docs.length);
  }

  Widget _buildMetricCard(String title, Stream<int> stream, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              return Text(
                snapshot.hasData ? snapshot.data.toString() : '-',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              );
            }
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActiveBusesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No active trips right now.', style: TextStyle(color: Colors.grey))));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final driverId = data['driverId'] ?? 'Unknown';
            final busId = data['busId'] ?? 'Unknown';
            final routeId = data['routeId'] ?? 'Unknown';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(driverId).get(),
              builder: (context, userSnapshot) {
                String driverName = 'Loading...';
                if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData != null) {
                    driverName = userData['name'] ?? 'Unknown Driver';
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFEBEFF5), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.directions_bus, color: Color(0xFF0052D4)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(busId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Driver: $driverName', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('ID: $driverId', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(routeId, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                );
              }
            );
          },
        );
      }
    );
  }
}
