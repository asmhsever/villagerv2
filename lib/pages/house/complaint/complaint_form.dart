import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/theme/Color.dart';

class HouseComplaintFormPage extends StatefulWidget {
  final int houseId;

  const HouseComplaintFormPage({super.key, required this.houseId});

  @override
  State<HouseComplaintFormPage> createState() => _HouseComplaintFormPageState();
}

class _HouseComplaintFormPageState extends State<HouseComplaintFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedTypeId = 0;
  bool _isPrivate = false;

  // Platform support variables
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  bool _isSubmitting = false;

  List<Map<String, dynamic>> _complaintTypes = [];
  bool _isLoadingTypes = true;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Theme Colors

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    _loadComplaintTypes();
    _slideController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
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
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError
            ? ThemeColors.clayOrange
            : ThemeColors.oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: ThemeColors.ivoryWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.earthClay.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  decoration: BoxDecoration(
                    color: ThemeColors.warmStone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeColors.softBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.image_rounded,
                          color: ThemeColors.softBrown,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'เลือกรูปภาพ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.softBrown,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                _buildImageOption(
                  Icons.photo_camera_rounded,
                  'ถ่ายรูป',
                  'ใช้กล้องเพื่อถ่ายรูปใหม่',
                  () {
                    Navigator.of(context).pop();
                    _getImage(ImageSource.camera);
                  },
                ),
                _buildImageOption(
                  Icons.photo_library_rounded,
                  'เลือกจากแกลเลอรี่',
                  'เลือกรูปภาพที่มีอยู่แล้ว',
                  () {
                    Navigator.of(context).pop();
                    _getImage(ImageSource.gallery);
                  },
                ),
                if (_hasSelectedImage())
                  _buildImageOption(
                    Icons.delete_rounded,
                    'ลบรูปภาพ',
                    'ลบรูปภาพที่เลือกไว้',
                    () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                      });
                    },
                    isDelete: true,
                  ),
                const SizedBox(height: 24),
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
    String subtitle,
    VoidCallback onTap, {
    bool isDelete = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDelete
            ? ThemeColors.clayOrange.withOpacity(0.05)
            : ThemeColors.beige,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelete
              ? ThemeColors.clayOrange.withOpacity(0.2)
              : ThemeColors.softBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDelete
                        ? ThemeColors.clayOrange.withOpacity(0.15)
                        : ThemeColors.softBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDelete
                        ? ThemeColors.clayOrange
                        : ThemeColors.softBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDelete
                              ? ThemeColors.clayOrange
                              : ThemeColors.softBrown,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDelete
                              ? ThemeColors.clayOrange.withOpacity(0.7)
                              : ThemeColors.earthClay,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDelete
                      ? ThemeColors.clayOrange.withOpacity(0.5)
                      : ThemeColors.earthClay.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _selectedImageFile = null;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
            _selectedImageName = null;
          });
        }
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e', isError: true);
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
      dynamic imageFile;

      // เตรียม imageFile สำหรับส่งไปยัง function
      if (_hasSelectedImage()) {
        if (kIsWeb && _selectedImageBytes != null) {
          imageFile = _selectedImageBytes!;
        } else if (!kIsWeb && _selectedImageFile != null) {
          imageFile = _selectedImageFile!;
        }
      }

      final createdComplaint = await ComplaintDomain.create(
        houseId: widget.houseId,
        typeComplaint: _selectedTypeId,
        header: _headerController.text.trim(),
        description: _descriptionController.text.trim(),
        level: "1",
        isPrivate: _isPrivate,
        imageFile: imageFile, // ส่งรูปไปด้วย (ถ้ามี)
      );

      if (createdComplaint != null) {
        _showSnackBar('ส่งข้อมูลร้องเรียนสำเร็จ');
        Navigator.pop(context, true);
      } else {
        throw Exception('ไม่สามารถบันทึกข้อมูลได้');
      }
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
          'สร้างร้องเรียนใหม่',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
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
          ? _buildLoadingState()
          : SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _slideController,
                child: _buildForm(),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'กำลังโหลดข้อมูล...',
            style: TextStyle(
              color: ThemeColors.earthClay,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome Header
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Form Fields
            _buildFormCard(),
            const SizedBox(height: 24),

            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.burntOrange.withOpacity(0.1),
            ThemeColors.softTerracotta.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.feedback_rounded,
                    color: ThemeColors.burntOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สร้างร้องเรียนใหม่',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.softBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'บ้านเลขที่ ${widget.houseId}',
                        style: TextStyle(
                          fontSize: 16,
                          color: ThemeColors.earthClay,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Input
            _buildInputField(
              'หัวข้อร้องเรียน',
              Icons.title_rounded,
              _buildHeaderInput(),
              'สิ่งที่คุณต้องการร้องเรียน',
            ),
            const SizedBox(height: 24),

            // Description Input
            _buildInputField(
              'รายละเอียด',
              Icons.description_rounded,
              _buildDescriptionInput(),
              'อธิบายปัญหาที่เกิดขึ้นอย่างละเอียด',
            ),
            const SizedBox(height: 24),

            // Type Dropdown
            _buildInputField(
              'ประเภทร้องเรียน',
              Icons.category_rounded,
              _buildTypeDropdown(),
              'เลือกหมวดหมู่ที่เหมาะสม',
            ),
            const SizedBox(height: 24),

            // Image Picker
            _buildInputField(
              'รูปภาพประกอบ',
              Icons.image_rounded,
              _buildImagePicker(),
              'เพิ่มรูปภาพเพื่อประกอบการร้องเรียน (ไม่บังคับ)',
            ),
            const SizedBox(height: 24),

            // Privacy Switch
            _buildPrivacySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String title,
    IconData icon,
    Widget child,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ThemeColors.softBrown, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeColors.earthClay,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildHeaderInput() {
    return TextFormField(
      controller: _headerController,
      style: TextStyle(color: ThemeColors.softBrown, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'เช่น "ไฟฟ้าดับบ่อย" หรือ "เสียงดังจากเพื่อนบ้าน"',
        hintStyle: TextStyle(
          color: ThemeColors.earthClay.withOpacity(0.6),
          fontSize: 14,
        ),
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
      style: TextStyle(color: ThemeColors.softBrown, fontSize: 15),
      maxLines: 4,
      decoration: InputDecoration(
        hintText:
            'อธิบายปัญหาอย่างละเอียด เช่น เกิดเมื่อไหร่ กี่ครั้ง ส่งผลกระทบอย่างไร',
        hintStyle: TextStyle(
          color: ThemeColors.earthClay.withOpacity(0.6),
          fontSize: 14,
        ),
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
          border: Border.all(color: ThemeColors.warmStone.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: ThemeColors.warmStone, size: 20),
            const SizedBox(width: 12),
            Text(
              'ไม่พบข้อมูลประเภทร้องเรียน',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedTypeId == 0 ? null : _selectedTypeId,
      style: TextStyle(color: ThemeColors.softBrown, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'กรุณาเลือกประเภทร้องเรียน',
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
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: ThemeColors.earthClay,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_hasSelectedImage()) ...[
          _buildImagePreview(),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.memory(
                    _selectedImageBytes!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    _selectedImageFile!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: ThemeColors.ivoryWhite,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'รูปที่เลือก',
                    style: TextStyle(
                      color: ThemeColors.ivoryWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: ThemeColors.clayOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.clayOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: ThemeColors.ivoryWhite,
                  size: 16,
                ),
                onPressed: () => setState(() {
                  _selectedImageFile = null;
                  _selectedImageBytes = null;
                  _selectedImageName = null;
                }),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                  _hasSelectedImage()
                      ? Icons.edit_rounded
                      : Icons.add_photo_alternate_rounded,
                  size: 32,
                  color: ThemeColors.softBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _hasSelectedImage() ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'แตะเพื่อเลือกรูปจากแกลเลอรี่หรือถ่ายรูปใหม่',
                style: TextStyle(color: ThemeColors.earthClay, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isPrivate
                    ? ThemeColors.burntOrange.withOpacity(0.15)
                    : ThemeColors.beige,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: _isPrivate
                    ? ThemeColors.burntOrange
                    : ThemeColors.earthClay,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ความเป็นส่วนตัว',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                  Text(
                    'เลือกว่าใครสามารถเห็นร้องเรียนนี้ได้บ้าง',
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeColors.earthClay,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _isPrivate
                ? ThemeColors.burntOrange.withOpacity(0.05)
                : ThemeColors.oliveGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPrivate
                  ? ThemeColors.burntOrange.withOpacity(0.2)
                  : ThemeColors.oliveGreen.withOpacity(0.2),
            ),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              _isPrivate ? 'ร้องเรียนแบบส่วนตัว' : 'ร้องเรียนแบบสาธารณะ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isPrivate
                    ? ThemeColors.burntOrange
                    : ThemeColors.oliveGreen,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _isPrivate
                    ? 'เฉพาะคุณและผู้ดูแลเท่านั้นที่เห็นได้'
                    : 'ทุกคนในหมู่บ้านสามารถเห็นได้',
                style: TextStyle(
                  color: _isPrivate
                      ? ThemeColors.burntOrange.withOpacity(0.7)
                      : ThemeColors.oliveGreen.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            activeColor: ThemeColors.burntOrange,
            inactiveThumbColor: ThemeColors.oliveGreen,
            inactiveTrackColor: ThemeColors.oliveGreen.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
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
                  color: ThemeColors.burntOrange.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitComplaint,
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
                    'กำลังส่งข้อมูล...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.ivoryWhite,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    color: ThemeColors.ivoryWhite,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ส่งข้อมูลร้องเรียน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.ivoryWhite,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
