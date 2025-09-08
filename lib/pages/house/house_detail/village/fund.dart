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
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth; // null = all months

  // Get available years from funds
  List<int> _getAvailableYears(List<FundModel> funds) {
    final years = funds
        .where((fund) => fund.createdAt != null)
        .map((fund) => fund.createdAt!.year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // Sort descending
    if (years.isEmpty) years.add(DateTime.now().year);
    return years;
  }

  // Get available months for selected year
  List<int> _getAvailableMonths(List<FundModel> funds, int year) {
    final months = funds
        .where((fund) => fund.createdAt != null && fund.createdAt!.year == year)
        .map((fund) => fund.createdAt!.month)
        .toSet()
        .toList();
    months.sort();
    return months;
  }

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

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'ม.ค.',
      'ก.ย.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return monthNames[month];
  }

  Map<String, double> _calculateTotals(List<FundModel> funds) {
    final filteredFunds = _filterFundsByDate(funds);

    final totalIncome = filteredFunds
        .where((fund) => fund.type == 'income')
        .fold(0.0, (sum, fund) => sum + fund.amount);

    final totalOutcome = filteredFunds
        .where((fund) => fund.type == 'outcome')
        .fold(0.0, (sum, fund) => sum + fund.amount);

    final balance = totalIncome - totalOutcome;

    return {'income': totalIncome, 'outcome': totalOutcome, 'balance': balance};
  }

  List<FundModel> _filterFundsByDate(List<FundModel> funds) {
    return funds.where((fund) {
      if (fund.createdAt == null) return false;

      final fundDate = fund.createdAt!;
      final matchesYear = fundDate.year == _selectedYear;
      final matchesMonth =
          _selectedMonth == null || fundDate.month == _selectedMonth;

      return matchesYear && matchesMonth;
    }).toList();
  }

  List<FundModel> _filterFunds(List<FundModel> funds) {
    final dateFilteredFunds = _filterFundsByDate(funds);

    switch (_selectedFilter) {
      case 'income':
        return dateFilteredFunds
            .where((fund) => fund.type == 'income')
            .toList();
      case 'outcome':
        return dateFilteredFunds
            .where((fund) => fund.type == 'outcome')
            .toList();
      default:
        return dateFilteredFunds;
    }
  }

  Widget _buildDateFilter(List<FundModel> allFunds) {
    final availableYears = _getAvailableYears(allFunds);
    final availableMonths = _getAvailableMonths(allFunds, _selectedYear);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.sandyTan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.warmStone.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Year Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.ivoryWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeColors.warmStone.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      dropdownColor: ThemeColors.ivoryWhite,
                      items: availableYears.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            'ปี ${year + 543}',
                            style: TextStyle(
                              color: ThemeColors.softBrown,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (year) {
                        setState(() {
                          _selectedYear = year!;
                          // Reset month if not available in new year
                          if (_selectedMonth != null &&
                              !_getAvailableMonths(
                                allFunds,
                                year,
                              ).contains(_selectedMonth)) {
                            _selectedMonth = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Month Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.ivoryWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeColors.warmStone.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedMonth,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      dropdownColor: ThemeColors.ivoryWhite,
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'ทั้งปี',
                            style: TextStyle(
                              color: ThemeColors.softBrown,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ...availableMonths.map((month) {
                          return DropdownMenuItem<int?>(
                            value: month,
                            child: Text(
                              _getMonthName(month),
                              style: TextStyle(
                                color: ThemeColors.softBrown,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (month) {
                        setState(() {
                          _selectedMonth = month;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Reset Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedYear = DateTime.now().year;
                    _selectedMonth = null;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.warmStone.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: ThemeColors.softBrown,
                    size: 20,
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
    String periodText = _selectedMonth == null
        ? 'ปี ${_selectedYear + 543}'
        : '${_getMonthName(_selectedMonth!)} ${_selectedYear + 543}';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, 8, 16, 4),
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
      child: Row(
        children: [
          // Period and Balance
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodText,
                  style: TextStyle(
                    color: ThemeColors.ivoryWhite.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatCurrency(totals['balance']!),
                  style: TextStyle(
                    color: ThemeColors.ivoryWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Income
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: ThemeColors.oliveGreen,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'รายรับ',
                      style: TextStyle(
                        color: ThemeColors.ivoryWhite.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  _formatCurrency(totals['income']!),
                  style: TextStyle(
                    color: ThemeColors.oliveGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 40,
            width: 1,
            color: ThemeColors.ivoryWhite.withOpacity(0.2),
            margin: EdgeInsets.symmetric(horizontal: 8),
          ),
          // Outcome
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_down_rounded,
                      color: ThemeColors.burntOrange,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'รายจ่าย',
                      style: TextStyle(
                        color: ThemeColors.ivoryWhite.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  _formatCurrency(totals['outcome']!),
                  style: TextStyle(
                    color: ThemeColors.burntOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
        // Loading date filter
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeColors.sandyTan.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: ThemeColors.warmStone.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: ThemeColors.warmStone.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.sandyTan,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ไม่มีข้อมูลในช่วงเวลาที่เลือก',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
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
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: 48,
                    color: ThemeColors.warmStone,
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
                  'ในช่วงเวลาที่เลือก\nลองเปลี่ยนช่วงเวลาหรือเพิ่มรายการใหม่',
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
        _buildDateFilter([]), // Empty list for error state
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
        _buildDateFilter(allFunds),
        _buildFilterTabs(),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
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
                        SizedBox(height: 10),
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
                        SizedBox(height: 4),
                        Text(
                          'ในช่วงเวลาที่เลือก\nลองเปลี่ยนช่วงเวลา ตัวกรอง หรือเพิ่มรายการใหม่',
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
