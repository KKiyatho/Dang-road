import 'package:app/services/live_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveEnvironment labels', () {
    LiveEnvironment environment({
      required double apparentTemperature,
      double? usAqi,
    }) => LiveEnvironment(
      temperature: 25,
      apparentTemperature: apparentTemperature,
      humidity: 50,
      windSpeed: 8,
      pm25: null,
      pm10: null,
      usAqi: usAqi,
      observedAt: DateTime.utc(2026, 10, 24),
    );

    test('reports heat and cold caution using apparent temperature', () {
      expect(environment(apparentTemperature: 35).heatLabel, '폭염 주의');
      expect(environment(apparentTemperature: 30).heatLabel, '더위 주의');
      expect(environment(apparentTemperature: 0).heatLabel, '추위 주의');
      expect(environment(apparentTemperature: 18).heatLabel, '기온 보통');
    });

    test('reports US AQI bands and missing data honestly', () {
      expect(environment(apparentTemperature: 18, usAqi: 20).airLabel, '좋음');
      expect(environment(apparentTemperature: 18, usAqi: 80).airLabel, '보통');
      expect(
        environment(apparentTemperature: 18, usAqi: 120).airLabel,
        '민감군 주의',
      );
      expect(environment(apparentTemperature: 18).airLabel, '대기질 정보 없음');
    });
  });
}
