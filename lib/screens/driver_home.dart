import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'driver_dashboard.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  // Mocked list of buses for the MVP functional flow as requested
  final List<Map<String, String>> availableBuses = [
    {'id': 'bus_1', 'name': 'Bus 1 (Route 10A)'},
    {'id': 'bus_2', 'name': 'Bus 2 (Route 42X)'},
    {'id': 'bus_3', 'name': 'Bus 3 (Express)'},
    {'id': 'bus_4', 'name': 'Bus 4 (Downtown)'},
    {'id': 'bus_5', 'name': 'Bus 5 (City Loop)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text('Driver Dashboard', style: TextStyle(color: Color(0xFF0052D4), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.blueGrey), onPressed: () => AuthService().signOut()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back, Driver', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Please select the bus you are operating for this shift to begin tracking.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 32),
            const Text('AVAILABLE BUSES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: availableBuses.length,
                itemBuilder: (context, index) {
                  final bus = availableBuses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFEBEFF5), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.directions_bus, color: Color(0xFF0052D4)),
                      ),
                      title: Text(bus['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052D4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          // Extract a fake route ID from the name or just pass route1
                          final routeId = bus['name']!.contains('(') 
                            ? bus['name']!.split('(')[1].replaceAll(')', '') 
                            : 'Unknown Route';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverDashboard(
                                busId: bus['id']!,
                                routeName: routeId,
                              ),
                            ),
                          );
                        },
                        child: const Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
