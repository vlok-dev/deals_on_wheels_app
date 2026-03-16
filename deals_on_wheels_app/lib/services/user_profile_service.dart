import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  static final _client = Supabase.instance.client;

  static Future<void> setCity(String userId, String city) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'city': city,
    });
  }

  static Future<String?> getCity(String userId) async {
    final res = await _client.from('profiles').select('city').eq('id', userId).single();
    return res['city'] as String?;
  }
}
