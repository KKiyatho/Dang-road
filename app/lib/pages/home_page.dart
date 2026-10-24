import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_data_service.dart';
import '../services/location_service.dart';
import '../widgets/location_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.location,
    required this.locationLabel,
    required this.onLocationChanged,
    required this.onOpenCourses,
    super.key,
  });

  final LatLng location;
  final String locationLabel;
  final void Function(LatLng location, String label) onLocationChanged;
  final VoidCallback onOpenCourses;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<LiveEnvironment> _environment;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _refresh();
  }

  void _refresh() {
    _environment = LiveDataService.fetchEnvironment(widget.location);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService.currentPosition();
      widget.onLocationChanged(position, '내 주변');
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
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => setState(_refresh),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF087A55)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.locationLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            LocationPickerButton(
              onSelected: (selection) =>
                  widget.onLocationChanged(selection.point, selection.label),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '내 위치 사용',
              onPressed: _locating ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<LiveEnvironment>(
          future: _environment,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _EnvironmentLoading();
            }
            if (snapshot.hasError) {
              return _EnvironmentError(
                message: snapshot.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
                onRetry: () => setState(_refresh),
              );
            }
            final data = snapshot.data!;
            return _EnvironmentSummary(data: data);
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘 산책할 곳', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  '현재 위치 주변의 실제 보행로와 지도 데이터를 불러옵니다. '
                  '코스의 상태와 반려견 적합성은 현장 확인이 필요합니다.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onOpenCourses,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('주변 산책로 보기'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _DataNotice(),
      ],
    ),
  );
}

class _EnvironmentSummary extends StatelessWidget {
  const _EnvironmentSummary({required this.data});

  final LiveEnvironment data;

  @override
  Widget build(BuildContext context) {
    final isCaution =
        data.apparentTemperature >= 30 ||
        data.apparentTemperature <= 0 ||
        (data.usAqi != null && data.usAqi! > 100);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCaution ? Icons.warning_amber_rounded : Icons.eco_outlined,
                  color: isCaution
                      ? colorScheme.error
                      : const Color(0xFF087A55),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCaution ? '산책 전 환경을 확인하세요' : '현재 환경 정보',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  'Open-Meteo',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.temperature.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    '체감 ${data.apparentTemperature.toStringAsFixed(1)}°',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EnvironmentChip(
                  icon: Icons.thermostat_outlined,
                  label: data.heatLabel,
                ),
                _EnvironmentChip(
                  icon: Icons.air,
                  label: '풍속 ${data.windSpeed.toStringAsFixed(0)} km/h',
                ),
                _EnvironmentChip(
                  icon: Icons.water_drop_outlined,
                  label: '습도 ${data.humidity.toStringAsFixed(0)}%',
                ),
                _EnvironmentChip(
                  icon: Icons.masks_outlined,
                  label: '대기 ${data.airLabel}',
                ),
              ],
            ),
            if (data.usAqi != null || data.pm25 != null) ...[
              const SizedBox(height: 12),
              Text(
                'US AQI ${data.usAqi?.toStringAsFixed(0) ?? '-'} · '
                'PM2.5 ${data.pm25?.toStringAsFixed(1) ?? '-'} μg/m³ · '
                'PM10 ${data.pm10?.toStringAsFixed(1) ?? '-'} μg/m³',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '관측 ${data.observedAt.toLocal().toString().substring(0, 16)} · '
              '수치 기반 참고 정보이며 안전을 보장하지 않습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentChip extends StatelessWidget {
  const _EnvironmentChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _EnvironmentLoading extends StatelessWidget {
  const _EnvironmentLoading();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('현재 날씨와 대기질을 불러오는 중입니다.'),
        ],
      ),
    ),
  );
}

class _EnvironmentError extends StatelessWidget {
  const _EnvironmentError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('환경 데이터를 가져오지 못했습니다.'),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DataNotice extends StatelessWidget {
  const _DataNotice();

  @override
  Widget build(BuildContext context) => const ListTile(
    leading: Icon(Icons.info_outline),
    title: Text('데이터 안내'),
    subtitle: Text(
      '날씨·대기질은 외부 API 관측값입니다. 지도 경로는 OpenStreetMap 자료이며 '
      '출입 가능 여부, 공사, 실제 혼잡도는 현장에서 확인해 주세요.',
    ),
  );
}
