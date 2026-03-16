import 'package:supabase_flutter/supabase_flutter.dart';

class DealsService {
  static final _client = Supabase.instance.client;

  static Future<void> postDeal({
    required String userId,
    required String userEmail,
    required String city,
    required String content,
  }) async {
    await _client.from('posts').insert({
      'user_id': userId,
      'user_email': userEmail,
      'city': city,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getDealsForCity(String city) async {
    final res = await _client.from('posts').select().eq('city', city).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
