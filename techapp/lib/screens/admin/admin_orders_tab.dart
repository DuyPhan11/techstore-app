import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/admin_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../order/order_detail_screen.dart';
import '../order/order_invoice_pdf_preview_screen.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'ALL';

  final List<Map<String, String>> _statusFilters = const [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING', 'label': 'Chờ xác nhận'},
    {'key': 'CONFIRMED', 'label': 'Đã xác nhận'},
    {'key': 'SHIPPING', 'label': 'Đang giao'},
    {'key': 'COMPLETED', 'label': 'Hoàn thành'},
    {'key': 'RETURN_REQUESTED', 'label': 'Chờ đổi trả'},
    {'key': 'REFUNDED', 'label': 'Đã hoàn tiền'},
    {'key': 'CANCELLED', 'label': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await AdminService.getAdminOrders(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(OrderModel order, String newStatus, String actionTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: Text('Bạn có chắc chắn muốn chuyển đơn hàng #${order.orderCode} sang trạng thái này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ToastHelper.showSuccess(context, 'Cập nhật trạng thái đơn #${order.orderCode} thành công');
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    }
  }

  void _navigateToDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          isAdmin: true,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _fetchOrders();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PAYMENT_PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.purple;
      case 'SHIPPING':
        return const Color(0xFF0284C7);
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.danger;
      case 'RETURN_REQUESTED':
        return Colors.amber.shade800;
      case 'RETURN_APPROVED':
        return const Color(0xFF0284C7);
      case 'RETURN_REJECTED':
        return AppColors.danger;
      case 'REFUNDED':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((f) {
                final isSelected = _selectedStatus == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']!),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                    backgroundColor: const Color(0xFFF3F4F6),
                    checkmarkColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = f['key']!);
                        _fetchOrders();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.8, color: AppColors.divider),

        // Orders List View
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchOrders,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchOrders, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      )
                    : _orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              const Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                                    SizedBox(height: 10),
                                    Text('Không có đơn hàng nào', style: TextStyle(color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: _orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              final statusColor = _getStatusColor(order.status);

                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _navigateToDetail(order),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header: Order code & Status badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '#${order.orderCode}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              order.statusDisplay,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Customer Info
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${order.recipientName} • ${order.recipientPhone}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.shippingAddress,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Products preview
                                      if (order.items.isNotEmpty) ...[
                                        Text(
                                          'Sản phẩm: ${order.items.map((i) => "${i.productName} (x${i.quantity})").join(", ")}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                        ),
                                        const SizedBox(height: 8),
                                      ],

                                      // Return Reason Preview (if any)
                                      if (order.returnReason != null && order.returnReason!.isNotEmpty) ...[
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.assignment_return_rounded, size: 14, color: Colors.amber.shade800),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Lý do đổi trả: ${order.returnReason}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const Divider(height: 18, thickness: 0.8, color: AppColors.divider),

                                      // Footer: Total price + Action buttons
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Tổng tiền thanh toán', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              Text(
                                                CurrencyHelper.format(order.finalAmount),
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                                              ),
                                              Text(
                                                'Gồm VAT ${(order.vatRate * 100).toStringAsFixed(0)}% • Ship ${order.shippingFee > 0 ? CurrencyHelper.format(order.shippingFee) : "0 ₫"}',
                                                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Action based on status
                                              if (order.status.toUpperCase() == 'PENDING') ...[
                                                OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.danger,
                                                    side: const BorderSide(color: AppColors.danger),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  onPressed: () => _updateStatus(order, 'CANCELLED', 'Hủy đơn hàng'),
                                                  child: const Text('Hủy', style: TextStyle(fontSize: 11)),
                                                ),
                                                const SizedBox(width: 6),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  onPressed: () => _updateStatus(order, 'CONFIRMED', 'Xác nhận đơn hàng'),
                                                  child: const Text('Duyệt đơn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ] else if (order.status.toUpperCase() == 'CONFIRMED') ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0284C7),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  onPressed: () => _updateStatus(order, 'SHIPPING', 'Giao hàng cho đơn vị vận chuyển'),
                                                  child: const Text('Giao hàng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ] else if (order.status.toUpperCase() == 'SHIPPING') ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  onPressed: () => _updateStatus(order, 'COMPLETED', 'Xác nhận giao thành công'),
                                                  child: const Text('Hoàn tất', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ] else if (order.status.toUpperCase() == 'RETURN_REQUESTED') ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.amber.shade800,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  onPressed: () => _navigateToDetail(order),
                                                  child: const Text('Duyệt đổi trả', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ] else if (order.status.toUpperCase() == 'RETURN_APPROVED') ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  onPressed: () => _navigateToDetail(order),
                                                  child: const Text('Hoàn tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                              if (order.canExportInvoice) ...[
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  tooltip: 'Xuất hóa đơn PDF',
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => OrderInvoicePdfPreviewScreen(order: order),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 2),
                                              ],
                                              // Details button
                                              IconButton(
                                                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                tooltip: 'Chi tiết đơn hàng',
                                                onPressed: () => _navigateToDetail(order),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                          ),
          ),
        ),
      ],
    );
  }
}
