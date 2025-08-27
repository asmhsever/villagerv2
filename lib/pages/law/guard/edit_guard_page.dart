// lib/pages/edit_guard_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullproject/domains/guard_domain.dart';
import 'package:fullproject/models/guard_model.dart';
import 'package:fullproject/config/supabase_config.dart';

class EditGuardPage extends StatefulWidget {
  final GuardModel guard;

  const EditGuardPage({super.key, required this.guard});

  @override
  State<EditGuardPage> createState() => _EditGuardPageState();
}

class _EditGuardPageState extends State<EditGuardPage>
    with TickerProviderStateMixin {
  // Theme Colors
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color lightBrown = Color(0xFFA0522D);
  static const Color accentGold = Color(0xFFDAA520);
  static const Color backgroundCream = Color(0xFFFAF6F0);
  static const Color cardWhite = Color(0xFFFFFFFE);
  static const Color textDark = Color(0xFF2C1810);
  static const Color textMedium = Color(0xFF5D4E37);
  static const Color textLight = Color(0xFF8B7355);
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFF8C00);
  static const Color errorRed = Color(0xFFDC3545);

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _phoneController;

  // Image Picker
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  // Form State
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _firstNameController = TextEditingController(text: widget.guard.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.guard.lastName ?? '');
    _nicknameController = TextEditingController(text: widget.guard.nickname ?? '');
    _phoneController = TextEditingController(text: _formatPhoneNumber(widget.guard.phone ?? ''));
    _currentImageUrl = widget.guard.img;

    // Animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _fadeController.forward();

    // Listen for changes
    _firstNameController.addListener(_onFormChanged);
    _lastNameController.addListener(_onFormChanged);
    _nicknameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    final hasTextChanges =
        _firstNameController.text != (widget.guard.firstName ?? '') ||
            _lastNameController.text != (widget.guard.lastName ?? '') ||
            _nicknameController.text != (widget.guard.nickname ?? '') ||
            _phoneController.text != _formatPhoneNumber(widget.guard.phone ?? '');

    final hasImageChanges = _selectedImage != null || _removeCurrentImage;

    setState(() {
      _hasChanges = hasTextChanges || hasImageChanges;
    });
  }

  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length >= 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length >= 6) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length >= 3) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) {
        if (!didPop && _hasChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundCream,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundCream, Color(0xFFF5F1EA)],
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: warningOrange,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 28),
        onPressed: () => _handleBack(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'แก้ไขข้อมูล ${_getDisplayName()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [warningOrange, Color(0xFFE67E00)],
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
                  Icons.edit_rounded,
                  size: 60,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Changes indicator
        if (_hasChanges)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 14),
                SizedBox(width: 4),
                Text('มีการแก้ไข', style: TextStyle(fontSize: 10)),
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
            // Guard Info Header
            _buildGuardInfoHeader(),
            const SizedBox(height: 24),

            // Profile Image Section
            _buildImageSection(),
            const SizedBox(height: 24),

            // Personal Information Card
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),

            // Contact Information Card
            _buildContactInfoCard(),
            const SizedBox(height: 20),

            // System Information Card
            _buildSystemInfoCard(),
            const SizedBox(height: 120), // Space for FABs
          ],
        ),
      ),
    );
  }

  Widget _buildGuardInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBrown.withOpacity(0.1), accentGold.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBrown.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.security_rounded, color: primaryBrown, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เจ้าหน้าที่ #${widget.guard.guardId}',
                  style: TextStyle(
                    color: primaryBrown,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: successGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: successGreen,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'กำลังแก้ไขข้อมูล',
                        style: TextStyle(
                          color: successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
        color: cardWhite,
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
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Image Preview
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [warningOrange.withOpacity(0.1), accentGold.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _getImageBorderColor(),
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
    if (_removeCurrentImage && _selectedImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: 40,
            color: textLight,
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่มีรูปภาพ',
            style: TextStyle(
              color: textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
        ),
      );
    }

    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          _resolveImageUrl(_currentImageUrl!),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(warningOrange),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, size: 40, color: textLight),
              const SizedBox(height: 8),
              Text(
                'ไม่สามารถโหลดรูปได้',
                style: TextStyle(color: textMedium, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 40,
          color: warningOrange.withOpacity(0.7),
        ),
        const SizedBox(height: 8),
        Text(
          'เพิ่มรูปภาพ',
          style: TextStyle(
            color: textMedium,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          icon: Icon(
            _selectedImage != null || (_currentImageUrl?.isNotEmpty ?? false)
                ? Icons.edit_rounded
                : Icons.add_photo_alternate_rounded,
            size: 16,
          ),
          label: Text(_selectedImage != null || (_currentImageUrl?.isNotEmpty ?? false)
              ? 'เปลี่ยนรูป'
              : 'เพิ่มรูป'),
          style: TextButton.styleFrom(foregroundColor: warningOrange),
        ),

        if (_selectedImage != null) ...[
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _onFormChanged();
              });
            },
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('เลิกเปลี่ยน'),
            style: TextButton.styleFrom(foregroundColor: primaryBrown),
          ),
        ],

        if ((_currentImageUrl?.isNotEmpty ?? false) && !_removeCurrentImage) ...[
          TextButton.icon(
            onPressed: () {
              setState(() {
                _removeCurrentImage = true;
                _selectedImage = null;
                _onFormChanged();
              });
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('ลบรูป'),
            style: TextButton.styleFrom(foregroundColor: errorRed),
          ),
        ],

        if (_removeCurrentImage) ...[
          TextButton.icon(
            onPressed: () {
              setState(() {
                _removeCurrentImage = false;
                _onFormChanged();
              });
            },
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('เลิกลบ'),
            style: TextButton.styleFrom(foregroundColor: successGreen),
          ),
        ],
      ],
    );
  }

  Color _getImageBorderColor() {
    if (_selectedImage != null) return successGreen;
    if (_removeCurrentImage) return errorRed;
    if (_currentImageUrl?.isNotEmpty ?? false) return warningOrange;
    return primaryBrown.withOpacity(0.3);
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
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
                  color: primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_rounded, color: primaryBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // First Name
          _buildTextField(
            controller: _firstNameController,
            label: 'ชื่อจริง',
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกชื่อจริง';
              }
              if (value.trim().length < 2) {
                return 'ชื่อจริงต้องมีอย่างน้อย 2 ตัวอักษร';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Last Name
          _buildTextField(
            controller: _lastNameController,
            label: 'นามสกุล',
            icon: Icons.person_outline_rounded,
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
          const SizedBox(height: 16),

          // Nickname
          _buildTextField(
            controller: _nicknameController,
            label: 'ชื่อเล่น',
            icon: Icons.tag_rounded,
            isRequired: false,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                return 'ชื่อเล่นต้องมีอย่างน้อย 2 ตัวอักษร';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
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
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.contact_phone_rounded, color: successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลติดต่อ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Phone Number
          _buildTextField(
            controller: _phoneController,
            label: 'เบอร์โทรศัพท์',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              _PhoneNumberFormatter(),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกเบอร์โทรศัพท์';
              }
              final phoneRegex = RegExp(r'^0[0-9]{8,9}$');
              final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
              if (!phoneRegex.hasMatch(cleanPhone)) {
                return 'รูปแบบเบอร์โทรไม่ถูกต้อง (ตัวอย่าง: 0812345678)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
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
                  color: accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_rounded, color: accentGold, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลระบบ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Guard ID
              Expanded(
                child: _buildReadOnlyField(
                  label: 'รหัสเจ้าหน้าที่',
                  value: '#${widget.guard.guardId}',
                  icon: Icons.badge_rounded,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(width: 16),
              // Village ID
              Expanded(
                child: _buildReadOnlyField(
                  label: 'รหัสหมู่บ้าน',
                  value: widget.guard.villageId.toString(),
                  icon: Icons.location_city_rounded,
                  color: accentGold,
                ),
              ),
            ],
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
                  style: TextStyle(
                    color: textMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: textMedium,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: textMedium, size: 20),
        filled: true,
        fillColor: backgroundCream.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLight.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLight.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: warningOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 2),
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
          // Cancel/Reset Button
          Expanded(
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _resetForm,
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              elevation: 4,
              heroTag: "reset",
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('รีเซ็ต'),
            ),
          ),
          const SizedBox(width: 16),

          // Save Button
          Expanded(
            flex: 2,
            child: FloatingActionButton.extended(
              onPressed: _isLoading || !_hasChanges ? null : _updateGuard,
              backgroundColor: _hasChanges ? warningOrange : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: _hasChanges ? 8 : 2,
              heroTag: "save",
              icon: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isLoading
                    ? 'กำลังบันทึก...'
                    : _hasChanges
                    ? 'บันทึกการแก้ไข'
                    : 'ไม่มีการเปลี่ยนแปลง',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
        decoration: const BoxDecoration(
          color: cardWhite,
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
                color: textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เปลี่ยนรูปภาพ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'ถ่ายรูปใหม่',
                    color: warningOrange,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'เลือกจากแกลเลอรี่',
                    color: accentGold,
                    onTap: () => _pickImage(ImageSource.gallery),
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

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
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
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context); // Close bottom sheet

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _removeCurrentImage = false;
        });
        _onFormChanged();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}');
    }
  }

  Future<void> _updateGuard() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) => _shakeController.reverse());
      return;
    }

    if (!_hasChanges) {
      _showInfoSnackBar('ไม่มีการเปลี่ยนแปลงข้อมูล');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.lightImpact();

      await GuardDomain.update(
        guardId: widget.guard.guardId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        nickname: _nicknameController.text.trim().isEmpty
            ? ''
            : _nicknameController.text.trim(),
        imageFile: _selectedImage != null ? File(_selectedImage!.path) : null,
        removeImage: _removeCurrentImage,
      );

      HapticFeedback.lightImpact();
      _showSuccessSnackBar('อัปเดตข้อมูลเจ้าหน้าที่สำเร็จ');

      // Wait a bit for the snackbar to show
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('รีเซ็ตข้อมูล'),
        content: const Text('คุณต้องการรีเซ็ตข้อมูลกลับเป็นค่าเดิมหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                _firstNameController.text = widget.guard.firstName ?? '';
                _lastNameController.text = widget.guard.lastName ?? '';
                _nicknameController.text = widget.guard.nickname ?? '';
                _phoneController.text = _formatPhoneNumber(widget.guard.phone ?? '');
                _selectedImage = null;
                _removeCurrentImage = false;
                _hasChanges = false;
              });

              _showSuccessSnackBar('รีเซ็ตข้อมูลเรียบร้อย');
            },
            style: ElevatedButton.styleFrom(backgroundColor: warningOrange),
            child: const Text('รีเซ็ต'),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก'),
        content: const Text('คุณต้องการออกจากหน้านี้โดยไม่บันทึกการเปลี่ยนแปลงหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _updateGuard(); // Try to save first
            },
            child: const Text('บันทึกและออก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close page
            },
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('ออกโดยไม่บันทึก'),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    final firstName = widget.guard.firstName ?? '';
    final lastName = widget.guard.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (widget.guard.nickname?.isNotEmpty ?? false) return widget.guard.nickname!;
    return 'เจ้าหน้าที่ #${widget.guard.guardId}';
  }

  String _resolveImageUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    final s = pathOrUrl.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final client = SupabaseConfig.client;
    return client.storage.from('guard').getPublicUrl(s);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successGreen,
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
            Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Custom formatter for phone number (same as AddGuardPage)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) return newValue.copyWith(text: '');

    String formatted = text;
    if (text.length >= 3) {
      formatted = '${text.substring(0, 3)}-${text.substring(3)}';
    }
    if (text.length >= 6) {
      formatted = '${text.substring(0, 3)}-${text.substring(3, 6)}-${text.substring(6)}';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}