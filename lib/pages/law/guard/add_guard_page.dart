// lib/pages/add_guard_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fullproject/config/supabase_config.dart'; // kept if used elsewhere
import 'package:fullproject/domains/guard_domain.dart';

class AddGuardPage extends StatefulWidget {
  final int villageId;

  const AddGuardPage({super.key, required this.villageId});

  @override
  State<AddGuardPage> createState() => _AddGuardPageState();
}

class _AddGuardPageState extends State<AddGuardPage>
    with TickerProviderStateMixin {
  // Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color mutedBurntSienna = Color(0xFFC8755A);
  static const Color danger = Color(0xFFDC3545);

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Image Picker - Web & Mobile
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // Mobile
  Uint8List? _webImage; // Web

  // Animations
  late final AnimationController _fadeController;
  late final AnimationController _shakeController;
  late final Animation<Offset> _shakeAnimation;

  // Form State
  bool _isLoading = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0),
    ).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _fadeController.forward();

    _firstNameController.addListener(_onFormChanged);
    _lastNameController.addListener(_onFormChanged);
    _nicknameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    final hasContent = _firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty ||
        _nicknameController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _selectedImage != null ||
        _webImage != null;

    if (mounted) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  bool get _hasImage => _selectedImage != null || _webImage != null;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasContent,
      onPopInvoked: (didPop) {
        if (!didPop && _hasContent) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: ivoryWhite,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ivoryWhite, beige],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildActionButtons(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: oliveGreen,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 28),
        onPressed: _handleBack,
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'เพิ่มเจ้าหน้าที่ใหม่',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black26),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [oliveGreen, Color(0xFF8FA068)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 50,
                child: Icon(
                  Icons.person_add_rounded,
                  size: 60,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_hasContent)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 14),
                SizedBox(width: 4),
                Text('กำลังกรอก', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return SlideTransition(
      position: _shakeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),
            _buildContactInfoCard(),
            const SizedBox(height: 20),
            _buildSystemInfoCard(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [oliveGreen.withOpacity(0.1), softBrown.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: oliveGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: oliveGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_add_rounded, color: oliveGreen, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'หมู่บ้าน #${widget.villageId}',
                  style: const TextStyle(
                    color: oliveGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เพิ่มเจ้าหน้าที่รักษาความปลอดภัย',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: oliveGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: oliveGreen,
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'กรอกข้อมูลใหม่',
                  style: TextStyle(
                    color: oliveGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'รูปโปรไฟล์',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: earthClay,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกรูปภาพสำหรับเจ้าหน้าที่ (ไม่บังคับ)',
            style: TextStyle(fontSize: 12, color: warmStone),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [oliveGreen.withOpacity(0.1), softBrown.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _hasImage ? oliveGreen : softBrown.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _buildImagePreview(),
            ),
          ),
          const SizedBox(height: 16),
          _buildImageControls(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: kIsWeb && _webImage != null
            ? Image.memory(_webImage!, fit: BoxFit.cover, width: 120, height: 120)
            : !kIsWeb && _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover, width: 120, height: 120)
            : Container(
          width: 120,
          height: 120,
          color: Colors.grey.shade300,
          child: const Icon(Icons.error),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 40,
          color: oliveGreen.withOpacity(0.7),
        ),
        const SizedBox(height: 8),
        Text(
          'เพิ่มรูปภาพ',
          style: TextStyle(color: earthClay, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text('แตะเพื่อเลือกรูป', style: TextStyle(color: warmStone, fontSize: 10)),
      ],
    );
  }

  Widget _buildImageControls() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        TextButton.icon(
          onPressed: _showImagePickerOptions,
          icon: Icon(_hasImage ? Icons.edit_rounded : Icons.add_photo_alternate_rounded, size: 16),
          label: Text(_hasImage ? 'เปลี่ยนรูป' : 'เพิ่มรูป'),
          style: TextButton.styleFrom(foregroundColor: oliveGreen),
        ),
        if (_hasImage)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _webImage = null;
                _onFormChanged();
              });
            },
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text('ลบรูป'),
            style: TextButton.styleFrom(foregroundColor: danger),
          ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: softBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: softBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthClay),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _firstNameController,
            label: 'ชื่อจริง',
            icon: Icons.person_outline_rounded,
            isRequired: false,
            keyboardType: TextInputType.name,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
              FilteringTextInputFormatter.deny(RegExp(r'[0-9]')), // disallow digits to allow letters
            ],
            validator: (_) => null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lastNameController,
            label: 'นามสกุล',
            icon: Icons.person_outline_rounded,
            isRequired: false,
            validator: (_) => null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nicknameController,
            label: 'ชื่อเล่น',
            icon: Icons.tag_rounded,
            isRequired: false,
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contact_phone_rounded, color: burntOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลติดต่อ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthClay),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _phoneController,
            label: 'เบอร์โทรศัพท์',
            icon: Icons.phone_rounded,
            isRequired: false,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
              _FlexiblePhoneFormatter(),
            ],
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: clayOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded, color: clayOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลระบบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthClay),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            label: 'รหัสหมู่บ้าน',
            value: widget.villageId.toString(),
            icon: Icons.location_city_rounded,
            color: clayOrange,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: oliveGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: oliveGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: oliveGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'รหัสเจ้าหน้าที่จะถูกสร้างโดยอัตโนมัติหลังจากบันทึกข้อมูล',
                    style: TextStyle(color: oliveGreen, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: earthClay, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: earthClay, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: earthClay, size: 20),
        filled: true,
        fillColor: beige.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: warmStone.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: warmStone.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oliveGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _clearForm,
              backgroundColor: warmStone,
              foregroundColor: Colors.white,
              elevation: 4,
              heroTag: 'clear',
              icon: const Icon(Icons.clear_all_rounded),
              label: Text('เคลียร์'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _createGuard,
              backgroundColor: oliveGreen,
              foregroundColor: Colors.white,
              elevation: 8,
              heroTag: 'save',
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isLoading ? 'กำลังบันทึก...' : 'เพิ่มเจ้าหน้าที่',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: warmStone.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เลือกรูปภาพ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthClay),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb) ...[
              _buildImageOptionButton(
                icon: Icons.camera_alt_rounded,
                label: 'ถ่ายรูปใหม่',
                color: oliveGreen,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
            ],
            _buildImageOptionButton(
              icon: Icons.photo_library_rounded,
              label: kIsWeb ? 'เลือกรูปภาพ' : 'เลือกจากแกลเลอรี่',
              color: softBrown,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_hasImage) ...[
              const SizedBox(height: 16),
              _buildImageOptionButton(
                icon: Icons.delete_rounded,
                label: 'ลบรูปภาพ',
                color: danger,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _webImage = null;
                    _onFormChanged();
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: earthClay, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context); // close bottom sheet

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
        });
        _onFormChanged();
        HapticFeedback.lightImpact();
      } else {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(pickedFile.path);
          _webImage = null;
        });
        _onFormChanged();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}');
    }
  }

  Future<void> _createGuard() async {


    setState(() => _isLoading = true);

    try {
      HapticFeedback.lightImpact();

      dynamic imageFile;
      if (kIsWeb && _webImage != null) {
        imageFile = _webImage; // bytes for web
      } else if (_selectedImage != null) {
        imageFile = _selectedImage; // File for mobile
      }

      final guard = await GuardDomain.create(
        villageId: widget.villageId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        nickname: _nicknameController.text.trim().isEmpty
            ? ''
            : _nicknameController.text.trim(),
        imageFile: imageFile,
      );

      if (guard == null) {
        throw Exception('ไม่สามารถสร้างเจ้าหน้าที่ได้');
      }

      HapticFeedback.lightImpact();
      _showSuccessSnackBar('เพิ่มเจ้าหน้าที่สำเร็จ');

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    HapticFeedback.lightImpact();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ivoryWhite,
        title: Text('เคลียร์ข้อมูล', style: TextStyle(color: earthClay, fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการเคลียร์ข้อมูลทั้งหมดหรือไม่?', style: TextStyle(color: warmStone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: warmStone)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _firstNameController.clear();
                _lastNameController.clear();
                _nicknameController.clear();
                _phoneController.clear();
                _selectedImage = null;
                _webImage = null;
                _hasContent = false;
              });
              _showSuccessSnackBar('เคลียร์ข้อมูลเรียบร้อย');
            },
            style: ElevatedButton.styleFrom(backgroundColor: oliveGreen, foregroundColor: Colors.white),
            child: Text('เคลียร์'),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_hasContent) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ivoryWhite,
        title: Text('มีข้อมูลที่ยังไม่ได้บันทึก', style: TextStyle(color: earthClay, fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการออกจากหน้านี้โดยไม่บันทึกข้อมูลหรือไม่?', style: TextStyle(color: warmStone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: warmStone)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              _createGuard(); // save then pop on success
            },
            child: Text('บันทึกและออก', style: TextStyle(color: oliveGreen)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close page without saving
            },
            style: ElevatedButton.styleFrom(backgroundColor: danger, foregroundColor: Colors.white),
            child: Text('ออกโดยไม่บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Custom formatter for phone number (XXX-XXX-XXXX)
/// Flexible number formatter: groups as 3-3-4 then appends remainder (up to 15 digits)
class _FlexiblePhoneFormatter extends TextInputFormatter {
  const _FlexiblePhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted;
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 6) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else if (digits.length <= 10) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else {
      // 3-3-4-rest
      final rest = digits.substring(10);
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 10)}-${rest}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
