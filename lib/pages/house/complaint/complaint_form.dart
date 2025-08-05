import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data'; // Add this import
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';

class HouseComplaintFormPage extends StatefulWidget {
  final int houseId;

  const HouseComplaintFormPage({super.key, required this.houseId});

  @override
  State<HouseComplaintFormPage> createState() => _HouseComplaintFormPageState();
}

class _HouseComplaintFormPageState extends State<HouseComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedTypeId = 0;
  bool _isPrivate = false;

  // Change these variables to support both platforms
  File? _selectedImageFile; // For mobile/desktop
  Uint8List? _selectedImageBytes; // For web
  String? _selectedImageName; // Store image name for web

  bool _isSubmitting = false;

  List<Map<String, dynamic>> _complaintTypes = [];
  bool _isLoadingTypes = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadComplaintTypes();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        if (types.isNotEmpty) {
          // ไม่กำหนดค่าเริ่มต้น ให้ผู้ใช้เลือกเอง
        }
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
              if (_hasSelectedImage()) // Updated condition
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'ลบรูปภาพ',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImageFile = null;
                      _selectedImageBytes = null;
                      _selectedImageName = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to check if image is selected
  bool _hasSelectedImage() {
    return kIsWeb ? _selectedImageBytes != null : _selectedImageFile != null;
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
        if (kIsWeb) {
          // For web: read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _selectedImageFile = null; // Clear file reference
          });
        } else {
          // For mobile/desktop: use file
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null; // Clear bytes reference
            _selectedImageName = null;
          });
        }
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

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // สร้าง ComplaintModel โดยยังไม่มีรูปภาพ
      final complaint = ComplaintModel(
        houseId: widget.houseId,
        typeComplaint: _selectedTypeId,
        createAt: DateTime.now().toIso8601String(),
        header: _headerController.text.trim(),
        description: _descriptionController.text.trim(),
        level: 0,
        isPrivate: _isPrivate,
        img: null,
        status: 'pending',
        updateAt: null,
      );

      // บันทึกข้อมูลผ่าน Domain เพื่อได้ complaint_id กลับมา
      final createdComplaint = await ComplaintDomain.create(complaint);

      if (createdComplaint != null) {
        String? imageUrl;

        // อัพโหลดรูปภาพถ้ามี โดยใช้ complaint_id ที่ได้จาก server
        if (_hasSelectedImage() && createdComplaint.complaintId != 0) {
          // You'll need to modify your SupabaseImage().uploadImage method
          // to handle both File and Uint8List
          if (kIsWeb && _selectedImageBytes != null) {
            // For web: pass bytes instead of file
            // You might need to modify your upload method to accept bytes
            imageUrl = await SupabaseImage().uploadImage(
              imageFile: _selectedImageBytes!,
              tableName: "complaint",
              rowName: "complaint_id",
              rowImgName: "img",
              rowKey: createdComplaint.complaintId,
            );
          } else if (!kIsWeb && _selectedImageFile != null) {
            // For mobile/desktop: use existing file upload
            imageUrl = await SupabaseImage().uploadImage(
              imageFile: _selectedImageFile!,
              tableName: "complaint",
              rowName: "complaint_id",
              rowImgName: "img",
              rowKey: createdComplaint.complaintId,
            );
          }

          // อัพเดทข้อมูลให้มีรูปภาพ
          if (imageUrl != null) {
            final updatedComplaint = ComplaintModel(
              complaintId: createdComplaint.complaintId,
              houseId: createdComplaint.houseId,
              typeComplaint: createdComplaint.typeComplaint,
              createAt: createdComplaint.createAt,
              header: createdComplaint.header,
              description: createdComplaint.description,
              level: createdComplaint.level,
              isPrivate: createdComplaint.isPrivate,
              img: imageUrl,
              status: createdComplaint.status,
              updateAt: DateTime.now().toIso8601String(),
            );

            // อัพเดทข้อมูลในฐานข้อมูล
            await ComplaintDomain.update(
              complaintId: createdComplaint.complaintId!,
              updatedComplaint: updatedComplaint,
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งข้อมูลร้องเรียนสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception('ไม่สามารถบันทึกข้อมูลได้');
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
        title: const Text('ร้องเรียนใหม่'),
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

                    // ประเภทร้องเรียน
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

                    // ปุ่มส่ง
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitComplaint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC7B9A5),
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
                                  Text('กำลังส่งข้อมูล...'),
                                ],
                              )
                            : const Text(
                                'ส่งข้อมูลร้องเรียน',
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
          print('Selected Type ID: $newValue');
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

  // Updated image picker widget to support both platforms
  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_hasSelectedImage()) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.memory(
                        _selectedImageBytes!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        _selectedImageFile!,
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
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
                  _hasSelectedImage() ? Icons.edit : Icons.add_photo_alternate,
                  size: 32,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasSelectedImage() ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
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
