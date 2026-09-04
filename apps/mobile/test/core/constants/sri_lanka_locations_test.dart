import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/sri_lanka_locations.dart';

void main() {
  group('SriLankaLocations', () {
    test('contains all 9 Sri Lankan provinces', () {
      final provinces = SriLankaLocations.provinces;
      expect(provinces.length, equals(9));
      expect(
        provinces,
        containsAll([
          'Central',
          'Eastern',
          'North Central',
          'North Western',
          'Northern',
          'Sabaragamuwa',
          'Southern',
          'Uva',
          'Western',
        ]),
      );
    });

    test('returns cities for valid province', () {
      final westernCities = SriLankaLocations.getCitiesForProvince('Western');
      expect(westernCities, isNotEmpty);
      expect(westernCities, contains('Colombo'));
      expect(westernCities, contains('Negombo'));

      final centralCities = SriLankaLocations.getCitiesForProvince('Central');
      expect(centralCities, contains('Kandy'));
    });

    test('returns empty list for null or unknown province', () {
      expect(SriLankaLocations.getCitiesForProvince(null), isEmpty);
      expect(SriLankaLocations.getCitiesForProvince(''), isEmpty);
      expect(SriLankaLocations.getCitiesForProvince('Atlantis'), isEmpty);
    });

    test('validates provinces correctly', () {
      expect(SriLankaLocations.isValidProvince('Western'), isTrue);
      expect(SriLankaLocations.isValidProvince('Southern'), isTrue);
      expect(SriLankaLocations.isValidProvince('InvalidProvince'), isFalse);
      expect(SriLankaLocations.isValidProvince(null), isFalse);
    });

    test('validates cities within province correctly', () {
      expect(SriLankaLocations.isValidCity('Western', 'Colombo'), isTrue);
      expect(SriLankaLocations.isValidCity('Western', 'colombo'), isTrue);
      expect(SriLankaLocations.isValidCity('Central', 'Kandy'), isTrue);
      expect(SriLankaLocations.isValidCity('Central', 'Colombo'), isFalse);
      expect(SriLankaLocations.isValidCity(null, 'Colombo'), isFalse);
      expect(SriLankaLocations.isValidCity('Western', null), isFalse);
    });
  });
}
