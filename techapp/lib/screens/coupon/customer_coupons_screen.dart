import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';

class CustomerCouponsScreen extends StatefulWidget {
  final bool isSelectionMode;
  final double? currentOrderAmount;

  const CustomerCouponsScreen({
    super.key,
    this.isSelectionMode = false,
    this.currentOrderAmount,
  });

  @override
  State<CustomerCouponsScreen> createState() => _CustomerCouponsScreenState();
}

class _CustomerCouponsScreenState extends State<CustomerCouponsScreen> {
  bool _isLoading = true;
  List<CouponModel> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    try {
      final list = await CouponService.getAvailableCoupons();
      if (mounted) {
        setState(() {
          _coupons = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ToastHelper.showSuccess(context, 'Đã sao chép mã "$code"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isSelectionMode ? 'Chọn Mã Giảm Giá' : 'Kho Voucher & Ưu Đãi',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoupons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _coupons.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.confirmation_num_outlined,
                  title: 'Chưa có mã giảm giá nào',
                  subtitle: 'Các chương trình ưu đãi và voucher sẽ sớm được cập nhật.',
                )
              : RefreshIndicator(
                  onRefresh: _loadCoupons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _coupons.length,
                    itemBuilder: (context, index) {
                      final item = _coupons[index];
                      return _buildVoucherCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildVoucherCard(CouponModel coupon) {
    final bool isPercentage = coupon.discountType == 'PERCENTAGE';
    final double? currentTotal = widget.currentOrderAmount;
    final bool isEligible = currentTotal == null || currentTotal >= coupon.minOrderAmount;
    final double needMore = (currentTotal != null && currentTotal < coupon.minOrderAmount)
        ? (coupon.minOrderAmount - currentTotal)
        : 0.0;

    final String discountTitle = isPercentage
        ? 'Giảm ${coupon.discountValue.toStringAsFixed(coupon.discountValue.truncateToDouble() == coupon.discountValue ? 0 : 1)}%'
        : 'Giảm ${CurrencyHelper.format(coupon.discountValue)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEligible ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột trái: Icon huy hiệu voucher
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isEligible
                        ? (isPercentage ? const Color(0xFFEEF2FF) : const Color(0xFFFEF3C7))
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isPercentage ? Icons.percent : Icons.local_offer,
                      color: isEligible
                          ? (isPercentage ? const Color(0xFF4F46E5) : const Color(0xFFD97706))
                          : const Color(0xFF94A3B8),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Cột giữa: Thông tin voucher
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge code
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              coupon.code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyCode(coupon.code),
                            child: const Icon(Icons.copy, size: 14, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Tiêu đề mức giảm
                      Text(
                        discountTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEligible ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),

                      if (isPercentage && coupon.maxDiscountAmount != null && coupon.maxDiscountAmount! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Giảm tối đa: ${CurrencyHelper.format(coupon.maxDiscountAmount!)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),

                      const SizedBox(height: 4),
                      Text(
                        coupon.minOrderAmount > 0
                            ? 'Đơn tối thiểu: ${CurrencyHelper.format(coupon.minOrderAmount)}'
                            : 'Mọi giá trị đơn hàng',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),

                      // Thông báo nếu chưa đủ điều kiện
                      if (!isEligible && needMore > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mua thêm ${CurrencyHelper.format(needMore)} để áp dụng',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),
                      // Hạn sử dụng
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            'HSD: ${DateFormat('dd/MM/yyyy').format(coupon.endDate)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cột phải: Nút Áp dụng hoặc Sao chép
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: widget.isSelectionMode
                      ? ElevatedButton(
                          onPressed: isEligible ? () => Navigator.pop(context, coupon) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Áp dụng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      : OutlinedButton(
                          onPressed: () => _copyCode(coupon.code),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Lưu mã', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
