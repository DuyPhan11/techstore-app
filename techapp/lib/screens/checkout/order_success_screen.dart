import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/order_model.dart';
import '../../utils/currency_format.dart';
import '../order/order_detail_screen.dart';
import '../order/order_invoice_pdf_preview_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đặt hàng thành công'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 72,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cảm ơn bạn đã đặt hàng!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đơn hàng của bạn đã được ghi nhận trên hệ thống TechStore và đang được nhân viên xử lý.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 28),

              // Order Summary Card
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
                    _buildRow('Mã đơn hàng:', order.orderCode, isBold: true, highlight: true),
                    const Divider(height: 20, thickness: 0.8, color: AppColors.divider),
                    _buildRow('Người nhận:', order.recipientName),
                    const SizedBox(height: 10),
                    _buildRow('Số điện thoại:', order.recipientPhone),
                    const SizedBox(height: 10),
                    _buildRow('Địa chỉ nhận:', order.shippingAddress),
                    const SizedBox(height: 10),
                    _buildRow('Thanh toán:', order.paymentMethodDisplay),
                    const SizedBox(height: 10),
                    _buildRow('Trạng thái đơn:', order.statusDisplay),
                    const Divider(height: 20, thickness: 0.8, color: AppColors.divider),
                    _buildRow('Tiền hàng (Tạm tính):', CurrencyHelper.format(order.totalItemsAmount)),
                    if (order.discountAmount > 0) ...[
                      const SizedBox(height: 10),
                      _buildRow('Giảm giá voucher:', '-${CurrencyHelper.format(order.discountAmount)}', color: AppColors.success),
                    ],
                    const SizedBox(height: 10),
                    _buildRow(
                      'Phí vận chuyển:',
                      order.shippingFee > 0 ? '+${CurrencyHelper.format(order.shippingFee)}' : '0 ₫ (Miễn phí)',
                      color: order.shippingFee == 0 ? AppColors.freeShipping : null,
                    ),
                    const SizedBox(height: 10),
                    _buildRow(
                      'Thuế VAT (${(order.vatRate * 100).toStringAsFixed(0)}%):',
                      '+${CurrencyHelper.format(order.taxAmount > 0 ? order.taxAmount : ((order.totalItemsAmount - order.discountAmount) * order.vatRate).roundToDouble())}',
                    ),
                    const Divider(height: 20, thickness: 0.8, color: AppColors.divider),
                    _buildRow('Tổng thanh toán:', CurrencyHelper.format(order.finalAmount), isBold: true, color: AppColors.danger),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Xem chi tiết đơn hàng'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                  label: const Text('Xuất hóa đơn PDF', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderInvoicePdfPreviewScreen(order: order),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Tiếp tục mua sắm'),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool highlight = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (highlight ? AppColors.primary : AppColors.textDark),
            ),
          ),
        ),
      ],
    );
  }
}
