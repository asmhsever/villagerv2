// lib/pages/law/complaint/complaint_management_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:intl/intl.dart';

class LawComplaintManagementPage extends StatefulWidget {
  const LawComplaintManagementPage({super.key});

  @override
  State<LawComplaintManagementPage> createState() => _LawComplaintManagementPageState();
}

class _LawComplaintManagementPageState extends State<LawComplaintManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LawModel? _currentLaw;
  String _filterType = 'all';
  int _filterLevel = 0;
  Map<int, String> _houseNumbers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentUser();
    _loadHouseNumbers();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      setState(() => _currentLaw = user);
    }
  }

  Future<void> _loadHouseNumbers() async {
    if (_currentLaw == null) return;

    final houses = await HouseDomain.getAllInVillage(
      villageId: _currentLaw!.villageId,
    );

    setState(() {
      _houseNumbers = {
        for (var house in houses)
          house.houseId: house.houseNumber ?? 'ไม่ระบุ'
      };
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLaw == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการคำร้องเรียน'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'รอดำเนินการ', icon: Icon(Icons.pending_actions)),
            Tab(text: 'กำลังดำเนินการ', icon: Icon(Icons.engineering)),
            Tab(text: 'เสร็จสิ้น', icon: Icon(Icons.check_circle)),
            Tab(text: 'ทั้งหมด', icon: Icon(Icons.list_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintList('pending'),
          _buildComplaintList('in_progress'),
          _buildComplaintList('resolved'),
          _buildComplaintList('all'),
        ],
      ),
    );
  }

  Widget _buildComplaintList(String status) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: FutureBuilder<List<ComplaintModel>>(
            future: _getComplaintsByStatus(status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                );
              }

              final complaints = snapshot.data ?? [];
              final filteredComplaints = _applyFilters(complaints);

              if (filteredComplaints.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getEmptyIcon(status),
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getEmptyMessage(status),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredComplaints.length,
                  itemBuilder: (context, index) {
                    return _ComplaintManagementCard(
                      complaint: filteredComplaints[index],
                      houseNumber: _houseNumbers[filteredComplaints[index].houseId] ?? 'ไม่ระบุ',
                      onStatusChanged: () => setState(() {}),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Filter by Type
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'ประเภท',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                DropdownMenuItem(value: '1', child: Text('สาธารณูปโภค')),
                DropdownMenuItem(value: '2', child: Text('ความปลอดภัย')),
                DropdownMenuItem(value: '3', child: Text('สิ่งแวดล้อม')),
                DropdownMenuItem(value: '4', child: Text('การบริการ')),
              ],
              onChanged: (value) => setState(() => _filterType = value!),
            ),
          ),
          const SizedBox(width: 8),
          // Filter by Level
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _filterLevel,
              decoration: const InputDecoration(
                labelText: 'ความสำคัญ',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('ทั้งหมด')),
                DropdownMenuItem(value: 1, child: Text('ต่ำ')),
                DropdownMenuItem(value: 2, child: Text('ปกติ')),
                DropdownMenuItem(value: 3, child: Text('สูง')),
                DropdownMenuItem(value: 4, child: Text('เร่งด่วน')),
              ],
              onChanged: (value) => setState(() => _filterLevel = value!),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ComplaintModel>> _getComplaintsByStatus(String status) async {
    if (_currentLaw == null) return [];

    switch (status) {
      case 'pending':
        return ComplaintDomain.getByStatusInVillage(
          _currentLaw!.villageId,
          'pending',
        );
      case 'in_progress':
        return ComplaintDomain.getByStatusInVillage(
          _currentLaw!.villageId,
          'in_progress',
        );
      case 'resolved':
        return ComplaintDomain.getByStatusInVillage(
          _currentLaw!.villageId,
          'resolved',
        );
      default:
        return ComplaintDomain.getAllInVillage(_currentLaw!.villageId);
    }
  }

  List<ComplaintModel> _applyFilters(List<ComplaintModel> complaints) {
    return complaints.where((complaint) {
      // Filter by type
      if (_filterType != 'all' &&
          complaint.typeComplaint.toString() != _filterType) {
        return false;
      }

      // Filter by level
      if (_filterLevel > 0 && complaint.level != _filterLevel) {
        return false;
      }

      return true;
    }).toList();
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'in_progress':
        return Icons.engineering_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'ไม่มีคำร้องเรียนที่รอดำเนินการ';
      case 'in_progress':
        return 'ไม่มีคำร้องเรียนที่กำลังดำเนินการ';
      case 'resolved':
        return 'ไม่มีคำร้องเรียนที่เสร็จสิ้น';
      default:
        return 'ไม่มีคำร้องเรียน';
    }
  }
}

