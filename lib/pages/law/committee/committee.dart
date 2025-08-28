// lib/pages/committee/committee_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/committee_domain.dart';
import 'package:fullproject/models/committee_model.dart';
import 'package:fullproject/theme/Color.dart';
import 'add_committee.dart';
import 'edit_committee.dart';

class LawCommitteeListPage extends StatefulWidget {
  final int villageId;

  const LawCommitteeListPage({super.key, required this.villageId});

  @override
  State<LawCommitteeListPage> createState() => _LawCommitteeListPageState();
}

class _LawCommitteeListPageState extends State<LawCommitteeListPage> {
  // Theme Colors

  bool _isRefreshing = false; // ป้องกันกดซ้ำตอนกำลังทำงาน

  Future<void> _navigateToAddCommittee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommitteeAddPage(villageId: widget.villageId),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToEditCommittee(CommitteeModel committee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommitteeEditPage(
          committee: committee,
          villageId: widget.villageId,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshList() async {
    // ใช้ setState เพื่อให้ FutureBuilder ยิง query ใหม่
    setState(() => _isRefreshing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _confirmDelete(CommitteeModel committee) async {
    // ป้องกันลบเมื่อไม่มี id
    final id = committee.committeeId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบรหัสคณะกรรมการ เพื่อลบรายการ')),
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('ยืนยันการลบ'),
              content: Text('ต้องการลบคณะกรรมการรหัส $id ใช่หรือไม่?'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.beige,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('ลบ'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    setState(
      () => _isRefreshing = true,
    ); // ใช้สถานะเดียวกับรีเฟรช เพื่อล็อกปุ่ม
    try {
      await CommitteeDomain.delete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบคณะกรรมการสำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        // ยิงโหลดข้อมูลใหม่
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: const Text(
          'รายชื่อคณะกรรมการหมู่บ้าน',
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToAddCommittee,
            tooltip: 'เพิ่มคณะกรรมการใหม่',
          ),
        ],
      ),
      body: FutureBuilder<List<CommitteeModel>>(
        future: CommitteeDomain.getByVillageId(widget.villageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
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
                    'กำลังโหลดข้อมูลคณะกรรมการ...',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ThemeColors.mutedBurntSienna,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      color: ThemeColors.clayOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: ThemeColors.mutedBurntSienna,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.burntOrange,
                      foregroundColor: ThemeColors.ivoryWhite,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ThemeColors.sandyTan.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ThemeColors.warmStone.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.groups,
                      size: 64,
                      color: ThemeColors.earthClay,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีข้อมูลคณะกรรมการ',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีคณะกรรมการในหมู่บ้านนี้',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddCommittee,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มคณะกรรมการใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.oliveGreen,
                      foregroundColor: ThemeColors.ivoryWhite,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final committees = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.beige.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeColors.warmStone.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups,
                              color: ThemeColors.softBrown,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'จำนวนคณะกรรมการ: ${committees.length} คน',
                              style: TextStyle(
                                color: ThemeColors.earthClay,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeColors.oliveGreen.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isRefreshing
                            ? null
                            : _navigateToAddCommittee,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.oliveGreen,
                          foregroundColor: ThemeColors.ivoryWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'เพิ่ม',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshList,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: committees.length,
                      itemBuilder: (context, index) {
                        final committee = committees[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildCommitteeCard(committee, index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommitteeCard(CommitteeModel committee, int index) {
    final cardColors = [
      ThemeColors.softBrown,
      ThemeColors.burntOrange,
      ThemeColors.oliveGreen,
      ThemeColors.softTerracotta,
      ThemeColors.clayOrange,
      ThemeColors.mutedBurntSienna,
    ];
    final cardColor = cardColors[index % cardColors.length];

    return Card(
      elevation: 4,
      shadowColor: cardColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThemeColors.ivoryWhite, cardColor.withOpacity(0.1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.badge,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'คณะกรรมการคนที่ ${index + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors.oliveGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ThemeColors.oliveGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: ThemeColors.oliveGreen,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ดำรงตำแหน่ง',
                                style: TextStyle(
                                  color: ThemeColors.oliveGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ปุ่มแก้ไข
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.burntOrange.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: ThemeColors.burntOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isRefreshing
                            ? null
                            : () => _navigateToEditCommittee(committee),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.edit,
                            color: ThemeColors.burntOrange,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มลบ
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.beige.withOpacity(0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: ThemeColors.beige.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isRefreshing
                            ? null
                            : () => _confirmDelete(committee),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline,
                            color: ThemeColors.beige,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'รหัส',
                      value: committee.committeeId?.toString() ?? 'ไม่ระบุ',
                      color: cardColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'บ้าน',
                      value: committee.houseId?.toString() ?? 'ไม่ระบุ',
                      color: cardColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'หมู่บ้าน',
                      value: committee.villageId?.toString() ?? 'ไม่ระบุ',
                      color: cardColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetailItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: ThemeColors.earthClay,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
