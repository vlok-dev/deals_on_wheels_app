import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GroceryItem {
  final String id;
  final String userId;
  final String itemName;
  final String? quantity;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroceryItem({
    required this.id,
    required this.userId,
    required this.itemName,
    this.quantity,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as String?,
      completed: map['completed'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'item_name': itemName,
      'quantity': quantity,
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GroceryService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final Uuid _uuid = Uuid();

  static Future<List<GroceryItem>> getGroceryList(String userId) async {
    try {
      final response = await _client
          .from('groceries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final List<GroceryItem> groceries = (response as List)
          .map((item) => GroceryItem.fromMap(item))
          .toList();

      return groceries;
    } catch (e) {
      print('Error fetching grocery list: $e');
      return [];
    }
  }

  static Future<GroceryItem> addGroceryItem({
    required String userId,
    required String itemName,
    String? quantity,
  }) async {
    try {
      final newItem = GroceryItem(
        id: _uuid.v4(),
        userId: userId,
        itemName: itemName.trim(),
        quantity: quantity?.trim(),
        completed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _client.from('groceries').insert(newItem.toMap());

      return newItem;
    } catch (e) {
      print('Error adding grocery item: $e');
      rethrow;
    }
  }

  static Future<void> updateGroceryItem({
    required String id,
    required String itemName,
    required String? quantity,
    required bool completed,
  }) async {
    try {
      await _client
          .from('groceries')
          .update({
            'item_name': itemName.trim(),
            'quantity': quantity?.trim(),
            'completed': completed,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      print('Error updating grocery item: $e');
      rethrow;
    }
  }

  static Future<void> toggleGroceryItem(String id, bool completed) async {
    try {
      await _client
          .from('groceries')
          .update({
            'completed': completed,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      print('Error toggling grocery item: $e');
      rethrow;
    }
  }

  static Future<void> deleteGroceryItem(String id) async {
    try {
      await _client.from('groceries').delete().eq('id', id);
    } catch (e) {
      print('Error deleting grocery item: $e');
      rethrow;
    }
  }

  static Future<void> clearCompletedItems(String userId) async {
    try {
      await _client
          .from('groceries')
          .delete()
          .eq('user_id', userId)
          .eq('completed', true);
    } catch (e) {
      print('Error clearing completed items: $e');
      rethrow;
    }
  }

  static Future<int> getCompletedCount(String userId) async {
    try {
      final response = await _client
          .from('groceries')
          .select('id')
          .eq('user_id', userId)
          .eq('completed', true);

      return (response as List).length;
    } catch (e) {
      print('Error getting completed count: $e');
      return 0;
    }
  }

  static Future<int> getPendingCount(String userId) async {
    try {
      final response = await _client
          .from('groceries')
          .select('id')
          .eq('user_id', userId)
          .eq('completed', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting pending count: $e');
      return 0;
    }
  }
}
