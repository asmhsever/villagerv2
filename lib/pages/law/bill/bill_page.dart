import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/bill/bill_add_page.dart';
import 'package:fullproject/pages/law/bill/bill_detail_page.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:intl/intl.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  Future<List<BillModel>>? _bills;
  LawModel? law;
  Map<int, String> houseMap = {};
  Map<int, String> serviceMap = {};
  int? filterStatus;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      setState(() => law = user);
      await _loadHouseAndServiceData();
      _loadBills();
    } else {
      setState(() {
        _bills = Future.value([]);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHouseAndServiceData() async {
    try {
      if (law != null) {
        final houseResponse = await SupabaseConfig.client
            .from('house')
            .select('house_id, house_number')
            .eq('village_id', law!.villageId);

        final serviceResponse = await SupabaseConfig.client
            .from('service')
            .select('service_id, name');

        final Map<int, String> newHouseMap = {};
        for (var house in houseResponse) {
          newHouseMap[house['house_id']] = house['house_number'];
        }

        final Map<int, String> newServiceMap = {};
        for (var service in serviceResponse) {
          newServiceMap[service['service_id']] = service['name'];
        }

        setState(() {
          houseMap = newHouseMap;
          serviceMap = newServiceMap;
        });
      }
    } catch (e) {
      print('Error loading house and service data: $e');
    }
  }

  void _loadBills() {
    if (law != null) {
      setState(() {
        _bills = BillDomain.getAllInVillage(villageId: law!.villageId);
        _isLoading = false;
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _getServiceNameTh(int serviceId) {
    const serviceTranslations = {
      'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
      'Trash Fee': 'ค่าขยะ',
      'water Fee': 'ค่าน้ำ',
      'enegy Fee': 'ค่าไฟ',
    };

    final englishName = serviceMap[serviceId];
    return serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุ';
  }

  Future<void> _refreshBills() async {
    await _loadHouseAndServiceData();
    _loadBills();
  }

  Future<void> _navigateToAddForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillAddPage()),
    );
    if (result == true) {
      _refreshBills();
    }
  }

  void _navigateToDetail(BillModel bill) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BillDetailPage(bill: bill)),
    );
    if (result == true) {
      _refreshBills();
    }
  }

  List<BillModel> _filterBills(List<BillModel> bills) {
    List<BillModel> filtered = bills;

    // กรองตามสถานะ
    if (filterStatus != null) {
      filtered = filtered.where((b) => b.paidStatus == filterStatus).toList();
    }

    // กรองตามการค้นหา
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((bill) {
        final houseNumber = houseMap[bill.houseId]?.toLowerCase() ?? '${bill.houseId}';
        final serviceName = _getServiceNameTh(bill.service).toLowerCase();
        final amount = bill.amount.toString();
        final query = _searchQuery.toLowerCase();

        return houseNumber.contains(query) ||
            serviceName.contains(query) ||
            amount.contains(query);
      }).toList();
    }

    return filtered;
  }

  bool _isOverdue(BillModel bill) {
    if (bill.paidStatus == 1) return false;
    return DateTime.now().isAfter(bill.dueDate);
  }

  Color _getStatusColor(BillModel bill) {
    if (bill.paidStatus == 1) return Colors.green;
    if (_isOverdue(bill)) return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon(BillModel bill) {
    if (bill.paidStatus == 1) return Icons.check_circle;
    if (_isOverdue(bill)) return Icons.warning;
    return Icons.schedule;
  }

  String _getStatusText(BillModel bill) {
    if (bill.paidStatus == 1) return 'ชำระแล้ว';
    if (_isOverdue(bill)) return 'เกินกำหนด';
    return 'ยังไม่ชำระ';
  }

  List<TextSpan> _highlightSearchText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // เพิ่มข้อความก่อนหน้า
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: baseStyle,
        ));
      }

      // เพิ่มข้อความที่ค้นหา (ไฮไลท์)
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // เพิ่มข้อความที่เหลือ
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการค่าส่วนกลาง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshBills,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<BillModel>>(
        future: _bills,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBills,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'ไม่มีข้อมูลค่าส่วนกลาง',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เริ่มต้นด้วยการเพิ่มบิลใหม่',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddForm,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มบิลแรก'),
                  ),
                ],
              ),
            );
          } else {
            final filtered = _filterBills(snapshot.data!);
            return RefreshIndicator(
              onRefresh: _refreshBills,
              child: Column(
                children: [
                  // สถิติโดยรวม
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'ทั้งหมด',
                          '${snapshot.data!.length}',
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'ยังไม่จ่าย',
                          '${snapshot.data!.where((b) => b.paidStatus == 0).length}',
                          Icons.schedule,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'จ่ายแล้ว',
                          '${snapshot.data!.where((b) => b.paidStatus == 1).length}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // ช่องค้นหาและตัวกรอง
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // ช่องค้นหา
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ค้นหาบ้านเลขที่, ประเภทบริการ, หรือจำนวนเงิน...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),

                        const SizedBox(height: 12),

                        // ตัวกรองสถานะ
                        Row(
                          children: [
                            const Text('กรองสถานะ: '),
                            Expanded(
                              child: DropdownButton<int?>(
                                value: filterStatus,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('ทั้งหมด'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text('ยังไม่ชำระ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text('ชำระแล้ว'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => filterStatus = value),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'แสดง: ${filtered.length} รายการ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // รายการบิล
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final bill = filtered[index];
                        final houseNumber = houseMap[bill.houseId] ?? '${bill.houseId}';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(bill).withValues(alpha: 0.1),
                              child: Icon(
                                _getStatusIcon(bill),
                                color: _getStatusColor(bill),
                              ),
                            ),
                            title: RichText(
                              text: TextSpan(
                                children: _highlightSearchText(
                                  'บ้านเลขที่ $houseNumber',
                                  _searchQuery,
                                  const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: _highlightSearchText(
                                      '${_getServiceNameTh(bill.service)} - ${formatCurrency(bill.amount)} บาท',
                                      _searchQuery,
                                      const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ครบกำหนด: ${formatDate(bill.dueDate)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(bill).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(bill).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _getStatusText(bill),
                                style: TextStyle(
                                  color: _getStatusColor(bill),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            onTap: () => _navigateToDetail(bill),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddForm,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มค่าส่วนกลาง'),
      ),
    );
  }
}