import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class OpenStreetMapService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _overpassBaseUrl = 'https://overpass-api.de/api/interpreter';

  // Grocery store tags for OpenStreetMap
  static const List<String> groceryStoreTags = [
    'shop=supermarket',
    'shop=convenience',
    'shop=grocery',
    'shop=greengrocer',
    'amenity=marketplace'
  ];

  // Major grocery chains in South Africa
  static const List<String> groceryChains = [
    'Pick n Pay', 'Food lovers market', 'Shoprite', 'Spar', 
    'Checkers', 'Grocery Express', 'Econofoods', 'Besties',
    'Woolworths Food', 'Pick n Pay Hyper', 'Shoprite Hyper',
    'Checkers Hyper', 'Spar Supermarket', 'Boxer', 'OK Foods'
  ];

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<List<Map<String, dynamic>>> searchGroceryStores(String query, String? city, String? suburb) async {
    try {
      print('DEBUG: Searching for "$query" in $suburb, $city');
      
      // Try multiple search strategies to match OpenStreetMap.org behavior
      List<Map<String, dynamic>> allResults = [];
      
      // Strategy 1: Exact query like OpenStreetMap.org search
      if (suburb != null && suburb.isNotEmpty) {
        String exactQuery = '$query $suburb';
        allResults.addAll(await _performSearch(exactQuery));
        print('DEBUG: Exact query "$exactQuery" found ${allResults.length} results');
      }
      
      // Strategy 2: Query with city
      if (allResults.isEmpty && city != null && city.isNotEmpty) {
        String cityQuery = '$query $city';
        allResults.addAll(await _performSearch(cityQuery));
        print('DEBUG: City query "$cityQuery" found ${allResults.length} results');
      }
      
      // Strategy 3: Query with suburb and city
      if (allResults.isEmpty && suburb != null && city != null && city.isNotEmpty) {
        String suburbCityQuery = '$query $suburb $city';
        allResults.addAll(await _performSearch(suburbCityQuery));
        print('DEBUG: Suburb+City query "$suburbCityQuery" found ${allResults.length} results');
      }
      
      // Strategy 4: Add South Africa if still no results
      if (allResults.isEmpty) {
        String countryQuery = '$query ${suburb ?? ''} ${city ?? ''} South Africa';
        allResults.addAll(await _performSearch(countryQuery));
        print('DEBUG: Country query "$countryQuery" found ${allResults.length} results');
      }
      
      // Strategy 5: Try with "supermarket" if store name only
      if (allResults.isEmpty && _isStoreNameOnly(query)) {
        String supermarketQuery = '$query supermarket $suburb';
        allResults.addAll(await _performSearch(supermarketQuery));
        print('DEBUG: Supermarket query "$supermarketQuery" found ${allResults.length} results');
      }
      
      // Strategy 6: Fallback to verified local stores if all API calls fail
      if (allResults.isEmpty) {
        allResults.addAll(_getFallbackStores(query, suburb, city));
        print('DEBUG: Fallback stores found ${allResults.length} results');
      }
      
      // Filter to only include results that match the selected suburb (if specified)
      if (suburb != null && suburb.isNotEmpty) {
        final filteredResults = allResults.where((place) {
          final address = (place['address'] as String? ?? '').toLowerCase();
          final name = (place['name'] as String? ?? '').toLowerCase();
          return address.contains(suburb.toLowerCase()) || name.contains(suburb.toLowerCase());
        }).toList();
        
        print('DEBUG: Filtered to ${filteredResults.length} results in $suburb');
        return filteredResults;
      }
      
      return allResults;
    } catch (e) {
      print('DEBUG: Error searching grocery stores: $e');
    }
    return [];
  }

  static bool _isStoreNameOnly(String query) {
    final queryLower = query.toLowerCase();
    return groceryChains.any((chain) => queryLower.contains(chain.toLowerCase())) ||
           queryLower.contains('spar') ||
           queryLower.contains('pick n pay') ||
           queryLower.contains('shoprite');
  }

  static Future<List<Map<String, dynamic>>> _performSearch(String searchQuery) async {
    try {
      print('DEBUG: Making API call to: $_nominatimBaseUrl?q=$searchQuery&format=json&limit=10&addressdetails=1');
      
      final response = await http.get(
        Uri.parse('$_nominatimBaseUrl?q=$searchQuery&format=json&limit=10&addressdetails=1'),
        headers: {'User-Agent': 'DealsOnWheels/1.0'},
      );

      print('DEBUG: HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        print('DEBUG: Raw search results for "$searchQuery": ${results.length}');
        
        if (results.isNotEmpty) {
          for (int i = 0; i < results.length; i++) {
            final result = results[i];
            print('DEBUG: Result $i: ${result['display_name']}');
          }
        }
        
        return results.map((result) => _parseNominatimResult(result)).toList();
      } else if (response.statusCode == 429) {
        print('DEBUG: Rate limited - using fallback data');
        print('DEBUG: Response Body: ${response.body}');
        return []; // Return empty to trigger fallback
      } else {
        print('DEBUG: HTTP error ${response.statusCode} for query: $searchQuery');
        return [];
      }
    } catch (e) {
      print('DEBUG: Network error for query "$searchQuery": $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _getFallbackStores(String query, String? suburb, String? city) {
    final queryLower = query.toLowerCase();
    final suburbLower = suburb?.toLowerCase() ?? '';
    final cityLower = city?.toLowerCase() ?? '';
    
    List<Map<String, dynamic>> fallbackStores = [];
    
    // Port Elizabeth stores - VERIFIED LOCAL DATA
    if (cityLower.contains('port elizabeth') || cityLower.contains('pe')) {
      if (suburbLower.contains('walmer')) {
        fallbackStores = [
          {'name': 'Spar', 'address': '130 Main Road, Walmer, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Pick n Pay', 'address': 'Walmer Park Shopping Centre, Walmer, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Checkers', 'address': 'Walmer Park Shopping Centre, Walmer, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Woolworths Food', 'address': 'Walmer Park Shopping Centre, Walmer, Port Elizabeth', 'type': 'fallback'},
          {'name': 'OUR Superspar', 'address': 'Walmer, Port Elizabeth', 'type': 'fallback'},
        ];
      } else if (suburbLower.contains('summerstrand')) {
        fallbackStores = [
          {'name': 'Pick n Pay', 'address': 'Summerstrand Village, Summerstrand, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Spar', 'address': 'Summerstrand, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Checkers', 'address': 'The Boardwalk, Summerstrand, Port Elizabeth', 'type': 'fallback'},
        ];
      } else if (suburbLower.contains('newton park')) {
        fallbackStores = [
          {'name': 'Spar', 'address': 'Newton Park, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Pick n Pay', 'address': 'Newton Park Centre, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Shoprite', 'address': 'Newton Park, Port Elizabeth', 'type': 'fallback'},
          {'name': 'Checkers', 'address': 'Newton Park, Port Elizabeth', 'type': 'fallback'},
        ];
      }
    }
    
    // Filter by query if specific store mentioned
    if (queryLower.contains('spar')) {
      fallbackStores = fallbackStores.where((store) => 
        (store['name'] as String).toLowerCase().contains('spar')).toList();
    } else if (queryLower.contains('our superspar')) {
      fallbackStores = fallbackStores.where((store) => 
        (store['name'] as String).toLowerCase().contains('our superspar')).toList();
    } else if (queryLower.contains('pick n pay')) {
      fallbackStores = fallbackStores.where((store) => 
        (store['name'] as String).toLowerCase().contains('pick n')).toList();
    } else if (queryLower.contains('shoprite')) {
      fallbackStores = fallbackStores.where((store) => 
        (store['name'] as String).toLowerCase().contains('shoprite')).toList();
    } else if (queryLower.contains('checkers')) {
      fallbackStores = fallbackStores.where((store) => 
        (store['name'] as String).toLowerCase().contains('checkers')).toList();
    }
    
    return fallbackStores;
  }

  static Map<String, dynamic> _parseNominatimResult(Map<String, dynamic> result) {
    final displayName = result['display_name'] as String? ?? '';
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    
    return {
      'name': _extractStoreName(displayName),
      'address': displayName,
      'latitude': lat,
      'longitude': lon,
      'place_id': result['place_id']?.toString(),
      'type': 'nominatim',
    };
  }

  static String _extractStoreName(String displayName) {
    // Extract store name from full address
    final parts = displayName.split(',');
    if (parts.isNotEmpty) {
      final firstPart = parts[0].trim();
      
      // Check if it contains grocery chain names
      for (final chain in groceryChains) {
        if (firstPart.toLowerCase().contains(chain.toLowerCase())) {
          return firstPart;
        }
      }
      
      // Return first part if it looks like a store name
      if (firstPart.length < 50 && !firstPart.contains('St') && !firstPart.contains('Road')) {
        return firstPart;
      }
    }
    
    return displayName.split(',')[0].trim();
  }

  static String getStoreName(Map<String, dynamic> place) {
    return place['name'] as String? ?? 'Unknown Store';
  }

  static String getStoreAddress(Map<String, dynamic> place) {
    return place['address'] as String? ?? '';
  }

  static double? getStoreLatitude(Map<String, dynamic> place) {
    return place['latitude'] as double?;
  }

  static double? getStoreLongitude(Map<String, dynamic> place) {
    return place['longitude'] as double?;
  }

  static String getStorePlaceId(Map<String, dynamic> place) {
    return place['place_id'] as String? ?? '';
  }
}
