import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/src/services/location_service.dart';

void main() {
  group('LocationService Tests', () {
    test('should return Lebanese governorates', () {
      final governorates = LocationService.getGovernorates('Lebanon');
      
      expect(governorates, isNotEmpty);
      expect(governorates, contains('Akkar Governorate (Halba)'));
      expect(governorates, contains('Beirut Governorate (Beirut)'));
      expect(governorates, contains('Mount Lebanon Governorate (Baabda)'));
      expect(governorates, contains('North Governorate (Tripoli)'));
      expect(governorates, contains('South Governorate (Sidon)'));
      expect(governorates, contains('Beqaa Governorate (Zahlé)'));
      expect(governorates, contains('Keserwan-Jbeil Governorate (Jounieh)'));
      expect(governorates, contains('Nabatieh Governorate (Nabatieh)'));
      expect(governorates, contains('Baalbek-Hermel Governorate (Baalbek)'));
    });

    test('should return districts for a governorate', () {
      final districts = LocationService.getDistrictsByGovernorate('Lebanon', 'Mount Lebanon Governorate (Baabda)');
      
      expect(districts, isNotEmpty);
      expect(districts, contains('Aley (Aley)'));
      expect(districts, contains('Baabda (Baabda)'));
      expect(districts, contains('Chouf (Beiteddine)'));
      expect(districts, contains('Matn/Metn (Jdeideh)'));
    });

    test('should return streets for a district', () {
      final streets = LocationService.getStreetsByGovernorate('Lebanon', 'Beirut Governorate (Beirut)', 'Beirut (Beirut)');
      
      expect(streets, isNotEmpty);
      expect(streets, contains('Hamra Street'));
      expect(streets, contains('Corniche Beirut'));
      expect(streets, contains('Downtown Beirut'));
    });

    test('should extract governorate capital correctly', () {
      final capital = LocationService.getGovernorateCapital('Mount Lebanon Governorate (Baabda)');
      expect(capital, equals('Baabda'));
    });

    test('should extract district capital correctly', () {
      final capital = LocationService.getDistrictCapital('Aley (Aley)');
      expect(capital, equals('Aley'));
    });

    test('should identify Lebanon as using governorate structure', () {
      expect(LocationService.usesGovernorateStructure('Lebanon'), isTrue);
      expect(LocationService.usesGovernorateStructure('Syria'), isFalse);
    });

    test('should validate location combinations', () {
      expect(
        LocationService.isValidLocationByGovernorate('Lebanon', 'Beirut Governorate (Beirut)', 'Beirut (Beirut)', 'Hamra Street'),
        isTrue
      );
      
      expect(
        LocationService.isValidLocationByGovernorate('Lebanon', 'Beirut Governorate (Beirut)', 'Beirut (Beirut)', 'Non-existent Street'),
        isFalse
      );
    });
  });
}
