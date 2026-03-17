import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_profile_service.dart';
import '../services/deals_service.dart';
import '../services/location_service.dart';
import '../services/openstreetmap_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/openstreetmap_store_selector.dart';

class DealsFeedScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DealsFeedScreen({Key? key, this.onNavigate}) : super(key: key);
  
  @override
  _DealsFeedScreenState createState() => _DealsFeedScreenState();
}

class _DealsFeedScreenState extends State<DealsFeedScreen> with SingleTickerProviderStateMixin {
    void _logout() async {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  late TabController _tabController;
  final TextEditingController _dealController = TextEditingController();
  List<Map<String, dynamic>> _deals = [];
  int _visibleCount = 5;
  String? _userCity;
  String? _selectedSuburb;
  String? _selectedShopLocation;
  String? _selectedImageUrl;
  bool _isUploading = false;
  final List<String> _emojis = ['👍', '🔥', '😂', '😍', '😮'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadUserCityAndDeals();
  }

  Future<void> _loadUserCityAndDeals() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final city = await UserProfileService.getCity(user.id);
    if (mounted) {
      setState(() {
        _userCity = city;
      });
    }
    if (city != null) {
      final deals = await DealsService.getDealsForCity(city);
      if (mounted) {
        setState(() {
          _deals = deals;
          _visibleCount = 5;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dealController.dispose();
    super.dispose();
  }

  void _postDeal() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (_dealController.text.trim().isEmpty || user == null || _userCity == null) {
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    final content = _dealController.text.trim();
    
    try {
      // Extract store details from selected store location
      String? shopName;
      String? shopAddress;
      double? shopLat;
      double? shopLng;
      String? placeId;

      if (_selectedShopLocation != null) {
        // This would be populated from the OpenStreetMap selection
        // For now, we'll extract the shop name from the selected location
        final parts = _selectedShopLocation!.split(' - ');
        shopName = parts.isNotEmpty ? parts[0] : _selectedShopLocation;
        shopAddress = parts.length > 1 ? parts.sublist(1).join(' - ') : null;
      }

      await DealsService.postDeal(
        userId: user.id,
        userEmail: user.email ?? 'Unknown',
        city: _userCity!,
        suburb: _selectedSuburb,
        shop: shopName,
        shopLocation: _selectedShopLocation,
        shopLatitude: shopLat,
        shopLongitude: shopLng,
        googlePlaceId: placeId,
        content: content,
        // Temporarily disable image upload
        imageUrl: null,
      );
      
      final deals = await DealsService.getDealsForCity(_userCity!);
      if (mounted) {
        setState(() {
          _deals = deals;
          _visibleCount = 5;
          _dealController.clear();
          _selectedImageUrl = null;
          _selectedSuburb = null;
          _selectedShopLocation = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post deal: ' + e.toString())),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    // Show dialog to choose between camera and gallery
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await DealsService.pickImageFromCamera();
                if (image != null) {
                  setState(() {
                    _selectedImageUrl = image.path;
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await DealsService.pickImageFromGallery();
                if (image != null) {
                  setState(() {
                    _selectedImageUrl = image.path;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _extractShopName(String shopLocation) {
    // Extract shop name from "Spar - Walmer Park" -> "Spar"
    return shopLocation.split(' - ')[0].trim();
  }

  void _reactToDeal(int index, String emoji) {
    setState(() {
      _deals[index]['reactions'][emoji]++;
    });
  }

  void _navigateToGroceryList() {
    widget.onNavigate?.call(1);
  }

  void _navigateToProfile() {
    widget.onNavigate?.call(2);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: _userCity == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('City: $_userCity', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SearchableDropdown<String>(
                              items: LocationService.getSuburbsForCity(_userCity!),
                              value: _selectedSuburb,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSuburb = value;
                                  _selectedShopLocation = null; // Reset shop location when suburb changes
                                });
                              },
                              labelText: 'Suburb',
                              hintText: 'Select suburb',
                              displayString: (suburb) => suburb,
                              filterFunction: (suburb, query) => suburb.toLowerCase().contains(query.toLowerCase()),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      OpenStreetMapStoreSelector(
                        selectedStore: _selectedShopLocation,
                        onChanged: (value) => setState(() => _selectedShopLocation = value),
                        city: _userCity,
                        suburb: _selectedSuburb,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dealController,
                              decoration: InputDecoration(
                                labelText: 'Post a deal',
                              ),
                              maxLines: 3,
                            ),
                          ),
                          // Temporarily disable image button until we fix picker
                          // IconButton(
                          //   icon: Icon(Icons.camera_alt),
                          //   onPressed: _isUploading ? null : _pickImage,
                          //   tooltip: 'Take Photo',
                          // ),
                          IconButton(
                            icon: _isUploading 
                                ? CircularProgressIndicator()
                                : Icon(Icons.send),
                            onPressed: _userCity == null || _isUploading ? null : _postDeal,
                          ),
                        ],
                      ),
                      // Temporarily disable image preview
                      // if (_selectedImageUrl != null)
                      //   Container(
                      //     margin: EdgeInsets.symmetric(vertical: 8),
                      //     height: 200,
                      //     width: double.infinity,
                      //     decoration: BoxDecoration(
                      //       borderRadius: BorderRadius.circular(8),
                      //       border: Border.all(color: Colors.grey),
                      //     ),
                      //     child: Stack(
                      //       children: [
                      //         ClipRRect(
                      //           borderRadius: BorderRadius.circular(8),
                      //           child: Image.file(
                      //             _selectedImageUrl!.startsWith('file://') 
                      //               ? File(_selectedImageUrl!.replaceFirst('file://', ''))
                      //               : File(_selectedImageUrl!),
                      //             fit: BoxFit.cover,
                      //             errorBuilder: (context, error, stackTrace) {
                      //               return Center(child: Text('Error loading image'));
                      //             },
                      //           ),
                      //         ),
                      //         Positioned(
                      //           top: 8,
                      //           right: 8,
                      //           child: GestureDetector(
                      //             onTap: () {
                      //               setState(() {
                      //                 _selectedImageUrl = null;
                      //               });
                      //             },
                      //             child: Container(
                      //               padding: EdgeInsets.all(4),
                      //               decoration: BoxDecoration(
                      //                 color: Colors.black54,
                      //                 shape: BoxShape.circle,
                      //               ),
                      //               child: Icon(Icons.close, color: Colors.white, size: 20),
                      //             ),
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      SizedBox(height: 16),
                      // Navigation tabs
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to deals feed (current screen)
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    children: [
                                      Icon(Icons.local_offer, color: Colors.blue),
                                      Text('Deals', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to grocery list
                                  _navigateToGroceryList();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    children: [
                                      Icon(Icons.shopping_cart, color: Colors.grey),
                                      Text('Grocery List', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to profile
                                  _navigateToProfile();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    children: [
                                      Icon(Icons.person, color: Colors.grey),
                                      Text('Profile', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: _deals.isEmpty
                            ? Center(child: Text('No deals yet.'))
                            : Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: (_visibleCount > _deals.length) ? _deals.length : _visibleCount,
                                      itemBuilder: (context, index) {
                                        final deal = _deals[index];
                                        return Card(
                                          margin: EdgeInsets.symmetric(vertical: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deal['user_email'] ?? 'Unknown',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 2),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(deal['city'] ?? '', style: TextStyle(fontSize: 12)),
                                                ),
                                                if (deal['suburb'] != null && deal['suburb'].toString().isNotEmpty)
                                                  Container(
                                                    margin: EdgeInsets.only(top: 4),
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade100,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(deal['suburb'], style: TextStyle(fontSize: 12)),
                                                  ),
                                                if (deal['shop_location'] != null && deal['shop_location'].toString().isNotEmpty)
                                                  Container(
                                                    margin: EdgeInsets.only(top: 4),
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.shade100,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(deal['shop_location'], style: TextStyle(fontSize: 12)),
                                                  ),
                                                SizedBox(height: 4),
                                                Text(deal['content'] ?? ''),
                                                if (deal['image_url'] != null && deal['image_url'].toString().isNotEmpty)
                                                  Container(
                                                    margin: EdgeInsets.only(top: 8),
                                                    height: 200,
                                                    width: double.infinity,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        deal['image_url'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            height: 200,
                                                            color: Colors.grey[200],
                                                            child: Center(child: Text('Image not available')),
                                                          );
                                                        },
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return Container(
                                                            height: 200,
                                                            color: Colors.grey[200],
                                                            child: Center(child: CircularProgressIndicator()),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                // ...existing emoji reaction row (to be improved in next step)...
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_visibleCount < _deals.length && _visibleCount < 20)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _visibleCount = (_visibleCount + 5 > 20) ? 20 : _visibleCount + 5;
                                          });
                                        },
                                        child: Text('Load More'),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
              ),
            );
  }
}
