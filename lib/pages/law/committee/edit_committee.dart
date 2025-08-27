// lib/pages/committee/edit_committee.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/committee_domain.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/committee_model.dart';
import 'package:fullproject/models/house_model.dart';

class CommitteeEditPage extends StatefulWidget {
  final CommitteeModel committee;
  final int villageId;

  const CommitteeEditPage({super.key, required this.committee, required this.villageId});

  @override
  State<CommitteeEditPage> createState() => _CommitteeEditPageState();
}

class _CommitteeEditPageState extends State<CommitteeEditPage> {
  // Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color mutedBurntSienna = Color(0xFFC8755A);

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
      final houses = await HouseDomain.getAllInVillage(villageId: widget.villageId);
      final committees = await CommitteeDomain.getByVillageId(widget.villageId);

      // กันบ้านที่ถูกใช้แล้ว แต่ยกเว้นบ้านเดิมของคณะกรรมการคนนี้
      final usedHouseIds = committees
          .where((c) => c.committeeId != widget.committee.committeeId)
          .map((c) => c.houseId)
          .whereType<int>()
          .toSet();

      final available = houses.where((h) => !usedHouseIds.contains(h.houseId)).toList();

      // ตั้งค่า selected = บ้านเดิม หากยังไม่ได้เลือก
      final currentId = widget.committee.houseId;
      HouseModel? current;
      if (currentId != null) {
        current = houses.firstWhere(
              (h) => h.houseId == currentId,
          orElse: () => available.isNotEmpty ? available.first : houses.first,
        );
        // ให้แน่ใจว่าบ้านเดิมเห็นในตัวเลือก
        if (!available.any((h) => h.houseId == currentId)) {
          available.insert(0, current);
        }
      }

