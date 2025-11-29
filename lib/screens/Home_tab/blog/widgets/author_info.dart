import 'package:flutter/material.dart';
import '/../../models/blog_model.dart';

class AuthorInfo extends StatelessWidget {
  final BlogModel blog;

  const AuthorInfo({Key? key, required this.blog}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),
            // Author Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getAuthorName(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_getAuthorBio().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getAuthorBio(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _getAuthorEmail(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final profilePhotoUrl = blog.createdBy.profile?.profilePhoto.url;
    
    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(profilePhotoUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Nếu ảnh lỗi, sẽ hiển thị fallback avatar
        },
        child: profilePhotoUrl.isEmpty ? _buildFallbackAvatar() : null,
      );
    }
    
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.blue[100],
      child: Text(
        _getAuthorInitials(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  String _getAuthorInitials() {
    final name = _getAuthorName();
    if (name.isNotEmpty && name != 'Người dùng') {
      final nameParts = name.split(' ').where((part) => part.isNotEmpty).toList();
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty) {
        return nameParts[0].substring(0, 1).toUpperCase();
      }
    }
    
    // Fallback từ email
    final email = _getAuthorEmail();
    if (email.isNotEmpty && email.contains('@') && email != 'Chưa có email') {
      return email.substring(0, 1).toUpperCase();
    }
    
    return 'U';
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

  String _getAuthorEmail() {
    return blog.createdBy.email.isNotEmpty 
        ? blog.createdBy.email 
        : 'Chưa có email';
  }

  String _getAuthorBio() {
    return blog.createdBy.profile?.bio ?? '';
  }
}