import 'package:flutter/material.dart';
import '../models/destination_model.dart';

/// Dropdown list of matching destinations shown below a destination input
/// while it has focus — used on both the Home search shortcut and the
/// Search screen's destination field.
class DestinationSuggestionsList extends StatelessWidget {
  final List<DestinationModel> suggestions;
  final ValueChanged<DestinationModel> onSelected;
  const DestinationSuggestionsList({super.key, required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          final d = suggestions[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined, size: 18, color: Colors.blue),
            title: Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(d.country, style: const TextStyle(fontSize: 12)),
            onTap: () => onSelected(d),
          );
        },
      ),
    );
  }
}
