import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'deals_feed_screen.dart';
import 'grocery_list_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<GroceryListScreenState> _groceryListKey = GlobalKey<GroceryListScreenState>();
  late TabController _tabController;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _screens = [
      DealsFeedScreen(
        key: Key('deals_feed'),
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      GroceryListScreen(key: _groceryListKey),
      ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Deals Feed';
      case 1:
        return 'Grocery List';
      case 2:
        return 'Profile';
      default:
        return '';
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_currentIndex) {
      case 0:
        return [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ];
      case 1:
        return [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              _groceryListKey.currentState?.clearCompleted();
            },
            tooltip: 'Clear Completed',
          ),
        ];
      case 2:
        return [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            tooltip: 'Logout',
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: _getAppBarActions(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton(
        onPressed: () {
          _groceryListKey.currentState?.showAddItemDialog();
        },
        child: Icon(Icons.add),
        tooltip: 'Add Item',
      ) : null,
    );
  }
}
