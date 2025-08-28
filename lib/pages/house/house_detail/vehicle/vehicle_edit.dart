import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:fullproject/theme/Color.dart';

class HouseVehicleEditPage extends StatefulWidget {
  final VehicleModel vehicle; // ต้องมี vehicle เสมอสำหรับการแก้ไข

  const HouseVehicleEditPage({super.key, required this.vehicle});

  @override
  State<HouseVehicleEditPage> createState() => _HouseVehicleEditPageState();
}

class _HouseVehicleEditPageState extends State<HouseVehicleEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();

  // Image variables for both web and mobile
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final ImagePicker _picker = ImagePicker();

  // Theme Colors

  @override
  void initState() {
    super.initState();
    _initializeForm();

    // Listen for changes
    _brandController.addListener(_onFieldChanged);
    _modelController.addListener(_onFieldChanged);
    _numberController.addListener(_onFieldChanged);
  }

  void _initializeForm() {
    _brandController.text = widget.vehicle.brand ?? '';
    _modelController.text = widget.vehicle.model ?? '';
    _numberController.text = widget.vehicle.number ?? '';
    _currentImageUrl = widget.vehicle.img;
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _numberController.dispose();
    _selectedImageFile?.delete(); // Clean up image file if exists
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: ThemeColors.clayOrange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการออก',
              style: TextStyle(color: ThemeColors.softBrown),
            ),
          ],
        ),
        content: Text(
          'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?',
          style: TextStyle(color: ThemeColors.earthClay),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: ThemeColors.warmStone),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.clayOrange,
            ),
            child: const Text('ออก'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  bool _hasSelectedImage() {
    return (kIsWeb && _selectedImageBytes != null) ||
        (!kIsWeb && _selectedImageFile != null);
  }

  Future<void> _pickImage() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: ThemeColors.oliveGreen,
                  ),
                ),
                title: Text(
                  'เลือกจากแกลเลอรี่',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: ThemeColors.burntOrange,
                  ),
                ),
                title: Text(
                  'ถ่ายภาพ',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              if (_hasSelectedImage() ||
                  (_currentImageUrl != null && !_removeCurrentImage))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeColors.clayOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      color: ThemeColors.clayOrange,
                    ),
                  ),
                  title: Text(
                    'ลบรูปภาพ',
                    style: TextStyle(color: ThemeColors.clayOrange),
                  ),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      switch (result) {
        case 'camera':
          _getImage(ImageSource.camera);
          break;
        case 'gallery':
          _getImage(ImageSource.gallery);
          break;
        case 'delete':
          _removeImage();
          break;
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
            _removeCurrentImage = false;
            _hasUnsavedChanges = true;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
            _removeCurrentImage = false;
            _hasUnsavedChanges = true;
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e', isError: true);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _removeCurrentImage = true;
      _hasUnsavedChanges = true;
    });
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

  void _resetForm() {
    setState(() {
      _brandController.text = widget.vehicle.brand ?? '';
      _modelController.text = widget.vehicle.model ?? '';
      _numberController.text = widget.vehicle.number ?? '';
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _currentImageUrl = widget.vehicle.img;
      _removeCurrentImage = false;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await VehicleDomain.update(
        vehicleId: widget.vehicle.vehicleId,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        number: _numberController.text.trim(),
        imageFile: _hasSelectedImage()
            ? (kIsWeb ? _selectedImageBytes : _selectedImageFile)
            : null,
        removeImage: _removeCurrentImage,
      );

      if (context.mounted) {
        setState(() => _hasUnsavedChanges = false);
        _showSnackBar('แก้ไขยานพาหนะสำเร็จ');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ThemeColors.beige,
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFormCard(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: ThemeColors.softBrown,
          ),
        ),
      ),
      title: Text(
        'แก้ไขยานพาหนะ',
        style: TextStyle(
          color: ThemeColors.softBrown,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลยานพาหนะ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.softBrown,
            ),
          ),
          const SizedBox(height: 20),

          // ยี่ห้อ
          _buildTextField(
            controller: _brandController,
            label: 'ยี่ห้อ',
            icon: Icons.branding_watermark_rounded,
            hint: 'เช่น Toyota, Honda',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกยี่ห้อ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // รุ่น
          _buildTextField(
            controller: _modelController,
            label: 'รุ่น',
            icon: Icons.car_repair_rounded,
            hint: 'เช่น Corolla, Civic',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกรุ่น';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ป้ายทะเบียน
          _buildTextField(
            controller: _numberController,
            label: 'ป้ายทะเบียน',
            icon: Icons.confirmation_number_rounded,
            hint: 'เช่น กข 1234',
          ),
          const SizedBox(height: 20),

          // รูปภาพ
          _buildImageSection(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: ThemeColors.warmStone),
        hintStyle: TextStyle(color: ThemeColors.warmStone.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: ThemeColors.softBrown),
        filled: true,
        fillColor: ThemeColors.beige.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.sandyTan, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.softBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.clayOrange, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeColors.clayOrange, width: 2),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รูปภาพยานพาหนะ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown,
          ),
        ),
        const SizedBox(height: 12),

        if (_hasSelectedImage())
          _buildSelectedImage()
        else if (_currentImageUrl != null && !_removeCurrentImage)
          _buildCurrentImage()
        else
          _buildImagePicker(),
      ],
    );
  }

  Widget _buildSelectedImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.sandyTan, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: kIsWeb && _selectedImageBytes != null
                  ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  : !kIsWeb && _selectedImageFile != null
                  ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                  : Container(
                      color: ThemeColors.beige,
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 60,
                        color: ThemeColors.warmStone,
                      ),
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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _removeImage,
                icon: const Icon(
                  Icons.close_rounded,
                  color: ThemeColors.ivoryWhite,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'รูปใหม่',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.sandyTan, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BuildImage(
              imagePath: _currentImageUrl!,
              tablePath: "vehicle",
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.burntOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'รูปเดิม',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  'เปลี่ยนรูปภาพ',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: ThemeColors.beige.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeColors.sandyTan,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 32,
                color: ThemeColors.oliveGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'เลือกรูปภาพยานพาหนะ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ThemeColors.earthClay,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'แตะเพื่อเลือกรูปภาพ',
              style: TextStyle(fontSize: 12, color: ThemeColors.warmStone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Update Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ThemeColors.burntOrange, ThemeColors.softTerracotta],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.burntOrange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isSaving ? null : _updateVehicle,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isSaving
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.ivoryWhite,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.update_rounded,
                            color: ThemeColors.ivoryWhite,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'บันทึกการแก้ไข',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.ivoryWhite,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        const SizedBox(height: 12),

        // Cancel Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ThemeColors.warmStone.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ThemeColors.warmStone.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isSaving
                  ? null
                  : () async {
                      if (_hasUnsavedChanges) {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && context.mounted) {
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: ThemeColors.warmStone,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.warmStone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
