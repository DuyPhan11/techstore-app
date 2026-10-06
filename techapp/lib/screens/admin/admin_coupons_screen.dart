import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  bool _isLoading = true;
  bool _isLoadingStats = true;

  AdminCouponStatsModel? _stats;
  List<CouponModel> _coupons = [];

  // Filter state
  String _selectedFilter = 'ALL'; // ALL, ACTIVE, INACTIVE, PERCENTAGE, FIXED
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadStats(),
      _loadCoupons(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final s = await CouponService.getAdminCouponStats();
      if (mounted) {
        setState(() {
          _stats = s;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadCoupons() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String? discountType;
      bool? isActive;

      if (_selectedFilter == 'ACTIVE') {
        isActive = true;
      } else if (_selectedFilter == 'INACTIVE') {
        isActive = false;
      } else if (_selectedFilter == 'PERCENTAGE') {
        discountType = 'PERCENTAGE';
      } else if (_selectedFilter == 'FIXED') {
        discountType = 'FIXED_AMOUNT';
      }

      final res = await CouponService.getAdminCoupons(
        search: _searchQuery,
        discountType: discountType,
        isActive: isActive,
        page: 0,
        size: 50,
      );

      if (mounted) {
        setState(() {
          _coupons = res['coupons'] as List<CouponModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(context, 'Không thể tải danh sách mã giảm giá: $e');
      }
    }
  }

  Future<void> _handleToggleStatus(CouponModel coupon, bool newStatus) async {
    try {
      final updated = await CouponService.toggleCouponStatus(coupon.id, newStatus);
      if (mounted) {
        setState(() {
          final idx = _coupons.indexWhere((c) => c.id == coupon.id);
          if (idx != -1) {
            _coupons[idx] = updated;
          }
        });
        _loadStats();
        ToastHelper.showSuccess(
          context,
          newStatus
              ? 'Đã kích hoạt mã ${coupon.code}'
              : 'Đã tạm dừng mã ${coupon.code}',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Thao tác thất bại: $e');
      }
    }
  }

  Future<void> _handleDeleteCoupon(CouponModel coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Xóa mã giảm giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn mã "${coupon.code}"?\n'
          'Hành động này sẽ không thể khôi phục.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CouponService.deleteCoupon(coupon.id);
      if (mounted) {
        setState(() {
          _coupons.removeWhere((c) => c.id == coupon.id);
        });
        _loadStats();
        ToastHelper.showSuccess(context, 'Đã xóa mã ${coupon.code} thành công');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Xóa thất bại: $e');
      }
    }
  }

  void _openCouponForm({CouponModel? coupon}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CouponFormBottomSheet(
        coupon: coupon,
        onSaved: () {
          _loadAll();
        },
      ),
    );
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ToastHelper.showSuccess(context, 'Đã sao chép mã "$code"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý Mã Giảm Giá',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            Text(
              'Khuyến mãi & Mã voucher ưu đãi',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadAll,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCouponForm(),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm mã mới', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            // 1. Thống kê tổng quan (Stats Cards)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatsHeader(),
              ),
            ),

            // 2. Ô tìm kiếm & Bộ lọc Chip
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 3. Danh sách thẻ Coupon
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                ),
              )
            else if (_coupons.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.confirmation_num_outlined,
                  title: 'Không tìm thấy mã giảm giá',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'Không có mã nào khớp với từ khóa "$_searchQuery"'
                      : 'Chưa có mã giảm giá nào trong bộ lọc này.',
                  buttonText: 'Tạo mã giảm giá mới',
                  onButtonPressed: () => _openCouponForm(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _coupons[index];
                      return _buildCouponCard(item);
                    },
                    childCount: _coupons.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget Thống kê tổng quan
  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tổng quan Khuyến mãi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              if (_isLoadingStats)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Tổng số mã',
                  value: _stats != null ? '${_stats!.totalCoupons}' : '--',
                  color: const Color(0xFF0F172A),
                  bgColor: const Color(0xFFF1F5F9),
                  icon: Icons.confirmation_num,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  title: 'Đang chạy',
                  value: _stats != null ? '${_stats!.activeCoupons}' : '--',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  title: 'Hết hạn/Khóa',
                  value: _stats != null ? '${_stats!.expiredCoupons}' : '--',
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEE2E2),
                  icon: Icons.timer_off_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  title: 'Lượt đã dùng',
                  value: _stats != null ? '${_stats!.totalUsed}' : '--',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Thanh tìm kiếm
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) {
          setState(() => _searchQuery = val.trim());
          _loadCoupons();
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm mã voucher...',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                    _loadCoupons();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Widget Bộ lọc Chip
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
      {'key': 'ACTIVE', 'label': 'Đang hoạt động'},
      {'key': 'INACTIVE', 'label': 'Tạm dừng'},
      {'key': 'PERCENTAGE', 'label': 'Giảm %'},
      {'key': 'FIXED', 'label': 'Giảm số tiền'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = f['key']!);
                  _loadCoupons();
                }
              },
              selectedColor: const Color(0xFF0F172A),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget Thẻ Mã giảm giá phong cách Voucher Ticket
  Widget _buildCouponCard(CouponModel coupon) {
    final now = DateTime.now();
    final bool isPercentage = coupon.discountType == 'PERCENTAGE';
    final bool isExpired = now.isAfter(coupon.endDate);
    final bool isFullyUsed = coupon.usedCount >= coupon.usageLimit;
    final bool isRunning = coupon.isActive && !isExpired && !isFullyUsed;

    Color badgeColor;
    String statusText;
    if (isRunning) {
      badgeColor = const Color(0xFF16A34A);
      statusText = 'Hoạt động';
    } else if (isExpired) {
      badgeColor = const Color(0xFFDC2626);
      statusText = 'Đã hết hạn';
    } else if (isFullyUsed) {
      badgeColor = const Color(0xFFD97706);
      statusText = 'Hết lượt dùng';
    } else {
      badgeColor = const Color(0xFF64748B);
      statusText = 'Đã tạm tắt';
    }

    final String discountDisplay = isPercentage
        ? 'Giảm ${coupon.discountValue.toStringAsFixed(coupon.discountValue.truncateToDouble() == coupon.discountValue ? 0 : 1)}%'
        : 'Giảm ${CurrencyHelper.format(coupon.discountValue)}';

    final double usedProgress = coupon.usageLimit > 0
        ? (coupon.usedCount / coupon.usageLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: isRunning ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phần đầu thẻ: Code, discount, switch
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Voucher
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPercentage ? const Color(0xFFEEF2FF) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPercentage ? Icons.percent : Icons.attach_money,
                        color: isPercentage ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Code và Tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _copyToClipboard(coupon.code),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF94A3B8), style: BorderStyle.solid),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        coupon.code,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.copy, size: 14, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge trạng thái
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            discountDisplay,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (isPercentage && coupon.maxDiscountAmount != null && coupon.maxDiscountAmount! > 0)
                            Text(
                              'Giảm tối đa: ${CurrencyHelper.format(coupon.maxDiscountAmount!)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                        ],
                      ),
                    ),

                    // Switch Bật/Tắt
                    Switch.adaptive(
                      value: coupon.isActive,
                      activeTrackColor: const Color(0xFF16A34A),
                      onChanged: (val) => _handleToggleStatus(coupon, val),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Điều kiện áp dụng
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      coupon.minOrderAmount > 0
                          ? 'Đơn tối thiểu: ${CurrencyHelper.format(coupon.minOrderAmount)}'
                          : 'Áp dụng cho mọi giá trị đơn',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Hạn sử dụng
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Hạn dùng: ${DateFormat('dd/MM/yyyy HH:mm').format(coupon.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tiến độ sử dụng (Progress Bar)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã dùng: ${coupon.usedCount} / ${coupon.usageLimit} lượt',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        Text(
                          '${(usedProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: usedProgress >= 1.0 ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usedProgress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          usedProgress >= 1.0
                              ? const Color(0xFFDC2626)
                              : (usedProgress > 0.8 ? const Color(0xFFD97706) : const Color(0xFF4F46E5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Thanh hành động dưới đáy thẻ: Sửa & Xóa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Nút Chỉnh sửa
                OutlinedButton.icon(
                  onPressed: () => _openCouponForm(coupon: coupon),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút Xóa
                IconButton(
                  onPressed: () => _handleDeleteCoupon(coupon),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                  tooltip: 'Xóa mã giảm giá',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORM BOTTOM SHEET TẠO / SỬA MÃ GIẢM GIÁ
// ==========================================
class _CouponFormBottomSheet extends StatefulWidget {
  final CouponModel? coupon;
  final VoidCallback onSaved;

  const _CouponFormBottomSheet({
    this.coupon,
    required this.onSaved,
  });

  @override
  State<_CouponFormBottomSheet> createState() => _CouponFormBottomSheetState();
}

class _CouponFormBottomSheetState extends State<_CouponFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _discountValueCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _usageLimitCtrl;

  late String _discountType; // 'PERCENTAGE' or 'FIXED_AMOUNT'
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _discountType = c?.discountType ?? 'PERCENTAGE';
    _discountValueCtrl = TextEditingController(
      text: c != null ? c.discountValue.toStringAsFixed(c.discountValue.truncateToDouble() == c.discountValue ? 0 : 2) : '',
    );
    _minOrderCtrl = TextEditingController(
      text: c != null && c.minOrderAmount > 0 ? c.minOrderAmount.toStringAsFixed(0) : '0',
    );
    _maxDiscountCtrl = TextEditingController(
      text: c?.maxDiscountAmount != null && c!.maxDiscountAmount! > 0 ? c.maxDiscountAmount!.toStringAsFixed(0) : '',
    );
    _usageLimitCtrl = TextEditingController(
      text: c != null ? c.usageLimit.toString() : '100',
    );
    _startDate = c?.startDate ?? DateTime.now();
    _endDate = c?.endDate ?? DateTime.now().plusDays(30);
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountValueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageLimitCtrl.dispose();
    super.dispose();
  }

  void _generateRandomCode() {
    final now = DateTime.now();
    final randomSuffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    setState(() {
      _codeCtrl.text = 'TECH$randomSuffix';
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = combined;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      } else {
        _endDate = combined;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
      ToastHelper.showError(context, 'Thời gian kết thúc phải diễn ra sau thời gian bắt đầu');
      return;
    }

    final double discountVal = double.tryParse(_discountValueCtrl.text.trim()) ?? 0.0;
    if (_discountType == 'PERCENTAGE' && discountVal > 100) {
      ToastHelper.showError(context, 'Phần trăm giảm giá không được vượt quá 100%');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double minOrder = double.tryParse(_minOrderCtrl.text.trim()) ?? 0.0;
      final double? maxDiscount = _discountType == 'PERCENTAGE' && _maxDiscountCtrl.text.trim().isNotEmpty
          ? double.tryParse(_maxDiscountCtrl.text.trim())
          : null;
      final int usageLimit = int.tryParse(_usageLimitCtrl.text.trim()) ?? 100;

      final DateFormat isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

      if (widget.coupon == null) {
        // Create new
        final body = <String, dynamic>{
          'code': _codeCtrl.text.trim().toUpperCase(),
          'discountType': _discountType,
          'discountValue': discountVal,
          'minOrderAmount': minOrder,
          'usageLimit': usageLimit,
          'startDate': isoFormat.format(_startDate),
          'endDate': isoFormat.format(_endDate),
          'isActive': _isActive,
        };
        if (maxDiscount != null) {
          body['maxDiscountAmount'] = maxDiscount;
        }
        await CouponService.createCoupon(body);
        if (mounted) {
          ToastHelper.showSuccess(context, 'Tạo mã ${_codeCtrl.text.trim().toUpperCase()} thành công!');
          Navigator.pop(context);
          widget.onSaved();
        }
      } else {
        // Update existing
        final body = <String, dynamic>{
          'discountType': _discountType,
          'discountValue': discountVal,
          'minOrderAmount': minOrder,
          'usageLimit': usageLimit,
          'startDate': isoFormat.format(_startDate),
          'endDate': isoFormat.format(_endDate),
          'isActive': _isActive,
        };
        if (maxDiscount != null) {
          body['maxDiscountAmount'] = maxDiscount;
        }
        await CouponService.updateCoupon(widget.coupon!.id, body);
        if (mounted) {
          ToastHelper.showSuccess(context, 'Cập nhật mã ${widget.coupon!.code} thành công!');
          Navigator.pop(context);
          widget.onSaved();
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.coupon != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit_note : Icons.add_circle_outline,
                  color: const Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEdit ? 'Chỉnh sửa mã ${widget.coupon!.code}' : 'Tạo Mã Giảm Giá Mới',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          // Form fields
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 1. Mã giảm giá
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeCtrl,
                          enabled: !isEdit, // Mã không sửa được sau khi tạo
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mã voucher *',
                            hintText: 'VD: TECHSTORE10',
                            helperText: isEdit ? 'Mã voucher cố định không thể sửa' : 'Từ 3-50 ký tự viết liền',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.qr_code, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mã voucher';
                            if (val.trim().length < 3) return 'Mã tối thiểu 3 ký tự';
                            return null;
                          },
                        ),
                      ),
                      if (!isEdit) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ElevatedButton.icon(
                            onPressed: _generateRandomCode,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Tạo ngẫu nhiên', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Loại giảm giá (Segmented button)
                  const Text('Loại giảm giá *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _discountType = 'PERCENTAGE'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _discountType == 'PERCENTAGE' ? const Color(0xFFEEF2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _discountType == 'PERCENTAGE' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                width: _discountType == 'PERCENTAGE' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.percent, size: 18, color: _discountType == 'PERCENTAGE' ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(
                                  'Theo phần trăm (%)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _discountType == 'PERCENTAGE' ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _discountType = 'FIXED_AMOUNT'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _discountType == 'FIXED_AMOUNT' ? const Color(0xFFFEF3C7) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _discountType == 'FIXED_AMOUNT' ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
                                width: _discountType == 'FIXED_AMOUNT' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.attach_money, size: 18, color: _discountType == 'FIXED_AMOUNT' ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(
                                  'Số tiền cố định (₫)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _discountType == 'FIXED_AMOUNT' ? const Color(0xFFD97706) : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Giá trị giảm & Giảm tối đa
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountValueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: _discountType == 'PERCENTAGE' ? 'Phần trăm giảm (%) *' : 'Số tiền giảm (₫) *',
                            hintText: _discountType == 'PERCENTAGE' ? 'VD: 15' : 'VD: 50000',
                            suffixText: _discountType == 'PERCENTAGE' ? '%' : '₫',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giá trị';
                            final n = double.tryParse(val.trim());
                            if (n == null || n <= 0) return 'Phải lớn hơn 0';
                            if (_discountType == 'PERCENTAGE' && n > 100) return 'Tối đa 100%';
                            return null;
                          },
                        ),
                      ),
                      if (_discountType == 'PERCENTAGE') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _maxDiscountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Giảm tối đa (₫)',
                              hintText: 'VD: 500000',
                              suffixText: '₫',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Đơn hàng tối thiểu & Số lượt dùng
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minOrderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Đơn tối thiểu (₫)',
                            hintText: 'VD: 200000',
                            suffixText: '₫',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _usageLimitCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Lượt sử dụng *',
                            hintText: 'VD: 100',
                            suffixText: 'lượt',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Nhập số lượt';
                            final n = int.tryParse(val.trim());
                            if (n == null || n < 1) return 'Tối thiểu 1';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Thời gian bắt đầu và kết thúc
                  const Text('Thời gian hiệu lực *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(isStart: true),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Từ lúc', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF4F46E5)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(_startDate),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(isStart: false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Đến lúc', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.event_available, size: 14, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(_endDate),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Trạng thái kích hoạt
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kích hoạt mã ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            Text('Khách hàng có thể áp dụng mã này khi mua sắm', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isActive,
                          activeTrackColor: const Color(0xFF16A34A),
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Lưu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isEdit ? 'CẬP NHẬT MÃ GIẢM GIÁ' : 'TẠO MÃ GIẢM GIÁ',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime plusDays(int days) {
    return add(Duration(days: days));
  }
}
