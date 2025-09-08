// lib/pages/committee/committee_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/models/committee_model.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/domains/committee_domain.dart';
import 'package:fullproject/theme/Color.dart';

import 'edit_committee.dart';

class CommitteeDetailPage extends StatefulWidget {
  final CommitteeModel committee;

  const CommitteeDetailPage({super.key, required this.committee});

  @override
  State<CommitteeDetailPage> createState() => _CommitteeDetailPageState();
}

class _CommitteeDetailPageState extends State<CommitteeDetailPage> {
  late CommitteeModel currentCommittee;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    currentCommittee = widget.committee;
  }

  Future<void> _navigateToEditCommittee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommitteeEditPage(
          committee: currentCommittee,
          villageId: currentCommittee.villageId ?? 0,
        ),
      ),
    );

    if (result == true && mounted) {
      // รีเฟรชข้อมูลหลังจากแก้ไข
      await _refreshCommitteeData();
    }
  }

  Future<void> _refreshCommitteeData() async {
    setState(() => _isRefreshing = true);
    try {
      // ดึงข้อมูลล่าสุดจากฐานข้อมูล
      final committees = await CommitteeDomain.getByVillage(
        villageId: currentCommittee.villageId ?? 0,
      );
      final updatedCommittee = committees.firstWhere(
            (c) => c.committeeId == currentCommittee.committeeId,
        orElse: () => currentCommittee,
      );

      if (mounted) {
        setState(() {
          currentCommittee = updatedCommittee;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการรีเฟรชข้อมูล: $e'),
            backgroundColor: ThemeColors.mutedBurntSienna,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
                child: Icon(Icons.warning_amber, color: ThemeColors.mutedBurntSienna, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'ยืนยันการลบ',
                style: TextStyle(
                  color: ThemeColors.earthClay,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'ต้องการลบคณะกรรมการ ${_getDisplayName(currentCommittee)} ใช่หรือไม่?',
            style: TextStyle(color: ThemeColors.warmStone, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: ThemeColors.warmStone),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.mutedBurntSienna,
                foregroundColor: ThemeColors.ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isRefreshing = true);
    try {
      await CommitteeDomain.delete(currentCommittee.committeeId!);
      if (!mounted) return;

      // กลับไปหน้าก่อนหน้าและส่งสัญญาณว่าได้ลบแล้ว
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: ThemeColors.ivoryWhite, size: 20),
              const SizedBox(width: 8),
              Text('ลบคณะกรรมการสำเร็จ'),
            ],
          ),
          backgroundColor: ThemeColors.oliveGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: ThemeColors.ivoryWhite, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('ลบไม่สำเร็จ: $e')),
            ],
          ),
          backgroundColor: ThemeColors.mutedBurntSienna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _getDisplayName(CommitteeModel committee) {
    final full = '${committee.firstName ?? ''} ${committee.lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : 'คณะกรรมการ #${committee.committeeId}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    String getFirstChar(String s) {
      final it = s.runes.iterator;
      return it.moveNext() ? String.fromCharCode(it.current).toUpperCase() : '?';
    }

    String getLastChar(String s) {
      int? last;
      for (final r in s.runes) {
        last = r;
      }
      return String.fromCharCode(last ?? 63).toUpperCase();
    }

    return parts.length == 1
        ? getFirstChar(parts.first)
        : '${getFirstChar(parts.first)}${getLastChar(parts.last)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text(
          'รายละเอียดคณะกรรมการ',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _isRefreshing ? null : _navigateToEditCommittee,
            tooltip: 'แก้ไขข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isRefreshing ? null : _confirmDelete,
            tooltip: 'ลบคณะกรรมการ',
          ),
        ],
      ),
      body: _isRefreshing
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังประมวลผล...',
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshCommitteeData,
        color: ThemeColors.softBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              _buildProfileCard(),
              const SizedBox(height: 20),

              // Personal Information
              _buildPersonalInfoCard(),
              const SizedBox(height: 20),

              // Contact Information
              _buildContactInfoCard(),
              const SizedBox(height: 20),

              // System Information
              _buildSystemInfoCard(),
              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Center(
      child: Card(
        elevation: 8,
        shadowColor: ThemeColors.softBrown.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ThemeColors.ivoryWhite, ThemeColors.softBrown.withOpacity(0.1)],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // รูปโปรไฟล์
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.softBrown.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: currentCommittee.img != null && currentCommittee.img!.isNotEmpty
                      ? BuildImage(
                    imagePath: currentCommittee.img!,
                    tablePath: 'committee',
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    placeholder: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: ThemeColors.softBrown,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: ThemeColors.softBrown,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_getDisplayName(currentCommittee)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                      : Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: ThemeColors.softBrown,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_getDisplayName(currentCommittee)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ชื่อ-นามสกุล
              Text(
                _getDisplayName(currentCommittee),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: ThemeColors.oliveGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: ThemeColors.oliveGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ThemeColors.oliveGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'คณะกรรมการหมู่บ้าน',
                      style: TextStyle(
                        color: ThemeColors.oliveGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: ThemeColors.burntOrange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThemeColors.ivoryWhite, ThemeColors.burntOrange.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: ThemeColors.burntOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.earthClay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: Icons.person,
              label: 'ชื่อ',
              value: currentCommittee.firstName ?? 'ไม่ระบุ',
              color: ThemeColors.burntOrange,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'นามสกุล',
              value: currentCommittee.lastName ?? 'ไม่ระบุ',
              color: ThemeColors.burntOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: ThemeColors.oliveGreen.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThemeColors.ivoryWhite, ThemeColors.oliveGreen.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.contact_phone, color: ThemeColors.oliveGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ข้อมูลการติดต่อ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.earthClay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: Icons.phone,
              label: 'เบอร์โทร',
              value: currentCommittee.phone ?? 'ไม่ระบุ',
              color: ThemeColors.oliveGreen,
              onTap: currentCommittee.phone != null && currentCommittee.phone!.isNotEmpty
                  ? () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: currentCommittee.phone!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('คัดลอกหมายเลขโทรศัพท์แล้ว'),
                    backgroundColor: ThemeColors.oliveGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
                  : null,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.home,
              label: 'รหัสบ้าน',
              value: currentCommittee.houseId?.toString() ?? 'ไม่ระบุ',
              color: ThemeColors.oliveGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: ThemeColors.clayOrange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThemeColors.ivoryWhite, ThemeColors.clayOrange.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.clayOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: ThemeColors.clayOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ข้อมูลระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.earthClay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: Icons.badge,
              label: 'รหัสคณะกรรมการ',
              value: currentCommittee.committeeId?.toString() ?? 'ไม่ระบุ',
              color: ThemeColors.clayOrange,
              onTap: () {
                Clipboard.setData(ClipboardData(text: currentCommittee.committeeId?.toString() ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('คัดลอกรหัสคณะกรรมการแล้ว'),
                    backgroundColor: ThemeColors.oliveGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.home,
              label: 'รหัสหมู่บ้าน',
              value: currentCommittee.villageId?.toString() ?? 'ไม่ระบุ',
              color: ThemeColors.clayOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ThemeColors.warmStone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, color: color.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _navigateToEditCommittee,
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไขข้อมูล'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.softBrown,
              foregroundColor: ThemeColors.ivoryWhite,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isRefreshing ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('ลบคณะกรรมการ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ThemeColors.mutedBurntSienna,
              side: BorderSide(color: ThemeColors.mutedBurntSienna, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}