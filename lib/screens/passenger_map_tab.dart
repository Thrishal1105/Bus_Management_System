import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerMapTab extends StatefulWidget {
  const PassengerMapTab({super.key});

  @override
  State<PassengerMapTab> createState() => _PassengerMapTabState();
}

class _PassengerMapTabState extends State<PassengerMapTab> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Listen only to active trips in real time
      stream: FirebaseFirestore.instance.collection('trips').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading live tracking'));
        }

        // Extract active trips
        final activeTrips = snapshot.data?.docs ?? [];
        
        // Build markers
        List<Marker> markers = [];
        for (var doc in activeTrips) {
          final data = doc.data() as Map<String, dynamic>;
          final geo = data['currentLocation'] as GeoPoint?;
          final routeId = data['routeId'] ?? 'Unknown';
          
          if (geo != null) {
            markers.add(
              Marker(
                point: LatLng(geo.latitude, geo.longitude),
                width: 60,
                height: 60,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF0052D4), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(routeId.toString().length > 4 ? routeId.toString().substring(0, 4) : routeId.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            );
          }
        }

        return Stack(
          children: [
            // Full screen map
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(28.6139, 77.2090),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.busapp.bus_app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),

            // Bottom Sheet: Nearby Buses
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('LIVE TRACKING', style: TextStyle(color: Color(0xFF0052D4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active Buses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text('UPDATING LIVE', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (activeTrips.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No buses are currently active.", style: TextStyle(color: Colors.grey)),
                      )
                    else
                      // Constrained height list view for busses
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: activeTrips.length,
                          itemBuilder: (context, index) {
                            final data = activeTrips[index].data() as Map<String, dynamic>;
                            final routeId = data['routeId'] ?? 'Unknown';
                            final busId = data['busId'] ?? 'Unknown';
                            final geo = data['currentLocation'] as GeoPoint?;
                            
                            // Determine last update freshness
                            final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();
                            String status = 'ACTIVE';
                            bool isDelayed = false;
                            
                            if (lastUpdated != null) {
                              final diff = DateTime.now().difference(lastUpdated);
                              if (diff.inSeconds > 15) {
                                isDelayed = true;
                                status = 'SIGNAL LOST (${diff.inSeconds}s)';
                              } else {
                                status = 'TRACKING LIVE';
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  if (geo != null) {
                                    // Smoothly snap map to bus location
                                    _mapController.move(LatLng(geo.latitude, geo.longitude), 16.0);
                                  }
                                },
                                child: _buildBusCard(
                                  routeNum: routeId.toString().length > 3 ? routeId.toString().substring(0, 3) : routeId.toString(),
                                  title: 'Route $routeId',
                                  subtitle: 'Bus ID: $busId',
                                  status: status,
                                  isDelayed: isDelayed,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            )
          ],
        );
      }
    );
  }

  Widget _buildBusCard({required String routeNum, required String title, required String subtitle, required String status, bool isDelayed = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF4F5FA), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: const Color(0xFF0052D4), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(routeNum, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isDelayed ? Icons.signal_wifi_connected_no_internet_4 : Icons.sensors, color: isDelayed ? Colors.redAccent : Colors.green, size: 20),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDelayed ? Colors.red : Colors.green.shade700)),
            ],
          )
        ],
      ),
    );
  }
}
