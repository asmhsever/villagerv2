import 'package:flutter/material.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/profile/profile_edit.dart';
import '../../../domains/law_domain.dart';

class LawProfilePage extends StatefulWidget {
  final int lawId;

  const LawProfilePage({
    super.key,
    required this.lawId,
  });

  @override
  State<LawProfilePage> createState() => _LawProfilePageState();
}

class _LawProfilePageState extends State<LawProfilePage> {
  LawModel? _lawModel;
  bool _isLoading = true;
  ProfileCompleteness? _completeness;
  Map<String, dynamic>? _activitySummary;

  @override
  void initState() {
    super.initState();
    _loadLawProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLawProfile() async {
    setState(() => _isLoading = true);

    try {
      // โหลดข้อมูลหลัก
      final law = await LawDomain.getById(widget.lawId);

      // โหลดสรุปกิจกรรม
      final activity = await LawDomain.getActivitySummary(widget.lawId);

      if (mounted) {
        setState(() {
          _lawModel = law;
          _completeness = law?.getProfileCompleteness();
          _activitySummary = activity;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LawProfileEditPage(lawId: widget.lawId),
      ),
    );

    // ถ้าแก้ไขสำเร็จ รีเฟรชข้อมูล
    if (result == true) {
      _loadLawProfile();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _lawModel != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lawModel == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
          : RefreshIndicator(
        onRefresh: _loadLawProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildProfileCompletenessCard(),
              const SizedBox(height: 20),
              _buildBasicInfoCard(),
              const SizedBox(height: 20),
              _buildActivitySummaryCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // รูปโปรไฟล์
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: _lawModel!.hasProfileImage
                  ? NetworkImage(_lawModel!.profileImageUrl!)
                  : null,
              child: !_lawModel!.hasProfileImage
                  ? Text(
                _lawModel!.initials,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 16),

            // ชื่อ-นามสกุล
            Text(
              _lawModel!.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ข้อมูลเพิ่มเติม
            Text(
              'อายุ ${_lawModel!.age ?? 'ไม่ระบุ'} ปี • ${_lawModel!.genderDisplay}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            // เวลาเข้าสู่ระบบล่าสุด
            Text(
              'เข้าสู่ระบบล่าสุด: ${_lawModel!.lastLoginDisplay}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletenessCard() {
    if (_completeness == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _completeness!.isComplete ? Icons.check_circle : Icons.info,
                  color: _completeness!.statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'ความสมบูรณ์ของโปรไฟล์',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: _completeness!.percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_completeness!.statusColor),
            ),
            const SizedBox(height: 8),

            Text(
              '${_completeness!.percentage}% (${_completeness!.completed}/${_completeness!.total})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _completeness!.statusColor,
              ),
            ),

            if (!_completeness!.isComplete) ...[
              const SizedBox(height: 12),
              Text(
                'ข้อมูลที่ยังไม่ครบ:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: _completeness!.missingFields
                    .map((field) => Chip(
                  label: Text(field),
                  backgroundColor: Colors.orange.shade100,
                ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _navigateToEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('แก้ไข'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow('ชื่อจริง', _lawModel!.firstName ?? 'ไม่ระบุ'),
            _buildInfoRow('นามสกุล', _lawModel!.lastName ?? 'ไม่ระบุ'),
            _buildInfoRow('เบอร์โทรศัพท์', _lawModel!.phone ?? 'ไม่ระบุ'),
            _buildInfoRow('ที่อยู่', _lawModel!.address ?? 'ไม่ระบุ'),
            _buildInfoRow('วันเกิด', _lawModel!.birthDateDisplay),
            _buildInfoRow('เพศ', _lawModel!.genderDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummaryCard() {
    if (_activitySummary == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สรุปกิจกรรม',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.article, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text('ประกาศทั้งหมด: ${_activitySummary!['total_notions'] ?? 0} รายการ'),
              ],
            ),

            if (_activitySummary!['recent_notions'] != null &&
                (_activitySummary!['recent_notions'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'ประกาศล่าสุด:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...((_activitySummary!['recent_notions'] as List).take(3)).map(
                    (notion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 8),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notion['header'] ?? 'ไม่มีหัวเรื่อง',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไขโปรไฟล์'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadLawProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('รีเฟรชข้อมูล'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}