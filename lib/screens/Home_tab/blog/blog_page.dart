import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/blog_model.dart';
import '../../../services/blog_service.dart';
import 'blog_detail_page.dart';
import 'create_create_blog.dart';
import 'widgets/blog_card.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/error_widget.dart';
import 'widgets/empty_state.dart';

class BlogListPage extends StatefulWidget {
  const BlogListPage({Key? key}) : super(key: key);

  @override
  State<BlogListPage> createState() => _BlogListPageState();
}

class _BlogListPageState extends State<BlogListPage> {
  late BlogService _blogService;
  List<BlogModel> _blogs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadBlogs();
  }

  void _initializeService() {
    _blogService = BlogService();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _blogService.getAllBlogs();
      
      if (result.success && result.data != null) {
        setState(() {
          _blogs = result.data!.blogs;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshBlogs() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadBlogs();
  }

  void _navigateToBlogDetail(BlogModel blog) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlogDetailPage(blog: blog),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToCreateBlog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateBlogPage()),
    ).then((_) => _loadBlogs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Khám phá tri thức',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        // ĐÃ BỎ NÚT QUAY LẠI
        actions: [
          _buildCreateButton(),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _navigateToCreateBlog,
        icon: const Icon(Icons.edit_rounded, size: 16),
        label: Text(
          'Viết Bài', // ĐÃ ĐỔI TỪ "Viết Blog" THÀNH "Viết Bài"
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 1,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToCreateBlog,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 2,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const BlogLoadingIndicator();
    }

    if (_errorMessage.isNotEmpty) {
      return BlogErrorWidget(
        errorMessage: _errorMessage,
        onRetry: _loadBlogs,
      );
    }

    return _buildBlogList();
  }

  Widget _buildBlogList() {
    return RefreshIndicator(
      onRefresh: _refreshBlogs,
      color: Colors.blue[600],
      backgroundColor: Colors.white,
      displacement: 40,
      child: CustomScrollView(
        slivers: [
          // Header với thống kê
          _buildHeaderSection(),
          
          // Grid blogs
          _blogs.isEmpty ? _buildEmptySliver() : _buildBlogGrid(),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
            const SizedBox(height: 4),
            Text(
              '${_blogs.length} bài viết chia sẻ từ cộng đồng',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick stats
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    // Tính toán số lượng blog theo trạng thái
    final approvedCount = _blogs.where((blog) => blog.approval == 'approved').length;
    final pendingCount = _blogs.where((blog) => blog.approval == 'pending').length;
    final totalViews = _blogs.fold(0, (sum, blog) => sum + blog.views);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.article_rounded, '${_blogs.length}', 'Bài viết'),
          _buildStatItem(Icons.visibility_rounded, '$totalViews', 'Lượt xem'),
          _buildStatItem(Icons.verified_rounded, '$approvedCount', 'Đã duyệt'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.blue[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  SliverFillRemaining _buildEmptySliver() {
    return SliverFillRemaining(
      child: BlogEmptyState(
        onRefresh: _refreshBlogs,
      ),
    );
  }

  Widget _buildBlogGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final blog = _blogs[index];
            return BlogCard(
              blog: blog,
              onTap: () => _navigateToBlogDetail(blog),
            );
          },
          childCount: _blogs.length,
        ),
      ),
    );
  }
}