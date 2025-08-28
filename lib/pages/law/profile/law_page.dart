// lib/pages/law/profile/law_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/domains/law_domain.dart';
import 'package:fullproject/pages/law/profile/law_edit_page.dart';
import 'package:fullproject/services/auth_service.dart';

class LawPage extends StatefulWidget {
  final int villageId;

  const LawPage({
    super.key,
    required this.villageId,
  });

  @override
  State<LawPage> createState() => _LawPageState();
}

class _LawPageState extends State<LawPage> {
  LawModel? _currentUser;
  bool _isLoading = true;

  // Theme Colors
  static const Color _softBrown = Color(0xFFA47551);
  static const Color _ivoryWhite = Color(0xFFFFFDF6);
  static const Color _beige = Color(0xFFF5F0E1);
  static const Color _sandyTan = Color(0xFFD8CAB8);
  static const Color _earthClay = Color(0xFFBFA18F);
  static const Color _warmStone = Color(0xFFC7B9A5);
  static const Color _oliveGreen = Color(0xFFA3B18A);
  static const Color _burntOrange = Color(0xFFE08E45);
  static const Color _softBorder = Color(0xFFD0C4B0);
  static const Color _inputFill = Color(0xFFFBF9F3);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // --- Helpers ---
  String _formatGender(String? gender) {
    switch (gender) {
      case 'M':
        return 'ชาย';
      case 'F':
        return 'หญิง';
      default:
        return 'ไม่ระบุ';
    }
  }

  String _calculateAge(String? birthDate) {
    if (birthDate == null) return 'ไม่ระบุ';
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return '$age ปี';
    } catch (_) {
      return 'ไม่ระบุ';
    }
  }

  String _formatBirthDate(String birthDate) {
    try {
      final date = DateTime.parse(birthDate);
      const thaiMonths = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
    } catch (_) {
      return birthDate;
    }
  }

  // --- Data ---
  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;

      if (user is LawModel) {
        // ดึงข้อมูลครบถ้วนจาก database
        final fullUserData = await LawDomain.getById(user.lawId);
        setState(() {
          _currentUser = fullUserData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog('ไม่พบข้อมูลผู้ใช้');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  // --- UI helpers ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('เกิดข้อผิดพลาด', style: TextStyle(fontWeight: FontWeight.bold, color: _softBrown)),
        content: Text(message, style: const TextStyle(color: _earthClay)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง', style: TextStyle(color: _burntOrange)),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawEditPage(villageId: widget.villageId, law: _currentUser),
      ),
    );
    if (result == true) {
      _loadCurrentUser(); // รีโหลดข้อมูลหลังแก้ไข
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isAddress = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _warmStone.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _warmStone,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: _earthClay,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _softBorder.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _warmStone.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: _warmStone,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _earthClay,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivoryWhite,
      appBar: AppBar(
        backgroundColor: _softBrown,
        elevation: 0,
        title: const Text(
          'ข้อมูลส่วนตัว',
          style: TextStyle(color: _ivoryWhite, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _ivoryWhite),
        actions: [
          IconButton(
            onPressed: _loadCurrentUser,
            icon: const Icon(Icons.refresh, color: _ivoryWhite),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_burntOrange),
            ),
            const SizedBox(height: 16),
            const Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(color: _earthClay, fontSize: 16),
            ),
          ],
        ),
      )
          : _currentUser == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_off, size: 64, color: _warmStone),
            SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลผู้ใช้',
              style: TextStyle(color: _earthClay, fontSize: 18),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadCurrentUser,
        color: _softBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [_softBrown, _burntOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _warmStone.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _currentUser!.img != null && _currentUser!.img!.isNotEmpty
                          ? NetworkImage(_currentUser!.img!)
                          : null,
                      child: _currentUser!.img == null || _currentUser!.img!.isEmpty
                          ? const Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentUser!.fullName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'นิติบุคคลหมู่บ้าน',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    title: 'เพศ',
                    value: _formatGender(_currentUser!.gender),
                    color: _currentUser!.gender == 'M' ? _oliveGreen : _burntOrange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    icon: Icons.cake,
                    title: 'อายุ',
                    value: _calculateAge(_currentUser!.birthDate),
                    color: _warmStone,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Detailed Information
              if (_currentUser!.phone != null && _currentUser!.phone!.isNotEmpty) ...[
                _buildInfoCard(
                  icon: Icons.phone,
                  title: 'เบอร์โทรศัพท์',
                  value: _currentUser!.phone!,
                  color: _oliveGreen,
                ),
                const SizedBox(height: 16),
              ],

              if (_currentUser!.address != null && _currentUser!.address!.isNotEmpty) ...[
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'ที่อยู่',
                  value: _currentUser!.address!,
                  color: _burntOrange,
                  isAddress: true,
                ),
                const SizedBox(height: 16),
              ],

              if (_currentUser!.birthDate != null && _currentUser!.birthDate!.isNotEmpty) ...[
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'วันเกิด',
                  value: _formatBirthDate(_currentUser!.birthDate!),
                  color: _softBrown,
                ),
                const SizedBox(height: 16),
              ],

              _buildInfoCard(
                icon: Icons.location_city,
                title: 'หมู่บ้าน',
                value: 'ID: ${_currentUser!.villageId}',
                color: _earthClay,
              ),
              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.badge,
                title: 'รหัสผู้ใช้',
                value: 'ID: ${_currentUser!.userId}',
                color: _warmStone,
              ),
              const SizedBox(height: 32),

              // Edit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('แก้ไขข้อมูลส่วนตัว'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _burntOrange,
                    foregroundColor: _ivoryWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}