import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/pages/house/complaint/complaint_delete.dart';
import 'package:fullproject/pages/house/complaint/complaint_edit.dart';
import 'package:fullproject/services/image_service.dart';

// หน้าสำหรับดูรายละเอียดร้องเรียน (Lazy Loading เฉพาะร้องเรียน)
class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({Key? key, required this.complaint})
    : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Future<ComplaintModel?> _complaintFuture;

  @override
  void initState() {
    super.initState();
    _complaintFuture = ComplaintDomain.getById(widget.complaint.complaintId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ร้องเรียน #${widget.complaint.complaintId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _complaintFuture = ComplaintDomain.getById(
                  widget.complaint.complaintId!,
                );
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<ComplaintModel?>(
        future: _complaintFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('ไม่สามารถโหลดข้อมูลร้องเรียนได้'));
          }

          final complaint = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Fixed: Use Row instead of Spacer, add proper closing brackets
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (complaint.status?.toLowerCase() == 'pending' ||
                        complaint.status == null) ...[
                      ElevatedButton.icon(
                        onPressed: () => _editComplaint(complaint),
                        // Add your edit function here
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('แก้ไข'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _deleteComplaint(complaint),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('ลบ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ✅ Add spacing after buttons
                _buildDetailCard('หัวข้อ', complaint.header),
                _buildDetailCard('รายละเอียด', complaint.description),
                _buildDetailCard('บ้านเลขที่', complaint.houseId.toString()),
                _buildDetailCard(
                  'ประเภท',
                  _getTypeText(complaint.typeComplaint),
                ),
                _buildDetailCard(
                  'ระดับความสำคัญ',
                  _getLevelText(complaint.level),
                ),
                _buildDetailCard('สถานะ', _getStatusText(complaint.status)),
                _buildDetailCard(
                  'ความเป็นส่วนตัว',
                  complaint.isPrivate ? 'ส่วนตัว' : 'สาธารณะ',
                ),
                _buildDetailCard(
                  'วันที่สร้าง',
                  _formatDateTime(complaint.createAt),
                ),
                if (complaint.updateAt != null)
                  _buildDetailCard(
                    'วันที่อัพเดท',
                    _formatDateTime(complaint.updateAt!),
                  ),
                if (complaint.img != null) _buildImageCard(complaint.img!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รูปภาพ:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BuildImage(imagePath: imageUrl, tablePath: 'complaint'),
            ),
          ],
        ),
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

  // ฟังก์ชันสำหรับลบ Complaint
  void _deleteComplaint(ComplaintModel complaint) async {
    final result = await DeleteComplaintWidget.show(
      context: context,
      complaint: complaint,
      getTypeText: _getTypeText,
      getStatusText: _getStatusText,
    );

    // Optional: Handle the result if needed
    if (result == true) {
      // Refresh the page or do something after successful deletion
    }
  }

  void _editComplaint(ComplaintModel complaint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseComplaintEditPage(complaint: complaint),
      ),
    );

    if (result == true) {
      // Refresh data after successful edit
      setState(() {
        _complaintFuture = ComplaintDomain.getById(
          widget.complaint.complaintId!,
        );
      });
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

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      case 'pending':
      default:
        return 'รอดำเนินการ';
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
