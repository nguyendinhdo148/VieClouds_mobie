import 'package:flutter/material.dart';

class SearchSuggestions extends StatelessWidget {
  final String searchText;
  final Function(String) onSuggestionTap;

  const SearchSuggestions({
    Key? key,
    required this.searchText,
    required this.onSuggestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Lập trình viên Flutter',
      'Kế toán tổng hợp',
      'Nhân viên kinh doanh',
      'Marketing Digital',
      'UI/UX Designer',
      'Quản lý dự án'
    ];

    final filteredSuggestions = suggestions
        .where((suggestion) => suggestion
            .toLowerCase()
            .contains(searchText.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: _PastelColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gợi ý tìm kiếm',
              style: _TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: _PastelColors.dark,
              ),
            ),
          ),
          ...filteredSuggestions.map((suggestion) => ListTile(
                title: Text(
                  suggestion,
                  style: _TextStyles.bodyMedium,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _PastelColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.search, size: 18, color: _PastelColors.primary),
                ),
                onTap: () => onSuggestionTap(suggestion),
              )),
        ],
      ),
    );
  }
}

class _PastelColors {
  static const Color primary = Color(0xFFA8D8EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF2D3748);
}

class _TextStyles {
  static final TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: _PastelColors.dark,
  );
}