import 'package:flutter/material.dart';
import 'driver_map_tab.dart';
import 'driver_scanner_tab.dart';
import '../services/trip_service.dart';

class DriverDashboard extends StatefulWidget {
  final String busId;
  final String routeName;

  const DriverDashboard({super.key, required this.busId, required this.routeName});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentIndex = 0;
  final TripService _tripService = TripService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DriverMapTab(busId: widget.busId, routeName: widget.routeName, tripService: _tripService),
      DriverScannerTab(),
    ];
  }

  @override
  void dispose() {
    _tripService.stopTrip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: Text('${widget.routeName} - Tracker', style: const TextStyle(color: Color(0xFF0052D4), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0052D4)),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF0052D4),
          unselectedItemColor: Colors.blueGrey.shade300,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          items: [
            _buildNavItem(Icons.map_outlined, Icons.map, 'Tracking', 0),
            _buildNavItem(Icons.qr_code_scanner, Icons.qr_code_scanner, 'Scan Pass', 1),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData unselected, IconData selected, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: _currentIndex == index ? const Color(0xFF0052D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          _currentIndex == index ? selected : unselected,
          color: _currentIndex == index ? Colors.white : Colors.blueGrey.shade300,
        ),
      ),
      label: label,
    );
  }
}
