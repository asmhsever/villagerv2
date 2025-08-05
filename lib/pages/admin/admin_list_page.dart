import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullproject/domains/admin_domain.dart';
import 'package:fullproject/models/admin_model.dart';
import 'package:fullproject/services/auth_service.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({Key? key}) : super(key: key);

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  List<AdminModel> _admins = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  final int _pageSize = 10;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // โหลดข้อมูล admin
  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // เรียกใช้ AdminDomain เพื่อดึงข้อมูลแบบ pagination
      final result = await AdminDomain.getAdminsWithPagination(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (result['success']) {
        setState(() {
          _admins = result['admins'] as List<AdminModel>;
          _totalPages = result['totalPages'];
          _totalCount = result['totalCount'];
        });
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('เกิดข้อผิดพลาด: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // แสดงข้อความ
  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  // ค้นหา admin
  Future<void> _searchAdmins() async {
    setState(() {
      _currentPage = 1;
      _searchQuery = _searchController.text.trim();
    });
    await _loadAdmins();
  }

  // รีเซ็ตการค้นหา
  Future<void> _resetSearch() async {
    _searchController.clear();
    setState(() {
      _currentPage = 1;
      _searchQuery = '';
    });
    await _loadAdmins();
  }

  // ลบ admin
  Future<void> _deleteAdmin(AdminModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบผู้ดูแลระบบ "${admin.username}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AdminDomain.deleteAdmin(admin.adminId);

        if (result['success']) {
          _showMessage(result['message']);
          await _loadAdmins(); // รีโหลดข้อมูล
        } else {
          _showMessage(result['message'], isError: true);
        }
      } catch (e) {
        _showMessage('เกิดข้อผิดพลาด: $e', isError: true);
      }
    }
  }

  // เปลี่ยนหน้า
  void _changePage(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages && newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
      _loadAdmins();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ดูแลระบบ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // นำทางไปหน้าสร้าง admin ใหม่
              Navigator.of(context).pushNamed('/admin/create');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'ค้นหาชื่อผู้ใช้',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchAdmins(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchAdmins,
                  child: const Text('ค้นหา'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _resetSearch,
                  child: const Text('รีเซ็ต'),
                ),
              ],
            ),
          ),

          // Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('พบทั้งหมด $_totalCount รายการ'),
                Text('หน้าที่ $_currentPage จาก $_totalPages'),
              ],
            ),
          ),

          const Divider(),

          // Admin List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _admins.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูลผู้ดูแลระบบ',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _admins.length,
                    itemBuilder: (context, index) {
                      final admin = _admins[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              admin.username.substring(0, 1).toUpperCase(),
                            ),
                          ),
                          title: Text(admin.username),
                          subtitle: Text('ID: ${admin.adminId}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  Navigator.of(
                                    context,
                                  ).pushNamed('/admin/edit', arguments: admin);
                                  break;
                                case 'delete':
                                  _deleteAdmin(admin);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('แก้ไข'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text('ลบ'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () => _changePage(1) : null,
                    icon: const Icon(Icons.first_page),
                  ),
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () => _changePage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_currentPage / $_totalPages'),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () => _changePage(_currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () => _changePage(_totalPages)
                        : null,
                    icon: const Icon(Icons.last_page),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
