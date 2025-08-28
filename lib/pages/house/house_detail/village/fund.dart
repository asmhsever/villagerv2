import 'package:flutter/material.dart';
import 'package:fullproject/domains/funds_domain.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:fullproject/pages/house/house_detail/village/fund_detail.dart';
import 'package:intl/intl.dart';
import 'package:fullproject/theme/Color.dart';

// Fund Page with Natural Earth Theme using FutureBuilder
class HouseFundPage extends StatefulWidget {
  final int villageId;

  const HouseFundPage({Key? key, required this.villageId}) : super(key: key);

  @override
  State<HouseFundPage> createState() => _HouseFundPageState();
}

class _HouseFundPageState extends State<HouseFundPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // Filter state
  String _selectedFilter = 'all'; // 'all', 'income', 'outcome'

  // Theme Colors

  Future<void> _refreshData() async {
    setState(() {});
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
    final totalIncome = funds
        .where((fund) => fund.type == 'income')
        .fold(0.0, (sum, fund) => sum + fund.amount);

    final totalOutcome = funds
        .where((fund) => fund.type == 'outcome')
        .fold(0.0, (sum, fund) => sum + fund.amount);

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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ThemeColors.beige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.sandyTan, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab('all', 'ทั้งหมด', Icons.list_rounded),
          ),
          Expanded(
            child: _buildFilterTab(
              'income',
              'รายรับ',
              Icons.trending_up_rounded,
            ),
          ),
          Expanded(
            child: _buildFilterTab(
              'outcome',
              'รายจ่าย',
              Icons.trending_down_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    final color = filter == 'income'
        ? ThemeColors.oliveGreen
        : filter == 'outcome'
        ? ThemeColors.burntOrange
        : ThemeColors.softBrown;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              size: 16,
              color: isSelected ? color : ThemeColors.warmStone,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : ThemeColors.warmStone,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, double> totals) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.softBrown,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Balance Amount
          Text(
            _formatCurrency(totals['balance']!),
            style: TextStyle(
              color: ThemeColors.ivoryWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Income and Outcome Row
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: ThemeColors.oliveGreen,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายรับ',
                          style: TextStyle(
                            color: ThemeColors.ivoryWhite.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatCurrency(totals['income']!),
                          style: TextStyle(
                            color: ThemeColors.oliveGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: ThemeColors.ivoryWhite.withOpacity(0.2),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_down_rounded,
                      color: ThemeColors.burntOrange,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายจ่าย',
                          style: TextStyle(
                            color: ThemeColors.ivoryWhite.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatCurrency(totals['outcome']!),
                          style: TextStyle(
                            color: ThemeColors.burntOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Loading Balance Card
        Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeColors.softBrown.withOpacity(0.7),
                ThemeColors.clayOrange.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'กำลังโหลด...',
                style: TextStyle(
                  color: ThemeColors.ivoryWhite.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeColors.ivoryWhite,
                ),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
        // Filter tabs (loading state)
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeColors.beige.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: ThemeColors.warmStone.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: ThemeColors.warmStone.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: ThemeColors.warmStone.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        // Loading List
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ThemeColors.softBrown,
                  ),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'กำลังโหลดข้อมูล...',
                  style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
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
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ThemeColors.beige,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _selectedFilter == 'all'
                      ? 'ไม่มีข้อมูลกองทุน'
                      : _selectedFilter == 'income'
                      ? 'ไม่มีรายการรายรับ'
                      : 'ไม่มีรายการรายจ่าย',
                  style: TextStyle(
                    color: ThemeColors.earthClay,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _selectedFilter == 'all'
                      ? 'เริ่มต้นโดยการเพิ่มรายการแรก'
                      : 'ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่',
                  style: TextStyle(color: ThemeColors.warmStone, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
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
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: ThemeColors.burntOrange,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'เกิดข้อผิดพลาด',
                  style: TextStyle(
                    color: ThemeColors.earthClay,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  error,
                  style: TextStyle(color: ThemeColors.warmStone, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: Icon(Icons.refresh),
                  label: Text('ลองใหม่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.softBrown,
                    foregroundColor: ThemeColors.ivoryWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFundsList(List<FundModel> allFunds) {
    final totals = _calculateTotals(allFunds);
    final filteredFunds = _filterFunds(allFunds);

    return Column(
      children: [
        _buildBalanceCard(totals),
        _buildFilterTabs(),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: filteredFunds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: ThemeColors.beige,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            _selectedFilter == 'income'
                                ? Icons.trending_up_outlined
                                : _selectedFilter == 'outcome'
                                ? Icons.trending_down_outlined
                                : Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: ThemeColors.warmStone,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _selectedFilter == 'income'
                              ? 'ไม่มีรายการรายรับ'
                              : _selectedFilter == 'outcome'
                              ? 'ไม่มีรายการรายจ่าย'
                              : 'ไม่มีข้อมูลกองทุน',
                          style: TextStyle(
                            color: ThemeColors.earthClay,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่',
                          style: TextStyle(
                            color: ThemeColors.warmStone,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
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
                      padding: EdgeInsets.only(bottom: 100),
                      itemCount: filteredFunds.length,
                      itemBuilder: (context, index) {
                        final fund = filteredFunds[index];
                        final isIncome = fund.type == 'income';
                        final color = isIncome
                            ? ThemeColors.oliveGreen
                            : ThemeColors.burntOrange;
                        final icon = isIncome
                            ? Icons.add_circle_rounded
                            : Icons.remove_circle_rounded;

                        return GestureDetector(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: ThemeColors.beige,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ThemeColors.sandyTan,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeColors.warmStone.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(20),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(icon, color: color, size: 28),
                              ),
                              title: Text(
                                fund.description,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: ThemeColors.softBrown,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: ThemeColors.warmStone,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatDate(fund.createdAt),
                                      style: TextStyle(
                                        color: ThemeColors.earthClay,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${isIncome ? '+' : '-'}${_formatCurrency(fund.amount)}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (fund.receiptImg != null) ...[
                                    SizedBox(height: 3),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HouseFundDetailPage(fund: fund),
                              ),
                            );
                          },
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
        title: Text(
          'กองทุนหมู่บ้าน ${widget.villageId}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.ivoryWhite,
            fontSize: 20,
          ),
        ),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
      ),
      body: FutureBuilder<List<FundModel>>(
        future: FundDomain.getByVillageId(widget.villageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState('เกิดข้อผิดพลาด: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildFundsList(snapshot.data!);
          }
        },
      ),
    );
  }
}
