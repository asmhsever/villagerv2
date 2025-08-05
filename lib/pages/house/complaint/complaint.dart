import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/pages/house/complaint/complaint_detail.dart';
import 'package:fullproject/pages/house/complaint/complaint_form.dart';

class HouseComplaintPage extends StatefulWidget {
  final int houseId; // ดูเฉพาะบ้านนี้เท่านั้น

  const HouseComplaintPage({Key? key, required this.houseId}) : super(key: key);

  @override
  State<HouseComplaintPage> createState() => _HouseComplaintPageState();
}

class _HouseComplaintPageState extends State<HouseComplaintPage> {
  late Future<List<ComplaintModel>> _complaintsFuture;
  String _currentFilter = 'all'; // all, pending, resolved, high_priority

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    switch (_currentFilter) {
      case 'pending':
        _complaintsFuture = ComplaintDomain.getPendingInHouse(widget.houseId);
        break;
      case 'resolved':
        _complaintsFuture = ComplaintDomain.getResolvedInHouse(widget.houseId);
        break;
      case 'high_priority':
        _complaintsFuture = ComplaintDomain.getByLevelInHouse(
          widget.houseId,
          3,
        );
        break;
      default:
        _complaintsFuture = ComplaintDomain.getAllInHouse(widget.houseId);
    }
  }

  void _refreshComplaints() {
    setState(() {
      _loadComplaints();
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _loadComplaints();
    });
  }

  // ฟังก์ชันสำหรับลบ Complaint
  void _addComplaint({required int houseId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseComplaintFormPage(houseId: houseId),
      ),
    );

    if (result == true) _refreshComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refreshComplaints(),
        child: FutureBuilder<List<ComplaintModel>>(
          future: _complaintsFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดข้อมูลร้องเรียน...'),
                  ],
                ),
              );
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshComplaints,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              );
            }

            // Empty state
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getEmptyIcon(), size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyMessage(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Success state with data
            final complaints = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      return ComplaintCard(
                        complaint: complaint,
                        onTap: () => _navigateToComplaintDetail(complaint),
                        onStatusUpdate: _refreshComplaints,
                      );
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _addComplaint(houseId: widget.houseId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFC7B9A5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "ร้องเรียน +",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (_currentFilter) {
      case 'pending':
        return Icons.pending_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'high_priority':
        return Icons.priority_high_outlined;
      default:
        return Icons.feedback_outlined;
    }
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case 'pending':
        return 'ไม่มีร้องเรียนที่รอดำเนินการ';
      case 'resolved':
        return 'ไม่มีร้องเรียนที่เสร็จสิ้นแล้ว';
      case 'high_priority':
        return 'ไม่มีร้องเรียนความสำคัญสูง';
      default:
        return 'ไม่มีข้อมูลร้องเรียน';
    }
  }

  void _navigateToComplaintDetail(ComplaintModel complaint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailScreen(complaint: complaint),
      ),
    ).then((result) {
      // This executes when Navigator.pop() is called
      print('Returned from detail screen');
      _refreshComplaints();
    });
  }

  // void _navigateToAddComplaint() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => AddComplaintScreen(houseId: widget.houseId),
  //     ),
  //   ).then((_) => _refreshComplaints()); // Refresh เมื่อกลับมา
  // }
}

// Widget สำหรับแสดงข้อมูลร้องเรียนแต่ละรายการ
class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;

  const ComplaintCard({
    Key? key,
    required this.complaint,
    this.onTap,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: _buildStatusAvatar(),
        title: Text(
          complaint.header,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildPriorityChip(),
                const SizedBox(width: 8),
                _buildPrivacyChip(),
                const SizedBox(width: 8),
                _buildTypeChip(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'วันที่: ${_formatDate(complaint.createAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),

        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildStatusAvatar() {
    Color color;
    IconData icon;

    switch (complaint.status?.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }

    return CircleAvatar(
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildPriorityChip() {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPrivacyChip() {
    if (!complaint.isPrivate) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: const Text(
        'ส่วนตัว',
        style: TextStyle(
          color: Colors.purple,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    String text;
    Color color;

    switch (complaint.typeComplaint) {
      case 1:
        text = 'สาธารณูปโภค';
        color = Colors.cyan;
        break;
      case 2:
        text = 'ความปลอดภัย';
        color = Colors.red;
        break;
      case 3:
        text = 'สิ่งแวดล้อม';
        color = Colors.green;
        break;
      case 4:
        text = 'การบริการ';
        color = Colors.indigo;
        break;
      default:
        text = 'อื่นๆ';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final success = await ComplaintDomain.updateStatus(
      complaintId: complaint.complaintId!,
      status: status,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพเดทสถานะเป็น ${_getStatusText(status)} แล้ว'),
          backgroundColor: Colors.green,
        ),
      );
      onStatusUpdate?.call();
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
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      default:
        return 'รอดำเนินการ';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
