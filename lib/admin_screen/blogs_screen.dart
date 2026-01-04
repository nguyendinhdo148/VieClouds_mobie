// screens/admin_screen/blogs_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:viejob_app/services/admin_service.dart';
import 'package:viejob_app/services/auth_service.dart';
import 'package:viejob_app/core/secure_storage.dart';

class AdminBlogsScreen extends StatefulWidget {
  final String? status;
  
  const AdminBlogsScreen({Key? key, this.status}) : super(key: key);

  @override
  State<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

class _AdminBlogsScreenState extends State<AdminBlogsScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  
  bool _isLoading = true;
  bool _isMobile = false;
  Map<String, dynamic> _user = {};
  List<dynamic> _blogs = [];
  int _totalItems = 0;
  String _currentApproval = 'all';
  String _currentCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  // Danh mục blog (giống web)
  final List<Map<String, String>> _blogCategories = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'career_tips', 'label': 'Kinh nghiệm làm việc'},
    {'value': 'interview', 'label': 'Kỹ năng phỏng vấn'},
    {'value': 'resume', 'label': 'CV và Hồ sơ'},
    {'value': 'job_search', 'label': 'Tìm việc'},
    {'value': 'personal_development', 'label': 'Phát triển bản thân'},
    {'value': 'trends', 'label': 'Xu hướng'},
    {'value': 'industry_news', 'label': 'Tin tức ngành'},
    {'value': 'success_stories', 'label': 'Câu chuyện thành công'},
    {'value': 'work_life_balance', 'label': 'Cân bằng cuộc sống'},
    {'value': 'remote_work', 'label': 'Làm việc từ xa'},
    {'value': 'freelancing', 'label': 'Làm việc tự do'},
    {'value': 'leadership', 'label': 'Lãnh đạo'},
    {'value': 'networking', 'label': 'Xây dựng mối quan hệ'},
    {'value': 'entrepreneurship', 'label': 'Khởi nghiệp'},
    {'value': 'technology', 'label': 'Công nghệ'},
    {'value': 'soft_skills', 'label': 'Kỹ năng mềm'},
    {'value': 'hard_skills', 'label': 'Kỹ năng cứng'},
    {'value': 'education', 'label': 'Giáo dục và đào tạo'},
    {'value': 'workplace_culture', 'label': 'Văn hóa doanh nghiệp'},
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    try {
      final userJson = await _secureStorage.getUserData();
      
      if (userJson == null) {
        context.go('/login');
        return;
      }
      
      final user = jsonDecode(userJson);
      if (user['role'] != 'admin') {
        context.go('/login');
        return;
      }
      
      if (!mounted) return;
      
      setState(() {
        _user = user;
      });
      
      await _loadBlogs();
      
    } catch (e) {
      print('Error checking auth: $e');
      context.go('/login');
    }
  }

