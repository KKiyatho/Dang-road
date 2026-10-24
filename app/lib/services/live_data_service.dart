import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LiveEnvironment {
  const LiveEnvironment({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.pm25,
    required this.pm10,
    required this.usAqi,
    required this.observedAt,
  });

  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final double? pm25;
  final double? pm10;
  final double? usAqi;
  final DateTime observedAt;

  String get heatLabel {
    if (apparentTemperature >= 35) return '폭염 주의';
    if (apparentTemperature >= 30) return '더위 주의';
    if (apparentTemperature <= 0) return '추위 주의';
    return '기온 보통';
  }

  String get airLabel {
    final aqi = usAqi;
    if (aqi == null) return '대기질 정보 없음';
    if (aqi <= 50) return '좋음';
    if (aqi <= 100) return '보통';
    if (aqi <= 150) return '민감군 주의';
    return '나쁨';
  }
}

class OsmWalkway {
  const OsmWalkway({
    required this.id,
    required this.name,
    required this.kind,
    required this.points,
    required this.distanceMeters,
  });

  final int id;
  final String name;
  final String kind;
  final List<LatLng> points;
  final double distanceMeters;

  Polyline toPolyline({required bool selected}) => Polyline(
    points: points,
    color: selected ? const Color(0xFF087A55) : const Color(0xFF4C9A78),
    strokeWidth: selected ? 6 : 3,
  );
}

class LocationSelection {
  const LocationSelection({required this.point, required this.label});

  final LatLng point;
  final String label;
}

class LiveDataService {
  LiveDataService._();

  static Future<LiveEnvironment> fetchEnvironment(LatLng location) async {
    final coordinates = {
      'latitude': location.latitude.toStringAsFixed(5),
      'longitude': location.longitude.toStringAsFixed(5),
      'timezone': 'Asia/Seoul',
    };
    final weatherUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      ...coordinates,
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m',
    });
    final airUri = Uri.https(
      'air-quality-api.open-meteo.com',
      '/v1/air-quality',
      {...coordinates, 'current': 'pm10,pm2_5,us_aqi'},
    );

    final responses = await Future.wait([
      http.get(weatherUri).timeout(const Duration(seconds: 15)),
      http.get(airUri).timeout(const Duration(seconds: 15)),
    ]);
    if (responses.any((response) => response.statusCode != 200)) {
      throw Exception('환경 데이터 제공 서버가 응답하지 않습니다. 잠시 후 다시 시도해 주세요.');
    }

    final weather = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final air = jsonDecode(responses[1].body) as Map<String, dynamic>;
    final current = weather['current'] as Map<String, dynamic>;
    final airCurrent = air['current'] as Map<String, dynamic>? ?? {};

    return LiveEnvironment(
      temperature: _number(current['temperature_2m']),
      apparentTemperature: _number(current['apparent_temperature']),
      humidity: _number(current['relative_humidity_2m']),
      windSpeed: _number(current['wind_speed_10m']),
      pm25: _optionalNumber(airCurrent['pm2_5']),
      pm10: _optionalNumber(airCurrent['pm10']),
      usAqi: _optionalNumber(airCurrent['us_aqi']),
      observedAt: DateTime.parse(current['time'] as String),
    );
  }

  static Future<List<OsmWalkway>> fetchWalkways(LatLng center) async {
    final lat = center.latitude.toStringAsFixed(5);
    final lon = center.longitude.toStringAsFixed(5);
    final query =
        '''
[out:json][timeout:25];
way["highway"~"^(footway|path|pedestrian|cycleway|steps|track)\$"](around:800,$lat,$lon);
out tags geom 100;
''';
    final response = await http
        .post(
          Uri.https('overpass-api.de', '/api/interpreter'),
          headers: {'Accept': 'application/json'},
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('산책로 지도 서버가 응답하지 않습니다. 잠시 후 다시 시도해 주세요.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'] as List<dynamic>? ?? const [];
    final walkways = <OsmWalkway>[];
    for (final element in elements) {
      final way = element as Map<String, dynamic>;
      final geometry = way['geometry'] as List<dynamic>? ?? const [];
      if (geometry.length < 2) continue;

      final points = geometry
          .map((point) {
            final coordinates = point as Map<String, dynamic>;
            return LatLng(
              _number(coordinates['lat']),
              _number(coordinates['lon']),
            );
          })
          .toList(growable: false);
      var distance = 0.0;
      for (var index = 1; index < points.length; index++) {
        distance += Geolocator.distanceBetween(
          points[index - 1].latitude,
          points[index - 1].longitude,
          points[index].latitude,
          points[index].longitude,
        );
      }

      final tags = way['tags'] as Map<String, dynamic>? ?? const {};
      walkways.add(
        OsmWalkway(
          id: way['id'] as int,
          name:
              tags['name'] as String? ?? _kindLabel(tags['highway'] as String?),
          kind:
              tags['surface'] as String? ??
              _kindLabel(tags['highway'] as String?),
          points: points,
          distanceMeters: distance,
        ),
      );
    }

    walkways.sort((first, second) {
      final firstDistance = _distanceTo(center, first.points);
      final secondDistance = _distanceTo(center, second.points);
      return firstDistance.compareTo(secondDistance);
    });
    return walkways.take(80).toList(growable: false);
  }

  static Future<List<LocationSelection>> searchLocations(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '8',
      'language': 'ko',
      'format': 'json',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('지역 검색 서버가 응답하지 않습니다. 잠시 후 다시 시도해 주세요.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>? ?? const [];
    return results
        .map((result) {
          final item = result as Map<String, dynamic>;
          final name = item['name'] as String? ?? '이름 없는 지역';
          final region = item['admin1'] as String?;
          final country = item['country'] as String?;
          final parts = [
            name,
            region,
            country,
          ].whereType<String>().where((part) => part.isNotEmpty).toSet();
          return LocationSelection(
            point: LatLng(
              _number(item['latitude']),
              _number(item['longitude']),
            ),
            label: parts.join(' · '),
          );
        })
        .toList(growable: false);
  }

  static double _distanceTo(LatLng center, List<LatLng> points) {
    return points
        .map(
          (point) => Geolocator.distanceBetween(
            center.latitude,
            center.longitude,
            point.latitude,
            point.longitude,
          ),
        )
        .reduce(math.min);
  }

  static String _kindLabel(String? value) => switch (value) {
    'footway' => '보행로',
    'path' => '산책로',
    'pedestrian' => '보행자 전용길',
    'cycleway' => '자전거·보행 겸용길',
    'steps' => '계단',
    'track' => '비포장길',
    _ => 'OpenStreetMap 경로',
  };

  static double _number(Object? value) => value is num ? value.toDouble() : 0;

  static double? _optionalNumber(Object? value) =>
      value is num ? value.toDouble() : null;
}
