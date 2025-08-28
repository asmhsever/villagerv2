import 'package:flutter/material.dart';
import 'package:fullproject/domains/guard_domain.dart';
import 'package:fullproject/models/guard_model.dart';
import 'package:fullproject/theme/Color.dart';

class HouseGuardListPage extends StatefulWidget {
  final int villageId;

  const HouseGuardListPage({super.key, required this.villageId});

  @override
  State<HouseGuardListPage> createState() => _HouseGuardListPageState();
}

class _HouseGuardListPageState extends State<HouseGuardListPage> {
  // Theme Colors

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: const Text(
          'รายชื่อเจ้าหน้าที่รักษาความปลอดภัย',
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
      ),
      body: FutureBuilder<List<GuardModel>>(
        future: GuardDomain.getByVillageId(widget.villageId),
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
                    'กำลังโหลดข้อมูลเจ้าหน้าที่...',
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
                      Icons.security,
                      size: 64,
                      color: ThemeColors.earthClay,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีข้อมูลเจ้าหน้าที่',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีเจ้าหน้าที่รักษาความปลอดภัยในหมู่บ้านนี้',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final guards = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Container(
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
                        Icons.people,
                        color: ThemeColors.softBrown,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'จำนวนเจ้าหน้าที่: ${guards.length} คน',
                        style: TextStyle(
                          color: ThemeColors.earthClay,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Guards List
                Expanded(
                  child: ListView.builder(
                    itemCount: guards.length,
                    itemBuilder: (context, index) {
                      final guard = guards[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildGuardCard(guard, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuardCard(GuardModel guard, int index) {
    // สีสำหรับแต่ละ card ที่หมุนเวียน
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
            mainAxisSize: MainAxisSize.min, // เพื่อให้ Card ไม่สูง
            children: [
              // Header with Avatar and Name
              Row(
                children: [
                  Container(
                    width: 50, // ลดขนาด Avatar
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
                      Icons.person,
                      color: Colors.white,
                      size: 24, // ลดขนาด Icon
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👮‍♂️ เจ้าหน้าที่',
                          style: TextStyle(
                            color: ThemeColors.earthClay,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${guard.firstName ?? ''} ${guard.lastName ?? ''}'
                                  .trim()
                                  .isNotEmpty
                              ? '${guard.firstName ?? ''} ${guard.lastName ?? ''}'
                                    .trim()
                              : guard.nickname ?? 'ไม่ระบุชื่อ',
                          style: TextStyle(
                            fontSize: 18, // ลดขนาดฟอนต์
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Status Badge แบบ inline
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
                                'ปฏิบัติงาน',
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
                ],
              ),
              const SizedBox(height: 20),

              // Guard Details แบบ horizontal
              Row(
                children: [
                  // รหัสเจ้าหน้าที่
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'รหัส',
                      value: guard.guardId?.toString() ?? 'ไม่ระบุ',
                      color: cardColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ชื่อเล่น
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'ชื่อเล่น',
                      value: guard.nickname ?? 'ไม่ระบุ',
                      color: cardColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // เบอร์โทรศัพท์
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'เบอร์โทร',
                      value: guard.phone ?? 'ไม่ระบุ',
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

  // Helper Widget สำหรับแสดงข้อมูลแบบกะทัดรัด
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
