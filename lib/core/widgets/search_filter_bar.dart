import 'package:flutter/material.dart';

class SearchFilterBar<T> extends StatelessWidget {
  // Search
  final ValueChanged<String> onSearchChanged;

  // Filter
  final String? filterValue;
  final List<String> filterOptions;
  final ValueChanged<String?> onFilterChanged;
  final String filterLabel;

  // Sort
  final String? sortValue;
  final List<String> sortOptions;
  final ValueChanged<String?> onSortChanged;

  const SearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.filterOptions,
    required this.filterValue,
    required this.onFilterChanged,
    this.filterLabel = "Filter",
    required this.sortOptions,
    required this.sortValue,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Check if filter should be displayed
    final bool hasFilter = filterOptions.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // 1. SEARCH BOX
            TextField(
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
            const Divider(height: 1),

            // 2. FILTER & SORT ROW
            Row(
              children: [
                // --- FILTER SECTION (Only show if options exist) ---
                if (hasFilter) ...[
                  const Icon(Icons.filter_list, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: filterValue,
                        isExpanded: true,
                        hint: Text(filterLabel),
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        items: filterOptions.map((opt) {
                          return DropdownMenuItem(value: opt, child: Text(opt));
                        }).toList(),
                        onChanged: onFilterChanged,
                      ),
                    ),
                  ),

                  // Divider line
                  Container(width: 1, height: 24, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
                ],

                // --- SORT SECTION (Always visible) ---
                const Icon(Icons.sort, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sortValue,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      items: sortOptions.map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: onSortChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}