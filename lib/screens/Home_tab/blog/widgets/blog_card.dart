import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../../models/blog_model.dart';

class BlogCard extends StatelessWidget {
  final BlogModel blog;
  final VoidCallback onTap;

  const BlogCard({
    Key? key,
    required this.blog,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0), // Đã được xử lý spacing trong grid
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            // QUAN TRỌNG: Đặt chiều cao cố định
            height: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Blog Image - Chiếm 120px cố định
                Stack(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: blog.image.url.isNotEmpty
                          ? Image.network(
                              blog.image.url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildImageLoading();
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                    
                    // Gradient Overlay
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    
                    // Category Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildCategoryChip(),
                    ),
                    
                    // Status Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildStatusChip(),
                    ),
                  ],
                ),
                
                // Content - Phần còn lại (160px)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title - Chiếm tối đa 2 dòng
                        Text(
                          blog.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Author - Xuống dòng nếu cần
                        Text(
                          _getAuthorName(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        
                        const SizedBox(height: 8),
                        
                        // Footer - Chiều cao cố định
                        _buildFooterInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        blog.category.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _getCategoryColor(),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 8,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            _getStatusText(),
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Views
          Row(
            children: [
              Icon(
                Icons.remove_red_eye_rounded,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 2),
              Text(
                '${blog.views}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          
          // Read time estimate
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 2),
              Text(
                '${_calculateReadTime(blog.content)} phút',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.article_rounded,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    final categoryColors = {
      'technology': Colors.blue[700]!,
      'design': Colors.purple[700]!,
      'business': Colors.green[700]!,
      'lifestyle': Colors.orange[700]!,
      'education': Colors.red[700]!,
    };
    
    return categoryColors[blog.category.toLowerCase()] ?? Colors.grey[700]!;
  }

  Color _getStatusColor() {
    switch (blog.approval) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (blog.approval) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
      default:
        return Icons.schedule_rounded;
    }
  }

  String _getStatusText() {
    switch (blog.approval) {
      case 'approved':
        return 'ĐÃ DUYỆT';
      case 'rejected':
        return 'TỪ CHỐI';
      case 'pending':
      default:
        return 'CHỜ DUYỆT';
    }
  }

  String _getCleanContent(String htmlString) {
    // Remove HTML tags
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String cleanText = htmlString.replaceAll(exp, '');
    
    // Trim and limit length
    const maxLength = 100; // Giảm xuống để phù hợp
    if (cleanText.length <= maxLength) return cleanText;
    return '${cleanText.substring(0, maxLength)}...';
  }

  int _calculateReadTime(String content) {
    final cleanContent = _getCleanContent(content);
    final wordCount = cleanContent.split(' ').length;
    final readTime = wordCount / 200; // 200 từ/phút
    return readTime.ceil().clamp(1, 10);
  }

  String _getAuthorName() {
    // Kiểm tra xem có fullname không
    if (blog.createdBy.fullname.isNotEmpty) {
      return blog.createdBy.fullname;
    }
    
    // Fallback: lấy phần trước @ của email
    final email = blog.createdBy.email;
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@')[0];
    }
    
    return 'Người dùng';
  }
}