// lib/pages/committee/add_committee.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/committee_domain.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/committee_model.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/theme/Color.dart';

class CommitteeAddPage extends StatefulWidget {
  final int villageId;

  const CommitteeAddPage({super.key, required this.villageId});

  @override
  State<CommitteeAddPage> createState() => _CommitteeAddPageState();
}

class _CommitteeAddPageState extends State<CommitteeAddPage> {
  // Theme Colors

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _hasChanges = false;
  List<HouseModel> _availableHouses = [];
  HouseModel? _selectedHouse;

  @override
  void initState() {
    super.initState();
    _loadAvailableHouses();
  }

  void _onFormChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _loadAvailableHouses() async {
    setState(() => _isLoading = true);
    try {
      // ดึงข้อมูลทีเดียว แล้วกรองด้วย set (เร็วกว่า loop เรียก API หลายครั้ง)
      final houses = await HouseDomain.getAllInVillage(
        villageId: widget.villageId,
      );
      final committees = await CommitteeDomain.getByVillageId(widget.villageId);
      final assignedHouseIds = committees
          .map((c) => c.houseId)
          .whereType<int>()
          .toSet();

      final available = houses
          .where((h) => !assignedHouseIds.contains(h.houseId))
          .toList();

      if (!mounted) return;
      setState(() {
        _availableHouses = available;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('เกิดข้อผิดพลาดในการโหลดข้อมูลบ้าน: $e');
    }
  }

  Future<void> _createCommittee() async {
    if (_selectedHouse == null) return; // กัน null จาก UI
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final houseId = _selectedHouse!.houseId;

      // ตรวจซ้ำกันชนแบบเร็ว ก่อน insert (กันซ้อนกันจากหลายอุปกรณ์)
      final exists = await CommitteeDomain.hasCommitteeByHouseId(houseId);
      if (exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showErrorDialog('บ้านเลขที่ $houseId มีคณะกรรมการอยู่แล้ว');
        // รีโหลดลิสต์ให้ทันสถานะจริง
        await _loadAvailableHouses();
        return;
      }

      // ไม่กำหนด committee_id ที่นี่ — ให้ Domain เติมอัตโนมัติ (แก้ NOT NULL)
      final created = await CommitteeDomain.create(
        CommitteeModel(villageId: widget.villageId, houseId: houseId),
      );

      if (!mounted) return;
      _showSuccessDialog(created.committeeId);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('เกิดข้อผิดพลาดในการสร้างคณะกรรมการ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(int? createdId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: ThemeColors.oliveGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'สร้างสำเร็จ',
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          createdId == null
              ? 'คณะกรรมการใหม่ถูกสร้างเรียบร้อยแล้ว'
              : 'คณะกรรมการใหม่ถูกสร้างเรียบร้อย (รหัส: $createdId)\nบ้านเลขที่: ${_selectedHouse?.houseId}',
          style: const TextStyle(fontSize: 14, color: ThemeColors.warmStone),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: const Text(
                    'เพิ่มอีก',
                    style: TextStyle(color: ThemeColors.burntOrange),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.oliveGreen,
                    foregroundColor: ThemeColors.ivoryWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('เสร็จสิ้น'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.mutedBurntSienna.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: ThemeColors.mutedBurntSienna,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                color: ThemeColors.clayOrange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: ThemeColors.warmStone, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.burntOrange,
              foregroundColor: ThemeColors.ivoryWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedHouse = null;
      _hasChanges = false;
    });
    _loadAvailableHouses();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: ThemeColors.burntOrange, size: 24),
            SizedBox(width: 12),
            Text(
              'ยืนยันการออก',
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'คุณมีข้อมูลที่ยังไม่ได้บันทึก ต้องการออกจากหน้านี้หรือไม่?',
          style: TextStyle(color: ThemeColors.warmStone, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: ThemeColors.warmStone),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.mutedBurntSienna,
              foregroundColor: ThemeColors.ivoryWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ออกจากหน้า'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: ThemeColors.ivoryWhite,
        appBar: AppBar(
          title: const Text(
            'เพิ่มคณะกรรมการใหม่',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: ThemeColors.softBrown,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          actions: [
            if (_selectedHouse != null && !_isLoading)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _createCommittee,
                tooltip: 'เพิ่มคณะกรรมการ',
              ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeColors.softBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'กำลังประมวลผล...',
                      style: TextStyle(
                        color: ThemeColors.earthClay,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ThemeColors.beige.withOpacity(0.8),
                              ThemeColors.sandyTan.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ThemeColors.warmStone.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: ThemeColors.softBrown,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeColors.softBrown.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.group_add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เพิ่มคณะกรรมการใหม่',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeColors.earthClay,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'หมู่บ้าน: ${widget.villageId}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ThemeColors.warmStone,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ThemeColors.oliveGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeColors.oliveGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: ThemeColors.oliveGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'มีบ้านที่สามารถเพิ่มคณะกรรมการได้: ${_availableHouses.length} บ้าน',
                                style: const TextStyle(
                                  color: ThemeColors.oliveGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ข้อมูลคณะกรรมการ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.earthClay,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        label: 'รหัสหมู่บ้าน',
                        value: widget.villageId.toString(),
                        icon: Icons.location_city,
                      ),
                      const SizedBox(height: 16),
                      _buildHouseSelectionField(),
                      if (_availableHouses.isEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ThemeColors.mutedBurntSienna.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ThemeColors.mutedBurntSienna.withOpacity(
                                0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.warning_amber,
                                color: ThemeColors.mutedBurntSienna,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'ไม่มีบ้านที่สามารถเพิ่มคณะกรรมการได้',
                                style: TextStyle(
                                  color: ThemeColors.mutedBurntSienna,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'บ้านทั้งหมดในหมู่บ้านนี้มีคณะกรรมการแล้ว',
                                style: TextStyle(
                                  color: Color(0xFFC8755A),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (await _onWillPop())
                                        Navigator.of(context).pop();
                                    },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('ยกเลิก'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ThemeColors.mutedBurntSienna,
                                side: const BorderSide(
                                  color: ThemeColors.mutedBurntSienna,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_selectedHouse != null &&
                                      !_isLoading &&
                                      _availableHouses.isNotEmpty)
                                  ? _createCommittee
                                  : null,
                              icon: const Icon(Icons.add),
                              label: const Text('เพิ่มคณะกรรมการ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedHouse != null
                                    ? ThemeColors.oliveGreen
                                    : ThemeColors.warmStone,
                                foregroundColor: ThemeColors.ivoryWhite,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: _selectedHouse != null ? 4 : 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ThemeColors.earthClay,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.sandyTan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThemeColors.warmStone.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: ThemeColors.warmStone, size: 20),
              const SizedBox(width: 12),
              Text(
                value,
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
    );
  }

  Widget _buildHouseSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลือกบ้าน',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ThemeColors.earthClay,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _availableHouses.isEmpty
                ? ThemeColors.warmStone.withOpacity(0.1)
                : ThemeColors.ivoryWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedHouse != null
                  ? ThemeColors.oliveGreen
                  : _availableHouses.isEmpty
                  ? ThemeColors.mutedBurntSienna.withOpacity(0.5)
                  : ThemeColors.warmStone.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<HouseModel>(
              value: _selectedHouse,
              hint: Row(
                children: [
                  Icon(
                    Icons.home,
                    color: _availableHouses.isEmpty
                        ? ThemeColors.mutedBurntSienna
                        : ThemeColors.warmStone,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _availableHouses.isEmpty
                        ? 'ไม่มีบ้านที่สามารถเลือกได้'
                        : 'เลือกบ้าน...',
                    style: TextStyle(
                      color: _availableHouses.isEmpty
                          ? ThemeColors.mutedBurntSienna
                          : ThemeColors.warmStone,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: _availableHouses.isEmpty
                    ? ThemeColors.mutedBurntSienna
                    : ThemeColors.earthClay,
              ),
              isExpanded: true,
              items: _availableHouses.map((house) {
                return DropdownMenuItem<HouseModel>(
                  value: house,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home,
                        color: ThemeColors.softBrown,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'บ้านเลขที่: ${house.houseId}',
                              style: TextStyle(
                                fontSize: 16,
                                color: ThemeColors.earthClay,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (house.houseNumber != null ||
                                house.owner != null)
                              Text(
                                '${house.houseNumber ?? 'ไม่ระบุหมายเลข'} • ${house.owner ?? 'ไม่ระบุเจ้าของ'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeColors.warmStone,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _availableHouses.isEmpty
                  ? null
                  : (HouseModel? newValue) {
                      setState(() {
                        _selectedHouse = newValue;
                        _onFormChanged();
                      });
                    },
              dropdownColor: ThemeColors.ivoryWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_selectedHouse != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.oliveGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ThemeColors.oliveGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: ThemeColors.oliveGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกแล้ว: บ้านเลขที่ ${_selectedHouse!.houseId}',
                        style: const TextStyle(
                          color: ThemeColors.oliveGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedHouse!.owner != null)
                        Text(
                          'เจ้าของ: ${_selectedHouse!.owner}',
                          style: TextStyle(
                            color: ThemeColors.oliveGreen.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
