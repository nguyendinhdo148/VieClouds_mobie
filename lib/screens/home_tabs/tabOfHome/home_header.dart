import 'package:flutter/material.dart';
import 'package:viejob_app/screens/home_tabs/tabOfHome/search_suggestions.dart';

class HomeHeader extends StatefulWidget {
  final Function(String) onSearch;

  const HomeHeader({
    Key? key,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchSuggestions = false;

  void _searchJobs() {
    if (_searchController.text.isNotEmpty) {
      widget.onSearch(_searchController.text);
    }
  }

  void _hideSuggestions() {
    setState(() {
      _showSearchSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo lớn thay thế chữ "Xin chào"
        Center(
          child: Container(
            width: 120,
            height: 60,
            child: Image.asset(
              'assets/images/vj1.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Dòng chữ phụ
        Center(
          child: Text(
            'Tìm công việc mơ ước của bạn',
            style: _TextStyles.bodyLarge.copyWith(
              color: _VibrantColors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Search Bar với hiệu ứng nổi bật
        GestureDetector(
          onTap: _hideSuggestions,
          child: Stack(
            children: [
              // Background glow effect
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _VibrantColors.blue.withOpacity(0.1),
                      _VibrantColors.purple.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _VibrantColors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // Main search bar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _VibrantColors.blue.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _VibrantColors.blue.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.search_rounded,
                      color: _VibrantColors.blue.withOpacity(0.7),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm công việc, công ty, kỹ năng...',
                          hintStyle: _TextStyles.bodyLarge.copyWith(
                            color: _VibrantColors.lightGrey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          setState(() {
                            _showSearchSuggestions = true;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _showSearchSuggestions = value.isNotEmpty;
                          });
                        },
                        onSubmitted: (_) => _searchJobs(),
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _VibrantColors.blue,
                            _VibrantColors.purple,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _VibrantColors.blue.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, 
                            color: Colors.white, size: 20),
                        onPressed: _searchJobs,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Suggestions
              if (_showSearchSuggestions && _searchController.text.isNotEmpty)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: SearchSuggestions(
                    searchText: _searchController.text,
                    onSuggestionTap: (suggestion) {
                      _searchController.text = suggestion;
                      _searchJobs();
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Màu sắc nổi bật
class _VibrantColors {
  static const Color blue = Color(0xFF4361EE);
  static const Color purple = Color(0xFF7209B7);
  static const Color dark = Color(0xFF2D3748);
  static const Color grey = Color(0xFF718096);
  static const Color lightGrey = Color(0xFFA0AEC0);
}

class _TextStyles {
  

  static final TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: _VibrantColors.dark,
  );
}