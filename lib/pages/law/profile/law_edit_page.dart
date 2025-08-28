import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/domains/law_domain.dart';

class LawEditPage extends StatefulWidget {
  final int villageId;
  final LawModel? law; // null = สร้างใหม่, มีค่า = แก้ไข

  const LawEditPage({
    Key? key,
    required this.villageId,
    this.law,
  }) : super(key: key);

  @override
  State<LawEditPage> createState() => _LawEditPageState();
}

class _LawEditPageState extends State<LawEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender = 'M';
  DateTime? _selectedBirthDate;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;
  bool _isLoading = false;
  int _currentUserId = 1; // จะต้องได้มาจาก session จริง

  // Theme Colors
  static const Color _softBrown = Color(0xFFA47551);
  static const Color _ivoryWhite = Color(0xFFFFFDF6);
  static const Color _beige = Color(0xFFF5F0E1);
  static const Color _sandyTan = Color(0xFFD8CAB8);
  static const Color _earthClay = Color(0xFFBFA18F);
  static const Color _warmStone = Color(0xFFC7B9A5);
  static const Color _oliveGreen = Color(0xFFA3B18A);
  static const Color _burntOrange = Color(0xFFE08E45);
  static const Color _softBorder = Color(0xFFD0C4B0);
  static const Color _focusedBrown = Color(0xFF916846);
  static const Color _inputFill = Color(0xFFFBF9F3);

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    if (widget.law != null) {
      final law = widget.law!;
      _firstNameController.text = law.firstName ?? '';
      _lastNameController.text = law.lastName ?? '';
      _phoneController.text = law.phone ?? '';
      _addressController.text = law.address ?? '';
      _selectedGender = law.gender ?? 'M';
      _currentImageUrl = law.img;

      if (law.birthDate != null && law.birthDate!.isNotEmpty) {
        try {
          _selectedBirthDate = DateTime.parse(law.birthDate!);
        } catch (e) {
          _selectedBirthDate = null;
        }
      }
    }
  }

  bool get _isEditMode => widget.law != null;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // แสดง dialog ให้เลือกว่าจะเอารูปจากกล้องหรือแกลเลอรี่
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _ivoryWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'เลือกรูปภาพ',
            style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: _burntOrange),
                title: Text('กล้อง', style: TextStyle(color: _earthClay)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: _burntOrange),
                title: Text('แกลเลอรี่', style: TextStyle(color: _earthClay)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
            _removeCurrentImage = false;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('ไม่สามารถเลือกรูปภาพได้: $e');
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _softBrown,
              onPrimary: _ivoryWhite,
              surface: _ivoryWhite,
              onSurface: _earthClay,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _removeCurrentImage = true;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold)
        ),
        content: Text(message, style: TextStyle(color: _earthClay)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง', style: TextStyle(color: _burntOrange)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _oliveGreen,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _saveLaw() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      _showErrorDialog('กรุณาเลือกวันเกิด');
      return;
    }

    // ตรวจสอบอายุไม่ให้เกิน 120 ปี
    final now = DateTime.now();
    final age = now.year - _selectedBirthDate!.year;
    if (age > 120 || age < 0) {
      _showErrorDialog('วันเกิดไม่ถูกต้อง กรุณาเลือกวันเกิดที่ถูกต้อง');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final birthDateString = _selectedBirthDate!.toIso8601String().substring(0, 10);

      LawModel? result;

      if (_isEditMode) {
        // แก้ไข
        result = await LawDomain.update(
          lawId: widget.law!.lawId,
          villageId: widget.villageId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: birthDateString,
          phone: _phoneController.text.trim(),
          gender: _selectedGender!,
          address: _addressController.text.trim(),
          userId: _currentUserId,
          imageFile: _selectedImage,
          removeImage: _removeCurrentImage,
        );
      } else {
        // สร้างใหม่
        result = await LawDomain.create(
          villageId: widget.villageId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: birthDateString,
          phone: _phoneController.text.trim(),
          gender: _selectedGender!,
          address: _addressController.text.trim(),
          userId: _currentUserId,
          imageFile: _selectedImage,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result != null) {
        _showSuccessDialog(_isEditMode ? 'อัปเดตข้อมูลสำเร็จ' : 'บันทึกข้อมูลสำเร็จ');
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(_isEditMode ? 'ไม่สามารถอัปเดตข้อมูลได้' : 'ไม่สามารถบันทึกข้อมูลได้');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('เกิดข้อผิดพลาด: $e');
    }
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Text(
          'รูปภาพประจำตัว',
          style: TextStyle(
            color: _softBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _sandyTan.withOpacity(0.3),
              borderRadius: BorderRadius.circular(70),
              border: Border.all(color: _softBorder, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _warmStone.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(70),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            )
                : (_currentImageUrl != null && !_removeCurrentImage)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(70),
              child: Image.network(
                _currentImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_burntOrange),
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person_add,
                    size: 50,
                    color: _warmStone,
                  );
                },
              ),
            )
                : Icon(
              Icons.person_add,
              size: 50,
              color: _warmStone,
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt, size: 18),
              label: Text('เลือกรูป'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _burntOrange,
                foregroundColor: _ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            if (_selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage))
              SizedBox(width: 12),
            if (_selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage))
              OutlinedButton.icon(
                onPressed: _removeImage,
                icon: Icon(Icons.delete, size: 18),
                label: Text('ลบรูป'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    IconData? prefixIcon,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: _softBrown,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            children: required ? [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red[700]),
              ),
            ] : [],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: _earthClay, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _earthClay.withOpacity(0.6)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _warmStone)
                : null,
            filled: true,
            fillColor: _inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _softBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _softBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _focusedBrown, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[700]!, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[700]!, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  String _formatThaiDate(DateTime date) {
    final List<String> thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivoryWhite,
      appBar: AppBar(
        backgroundColor: _softBrown,
        elevation: 0,
        title: Text(
          _isEditMode ? 'แก้ไขข้อมูล' : 'เพิ่มข้อมูลใหม่',
          style: TextStyle(
            color: _ivoryWhite,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: _ivoryWhite),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              _buildImageSection(),
              SizedBox(height: 32),

              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'ชื่อ',
                      hint: 'กรอกชื่อ',
                      prefixIcon: Icons.person,
                      required: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อ';
                        }
                        if (value.trim().length < 2) {
                          return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'นามสกุล',
                      hint: 'กรอกนามสกุล',
                      required: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกนามสกุล';
                        }
                        if (value.trim().length < 2) {
                          return 'นามสกุลต้องมีอย่างน้อย 2 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Gender and Birth Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'เพศ',
                            style: TextStyle(
                              color: _softBrown,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _inputFill,
                            prefixIcon: Icon(Icons.people, color: _warmStone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _softBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _softBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _focusedBrown, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          dropdownColor: _ivoryWhite,
                          style: TextStyle(color: _earthClay, fontSize: 16),
                          items: [
                            DropdownMenuItem(value: 'M', child: Text('ชาย')),
                            DropdownMenuItem(value: 'F', child: Text('หญิง')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาเลือกเพศ';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'วันเกิด',
                            style: TextStyle(
                              color: _softBrown,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectBirthDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _inputFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _softBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cake, color: _warmStone),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedBirthDate != null
                                        ? _formatThaiDate(_selectedBirthDate!)
                                        : 'เลือกวันเกิด',
                                    style: TextStyle(
                                      color: _selectedBirthDate != null
                                          ? _earthClay
                                          : _earthClay.withOpacity(0.6),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today, color: _warmStone, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'เบอร์โทรศัพท์',
                hint: 'กรอกเบอร์โทรศัพท์ (เช่น 0812345678)',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // ลบช่องว่างและเครื่องหมายพิเศษ
                    final cleanedPhone = value.replaceAll(RegExp(r'[^\d]'), '');

                    if (cleanedPhone.length < 9 || cleanedPhone.length > 10) {
                      return 'เบอร์โทรต้องมี 9-10 หลัก';
                    }

                    if (!cleanedPhone.startsWith('0') && cleanedPhone.length == 10) {
                      return 'เบอร์โทรต้องขึ้นต้นด้วย 0';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'ที่อยู่',
                hint: 'กรอกที่อยู่ที่ติดต่อได้',
                maxLines: 3,
                prefixIcon: Icons.location_on,
              ),
              SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveLaw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _burntOrange,
                  foregroundColor: _ivoryWhite,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        valueColor: AlwaysStoppedAnimation<Color>(_ivoryWhite),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _isEditMode ? 'กำลังอัปเดต...' : 'กำลังบันทึก...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    : Text(
                  _isEditMode ? 'อัปเดตข้อมูล' : 'บันทึกข้อมูล',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _earthClay,
                  side: BorderSide(color: _softBorder, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ยกเลิก',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}