      if (!mounted) return;
      setState(() {
        _availableHouses = available;
        _selectedHouse = current;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('เกิดข้อผิดพลาดในการโหลดข้อมูลบ้าน: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_selectedHouse == null) return;
    if (!_formKey.currentState!.validate()) return;

    final newHouseId = _selectedHouse!.houseId;
    final oldHouseId = widget.committee.houseId;

    setState(() => _isLoading = true);
    try {
      // ถ้าเปลี่ยนบ้าน ให้ตรวจว่ามีคณะกรรมการบ้านนี้อยู่แล้วหรือไม่
      if (newHouseId != oldHouseId) {
        final exists = await CommitteeDomain.hasCommitteeByHouseId(newHouseId);
        if (exists) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showErrorDialog('บ้านเลขที่ $newHouseId มีคณะกรรมการอยู่แล้ว');
          await _loadAvailableHouses();
          return;
        }
      }

      final updated = CommitteeModel(
        committeeId: widget.committee.committeeId,
        villageId: widget.villageId,
        houseId: newHouseId,
      );

      await CommitteeDomain.update(widget.committee.committeeId!, updated);

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('เกิดข้อผิดพลาดในการบันทึก: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: oliveGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.check_circle, color: oliveGreen, size: 24)),
          const SizedBox(width: 12),
          Text('บันทึกสำเร็จ', style: TextStyle(color: earthClay, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: const Text('ข้อมูลคณะกรรมการได้รับการอัปเดตเรียบร้อยแล้ว', style: TextStyle(color: warmStone, fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(true); },
            style: ElevatedButton.styleFrom(backgroundColor: oliveGreen, foregroundColor: ivoryWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: mutedBurntSienna.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.error_outline, color: mutedBurntSienna, size: 24)),
          const SizedBox(width: 12),
          Text('เกิดข้อผิดพลาด', style: TextStyle(color: clayOrange, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Text(message, style: const TextStyle(color: warmStone, fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: burntOrange, foregroundColor: ivoryWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [Icon(Icons.warning_amber, color: burntOrange, size: 24), SizedBox(width: 12), Text('ยืนยันการออก', style: TextStyle(color: earthClay, fontSize: 18, fontWeight: FontWeight.bold))]),
        content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกจากหน้านี้หรือไม่?', style: TextStyle(color: warmStone, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('ยกเลิก', style: TextStyle(color: warmStone))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: mutedBurntSienna, foregroundColor: ivoryWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('ออกจากหน้า')),
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
        backgroundColor: ivoryWhite,
        appBar: AppBar(
          title: const Text('แก้ไขข้อมูลคณะกรรมการ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: softBrown,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () async { if (await _onWillPop()) Navigator.of(context).pop(); }),
          actions: [ if (_hasChanges && !_isLoading) IconButton(icon: const Icon(Icons.save, color: Colors.white), onPressed: _saveChanges, tooltip: 'บันทึกการเปลี่ยนแปลง') ],
        ),
        body: _isLoading
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(softBrown)),
          const SizedBox(height: 16),
          Text('กำลังประมวลผล...', style: TextStyle(color: earthClay, fontSize: 14)),
        ]))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [beige.withOpacity(0.8), sandyTan.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: warmStone.withOpacity(0.3), width: 1),
                ),
                child: Row(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: softBrown, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: softBrown.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))]), child: const Icon(Icons.edit, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('แก้ไขข้อมูลคณะกรรมการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthClay)),
                    const SizedBox(height: 4),
                    Text('รหัส: ${widget.committee.committeeId ?? 'ไม่ระบุ'}', style: TextStyle(fontSize: 14, color: warmStone)),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),
              Text('ข้อมูลคณะกรรมการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: earthClay)),
              const SizedBox(height: 16),
              _buildReadOnlyField(label: 'รหัสหมู่บ้าน', value: widget.villageId.toString(), icon: Icons.location_city),
              const SizedBox(height: 16),
              _buildReadOnlyField(label: 'รหัสคณะกรรมการ', value: widget.committee.committeeId?.toString() ?? 'ไม่ระบุ', icon: Icons.badge),
              const SizedBox(height: 16),
              _buildHouseSelectionField(),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () async { if (await _onWillPop()) Navigator.of(context).pop(); },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('ยกเลิก'),
                    style: OutlinedButton.styleFrom(foregroundColor: mutedBurntSienna, side: const BorderSide(color: mutedBurntSienna), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_hasChanges && !_isLoading && _selectedHouse != null) ? _saveChanges : null,
                    icon: const Icon(Icons.save),
                    label: const Text('บันทึก'),
                    style: ElevatedButton.styleFrom(backgroundColor: _hasChanges ? oliveGreen : warmStone, foregroundColor: ivoryWhite, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: _hasChanges ? 4 : 1),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (_hasChanges)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: burntOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: burntOrange.withOpacity(0.3), width: 1)),
                  child: Row(children: const [Icon(Icons.info_outline, color: burntOrange, size: 20), SizedBox(width: 8), Expanded(child: Text('มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก', style: TextStyle(color: burntOrange, fontSize: 12, fontWeight: FontWeight.w500)))]),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: earthClay)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: sandyTan.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: warmStone.withOpacity(0.3), width: 1)),
        child: Row(children: [Icon(icon, color: warmStone, size: 20), const SizedBox(width: 12), Text(value, style: TextStyle(fontSize: 16, color: earthClay, fontWeight: FontWeight.w500))]),
      ),
    ]);
  }

  Widget _buildHouseSelectionField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('เลือกบ้าน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: earthClay)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: ivoryWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _selectedHouse != null ? oliveGreen : warmStone.withOpacity(0.5), width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<HouseModel>(
            value: _selectedHouse,
            hint: Row(children: [Icon(Icons.home, color: warmStone, size: 20), const SizedBox(width: 12), Text('เลือกบ้าน...', style: TextStyle(color: warmStone, fontSize: 16))]),
            icon: Icon(Icons.arrow_drop_down, color: earthClay),
            isExpanded: true,
            items: _availableHouses.map((house) {
              return DropdownMenuItem<HouseModel>(
                value: house,
                child: Row(children: [
                  const Icon(Icons.home, color: softBrown, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('บ้านเลขที่: ${house.houseId} (${house.houseNumber ?? 'ไม่ระบุ'})', style: TextStyle(fontSize: 16, color: earthClay), overflow: TextOverflow.ellipsis)),
                ]),
              );
            }).toList(),
            onChanged: (HouseModel? newValue) {
              setState(() {
                _selectedHouse = newValue;
                _onFormChanged();
              });
            },
            dropdownColor: ivoryWhite,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      if (_selectedHouse != null) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: oliveGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: oliveGreen.withOpacity(0.3), width: 1)),
          child: Row(children: [
            const Icon(Icons.check_circle, color: oliveGreen, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('เลือกบ้าน: ${_selectedHouse!.houseNumber ?? 'ไม่ระบุหมายเลข'} (ID: ${_selectedHouse!.houseId})', style: const TextStyle(color: oliveGreen, fontSize: 12, fontWeight: FontWeight.w500))),
          ]),
        ),
      ],
    ]);
  }
}
