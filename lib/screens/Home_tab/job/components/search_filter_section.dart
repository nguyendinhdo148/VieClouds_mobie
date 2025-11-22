import 'package:flutter/material.dart';

class SearchFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final String selectedLocation;
  final String selectedSalary;
  final bool isSearching;
  final List<String> categories;
  final List<String> locations;
  final List<String> salaries;
  final VoidCallback onSearch;
  final Function(String, String) onFilterChanged;
  final VoidCallback onAdvancedFilter;

  const SearchFilterSection({
    Key? key,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.selectedSalary,
    required this.isSearching,
    required this.categories,
    required this.locations,
    required this.salaries,
    required this.onSearch,
    required this.onFilterChanged,
    required this.onAdvancedFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc, kỹ năng, công ty...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: Colors.grey),
                      onPressed: onAdvancedFilter,
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (value) => onSearch(),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Lĩnh vực', selectedCategory, 
                    () => _showFilterBottomSheet(context, 'category')),
                const SizedBox(width: 8),
                _buildFilterChip('Địa điểm', selectedLocation, 
                    () => _showFilterBottomSheet(context, 'location')),
                const SizedBox(width: 8),
                _buildFilterChip('Mức lương', selectedSalary, 
                    () => _showFilterBottomSheet(context, 'salary')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value.length > 15 ? '${value.substring(0, 15)}...' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, String filterType) {
    List<String> options = [];
    String title = '';
    String selectedValue = '';

    switch (filterType) {
      case 'category':
        options = categories;
        title = 'Chọn lĩnh vực';
        selectedValue = selectedCategory;
        break;
      case 'location':
        options = locations;
        title = 'Chọn địa điểm';
        selectedValue = selectedLocation;
        break;
      case 'salary':
        options = salaries;
        title = 'Chọn mức lương';
        selectedValue = selectedSalary;
        break;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => ListTile(
                title: Text(option),
                trailing: option == selectedValue
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  onFilterChanged(filterType, option);
                  Navigator.pop(context);
                },
              )).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}