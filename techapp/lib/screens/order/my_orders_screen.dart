import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/currency_format.dart';
import '../../widgets/empty_state.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';
import 'order_invoice_pdf_preview_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Tất cả', 'Chờ xử lý', 'Đã xác nhận', 'Đang giao', 'Hoàn tất', 'Đổi trả', 'Đã hủy'];
  bool _hasInitialFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFetchOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndFetchOrders();
  }

  void _checkAndFetchOrders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated && !_hasInitialFetched) {
      _hasInitialFetched = true;
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn mua của tôi')),
        body: EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'Vui lòng đăng nhập',
          subtitle: 'Đăng nhập để theo dõi và quản lý lịch sử đơn mua hàng của bạn.',
          buttonText: 'Đăng nhập',
          onButtonPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            if (context.mounted) {
              final authAfter = Provider.of<AuthProvider>(context, listen: false);
              if (authAfter.isAuthenticated) {
                Provider.of<OrderProvider>(context, listen: false).fetchOrders();
              }
            }
          },
        ),
      );
    }

    final filteredOrders = orderProvider.filterOrders(_tabController.index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn mua của tôi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: const Color(0xFFEEEEEE),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.fetchOrders(),
        child: orderProvider.isLoading && orderProvider.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orderProvider.errorMessage != null && orderProvider.orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(
                            orderProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textDark),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => orderProvider.fetchOrders(),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredOrders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyStateWidget(
                              icon: Icons.receipt_long_outlined,
                              title: 'Chưa có đơn hàng nào',
                              subtitle: _tabController.index == 0
                                  ? 'Bạn chưa có đơn mua nào. Hãy mua sắm ngay để trải nghiệm dịch vụ!'
                                  : 'Không tìm thấy đơn hàng nào ở mục này.',
                              buttonText: 'Khám phá sản phẩm',
                              onButtonPressed: () {
                                Navigator.popUntil(context, (route) => route.isFirst);
                              },
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(order, orderProvider);
                        },
                      ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderProvider orderProvider) {
    Color statusColor = AppColors.primary;
    if (order.status == 'COMPLETED') statusColor = AppColors.success;
    if (order.status == 'CANCELLED') statusColor = AppColors.danger;
    if (order.status == 'SHIPPING') statusColor = const Color(0xFF0284C7);
    if (order.status == 'CONFIRMED') statusColor = const Color(0xFF2563EB);
    if (order.status == 'PENDING' || order.status == 'PAYMENT_PENDING') statusColor = Colors.orange;
    if (order.status == 'RETURN_REQUESTED') statusColor = Colors.amber.shade800;
    if (order.status == 'RETURN_APPROVED') statusColor = const Color(0xFF0284C7);
    if (order.status == 'RETURN_REJECTED') statusColor = AppColors.danger;
    if (order.status == 'REFUNDED') statusColor = AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mã: ${order.orderCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.statusDisplay,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ngày đặt: ${CurrencyHelper.formatDateTime(order.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (order.isReturnFlow) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    order.isRefunded
                        ? Icons.check_circle_outline_rounded
                        : (order.isReturnRejected
                            ? Icons.error_outline_rounded
                            : Icons.assignment_return_rounded),
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.isReturnRequested
                          ? 'Đang chờ shop duyệt: ${order.returnReason ?? ""}'
                          : (order.isReturnApproved
                              ? 'Đã duyệt: Chờ thu hồi sản phẩm'
                              : (order.isReturnRejected
                                  ? 'Từ chối: ${order.returnRejectReason ?? ""}'
                                  : 'Đã hoàn tiền về tài khoản ngân hàng')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 18, thickness: 0.8, color: AppColors.divider),

          // Items summary
          if (order.items.isNotEmpty) ...[
            ...order.items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SafeNetworkImage(
                          imageUrl: item.productImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          fallbackIconSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyHelper.format(item.unitPrice)} × ${item.quantity}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyHelper.format(item.subtotal),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '+ Thêm ${order.items.length - 3} sản phẩm khác',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            const Divider(height: 18, thickness: 0.8, color: AppColors.divider),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    CurrencyHelper.format(order.finalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger),
                  ),
                  const Text(
                    'Đã gồm VAT & phí vận chuyển',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order.canExportInvoice) ...[
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: AppColors.primary),
                      tooltip: 'Hóa đơn PDF',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderInvoicePdfPreviewScreen(order: order),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id),
                        ),
                      );
                      orderProvider.fetchOrders(silent: true);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
