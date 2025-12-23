// recruiter_screen/job_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/job_service.dart';
import '../services/company_service.dart';
import '../models/job_model.dart';

class JobFormDialog extends StatefulWidget {
  final JobModel? job;
  final VoidCallback? onSuccess;

  const JobFormDialog({
    Key? key,
    this.job,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<JobFormDialog> createState() => _JobFormDialogState();
}

class _JobFormDialogState extends State<JobFormDialog> {
  final JobService _jobService = JobService();
  final CompanyService _companyService = CompanyService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isLoadingCompanies = true;
  List<Map<String, dynamic>> _companyList = []; // Đơn giản chỉ cần Map
  String? _selectedCompanyId;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _experienceController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();

  // Dropdown values
  String _jobType = 'full_time';
  String _position = '1';
  String _category = 'IT';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    if (widget.job != null) {
      _populateFormData(widget.job!);
    }
  }

  Future<void> _loadCompanies() async {
    try {
      print('🔄 Loading companies...');
      
      final result = await _companyService.getRecruiterCompanies();
      
      if (result['success'] == true) {
        final dynamic companiesData = result['companies'] ?? [];
        
        if (companiesData is List) {
          final List<Map<String, dynamic>> companyList = [];
          
          for (var companyData in companiesData) {
            if (companyData is Map<String, dynamic>) {
              // Chỉ lấy id và name
              companyList.add({
                'id': companyData['_id']?.toString() ?? '',
                'name': companyData['name']?.toString() ?? 'Không tên',
              });
            }
          }
          
          setState(() {
            _companyList = companyList;
            if (_companyList.isNotEmpty) {
              _selectedCompanyId = _companyList.first['id'];
            }
          });
          print('✅ Loaded ${_companyList.length} companies');
        }
      } else {
        print('⚠️ Failed to load companies: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error loading companies: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCompanies = false);
      }
    }
  }

  void _populateFormData(JobModel job) {
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _locationController.text = job.location;
    _salaryController.text = job.salary.toString();
    _experienceController.text = job.experienceLevel.toString();
    
    if (job.requirements.isNotEmpty) {
      _requirementsController.text = job.requirements.join('\n');
    }
    
    if (job.benefits.isNotEmpty) {
      _benefitsController.text = job.benefits.join('\n');
    }
    
    _jobType = job.jobType;
    _position = job.position.toString();
    _category = job.category;
    _status = job.status;
    
    // Lấy companyId từ job
    _selectedCompanyId = job.companyId;
    print('📝 Populated companyId from job: $_selectedCompanyId');
  }

  Map<String, dynamic> _getFormData() {
    // Parse requirements and benefits
    final requirements = _requirementsController.text
        .split('\n')
        .map((req) => req.trim())
        .where((req) => req.isNotEmpty)
        .toList();
    
    final benefits = _benefitsController.text
        .split('\n')
        .map((benefit) => benefit.trim())
        .where((benefit) => benefit.isNotEmpty)
        .toList();

    // Convert numbers
    final salary = double.tryParse(_salaryController.text) ?? 0;
    final experienceLevel = int.tryParse(_experienceController.text) ?? 0;
    final position = int.tryParse(_position) ?? 1;

    // Tạo dữ liệu theo ĐÚNG format của React/API
    final jobData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'requirements': requirements,
      'salary': salary,
      'experienceLevel': experienceLevel,
      'benefits': benefits,
      'location': _locationController.text.trim(),
      'jobType': _jobType,
      'position': position,
      'category': _category,
      'status': _status,
      'company': _selectedCompanyId, // <- QUAN TRỌNG: string ID
    };

    // Debug
    print('📝 Job data for API:');
    print('   Type: ${widget.job == null ? 'CREATE' : 'UPDATE'}');
    print('   Company ID: $_selectedCompanyId');

    return jobData;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    // Kiểm tra companyId
    if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn công ty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = _getFormData();
      
      print('🚀 Submitting job data...');
      
      final result = widget.job == null
          ? await _jobService.createJob(formData)
          : await _jobService.updateJob(widget.job!.id, formData);

      if (result['success'] == true) {
        print('✅ Job created/updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.job == null
                ? 'Tạo công việc thành công!'
                : 'Cập nhật công việc thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
        widget.onSuccess?.call();
      } else {
        final error = result['error'] ?? 'Thao tác thất bại';
        print('❌ API returned error: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('❌ Error in handleSubmit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Validation methods
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) return '$fieldName phải là số';
    if (numValue < 0) return '$fieldName không được âm';
    return null;
  }

  // UI Components
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: _inputBorder,
            enabledBorder: _inputBorder,
            focusedBorder: _focusedBorder,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(_getDisplayText(option, label)),
            );
          }).toList(),
          decoration: InputDecoration(
            border: _inputBorder,
            enabledBorder: _inputBorder,
            focusedBorder: _focusedBorder,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDropdown() {
    if (_isLoadingCompanies) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Công ty*', style: _labelStyle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Đang tải danh sách công ty...'),
              ],
            ),
          ),
        ],
      );
    }

    if (_companyList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Công ty*', style: _labelStyle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.orange.shade50,
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn chưa có công ty nào. Vui lòng tạo công ty trước!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Công ty*', style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCompanyId,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn công ty';
            }
            return null;
          },
          onChanged: (value) {
            setState(() => _selectedCompanyId = value);
          },
          items: _companyList.map((company) {
            return DropdownMenuItem<String>(
              value: company['id'],
              child: Text(
                company['name'],
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            border: _inputBorder,
            enabledBorder: _inputBorder,
            focusedBorder: _focusedBorder,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getDisplayText(String value, String field) {
    switch (field) {
      case 'Loại công việc':
        switch (value) {
          case 'full_time': return 'Toàn thời gian';
          case 'part_time': return 'Bán thời gian';
          case 'contract': return 'Hợp đồng';
          case 'internship': return 'Thực tập';
          case 'freelance': return 'Freelance';
          case 'remote': return 'Làm việc từ xa';
          default: return value;
        }
      case 'Vị trí':
        switch (value) {
          case '1': return 'Nhân viên';
          case '2': return 'Chuyên viên';
          case '3': return 'Trưởng nhóm';
          case '4': return 'Quản lý';
          case '5': return 'Trưởng phòng';
          case '6': return 'Giám đốc';
          default: return value;
        }
      case 'Danh mục':
        return value;
      case 'Trạng thái':
        switch (value) {
          case 'active': return 'Hoạt động';
          case 'draft': return 'Bản nháp';
          case 'closed': return 'Đã đóng';
          default: return value;
        }
      default:
        return value;
    }
  }

  // Styles
  final _labelStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  final _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.blue),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.job == null ? 'Tạo công việc mới' : 'Chỉnh sửa công việc',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Company Dropdown
                _buildCompanyDropdown(),
                const SizedBox(height: 12),
                
                // Title
                _buildTextField(
                  controller: _titleController,
                  label: 'Tiêu đề công việc*',
                  hintText: 'Nhập tiêu đề công việc',
                  validator: (value) => _validateRequired(value, 'tiêu đề công việc'),
                ),
                const SizedBox(height: 12),
                
                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Mô tả công việc*',
                  hintText: 'Nhập mô tả chi tiết công việc',
                  validator: (value) => _validateRequired(value, 'mô tả công việc'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                // Location
                _buildTextField(
                  controller: _locationController,
                  label: 'Địa điểm làm việc*',
                  hintText: 'Nhập địa điểm làm việc',
                  validator: (value) => _validateRequired(value, 'địa điểm làm việc'),
                ),
                const SizedBox(height: 12),
                
                // Salary & Experience
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _salaryController,
                        label: 'Lương (VNĐ)*',
                        hintText: 'VD: 10000000',
                        validator: (value) => _validateNumber(value, 'mức lương'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _experienceController,
                        label: 'Kinh nghiệm (năm)*',
                        hintText: 'VD: 2',
                        validator: (value) => _validateNumber(value, 'kinh nghiệm'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Job Type
                _buildDropdown(
                  label: 'Loại công việc',
                  value: _jobType,
                  options: const ['full_time', 'part_time', 'contract', 'internship', 'freelance', 'remote'],
                  onChanged: (value) => value != null ? setState(() => _jobType = value) : null,
                ),
                const SizedBox(height: 12),
                
                // Position
                _buildDropdown(
                  label: 'Vị trí',
                  value: _position,
                  options: const ['1', '2', '3', '4', '5', '6'],
                  onChanged: (value) => value != null ? setState(() => _position = value) : null,
                ),
                const SizedBox(height: 12),
                
                // Category
                _buildDropdown(
                  label: 'Danh mục',
                  value: _category,
                  options: const ['IT', 'Marketing', 'Sales', 'Design', 'Finance', 'HR', 'Operations', 'Other'],
                  onChanged: (value) => value != null ? setState(() => _category = value) : null,
                ),
                const SizedBox(height: 12),
                
                // Status (chỉ hiển thị khi edit)
                if (widget.job != null) ...[
                  _buildDropdown(
                    label: 'Trạng thái',
                    value: _status,
                    options: const ['active', 'draft', 'closed'],
                    onChanged: (value) => value != null ? setState(() => _status = value) : null,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Requirements
                _buildTextField(
                  controller: _requirementsController,
                  label: 'Yêu cầu công việc*',
                  hintText: 'Mỗi dòng là 1 yêu cầu',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập ít nhất một yêu cầu';
                    final lines = value.split('\n').where((line) => line.trim().isNotEmpty);
                    if (lines.isEmpty) return 'Vui lòng nhập ít nhất một yêu cầu';
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                // Benefits
                _buildTextField(
                  controller: _benefitsController,
                  label: 'Quyền lợi (không bắt buộc)',
                  hintText: 'Mỗi dòng là 1 quyền lợi',
                  validator: (value) => null,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            widget.job == null ? 'Tạo công việc' : 'Cập nhật',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _experienceController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }
}