import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/theme/Color.dart';

class BillPaymentPage extends StatefulWidget {
  final BillModel bill;

  const BillPaymentPage({super.key, required this.bill});

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _slipDateTimeController = TextEditingController();
  final _referenceNoController = TextEditingController();
  final _remarkController = TextEditingController();

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  DateTime? _selectedDateTime;

  bool _hasSelectedImage() {
    if (kIsWeb) {
      return _selectedImageBytes != null;
    } else {
      return _selectedImageFile != null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set default datetime to current
    _selectedDateTime = DateTime.now();
    _updateDateTimeController();
  }

  @override
  void dispose() {
    _slipDateTimeController.dispose();
    _referenceNoController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _updateDateTimeController() {
    if (_selectedDateTime != null) {
      _slipDateTimeController.text = _formatDateTime(_selectedDateTime!);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDateTime() async {
    // เลือกวันที่ก่อน
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ThemeColors.softBrown, // Soft rown
              onPrimary: ThemeColors.ivoryWhite, // Ivory White
              surface: ThemeColors.ivoryWhite, // Ivory White
              onSurface: ThemeColors.softBrown, // Soft Brown
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // เลือกเวลาหลังจากเลือกวันที่
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDateTime != null
            ? TimeOfDay.fromDateTime(_selectedDateTime!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: ThemeColors.softBrown, // Soft Brown
                onPrimary: ThemeColors.ivoryWhite, // Ivory White
                surface: ThemeColors.ivoryWhite, // Ivory White
                onSurface: ThemeColors.softBrown, // Soft Brown
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _updateDateTimeController();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          // For mobile platforms
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
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
          // Ivory White
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              color: ThemeColors.softBrown, // Soft Brown
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
                // Burnt Orange
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              _buildImageSourceTile(
                icon: Icons.photo_library,
                title: 'เลือกจากแกลเลอรี่',
                subtitle: 'เลือกรูปที่มีอยู่แล้ว',
                color: ThemeColors.oliveGreen,
                // Olive Green
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.earthClay, // Earth Clay
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

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasSelectedImage()) {
      _showErrorSnackBar('กรุณาแนบสลิปการโอนเงิน');
      return;
    }

    // Show confirmation dialog
    final bool? confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final DateTime transferDateTime = _selectedDateTime!;

      // เตรียม imageFile สำหรับส่งไปยัง function
      dynamic imageFile;
      if (_hasSelectedImage()) {
        if (kIsWeb && _selectedImageBytes != null) {
          imageFile = _selectedImageBytes!;
        } else if (!kIsWeb && _selectedImageFile != null) {
          imageFile = _selectedImageFile!;
        }
      }

      final success = await BillDomain.update(
        billId: widget.bill.billId,
        slipImageFile: imageFile,
        slipDate: transferDateTime,
        // ส่ง DateTime ตรงๆ
        status: "UNDER_REVIEW",
        paidMethod: "BANK_TRANSFER",
      );

      if (success) {
        if (mounted) {
          _showSuccessSnackBar('ส่งข้อมูลการชำระเงินแล้ว รอการตรวจสอบ');
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('เกิดข้อผิดพลาดในการส่งข้อมูล');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        // Ivory White
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: ThemeColors.softBrown, size: 24),
            SizedBox(width: 8),
            Text(
              'ยืนยันการชำระเงิน',
              style: TextStyle(
                color: ThemeColors.softBrown, // Soft Brown
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ต้องการส่งข้อมูลการชำระบิลเลขที่ ${widget.bill.billId} หรือไม่?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.beige, // Beige
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildConfirmationRow(
                    'จำนวนเงิน',
                    '฿${widget.bill.amount.toStringAsFixed(2)}',
                  ),
                  _buildConfirmationRow(
                    'วันที่-เวลาโอน',
                    _formatDateTime(_selectedDateTime!),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.earthClay, // Earth Clay
            ),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.burntOrange, // Burnt Orange
              foregroundColor: ThemeColors.ivoryWhite, // Ivory White
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: ThemeColors.earthClay, // Earth Clay
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: ThemeColors.softBrown, // Soft Brown
              ),
            ),
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
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.oliveGreen, // Olive Green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.softTerracotta, // Soft Terracotta
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite, // Ivory White
      appBar: AppBar(
        title: const Text(
          'จ่ายบิล',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ThemeColors.ivoryWhite, // Ivory White
          ),
        ),
        backgroundColor: ThemeColors.softBrown,
        // Soft Brown
        foregroundColor: ThemeColors.ivoryWhite,
        // Ivory White
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPaymentGuide(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top section with bill info and form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bill Information Card
                    _buildBillInfoCard(),

                    const SizedBox(height: 20),

                    // Payment Form
                    _buildPaymentForm(),
                  ],
                ),
              ),
            ),

            // Bottom section with submit button
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBillInfoCard() {
    return Card(
      color: ThemeColors.beige, // Beige
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: ThemeColors.softBrown.withOpacity(0.1),
                    // Soft Brown
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: ThemeColors.softBrown, // Soft Brown
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูลบิล',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown, // Soft Brown
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getBillStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getBillStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.ivoryWhite, // Ivory White
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeColors.sandyTan), // Sandy Tan
              ),
              child: Column(
                children: [
                  _buildInfoRow('เลขที่บิล', widget.bill.billId.toString()),
                  _buildInfoRow('บ้านเลขที่', widget.bill.houseId.toString()),
                  _buildInfoRow(
                    'จำนวนเงิน',
                    '฿${widget.bill.amount.toStringAsFixed(2)}',
                  ),
                  _buildInfoRow(
                    'วันครบกำหนด',
                    _formatDate(widget.bill.dueDate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBillStatusColor() {
    switch (widget.bill.status) {
      case 'PENDING':
        return ThemeColors.burntOrange; // Burnt Orange
      case 'REJECTED':
        return ThemeColors.softTerracotta; // Soft Terracotta
      case 'OVERDUE':
        return ThemeColors.clayOrange; // Clay Orange
      default:
        return ThemeColors.earthClay; // Earth Clay
    }
  }

  String _getBillStatusText() {
    switch (widget.bill.status) {
      case 'PENDING':
        return 'รอชำระ';
      case 'REJECTED':
        return 'สลิปไม่ผ่าน';
      case 'OVERDUE':
        return 'เลยกำหนด';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: ThemeColors.earthClay, // Earth Clay
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ThemeColors.softBrown, // Soft Brown
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      color: ThemeColors.inputFill, // Input Fill
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    // Burnt Orange
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: ThemeColors.burntOrange, // Burnt Orange
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูลการโอนเงิน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown, // Soft Brown
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date and Time Combined Field
            _buildDateTimeField(
              label: 'วันที่และเวลาโอน',
              controller: _slipDateTimeController,
              icon: Icons.schedule,
              onTap: _selectDateTime,
            ),

            const SizedBox(height: 20),

            // Slip Image
            _buildImagePicker(),

            const SizedBox(height: 20),

            // Remark (Optional)
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown, // Soft Brown
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
            // Burnt Orange
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down,
              color: ThemeColors.beige,
            ),
            filled: true,
            fillColor: ThemeColors.ivoryWhite,
            // Ivory White
            hintText: 'แตะเพื่อเลือกวันที่และเวลา',
            hintStyle: const TextStyle(color: ThemeColors.warmStone),
            // Warm Stone
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.softBrown,
              ), // Soft Border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.softBrown,
              ), // Soft Border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.focusedBrown,
                width: 2,
              ), // Focused Brown
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกวันที่และเวลาโอน';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown, // Soft Brown
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ThemeColors.burntOrange),
            // Burnt Orange
            filled: true,
            fillColor: ThemeColors.ivoryWhite,
            // Ivory White
            hintText: hint,
            hintStyle: const TextStyle(color: ThemeColors.warmStone),
            // Warm Stone
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.softBrown,
              ), // Soft Border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.softBrown,
              ), // Soft Border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.focusedBrown,
                width: 2,
              ), // Focused Brown
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ThemeColors.softTerracotta,
              ), // Soft Terracotta
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แนบสลิปการโอนเงิน *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown, // Soft Brown
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: _hasSelectedImage() ? 200 : 180,
            maxHeight: _hasSelectedImage() ? 300 : 210,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hasSelectedImage()
                  ? ThemeColors
                        .oliveGreen // Olive Green
                  : ThemeColors.softBrown, // Soft Border
              width: 2,
              style: _hasSelectedImage()
                  ? BorderStyle.solid
                  : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
            color: ThemeColors.ivoryWhite, // Ivory White
          ),
          child: _hasSelectedImage()
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb && _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            )
                          : !kIsWeb && _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
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
                            _selectedImageFile = null;
                            _selectedImageBytes = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color:
                                ThemeColors.softTerracotta, // Soft Terracotta
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
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: ThemeColors.burntOrange, // Burnt Orange
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
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: ThemeColors.burntOrange, // Burnt Orange
                        ),
                        SizedBox(height: 12),
                        Text(
                          'แตะเพื่อเลือกรูปภาพ',
                          style: TextStyle(
                            color: ThemeColors.earthClay, // Earth Clay
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'สลิปการโอนเงิน',
                          style: TextStyle(
                            color: ThemeColors.warmStone, // Warm Stone
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'รองรับไฟล์ JPG, PNG ขนาดไม่เกิน 5MB',
                          style: TextStyle(
                            color: ThemeColors.warmStone, // Warm Stone
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

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: ThemeColors.ivoryWhite, // Ivory White
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.beige, // Beige
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeColors.sandyTan), // Sandy Tan
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: ThemeColors.softBrown, // Soft Brown
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ยอดที่ต้องชำระ:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors.earthClay, // Earth Clay
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '฿${widget.bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.softBrown, // Soft Brown
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.burntOrange,
                  // Burnt Orange
                  foregroundColor: ThemeColors.ivoryWhite,
                  // Ivory White
                  disabledBackgroundColor: const Color(0xFFDCDCDC),
                  // Disabled Grey
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: ThemeColors.burntOrange.withOpacity(0.3),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: ThemeColors.ivoryWhite, // Ivory White
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'กำลังส่งข้อมูล...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ส่งข้อมูลการชำระเงิน',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        // Ivory White
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_center, color: ThemeColors.softBrown, size: 24),
            SizedBox(width: 8),
            Text(
              'วิธีการชำระเงิน',
              style: TextStyle(
                color: ThemeColors.softBrown, // Soft Brown
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep(
                '1',
                'โอนเงินผ่านธนาคาร',
                'โอนเงินตามจำนวนที่ระบุในบิล',
              ),
              _buildGuideStep(
                '2',
                'ถ่ายรูปสลิป',
                'ถ่ายรูปสลิปการโอนเงินให้ชัดเจน',
              ),
              _buildGuideStep('4', 'ส่งข้อมูล', 'กดส่งและรอการตรวจสอบ'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeColors.beige, // Beige
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 หมายเหตุ: กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนส่ง เพื่อความรวดเร็วในการตรวจสอบ',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeColors.earthClay, // Earth Clay
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.softBrown, // Soft Brown
            ),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: ThemeColors.burntOrange, // Burnt Orange
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
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
                    color: ThemeColors.softBrown, // Soft Brown
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeColors.earthClay, // Earth Clay
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
