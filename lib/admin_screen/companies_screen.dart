// screens/admin_screen/companies_screen.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:viejob_app/services/admin_service.dart';
import 'package:viejob_app/services/auth_service.dart';
import 'package:viejob_app/core/secure_storage.dart';
import 'package:viejob_app/config/api_config.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({Key? key}) : super(key: key);

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  bool _isMobile = false;
  Map<String, dynamic> _user = {};
  List<dynamic> _companies = [];
  int _totalItems = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Form variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _taxCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noeController = TextEditingController();
  final TextEditingController _yoeController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  
  File? _logoFile;
  File? _businessLicenseFile;
  String? _logoUrl;
  String? _businessLicenseUrl;
  
  bool _isEditing = false;
  String? _editingCompanyId;

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
      
      await _loadCompanies();
      
    } catch (e) {
      print('Error checking auth: $e');
      context.go('/login');
    }
  }

Future<void> _loadCompanies({String? search}) async {
  setState(() {
    _isLoading = true;
  });

  try {
    final result = await _adminService.getAllCompanies(search: search);

    if (!mounted) return;

    if (result['success'] == true) {
      final companies = result['companies'] ?? [];

      setState(() {
        _companies = companies;

        // 🔥 FIX Ở ĐÂY
        if (search != null && search.isNotEmpty) {
          _totalItems = companies.length;
        } else {
          _totalItems = result['total'] ??
              result['count'] ??
              companies.length;
        }

        _isLoading = false;
      });
    } else {
      _isLoading = false;
      _showError('Không thể tải danh sách công ty');
    }
  } catch (e) {
    _isLoading = false;
    _showError('Lỗi: $e');
  }
}

  Future<void> _deleteCompany(String companyId, String companyName) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công ty "$companyName"?'),
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
      final result = await _adminService.deleteCompany(companyId);
      
      if (result['success'] == true) {
        _showSuccess('Đã xóa công ty thành công');
        await _loadCompanies(search: _searchController.text);
      } else {
        _showError(result['error'] ?? 'Không thể xóa công ty');
      }
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isLogo) {
            _logoFile = File(image.path);
            _logoUrl = null;
          } else {
            _businessLicenseFile = File(image.path);
            _businessLicenseUrl = null;
          }
        });
      }
    } catch (e) {
      _showError('Lỗi khi chọn ảnh: $e');
    }
  }

  void _openCreateCompanyDialog() {
    _resetForm();
    _showCompanyFormDialog();
  }

  void _openEditCompanyDialog(Map<String, dynamic> company) {
    _resetForm();
    _isEditing = true;
    _editingCompanyId = company['_id'];
    
    _nameController.text = company['name'] ?? '';
    _descriptionController.text = company['description'] ?? '';
    _websiteController.text = company['website'] ?? '';
    _locationController.text = company['location'] ?? '';
    _taxCodeController.text = company['taxCode'] ?? '';
    _addressController.text = company['address'] ?? '';
    _noeController.text = company['noe']?.toString() ?? '';
    _yoeController.text = company['yoe']?.toString() ?? '';
    _fieldController.text = company['field'] ?? '';
    
    _logoUrl = company['logo'];
    _businessLicenseUrl = company['businessLicense'];
    
    _showCompanyFormDialog();
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _websiteController.clear();
    _locationController.clear();
    _taxCodeController.clear();
    _addressController.clear();
    _noeController.clear();
    _yoeController.clear();
    _fieldController.clear();
    
    _logoFile = null;
    _businessLicenseFile = null;
    _logoUrl = null;
    _businessLicenseUrl = null;
    
    _isEditing = false;
    _editingCompanyId = null;
  }

  void _showCompanyFormDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isEditing ? 'Chỉnh sửa công ty' : 'Tạo công ty mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(
                  'Logo công ty',
                  _logoFile,
                  _logoUrl,
                  true,
                ),
                const SizedBox(height: 16),
                _buildImagePicker(
                  'Giấy phép kinh doanh',
                  _businessLicenseFile,
                  _businessLicenseUrl,
                  false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công ty *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên công ty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Địa điểm *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa điểm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã số thuế *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã số thuế';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ chi tiết',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _noeController,
                        decoration: const InputDecoration(
                          labelText: 'Số nhân viên',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yoeController,
                        decoration: const InputDecoration(
                          labelText: 'Năm thành lập',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fieldController,
                  decoration: const InputDecoration(
                    labelText: 'Lĩnh vực hoạt động',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty || 
                    _locationController.text.isEmpty || 
                    _taxCodeController.text.isEmpty) {
                  _showError('Vui lòng điền đầy đủ thông tin bắt buộc');
                  return;
                }
                
                await _saveCompany();
                if (mounted) {
                  Navigator.pop(context);
                  _resetForm();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePicker(
    String label,
    File? file,
    String? url,
    bool isLogo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: file != null || url != null
              ? Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: file != null
                              ? Image.file(file, fit: BoxFit.cover)
                              : Image.network(url!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.edit, size: 16, color: Colors.black),
                        ),
                        onPressed: () => _pickImage(isLogo),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: TextButton.icon(
                    onPressed: () => _pickImage(isLogo),
                    icon: const Icon(Iconsax.image),
                    label: const Text('Chọn ảnh'),
                  ),
                ),
        ),
      ],
    );
  }

