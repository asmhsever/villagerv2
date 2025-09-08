// lib/pages/committee/edit_committee.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fullproject/domains/committee_domain.dart';
import 'package:fullproject/models/committee_model.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/image_service.dart';

class CommitteeEditPage extends StatefulWidget {
  final CommitteeModel committee;
  final int villageId;

  const CommitteeEditPage({
    super.key,
    required this.committee,
    required this.villageId,
  });

  @override
  State<CommitteeEditPage> createState() => _CommitteeEditPageState();
}

class _CommitteeEditPageState extends State<CommitteeEditPage>
    with TickerProviderStateMixin {
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  // House dropdown data
  List<Map<String, dynamic>> _availableHouses = [];
  int? _selectedHouseId;
  bool _isLoadingHouses = false;

  // Image Picker - Web & Mobile
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // Mobile
  Uint8List? _webImage; // Web
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
    _firstNameController = TextEditingController(text: widget.committee.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.committee.lastName ?? '');
    _phoneController = TextEditingController(text: _formatPhoneNumber(widget.committee.phone ?? ''));
    _currentImageUrl = widget.committee.img;
    _selectedHouseId = widget.committee.houseId;

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
    _phoneController.addListener(_onFormChanged);

    // Load available houses
    _loadAvailableHouses();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    final hasTextChanges =
        _firstNameController.text != (widget.committee.firstName ?? '') ||
            _lastNameController.text != (widget.committee.lastName ?? '') ||
            _phoneController.text != _formatPhoneNumber(widget.committee.phone ?? '') ||
            _selectedHouseId != widget.committee.houseId;

    final hasImageChanges = _selectedImage != null || _webImage != null || _removeCurrentImage;

    setState(() {
      _hasChanges = hasTextChanges || hasImageChanges;
    });
  }

  Future<void> _loadAvailableHouses() async {
    setState(() => _isLoadingHouses = true);

    try {
      final client = SupabaseConfig.client;

      // Get all houses in this village
      final usedHouseIds = await client
          .from('committee')
          .select('house_id')
          .eq('village_id', widget.villageId);

      // Get houses that already have committee (except current committee)
      final committeeResponse = await client
          .from('committee')
          .select('house_id')
          .eq('village_id', widget.villageId)
          .neq('committee_id', widget.committee.committeeId ?? 0);

      final housesWithCommittee = committeeResponse
          .map((e) => e['house_id'] as int)
          .toSet();

// Create a list of available house IDs (1-100 for example)
      final allHouseIds = List.generate(100, (index) => index + 1);

      final availableHouseIds = allHouseIds
          .where((houseId) => !housesWithCommittee.contains(houseId))
          .toList();

      final currentHouseId = widget.committee.houseId;
      if (currentHouseId != null && !availableHouseIds.contains(currentHouseId)) {
        availableHouseIds.insert(0, currentHouseId);
      }


// Convert to the format expected by the dropdown
      final availableHouses = availableHouseIds.map((houseId) => {
        'house_id': houseId,
        'house_number': houseId.toString(),
        'owner': null,
      }).toList();

      if (mounted) {
        setState(() {
          _availableHouses = availableHouses;
          _isLoadingHouses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHouses = false);
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูลบ้าน: ${e.toString()}');
      }
    }
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
        backgroundColor: ThemeColors.ivoryWhite,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ThemeColors.ivoryWhite, ThemeColors.beige],
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
      backgroundColor: ThemeColors.softBrown,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 28),
        onPressed: _handleBack,
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'แก้ไขข้อมูล ${_getDisplayName()}',
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
              colors: [ThemeColors.softBrown, ThemeColors.clayOrange],
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
        if (_hasChanges)
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
            _buildCommitteeInfoHeader(),
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

  Widget _buildCommitteeInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeColors.softBrown.withOpacity(0.1), ThemeColors.burntOrange.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.softBrown.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeColors.softBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.groups_rounded, color: ThemeColors.softBrown, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คณะกรรมการ #${widget.committee.committeeId}',
                  style: TextStyle(
                    color: ThemeColors.softBrown,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplayName(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ThemeColors.burntOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ThemeColors.burntOrange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'กำลังแก้ไขข้อมูล',
                        style: TextStyle(
                          color: ThemeColors.burntOrange,
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
              color: ThemeColors.earthClay,
            ),
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
                  colors: [ThemeColors.softBrown.withOpacity(0.1), ThemeColors.burntOrange.withOpacity(0.1)],
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
    // แสดงรูปใหม่ที่เลือก
    if (_selectedImage != null || _webImage != null) {
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

    // แสดงรูปเดิมจาก server (ใช้ BuildImage)
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty && !_removeCurrentImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BuildImage(
          imagePath: _currentImageUrl!,
          tablePath: 'committee',
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          placeholder: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
            ),
          ),
          errorWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, size: 40, color: ThemeColors.warmStone),
              const SizedBox(height: 8),
              Text('ไม่สามารถโหลดรูปได้', style: TextStyle(color: ThemeColors.earthClay, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Placeholder เมื่อไม่มีรูป
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 40, color: ThemeColors.softBrown.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text('เพิ่มรูปภาพ', style: TextStyle(color: ThemeColors.earthClay, fontSize: 14, fontWeight: FontWeight.w500)),
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
            _selectedImage != null || _webImage != null || (_currentImageUrl?.isNotEmpty ?? false)
                ? Icons.edit_rounded
                : Icons.add_photo_alternate_rounded,
            size: 16,
          ),
          label: Text(_selectedImage != null || _webImage != null || (_currentImageUrl?.isNotEmpty ?? false)
              ? 'เปลี่ยนรูป'
              : 'เพิ่มรูป'),
          style: TextButton.styleFrom(foregroundColor: ThemeColors.softBrown),
        ),

        if (_selectedImage != null || _webImage != null) ...[
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _webImage = null;
                _onFormChanged();
              });
            },
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('เลิกเปลี่ยน'),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.warmStone),
          ),
        ],

        if ((_currentImageUrl?.isNotEmpty ?? false) && !_removeCurrentImage && _selectedImage == null && _webImage == null) ...[
          TextButton.icon(
            onPressed: () {
              setState(() {
                _removeCurrentImage = true;
                _onFormChanged();
              });
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('ลบรูป'),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.mutedBurntSienna),
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
            style: TextButton.styleFrom(foregroundColor: ThemeColors.oliveGreen),
          ),
        ],
      ],
    );
  }

  Color _getImageBorderColor() {
    if (_selectedImage != null || _webImage != null) return ThemeColors.oliveGreen;
    if (_removeCurrentImage) return ThemeColors.mutedBurntSienna;
    if (_currentImageUrl?.isNotEmpty ?? false) return ThemeColors.softBrown;
    return ThemeColors.warmStone.withOpacity(0.3);
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
                  color: ThemeColors.burntOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_rounded, color: ThemeColors.burntOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColors.earthClay),
              ),
              const SizedBox(width: 8),
              Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _firstNameController,
            label: 'ชื่อจริง',
            icon: Icons.person_outline_rounded,
            isRequired: true,
            keyboardType: TextInputType.name,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
              FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกชื่อจริง';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lastNameController,
            label: 'นามสกุล',
            icon: Icons.person_outline_rounded,
            isRequired: true,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
              FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกนามสกุล';
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
                  color: ThemeColors.oliveGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.contact_phone_rounded, color: ThemeColors.oliveGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลติดต่อ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColors.earthClay),
              ),
              const SizedBox(width: 8),
              Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _phoneController,
            label: 'เบอร์โทรศัพท์',
            icon: Icons.phone_rounded,
            isRequired: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
              _FlexiblePhoneFormatter(),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกเบอร์โทรศัพท์';
              }
              final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
              if (digitsOnly.length < 9) {
                return 'เบอร์โทรศัพท์ต้องมีอย่างน้อย 9 หลัก';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildHouseDropdown(),
        ],
      ),
    );
  }

  Widget _buildHouseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.home_rounded, color: ThemeColors.earthClay, size: 20),
            const SizedBox(width: 8),
            Text(
              'เลือกบ้าน *',
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ThemeColors.beige.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeColors.warmStone.withOpacity(0.3)),
          ),
          child: _isLoadingHouses
              ? Container(
            height: 56,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'กำลังโหลดข้อมูลบ้าน...',
                  style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
                ),
              ],
            ),
          )
              : _availableHouses.isEmpty
              ? Container(
            height: 56,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: ThemeColors.warmStone, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ไม่มีบ้านที่ว่างในหมู่บ้านนี้',
                    style: TextStyle(color: ThemeColors.warmStone, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _loadAvailableHouses,
                  child: Text('รีเฟรช', style: TextStyle(color: ThemeColors.softBrown)),
                ),
              ],
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedHouseId,
              hint: Text(
                'เลือกบ้าน',
                style: TextStyle(color: ThemeColors.warmStone, fontSize: 16),
              ),
              isExpanded: true,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: ThemeColors.earthClay,
              ),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedHouseId = newValue;
                  _onFormChanged();
                });
              },
              items: _availableHouses.map<DropdownMenuItem<int>>((house) {
                return DropdownMenuItem<int>(
                  value: house['house_id'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ThemeColors.softBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            house['house_number']?.toString() ?? 'ไม่ระบุ',
                            style: TextStyle(
                              color: ThemeColors.softBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'บ้านเลขที่ ${house['house_number']?.toString() ?? 'ไม่ระบุ'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (house['owner'] != null && house['owner'].toString().isNotEmpty)
                                Text(
                                  'เจ้าของ: ${house['owner']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ThemeColors.warmStone,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_selectedHouseId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'กรุณาเลือกบ้าน',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
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
                  color: ThemeColors.clayOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_rounded, color: ThemeColors.clayOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลระบบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColors.earthClay),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  label: 'รหัสคณะกรรมการ',
                  value: '#${widget.committee.committeeId}',
                  icon: Icons.badge_rounded,
                  color: ThemeColors.softBrown,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField(
                  label: 'รหัสหมู่บ้าน',
                  value: widget.villageId.toString(),
                  icon: Icons.location_city_rounded,
                  color: ThemeColors.clayOrange,
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
                  style: TextStyle(color: ThemeColors.earthClay, fontSize: 12, fontWeight: FontWeight.w500),
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
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: ThemeColors.earthClay, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: ThemeColors.earthClay, size: 20),
        filled: true,
        fillColor: ThemeColors.beige.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.warmStone.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.warmStone.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
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
              onPressed: _isLoading ? null : _resetForm,
              backgroundColor: ThemeColors.warmStone,
              foregroundColor: Colors.white,
              elevation: 4,
              heroTag: "reset",
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('รีเซ็ต'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FloatingActionButton.extended(
              onPressed: _isLoading || !_hasChanges ? null : _updateCommittee,
              backgroundColor: _hasChanges ? ThemeColors.softBrown : Colors.grey.shade400,
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
                color: ThemeColors.warmStone.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เปลี่ยนรูปภาพ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb) ...[
              _buildImageOptionButton(
                icon: Icons.camera_alt_rounded,
                label: 'ถ่ายรูปใหม่',
                color: ThemeColors.softBrown,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
            ],
            _buildImageOptionButton(
              icon: Icons.photo_library_rounded,
              label: kIsWeb ? 'เลือกรูปภาพ' : 'เลือกจากแกลเลอรี่',
              color: ThemeColors.burntOrange,
              onTap: () => _pickImage(ImageSource.gallery),
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
                    style: TextStyle(color: ThemeColors.earthClay, fontSize: 16, fontWeight: FontWeight.w500),
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

      if (pickedFile != null && mounted) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
            _removeCurrentImage = false;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImage = null;
            _removeCurrentImage = false;
          });
        }
        _onFormChanged();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}');
    }
  }

  Future<void> _updateCommittee() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) => _shakeController.reverse());
      return;
    }

    if (!_hasChanges) {
      _showInfoSnackBar('ไม่มีการเปลี่ยนแปลงข้อมูล');
      return;
    }

    if (_selectedHouseId == null) {
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) => _shakeController.reverse());
      _showErrorSnackBar('กรุณาเลือกบ้าน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      HapticFeedback.lightImpact();

      dynamic imageFile;
      if (kIsWeb && _webImage != null) {
        imageFile = _webImage; // bytes for web
      } else if (_selectedImage != null) {
        imageFile = _selectedImage; // File for mobile
      }

      await CommitteeDomain.update(
        committeeId: widget.committee.committeeId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        villageId: widget.villageId,
        houseId: _selectedHouseId!,
        imageFile: imageFile,
        removeImage: _removeCurrentImage,
      );

      HapticFeedback.lightImpact();
      _showSuccessSnackBar('อัปเดตข้อมูลคณะกรรมการสำเร็จ');

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ThemeColors.ivoryWhite,
        title: Text(
          'รีเซ็ตข้อมูล',
          style: TextStyle(color: ThemeColors.earthClay, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการรีเซ็ตข้อมูลกลับเป็นค่าเดิมหรือไม่?',
          style: TextStyle(color: ThemeColors.warmStone),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: ThemeColors.warmStone)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                _firstNameController.text = widget.committee.firstName ?? '';
                _lastNameController.text = widget.committee.lastName ?? '';
                _phoneController.text = _formatPhoneNumber(widget.committee.phone ?? '');
                _selectedHouseId = widget.committee.houseId;
                _selectedImage = null;
                _webImage = null;
                _removeCurrentImage = false;
                _hasChanges = false;
              });

              _showSuccessSnackBar('รีเซ็ตข้อมูลเรียบร้อย');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.softBrown,
              foregroundColor: Colors.white,
            ),
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
        backgroundColor: ThemeColors.ivoryWhite,
        title: Text(
          'มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก',
          style: TextStyle(color: ThemeColors.earthClay, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการออกจากหน้านี้โดยไม่บันทึกการเปลี่ยนแปลงหรือไม่?',
          style: TextStyle(color: ThemeColors.warmStone),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: ThemeColors.warmStone)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _updateCommittee(); // Try to save first
            },
            child: Text('บันทึกและออก', style: TextStyle(color: ThemeColors.oliveGreen)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.mutedBurntSienna,
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกโดยไม่บันทึก'),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    final firstName = widget.committee.firstName ?? '';
    final lastName = widget.committee.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    return 'คณะกรรมการ #${widget.committee.committeeId}';
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
        backgroundColor: ThemeColors.softBrown,
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeColors.mutedBurntSienna,
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
        backgroundColor: ThemeColors.warmStone,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 10)}-$rest';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}