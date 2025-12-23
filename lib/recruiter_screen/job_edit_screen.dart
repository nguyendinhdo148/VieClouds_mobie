// recruiter_screen/job_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

class JobEditScreen extends StatefulWidget {
  final JobModel job;
  final VoidCallback? onSuccess;

  const JobEditScreen({
    Key? key,
    required this.job,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends State<JobEditScreen> {
  final JobService _jobService = JobService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
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
    _populateFormData(widget.job);
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
    _selectedCompanyId = job.companyId;
  }

  Map<String, dynamic> _getFormData() {
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

    final salary = double.tryParse(_salaryController.text) ?? 0;
    final experienceLevel = int.tryParse(_experienceController.text) ?? 0;
    final position = int.tryParse(_position) ?? 1;

    return {
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
      'company': _selectedCompanyId,
    };
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final formData = _getFormData();
      
      print('🚀 Updating job: ${widget.job.id}');
      
      final result = await _jobService.updateJob(widget.job.id, formData);

      if (result['success'] == true) {
        print('✅ Job updated successfully');
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật công việc thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Đóng màn hình và gọi callback
        Navigator.pop(context);
        widget.onSuccess?.call();
      } else {
        throw Exception(result['error'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      print('❌ Error updating job: $e');
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa công việc',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.save_2, color: Colors.blue),
            onPressed: _isLoading ? null : _handleSubmit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildTextField(
                controller: _titleController,
                label: 'Tiêu đề công việc*',
                hintText: 'Nhập tiêu đề công việc',
                validator: (value) => _validateRequired(value, 'tiêu đề công việc'),
              ),
              const SizedBox(height: 16),
              
              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả công việc*',
                hintText: 'Nhập mô tả chi tiết công việc',
                validator: (value) => _validateRequired(value, 'mô tả công việc'),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              
              // Location
              _buildTextField(
                controller: _locationController,
                label: 'Địa điểm làm việc*',
                hintText: 'Nhập địa điểm làm việc',
                validator: (value) => _validateRequired(value, 'địa điểm làm việc'),
              ),
              const SizedBox(height: 16),
              
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
              const SizedBox(height: 16),
              
              // Job Type
              _buildDropdown(
                label: 'Loại công việc',
                value: _jobType,
                options: const ['full_time', 'part_time', 'contract', 'internship', 'freelance', 'remote'],
                onChanged: (value) => value != null ? setState(() => _jobType = value) : null,
              ),
              const SizedBox(height: 16),
              
              // Position
              _buildDropdown(
                label: 'Vị trí',
                value: _position,
                options: const ['1', '2', '3', '4', '5', '6'],
                onChanged: (value) => value != null ? setState(() => _position = value) : null,
              ),
              const SizedBox(height: 16),
              
              // Category
              _buildDropdown(
                label: 'Danh mục',
                value: _category,
                options: const ['IT', 'Marketing', 'Sales', 'Design', 'Finance', 'HR', 'Operations', 'Other'],
                onChanged: (value) => value != null ? setState(() => _category = value) : null,
              ),
              const SizedBox(height: 16),
              
              // Status
              _buildDropdown(
                label: 'Trạng thái',
                value: _status,
                options: const ['active', 'draft', 'closed'],
                onChanged: (value) => value != null ? setState(() => _status = value) : null,
              ),
              const SizedBox(height: 16),
              
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
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              
              // Benefits
              _buildTextField(
                controller: _benefitsController,
                label: 'Quyền lợi (không bắt buộc)',
                hintText: 'Mỗi dòng là 1 quyền lợi',
                validator: (value) => null,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CẬP NHẬT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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