import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_profile_service.dart';
import '../services/deals_service.dart';

class DealsFeedScreen extends StatefulWidget {
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
    setState(() {
      _userCity = city;
    });
    if (city != null) {
      final deals = await DealsService.getDealsForCity(city);
      setState(() {
        _deals = deals;
        _visibleCount = 5;
      });
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
    print('DEBUG: _postDeal called');
    print('DEBUG: user = ' + (user?.id ?? 'null'));
    print('DEBUG: user email = ' + (user?.email ?? 'null'));
    print('DEBUG: _userCity = ' + (_userCity ?? 'null'));
    print('DEBUG: deal text = ' + _dealController.text.trim());
    if (_dealController.text.trim().isEmpty || user == null || _userCity == null) {
      print('DEBUG: Missing required field, aborting post');
      return;
    }
    final content = _dealController.text.trim();
    try {
      await DealsService.postDeal(
        userId: user.id,
        userEmail: user.email ?? 'Unknown',
        city: _userCity!,
        content: content,
      );
      print('DEBUG: Post insert succeeded');
      final deals = await DealsService.getDealsForCity(_userCity!);
      setState(() {
        _deals = deals;
        _visibleCount = 5;
        _dealController.clear();
      });
    } catch (e) {
      print('DEBUG: Post insert failed: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post deal: ' + e.toString())),
      );
    }
  }

  void _reactToDeal(int index, String emoji) {
    setState(() {
      _deals[index]['reactions'][emoji]++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deals Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Deals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _userCity == null
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('City: $_userCity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dealController,
                              decoration: InputDecoration(
                                labelText: 'Post a deal',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: _userCity == null ? null : _postDeal,
                          ),
                        ],
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
                                                SizedBox(height: 4),
                                                Text(deal['content'] ?? ''),
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
        ],
      ),
    );
  }
}
