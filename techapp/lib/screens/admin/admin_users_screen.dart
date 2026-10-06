import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedRole = 'ALL'; // ALL, ROLE_ADMIN, ROLE_STAFF, ROLE_CUSTOMER

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AdminService.getAdminUsers(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        size: 50,
      );

      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    if (_selectedRole == 'ALL') return _users;
    return _users.where((u) => u.roles.contains(_selectedRole)).toList();
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final isLocked = user.status == 'LOCKED';
    final newStatus = isLocked ? 'ACTIVE' : 'LOCKED';
    final actionName = isLocked ? 'Mở khóa' : 'Khóa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName tài khoản'),
        content: Text('Bạn có chắc chắn muốn $actionName tài khoản "${user.fullName}" (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionName, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.updateUserStatus(user.id, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã $actionName tài khoản thành công'),
              backgroundColor: isLocked ? Colors.green : Colors.orange,
            ),
          );
          _fetchUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _fetchUsers(),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email, SĐT...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchUsers();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _fetchUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tìm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleChip('Tất cả', 'ALL'),
                const SizedBox(width: 8),
                _buildRoleChip('Khách hàng', 'ROLE_CUSTOMER'),
                const SizedBox(width: 8),
                _buildRoleChip('Nhân viên', 'ROLE_STAFF'),
                const SizedBox(width: 8),
                _buildRoleChip('Quản trị viên', 'ROLE_ADMIN'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String role) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchUsers, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final users = _filteredUsers;
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy người dùng nào',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isLocked = user.status == 'LOCKED';
    final initialLetter = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: user.isAdmin
                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                  : user.isStaff
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                      : const Color(0xFF94A3B8).withValues(alpha: 0.15),
              child: Text(
                initialLetter,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: user.isAdmin
                      ? const Color(0xFF6366F1)
                      : user.isStaff
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF475569),
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName : 'Chưa đặt tên',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isLocked ? Colors.red.shade200 : Colors.green.shade200),
                        ),
                        child: Text(
                          isLocked ? 'Đã khóa' : 'Hoạt động',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.red : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    Text(
                      'SĐT: ${user.phone}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: user.roles.map((role) {
                      Color badgeBg = Colors.grey.shade100;
                      Color badgeText = Colors.grey.shade700;
                      String roleLabel = role;

                      if (role == 'ROLE_ADMIN') {
                        badgeBg = const Color(0xFFEEF2FF);
                        badgeText = const Color(0xFF4F46E5);
                        roleLabel = 'Admin';
                      } else if (role == 'ROLE_STAFF') {
                        badgeBg = const Color(0xFFE0F2FE);
                        badgeText = const Color(0xFF0284C7);
                        roleLabel = 'Nhân viên';
                      } else if (role == 'ROLE_CUSTOMER') {
                        badgeBg = const Color(0xFFF1F5F9);
                        badgeText = const Color(0xFF475569);
                        roleLabel = 'Khách hàng';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeText),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status action button
            IconButton(
              icon: Icon(
                isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: isLocked ? Colors.green : Colors.red.shade400,
                size: 20,
              ),
              tooltip: isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
              onPressed: () => _toggleUserStatus(user),
            ),
          ],
        ),
      ),
    );
  }
}
