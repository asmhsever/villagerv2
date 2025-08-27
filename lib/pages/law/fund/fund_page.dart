// lib/pages/law/fund/fund_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/funds_domain.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:fullproject/pages/law/fund/fund_detail_page.dart';
import 'package:fullproject/pages/law/fund/fund_add_page.dart';
import 'package:fullproject/pages/law/fund/fund_edit_page.dart';
import 'package:intl/intl.dart';

class LawFundPage extends StatefulWidget {
  final int villageId;
  const LawFundPage({Key? key, required this.villageId}) : super(key: key);

  @override
  State<LawFundPage> createState() => _LawFundPageState();
}

class _LawFundPageState extends State<LawFundPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  String _selectedFilter = 'all'; // 'all', 'income', 'outcome'

  // Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);

  Future<void> _refreshData() async {
    setState(() {});
  }

  Future<void> _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawFundAddPage(villageId: widget.villageId),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _navigateToEditPage(FundModel fund) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawFundEditPage(fund: fund),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _navigateToDetailPage(FundModel fund) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawFundDetailPage(fund: fund),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _showOptionsBottomSheet(FundModel fund) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: beige,
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
                  color: warmStone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'ตัวเลือก',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: softBrown,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.visibility_outlined,
                    label: 'ดูรายละเอียด',
                    color: softBrown,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToDetailPage(fund);
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.edit_outlined,
                    label: 'แก้ไข',
                    color: softTerracotta,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEditPage(fund);
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.delete_outline,
                    label: 'ลบ',
                    color: burntOrange,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteFund(fund);
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

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFund(FundModel fund) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ยืนยันการลบ',
            style: TextStyle(
              color: softBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'คุณต้องการลบรายการนี้หรือไม่?',
                style: TextStyle(color: earthClay),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warmStone.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sandyTan, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund.description,
                      style: TextStyle(
                        color: softBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(fund.amount),
                      style: TextStyle(
                        color: fund.type == 'income' ? oliveGreen : burntOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'การดำเนินการนี้ไม่สามารถยกเลิกได้',
                style: TextStyle(
                  color: burntOrange,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: warmStone),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteFund(fund);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: burntOrange,
                foregroundColor: ivoryWhite,
              ),
              child: Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFund(FundModel fund) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: beige,
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(softBrown),
              ),
              SizedBox(width: 20),
              Text(
                'กำลังลบรายการ...',
                style: TextStyle(color: softBrown),
              ),
            ],
          ),
        );
      },
    );

    try {
      await FundDomain.delete(fund.fundId);
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: ivoryWhite),
              SizedBox(width: 8),
              Text('ลบรายการเรียบร้อยแล้ว'),
            ],
          ),
          backgroundColor: oliveGreen,
          duration: Duration(seconds: 3),
        ),
      );

      _refreshData();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: ivoryWhite),
              SizedBox(width: 8),
              Expanded(child: Text('เกิดข้อผิดพลาดในการลบ: $e')),
            ],
          ),
          backgroundColor: burntOrange,
          duration: Duration(seconds: 4),
        ),
      );
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

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: beige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sandyTan, width: 1),
      ),
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
    final color = filter == 'income' ? oliveGreen : filter == 'outcome' ? burntOrange : softBrown;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: isSelected ? color : warmStone),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isSelected ? color : warmStone, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, double> totals) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softBrown,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: earthClay.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Text(_formatCurrency(totals['balance']!), style: const TextStyle(color: ivoryWhite, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.trending_up_rounded, color: oliveGreen, size: 18),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('รายรับ', style: TextStyle(color: ivoryWhite.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                Text(_formatCurrency(totals['income']!), style: const TextStyle(color: oliveGreen, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
          Container(height: 24, width: 1, color: ivoryWhite.withOpacity(0.2)),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.trending_down_rounded, color: burntOrange, size: 18),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('รายจ่าย', style: TextStyle(color: ivoryWhite.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                Text(_formatCurrency(totals['outcome']!), style: const TextStyle(color: burntOrange, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildLoadingState() {
    return Column(children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [softBrown.withOpacity(0.7), clayOrange.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: const [
          Text('กำลังโหลด...', style: TextStyle(color: ivoryWhite, fontSize: 14, fontWeight: FontWeight.w500)),
          SizedBox(height: 12),
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ivoryWhite), strokeWidth: 2),
        ]),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: beige.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Container(width: 60, height: 20, decoration: BoxDecoration(color: warmStone.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          Container(width: 60, height: 20, decoration: BoxDecoration(color: warmStone.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          Container(width: 60, height: 20, decoration: BoxDecoration(color: warmStone.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
        ]),
      ),
      const Expanded(
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(softBrown), strokeWidth: 3),
          SizedBox(height: 16),
          Text('กำลังโหลดข้อมูล...', style: TextStyle(color: earthClay, fontSize: 16)),
        ])),
      ),
    ]);
  }

  Widget _buildEmptyState() {
    return Column(children: [
      _buildBalanceCard({'income': 0.0, 'outcome': 0.0, 'balance': 0.0}),
      _buildFilterTabs(),
      Expanded(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: beige,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: warmStone,
              ),
            ),
            const SizedBox(height: 20),
            Text(
                _selectedFilter == 'all'
                    ? 'ไม่มีข้อมูลกองทุน'
                    : _selectedFilter == 'income'
                    ? 'ไม่มีรายการรายรับ'
                    : 'ไม่มีรายการรายจ่าย',
                style: const TextStyle(color: earthClay, fontSize: 18, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 8),
            Text(
                _selectedFilter == 'all'
                    ? 'เริ่มต้นโดยการเพิ่มรายการแรก'
                    : 'ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่',
                style: const TextStyle(color: warmStone, fontSize: 14),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddPage,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มรายการใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: softBrown,
                foregroundColor: ivoryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildErrorState(String error) {
    return Column(children: [
      _buildBalanceCard({'income': 0.0, 'outcome': 0.0, 'balance': 0.0}),
      _buildFilterTabs(),
      Expanded(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: burntOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.error_outline, size: 48, color: burntOrange)),
            const SizedBox(height: 20),
            const Text('เกิดข้อผิดพลาด', style: TextStyle(color: earthClay, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: warmStone, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _refreshData, icon: const Icon(Icons.refresh), label: const Text('ลองใหม่'), style: ElevatedButton.styleFrom(backgroundColor: softBrown, foregroundColor: ivoryWhite)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildFundsList(List<FundModel> allFunds) {
    final totals = _calculateTotals(allFunds);
    final filteredFunds = _filterFunds(allFunds);

    return Column(children: [
      _buildBalanceCard(totals),
      _buildFilterTabs(),
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: filteredFunds.isEmpty
              ? Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: beige, borderRadius: BorderRadius.circular(50)),
                child: Icon(_selectedFilter == 'income' ? Icons.trending_up_outlined : _selectedFilter == 'outcome' ? Icons.trending_down_outlined : Icons.account_balance_wallet_outlined, size: 48, color: warmStone),
              ),
              const SizedBox(height: 20),
              Text(_selectedFilter == 'income' ? 'ไม่มีรายการรายรับ' : _selectedFilter == 'outcome' ? 'ไม่มีรายการรายจ่าย' : 'ไม่มีข้อมูลกองทุน', style: const TextStyle(color: earthClay, fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const Text('ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่', style: TextStyle(color: warmStone, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToAddPage,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มรายการใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: softBrown,
                  foregroundColor: ivoryWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ]),
          )
              : RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshData,
            color: softBrown,
            backgroundColor: ivoryWhite,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 140),
              itemCount: filteredFunds.length,
              itemBuilder: (context, index) {
                final fund = filteredFunds[index];
                final isIncome = fund.type == 'income';
                final color = isIncome ? oliveGreen : burntOrange;
                final icon = isIncome ? Icons.add_circle_rounded : Icons.remove_circle_rounded;

                return GestureDetector(
                  onTap: () => _navigateToDetailPage(fund),
                  onLongPress: () => _showOptionsBottomSheet(fund),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: beige,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sandyTan, width: 1),
                      boxShadow: [BoxShadow(color: warmStone.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: color.withOpacity(0.3), width: 2)
                          ),
                          child: Icon(icon, color: color, size: 28)
                      ),
                      title: Text(fund.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: softBrown)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: warmStone),
                            const SizedBox(width: 4),
                            Text(_formatDate(fund.createdAt), style: const TextStyle(color: earthClay, fontSize: 13)),
                          ],
                        ),
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
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: color.withOpacity(0.3), width: 1)
                                ),
                                child: Text('${isIncome ? '+' : '-'}${_formatCurrency(fund.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              if (fund.receiptImg != null && fund.receiptImg!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: softTerracotta.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt, size: 12, color: softTerracotta),
                                      const SizedBox(width: 2),
                                      Text('ใบเสร็จ', style: TextStyle(fontSize: 10, color: softTerracotta)),
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
                              decoration: BoxDecoration(
                                color: warmStone.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.more_vert, color: warmStone, size: 20),
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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
      appBar: AppBar(
        title: Text('กองทุนหมู่บ้าน ${widget.villageId}', style: const TextStyle(fontWeight: FontWeight.w600, color: ivoryWhite, fontSize: 20)),
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'เพิ่มรายการใหม่',
            onPressed: _navigateToAddPage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPage,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการ'),
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FutureBuilder<List<FundModel>>(
        future: FundDomain.getByVillageId(widget.villageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
          if (snapshot.hasError) return _buildErrorState('เกิดข้อผิดพลาด: ${snapshot.error}');
          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();
          return _buildFundsList(snapshot.data!);
        },
      ),
    );
  }
}