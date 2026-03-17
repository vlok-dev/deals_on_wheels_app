import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  static final _client = Supabase.instance.client;

  static Future<void> setCity(String userId, String city) async {
    try {
      print('DEBUG: Upserting profile - userId: $userId, city: $city');
      await _client.from('profiles').upsert({
        'id': userId,
        'city': city,
      });
      print('DEBUG: Profile upsert completed successfully');
    } catch (e) {
      print('DEBUG: Error in setCity: $e');
      rethrow;
    }
  }

  static Future<String?> getCity(String userId) async {
    try {
      final res = await _client.from('profiles').select('city').eq('id', userId);
      print('DEBUG: Profile query result: $res');
      if (res.isEmpty) {
        print('DEBUG: No profile found for user $userId');
        return null;
      }
      return res[0]['city'] as String?;
    } catch (e) {
      print('DEBUG: Error getting city for user $userId: $e');
      return null;
    }
  }
}
