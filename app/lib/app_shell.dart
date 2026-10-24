import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'pages/courses_page.dart';
import 'pages/home_page.dart';
import 'pages/meetups_page.dart';
import 'pages/records_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _defaultLocation = LatLng(35.8584, 128.6300);
  static const _titles = ['오늘 산책', '산책로', '함께 걷기', '내 기록'];

  int _selectedIndex = 0;
  LatLng _location = _defaultLocation;
  String _locationLabel = '대구 수성구';

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        location: _location,
        locationLabel: _locationLabel,
        onLocationChanged: _setLocation,
        onOpenCourses: () => setState(() => _selectedIndex = 1),
      ),
      CoursesPage(
        location: _location,
        locationLabel: _locationLabel,
        onLocationChanged: _setLocation,
      ),
      const MeetupsPage(),
      const RecordsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _locationLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '코스',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: '함께 걷기',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '내 기록',
          ),
        ],
      ),
    );
  }

  void _setLocation(LatLng location, String label) {
    setState(() {
      _location = location;
      _locationLabel = label;
    });
  }
}
