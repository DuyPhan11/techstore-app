import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/cart_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/currency_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quantity_selector.dart';
import '../auth/login_screen.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<int> _selectedItemIds = {};
  bool _hasInitializedSelection = false;
  bool _isBreakdownExpanded = false;

  void _syncSelectedItems(List<dynamic> items) {
    final currentIds = items.map((e) => e.id as int).toSet();
    // Prune removed IDs
    _selectedItemIds.removeWhere((id) => !currentIds.contains(id));

    // Auto-select all on first load if not initialized
    if (!_hasInitializedSelection && items.isNotEmpty) {
      _selectedItemIds.addAll(currentIds);
      _hasInitializedSelection = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng của bạn')),
        body: EmptyStateWidget(
          icon: Icons.lock_outline,
          title: 'Vui lòng đăng nhập',
          subtitle: 'Bạn cần đăng nhập tài khoản để xem giỏ hàng và tiến hành đặt hàng.',
          buttonText: 'Đăng nhập ngay',
          onButtonPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      );
    }

    _syncSelectedItems(cart.items);

    final bool isAllSelected = cart.items.isNotEmpty && _selectedItemIds.length == cart.items.length;
    final selectedItems = cart.items.where((i) => _selectedItemIds.contains(i.id)).toList();
    final double selectedTotal = selectedItems.fold(0.0, (sum, i) => sum + i.subtotal);
    final int selectedCount = selectedItems.length;

    // Chi tiết tính toán tổng cộng minh bạch
    final bool isFreeShipping = selectedTotal >= 5000000;
    final double estimatedShipping = selectedCount > 0 ? (isFreeShipping ? 0.0 : 30000.0) : 0.0;
    const double vatRate = 0.08; // Thuế VAT 8%
    final double estimatedVat = (selectedTotal * vatRate).roundToDouble();
    final double estimatedGrandTotal = selectedTotal + estimatedShipping + estimatedVat;

    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.totalItems})'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa toàn bộ',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm khỏi giỏ hàng?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        onPressed: () {
                          cart.clearCart();
                          setState(() {
                            _selectedItemIds.clear();
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Xóa hết'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.isLoading && cart.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.remove_shopping_cart_outlined,
                  title: 'Giỏ hàng của bạn đang trống',
                  subtitle: 'Khám phá hàng ngàn sản phẩm công nghệ giá tốt và thêm vào giỏ hàng ngay!',
                  buttonText: 'Mua sắm ngay',
                  onButtonPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                )
              : Column(
                  children: [
                    // Select All Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: isAllSelected,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItemIds.addAll(cart.items.map((i) => i.id));
                                  } else {
                                    _selectedItemIds.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isAllSelected) {
                                  _selectedItemIds.clear();
                                } else {
                                  _selectedItemIds.addAll(cart.items.map((i) => i.id));
                                }
                              });
                            },
                            child: Text(
                              'Chọn tất cả (${cart.items.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_selectedItemIds.isNotEmpty)
                            Text(
                              'Đã chọn $selectedCount sản phẩm',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Cart Items List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => cart.fetchCart(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            final isSelected = _selectedItemIds.contains(item.id);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Checkbox per item
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (bool? val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedItemIds.add(item.id);
                                          } else {
                                            _selectedItemIds.remove(item.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Image
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SafeNetworkImage(
                                        imageUrl: item.primaryImageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fallbackIconSize: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                _selectedItemIds.remove(item.id);
                                                cart.removeItem(item.productId);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyHelper.format(item.unitPrice),
                                          style: const TextStyle(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            QuantitySelector(
                                              quantity: item.quantity,
                                              maxStock: item.availableStock > 0 ? item.availableStock : 999,
                                              onChanged: (newQty) {
                                                cart.updateQuantity(item.productId, newQty);
                                              },
                                            ),
                                            Text(
                                              CurrencyHelper.format(item.subtotal),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Interactive Calculation Bar & Expandable Breakdown
                    if (selectedCount > 0) ...[
                      InkWell(
                        onTap: () => setState(() => _isBreakdownExpanded = !_isBreakdownExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border(
                              top: BorderSide(color: Colors.green.shade200, width: 0.8),
                              bottom: BorderSide(color: Colors.green.shade100, width: 0.8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calculate_outlined, size: 16, color: Colors.green.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Chi tiết cách tính tổng cộng ($selectedCount sản phẩm)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                              Text(
                                _isBreakdownExpanded ? 'Thu gọn' : 'Xem chi tiết',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                _isBreakdownExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                size: 18,
                                color: Colors.green.shade800,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _isBreakdownExpanded
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          '1. TIỀN HÀNG TỪNG SẢN PHẨM',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showCalculationDetailModal(
                                            context,
                                            selectedItems,
                                            selectedTotal,
                                            estimatedShipping,
                                            estimatedVat,
                                            estimatedGrandTotal,
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.open_in_full_rounded, size: 12, color: AppColors.primary),
                                              SizedBox(width: 3),
                                              Text(
                                                'Xem dạng bảng',
                                                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...selectedItems.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '• ${item.productName}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${CurrencyHelper.format(item.unitPrice)} × ${item.quantity} = ${CurrencyHelper.format(item.subtotal)}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const Divider(height: 14, thickness: 0.8, color: AppColors.divider),
                                    const Text(
                                      '2. TỔNG HỢP & DỰ KIẾN KHI MUA HÀNG',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Tiền hàng (Tạm tính):', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        Text(CurrencyHelper.format(selectedTotal), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Phí vận chuyển dự kiến:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        Text(
                                          isFreeShipping ? '0 ₫ (Miễn phí đơn ≥ 5tr)' : '+${CurrencyHelper.format(estimatedShipping)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isFreeShipping ? AppColors.freeShipping : AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Thuế VAT (8%) dự kiến:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        Text(
                                          '+${CurrencyHelper.format(estimatedVat)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 14, thickness: 0.8, color: AppColors.divider),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Tổng thanh toán dự kiến:',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                        ),
                                        Text(
                                          CurrencyHelper.format(estimatedGrandTotal),
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Công thức tính: Tổng = Tiền hàng + Phí ship + Thuế VAT (8%) - Mã giảm giá (nếu có mã giảm giá sẽ được áp dụng tại bước Thanh toán)',
                                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.35),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],

                    // Checkout Bottom Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: selectedCount > 0
                                  ? () => setState(() => _isBreakdownExpanded = !_isBreakdownExpanded)
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Tổng cộng ($selectedCount):',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                      if (selectedCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          _isBreakdownExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    CurrencyHelper.format(selectedTotal),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  if (selectedCount > 0)
                                    Text(
                                      'Dự kiến: ${CurrencyHelper.format(estimatedGrandTotal)} (+VAT)',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: selectedCount > 0
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CheckoutScreen(
                                              selectedCartItems: selectedItems,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(
                                  selectedCount > 0
                                      ? 'Mua hàng ($selectedCount)'
                                      : 'Chọn sản phẩm',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showCalculationDetailModal(
    BuildContext context,
    List<CartItemModel> selectedItems,
    double subtotal,
    double shipping,
    double vat,
    double grandTotal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết cách tính tổng cộng',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đã chọn ${selectedItems.length} sản phẩm để thanh toán',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Tiền từng món
                      const Text(
                        '1. TIỀN HÀNG TỪNG SẢN PHẨM (ĐƠN GIÁ × SỐ LƯỢNG)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...selectedItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SafeNetworkImage(
                                    imageUrl: item.primaryImageUrl,
                                    fit: BoxFit.cover,
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
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${CurrencyHelper.format(item.unitPrice)} × ${item.quantity} cái',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyHelper.format(item.subtotal),
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Section 2: Tổng hợp chi phí dự kiến
                      const Text(
                        '2. BẢNG TỔNG HỢP CHI PHÍ DỰ KIẾN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Tạm tính tiền hàng:', CurrencyHelper.format(subtotal)),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Phí vận chuyển dự kiến:',
                              shipping == 0 ? '0 ₫ (Miễn phí đơn ≥ 5tr)' : '+${CurrencyHelper.format(shipping)}',
                              valueColor: shipping == 0 ? AppColors.freeShipping : null,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Thuế VAT (8%) dự kiến:',
                              '+${CurrencyHelper.format(vat)}',
                            ),
                            const Divider(height: 20, thickness: 0.8, color: AppColors.divider),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng thanh toán dự kiến:',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                Text(
                                  CurrencyHelper.format(grandTotal),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Note box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Công thức: Tổng = Tiền hàng + Phí vận chuyển + Thuế VAT (8%)\n'
                                '• Mã giảm giá (Voucher) và phương thức nhận hàng sẽ được áp dụng tại bước Thanh toán tiếp theo.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(selectedCartItems: selectedItems),
                          ),
                        );
                      },
                      child: Text(
                        'Tiến hành mua hàng (${CurrencyHelper.format(grandTotal)})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
