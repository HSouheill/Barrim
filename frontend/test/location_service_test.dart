import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/src/services/location_service.dart';

void main() {
  group('LocationService Tests', () {
    test('should return Lebanese governorates', () {
      final governorates = LocationService.getGovernorates('Lebanon');
      
      expect(governorates, isNotEmpty);
      expect(governorates, contains('Akkar '));
      expect(governorates, contains('Beirut '));
      expect(governorates, contains('Mount Lebanon '));
      expect(governorates, contains('North '));
      expect(governorates, contains('South '));
      expect(governorates, contains('Beqaa '));
      expect(governorates, contains('Keserwan-Jbeil '));
      expect(governorates, contains('Nabatieh '));
      expect(governorates, contains('Baalbek-Hermel '));
    });

    test('should return districts for a governorate', () {
      final districts = LocationService.getDistrictsByGovernorate('Lebanon', 'Mount Lebanon');
      
      expect(districts, isNotEmpty);
      expect(districts, contains('Aley'));
      expect(districts, contains('Baabda'));
      expect(districts, contains('Chouf'));
      expect(districts, contains('Matn/Metn'));
    });

    test('should return streets for a district', () {
      final streets = LocationService.getStreetsByGovernorate('Lebanon', 'Beirut', 'Beirut');
      
      expect(streets, isNotEmpty);
      expect(streets, contains('Hamra Street'));
      expect(streets, contains('Corniche Beirut'));
      expect(streets, contains('Downtown Beirut'));
    });

    test('should extract governorate capital correctly', () {
      final capital = LocationService.getGovernorateCapital('Mount Lebanon');
      expect(capital, equals('Baabda'));
    });

    test('should extract district capital correctly', () {
      final capital = LocationService.getDistrictCapital('Aley');
      expect(capital, equals('Aley'));
    });

    test('should identify Lebanon as using governorate structure', () {
      expect(LocationService.usesGovernorateStructure('Lebanon'), isTrue);
      expect(LocationService.usesGovernorateStructure('Syria'), isFalse);
    });

    test('should validate location combinations', () {
      expect(
        LocationService.isValidLocationByGovernorate('Lebanon', 'Beirut', 'Beirut', 'Hamra Street'),
        isTrue
      );
      
      expect(
        LocationService.isValidLocationByGovernorate('Lebanon', 'Beirut', 'Beirut', 'Non-existent Street'),
        isFalse
      );
    });
  });
}
