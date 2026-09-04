/// Sri Lanka administrative provinces and their primary cities and towns.
class SriLankaLocations {
  SriLankaLocations._();

  static const Map<String, List<String>> provincesAndCities = {
    'Western': [
      'Colombo',
      'Dehiwala-Mount Lavinia',
      'Moratuwa',
      'Sri Jayawardenepura Kotte',
      'Negombo',
      'Gampaha',
      'Kelaniya',
      'Panadura',
      'Kalutara',
      'Horana',
      'Homagama',
      'Maharagama',
      'Kesbewa',
      'Battaramulla',
      'Kaduwela',
      'Wattala',
      'Ja-Ela',
      'Minuwangoda',
      'Beruwala',
      'Aluthgama',
    ],
    'Central': [
      'Kandy',
      'Matale',
      'Nuwara Eliya',
      'Gampola',
      'Nawalapitiya',
      'Hatton',
      'Dambulla',
      'Peradeniya',
      'Katugastota',
      'Kundasale',
      'Talawakele',
    ],
    'Southern': [
      'Galle',
      'Matara',
      'Hambantota',
      'Tangalle',
      'Hikkaduwa',
      'Ambalangoda',
      'Weligama',
      'Bentota',
      'Beliatta',
      'Tissamaharama',
      'Elpitiya',
    ],
    'Northern': [
      'Jaffna',
      'Kilinochchi',
      'Mannar',
      'Vavuniya',
      'Mullaitivu',
      'Point Pedro',
      'Chavakachcheri',
    ],
    'Eastern': [
      'Trincomalee',
      'Batticaloa',
      'Ampara',
      'Kalmunai',
      'Kattankudy',
      'Eravur',
      'Akkaraipattu',
      'Sammanthurai',
      'Kinniya',
      'Mutur',
    ],
    'North Western': [
      'Kurunegala',
      'Puttalam',
      'Chilaw',
      'Kuliyapitiya',
      'Wennappuwa',
      'Narammala',
      'Wariyapola',
      'Marawila',
      'Dankotuwa',
      'Maho',
    ],
    'North Central': [
      'Anuradhapura',
      'Polonnaruwa',
      'Medawachchiya',
      'Tambuttegama',
      'Kekirawa',
      'Hingurakgoda',
      'Habarana',
    ],
    'Uva': [
      'Badulla',
      'Bandarawela',
      'Welimada',
      'Haputale',
      'Monaragala',
      'Wellawaya',
      'Mahiyanganaya',
      'Passara',
      'Ella',
      'Buttala',
    ],
    'Sabaragamuwa': [
      'Ratnapura',
      'Kegalle',
      'Balangoda',
      'Embilipitiya',
      'Mawanella',
      'Ruwanwella',
      'Yatiyantota',
      'Pelmadulla',
      'Eheliyagoda',
    ],
  };

  /// Returns the list of all Sri Lankan provinces sorted alphabetically.
  static List<String> get provinces => provincesAndCities.keys.toList()..sort();

  /// Returns the list of cities for a given province, or an empty list if not found.
  static List<String> getCitiesForProvince(String? province) {
    if (province == null || province.trim().isEmpty) {
      return const [];
    }
    final cities = provincesAndCities[province.trim()];
    if (cities == null) {
      return const [];
    }
    return List<String>.from(cities)..sort();
  }

  /// Checks if a province name is valid.
  static bool isValidProvince(String? province) {
    if (province == null) return false;
    return provincesAndCities.containsKey(province.trim());
  }

  /// Checks if a city exists within the given province.
  static bool isValidCity(String? province, String? city) {
    if (province == null || city == null) return false;
    final cities = provincesAndCities[province.trim()];
    if (cities == null) return false;
    return cities.any((c) => c.toLowerCase() == city.trim().toLowerCase());
  }
}
