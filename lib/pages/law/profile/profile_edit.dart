import 'package:flutter/material.dart';
import 'package:fullproject/models/law_model.dart';
import '../../../domains/law_domain.dart';

class LawProfileEditPage extends StatefulWidget {
  final int lawId;

  const LawProfileEditPage({
    super.key,
    required this.lawId,
  });

  @override
  State<LawProfileEditPage> createState() => _LawProfileEditPageState();
}

class _LawProfileEditPageState extends State<LawProfileEditPage> {
  LawModel? _lawModel;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers สำหรับฟอร์ม
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedGender;

  // Controllers สำหรับเปลี่ยนรหัสผ่าน
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _loadLawProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadLawProfile() async {
    setState(() => _isLoading = true);

    try {
      final law = await LawDomain.getById(widget.lawId);

      if (mounted) {
        setState(() {
          _lawModel = law;
          _isLoading = false;
        });

        if (_lawModel != null) {
          _updateControllers();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      }
    }
  }

  void _updateControllers() {
    _firstNameController.text = _lawModel?.firstName ?? '';
    _lastNameController.text = _lawModel?.lastName ?? '';
    _phoneController.text = _lawModel?.phone ?? '';
    _addressController.text = _lawModel?.address ?? '';
    _selectedBirthDate = _lawModel?.birthDate;
    _selectedGender = _lawModel?.gender;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _lawModel == null) return;

    setState(() => _isSaving = true);

    try {
      // ตรวจสอบเบอร์โทรซ้ำ
      final isPhoneExists = await LawDomain.isPhoneExists(
        _phoneController.text.trim(),
        excludeLawId: widget.lawId,
      );

      if (isPhoneExists) {
        _showErrorSnackbar('เบอร์โทรศัพท์นี้ถูกใช้แล้ว');
        setState(() => _isSaving = false);
        return;
      }

      final success = await LawDomain.updateBasicInfo(
        lawId: widget.lawId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          _showSuccessSnackbar('บันทึกข้อมูลเรียบร้อยแล้ว');
          Navigator.pop(context, true); // ส่งค่า true กลับไปว่าแก้ไขแล้ว
        } else {
          _showErrorSnackbar('เกิดข้อผิดพลาดในการบันทึกข้อมูล');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackbar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackbar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('รหัสผ่านใหม่ไม่ตรงกัน');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackbar('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }

    try {
      final success = await LawDomain.changePassword(
        userId: _lawModel!.userId,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว');
          setState(() => _showPasswordSection = false);
          _clearPasswordFields();
        } else {
          _showErrorSnackbar('รหัสผ่านปัจจุบันไม่ถูกต้อง');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1930),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      locale: const Locale('th', 'TH'),
    );

    if (date != null) {
      setState(() => _selectedBirthDate = date);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _lawModel != null && !_isSaving)
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lawModel == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Basic Info Section
              _buildBasicInfoSection(),
              const SizedBox(height: 24),

              // Password Section
              _buildPasswordSection(),
              const SizedBox(height: 24),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: _lawModel!.hasProfileImage
                  ? NetworkImage(_lawModel!.profileImageUrl!)
                  : null,
              child: !_lawModel!.hasProfileImage
                  ? Text(
                _lawModel!.initials,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lawModel!.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_lawModel!.lawId}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: เพิ่มการเปลี่ยนรูปโปรไฟล์
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ฟีเจอร์เปลี่ยนรูปโปรไฟล์ยังไม่พร้อม')),
                );
              },
              icon: const Icon(Icons.camera_alt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลส่วนตัว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ชื่อจริง
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อจริง *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุชื่อจริง';
                }
                if (value.trim().length < 2) {
                  return 'ชื่อจริงต้องมีอย่างน้อย 2 ตัวอักษร';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // นามสกุล
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'นามสกุล *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุนามสกุล';
                }
                if (value.trim().length < 2) {
                  return 'นามสกุลต้องมีอย่างน้อย 2 ตัวอักษร';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // เบอร์โทร
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุเบอร์โทรศัพท์';
                }
                final phone = value.trim().replaceAll(RegExp(r'[^\d]'), '');
                if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
                  return 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ที่อยู่
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'ที่อยู่',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // วันเกิด
            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันเกิด',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedBirthDate != null
                      ? LawModel(
                    lawId: 0,
                    villageId: 0,
                    userId: 0,
                    birthDate: _selectedBirthDate,
                  ).birthDateDisplay
                      : 'เลือกวันเกิด',
                  style: TextStyle(
                    color: _selectedBirthDate != null
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // เพศ
            const Text('เพศ', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('ชาย'),
                    value: 'M',
                    groupValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('หญิง'),
                    value: 'F',
                    groupValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เปลี่ยนรหัสผ่าน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _showPasswordSection,
                  onChanged: (value) {
                    setState(() => _showPasswordSection = value);
                    if (!value) _clearPasswordFields();
                  },
                ),
              ],
            ),

            if (_showPasswordSection) ...[
              const SizedBox(height: 16),

              // รหัสผ่านปัจจุบัน
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่านปัจจุบัน *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // รหัสผ่านใหม่
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่านใหม่ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'อย่างน้อย 6 ตัวอักษร',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // ยืนยันรหัสผ่าน
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'ยืนยันรหัสผ่านใหม่ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_clock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // ปุ่มเปลี่ยนรหัสผ่าน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.security),
                  label: const Text('เปลี่ยนรหัสผ่าน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}