// lib/pages/law/fund/fund_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/funds_domain.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:fullproject/pages/law/fund/fund_detail_page.dart';
import 'package:fullproject/pages/law/fund/fund_add_page.dart';
import 'package:fullproject/pages/law/fund/fund_edit_page.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawFundPage extends StatefulWidget {
  final int villageId;

  // RouteObserver ใช้ตรวจจับการกลับเข้าหน้านี้จากหน้าอื่น
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  const LawFundPage({Key? key, required this.villageId}) : super(key: key);

  @override
  State<LawFundPage> createState() => _LawFundPageState();
}

class _LawFundPageState extends State<LawFundPage> with RouteAware {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  // State management
  List<FundModel> _allFunds = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';
  Map<String, double> _totals = {'income': 0.0, 'outcome': 0.0, 'balance': 0.0};
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _initializeFunds();
  }

  // subscribe กับ RouteObserver เมื่อมี context แล้ว
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      LawFundPage.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    LawFundPage.routeObserver.unsubscribe(this);
    super.dispose();
  }

  // ถูกเรียกเมื่อ pop หน้าบนออก แล้วกลับมาเห็นหน้านี้อีกครั้ง
  @override
  void didPopNext() {
    _reloadOnReturn();
  }

  // --- Loading (dashboard-style) ---
  Future<void> _initializeFunds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final funds = await _loadFunds();
      if (!mounted) return;
      setState(() {
        _allFunds = funds;
        _totals = _calculateTotals(funds);
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}';
      });
    }
  }

  /// โหลดใหม่ทุกครั้งที่กลับเข้าหน้า พร้อม overlay
  Future<void> _reloadOnReturn() async {
    if (!mounted) return;
    _showLoadingDialog('กำลังรีเฟรชข้อมูล...');
    try {
      final funds = await _loadFunds();
      if (!mounted) return;
      setState(() {
        _allFunds = funds;
        _totals = _calculateTotals(funds);
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('โหลดข้อมูลล้มเหลว: $e');
    } finally {
      if (mounted) Navigator.of(context).pop(); // ปิด dialog
    }
  }

  /// ดึงข้อมูลจริงอย่างเดียว ไม่แตะ state (data layer)
  Future<List<FundModel>> _loadFunds() async {
    try {
      final funds = await FundDomain.getByVillageId(widget.villageId);
      return funds;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    await _initializeFunds();
  }

  // Loading overlay helper
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeColors.beige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: ThemeColors.softBrown,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawFundAddPage(villageId: widget.villageId),
      ),
    );

    if (result == true) {
      _showLoadingDialog('กำลังอัพเดตข้อมูล...');
      try {
        final funds = await _loadFunds();
        if (!mounted) return;
        setState(() {
          _allFunds = funds;
          _totals = _calculateTotals(funds);
          _lastUpdated = DateTime.now();
        });
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: ThemeColors.ivoryWhite),
                  SizedBox(width: 8),
                  Text('เพิ่มข้อมูลเรียบร้อย'),
                ],
              ),
              backgroundColor: ThemeColors.oliveGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('เกิดข้อผิดพลาดในการอัพเดตข้อมูล: $e');
      }
    }
  }

  Future<void> _navigateToEditPage(FundModel fund) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LawFundEditPage(fund: fund)),
    );

    if (result == true) {
      _showLoadingDialog('กำลังอัพเดตข้อมูล...');
      try {
        final funds = await _loadFunds();
        if (!mounted) return;
        setState(() {
          _allFunds = funds;
          _totals = _calculateTotals(funds);
          _lastUpdated = DateTime.now();
        });
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: ThemeColors.ivoryWhite),
                  SizedBox(width: 8),
                  Text('แก้ไขข้อมูลเรียบร้อย'),
                ],
              ),
              backgroundColor: ThemeColors.oliveGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('เกิดข้อผิดพลาดในการอัพเดตข้อมูล: $e');
      }
    }
  }

  Future<void> _navigateToDetailPage(FundModel fund) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LawFundDetailPage(fund: fund)),
    );

    if (result == true) {
      _showLoadingDialog('กำลังอัพเดตข้อมูล...');
      try {
        final funds = await _loadFunds();
        if (!mounted) return;
        setState(() {
          _allFunds = funds;
          _totals = _calculateTotals(funds);
          _lastUpdated = DateTime.now();
        });
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: ThemeColors.ivoryWhite),
                  SizedBox(width: 8),
                  Text('อัพเดตข้อมูลเรียบร้อย'),
                ],
              ),
              backgroundColor: ThemeColors.oliveGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('เกิดข้อผิดพลาดในการอัพเดตข้อมูล: $e');
      }
    }
  }

  // Utility methods
  Map<String, double> _calculateTotals(List<FundModel> funds) {
    final totalIncome = funds.where((fund) => fund.type == 'income').fold(0.0, (sum, fund) => sum + fund.amount);
    final totalOutcome = funds.where((fund) => fund.type == 'outcome').fold(0.0, (sum, fund) => sum + fund.amount);
    final balance = totalIncome - totalOutcome;
    return {'income': totalIncome, 'outcome': totalOutcome, 'balance': balance};
  }

  List<FundModel> _filterFunds(List<FundModel> funds) {
    switch (_selectedFilter) {
      case 'income':
        return funds.where((fund) => fund.type == 'income').toList();
      case 'outcome':
        return funds.where((fund) => fund.type == 'outcome').toList();
      default:
        return funds;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  String _formatLastUpdated(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'อัพเดตเมื่อสักครู่';
    if (difference.inMinutes < 60) return 'อัพเดต ${difference.inMinutes} นาทีที่แล้ว';
    if (difference.inHours < 24) return 'อัพเดต ${difference.inHours} ชั่วโมงที่แล้ว';
    return 'อัพเดต ${difference.inDays} วันที่แล้ว';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.beige,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('เกิดข้อผิดพลาด', style: TextStyle(color: ThemeColors.softBrown, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: ThemeColors.earthClay)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง', style: TextStyle(color: ThemeColors.burntOrange))),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(FundModel fund) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: ThemeColors.beige,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 4, decoration: BoxDecoration(color: ThemeColors.warmStone, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('ตัวเลือก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ThemeColors.softBrown)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(icon: Icons.visibility_outlined, label: 'ดูรายละเอียด', color: ThemeColors.softBrown, onTap: () {
                    Navigator.pop(context);
                    _navigateToDetailPage(fund);
                  }),
                  _buildOptionButton(icon: Icons.edit_outlined, label: 'แก้ไข', color: ThemeColors.softTerracotta, onTap: () {
                    Navigator.pop(context);
                    _navigateToEditPage(fund);
                  }),
                  _buildOptionButton(icon: Icons.delete_outline, label: 'ลบ', color: ThemeColors.burntOrange, onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteFund(fund);
                  }),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(0.3), width: 2)),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDeleteFund(FundModel fund) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.beige,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ยืนยันการลบ', style: TextStyle(color: ThemeColors.softBrown, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('คุณต้องการลบรายการนี้หรือไม่?', style: TextStyle(color: ThemeColors.earthClay)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ThemeColors.warmStone.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: ThemeColors.sandyTan, width: 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fund.description, style: const TextStyle(color: ThemeColors.softBrown, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(fund.amount),
                      style: TextStyle(
                        color: fund.type == 'income' ? ThemeColors.oliveGreen : ThemeColors.burntOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('การดำเนินการนี้ไม่สามารถยกเลิกได้', style: TextStyle(color: ThemeColors.burntOrange, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก', style: TextStyle(color: ThemeColors.warmStone))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteFund(fund);
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeColors.burntOrange, foregroundColor: ThemeColors.ivoryWhite),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFund(FundModel fund) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: ThemeColors.beige,
          content: Row(
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown)),
              SizedBox(width: 20),
              Text('กำลังลบรายการ...', style: TextStyle(color: ThemeColors.softBrown)),
            ],
          ),
        );
      },
    );

    try {
      await FundDomain.delete(fund.fundId);
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: ThemeColors.ivoryWhite),
              SizedBox(width: 8),
              Text('ลบรายการเรียบร้อยแล้ว'),
            ],
          ),
          backgroundColor: ThemeColors.oliveGreen,
          duration: Duration(seconds: 3),
        ),
      );

      _refreshData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('เกิดข้อผิดพลาดในการลบ: $e');
    }
  }

  // UI Building methods
  Widget _buildBalanceCard(Map<String, double> totals) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ThemeColors.softBrown, ThemeColors.burntOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: ThemeColors.earthClay.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          const Text('ยอดคงเหลือ', style: TextStyle(color: ThemeColors.ivoryWhite, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(_formatCurrency(totals['balance']!), style: const TextStyle(color: ThemeColors.ivoryWhite, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: const [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.trending_up_rounded, color: ThemeColors.oliveGreen, size: 20), SizedBox(width: 6), Text('รายรับ', style: TextStyle(color: ThemeColors.ivoryWhite, fontSize: 14, fontWeight: FontWeight.w500))]),
                      SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: const [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.trending_down_rounded, color: ThemeColors.burntOrange, size: 20), SizedBox(width: 6), Text('รายจ่าย', style: TextStyle(color: ThemeColors.ivoryWhite, fontSize: 14, fontWeight: FontWeight.w500))]),
                      SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: ThemeColors.beige, borderRadius: BorderRadius.circular(12), border: Border.all(color: ThemeColors.sandyTan, width: 1)),
      child: Row(
        children: [
          Expanded(child: _buildFilterTab('all', 'ทั้งหมด', Icons.list_rounded)),
          Expanded(child: _buildFilterTab('income', 'รายรับ', Icons.trending_up_rounded)),
          Expanded(child: _buildFilterTab('outcome', 'รายจ่าย', Icons.trending_down_rounded)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    final color = filter == 'income' ? ThemeColors.oliveGreen : filter == 'outcome' ? ThemeColors.burntOrange : ThemeColors.softBrown;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: isSelected ? Border.all(color: color, width: 1.5) : null),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : ThemeColors.warmStone),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isSelected ? color : ThemeColors.warmStone, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [ThemeColors.softBrown.withOpacity(0.7), ThemeColors.burntOrange.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.ivoryWhite), strokeWidth: 3),
              SizedBox(height: 16),
              Text('กำลังโหลดข้อมูลกองทุน...', style: TextStyle(color: ThemeColors.ivoryWhite, fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text('โปรดรอสักครู่', style: TextStyle(color: ThemeColors.ivoryWhite, fontSize: 14)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: ThemeColors.beige.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 60, height: 20, decoration: BoxDecoration(color: ThemeColors.warmStone.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              Container(width: 60, height: 20, decoration: BoxDecoration(color: ThemeColors.warmStone.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              Container(width: 60, height: 20, decoration: BoxDecoration(color: ThemeColors.warmStone.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown), strokeWidth: 3),
                SizedBox(height: 16),
                Text('กำลังประมวลผลข้อมูล...', style: TextStyle(color: ThemeColors.earthClay, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      children: [
        _buildBalanceCard({'income': 0.0, 'outcome': 0.0, 'balance': 0.0}),
        _buildFilterTabs(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: ThemeColors.burntOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.error_outline, size: 48, color: ThemeColors.burntOrange)),
                const SizedBox(height: 20),
                const Text('เกิดข้อผิดพลาด', style: TextStyle(color: ThemeColors.earthClay, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(error, style: const TextStyle(color: ThemeColors.warmStone, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                  style: ElevatedButton.styleFrom(backgroundColor: ThemeColors.softBrown, foregroundColor: ThemeColors.ivoryWhite, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildBalanceCard({'income': 0.0, 'outcome': 0.0, 'balance': 0.0}),
        _buildFilterTabs(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: ThemeColors.beige, borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: ThemeColors.warmStone)),
                const SizedBox(height: 20),
                Text(_selectedFilter == 'all' ? 'ไม่มีข้อมูลกองทุน' : _selectedFilter == 'income' ? 'ไม่มีรายการรายรับ' : 'ไม่มีรายการรายจ่าย', style: const TextStyle(color: ThemeColors.earthClay, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(_selectedFilter == 'all' ? 'เริ่มต้นโดยการเพิ่มรายการแรก' : 'ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่', style: const TextStyle(color: ThemeColors.warmStone, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToAddPage,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มรายการใหม่'),
                  style: ElevatedButton.styleFrom(backgroundColor: ThemeColors.softBrown, foregroundColor: ThemeColors.ivoryWhite, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFundsList(List<FundModel> allFunds) {
    final filteredFunds = _filterFunds(allFunds);
    return Column(
      children: [
        _buildBalanceCard(_totals),
        _buildFilterTabs(),
        if (_lastUpdated != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('รายการ: ${filteredFunds.length}', style: const TextStyle(color: ThemeColors.warmStone, fontSize: 12)),
                Text(_formatLastUpdated(_lastUpdated), style: const TextStyle(color: ThemeColors.warmStone, fontSize: 12)),
              ],
            ),
          ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: filteredFunds.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: ThemeColors.beige, borderRadius: BorderRadius.circular(50)),
                    child: Icon(_selectedFilter == 'income' ? Icons.trending_up_outlined : _selectedFilter == 'outcome' ? Icons.trending_down_outlined : Icons.account_balance_wallet_outlined, size: 48, color: ThemeColors.warmStone),
                  ),
                  const SizedBox(height: 20),
                  Text(_selectedFilter == 'income' ? 'ไม่มีรายการรายรับ' : _selectedFilter == 'outcome' ? 'ไม่มีรายการรายจ่าย' : 'ไม่มีข้อมูลกองทุน', style: const TextStyle(color: ThemeColors.earthClay, fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่', style: TextStyle(color: ThemeColors.warmStone, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddPage,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มรายการใหม่'),
                    style: ElevatedButton.styleFrom(backgroundColor: ThemeColors.softBrown, foregroundColor: ThemeColors.ivoryWhite, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshData,
              color: ThemeColors.softBrown,
              backgroundColor: ThemeColors.ivoryWhite,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 140),
                itemCount: filteredFunds.length,
                itemBuilder: (context, index) {
                  final fund = filteredFunds[index];
                  final isIncome = fund.type == 'income';
                  final color = isIncome ? ThemeColors.oliveGreen : ThemeColors.burntOrange;
                  final icon = isIncome ? Icons.add_circle_rounded : Icons.remove_circle_rounded;

                  return GestureDetector(
                    onTap: () => _navigateToDetailPage(fund),
                    onLongPress: () => _showOptionsBottomSheet(fund),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ThemeColors.beige,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ThemeColors.sandyTan, width: 1),
                        boxShadow: [BoxShadow(color: ThemeColors.warmStone.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(28), border: Border.all(color: color.withOpacity(0.3), width: 2)),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        title: Text(fund.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: ThemeColors.softBrown)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: ThemeColors.warmStone), const SizedBox(width: 4), Text(_formatDate(fund.createdAt), style: const TextStyle(color: ThemeColors.earthClay, fontSize: 13))]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3), width: 1)),
                                  child: Text('${isIncome ? '+' : '-'}${_formatCurrency(fund.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                if ((fund.receiptImg ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: ThemeColors.softTerracotta.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.receipt, size: 12, color: ThemeColors.softTerracotta),
                                        SizedBox(width: 2),
                                        Text('ใบเสร็จ', style: TextStyle(fontSize: 10, color: ThemeColors.softTerracotta)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showOptionsBottomSheet(fund),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: ThemeColors.warmStone.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.more_vert, color: ThemeColors.warmStone, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text('กองทุนหมู่บ้าน ${widget.villageId}', style: const TextStyle(fontWeight: FontWeight.w600, color: ThemeColors.ivoryWhite, fontSize: 20)),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), tooltip: 'รีเฟรชข้อมูล', onPressed: _refreshData),
          IconButton(icon: const Icon(Icons.add, color: Colors.white), tooltip: 'เพิ่มรายการใหม่', onPressed: _navigateToAddPage),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPage,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการ'),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        tooltip: 'เพิ่มรายการกองทุนใหม่',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState(_errorMessage!)
          : _allFunds.isEmpty
          ? _buildEmptyState()
          : _buildFundsList(_allFunds),
    );
  }
}
