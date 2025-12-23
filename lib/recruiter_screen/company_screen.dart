// recruiter_screen/company_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import '../core/secure_storage.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({Key? key}) : super(key: key);

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  
  List<Company> _companies = [];
  bool _isLoading = true;
  bool _isDialogOpen = false;
  Company? _selectedCompany;
  
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _taxCodeController = TextEditingController();
  
  File? _logoFile;
  File? _businessLicenseFile;
  String? _logoUrl;
  String? _businessLicenseUrl;

  // Sidebar variables
  User? _user;
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      name: "Dashboard",
      route: "/recruiter",
      icon: Iconsax.home_2,
    ),
    NavigationItem(
      name: "Quản lý công ty",
      route: "/recruiter/company",
      icon: Iconsax.building_4,
    ),
    NavigationItem(
      name: "Quản lý việc làm",
      route: "/recruiter/jobs",
      icon: Iconsax.briefcase,
    ),
    NavigationItem(
      name: "Quản lý ứng viên",
      route: "/recruiter/candidates",
      icon: Iconsax.people,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  void _checkAuthAndLoadData() async {
    final userJson = await _secureStorage.getUserData();
    
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        if (userData['role'] != "recruiter") {
          if (mounted) {
            context.go('/login');
          }
          return;
        }
        setState(() {
          _user = User.fromJson(userData);
        });
        await _loadCompanies();
      } catch (e) {
        print('Error parsing user data: $e');
        if (mounted) {
          context.go('/login');
        }
      }
    } else {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _loadCompanies() async {
    try {
      print('🔄 Loading companies...');
      setState(() {
        _isLoading = true;
      });
      
      final result = await _companyService.getRecruiterCompanies();
      
      if (result['success'] == true) {
        final List<dynamic> companiesJson = result['companies'] ?? [];
        setState(() {
          _companies = companiesJson
              .map((json) => Company.fromJson(json))
              .toList();
        });
        print('✅ Loaded ${_companies.length} companies');
      } else {
        print('⚠️ Failed to load companies: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải danh sách công ty: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading companies: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách công ty: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isLogo) {
            _logoFile = File(pickedFile.path);
          } else {
            _businessLicenseFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAddEditDialog({Company? company}) async {
    // Reset form
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _addressController.clear();
    _websiteController.clear();
    _taxCodeController.clear();
    _logoFile = null;
    _businessLicenseFile = null;
    _logoUrl = null;
    _businessLicenseUrl = null;
    
    if (company != null) {
      // Edit mode
      _selectedCompany = company;
      _nameController.text = company.name;
      _descriptionController.text = company.description ?? '';
      _locationController.text = company.location ?? '';
      _addressController.text = company.address ?? '';
      _websiteController.text = company.website ?? '';
      _taxCodeController.text = company.taxCode ?? '';
      _logoUrl = company.logo;
      _businessLicenseUrl = company.businessLicense;
    } else {
      // Add mode
      _selectedCompany = null;
    }
    
    setState(() {
      _isDialogOpen = true;
    });
  }

  Future<void> _handleSaveCompany() async {
    // Validate required fields
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên công ty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_taxCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã số thuế'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Create FormData
      final Map<String, dynamic> formData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'address': _addressController.text,
        'website': _websiteController.text,
        'taxCode': _taxCodeController.text,
      };

      if (_logoFile != null) {
        formData['logo'] = _logoFile;
      }
      
      if (_businessLicenseFile != null) {
        formData['businessLicense'] = _businessLicenseFile;
      }

      if (_selectedCompany != null) {
        // Edit existing company
        print('🔄 Updating company: ${_selectedCompany!.id}');
        final result = await _companyService.updateCompany(
          companyId: _selectedCompany!.id,
          companyData: formData,
        );
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật công ty thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadCompanies();
        } else {
          throw Exception(result['error'] ?? 'Cập nhật thất bại');
        }
      } else {
        // Create new company
        print('🔄 Creating new company');
        final result = await _companyService.createCompany(formData);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm công ty thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadCompanies();
        } else {
          throw Exception(result['error'] ?? 'Tạo mới thất bại');
        }
      }
      
      // Close dialog
      setState(() {
        _isDialogOpen = false;
        _selectedCompany = null;
      });
      
    } catch (e) {
      print('❌ Error saving company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteCompany(String companyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa công ty này?\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _companyService.deleteCompany(companyId);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa công ty thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCompanies();
      } else {
        throw Exception(result['error'] ?? 'Xóa thất bại');
      }
    } catch (e) {
      print('❌ Error deleting company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          Text(
            'Quản lý công ty',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            _user?.fullname?.split(' ').last ?? 'Nhà tuyển dụng',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh, color: Colors.blue),
          onPressed: _loadCompanies,
        ),
      ],
    );
  }

  Widget _buildMobileSidebar() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Profile section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _user?.profile?.profilePhoto?.url != null
                        ? NetworkImage(_user!.profile!.profilePhoto!.url)
                        : null,
                    child: _user?.profile?.profilePhoto?.url == null
                        ? Text(
                            _user?.fullname?.isNotEmpty == true
                                ? _user!.fullname![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    backgroundColor: Colors.blue.shade100,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullname ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    final currentRoute = GoRouterState.of(context).uri.toString();
                    final isActive = currentRoute == item.route;
                    
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isActive ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.blue : Colors.black,
                        ),
                      ),
                      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                    );
                  },
                ),
              ),
            ),

            // Logout button
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
                onTap: () {
                  Navigator.pop(context);
                  _authService.logout(context);
                },
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
            // Profile section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _user?.profile?.profilePhoto?.url != null
                        ? NetworkImage(_user!.profile!.profilePhoto!.url)
                        : null,
                    child: _user?.profile?.profilePhoto?.url == null
                        ? Text(
                            _user?.fullname?.isNotEmpty == true
                                ? _user!.fullname![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    backgroundColor: Colors.blue.shade100,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullname ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    final currentRoute = GoRouterState.of(context).uri.toString();
                    final isActive = currentRoute == item.route;
                    
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        size: 20,
                        color: isActive ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.blue : Colors.black,
                        ),
                      ),
                      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => context.go(item.route),
                    );
                  },
                ),
              ),
            ),

            // Logout button
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

  Widget _buildCompanyList() {
    if (_companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.building,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có công ty nào được thêm',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openAddEditDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.add, size: 16),
                  SizedBox(width: 8),
                  Text('Thêm công ty mới'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    
    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _companies.length,
        itemBuilder: (context, index) {
          final company = _companies[index];
          return _buildCompanyCard(company);
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 16,
        columns: const [
          DataColumn(label: Text('Công ty'), numeric: false),
          DataColumn(label: Text('Trụ sở'), numeric: false),
          DataColumn(label: Text('Địa điểm'), numeric: false),
          DataColumn(label: Text('Website'), numeric: false),
          DataColumn(label: Text('Mã số thuế'), numeric: false),
          DataColumn(label: Text('Giấy phép KD'), numeric: false),
          DataColumn(label: Text('Ngày tạo'), numeric: false),
          DataColumn(label: Text('Ngày cập nhật'), numeric: false),
          DataColumn(label: Text('Thao tác'), numeric: false),
        ],
        rows: _companies.map((company) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: company.logo != null
                            ? NetworkImage(company.logo!)
                            : null,
                        child: company.logo == null
                            ? Text(
                                company.name.isNotEmpty
                                    ? company.name[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        backgroundColor: Colors.blue.shade100,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              company.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (company.description != null)
                              Text(
                                company.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    company.location ?? 'Chưa cập nhật',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    company.address ?? 'Chưa cập nhật địa điểm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                company.website != null && company.website!.isNotEmpty
                    ? SizedBox(
                        width: 150,
                        child: InkWell(
                          onTap: () {
                            // Mở website
                          },
                          child: Text(
                            company.website!,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    : const Text('Chưa có'),
              ),
              DataCell(
                SizedBox(
                  width: 120,
                  child: Text(
                    company.taxCode ?? 'Chưa cập nhật',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                company.businessLicense != null &&
                        company.businessLicense!.isNotEmpty
                    ? InkWell(
                        onTap: () {
                          // Xem giấy phép
                        },
                        child: const Text(
                          'Xem Giấy phép',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : const Text('Chưa có'),
              ),
              DataCell(
                Text(
                  DateFormat('dd/MM/yyyy').format(company.createdAt),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('dd/MM/yyyy').format(company.updatedAt),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.edit, size: 18),
                      color: Colors.blue,
                      onPressed: () => _openAddEditDialog(company: company),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, size: 18),
                      color: Colors.red,
                      onPressed: () => _handleDeleteCompany(company.id),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company header with logo and name
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: company.logo != null
                      ? NetworkImage(company.logo!)
                      : null,
                  child: company.logo == null
                      ? Text(
                          company.name.isNotEmpty
                              ? company.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (company.description != null)
                        Text(
                          company.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Company details
            _buildCompanyDetailRow('📍 Trụ sở', company.location ?? 'Chưa cập nhật'),
            _buildCompanyDetailRow('🏠 Địa chỉ', company.address ?? 'Chưa cập nhật'),
            _buildCompanyDetailRow('🌐 Website', company.website ?? 'Chưa có'),
            _buildCompanyDetailRow('📋 Mã số thuế', company.taxCode ?? 'Chưa cập nhật'),
            
            // Dates and actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tạo: ${DateFormat('dd/MM/yyyy').format(company.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.edit, size: 18),
                      color: Colors.blue,
                      onPressed: () => _openAddEditDialog(company: company),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, size: 18),
                      color: Colors.red,
                      onPressed: () => _handleDeleteCompany(company.id),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyFormDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _selectedCompany != null ? Iconsax.edit : Iconsax.add,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            _selectedCompany != null 
                ? 'Chỉnh sửa công ty'
                : 'Thêm công ty mới',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo upload
              const Text(
                'Logo công ty',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _logoFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _logoFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _logoUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.camera, size: 24, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Tải lên', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              // Form fields
              _buildFormField('Tên công ty *', _nameController),
              const SizedBox(height: 12),
              _buildFormField('Mô tả', _descriptionController, maxLines: 3),
              const SizedBox(height: 12),
              _buildFormField('Trụ sở chính', _locationController),
              const SizedBox(height: 12),
              _buildFormField('Địa chỉ chi tiết', _addressController),
              const SizedBox(height: 12),
              _buildFormField('Website', _websiteController),
              const SizedBox(height: 12),
              _buildFormField('Mã số thuế *', _taxCodeController),
              const SizedBox(height: 16),

              // Business license upload
              const Text(
                'Giấy phép kinh doanh',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _businessLicenseFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _businessLicenseFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _businessLicenseUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _businessLicenseUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.document_upload, size: 24, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Tải lên Giấy phép kinh doanh', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _isDialogOpen = false;
              _selectedCompany = null;
            });
          },
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _handleSaveCompany,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: Text(_selectedCompany != null ? 'Cập nhật' : 'Thêm mới'),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 12 : 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.building,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              ElevatedButton(
                onPressed: () => _openAddEditDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.add, size: 18),
                    SizedBox(width: 8),
                    Text('Thêm công ty mới'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Company List
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCompanyList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải danh sách công ty...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        drawer: _buildMobileSidebar(),
        body: Stack(
          children: [
            _buildContent(),
            
            // Add/Edit Dialog
            if (_isDialogOpen)
              ModalBarrier(
                color: Colors.black.withOpacity(0.5),
                dismissible: true,
              ),
            if (_isDialogOpen)
              Center(
                child: _buildCompanyFormDialog(),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          _buildDesktopSidebar(),
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                
                // Add/Edit Dialog
                if (_isDialogOpen)
                  ModalBarrier(
                    color: Colors.black.withOpacity(0.5),
                    dismissible: true,
                  ),
                if (_isDialogOpen)
                  Center(
                    child: _buildCompanyFormDialog(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }
}

// Model Classes
class Company {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? address;
  final String? website;
  final String? taxCode;
  final String? logo;
  final String? businessLicense;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.address,
    this.website,
    this.taxCode,
    this.logo,
    this.businessLicense,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      address: json['address'],
      website: json['website'],
      taxCode: json['taxCode'],
      logo: json['logo'],
      businessLicense: json['businessLicense'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

// User Model
class User {
  final String? fullname;
  final String? email;
  final String role;
  final Profile? profile;

  User({
    this.fullname,
    this.email,
    required this.role,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullname: json['fullname'],
      email: json['email'],
      role: json['role'],
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}

class Profile {
  final ProfilePhoto? profilePhoto;

  Profile({this.profilePhoto});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      profilePhoto: json['profilePhoto'] != null 
          ? ProfilePhoto.fromJson(json['profilePhoto'])
          : null,
    );
  }
}

class ProfilePhoto {
  final String url;

  ProfilePhoto({required this.url});

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(url: json['url']);
  }
}

class NavigationItem {
  final String name;
  final String route;
  final IconData icon;

  NavigationItem({
    required this.name,
    required this.route,
    required this.icon,
  });
}