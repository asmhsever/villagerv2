// lib/pages/law/complaint/complaint_resolve_form.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fullproject/domains/law_domain.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawComplaintResolveFormPage extends StatefulWidget {
  final ComplaintModel complaint;

  const LawComplaintResolveFormPage({super.key, required this.complaint});

  @override
  State<LawComplaintResolveFormPage> createState() =>
      _LawComplaintResolveFormPageState();
}

class _LawComplaintResolveFormPageState
    extends State<LawComplaintResolveFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _resolvedDescriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? houseNumber;
  String? complaintTypeName;

  // Updated image handling variables
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  bool isLoading = false;
  bool isSubmitting = false;
  late LawModel lawData;

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
  }

  @override
  void dispose() {
    _resolvedDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalData() async {
    setState(() => isLoading = true);

    try {
      // โหลดข้อมูลบ้าน
      final house = await SupabaseConfig.client
          .from('house')
          .select('house_number')
          .eq('house_id', widget.complaint.houseId)
          .maybeSingle();

      // โหลดข้อมูลประเภทร้องเรียน
      final complaintType = await ComplaintTypeDomain.getById(
        widget.complaint.typeComplaint,
      );

      try {
        final user = await AuthService.getCurrentUser();
        if (!mounted) return;

        if (user is LawModel) {
          setState(() {
            lawData = user;
          });
        } else {
          throw Exception('ไม่พบข้อมูลผู้ใช้');
        }
      } catch (e) {
        throw Exception(e);
      }

      if (mounted) {
        setState(() {
          houseNumber = house?['house_number']?.toString() ?? 'ไม่ทราบ';
          complaintTypeName = complaintType?.type ?? 'ไม่ระบุ';
        });
      }
    } catch (e) {
      print('Error loading additional data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String formatDateFromString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'รออนุมัติ';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      case null:
        return 'รอดำเนินการ';
      default:
        return status ?? 'ไม่ระบุ';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return ThemeColors.burntOrange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return ThemeColors.oliveGreen;
      case null:
        return ThemeColors.warmStone;
      default:
        return ThemeColors.earthClay;
    }
  }

  String getLevelLabel(String level) {
    switch (level) {
      case '1':
        return 'ต่ำ';
      case '2':
        return 'ปานกลาง';
      case '3':
        return 'สูง';
      case '4':
        return 'ฉุกเฉิน';
      default:
        return level;
    }
  }

  Color getLevelColor(String level) {
    switch (level) {
      case '1':
        return ThemeColors.oliveGreen;
      case '2':
        return Colors.orange;
      case '3':
        return ThemeColors.burntOrange;
      case '4':
        return Colors.red;
      default:
        return ThemeColors.earthClay;
    }
  }

  IconData getTypeIcon(int? typeId) {
    switch (typeId) {
      case 1:
        return Icons.water_damage;
      case 2:
        return Icons.electrical_services;
      case 3:
        return Icons.security;
      case 4:
        return Icons.clean_hands;
      case 5:
        return Icons.local_parking;
      default:
        return Icons.report_problem;
    }
  }

  // Updated Image Functions
  bool _hasSelectedImage() {
    return (kIsWeb && _selectedImageBytes != null) ||
        (!kIsWeb && _selectedImageFile != null);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายภาพ: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: ThemeColors.oliveGreen,
                  ),
                ),
                title: Text(
                  'เลือกจากแกลเลอรี่',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: ThemeColors.burntOrange,
                  ),
                ),
                title: Text(
                  'ถ่ายภาพ',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitResolveComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: ThemeColors.oliveGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ยืนยันส่งคำร้องเรียน',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ThemeColors.oliveGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'การส่งคำร้องเรียน',
                        style: TextStyle(
                          color: ThemeColors.oliveGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สถานะจะเปลี่ยนเป็น "เสร็จสิ้น" และไม่สามารถแก้ไขได้อีก',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'คุณต้องการส่งคำร้องเรียนนี้หรือไม่?',
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'หัวข้อ: ${widget.complaint.header}',
                    style: TextStyle(
                      color: ThemeColors.softBrown,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'รายละเอียดการแก้ไข: ${_resolvedDescriptionController.text}',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_hasSelectedImage())
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• รูปภาพประกอบ: มี',
                        style: TextStyle(
                          color: ThemeColors.earthClay,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.warmStone,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.oliveGreen,
              foregroundColor: ThemeColors.ivoryWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'ส่งคำร้องเรียน',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSubmitting = true);

    try {
      // TODO: ใส่ resolvedByLawId ที่ถูกต้องตาม user ที่ login
      final resolvedByLawId = lawData.lawId; // แทนที่ด้วย law user ID จริง

      // Prepare the image file for submission
      File? imageFileForSubmission;
      if (kIsWeb && _selectedImageBytes != null) {
        imageFileForSubmission = null;
      } else if (!kIsWeb && _selectedImageFile != null) {
        imageFileForSubmission = _selectedImageFile;
      }

      await ComplaintDomain.resolve(
        complaintId: widget.complaint.complaintId!,
        resolvedByLawId: resolvedByLawId,
        resolvedDescription: _resolvedDescriptionController.text.trim(),
        resolvedImageFile: imageFileForSubmission,
      );

      if (mounted) {
        // แสดงการแจ้งเตือนความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 8),
                const Text(
                  'ส่งคำร้องเรียนสำเร็จ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: ThemeColors.oliveGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // กลับไปหน้าก่อนหน้า 2 ครั้ง (ข้าม resolve form page)
        Navigator.pop(context, true); // กลับจาก resolve form page
        Navigator.pop(context, true); // กลับจาก detail page ไปยัง list page
      }
    } catch (e) {
      print('Error resolving complaint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาดในการส่งคำร้องเรียน: ${e.toString()}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: ThemeColors.ivoryWhite,
              onPressed: () => _submitResolveComplaint(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Card(
      elevation: 3,
      color: backgroundColor ?? ThemeColors.ivoryWhite,
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
                    color: ThemeColors.beige,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? ThemeColors.softBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? ThemeColors.softBrown,
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? ThemeColors.softBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt, color: ThemeColors.softBrown, size: 20),
            const SizedBox(width: 8),
            Text(
              'รูปภาพการแก้ไข (ไม่บังคับ)',
              style: TextStyle(
                color: ThemeColors.softBrown,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_hasSelectedImage()) ...[
          // แสดงรูปที่เลือก
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeColors.softBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb && _selectedImageBytes != null
                      ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                      : !kIsWeb && _selectedImageFile != null
                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                      : Container(
                          color: ThemeColors.beige,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: ThemeColors.warmStone,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      color: ThemeColors.ivoryWhite,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ปุ่มเปลี่ยนรูป
          OutlinedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: Icon(Icons.edit, color: ThemeColors.softBrown),
            label: Text(
              'เปลี่ยนรูปภาพ',
              style: TextStyle(color: ThemeColors.softBrown),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ThemeColors.softBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ] else ...[
          // ปุ่มเลือกรูป
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThemeColors.softBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: ThemeColors.warmStone,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เลือกรูปภาพการแก้ไข',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'แตะเพื่อเลือกรูปจากแกลเลอรี่หรือถ่ายภาพ',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighPriority =
        widget.complaint.level == '3' || widget.complaint.level == '4';

    return Scaffold(
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        backgroundColor: ThemeColors.oliveGreen,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        title: const Text(
          'ส่งคำร้องเรียน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ThemeColors.softBrown),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Priority Banner
                    if (isHighPriority)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: ThemeColors.burntOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.priority_high,
                              color: ThemeColors.ivoryWhite,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ร้องเรียนระดับความสำคัญสูง',
                              style: TextStyle(
                                color: ThemeColors.ivoryWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Original Complaint Info
                    _buildInfoCard(
                      title: 'ข้อมูลคำร้องเรียนเดิม',
                      icon: getTypeIcon(widget.complaint.typeComplaint),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ThemeColors.sandyTan,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.complaint.header,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.softBrown,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.complaint.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeColors.earthClay,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'บ้านเลขที่:',
                          houseNumber ?? '${widget.complaint.houseId}',
                        ),
                        _buildInfoRow(
                          'ประเภท:',
                          complaintTypeName ?? 'ไม่ระบุ',
                        ),
                        _buildInfoRow(
                          'สถานะปัจจุบัน:',
                          getStatusLabel(widget.complaint.status),
                          valueColor: getStatusColor(widget.complaint.status),
                        ),
                        _buildInfoRow(
                          'ระดับความสำคัญ:',
                          'ระดับ ${getLevelLabel(widget.complaint.level)}',
                          valueColor: getLevelColor(widget.complaint.level),
                        ),
                        _buildInfoRow(
                          'วันที่ส่ง:',
                          formatDateFromString(widget.complaint.createAt),
                        ),
                      ],
                    ),

                    // Original Image
                    if (widget.complaint.complaintImg?.isNotEmpty == true)
                      _buildInfoCard(
                        title: 'รูปภาพปัญหาเดิม',
                        icon: Icons.image,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BuildImage(
                              imagePath: widget.complaint.complaintImg!,
                              tablePath: "complaint/complaint",
                            ),
                          ),
                        ],
                      ),

                    // Resolve Form
                    _buildInfoCard(
                      title: 'ข้อมูลการแก้ไข',
                      icon: Icons.build_circle,
                      backgroundColor: ThemeColors.oliveGreen.withValues(
                        alpha: 0.05,
                      ),
                      iconColor: ThemeColors.oliveGreen,
                      children: [
                        // Description field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: ThemeColors.softBrown,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'รายละเอียดการแก้ไข *',
                                  style: TextStyle(
                                    color: ThemeColors.softBrown,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _resolvedDescriptionController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'อธิบายรายละเอียดการแก้ไขปัญหา...',
                                hintStyle: TextStyle(
                                  color: ThemeColors.warmStone,
                                ),
                                filled: true,
                                fillColor: ThemeColors.inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: ThemeColors.softBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: ThemeColors.softBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: ThemeColors.focusedBrown,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณากรอกรายละเอียดการแก้ไข';
                                }
                                if (value.trim().length < 10) {
                                  return 'รายละเอียดต้องมีความยาวอย่างน้อย 10 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'กรุณาอธิบายให้ละเอียด เช่น วิธีการแก้ไข, อุปกรณ์ที่ใช้, ระยะเวลา, ผลลัพธ์ที่ได้',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Image picker section
                        _buildImageSection(),
                      ],
                    ),

                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite,
          boxShadow: [
            BoxShadow(
              color: ThemeColors.softBrown.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: ThemeColors.warmStone),
                label: Text(
                  'ยกเลิก',
                  style: TextStyle(color: ThemeColors.warmStone),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ThemeColors.warmStone),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : _submitResolveComplaint,
                icon: isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeColors.ivoryWhite,
                          ),
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  isSubmitting ? 'กำลังส่งเรื่อง...' : 'ส่งคำร้องเรียน',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.oliveGreen,
                  foregroundColor: ThemeColors.ivoryWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
