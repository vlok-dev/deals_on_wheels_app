import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class DealsService {
  static final _client = Supabase.instance.client;
  static final _picker = ImagePicker();

  static Future<void> postDeal({
    required String userId,
    required String userEmail,
    required String city,
    required String content,
    String? suburb,
    String? shop,
    String? shopLocation,
    String? imageUrl,
    double? shopLatitude,
    double? shopLongitude,
    String? googlePlaceId,
  }) async {
    await _client.from('posts').insert({
      'user_id': userId,
      'user_email': userEmail,
      'city': city,
      'suburb': suburb,
      'shop': shop,
      'shop_location': shopLocation,
      'content': content,
      'image_url': imageUrl,
      'shop_latitude': shopLatitude,
      'shop_longitude': shopLongitude,
      'google_place_id': googlePlaceId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<String?> uploadImage(String userId, XFile imageFile) async {
    try {
      final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();
      
      await _client.storage.from('deal-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      
      final publicUrl = _client.storage.from('deal-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('DEBUG: Error uploading image: $e');
      return null;
    }
  }

  static Future<XFile?> pickImage({ImageSource source = ImageSource.camera}) async {
    try {
      print('DEBUG: Attempting to pick image from source: $source');
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      print('DEBUG: Image picked: ${image?.path}');
      return image;
    } catch (e) {
      print('DEBUG: Error picking image from $source: $e');
      // Try gallery as fallback if camera fails
      if (source == ImageSource.camera) {
        print('DEBUG: Camera failed, trying gallery as fallback');
        return await pickImage(source: ImageSource.gallery);
      }
      return null;
    }
  }

  static Future<XFile?> pickImageFromCamera() async {
    return await pickImage(source: ImageSource.camera);
  }

  static Future<XFile?> pickImageFromGallery() async {
    return await pickImage(source: ImageSource.gallery);
  }

  static Future<List<Map<String, dynamic>>> getDealsForCity(String city) async {
    try {
      print('DEBUG: Querying deals for city: "$city"');
      final res = await _client.from('posts').select().eq('city', city).order('created_at', ascending: false);
      print('DEBUG: Query result: $res');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('DEBUG: Error getting deals for city $city: $e');
      return [];
    }
  }
}
