import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String labelText;
  final String hintText;
  final String Function(T) displayString;
  final bool Function(T, String) filterFunction;

  const SearchableDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelText,
    required this.hintText,
    required this.displayString,
    required this.filterFunction,
  });

  @override
  _SearchableDropdownState<T> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget.filterFunction(item, _searchController.text))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _filteredItems = widget.items;
                _searchController.clear();
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value != null ? widget.displayString(widget.value!) : widget.hintText,
                    style: TextStyle(
                      color: widget.value != null ? Colors.black : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Divider(height: 1),
                Container(
                  height: 200,
                  child: _filteredItems.isEmpty
                      ? Center(child: Text('No items found'))
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return ListTile(
                              dense: true,
                              title: Text(widget.displayString(item)),
                              onTap: () {
                                setState(() {
                                  widget.onChanged(item);
                                  _isExpanded = false;
                                  _searchController.clear();
                                });
                              },
                            );
                          },
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
