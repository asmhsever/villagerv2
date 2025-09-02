import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class BillAddPage extends StatefulWidget {
  const BillAddPage({super.key});

  @override
  State<BillAddPage> createState() => _BillAddPageState();
}

class _BillAddPageState extends State<BillAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _billDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  DateTime? _billDate;
  DateTime? _dueDate;
  int? _selectedHouseId;
  int? _selectedServiceId;

  // Image files - only bill image now
  File? _billImageFile;
  Uint8List? _billImageBytes;

  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // แมปประเภทบริการให้เป็นภาษาไทย
  final Map<String, String> _serviceTranslations = {
    'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
    'Trash Fee': 'ค่าขยะ',
    'water Fee': 'ค่าน้ำ',
    'Water Fee': 'ค่าน้ำ',
    'enegy Fee': 'ค่าไฟ',
    'Energy Fee': 'ค่าไฟ',
    'Electricity Fee': 'ค่าไฟ',
  };

  bool _hasSelectedBillImage() {
    if (kIsWeb) {
      return _billImageBytes != null;
    } else {
      return _billImageFile != null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    // Set default bill date to current date
    _billDate = DateTime.now();
    _updateBillDateController();
  }

  void _updateBillDateController() {
    if (_billDate != null) {
      _billDateController.text = _formatDate(_billDate!);
    }
  }

  void _updateDueDateController() {
    if (_dueDate != null) {
      _dueDateController.text = _formatDate(_dueDate!);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectBillDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _billDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ThemeColors.softBrown,
              onPrimary: ThemeColors.ivoryWhite,
              surface: ThemeColors.ivoryWhite,
              onSurface: ThemeColors.softBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _billDate = pickedDate;
        _updateBillDateController();
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ThemeColors.softBrown,
              onPrimary: ThemeColors.ivoryWhite,
              surface: ThemeColors.ivoryWhite,
              onSurface: ThemeColors.softBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
        _updateDueDateController();
      });
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    try {
      final law = await AuthService.getCurrentUser();

      final results = await Future.wait([
        SupabaseConfig.client
            .from('house')
            .select('house_id, house_number')
            .eq('village_id', law.villageId),
        SupabaseConfig.client.from('service').select('service_id, name'),
      ]);

      setState(() {
        _houses = List<Map<String, dynamic>>.from(results[0]);
        _services = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      }
    }
  }

  String _getServiceNameTh(String? englishName) {
    return _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุ';
  }

  Future<void> _pickBillImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

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
            _billImageBytes = bytes;
            _billImageFile = null;
          });
        } else {
          setState(() {
            _billImageFile = File(image.path);
            _billImageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImageSourceTile(
                icon: Icons.camera_alt,
                title: 'ถ่ายรูป',
                subtitle: 'เปิดกล้องถ่ายรูปใหม่',
                color: ThemeColors.burntOrange,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              _buildImageSourceTile(
                icon: Icons.photo_library,
                title: 'เลือกจากแกลเลอรี่',
                subtitle: 'เลือกรูปที่มีอยู่แล้ว',
                color: ThemeColors.oliveGreen,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.earthClay,
              ),
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.clayOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.softTerracotta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ThemeColors.burntOrange),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down,
              color: ThemeColors.beige,
            ),
            filled: true,
            fillColor: ThemeColors.ivoryWhite,
            hintText: 'แตะเพื่อเลือกวันที่',
            hintStyle: const TextStyle(color: ThemeColors.warmStone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ThemeColors.softBrown),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ThemeColors.softBrown),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.focusedBrown,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildBillImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แนบรูปบิล *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: _hasSelectedBillImage() ? 200 : 180,
            maxHeight: _hasSelectedBillImage() ? 300 : 210,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hasSelectedBillImage()
                  ? ThemeColors.oliveGreen
                  : ThemeColors.softBrown,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
            color: ThemeColors.ivoryWhite,
          ),
          child: _hasSelectedBillImage()
              ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: kIsWeb && _billImageBytes != null
                    ? Image.memory(
                  _billImageBytes!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                )
                    : !kIsWeb && _billImageFile != null
                    ? Image.file(
                  _billImageFile!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                )
                    : const SizedBox(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _billImageFile = null;
                      _billImageBytes = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: ThemeColors.softTerracotta,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _pickBillImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: ThemeColors.burntOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          )
              : InkWell(
            onTap: _pickBillImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: ThemeColors.burntOrange,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'แตะเพื่อเลือกรูปภาพ',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'รูปบิล',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'รองรับไฟล์ JPG, PNG ขนาดไม่เกิน 5MB',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _billDate == null ||
        _dueDate == null ||
        _selectedHouseId == null ||
        _selectedServiceId == null) {
      _showWarningSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    if (!_hasSelectedBillImage()) {
      _showWarningSnackBar('กรุณาแนบรูปบิล');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // เตรียม imageFile สำหรับส่งไปยัง function
      dynamic billImageFile;
      if (_hasSelectedBillImage()) {
        if (kIsWeb && _billImageBytes != null) {
          billImageFile = _billImageBytes!;
        } else if (!kIsWeb && _billImageFile != null) {
          billImageFile = _billImageFile!;
        }
      }

      final result = await BillDomain.create(
        houseId: _selectedHouseId!,
        billDate: _billDate!.toIso8601String(),
        amount: double.parse(_amountController.text),
        service: _selectedServiceId!,
        dueDate: _dueDate!.toIso8601String(),
        referenceNo: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : 'REF${DateTime.now().millisecondsSinceEpoch}',
        status: 'PENDING',
        billImageFile: billImageFile,
        paidImageFile: null, // ไม่มีสลิป
        receiptImageFile: null, // ไม่มีใบเสร็จ
      );

      if (result != null) {
        _showSuccessSnackBar('เพิ่มบิลสำเร็จ');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('ไม่สามารถเพิ่มบิลได้');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: เพิ่มบิลไม่สำเร็จ\n${e.toString()}');
      debugPrint('Error creating bill: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withValues(alpha: 0.15),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? ThemeColors.softBrown).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? ThemeColors.softBrown,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.sandyTan,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: Colors.white,
        title: const Text(
          'เพิ่มค่าส่วนกลาง',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      body: _isLoading && (_houses.isEmpty || _services.isEmpty)
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ThemeColors.softBrown,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
          ],
        ),
      )
          : _houses.isEmpty || _services.isEmpty
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ThemeColors.ivoryWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ThemeColors.softBorder),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.earthClay.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.softTerracotta.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: ThemeColors.softTerracotta,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ไม่พบข้อมูล',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.softTerracotta,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ไม่พบข้อมูลบ้านหรือประเภทบริการ',
                textAlign: TextAlign.center,
                style: TextStyle(color: ThemeColors.earthClay),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.burntOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // การ์ดเลือกบ้าน
              _buildFormCard(
                title: 'เลือกบ้านเลขที่',
                icon: Icons.home_rounded,
                iconColor: ThemeColors.softBrown,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.softBorder),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _houses.any(
                          (h) => h['house_id'] == _selectedHouseId,
                    )
                        ? _selectedHouseId
                        : null,
                    items: _houses.map((house) {
                      return DropdownMenuItem<int>(
                        value: house['house_id'],
                        child: Text(
                          'บ้านเลขที่ ${house['house_number']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedHouseId = val),
                    decoration: InputDecoration(
                      hintText: 'เลือกบ้านเลขที่',
                      hintStyle: const TextStyle(
                        color: ThemeColors.earthClay,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) =>
                    value == null ? 'กรุณาเลือกบ้าน' : null,
                  ),
                ),
              ),

              // การ์ดเลือกประเภทบริการ
              _buildFormCard(
                title: 'เลือกประเภทบริการ',
                icon: Icons.receipt_long_rounded,
                iconColor: ThemeColors.warmStone,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.softBorder),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedServiceId,
                    items: _services.map((service) {
                      return DropdownMenuItem<int>(
                        value: service['service_id'],
                        child: Text(_getServiceNameTh(service['name'])),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedServiceId = val),
                    decoration: InputDecoration(
                      hintText: 'เลือกประเภทบริการ',
                      hintStyle: const TextStyle(
                        color: ThemeColors.earthClay,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) =>
                    value == null ? 'กรุณาเลือกประเภทบริการ' : null,
                  ),
                ),
              ),

              // การ์ดกรอกจำนวนเงิน
              _buildFormCard(
                title: 'จำนวนเงิน',
                icon: Icons.attach_money_rounded,
                iconColor: ThemeColors.oliveGreen,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.softBorder),
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'กรอกจำนวนเงิน',
                      hintStyle: const TextStyle(
                        color: ThemeColors.earthClay,
                      ),
                      suffixText: 'บาท',
                      suffixStyle: const TextStyle(
                        color: ThemeColors.oliveGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกจำนวนเงิน';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // การ์ดเลขอ้างอิง (Optional)
              _buildFormCard(
                title: 'เลขอ้างอิง (ไม่บังคับ)',
                icon: Icons.confirmation_number_rounded,
                iconColor: ThemeColors.mutedBurntSienna,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.softBorder),
                  ),
                  child: TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'กรอกเลขอ้างอิง (หากมี)',
                      hintStyle: const TextStyle(
                        color: ThemeColors.earthClay,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // การ์ดวันที่ออกบิล
              _buildFormCard(
                title: 'วันที่ออกบิล',
                icon: Icons.today_rounded,
                iconColor: ThemeColors.burntOrange,
                child: _buildDateField(
                  label: 'วันที่ออกบิล',
                  controller: _billDateController,
                  icon: Icons.today,
                  onTap: _selectBillDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกวันที่ออกบิล';
                    }
                    return null;
                  },
                ),
              ),

              // การ์ดเลือกวันครบกำหนด
              _buildFormCard(
                title: 'วันครบกำหนดชำระ',
                icon: Icons.calendar_today_rounded,
                iconColor: ThemeColors.mutedBurntSienna,
                child: _buildDateField(
                  label: 'วันครบกำหนดชำระ',
                  controller: _dueDateController,
                  icon: Icons.event,
                  onTap: _selectDueDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกวันครบกำหนดชำระ';
                    }
                    return null;
                  },
                ),
              ),

              // การ์ดอัปโหลดรูปบิล
              _buildFormCard(
                title: 'รูปบิล',
                icon: Icons.photo_library_rounded,
                iconColor: ThemeColors.warmStone,
                child: _buildBillImagePicker(),
              ),

              // ปุ่มเพิ่มรายการ
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.burntOrange.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Icon(Icons.add_rounded, size: 24),
                  label: Text(
                    _isLoading ? 'กำลังเพิ่มรายการ...' : 'เพิ่มรายการ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.burntOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ThemeColors.disabledGrey,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _billDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }
}