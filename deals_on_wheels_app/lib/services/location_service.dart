class LocationService {
  // Common suburbs for major South African cities
  static final Map<String, List<String>> suburbsByCity = {
    'Johannesburg': [
      'Sandton', 'Rosebank', 'Melville', 'Fourways', 'Midrand',
      'Randburg', 'Parktown', 'Bryanston', 'Houghton', 'Norwood',
      'Greenside', 'Orange Grove', 'Yeoville', 'Braamfontein',
      'Marshalltown', 'Fordsburg', 'Newtown', 'Maboneng'
    ],
    'Cape Town': [
      'Claremont', 'Rondebosch', 'Observatory', 'Woodstock', 'Sea Point',
      'Green Point', 'V&A Waterfront', 'Camps Bay', 'Hout Bay',
      'Constantia', 'Wynberg', 'Plumstead', 'Muizenberg',
      'Kalk Bay', 'Simon\'s Town', 'Stellenbosch', 'Somerset West'
    ],
    'Port Elizabeth': [
      'Walmer', 'Summerstrand', 'Humewood', 'South End', 'Central',
      'Newton Park', 'Gelvandale', 'Kensington', 'Korsten',
      'Parsons Hill', 'Linton Grange', 'Charlo', 'Mill Park',
      'Bluewater Bay', 'St George\'s Park'
    ],
  };

  // Grocery shops only
  static final List<String> groceryShops = [
    'Pick n Pay', 'Food lovers market', 'Shoprite', 'Spar', 
    'Checkers', 'Grocery Express', 'Econofoods', 'Besties'
  ];

  // Specific store locations by city and suburb
  static final Map<String, Map<String, List<String>>> shopLocations = {
    'Port Elizabeth': {
      'Walmer': [
        'Spar - Walmer Park', 'Spar - Walmer Downs', 'Pick n Pay - Walmer Park',
        'Shoprite - Walmer', 'Checkers - Walmer Centre'
      ],
      'Summerstrand': [
        'Pick n Pay - Summerstrand Village', 'Spar - Summerstrand',
        'Checkers - The Boardwalk'
      ],
      'Newton Park': [
        'Spar - Newton Park', 'Pick n Pay - Newton Park Centre',
        'Shoprite - Newton Park', 'Checkers - Newton Park'
      ],
      'Central': [
        'Spar - Central', 'Pick n Pay - Tramways Building',
        'Shoprite - Central', 'Food lovers market - Central'
      ],
      'Gelvandale': [
        'Spar - Gelvandale', 'Shoprite - Gelvandale',
        'Pick n Pay - Gelvandale'
      ],
      'Humewood': [
        'Spar - Humewood', 'Pick n Pay - Humewood',
        'Checkers - Humewood'
      ],
    },
    'Johannesburg': {
      'Sandton': [
        'Pick n Pay - Sandton City', 'Spar - Sandton',
        'Checkers - Sandton City', 'Food lovers market - Sandton'
      ],
      'Rosebank': [
        'Pick n Pay - Rosebank Mall', 'Spar - Rosebank',
        'Checkers - Rosebank'
      ],
      'Fourways': [
        'Pick n Pay - Fourways Mall', 'Spar - Fourways',
        'Shoprite - Fourways', 'Checkers - Fourways'
      ],
      'Randburg': [
        'Spar - Randburg', 'Pick n Pay - Randburg',
        'Checkers - Randburg', 'Shoprite - Randburg'
      ],
    },
    'Cape Town': {
      'Claremont': [
        'Pick n Pay - Claremont', 'Spar - Claremont',
        'Checkers - Claremont', 'Food lovers market - Claremont'
      ],
      'V&A Waterfront': [
        'Pick n Pay - V&A Waterfront', 'Spar - V&A',
        'Checkers - V&A'
      ],
      'Sea Point': [
        'Pick n Pay - Sea Point', 'Spar - Sea Point',
        'Checkers - Sea Point'
      ],
      'Wynberg': [
        'Spar - Wynberg', 'Pick n Pay - Wynberg',
        'Shoprite - Wynberg'
      ],
    },
  };

  static List<String> getSuburbsForCity(String city) {
    return suburbsByCity[city] ?? [];
  }

  static List<String> getAllSuburbs() {
    return suburbsByCity.values.expand((suburbs) => suburbs).toList();
  }

  static List<String> searchSuburbs(String query, String city) {
    if (query.isEmpty) return getSuburbsForCity(city);
    
    final suburbs = getSuburbsForCity(city);
    return suburbs
        .where((suburb) => suburb.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static List<String> searchGroceryShops(String query) {
    if (query.isEmpty) return groceryShops;
    
    return groceryShops
        .where((shop) => shop.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static List<String> getShopLocationsForCitySuburb(String city, String suburb) {
    return shopLocations[city]?[suburb] ?? [];
  }

  static List<String> searchShopLocations(String query, String city, String suburb) {
    if (query.isEmpty) return getShopLocationsForCitySuburb(city, suburb);
    
    final locations = getShopLocationsForCitySuburb(city, suburb);
    return locations
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static List<String> getAllShopLocations() {
    return shopLocations.values
        .map((cityMap) => cityMap.values.expand((locations) => locations))
        .expand((locations) => locations)
        .toList();
  }
}
