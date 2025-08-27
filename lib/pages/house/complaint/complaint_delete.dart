import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';

class DeleteComplaintWidget {
  static Future<bool?> show({
    required BuildContext context,
    required ComplaintModel complaint,
    required String Function(int) getTypeText,
    required String Function(String?) getStatusText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteComplaintDialog(
        complaint: complaint,
        getTypeText: getTypeText,
        getStatusText: getStatusText,
      ),
    );
  }
}

class _DeleteComplaintDialog extends StatelessWidget {
  final ComplaintModel complaint;
  final String Function(int) getTypeText;
  final String Function(String?) getStatusText;

  const _DeleteComplaintDialog({
    required this.complaint,
    required this.getTypeText,
    required this.getStatusText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ยืนยันการลบ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('คุณต้องการลบร้องเรียนนี้หรือไม่?'),
          const SizedBox(height: 12),
          _buildComplaintPreview(),
          const SizedBox(height: 8),
          const Text(
            '⚠️ การลบไม่สามารถยกเลิกได้',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () => _handleDelete(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
          ),
          child: const Text('ลบ'),
        ),
      ],
    );
  }

  Widget _buildComplaintPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'หัวข้อ: ${complaint.header}',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'รายละเอียด: ${complaint.description}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'ประเภท: ${getTypeText(complaint.typeComplaint)}',
            style: const TextStyle(color: Colors.blue),
          ),
          Text(
            'สถานะ: ${getStatusText(complaint.status)}',
            style: TextStyle(
              color: complaint.status?.toLowerCase() == 'pending'
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context) async {
    // ปิด confirmation dialog ก่อน
    Navigator.pop(context, true);

    // แสดง loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LoadingDialog(),
    );

    try {
      // เรียก API ลบ complaint
      await ComplaintDomain.delete(complaint.complaintId!);

      // ปิด loading dialog
      Navigator.pop(context);

      // แสดงข้อความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบร้องเรียนสำเร็จ'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // กลับไปหน้าก่อนหน้า
      Navigator.pop(context, true);
    } catch (e) {
      // ปิด loading dialog
      Navigator.pop(context);

      // แสดงข้อความ error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบ: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('กำลังลบร้องเรียน...'),
        ],
      ),
    );
  }
}
