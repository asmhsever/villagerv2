import 'package:flutter/material.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';

class HouseComplaintEditPage extends StatefulWidget {
  final ComplaintModel complaint;

  const HouseComplaintEditPage({super.key, required this.complaint});

  @override
  State<HouseComplaintEditPage> createState() => _HouseComplaintEditPageState();
}

class _HouseComplaintEditPageState extends State<HouseComplaintEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedTypeId = 0;
  bool _isPrivate = false;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _complaintTypes = [];
  bool _isLoadingTypes = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadComplaintTypes();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _headerController.text = widget.complaint.header;
    _descriptionController.text = widget.complaint.description;
    _selectedTypeId = widget.complaint.typeComplaint;
    _isPrivate = widget.complaint.isPrivate;
    _currentImageUrl = widget.complaint.img;
  }

  Future<void> _loadComplaintTypes() async {
    try {
      final types = await ComplaintTypeDomain.getAll();
      final List<Map<String, dynamic>> typejson = types
          .map((model) => model.toJson())
          .toList();
      setState(() {
        _complaintTypes = typejson;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTypes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถโหลดประเภทร้องเรียนได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null ||
                  (_currentImageUrl != null && !_removeCurrentImage))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'ลบรูปภาพ',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _removeCurrentImage = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _removeCurrentImage = true;
    });
  }

  Future<void> _updateComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? finalImageUrl;

      // Handle image updates
      if (_selectedImage != null) {
        // อัพโหลดรูปใหม่
        finalImageUrl = await SupabaseImage().uploadImage(
          imageFile: _selectedImage!,
          tableName: "complaint",
          rowName: "complaint_id",
          rowImgName: "img",
          rowKey: widget.complaint.complaintId,
        );
      } else if (_removeCurrentImage) {
        // ลบรูปเดิม
        finalImageUrl = null;
      } else {
        // เก็บรูปเดิม
        finalImageUrl = _currentImageUrl;
      }

      // สร้าง updated complaint model
      final updatedComplaint = ComplaintModel(
        complaintId: widget.complaint.complaintId,
        houseId: widget.complaint.houseId,
        typeComplaint: _selectedTypeId,
        createAt: widget.complaint.createAt,
        header: _headerController.text.trim(),
        description: _descriptionController.text.trim(),
        level: widget.complaint.level,
        isPrivate: _isPrivate,
        img: finalImageUrl,
        status: widget.complaint.status,
        updateAt: DateTime.now().toIso8601String(),
      );

      // อัพเดทข้อมูลในฐานข้อมูล
      final result = await ComplaintDomain.update(
        complaintId: widget.complaint.complaintId!,
        updatedComplaint: updatedComplaint,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แก้ไขร้องเรียนสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // ส่งค่า true กลับไปเพื่อ refresh
      } else {
        throw Exception('ไม่สามารถแก้ไขข้อมูลได้');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขร้องเรียน'),
        backgroundColor: const Color(0xFFC7B9A5),
        foregroundColor: Colors.white,
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingTypes
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แสดงข้อมูลเดิม
                    _buildInfoCard(),
                    const SizedBox(height: 20),

                    // หัวข้อร้องเรียน
                    _buildSectionTitle('หัวข้อร้องเรียน'),
                    TextFormField(
                      controller: _headerController,
                      decoration: const InputDecoration(
                        hintText: 'กรุณาระบุหัวข้อร้องเรียน',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณาระบุหัวข้อร้องเรียน';
                        }
                        if (value.trim().length < 5) {
                          return 'หัวข้อต้องมีอย่างน้อย 5 ตัวอักษร';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    const SizedBox(height: 20),

                    // รายละเอียด
                    _buildSectionTitle('รายละเอียด'),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'กรุณาระบุรายละเอียดของปัญหา',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณาระบุรายละเอียด';
                        }
                        if (value.trim().length < 10) {
                          return 'รายละเอียดต้องมีอย่างน้อย 10 ตัวอักษร';
                        }
                        return null;
                      },
                      maxLength: 500,
                    ),
                    const SizedBox(height: 20),

                    // ประเภทร้องเรียน (Dropdown)
                    _buildSectionTitle('ประเภทร้องเรียน'),
                    _buildTypeDropdown(),
                    const SizedBox(height: 20),

                    // รูปภาพ
                    _buildSectionTitle('รูปภาพประกอบ (ไม่บังคับ)'),
                    _buildImagePicker(),
                    const SizedBox(height: 30),

                    // ความเป็นส่วนตัว
                    _buildPrivacySwitch(),
                    const SizedBox(height: 20),

                    // ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _updateComplaint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('กำลังบันทึก...'),
                                ],
                              )
                            : const Text(
                                'บันทึกการแก้ไข',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลร้องเรียน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'สถานะ: ${_getStatusText(widget.complaint.status)}',
              style: TextStyle(
                color: _getStatusColor(widget.complaint.status),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('วันที่สร้าง: ${_formatDate(widget.complaint.createAt)}'),
            if (widget.complaint.updateAt != null)
              Text('อัพเดทล่าสุด: ${_formatDate(widget.complaint.updateAt!)}'),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return '📨 รอรับเรื่อง';
      case 'received':
        return '📥 รับเรื่องแล้ว';
      case 'in_progress':
        return '🔧 กำลังดำเนินการ';
      case 'on_hold':
        return '🕓 รอการดำเนินการ';
      case 'resolved':
        return '✅ ดำเนินการเสร็จสิ้น';
      case 'rejected':
        return '❌ ไม่รับเรื่อง';
      default:
        return '📨 รอรับเรื่อง';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'received':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'on_hold':
        return Colors.amber;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    if (_complaintTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'ไม่พบข้อมูลประเภทร้องเรียน',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedTypeId == 0 ? null : _selectedTypeId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'เลือกประเภทร้องเรียน',
      ),
      items: _complaintTypes.map<DropdownMenuItem<int>>((map) {
        final int typeId = map['type_id'] as int;
        final String typeName = map['type'] ?? 'ไม่ระบุ';

        return DropdownMenuItem<int>(
          value: typeId,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  typeName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedTypeId = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || value == 0) {
          return 'กรุณาเลือกประเภทร้องเรียน';
        }
        return null;
      },
      isExpanded: true,
      menuMaxHeight: 300,
    );
  }

  Widget _buildPrivacySwitch() {
    return Card(
      child: SwitchListTile(
        title: const Text('ร้องเรียนแบบส่วนตัว'),
        subtitle: const Text('เฉพาะบ้านของคุณเท่านั้น'),
        value: _isPrivate,
        onChanged: (value) {
          setState(() {
            _isPrivate = value;
          });
        },
        activeColor: Colors.purple,
        secondary: Icon(
          _isPrivate ? Icons.lock : Icons.lock_open,
          color: _isPrivate ? Colors.purple : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        // แสดงรูปใหม่ที่เลือก
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ]
        // แสดงรูปเดิมถ้าไม่มีรูปใหม่และไม่ได้ลบ
        else if (_currentImageUrl != null && !_removeCurrentImage) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _currentImageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('ไม่สามารถโหลดรูปภาพได้'),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'รูปเดิม',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ปุ่มเลือกรูป
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedImage != null ||
                          (_currentImageUrl != null && !_removeCurrentImage)
                      ? Icons.edit
                      : Icons.add_photo_alternate,
                  size: 32,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedImage != null ||
                          (_currentImageUrl != null && !_removeCurrentImage)
                      ? 'เปลี่ยนรูปภาพ'
                      : 'เพิ่มรูปภาพ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
