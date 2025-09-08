import 'package:flutter/material.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/theme/Color.dart';

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

  // Theme Colors

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
    _currentImageUrl = widget.complaint.complaintImg;
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
      _showSnackBar('ไม่สามารถโหลดประเภทร้องเรียนได้: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? ThemeColors.clayOrange
            : ThemeColors.oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: ThemeColors.ivoryWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: ThemeColors.warmStone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildImageOption(Icons.photo_camera_rounded, 'ถ่ายรูป', () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                }),
                _buildImageOption(
                  Icons.photo_library_rounded,
                  'เลือกจากแกลเลอรี่',
                  () {
                    Navigator.of(context).pop();
                    _getImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImage != null ||
                    (_currentImageUrl != null && !_removeCurrentImage))
                  _buildImageOption(Icons.delete_rounded, 'ลบรูปภาพ', () {
                    Navigator.of(context).pop();
                    _removeImage();
                  }, isDelete: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDelete = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDelete
            ? ThemeColors.clayOrange.withOpacity(0.1)
            : ThemeColors.beige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDelete
                ? ThemeColors.clayOrange.withOpacity(0.2)
                : ThemeColors.softBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDelete ? ThemeColors.clayOrange : ThemeColors.softBrown,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDelete ? ThemeColors.clayOrange : ThemeColors.softBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e', isError: true);
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
      await ComplaintDomain.update(
        complaintId: widget.complaint.complaintId!,
        houseId: widget.complaint.houseId,
        typeComplaint: _selectedTypeId,
        header: _headerController.text.trim(),
        description: _descriptionController.text.trim(),
        level: widget.complaint.level,
        isPrivate: _isPrivate,
        status: widget.complaint.status,
        imageFile: _selectedImage,
        // ส่งรูปใหม่ (ถ้ามี)
        removeImage: _removeCurrentImage, // flag สำหรับลบรูป
      );

      _showSnackBar('แก้ไขร้องเรียนสำเร็จ');
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        title: const Text(
          'แก้ไขร้องเรียน',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSubmitting)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColors.ivoryWhite,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingTypes
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColors.softBrown,
                    ),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // Header Input
                    _buildInputSection(
                      'หัวข้อร้องเรียน',
                      Icons.title_rounded,
                      _buildHeaderInput(),
                    ),
                    const SizedBox(height: 20),

                    // Description Input
                    _buildInputSection(
                      'รายละเอียด',
                      Icons.description_rounded,
                      _buildDescriptionInput(),
                    ),
                    const SizedBox(height: 20),

                    // Type Dropdown
                    _buildInputSection(
                      'ประเภทร้องเรียน',
                      Icons.category_rounded,
                      _buildTypeDropdown(),
                    ),
                    const SizedBox(height: 20),

                    // Image Picker
                    _buildInputSection(
                      'รูปภาพประกอบ (ไม่บังคับ)',
                      Icons.image_rounded,
                      _buildImagePicker(),
                    ),
                    const SizedBox(height: 20),

                    // Privacy Switch
                    _buildPrivacyCard(),
                    const SizedBox(height: 32),

                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.softTerracotta.withOpacity(0.15),
            ThemeColors.burntOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    color: ThemeColors.burntOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: ThemeColors.burntOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ข้อมูลร้องเรียน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'สถานะ',
              _getStatusText(widget.complaint.status),
              color: _getStatusColor(widget.complaint.status),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'วันที่สร้าง',
              _formatDate(widget.complaint.createAt),
            ),
            if (widget.complaint.updateAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'อัพเดทล่าสุด',
                _formatDate(widget.complaint.updateAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              color: ThemeColors.earthClay,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? ThemeColors.softBrown,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(String title, IconData icon, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ThemeColors.beige,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: ThemeColors.softBrown, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInput() {
    return TextFormField(
      controller: _headerController,
      style: TextStyle(color: ThemeColors.softBrown),
      decoration: InputDecoration(
        hintText: 'กรุณาระบุหัวข้อร้องเรียน',
        hintStyle: TextStyle(color: ThemeColors.earthClay.withOpacity(0.6)),
        filled: true,
        fillColor: ThemeColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.focusedBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.clayOrange),
        ),
        contentPadding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(color: ThemeColors.softBrown),
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'กรุณาระบุรายละเอียดของปัญหา',
        hintStyle: TextStyle(color: ThemeColors.earthClay.withOpacity(0.6)),
        filled: true,
        fillColor: ThemeColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.focusedBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.clayOrange),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
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
    );
  }

  Widget _buildTypeDropdown() {
    if (_complaintTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeColors.warmStone.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'ไม่พบข้อมูลประเภทร้องเรียน',
          style: TextStyle(color: ThemeColors.earthClay),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedTypeId == 0 ? null : _selectedTypeId,
      style: TextStyle(color: ThemeColors.softBrown),
      decoration: InputDecoration(
        hintText: 'เลือกประเภทร้องเรียน',
        hintStyle: TextStyle(color: ThemeColors.earthClay.withOpacity(0.6)),
        filled: true,
        fillColor: ThemeColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.focusedBrown, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      items: _complaintTypes.map<DropdownMenuItem<int>>((map) {
        final int typeId = map['type_id'] as int;
        final String typeName = map['type'] ?? 'ไม่ระบุ';

        return DropdownMenuItem<int>(
          value: typeId,
          child: Text(typeName, style: TextStyle(color: ThemeColors.softBrown)),
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
      dropdownColor: ThemeColors.ivoryWhite,
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          'ร้องเรียนแบบส่วนตัว',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'เฉพาะบ้านของคุณเท่านั้นที่เห็นได้',
            style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
          ),
        ),
        value: _isPrivate,
        onChanged: (value) {
          setState(() {
            _isPrivate = value;
          });
        },
        activeColor: ThemeColors.burntOrange,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isPrivate
                ? ThemeColors.burntOrange.withOpacity(0.1)
                : ThemeColors.warmStone.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: _isPrivate ? ThemeColors.burntOrange : ThemeColors.earthClay,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_selectedImage != null) ...[
          _buildImagePreview(),
          const SizedBox(height: 16),
        ] else if (_currentImageUrl != null && !_removeCurrentImage) ...[
          _buildCurrentImage(),
          const SizedBox(height: 16),
        ],
        _buildImagePickerButton(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
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
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'รูปใหม่',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: ThemeColors.clayOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => setState(() => _selectedImage = null),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BuildImage(
              imagePath: _currentImageUrl!,
              tablePath: "complaint",
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.burntOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'รูปเดิม',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButton() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(
            color: ThemeColors.softBorder,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: ThemeColors.inputFill,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.softBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _selectedImage != null ||
                        (_currentImageUrl != null && !_removeCurrentImage)
                    ? Icons.edit_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 32,
                color: ThemeColors.softBrown,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedImage != null ||
                      (_currentImageUrl != null && !_removeCurrentImage)
                  ? 'เปลี่ยนรูปภาพ'
                  : 'เพิ่มรูปภาพ',
              style: TextStyle(
                color: ThemeColors.softBrown,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isSubmitting
              ? [ThemeColors.warmStone, ThemeColors.warmStone]
              : [ThemeColors.burntOrange, ThemeColors.softTerracotta],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSubmitting
            ? []
            : [
                BoxShadow(
                  color: ThemeColors.burntOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _updateComplaint,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeColors.ivoryWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'กำลังบันทึก...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.ivoryWhite,
                    ),
                  ),
                ],
              )
            : Text(
                'บันทึกการแก้ไข',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.ivoryWhite,
                ),
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
        return ThemeColors.burntOrange;
      case 'received':
        return ThemeColors.softTerracotta;
      case 'in_progress':
        return ThemeColors.clayOrange;
      case 'on_hold':
        return ThemeColors.warmStone;
      case 'resolved':
        return ThemeColors.oliveGreen;
      case 'rejected':
        return ThemeColors.clayOrange;
      default:
        return ThemeColors.burntOrange;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const monthNames = [
        '',
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      return '${date.day} ${monthNames[date.month]} ${date.year + 543} เวลา ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
