// screens/profile/applicant_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../models/user_model.dart';
import '../../models/application_model.dart';
import '../../services/application_service.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final String userId;
  final bool isRecruiterView;
  final Map<String, dynamic>? applicantData;
  const ApplicantProfileScreen({
    Key? key,
    required this.userId,
    this.isRecruiterView = false,
    this.applicantData,
  }) : super(key: key);
  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  final ApplicationService _applicationService = ApplicationService();
  
  UserModel? _applicant;
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  bool _isLoadingApplications = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplicantData();
  }

// Trong _loadApplicantData() thêm debug

Future<void> _loadApplicantData() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ✅ Recruiter view → dùng data truyền sang
    if (widget.isRecruiterView && widget.applicantData != null) {
      _applicant = UserModel.fromJson(widget.applicantData!);
      await _loadApplications(); // vẫn load danh sách job đã apply
      return;
    }

    // ❌ Không cho recruiter gọi API user nữa
    throw Exception('Không thể tải hồ sơ ứng viên');
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  Future<void> _loadApplications() async {
    try {
      setState(() {
        _isLoadingApplications = true;
      });

      if (widget.isRecruiterView) {
        final result = await _applicationService.getRecruiterCandidatesWithDebug();
        if (result['success'] == true) {
          final applicationsData = result['applications'] ?? result['candidates'] ?? [];
          final allApplications = applicationsData
              .map<ApplicationModel>((json) => ApplicationModel.fromJson(json))
              .toList();
          
          setState(() {
            _applications = allApplications
                .where((app) => app.applicantId == widget.userId)
                .toList();
          });
        }
      }
    } catch (e) {
      print('❌ Error loading applications: $e');
    } finally {
      setState(() {
        _isLoadingApplications = false;
      });
    }
  }

  Widget _buildInfoCard(String title, String? value, {IconData? icon}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Chưa cập nhật',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Thông tin liên hệ', icon: Iconsax.info_circle),
        
        _buildInfoCard(
          'Email',
          _applicant?.email,
          icon: Iconsax.sms,
        ),
        
        _buildInfoCard(
          'Số điện thoại',
          _applicant?.phoneNumber != null ? '0${_applicant?.phoneNumber}' : null,
          icon: Iconsax.call,
        ),
        
        if (_applicant?.role != null)
          _buildInfoCard(
            'Vai trò',
            _applicant!.role,
            icon: Iconsax.profile_2user,
          ),
      ],
    );
  }

  Widget _buildBioSection() {
    final bio = _applicant?.profile?.bio;
    
    if (bio == null || bio.isEmpty) {
      return Container();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Giới thiệu bản thân', icon: Iconsax.user),
            const SizedBox(height: 12),
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsInfo() {
    final skills = _applicant?.profile?.skills;
    
    if (skills == null || skills.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Kỹ năng', icon: Iconsax.cpu),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Chip(
              label: Text(
                skill,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.blue.withOpacity(0.1),
              side: BorderSide(color: Colors.blue.withOpacity(0.3)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResumeSection() {
    final resume = _applicant?.profile?.resume;
    
    if (resume == null || resume.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('CV/Resume', icon: Iconsax.document),
              const SizedBox(height: 8),
              Text(
                'Ứng viên chưa tải lên CV',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('CV/Resume', icon: Iconsax.document),
            const SizedBox(height: 12),
            if (_applicant?.profile?.resumeOriginalName != null)
              Column(
                children: [
                  Text(
                    'Tên file: ${_applicant!.profile!.resumeOriginalName!}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ElevatedButton(
              onPressed: () async {
                if (await canLaunchUrlString(resume)) {
                  await launchUrlString(resume);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.document_download, size: 16),
                  SizedBox(width: 8),
                  Text('Xem/Tải CV'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsInfo() {
    if (!widget.isRecruiterView || _applications.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Vị trí đã ứng tuyển', icon: Iconsax.note),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _applications.length,
          itemBuilder: (context, index) {
            final app = _applications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Công ty: ${app.companyName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trạng thái:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            _getStatusBadge(app.status),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Ngày ứng tuyển:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đang xem xét',
            style: TextStyle(
              fontSize: 12,
              color: Colors.yellow.shade800,
            ),
          ),
        );
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đã chấp nhận',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade800,
            ),
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Đã từ chối',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade800,
            ),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải thông tin ứng viên...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.profile_remove,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông tin',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplicantData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 16),
                  SizedBox(width: 8),
                  Text('Thử lại'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profilePhoto = _applicant?.profile?.profilePhoto;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                ? NetworkImage(profilePhoto)
                : null,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: profilePhoto == null || profilePhoto.isEmpty
                ? Text(
                    _applicant?.fullname.isNotEmpty == true
                        ? _applicant!.fullname[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            _applicant?.fullname ?? 'Ứng viên',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Email
          if (_applicant?.email != null) ...[
            const SizedBox(height: 8),
            Text(
              _applicant!.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          // Contact buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_applicant?.email != null && _applicant!.email.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    final email = 'mailto:${_applicant!.email}';
                    if (await canLaunchUrlString(email)) {
                      await launchUrlString(email);
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.sms, color: Colors.white, size: 20),
                  ),
                ),
              
              if (_applicant?.phoneNumber != null && _applicant!.phoneNumber.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    final phone = 'tel:0${_applicant!.phoneNumber}';
                    if (await canLaunchUrlString(phone)) {
                      await launchUrlString(phone);
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.call, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ ứng viên'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildLoadingScreen(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ ứng viên'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildErrorScreen(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hồ sơ ứng viên'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadApplicantData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadApplicantData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile info
              _buildProfileHeader(),
              
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Contact info
                    _buildContactInfo(),
                    
                    // Bio section
                    _buildBioSection(),
                    
                    // Skills
                    _buildSkillsInfo(),
                    
                    // Resume section
                    _buildResumeSection(),
                    
                    // Applications info (only for recruiter)
                    if (_isLoadingApplications)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.blue),
                        ),
                      )
                    else
                      _buildApplicationsInfo(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}