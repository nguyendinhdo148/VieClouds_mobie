import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:viejob_app/services/blog_service.dart';
import 'package:viejob_app/core/api.dart';

class CreateBlogPage extends StatefulWidget {
  const CreateBlogPage({Key? key}) : super(key: key);

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _blogService = BlogService();
  final _apiClient = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Danh mục phổ biến
  final List<String> _commonCategories = [
    'Công nghệ',
    'Lập trình',
    'Thiết kế',
    'Kinh doanh',
    'Đời sống',
    'Giáo dục',
    'Sức khỏe',
    'Du lịch',
    'Ẩm thực',
    'Thể thao',
    'Nghệ thuật',
    'Khoa học'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiClient.setContext(context);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn ảnh: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chụp ảnh: $e';
      });
    }
  }

  Future<void> _submitBlog() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn ảnh đại diện cho bài viết';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      // Phân tích tags
      final tags = _tagsController.text.isNotEmpty
          ? _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()
          : <String>[];

      final result = await _blogService.createBlog(
        title: _titleController.text,
        content: _contentController.text,
        category: _categoryController.text,
        tags: tags,
        imagePath: _selectedImage!.path,
      );

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        setState(() {
          _successMessage = 'Tạo bài viết thành công!';
        });
        
        // Hiển thị dialog thành công
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tạo bài viết: $e';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text(
              'Thành công',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bài viết của bạn đã được tạo thành công và đang chờ phê duyệt.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to blog list
            },
            child: const Text(
              'Xem bài viết',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _clearForm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Viết bài mới'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedImage = null;
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn ảnh đại diện',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Viết Bài Mới',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            onPressed: _clearForm,
            tooltip: 'Xóa tất cả',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingIndicator() : _buildForm(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tạo bài viết...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần chọn ảnh
            _buildImagePickerSection(),
            
            const SizedBox(height: 24),
            
            // Tiêu đề
            _buildTitleField(),
            
            const SizedBox(height: 20),
            
            // Danh mục
            _buildCategoryField(),
            
            const SizedBox(height: 20),
            
            // Tags
            _buildTagsField(),
            
            const SizedBox(height: 20),
            
            // Nội dung
            _buildContentField(),
            
            const SizedBox(height: 24),
            
            // Thông báo lỗi/thành công
            _buildMessages(),
            
            const SizedBox(height: 24),
            
            // Nút đăng bài
            _buildSubmitButton(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh đại diện *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chọn ảnh đẹp để thu hút người đọc',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedImage == null ? Colors.grey[300]! : Colors.blue,
                width: _selectedImage == null ? 1.5 : 2,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[50],
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'Thêm ảnh đại diện',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nhấn để chọn ảnh',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Tiêu đề bài viết *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        prefixIcon: const Icon(Icons.title_rounded, color: Colors.grey),
        hintText: 'Nhập tiêu đề hấp dẫn...',
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      maxLength: 100,
      style: const TextStyle(fontSize: 16),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập tiêu đề bài viết';
        }
        if (value.length < 10) {
          return 'Tiêu đề nên có ít nhất 10 ký tự';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      readOnly: true,
      onTap: () {
        _showCategorySelection();
      },
      decoration: InputDecoration(
        labelText: 'Danh mục *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        prefixIcon: const Icon(Icons.category_rounded, color: Colors.grey),
        hintText: 'Chọn danh mục phù hợp...',
        hintStyle: TextStyle(color: Colors.grey[500]),
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng chọn danh mục';
        }
        return null;
      },
    );
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn danh mục',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _commonCategories.length,
                itemBuilder: (context, index) {
                  final category = _commonCategories[index];
                  return ListTile(
                    leading: const Icon(Icons.category_rounded, color: Colors.blue),
                    title: Text(category),
                    onTap: () {
                      setState(() {
                        _categoryController.text = category;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsField() {
    return TextFormField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: 'Tags (tùy chọn)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        prefixIcon: const Icon(Icons.tag_rounded, color: Colors.grey),
        hintText: 'flutter, dart, mobile... (phân cách bằng dấu phẩy)',
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nội dung bài viết *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chia sẻ kiến thức và trải nghiệm của bạn',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            hintText: 'Viết nội dung bài viết của bạn ở đây...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            alignLabelWithHint: true,
          ),
          maxLines: 10,
          maxLength: 5000,
          style: const TextStyle(fontSize: 15, height: 1.5),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập nội dung bài viết';
            }
            if (value.length < 100) {
              return 'Nội dung nên có ít nhất 100 ký tự';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessages() {
    if (_errorMessage.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red[700], height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    if (_successMessage.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _successMessage,
                style: TextStyle(color: Colors.green[700], height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _submitBlog,
        icon: const Icon(Icons.publish_rounded, size: 22),
        label: const Text(
          'ĐĂNG BÀI VIẾT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}