Future<void> _saveCompany() async {
  try {
    if (_nameController.text.isEmpty || 
        _locationController.text.isEmpty || 
        _taxCodeController.text.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin bắt buộc');
      return;
    }
    
    final Map<String, dynamic> companyData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'website': _websiteController.text.trim(),
      'location': _locationController.text.trim(),
      'taxCode': _taxCodeController.text.trim(),
      'address': _addressController.text.trim(),
      'field': _fieldController.text.trim(),
    };
    
    // Xử lý các trường số - đảm bảo chỉ gán khi parse thành công
    if (_noeController.text.isNotEmpty) {
      final noe = int.tryParse(_noeController.text);
      if (noe != null) {
        companyData['noe'] = noe;
      }
    }
    
    if (_yoeController.text.isNotEmpty) {
      final yoe = int.tryParse(_yoeController.text);
      if (yoe != null) {
        companyData['yoe'] = yoe;
      }
    }
    
    if (_isEditing && _editingCompanyId != null) {
      await _updateCompany(_editingCompanyId!, companyData);
    } else {
      await _createCompany(companyData);
    }
  } catch (e) {
    _showError('Lỗi khi lưu công ty: $e');
  }
}

Future<void> _createCompany(Map<String, dynamic> companyData) async {
  try {
    final token = await _secureStorage.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminCreateCompany}');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    
    // Add text fields - ĐẢM BẢO TẤT CẢ ĐỀU LÀ STRING
    companyData.forEach((key, value) {
      if (value != null) {
        // Chuyển tất cả giá trị thành string
        if (value is int) {
          request.fields[key] = value.toString();
        } else {
          request.fields[key] = value;
        }
      }
    });
    
    // Add logo file
    if (_logoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('logo', _logoFile!.path),
      );
    }
    
    // Add business license file
    if (_businessLicenseFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('businessLicense', _businessLicenseFile!.path),
      );
    }
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);
    
    if (response.statusCode == 200 && data['success'] == true) {
      _showSuccess('Tạo công ty thành công');
      await _loadCompanies(search: _searchController.text);
    } else {
      _showError(data['message'] ?? 'Tạo công ty thất bại');
    }
  } catch (e) {
    _showError('Lỗi khi tạo công ty: $e');
  }
}

Future<void> _updateCompany(String companyId, Map<String, dynamic> companyData) async {
  try {
    final token = await _secureStorage.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminUpdateCompany}/$companyId');
    
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    
    // Add text fields - ĐẢM BẢO TẤT CẢ ĐỀU LÀ STRING
    companyData.forEach((key, value) {
      if (value != null) {
        // Chuyển tất cả giá trị thành string
        if (value is int) {
          request.fields[key] = value.toString();
        } else {
          request.fields[key] = value;
        }
      }
    });
    
    // Add logo file (nếu có file mới)
    if (_logoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('logo', _logoFile!.path),
      );
    }
    
    // Add business license file (nếu có file mới)
    if (_businessLicenseFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('businessLicense', _businessLicenseFile!.path),
      );
    }
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);
    
    if (response.statusCode == 200 && data['success'] == true) {
      _showSuccess('Cập nhật công ty thành công');
      await _loadCompanies(search: _searchController.text);
    } else {
      _showError(data['message'] ?? 'Cập nhật công ty thất bại');
    }
  } catch (e) {
    _showError('Lỗi khi cập nhật công ty: $e');
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

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: company['logo'] != null && company['logo'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        company['logo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Iconsax.building_4,
                            size: 32,
                            color: Colors.blue.shade300,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Iconsax.building_4,
                      size: 32,
                      color: Colors.blue.shade300,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company['name'] ?? 'Không có tên',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (company['field'] != null && company['field'].isNotEmpty)
                    Text(
                      company['field'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  if (company['location'] != null && company['location'].isNotEmpty)
                    Row(
                      children: [
                        Icon(Iconsax.location, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            company['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (company['website'] != null && company['website'].isNotEmpty)
                    Row(
                      children: [
                        Icon(Iconsax.global, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            company['website'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (company['taxCode'] != null && company['taxCode'].isNotEmpty)
                    Row(
                      children: [
                        Icon(Iconsax.document_text, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'MST: ${company['taxCode']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Iconsax.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Iconsax.trash, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditCompanyDialog(company);
                } else if (value == 'delete') {
                  _deleteCompany(company['_id'], company['name'] ?? 'công ty');
                }
              },
            ),
          ],
        ),
      ),
    );
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
                      'Đang tải danh sách công ty...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_companies.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.building_4,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có công ty nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _openCreateCompanyDialog,
                      child: const Text('Thêm công ty đầu tiên'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadCompanies(),
                child: ListView.builder(
                  itemCount: _companies.length,
                  itemBuilder: (context, index) => _buildCompanyCard(_companies[index]),
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
        children: [
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
              title: const Text(
                'Quản lý công ty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
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
            'Quản lý công ty',
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
                      _user['fullname']?.isNotEmpty == true
                          ? _user['fullname'][0].toUpperCase()
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
                          _user['fullname'] ?? 'Admin',
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
                      _user['fullname']?.isNotEmpty == true
                          ? _user['fullname'][0].toUpperCase()
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
                          _user['fullname'] ?? 'Admin',
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }
}