// Trong blogs_screen.dart, sửa _loadBlogs:
Future<void> _loadBlogs({String? search}) async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Gọi API giống web React: /blog/all-blogs
    final result = await _adminService.getAllBlogs(
      approval: _currentApproval == 'all' ? null : _currentApproval,
      category: _currentCategory == 'all' ? null : _currentCategory,
      search: search,
    );
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      final blogs = result['blogs'] ?? [];
      setState(() {
        _blogs = blogs;
        _totalItems = result['total'] ?? result['count'] ?? blogs.length;
        _isLoading = false;
      });
      
      print('Loaded ${blogs.length} blogs'); // Debug
      
      // Debug: In ra dữ liệu blog đầu tiên
      if (blogs.isNotEmpty) {
        print('First blog data: ${blogs[0]}');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Error loading blogs: ${result['error']}'); // Debug
      _showError('Không thể tải danh sách bài viết: ${result['error']}');
    }
  } catch (e) {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    print('Exception loading blogs: $e'); // Debug
    _showError('Lỗi: $e');
  }
}
  Future<void> _approveBlog(String blogId, String blogTitle) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc muốn duyệt bài viết "$blogTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duyệt', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final result = await _adminService.approveBlog(blogId);
      
      if (result['success'] == true) {
        _showSuccess('Đã duyệt bài viết thành công');
        await _loadBlogs(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể duyệt bài viết');
      }
    }
  }

  Future<void> _rejectBlog(String blogId, String blogTitle) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối bài viết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bài viết: "$blogTitle"'),
            const SizedBox(height: 12),
            const Text('Lý do từ chối:'),
            const SizedBox(height: 4),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final result = await _adminService.rejectBlog(blogId, reasonController.text);
      
      if (result['success'] == true) {
        _showSuccess('Đã từ chối bài viết thành công');
        await _loadBlogs(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể từ chối bài viết');
      }
    }
  }

  Future<void> _deleteBlog(String blogId, String blogTitle) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bài viết "$blogTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final result = await _adminService.deleteBlog(blogId);
      
      if (result['success'] == true) {
        _showSuccess('Đã xóa bài viết thành công');
        await _loadBlogs(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể xóa bài viết');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
    final author = blog['created_by'] ?? {};
    final image = blog['image'] ?? {};
    final tags = List<String>.from(blog['tags'] ?? []);
    final isPending = blog['approval']?.toString() == 'pending';
    final isApproved = blog['approval']?.toString() == 'approved';
    final isRejected = blog['approval']?.toString() == 'rejected';
    final approvalNote = blog['approvalNote']?.toString() ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh blog
            if (image['url'] != null && image['url'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image['url'].toString(),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.purple.shade50,
                        border: Border.all(color: Colors.purple.shade100),
                      ),
                      child: Icon(
                        Iconsax.document_text,
                        size: 32,
                        color: Colors.purple.shade300,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.purple.shade50,
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Icon(
                  Iconsax.document_text,
                  size: 32,
                  color: Colors.purple.shade300,
                ),
              ),
            
            const SizedBox(width: 12),
            
            // Thông tin blog
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog['title']?.toString() ?? 'Không có tiêu đề',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Iconsax.user, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  author['fullname']?.toString() ?? 'Ẩn danh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getApprovalColor(blog['approval']?.toString()).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getApprovalColor(blog['approval']?.toString()).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getApprovalText(blog['approval']?.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getApprovalColor(blog['approval']?.toString()),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tags
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        )),
                        if (tags.length > 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${tags.length - 2}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  
                  // Thông tin thêm
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Danh mục
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Text(
                          _getCategoryLabel(blog['category']?.toString()),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Lượt xem
                      Row(
                        children: [
                          Icon(Iconsax.eye, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${blog['views'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      
                      // Ngày tạo
                      Row(
                        children: [
                          Icon(Iconsax.calendar, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(blog['createdAt']?.toString()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Lý do từ chối
                  if (isRejected && approvalNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Iconsax.info_circle, size: 14, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lý do: $approvalNote',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Nút thao tác
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chỉ hiển thị nút duyệt/từ chối khi chờ duyệt
                if (isPending) ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveBlog(
                      blog['_id'].toString(), 
                      blog['title']?.toString() ?? 'bài viết'
                    ),
                    icon: const Icon(Iconsax.tick_circle, size: 14),
                    label: const Text('Duyệt', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _rejectBlog(
                      blog['_id'].toString(), 
                      blog['title']?.toString() ?? 'bài viết'
                    ),
                    icon: const Icon(Iconsax.close_circle, size: 14),
                    label: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteBlog(
                    blog['_id'].toString(), 
                    blog['title']?.toString() ?? 'bài viết'
                  ),
                  icon: const Icon(Iconsax.trash, size: 14),
                  label: const Text('Xóa', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getApprovalColor(String? approval) {
    final approvalStr = approval?.toString() ?? 'pending';
    switch (approvalStr) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getApprovalText(String? approval) {
    final approvalStr = approval?.toString() ?? 'pending';
    switch (approvalStr) {
      case 'approved':
        return 'Đã duyệt';
      case 'pending':
        return 'Chờ duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return approvalStr;
    }
  }

  String _getCategoryLabel(String? categoryValue) {
    if (categoryValue == null) return 'Khác';
    
    final category = _blogCategories.firstWhere(
      (cat) => cat['value'] == categoryValue,
      orElse: () => {'value': 'other', 'label': 'Khác'},
    );
    
    return category['label']!;
  }

  Widget _buildContent() {
    _isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: _isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải danh sách bài viết...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_blogs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.document_text,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có bài viết nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadBlogs(),
                child: ListView.builder(
                  itemCount: _blogs.length,
                  itemBuilder: (context, index) => _buildBlogCard(_blogs[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: <Widget>[
          if (!_isMobile) _buildDesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!_isMobile) _buildDesktopAppBar(),
                Expanded(
                  child: _isLoading && _user.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                'Đang tải...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _isMobile ? _buildMobileSidebar() : null,
      appBar: _isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Iconsax.menu_1, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản lý bài viết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Danh sách bài viết',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Container _buildDesktopAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Quản lý bài viết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _user['fullname']?.toString().isNotEmpty == true
                          ? _user['fullname'].toString()[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user['fullname']?.toString() ?? 'Admin',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quản trị viên',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildSidebarItem(
                      icon: Iconsax.home_2,
                      label: 'Dashboard',
                      isActive: GoRouterState.of(context).uri.toString() == '/admin',
                      onTap: () => context.go('/admin'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.profile_2user,
                      label: 'Quản lý người dùng',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/users'),
                      onTap: () => context.go('/admin/users'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.building_4,
                      label: 'Quản lý công ty',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/companies'),
                      onTap: () => context.go('/admin/companies'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.briefcase,
                      label: 'Quản lý việc làm',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/jobs'),
                      onTap: () => context.go('/admin/jobs'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.document_text,
                      label: 'Quản lý blog',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/blogs'),
                      onTap: () => context.go('/admin/blogs'),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.logout, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _authService.logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 256,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _user['fullname']?.toString().isNotEmpty == true
                          ? _user['fullname'].toString()[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user['fullname']?.toString() ?? 'Admin',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quản trị viên',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSidebarItem(
                      icon: Iconsax.home_2,
                      label: 'Dashboard',
                      isActive: GoRouterState.of(context).uri.toString() == '/admin',
                      onTap: () => context.go('/admin'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.profile_2user,
                      label: 'Quản lý người dùng',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/users'),
                      onTap: () => context.go('/admin/users'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.building_4,
                      label: 'Quản lý công ty',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/companies'),
                      onTap: () => context.go('/admin/companies'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.briefcase,
                      label: 'Quản lý việc làm',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/jobs'),
                      onTap: () => context.go('/admin/jobs'),
                    ),
                    _buildSidebarItem(
                      icon: Iconsax.document_text,
                      label: 'Quản lý blog',
                      isActive: GoRouterState.of(context).uri.toString().contains('/admin/blogs'),
                      onTap: () => context.go('/admin/blogs'),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.logout, size: 16, color: Colors.red),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _authService.logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.blue : Colors.grey,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isActive ? Colors.blue : Colors.black,
        ),
      ),
      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      dense: true,
      onTap: onTap,
    );
  }
}