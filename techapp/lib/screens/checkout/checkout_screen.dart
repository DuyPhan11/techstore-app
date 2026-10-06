import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/branch_model.dart';
import '../../models/coupon_model.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/checkout_service.dart';
import '../../services/location_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../models/product_model.dart';
import '../../models/cart_model.dart';
import '../address/address_list_screen.dart';
import '../coupon/customer_coupons_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final ProductModel? directProduct;
  final int directQuantity;
  final List<CartItemModel>? selectedCartItems;

  const CheckoutScreen({
    super.key,
    this.directProduct,
    this.directQuantity = 1,
    this.selectedCartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();
  final _notesController = TextEditingController();

  List<BranchModel> _branches = [];
  int? _selectedBranchId;

  // Shipping method: 0 = Home delivery, 1 = Pick up in store
  int _shippingMethodIndex = 0;

  // Selected payment card / method
  int _selectedCardIndex = 0;
  String _paymentMethod = 'COD'; // 'COD', 'ONLINE_MOCK', 'GPAY', 'APPLEPAY'

  bool _isLoadingInitial = true;
  bool _isCheckingCoupon = false;
  bool _isSubmitting = false;

  bool _isGettingGps = false;

  Future<void> _handleQuickGps() async {
    setState(() => _isGettingGps = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      final place = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _addressController.text = place.displayName;
        });
        ToastHelper.showSuccess(context, 'Đã lấy vị trí GPS thành công!');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingGps = false);
      }
    }
  }

  CouponValidationModel? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _nameController.text = auth.user!.fullName;
      if (auth.user!.phone != null) {
        _phoneController.text = auth.user!.phone!;
      }
    }

    final addressProv = Provider.of<AddressProvider>(context, listen: false);
    if (addressProv.addresses.isEmpty) {
      await addressProv.fetchAddresses();
    }
    final selectedOrDef = addressProv.selectedAddress ?? addressProv.defaultAddress;
    if (selectedOrDef != null) {
      _nameController.text = selectedOrDef.recipientName;
      _phoneController.text = selectedOrDef.phone;
      _addressController.text = selectedOrDef.fullAddress;
    }

    try {
      final branches = await CheckoutService.getBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          if (branches.isNotEmpty) {
            _selectedBranchId = branches.first.id;
          }
          _isLoadingInitial = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      ToastHelper.showError(context, 'Vui lòng nhập mã giảm giá');
      return;
    }

    final isDirect = widget.directProduct != null;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final List<CartItemModel> checkoutItems = widget.selectedCartItems ?? cart.items;
    final orderAmount = isDirect
        ? (widget.directProduct!.price * widget.directQuantity)
        : checkoutItems.fold<double>(0.0, (sum, i) => sum + i.subtotal);

    setState(() => _isCheckingCoupon = true);

    try {
      final result = await CheckoutService.validateCoupon(code, orderAmount);
      if (result.valid) {
        setState(() {
          _appliedCoupon = result;
        });
        if (mounted) {
          ToastHelper.showSuccess(context, 'Đã áp dụng mã ${result.couponCode}: -${CurrencyHelper.format(result.discountAmount)}');
        }
      } else {
        if (mounted) {
          ToastHelper.showError(context, result.message ?? 'Mã khuyến mãi không hợp lệ');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingCoupon = false);
      }
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final isDirect = widget.directProduct != null;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final List<CartItemModel> checkoutItems = widget.selectedCartItems ?? cart.items;
    if (!isDirect && checkoutItems.isEmpty) {
      ToastHelper.showError(context, 'Không có sản phẩm nào để thanh toán');
      return;
    }

    final double subtotal = isDirect
        ? (widget.directProduct!.price * widget.directQuantity)
        : checkoutItems.fold<double>(0.0, (sum, i) => sum + i.subtotal);
    final isStorePickup = _shippingMethodIndex == 1;
    final bool isFreeShipping = isStorePickup || subtotal >= 5000000;
    final double shippingFee = isFreeShipping ? 0.0 : 30000.0;
    const double vatRate = 0.08;

    setState(() => _isSubmitting = true);

    try {
      final order = await CheckoutService.checkout(
        recipientName: _nameController.text.trim(),
        recipientPhone: _phoneController.text.trim(),
        shippingAddress: _shippingMethodIndex == 1
            ? 'Nhận tại cửa hàng (${_branches.firstWhere((b) => b.id == _selectedBranchId, orElse: () => _branches.first).name})'
            : _addressController.text.trim(),
        branchId: _selectedBranchId,
        couponCode: _appliedCoupon?.couponCode,
        paymentMethod: _paymentMethod == 'COD' ? 'COD' : 'ONLINE_MOCK',
        notes: _notesController.text.trim(),
        directProductId: isDirect ? widget.directProduct!.id : null,
        directQuantity: isDirect ? widget.directQuantity : null,
        selectedCartItemIds: isDirect ? null : checkoutItems.map((e) => e.id).toList(),
        shippingFee: shippingFee,
        vatRate: vatRate,
        mockPaymentSuccess: true,
      );

      if (!isDirect) {
        if (widget.selectedCartItems != null) {
          await cart.fetchCart();
        } else {
          await cart.clearCart();
        }
      }
      if (mounted) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(order: order),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDirect = widget.directProduct != null;
    final List<CartItemModel> checkoutItems = widget.selectedCartItems ?? cart.items;
    final double subtotal = isDirect
        ? (widget.directProduct!.price * widget.directQuantity)
        : checkoutItems.fold<double>(0.0, (sum, i) => sum + i.subtotal);
    final double discount = _appliedCoupon != null ? _appliedCoupon!.discountAmount : 0.0;
    final bool isStorePickup = _shippingMethodIndex == 1;
    final bool isFreeShipping = isStorePickup || subtotal >= 5000000;
    final double shippingFee = isFreeShipping ? 0.0 : 30000.0;
    const double vatRate = 0.08; // 8% VAT
    final double taxableAmount = (subtotal - discount) > 0 ? (subtotal - discount) : 0.0;
    final double vatAmount = (taxableAmount * vatRate).roundToDouble();
    final double grandTotal = taxableAmount + shippingFee + vatAmount;

    if (_isLoadingInitial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final showPreview = isDirect || checkoutItems.isNotEmpty;
    final String previewImage = isDirect
        ? (widget.directProduct!.primaryImageUrl ?? '')
        : (checkoutItems.isNotEmpty ? (checkoutItems.first.primaryImageUrl ?? '') : '');
    final String previewName = isDirect
        ? widget.directProduct!.name
        : (checkoutItems.isNotEmpty ? checkoutItems.first.productName : '');
    final String previewSubtitle = isDirect
        ? 'Số lượng: ${widget.directQuantity} • ${CurrencyHelper.format(subtotal)}'
        : '${checkoutItems.length} mặt hàng • ${CurrencyHelper.format(subtotal)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Preview Header
              if (showPreview) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAECEF)),
                  ),
                  child: Row(
                    children: [
                      // Circular Product Thumbnail
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SafeNetworkImage(
                          imageUrl: previewImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          fallbackIconSize: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previewName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              previewSubtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Shipping Method Segmented Control (Matching Screen 4)
              const Text(
                'Phương thức vận chuyển',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _shippingMethodIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _shippingMethodIndex == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _shippingMethodIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'Giao tận nơi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _shippingMethodIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _shippingMethodIndex == 0 ? AppColors.textDark : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _shippingMethodIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _shippingMethodIndex == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _shippingMethodIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'Nhận tại cửa hàng',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _shippingMethodIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _shippingMethodIndex == 1 ? AppColors.textDark : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Visual Credit Card Slider (Matching Screen 4)
              const Text(
                'Thẻ thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildVisualCard(
                      index: 0,
                      gradient: AppColors.cardGradientOrange,
                      bankName: 'TECHPAY VISA',
                      cardNumber: '**** **** **** 4242',
                      holderName: auth.user?.fullName.toUpperCase() ?? 'KHACH HANG',
                      expDate: '12/28',
                    ),
                    const SizedBox(width: 14),
                    _buildVisualCard(
                      index: 1,
                      gradient: AppColors.cardGradientPurple,
                      bankName: 'CYBER CARD',
                      cardNumber: '**** **** **** 8888',
                      holderName: auth.user?.fullName.toUpperCase() ?? 'KHACH HANG',
                      expDate: '09/27',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment method quick pills (G Pay, Apple Pay, PayPal, COD)
              Row(
                children: [
                  _buildPaymentPill(
                    label: 'COD',
                    icon: Icons.local_shipping_outlined,
                    methodKey: 'COD',
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentPill(
                    label: 'G Pay',
                    icon: Icons.account_balance_wallet_outlined,
                    methodKey: 'GPAY',
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentPill(
                    label: 'Apple Pay',
                    icon: Icons.phone_iphone_rounded,
                    methodKey: 'APPLEPAY',
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentPill(
                    label: 'Thẻ',
                    icon: Icons.credit_card_rounded,
                    methodKey: 'ONLINE_MOCK',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Delivery details inputs
              const Text(
                'Thông tin người nhận',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên người nhận *',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên người nhận' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại *',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              const SizedBox(height: 10),

              if (_shippingMethodIndex == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Địa chỉ giao hàng *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: _isGettingGps
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                                )
                              : const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                          label: const Text('Lấy GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _isGettingGps ? null : _handleQuickGps,
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.contacts_outlined, size: 14, color: Color(0xFF0284C7)),
                          label: const Text('Sổ địa chỉ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          onPressed: () async {
                            final picked = await Navigator.push<AddressModel>(
                              context,
                              MaterialPageRoute(builder: (_) => const AddressListScreen(isSelectionMode: true)),
                            );
                            if (picked != null) {
                              setState(() {
                                _nameController.text = picked.recipientName;
                                _phoneController.text = picked.phone;
                                _addressController.text = picked.fullAddress;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Nhập số nhà, tên đường, phường/xã, quận/huyện, thành phố...',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập địa chỉ nhận hàng' : null,
                ),
                const SizedBox(height: 12),
              ],

              // Branch dropdown for pick up
              if (_branches.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Chi nhánh nhận hàng',
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                  items: _branches.map((b) {
                    return DropdownMenuItem<int>(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBranchId = val),
                ),
                const SizedBox(height: 10),
              ],

              // Coupon Input Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mã giảm giá / Voucher',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.confirmation_num_outlined, size: 14, color: Color(0xFF4F46E5)),
                    label: const Text('Kho Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    onPressed: () async {
                      final isDirect = widget.directProduct != null;
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      final List<CartItemModel> checkoutItems = widget.selectedCartItems ?? cart.items;
                      final orderAmount = isDirect
                          ? (widget.directProduct!.price * widget.directQuantity)
                          : checkoutItems.fold<double>(0.0, (sum, i) => sum + i.subtotal);

                      final picked = await Navigator.push<CouponModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerCouponsScreen(
                            isSelectionMode: true,
                            currentOrderAmount: orderAmount,
                          ),
                        ),
                      );

                      if (picked != null) {
                        _couponController.text = picked.code;
                        _applyCoupon();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Mã giảm giá (ví dụ: TECH10)',
                        prefixIcon: Icon(Icons.discount_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isCheckingCoupon ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkButton,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: _isCheckingCoupon
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Áp dụng'),
                  ),
                ],
              ),
              if (_appliedCoupon != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Mã ${_appliedCoupon!.couponCode}: -${CurrencyHelper.format(_appliedCoupon!.discountAmount)}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _appliedCoupon = null;
                          _couponController.clear();
                        });
                      },
                      child: const Text('Xóa mã', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Order Summary / Price Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textDark),
                        SizedBox(width: 6),
                        Text(
                          'Chi tiết thanh toán',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 1. Tạm tính (Tiền hàng)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính (Tiền hàng)', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(CurrencyHelper.format(subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),

                    // 2. Giảm giá Voucher (nếu có)
                    if (discount > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Giảm giá voucher', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _appliedCoupon?.couponCode ?? '',
                                  style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '-${CurrencyHelper.format(discount)}',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 3. Phí vận chuyển
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phí vận chuyển', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              isStorePickup
                                  ? 'Nhận tại cửa hàng'
                                  : (subtotal >= 5000000 ? 'Giao tận nơi (Freeship đơn ≥ 5tr)' : 'Giao hàng tiêu chuẩn'),
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                            ),
                          ],
                        ),
                        if (shippingFee == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Text(
                              'Miễn phí (0 ₫)',
                              style: TextStyle(
                                color: AppColors.freeShipping,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          Text(
                            '+${CurrencyHelper.format(shippingFee)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 4. Thuế VAT (8%)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thuế VAT (8%)', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Thuế GTGT thiết bị công nghệ', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                          ],
                        ),
                        Text(
                          '+${CurrencyHelper.format(vatAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
                        ),
                      ],
                    ),

                    const Divider(height: 24, thickness: 0.8, color: AppColors.divider),

                    // 5. Tổng thanh toán
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng thanh toán',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        Text(
                          CurrencyHelper.format(grandTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    // 6. Explanation Note Box
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
                                    text: discount > 0
                                        ? 'Tổng tiền = Tiền hàng - Giảm giá + Phí vận chuyển + Thuế VAT (8%)'
                                        : 'Tổng tiền = Tiền hàng + Phí vận chuyển + Thuế VAT (8%)',
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
              const SizedBox(height: 20),

              // Full-Width Orange Pill Button "Xác nhận đặt hàng" (Matching Screen 4)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Xác nhận đặt hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCard({
    required int index,
    required List<Color> gradient,
    required String bankName,
    required String cardNumber,
    required String holderName,
    required String expDate,
  }) {
    final isSelected = _selectedCardIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardIndex = index;
          _paymentMethod = 'ONLINE_MOCK';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            const Icon(Icons.credit_card, color: Colors.white, size: 24),
            Text(
              cardNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  holderName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  expDate,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPill({
    required String label,
    required IconData icon,
    required String methodKey,
  }) {
    final isSelected = _paymentMethod == methodKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentMethod = methodKey;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textDark,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
