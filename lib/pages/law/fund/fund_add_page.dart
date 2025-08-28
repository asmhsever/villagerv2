import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/domains/funds_domain.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:image_picker/image_picker.dart';

class LawFundAddPage extends StatefulWidget {
  final int villageId;

  const LawFundAddPage({Key? key, required this.villageId}) : super(key: key);

  @override
  State<LawFundAddPage> createState() => _LawFundAddPageState();
}

class _LawFundAddPageState extends State<LawFundAddPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedType = 'income'; // income, outcome
  File? _receiptImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายรูป: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _receiptImage = null;
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeColors.beige,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeColors.warmStone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'เลือกรูปใบเสร็จ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.softBrown,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'ถ่ายรูป',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library_outlined,
                    label: 'เลือกจากแกลลอรี่',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  if (_receiptImage != null)
                    _buildImageOption(
                      icon: Icons.delete_outline,
                      label: 'ลบรูป',
                      color: ThemeColors.burntOrange,
                      onTap: () {
                        Navigator.pop(context);
                        _removeImage();
                      },
                    ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? ThemeColors.softBrown;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: optionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: optionColor.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: optionColor, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: optionColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFund() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      final result = await FundDomain.create(
        villageId: widget.villageId,
        type: _selectedType,
        amount: amount,
        description: _descriptionController.text,
        receiptImageFile: _receiptImage,
      );

      if (result != null) {
        _showSuccessSnackBar('เพิ่มรายการกองทุนเรียบร้อยแล้ว');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการบันทึกข้อมูล');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: ThemeColors.ivoryWhite),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: ThemeColors.oliveGreen,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: ThemeColors.ivoryWhite),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.burntOrange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ThemeColors.beige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.sandyTan, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              type: 'income',
              label: 'รายรับ',
              icon: Icons.trending_up_rounded,
              color: ThemeColors.oliveGreen,
            ),
          ),
          Expanded(
            child: _buildTypeOption(
              type: 'outcome',
              label: 'รายจ่าย',
              icon: Icons.trending_down_rounded,
              color: ThemeColors.burntOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : ThemeColors.warmStone,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : ThemeColors.warmStone,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'หลักฐานการทำรายการ (ไม่บังคับ)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown,
          ),
        ),
        SizedBox(height: 12),

        if (_receiptImage != null)
          _buildImagePreview()
        else
          _buildNoImageState(),
      ],
    );
  }

  Widget _buildNoImageState() {
    return GestureDetector(
      onTap: _showImagePicker,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: ThemeColors.beige,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeColors.sandyTan,
            width: 2,
            style: BorderStyle.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeColors.warmStone.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: ThemeColors.warmStone,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'เพิ่มรูปใบเสร็จ',
              style: TextStyle(
                color: ThemeColors.warmStone,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'แตะเพื่อเลือกรูปภาพ',
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.sandyTan, width: 2),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Image.file(
                _receiptImage!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.beige,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _showImagePicker,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: ThemeColors.softTerracotta,
                  ),
                  label: Text(
                    'เปลี่ยนรูป',
                    style: TextStyle(color: ThemeColors.softTerracotta),
                  ),
                ),
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: Icon(
                    Icons.delete_outline,
                    color: ThemeColors.burntOrange,
                  ),
                  label: Text(
                    'ลบรูป',
                    style: TextStyle(color: ThemeColors.burntOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ล้างข้อมูล',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'คุณต้องการล้างข้อมูลทั้งหมดหรือไม่?',
            style: TextStyle(color: ThemeColors.earthClay),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: ThemeColors.warmStone),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _descriptionController.clear();
                  _amountController.clear();
                  _receiptImage = null;
                  _selectedType = 'income';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.burntOrange,
                foregroundColor: ThemeColors.ivoryWhite,
              ),
              child: Text('ล้างข้อมูล'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text(
          'เพิ่มรายการกองทุน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.ivoryWhite,
            fontSize: 20,
          ),
        ),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: Icon(Icons.clear_all_outlined),
            tooltip: 'ล้างข้อมูล',
          ),
          if (_isLoading)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColors.ivoryWhite,
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedType == 'income'
                          ? ThemeColors.oliveGreen
                          : ThemeColors.burntOrange,
                      (_selectedType == 'income'
                              ? ThemeColors.oliveGreen
                              : ThemeColors.burntOrange)
                          .withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_selectedType == 'income'
                                  ? ThemeColors.oliveGreen
                                  : ThemeColors.burntOrange)
                              .withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedType == 'income'
                          ? Icons.add_circle_rounded
                          : Icons.remove_circle_rounded,
                      size: 48,
                      color: ThemeColors.ivoryWhite,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _selectedType == 'income'
                          ? 'เพิ่มรายรับ'
                          : 'เพิ่มรายจ่าย',
                      style: TextStyle(
                        color: ThemeColors.ivoryWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'หมู่บ้าน ${widget.villageId}',
                      style: TextStyle(
                        color: ThemeColors.ivoryWhite.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Type Selector
              Text(
                'ประเภทรายการ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.softBrown,
                ),
              ),
              SizedBox(height: 8),
              _buildTypeSelector(),
              SizedBox(height: 24),

              // Amount Field
              Text(
                'จำนวนเงิน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.softBrown,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'กรอกจำนวนเงิน',
                  prefixText: '฿ ',
                  prefixStyle: TextStyle(
                    color: ThemeColors.softBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: ThemeColors.beige,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.sandyTan,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.sandyTan,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.softBrown,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.burntOrange,
                      width: 1,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.w500,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนเงิน';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  }
                  if (amount <= 0) {
                    return 'จำนวนเงินต้องมากกว่า 0';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Description Field
              Text(
                'คำอธิบาย',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.softBrown,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'กรอกคำอธิบายรายการ...',
                  filled: true,
                  fillColor: ThemeColors.beige,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.sandyTan,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.sandyTan,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.softBrown,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.burntOrange,
                      width: 1,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
                style: TextStyle(fontSize: 16, color: ThemeColors.softBrown),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกคำอธิบาย';
                  }
                  if (value.trim().length < 3) {
                    return 'คำอธิบายต้องมีอย่างน้อย 3 ตัวอักษร';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Receipt Section
              _buildReceiptSection(),
              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFund,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == 'income'
                        ? ThemeColors.oliveGreen
                        : ThemeColors.burntOrange,
                    foregroundColor: ThemeColors.ivoryWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: ThemeColors.warmStone,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ThemeColors.ivoryWhite,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'กำลังบันทึก...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'เพิ่มรายการกองทุน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
