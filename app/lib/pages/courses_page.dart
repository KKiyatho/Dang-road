import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_data_service.dart';
import '../services/location_service.dart';
import '../widgets/location_picker.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({
    required this.location,
    required this.locationLabel,
    required this.onLocationChanged,
    super.key,
  });

  final LatLng location;
  final String locationLabel;
  final void Function(LatLng location, String label) onLocationChanged;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _mapController = MapController();
  late Future<List<OsmWalkway>> _walkways;
  int? _selectedId;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadWalkways();
  }

  @override
  void didUpdateWidget(covariant CoursesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _loadWalkways();
      _mapController.move(widget.location, 14);
    }
  }

  void _loadWalkways() {
    _selectedId = null;
    _walkways = LiveDataService.fetchWalkways(widget.location);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      widget.onLocationChanged(await LocationService.currentPosition(), '내 주변');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.locationLabel)),
            LocationPickerButton(
              onSelected: (selection) =>
                  widget.onLocationChanged(selection.point, selection.label),
            ),
            IconButton(
              tooltip: '현재 위치로 이동',
              onPressed: _locating ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
            IconButton(
              tooltip: '산책로 새로고침',
              onPressed: () => setState(_loadWalkways),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.location,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dangroad.app',
                maxZoom: 19,
              ),
              FutureBuilder<List<OsmWalkway>>(
                future: _walkways,
                builder: (context, snapshot) {
                  final ways = snapshot.data ?? const <OsmWalkway>[];
                  return PolylineLayer(
                    polylines: ways
                        .map(
                          (way) =>
                              way.toPolyline(selected: way.id == _selectedId),
                        )
                        .toList(),
                  );
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.location,
                    width: 34,
                    height: 34,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFFB3261E),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        flex: 4,
        child: FutureBuilder<List<OsmWalkway>>(
          future: _walkways,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                title: '산책로 데이터를 불러오지 못했습니다',
                detail: snapshot.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
                action: TextButton.icon(
                  onPressed: () => setState(_loadWalkways),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              );
            }
            final ways = snapshot.data ?? const <OsmWalkway>[];
            if (ways.isEmpty) {
              return const _MessageState(
                icon: Icons.route_outlined,
                title: '주변 보행로 정보가 없습니다',
                detail: '위치를 옮기거나 잠시 후 다시 확인해 주세요.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              itemCount: ways.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final way = ways[index];
                final isSelected = way.id == _selectedId;
                return ListTile(
                  selected: isSelected,
                  leading: const Icon(Icons.route_outlined),
                  title: Text(way.name),
                  subtitle: Text(
                    '${way.kind} · 경로 길이 ${_formatDistance(way.distanceMeters)} · OSM ${way.id}',
                  ),
                  onTap: () {
                    setState(() => _selectedId = way.id);
                    _mapController.move(way.points.first, 16);
                  },
                );
              },
            );
          },
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Text(
          '지도 및 보행로 © OpenStreetMap contributors · 실제 통행 가능 여부를 현장에서 확인하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ),
    ],
  );

  String _formatDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.black54),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(detail, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
