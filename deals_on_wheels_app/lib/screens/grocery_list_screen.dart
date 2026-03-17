import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/grocery_service.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({Key? key}) : super(key: key);
  
  @override
  GroceryListScreenState createState() => GroceryListScreenState();
}

class GroceryListScreenState extends State<GroceryListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  List<GroceryItem> _groceries = [];
  bool _isLoading = false;
  int _completedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadGroceryList();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadGroceryList() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groceries = await GroceryService.getGroceryList(user.id);
      final completedCount = await GroceryService.getCompletedCount(user.id);
      final pendingCount = await GroceryService.getPendingCount(user.id);

      if (mounted) {
        setState(() {
          _groceries = groceries;
          _completedCount = completedCount;
          _pendingCount = pendingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grocery list: $e')),
        );
      }
    }
  }

  Future<void> _addGroceryItem() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_itemController.text.trim().isEmpty) return;

    try {
      await GroceryService.addGroceryItem(
        userId: user.id,
        itemName: _itemController.text.trim(),
        quantity: _quantityController.text.trim().isEmpty ? null : _quantityController.text.trim(),
      );

      _itemController.clear();
      _quantityController.clear();
      FocusScope.of(context).unfocus();
      await _loadGroceryList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    }
  }

  Future<void> _toggleItem(GroceryItem item) async {
    try {
      await GroceryService.toggleGroceryItem(item.id, !item.completed);
      await _loadGroceryList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(GroceryItem item) async {
    try {
      await GroceryService.deleteGroceryItem(item.id);
      await _loadGroceryList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  Future<void> clearCompleted() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await GroceryService.clearCompletedItems(user.id);
      await _loadGroceryList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Completed items cleared!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing items: $e')),
        );
      }
    }
  }

  void showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Grocery Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Milk, Bread, Eggs',
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity (Optional)',
                hintText: 'e.g., 2 litres, 1 dozen',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addGroceryItem(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _itemController.clear();
              _quantityController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addGroceryItem();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                // Stats Card
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$_pendingCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text('Pending', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$_completedCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text('Completed', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${_pendingCount + _completedCount}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text('Total', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Grocery List
                Expanded(
                  child: _groceries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No items yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Tap + to add your first item',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _groceries.length,
                          itemBuilder: (context, index) {
                            final item = _groceries[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Checkbox(
                                  value: item.completed,
                                  onChanged: (value) => _toggleItem(item),
                                  activeColor: Colors.green,
                                ),
                                title: Text(
                                  item.itemName,
                                  style: TextStyle(
                                    decoration: item.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.completed
                                        ? Colors.grey
                                        : null,
                                  ),
                                ),
                                subtitle: item.quantity != null
                                    ? Text(
                                        item.quantity!,
                                        style: TextStyle(
                                          color: item.completed
                                              ? Colors.grey
                                              : Colors.blue[600],
                                        ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteItem(item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
              ),
            ),
          );
  }
}
