import 'package:flutter/material.dart';
import 'passenger_map_tab.dart';
import 'passenger_pass_tab.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PassengerMapTab(),
    const PassengerPassTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEFF5), // Slightly grayish blue background
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEBEFF5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFFEBEFF5),
          elevation: 0,
          selectedItemColor: const Color(0xFF0052D4),
          unselectedItemColor: Colors.blueGrey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          items: [
            _buildNavItem(Icons.explore_outlined, Icons.explore, 'Map', 0),
            _buildNavItem(Icons.qr_code_2_outlined, Icons.qr_code_2, 'Pass', 1),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData unselected, IconData selected, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _currentIndex == index ? const Color(0xFF0052D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          _currentIndex == index ? selected : unselected,
          color: _currentIndex == index ? Colors.white : Colors.blueGrey.shade400,
        ),
      ),
      label: label,
    );
  }
}