// Widget สำหรับแสดง Card ของแต่ละร้องเรียน
class _ComplaintManagementCard extends StatelessWidget {
  final ComplaintModel complaint;
  final String houseNumber;
  final VoidCallback onStatusChanged;

  const _ComplaintManagementCard({
    required this.complaint,
    required this.houseNumber,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: _buildStatusIcon(),
        title: Text(
          complaint.header,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('บ้านเลขที่: $houseNumber'),
            Row(
              children: [
                _buildLevelChip(),
                const SizedBox(width: 4),
                _buildTypeChip(),
                if (complaint.isPrivate) ...[
                  const SizedBox(width: 4),
                  _buildPrivateChip(),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                const Text(
                  'รายละเอียด:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(complaint.description),
                const SizedBox(height: 12),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'วันที่แจ้ง',
                        _formatDate(complaint.createAt),
                      ),
                    ),
                    if (complaint.updateAt != null)
                      Expanded(
                        child: _buildInfoItem(
                          'อัพเดทล่าสุด',
                          _formatDate(complaint.updateAt!),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (complaint.status != 'resolved') ...[
                      OutlinedButton.icon(
                        onPressed: () => _showStatusDialog(context),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('เปลี่ยนสถานะ'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _showDetailDialog(context),
                      icon: const Icon(Icons.visibility),
                      label: const Text('รายละเอียด'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    Color color;
    IconData icon;

    switch (complaint.status?.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.blue;
        icon = Icons.engineering;
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildLevelChip() {
    String text;
    Color color;

    switch (complaint.level) {
      case 1:
        text = 'ต่ำ';
        color = Colors.green;
        break;
      case 2:
        text = 'ปกติ';
        color = Colors.blue;
        break;
      case 3:
        text = 'สูง';
        color = Colors.orange;
        break;
      case 4:
      case 5:
        text = 'เร่งด่วน';
        color = Colors.red;
        break;
      default:
        text = 'ปกติ';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTypeChip() {
    String text;
    IconData icon;

    switch (complaint.typeComplaint) {
      case 1:
        text = 'สาธารณูปโภค';
        icon = Icons.build;
        break;
      case 2:
        text = 'ความปลอดภัย';
        icon = Icons.security;
        break;
      case 3:
        text = 'สิ่งแวดล้อม';
        icon = Icons.eco;
        break;
      case 4:
        text = 'การบริการ';
        icon = Icons.support_agent;
        break;
      default:
        text = 'อื่นๆ';
        icon = Icons.more_horiz;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 12, color: Colors.purple),
          SizedBox(width: 4),
          Text(
            'ส่วนตัว',
            style: TextStyle(color: Colors.purple, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เปลี่ยนสถานะ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('รอดำเนินการ'),
              onTap: () => _updateStatus(context, 'pending'),
            ),
            ListTile(
              leading: const Icon(Icons.engineering, color: Colors.blue),
              title: const Text('กำลังดำเนินการ'),
              onTap: () => _updateStatus(context, 'in_progress'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('เสร็จสิ้น'),
              onTap: () => _updateStatus(context, 'resolved'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    Navigator.pop(context);

    final success = await ComplaintDomain.updateStatus(
      complaintId: complaint.complaintId!,
      status: newStatus,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพเดทสถานะเป็น ${_getStatusText(newStatus)} สำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      onStatusChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัพเดทสถานะ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      default:
        return status;
    }
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รายละเอียดคำร้องเรียน',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailRow('หัวข้อ', complaint.header),
              _buildDetailRow('รายละเอียด', complaint.description),
              _buildDetailRow('บ้านเลขที่', houseNumber),
              _buildDetailRow('ประเภท', _getTypeText(complaint.typeComplaint)),
              _buildDetailRow('ระดับความสำคัญ', _getLevelText(complaint.level)),
              _buildDetailRow('สถานะ', _getStatusText(complaint.status ?? 'pending')),
              _buildDetailRow('ความเป็นส่วนตัว', complaint.isPrivate ? 'ส่วนตัว' : 'สาธารณะ'),
              _buildDetailRow('วันที่แจ้ง', _formatDate(complaint.createAt)),
              if (complaint.updateAt != null)
                _buildDetailRow('อัพเดทล่าสุด', _formatDate(complaint.updateAt!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getTypeText(int type) {
    switch (type) {
      case 1:
        return 'สาธารณูปโภค';
      case 2:
        return 'ความปลอดภัย';
      case 3:
        return 'สิ่งแวดล้อม';
      case 4:
        return 'การบริการ';
      default:
        return 'อื่นๆ';
    }
  }

  String _getLevelText(int level) {
    switch (level) {
      case 1:
        return 'ต่ำ';
      case 2:
        return 'ปกติ';
      case 3:
        return 'สูง';
      case 4:
      case 5:
        return 'เร่งด่วน';
      default:
        return 'ปกติ';
    }
  }
}