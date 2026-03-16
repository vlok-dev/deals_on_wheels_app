import 'package:flutter/material.dart';

class CitySelector extends StatelessWidget {
  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String> onChanged;
  const CitySelector({required this.cities, required this.selectedCity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCity,
      decoration: InputDecoration(labelText: 'Select your city'),
      items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
