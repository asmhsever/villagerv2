// lib/pages/law/complaint/success_complaint_form.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/success_complaint_domain.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class SuccessComplaintFormPage extends StatefulWidget {
  final ComplaintModel complaint;

  const SuccessComplaintFormPage({super.key, required this.complaint});

  @override
  State<SuccessComplaintFormPage> createState() => _SuccessComplaintFormPageState();
}

class _SuccessComplaintFormPageState extends State<SuccessComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  LawModel? currentLaw;

  // Image handling
  dynamic _imageFile;
  String? _imageFileName;
  final ImagePicker _picker = ImagePicker();

  // Earthy Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user is LawModel) {
        setState(() {
          currentLaw = user;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageFile = bytes;
          _imageFileName = image.name;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
            backgroundColor: burntOrange,
          ),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      _imageFileName = null;
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กรุณาตรวจสอบข้อมูลที่กรอก'),
          backgroundColor: burntOrange,
        ),
      );
      return;
    }

    if (currentLaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: burntOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. สร้างรายการดำเนินการเสร็จสิ้น
      final successResult = await SuccessComplaintDomain.create(
        lawId: currentLaw!.lawId,
        complaintId: widget.complaint.complaintId!,
        description: _descriptionController.text.trim(),
        imageFile: _imageFile,
      );

      if (successResult != null) {
        // 2. อัปเดตสถานะคำร้องเป็น resolved
        await ComplaintDomain.updateStatus(
          complaintId: widget.complaint.complaintId!,
          status: 'resolved',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('บันทึกการดำเนินการเสร็จสิ้นแล้ว'),
              backgroundColor: oliveGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('ไม่สามารถบันทึกข้อมูลได้');
      }
    } catch (e) {
      print('Error submitting success complaint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: burntOrange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: ivoryWhite,
              onPressed: () => _submit(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      color: ivoryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: beige,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: softBrown, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildSectionCard(
      title: 'รูปภาพหลักฐานการดำเนินการ (ไม่บังคับ)',
      icon: Icons.camera_alt,
      children: [
        if (_imageFile != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: warmStone),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _imageFile as Uint8List,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.image, color: earthClay, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _imageFileName ?? 'รูปภาพ',
                  style: TextStyle(
                    fontSize: 12,
                    color: earthClay,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _removeImage,
                icon: Icon(Icons.delete, color: burntOrange, size: 16),
                label: Text(
                  'ลบ',
                  style: TextStyle(color: burntOrange),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(
              _imageFile != null ? Icons.edit : Icons.add_photo_alternate,
              color: softBrown,
            ),
            label: Text(
              _imageFile != null ? 'เปลี่ยนรูปภาพ' : 'เลือกรูปภาพ',
              style: TextStyle(color: softBrown),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: softBrown),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'รองรับไฟล์ JPG, PNG ขนาดไม่เกิน 5MB\nแนะนำให้แนบรูปภาพการดำเนินการเพื่อเป็นหลักฐาน',
          style: TextStyle(
            fontSize: 12,
            color: warmStone,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: oliveGreen,
        foregroundColor: ivoryWhite,
        elevation: 0,
        title: const Text(
          'บันทึกการดำเนินการเสร็จสิ้น',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ข้อมูลคำร้อง
              _buildSectionCard(
                title: 'ข้อมูลคำร้องเรียน',
                icon: Icons.info_outline,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: beige,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: warmStone),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.complaint.header,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: softBrown,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.complaint.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: earthClay,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // รายละเอียดการดำเนินการ
              _buildSectionCard(
                title: 'รายละเอียดการดำเนินการ',
                icon: Icons.assignment_turned_in,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'อธิบายการดำเนินการที่ทำ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: warmStone),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: softBrown, width: 2),
                      ),
                      prefixIcon: Icon(Icons.description, color: earthClay),
                      fillColor: ivoryWhite,
                      filled: true,
                      hintText: 'อธิบายรายละเอียดว่าได้ดำเนินการแก้ไขปัญหาอย่างไร\nเช่น ติดตั้งไฟส่องสว่าง จัดทำป้ายเตือน ซ่อมแซมสิ่งปลูกสร้าง ฯลฯ',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกรายละเอียดการดำเนินการ';
                      }
                      if (value.trim().length < 10) {
                        return 'รายละเอียดต้องมีอย่างน้อย 10 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // รูปภาพหลักฐาน
              _buildImageSection(),

              const SizedBox(height: 24),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oliveGreen,
                    foregroundColor: ivoryWhite,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ivoryWhite),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('กำลังบันทึก...'),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle),
                      const SizedBox(width: 8),
                      const Text(
                        'บันทึกการดำเนินการเสร็จสิ้น',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}