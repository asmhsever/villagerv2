// lib/pages/law/complaint/complaint_form.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedHouseId;
  int? _selectedTypeId;
  String _selectedLevel = '1';
  bool _isPrivate = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _houses = [];
  List<ComplaintTypeModel> _complaintTypes = [];

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

  // รายการระดับความสำคัญ
  final List<Map<String, dynamic>> _levels = [
    {'value': '1', 'label': 'ต่ำ', 'color': oliveGreen, 'icon': Icons.info_outline},
    {'value': '2', 'label': 'ปานกลาง', 'color': Colors.orange, 'icon': Icons.warning_amber_outlined},
    {'value': '3', 'label': 'สูง', 'color': burntOrange, 'icon': Icons.priority_high},
    {'value': '4', 'label': 'ฉุกเฉิน', 'color': Colors.red, 'icon': Icons.emergency},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final user = await AuthService.getCurrentUser();

      // โหลดรายการบ้าน
      final houses = await SupabaseConfig.client
          .from('house')
          .select('house_id, house_number')
          .eq('village_id', user.villageId)
          .order('house_number');

      // โหลดประเภทร้องเรียน
      final types = await ComplaintTypeDomain.getAll();

      if (mounted) {
        setState(() {
          _houses = List<Map<String, dynamic>>.from(houses);
          _complaintTypes = types;
        });
      }
    } catch (e) {
      print('Error fetching initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: burntOrange,
          ),
        );
      }
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

    if (_selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กรุณาเลือกบ้าน'),
          backgroundColor: burntOrange,
        ),
      );
      return;
    }

    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กรุณาเลือกประเภทร้องเรียน'),
          backgroundColor: burntOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ComplaintDomain.create(
        houseId: _selectedHouseId!,
        typeComplaint: _selectedTypeId!,
        header: _headerController.text.trim(),
        description: _descriptionController.text.trim(),
        level: _selectedLevel,
        isPrivate: _isPrivate,
        imageFile: _imageFile,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ส่งร้องเรียนสำเร็จ'),
            backgroundColor: oliveGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('ไม่สามารถส่งร้องเรียนได้');
      }
    } catch (e) {
      print('Error creating complaint: $e');
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

  String _getLevelLabel(String level) {
    return _levels.firstWhere(
          (l) => l['value'] == level,
      orElse: () => {'label': 'ไม่ระบุ'},
    )['label'];
  }

  Color _getLevelColor(String level) {
    return _levels.firstWhere(
          (l) => l['value'] == level,
      orElse: () => {'color': earthClay},
    )['color'];
  }

  IconData _getLevelIcon(String level) {
    return _levels.firstWhere(
          (l) => l['value'] == level,
      orElse: () => {'icon': Icons.help_outline},
    )['icon'];
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
      title: 'รูปภาพประกอบ (ไม่บังคับ)',
      icon: Icons.image,
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
          'รองรับไฟล์ JPG, PNG ขนาดไม่เกิน 5MB',
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
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
        elevation: 0,
        title: const Text(
          'ส่งร้องเรียน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _submit,
            tooltip: 'ส่งร้องเรียน',
          ),
        ],
      ),
      body: _houses.isEmpty || _complaintTypes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: softBrown),
            const SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(color: earthClay),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ข้อมูลพื้นฐาน
              _buildSectionCard(
                title: 'ข้อมูลพื้นฐาน',
                icon: Icons.info_outline,
                children: [
                  // เลือกบ้าน
                  DropdownButtonFormField<int>(
                    value: _houses.any((h) => h['house_id'] == _selectedHouseId)
                        ? _selectedHouseId
                        : null,
                    items: _houses.map((house) {
                      return DropdownMenuItem<int>(
                        value: house['house_id'],
                        child: Text('บ้านเลขที่ ${house['house_number']}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedHouseId = val),
                    decoration: InputDecoration(
                      labelText: 'เลือกบ้าน',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: warmStone),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: softBrown, width: 2),
                      ),
                      prefixIcon: Icon(Icons.home, color: earthClay),
                      fillColor: ivoryWhite,
                      filled: true,
                    ),
                    validator: (value) => value == null ? 'กรุณาเลือกบ้าน' : null,
                  ),

                  const SizedBox(height: 16),

                  // เลือกประเภทร้องเรียน
                  DropdownButtonFormField<int>(
                    value: _complaintTypes.any((t) => t.typeId == _selectedTypeId)
                        ? _selectedTypeId
                        : null,
                    items: _complaintTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type.typeId,
                        child: Text(type.type ?? 'ไม่ระบุ'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTypeId = val),
                    decoration: InputDecoration(
                      labelText: 'ประเภทร้องเรียน',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: warmStone),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: softBrown, width: 2),
                      ),
                      prefixIcon: Icon(Icons.category, color: earthClay),
                      fillColor: ivoryWhite,
                      filled: true,
                    ),
                    validator: (value) => value == null ? 'กรุณาเลือกประเภทร้องเรียน' : null,
                  ),
                ],
              ),

              // รายละเอียดร้องเรียน
              _buildSectionCard(
                title: 'รายละเอียดร้องเรียน',
                icon: Icons.report_problem,
                children: [
                  // หัวข้อ
                  TextFormField(
                    controller: _headerController,
                    decoration: InputDecoration(
                      labelText: 'หัวข้อร้องเรียน',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: warmStone),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: softBrown, width: 2),
                      ),
                      prefixIcon: Icon(Icons.title, color: earthClay),
                      fillColor: ivoryWhite,
                      filled: true,
                      hintText: 'ระบุหัวข้อร้องเรียนโดยย่อ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกหัวข้อร้องเรียน';
                      }
                      if (value.trim().length < 5) {
                        return 'หัวข้อต้องมีอย่างน้อย 5 ตัวอักษร';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // รายละเอียด
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียด',
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
                      hintText: 'อธิบายรายละเอียดปัญหาที่ต้องการร้องเรียน',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกรายละเอียดร้องเรียน';
                      }
                      if (value.trim().length < 10) {
                        return 'รายละเอียดต้องมีอย่างน้อย 10 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // ระดับความสำคัญ
              _buildSectionCard(
                title: 'ระดับความสำคัญ',
                icon: Icons.priority_high,
                children: [
                  Column(
                    children: _levels.map((level) {
                      final isSelected = _selectedLevel == level['value'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedLevel = level['value']),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? level['color'].withValues(alpha: 0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? level['color']
                                    : warmStone,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: level['value'],
                                  groupValue: _selectedLevel,
                                  onChanged: (val) => setState(() => _selectedLevel = val!),
                                  activeColor: level['color'],
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  level['icon'],
                                  color: level['color'],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ระดับ ${level['label']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? level['color']
                                              : softBrown,
                                        ),
                                      ),
                                      Text(
                                        _getLevelDescription(level['value']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: earthClay,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // รูปภาพประกอบ
              _buildImageSection(),

              // การตั้งค่า
              _buildSectionCard(
                title: 'การตั้งค่า',
                icon: Icons.settings,
                children: [
                  SwitchListTile(
                    title: Text(
                      'ร้องเรียนแบบส่วนตัว',
                      style: TextStyle(
                        color: softBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _isPrivate
                          ? 'เฉพาะเจ้าหน้าที่เท่านั้นที่จะเห็นร้องเรียนนี้'
                          : 'ชาวบ้านในหมู่บ้านสามารถเห็นร้องเรียนนี้ได้',
                      style: TextStyle(
                        fontSize: 12,
                        color: earthClay,
                      ),
                    ),
                    value: _isPrivate,
                    onChanged: (value) => setState(() => _isPrivate = value),
                    activeColor: softBrown,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ปุ่มส่งร้องเรียน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burntOrange,
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
                      const Text('กำลังส่งร้องเรียน...'),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      const SizedBox(width: 8),
                      const Text(
                        'ส่งร้องเรียน',
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

  String _getLevelDescription(String level) {
    switch (level) {
      case '1':
        return 'ปัญหาทั่วไป ไม่เร่งด่วน';
      case '2':
        return 'ปัญหาที่ควรได้รับการแก้ไข';
      case '3':
        return 'ปัญหาที่ต้องแก้ไขโดยเร็ว';
      case '4':
        return 'ปัญหาเร่งด่วนที่ต้องแก้ไขทันที';
      default:
        return '';
    }
  }
}