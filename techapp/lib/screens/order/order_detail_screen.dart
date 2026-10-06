import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/order_model.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import 'order_invoice_pdf_preview_screen.dart';
import 'order_reviews_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final bool isAdmin;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.isAdmin = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = widget.isAdmin
          ? await AdminService.getAdminOrderDetail(widget.orderId)
          : await OrderService.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
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

  Future<void> _confirmCancelOrder() async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do hủy đơn (ví dụ: Đổi ý, mua nhầm...)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      try {
        await OrderService.cancelOrder(widget.orderId, reasonController.text.trim());
        if (mounted) {
          ToastHelper.showSuccess(context, 'Hủy đơn hàng thành công');
          _loadOrderDetail();
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isCancelling = false);
        }
      }
    }
  }

  Future<void> _updateAdminStatus(String newStatus, String actionTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: Text('Bạn có chắc chắn muốn chuyển đơn hàng #${_order!.orderCode} sang trạng thái này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.updateOrderStatus(_order!.id, newStatus);
      if (mounted) {
        ToastHelper.showSuccess(context, 'Cập nhật trạng thái thành công');
        _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PAYMENT_PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return const Color(0xFF2563EB);
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
        return AppColors.primary;
    }
  }

  Future<void> _showReturnRequestModal() async {
    final reasons = [
      'Sản phẩm lỗi kỹ thuật / không hoạt động',
      'Hàng bị bể vỡ, móp méo khi vận chuyển',
      'Giao sai sản phẩm / sai thông số kỹ thuật',
      'Sản phẩm không đúng với mô tả trên app',
      'Khác (ghi rõ trong phần mô tả)',
    ];
    String selectedReason = reasons.first;
    final noteController = TextEditingController();
    final bankNameController = TextEditingController(text: 'Vietcombank');
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.assignment_return_rounded, color: Colors.amber.shade800, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yêu cầu đổi trả & hoàn tiền',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Áp dụng cho đơn hàng gặp sự cố kỹ thuật hoặc hư hỏng',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.8, color: AppColors.divider),
                    const Text(
                      'Lý do đổi trả *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedReason,
                          items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedReason = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Mô tả chi tiết tình trạng sản phẩm',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Mô tả chi tiết lỗi gặp phải để shop xử lý nhanh chóng...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Thông tin tài khoản nhận tiền hoàn',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: bankNameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên ngân hàng *',
                              hintText: 'Ví dụ: Vietcombank, MB Bank, Techcombank...',
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên ngân hàng' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: accountNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số tài khoản *',
                              hintText: 'Nhập số tài khoản ngân hàng',
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số tài khoản' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: accountNameController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Tên chủ tài khoản *',
                              hintText: 'NGUYEN VAN A',
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên chủ tài khoản' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() != true) return;
                                setModalState(() => isSubmitting = true);
                                try {
                                  await OrderService.requestReturn(
                                    _order!.id,
                                    reason: selectedReason,
                                    note: noteController.text.trim(),
                                    bankName: bankNameController.text.trim(),
                                    bankAccountNumber: accountNumberController.text.trim(),
                                    bankAccountName: accountNameController.text.trim().toUpperCase(),
                                  );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    ToastHelper.showSuccess(context, 'Gửi yêu cầu đổi trả thành công!');
                                    _loadOrderDetail();
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setModalState(() => isSubmitting = false);
                                  }
                                  if (mounted) {
                                    ToastHelper.showError(context, e.toString());
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Gửi yêu cầu đổi trả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAdminApproveReturn({bool refundDirectly = false}) async {
    final title = refundDirectly ? 'Duyệt & Hoàn tiền ngay' : 'Duyệt yêu cầu đổi trả';
    final content = refundDirectly
        ? 'Bạn có chắc chắn muốn duyệt và hoàn tiền ngay số tiền ${CurrencyHelper.format(_order!.finalAmount)} cho khách?'
        : 'Bạn có chắc chắn muốn duyệt yêu cầu đổi trả cho đơn hàng #${_order!.orderCode}? Trạng thái sẽ chuyển thành "Đã duyệt đổi trả" chờ thu hồi sản phẩm.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: refundDirectly ? AppColors.success : AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.processReturnDecision(
        _order!.id,
        approve: true,
        refundDirectly: refundDirectly,
      );
      if (mounted) {
        ToastHelper.showSuccess(context, refundDirectly ? 'Hoàn tiền thành công' : 'Đã duyệt yêu cầu đổi trả');
        _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _handleAdminRejectReturn() async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối đổi trả'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập lý do từ chối yêu cầu đổi trả của khách hàng:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Sản phẩm đã quá hạn 7 ngày, lỗi do người dùng va đập...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ToastHelper.showError(ctx, 'Vui lòng nhập lý do từ chối');
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.processReturnDecision(
        _order!.id,
        approve: false,
        rejectReason: reasonController.text.trim(),
      );
      if (mounted) {
        ToastHelper.showSuccess(context, 'Đã từ chối yêu cầu đổi trả');
        _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _handleAdminProcessRefund() async {
    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hoàn tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xác nhận đã thu hồi hàng và chuyển khoản hoàn trả số tiền ${CurrencyHelper.format(_order!.finalAmount)} cho khách hàng?'),
            if (_order!.bankInfo != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tài khoản nhận: ${_order!.bankInfo}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Ghi chú / Mã giao dịch hoàn tiền (tùy chọn)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hoàn tiền'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.processRefund(
        _order!.id,
        note: noteController.text.trim(),
      );
      if (mounted) {
        ToastHelper.showSuccess(context, 'Xác nhận hoàn tiền thành công! Đã tự động hoàn kho.');
        _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Không thể tải chi tiết đơn hàng'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadOrderDetail, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${order.orderCode}'),
        actions: [
          if (order.canExportInvoice)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trạng thái đơn hàng:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          order.statusDisplay,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời gian đặt: ${CurrencyHelper.formatDateTime(order.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (order.isReturnFlow) ...[
              const SizedBox(height: 16),
              _buildReturnFlowCard(order),
            ],
            const SizedBox(height: 16),

            // Items list
            const Text(
              'Danh sách sản phẩm',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SafeNetworkImage(
                              imageUrl: item.productImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              fallbackIconSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyHelper.format(item.unitPrice)} x ${item.quantity}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyHelper.format(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Info Card
            const Text(
              'Thông tin giao nhận',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Người nhận:', order.recipientName),
                  const SizedBox(height: 8),
                  _buildDetailRow('Điện thoại:', order.recipientPhone),
                  const SizedBox(height: 8),
                  _buildDetailRow('Địa chỉ:', order.shippingAddress),
                  if (order.branchName != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Kho / Chi nhánh:', order.branchName!),
                  ],
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Ghi chú:', order.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Summary Card
            const Text(
              'Thanh toán',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Phương thức:', order.paymentMethodDisplay),
                  if (order.paymentStatus != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Tình trạng:', order.paymentStatus == 'PAID' ? 'Đã thanh toán' : 'Chưa thanh toán'),
                  ],
                  if (order.couponCode != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Mã voucher:', order.couponCode!),
                  ],
                  const Divider(height: 20, thickness: 0.8, color: AppColors.divider),
                  _buildDetailRow('Tiền hàng (Tạm tính):', CurrencyHelper.format(order.totalItemsAmount)),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Giảm giá voucher:',
                      '-${CurrencyHelper.format(order.discountAmount)}',
                      valueColor: AppColors.success,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Phí vận chuyển:',
                    order.shippingFee > 0
                        ? '+${CurrencyHelper.format(order.shippingFee)}'
                        : '0 ₫ (Miễn phí)',
                    valueColor: order.shippingFee == 0 ? AppColors.freeShipping : null,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Thuế VAT (${(order.vatRate * 100).toStringAsFixed(0)}%):',
                    order.taxAmount > 0
                        ? '+${CurrencyHelper.format(order.taxAmount)}'
                        : '+${CurrencyHelper.format(((order.totalItemsAmount - order.discountAmount) * order.vatRate).roundToDouble())}',
                  ),
                  const Divider(height: 20, thickness: 0.8, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        CurrencyHelper.format(order.finalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.danger),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.4),
                              children: [
                                const TextSpan(
                                  text: 'Công thức tính: ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: order.discountAmount > 0
                                      ? 'Tổng = Tiền hàng - Giảm giá + Phí vận chuyển + Thuế VAT (${(order.vatRate * 100).toStringAsFixed(0)}%)'
                                      : 'Tổng = Tiền hàng + Phí vận chuyển + Thuế VAT (${(order.vatRate * 100).toStringAsFixed(0)}%)',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Invoice PDF Export Card (For both Customer & Admin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: order.canExportInvoice
                          ? AppColors.primaryLight.withValues(alpha: 0.35)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: order.canExportInvoice ? AppColors.primary : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hóa đơn điện tử PDF',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.canExportInvoice
                              ? 'Hóa đơn bán hàng & phiếu xuất kho chính thức'
                              : (order.status == 'CANCELLED'
                                  ? 'Không thể xuất hóa đơn cho đơn đã hủy'
                                  : 'Khả dụng sau khi đơn hàng giao thành công'),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (order.canExportInvoice)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('Xem hóa đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderInvoicePdfPreviewScreen(order: order),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status == 'CANCELLED' ? 'Đã hủy' : 'Chờ hoàn tất',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (!widget.isAdmin && order.status == 'COMPLETED') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.rate_review_rounded, color: Colors.amber.shade800, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đánh giá sản phẩm',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chia sẻ cảm nhận chất lượng & nhận xét đơn hàng',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.star_rounded, size: 16),
                      label: const Text('Đánh giá'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderReviewsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            if (!widget.isAdmin && order.canRequestReturn) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.assignment_return_outlined, color: Colors.amber.shade800, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yêu cầu Đổi trả / Hoàn tiền',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hỗ trợ đổi mới trong 7 ngày (còn ${order.remainingReturnDays} ngày hiệu lực)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: _showReturnRequestModal,
                      child: const Text('Yêu cầu'),
                    ),
                  ],
                ),
              ),
            ] else if (!widget.isAdmin && order.isReturnExpired) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã hết thời hạn 7 ngày đổi trả',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nếu phát sinh sự cố phần cứng, vui lòng sử dụng Hóa đơn PDF để được bảo hành chính hãng.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action Section: Admin Actions OR Customer Cancel Action
            if (widget.isAdmin) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Thao tác quản lý đơn hàng (Admin)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (order.status.toUpperCase() == 'PENDING' || order.status.toUpperCase() == 'PAYMENT_PENDING') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateAdminStatus('CANCELLED', 'Hủy đơn hàng'),
                              child: const Text('Hủy đơn'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateAdminStatus('CONFIRMED', 'Xác nhận duyệt đơn hàng'),
                              child: const Text('Duyệt đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else if (order.status.toUpperCase() == 'CONFIRMED') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateAdminStatus('CANCELLED', 'Hủy đơn hàng'),
                              child: const Text('Hủy đơn'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateAdminStatus('SHIPPING', 'Giao hàng cho đơn vị vận chuyển'),
                              child: const Text('Giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else if (order.status.toUpperCase() == 'SHIPPING') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateAdminStatus('CANCELLED', 'Hủy đơn hàng'),
                              child: const Text('Hủy đơn'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateAdminStatus('COMPLETED', 'Xác nhận giao thành công'),
                              child: const Text('Hoàn tất giao', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else if (order.status.toUpperCase() == 'RETURN_REQUESTED') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _handleAdminRejectReturn,
                              child: const Text('Từ chối'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _handleAdminApproveReturn(refundDirectly: false),
                              child: const Text('Duyệt đổi trả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _handleAdminApproveReturn(refundDirectly: true),
                              child: const Text('Hoàn tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ] else if (order.status.toUpperCase() == 'RETURN_APPROVED') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.currency_exchange_rounded, size: 18),
                          label: const Text('Xác nhận nhận máy & Hoàn tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleAdminProcessRefund,
                        ),
                      ),
                    ] else if (order.status.toUpperCase() == 'RETURN_REJECTED') ...[
                      const Text(
                        'Yêu cầu đổi trả của đơn hàng này đã bị từ chối.',
                        style: TextStyle(fontSize: 13, color: AppColors.danger, fontStyle: FontStyle.italic),
                      ),
                    ] else if (order.status.toUpperCase() == 'REFUNDED') ...[
                      const Text(
                        'Đơn hàng đã được hoàn tiền thành công. Số lượng sản phẩm đã tự động hoàn nhập lại kho chi nhánh.',
                        style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
                      ),
                    ] else ...[
                      Text(
                        'Đơn hàng hiện ở trạng thái "${order.statusDisplay}". Không thể thay đổi trạng thái.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (order.canCancel) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isCancelling ? null : _confirmCancelOrder,
                  child: _isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                        )
                      : const Text('Hủy đơn hàng này'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String val, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnFlowCard(OrderModel order) {
    if (!order.isReturnFlow) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData iconData;
    String title;
    String description;

    if (order.isReturnRequested) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      iconColor = const Color(0xFFD97706);
      iconData = Icons.pending_actions_rounded;
      title = 'Yêu cầu đổi trả đang chờ xét duyệt';
      description = 'Cửa hàng đã nhận được yêu cầu đổi trả của bạn và đang tiến hành kiểm tra xác minh. Chúng tôi sẽ phản hồi trong vòng 24 giờ làm việc.';
    } else if (order.isReturnApproved) {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      iconColor = const Color(0xFF2563EB);
      iconData = Icons.verified_outlined;
      title = 'Yêu cầu đổi trả đã được chấp thuận';
      description = 'Vui lòng đóng gói lại sản phẩm cẩn thận (kèm đầy đủ phụ kiện). Shipper của TechStore sẽ liên hệ thu hồi máy trong 1-2 ngày làm việc. Sau khi kiểm tra nhận máy, tiền sẽ được hoàn về tài khoản của bạn.';
    } else if (order.isReturnRejected) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      iconColor = AppColors.danger;
      iconData = Icons.highlight_off_rounded;
      title = 'Yêu cầu đổi trả đã bị từ chối';
      description = order.returnRejectReason != null && order.returnRejectReason!.isNotEmpty
          ? 'Lý do từ chối: ${order.returnRejectReason}'
          : 'Sản phẩm không đáp ứng đủ điều kiện chính sách đổi trả / bảo hành của cửa hàng.';
    } else {
      // REFUNDED
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      iconColor = AppColors.success;
      iconData = Icons.check_circle_outline_rounded;
      title = 'Đã hoàn tiền thành công';
      description = 'Đơn hàng đã được hoàn tất thủ tục đổi trả và hoàn tiền. Số tiền ${CurrencyHelper.format(order.finalAmount)} đã được hoàn về tài khoản ngân hàng của bạn.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.8, color: Color(0xFFCBD5E1)),
          if (order.returnReason != null && order.returnReason!.isNotEmpty) ...[
            _buildDetailRow('Lý do đổi trả:', order.returnReason!),
            const SizedBox(height: 6),
          ],
          if (order.returnNote != null && order.returnNote!.isNotEmpty) ...[
            _buildDetailRow('Mô tả sự cố:', order.returnNote!),
            const SizedBox(height: 6),
          ],
          if (order.bankInfo != null && order.bankInfo!.isNotEmpty) ...[
            _buildDetailRow('Tài khoản nhận tiền:', order.bankInfo!),
            const SizedBox(height: 6),
          ],
          if (order.returnRequestedAt != null) ...[
            _buildDetailRow('Ngày gửi yêu cầu:', CurrencyHelper.formatDateTime(order.returnRequestedAt)),
            const SizedBox(height: 6),
          ],
          if (order.refundedAt != null) ...[
            _buildDetailRow('Ngày hoàn tiền:', CurrencyHelper.formatDateTime(order.refundedAt), valueColor: AppColors.success),
          ],
        ],
      ),
    );
  }
}
