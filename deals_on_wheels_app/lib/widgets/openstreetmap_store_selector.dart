import 'package:flutter/material.dart';
import 'dart:async';
import '../services/openstreetmap_service.dart';

class OpenStreetMapStoreSelector extends StatefulWidget {
  final String? selectedStore;
  final ValueChanged<String?> onChanged;
  final String? city;
  final String? suburb;

  const OpenStreetMapStoreSelector({
    required this.selectedStore,
    required this.onChanged,
    this.city,
    this.suburb,
  });

  @override
  _OpenStreetMapStoreSelectorState createState() => _OpenStreetMapStoreSelectorState();
}

class _OpenStreetMapStoreSelectorState extends State<OpenStreetMapStoreSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = false;
  bool _storeSelected = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.selectedStore != null) {
      _controller.text = widget.selectedStore!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchStores(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _stores = [];
      });
      return;
    }

    // Only search if query has at least 2 characters
    if (query.length < 2) return;

    setState(() {
      _isLoading = true;
    });

    // Debounce: wait 800ms before making API call
    _debounceTimer = Timer(Duration(milliseconds: 800), () async {
      try {
        final results = await OpenStreetMapService.searchGroceryStores(query, widget.city, widget.suburb);
        print('DEBUG: Search results for "$query": ${results.length} stores found');
        for (int i = 0; i < results.length; i++) {
          final store = results[i];
          print('DEBUG: Store $i: ${OpenStreetMapService.getStoreName(store)} - ${OpenStreetMapService.getStoreAddress(store)}');
        }
        
        if (mounted) {
          setState(() {
            _stores = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('DEBUG: Search error: $e');
        if (mounted) {
          setState(() {
            _stores = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  void _onStoreSelected(Map<String, dynamic> store) {
    final storeName = OpenStreetMapService.getStoreName(store);
    final storeAddress = OpenStreetMapService.getStoreAddress(store);
    
    // Format address to be shorter - only show suburb and city
    final shortAddress = _formatStoreAddress(storeAddress);
    final fullStoreInfo = '$storeName - $shortAddress';
    
    print('DEBUG: Store selected: $storeName');
    print('DEBUG: Store address: $storeAddress');
    print('DEBUG: Short address: $shortAddress');
    print('DEBUG: Full store info: $fullStoreInfo');
    
    widget.onChanged(fullStoreInfo);
    _controller.text = storeName;
    setState(() {
      _stores = [];
      _storeSelected = true;
    });
    
    // Clear the selected flag after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _storeSelected = false;
        });
      }
    });
    
    FocusScope.of(context).unfocus();
  }

  String _formatStoreAddress(String fullAddress) {
    // Extract just the suburb and city from a long address
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      // Take the last 2 parts (usually suburb and city)
      final suburb = parts[parts.length - 2].trim();
      final city = parts[parts.length - 1].trim().replaceAll('South Africa', '').trim();
      return '$suburb, $city';
    } else if (parts.length == 1) {
      // If only one part, try to get first 50 characters
      final singlePart = parts[0].trim();
      return singlePart.length > 50 ? '${singlePart.substring(0, 50)}...' : singlePart;
    }
    return fullAddress;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                  decoration: BoxDecoration(
                    color: _storeSelected ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _storeSelected ? Colors.green : Colors.grey,
                      width: _storeSelected ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for grocery stores...',
                      prefixIcon: Icon(
                        _storeSelected ? Icons.check_circle : Icons.search,
                        color: _storeSelected ? Colors.green : null,
                      ),
                      suffixIcon: _isLoading 
                          ? Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                widget.onChanged(null);
                                setState(() {
                                  _stores = [];
                                  _storeSelected = false;
                                });
                                // Focus back to the text field for new input
                                _focusNode.requestFocus();
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _searchStores,
                  ),
                ),
              if (_stores.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _stores.length,
                    itemBuilder: (context, index) {
                      final store = _stores[index];
                      final storeName = OpenStreetMapService.getStoreName(store);
                      final storeAddress = OpenStreetMapService.getStoreAddress(store);
                      
                      return InkWell(
                        onTap: () => _onStoreSelected(store),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, size: 20, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storeName,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      storeAddress,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        if (widget.city != null && widget.suburb != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🆓 Searching stores in ${widget.suburb}, ${widget.city} only',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.city != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Select a suburb to filter stores by location',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
