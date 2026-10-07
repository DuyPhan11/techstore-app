import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../services/product_service.dart';
import '../../services/recently_viewed_service.dart';
import '../../services/review_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_specifications_view.dart';
import '../../widgets/quantity_selector.dart';
import '../../widgets/safe_network_image.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../../widgets/ai_sparkles_icon.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  ProductReviewSummaryModel? _reviews;
  List<ProductModel> _relatedProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedImageIndex = 0;
  int _quantity = 1;

  bool _isEligibleToReview = false;
  final TextEditingController _reviewCommentController = TextEditingController();
  final PageController _imagePageController = PageController();
  int _reviewRating = 5;
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  String _formatReviewDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceAll(' ', 'T'));
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await ProductService.getProductById(widget.productId);
      // Ghi nhận sản phẩm vào lịch sử đã xem
      RecentlyViewedService.addProduct(product);

      ProductReviewSummaryModel? reviews;
      bool eligible = false;
      List<ProductModel> related = [];

      try {
        reviews = await ReviewService.getProductReviews(widget.productId);
        if (mounted) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.isAuthenticated) {
            eligible = await ReviewService.checkEligibility(widget.productId);
          }
        }
      } catch (_) {}

      try {
        related = await ProductService.getRelatedProducts(
          productId: widget.productId,
          categoryId: product.category?.id,
          brandId: product.brand?.id,
          limit: 6,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _product = product;
          _reviews = reviews;
          _isEligibleToReview = eligible;
          _relatedProducts = related;
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

  Future<void> _submitReview() async {
    if (_reviewCommentController.text.trim().isEmpty) {
      ToastHelper.showError(context, 'Vui lòng nhập nội dung đánh giá');
      return;
    }

    setState(() => _isSubmittingReview = true);

    try {
      await ReviewService.createReview(
        widget.productId,
        _reviewRating,
        _reviewCommentController.text.trim(),
      );
      if (mounted) {
        ToastHelper.showSuccess(context, 'Cảm ơn bạn đã gửi đánh giá!');
        _reviewCommentController.clear();
        _isEligibleToReview = false;
        final reviews = await ReviewService.getProductReviews(widget.productId);
        setState(() {
          _reviews = reviews;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Không thể tải thông tin sản phẩm'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(product.id);
    final List<String> images = product.images.isNotEmpty
        ? product.images.map((i) => i.imageUrl).toList()
        : (product.primaryImageUrl != null ? [product.primaryImageUrl!] : []);

    final double avgRating = _reviews?.averageRating ?? 0.0;
    final int reviewCount = _reviews?.totalReviews ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main Content Area with Floating Top Buttons pinned to viewport
            Expanded(
              child: Stack(
                children: [
                  // 1. Scrollable Content (scrolls underneath floating buttons)
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Main Product Image with swipeable PageView
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBFBFD),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: images.isNotEmpty
                                  ? PageView.builder(
                                      controller: _imagePageController,
                                      itemCount: images.length,
                                      onPageChanged: (idx) {
                                        setState(() => _selectedImageIndex = idx);
                                      },
                                      itemBuilder: (context, idx) {
                                        return Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SafeNetworkImage(
                                            imageUrl: images[idx],
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fallbackIconSize: 64,
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(Icons.devices, size: 64, color: Colors.grey),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                    // Dot Indicator (Matching Screen 3)
                    if (images.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (idx) {
                          final isSelected = _selectedImageIndex == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isSelected ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.darkButton : const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    const SizedBox(height: 14),

                    // Thumbnails Row (Rounded rectangles with active orange border)
                    if (images.length > 1)
                      SizedBox(
                        height: 58,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final isSelected = _selectedImageIndex == idx;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedImageIndex = idx);
                                _imagePageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 58,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFEAECEF),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SafeNetworkImage(
                                    imageUrl: images[idx],
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fallbackIconSize: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Product Title & Rating Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Star Rating Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.starYellow, size: 16),
                              const SizedBox(width: 3),
                              Text(
                                reviewCount > 0
                                    ? '${avgRating.toStringAsFixed(1)} ($reviewCount)'
                                    : 'Chưa có đánh giá',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price & "Including taxes and duties" (Matching Screen 3)
                    Text(
                      CurrencyHelper.format(product.price),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Đã bao gồm thuế và phí VAT',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),


                    // Stock status and Quantity Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: product.isInStock ? AppColors.freeShippingBg : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.isInStock ? 'Còn hàng (${product.totalStock} sản phẩm)' : 'Hết hàng',
                            style: TextStyle(
                              color: product.isInStock ? AppColors.freeShipping : AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (product.isInStock)
                          QuantitySelector(
                            quantity: _quantity,
                            maxStock: product.totalStock,
                            onChanged: (newQty) {
                              setState(() => _quantity = newQty);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Trust & Warranty Badges
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.verified_user_rounded, size: 18, color: Colors.blue.shade700),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bảo hành ${product.warrantyMonths} tháng',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      const Text(
                                        'Chính hãng 100%',
                                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.replay_rounded, size: 18, color: Colors.amber.shade800),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Đổi trả trong 7 ngày',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      Text(
                                        'Lỗi do nhà sản xuất',
                                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // TechBot AI Consult Banner
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiChatScreen(
                              initialPrompt: 'Tư vấn cho mình về sản phẩm ${product.name} này với (cấu hình, ưu điểm và chế độ bảo hành)',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0284C7).withValues(alpha: 0.08),
                              const Color(0xFF2563EB).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE0F2FE)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const AiSparklesIcon(size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Cần tư vấn thêm về máy này?',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const AiSparklesIcon(size: 13),
                                    ],
                                  ),
                                  const Text(
                                    'Hỏi TechBot AI để phân tích cấu hình & so sánh ngay',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF0284C7)),
                          ],
                        ),
                      ),
                    ),
                    if (product.branchInventories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Tồn kho tại các chi nhánh',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...product.branchInventories.map((b) {
                              final isOut = b.quantity == 0;
                              final isLow = b.quantity > 0 && b.quantity <= 5;
                              final bColor = isOut ? AppColors.danger : (isLow ? Colors.orange.shade800 : AppColors.success);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.branchName,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOut ? 'Hết hàng' : '${b.quantity} sản phẩm',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bColor),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Product Description
                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const Text(
                        'Mô tả sản phẩm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Specifications
                    if (product.specifications != null && product.specifications!.isNotEmpty) ...[
                      const Text(
                        'Thông số kỹ thuật',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ProductSpecificationsView(specifications: product.specifications!),
                      const SizedBox(height: 24),
                    ],

                    // Reviews Section Header & Overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Đánh giá & Nhận xét',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (reviewCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.starYellow, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${avgRating.toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Overall Rating Summary Card (if has reviews)
                    if (reviewCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '/ 5',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      starIdx < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: AppColors.starYellow,
                                      size: 18,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                '$reviewCount lượt đánh giá',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Form to write review if eligible
                    if (_isEligibleToReview) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.rate_review_rounded, size: 18, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Đánh giá sản phẩm bạn đã mua:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(5, (index) {
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: Icon(
                                    index < _reviewRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: AppColors.starYellow,
                                    size: 26,
                                  ),
                                  onPressed: () => setState(() => _reviewRating = index + 1),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _reviewCommentController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Chia sẻ cảm nhận, trải nghiệm sử dụng sản phẩm này với mọi người...',
                                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _isSubmittingReview ? null : _submitReview,
                                child: _isSubmittingReview
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Gửi đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // User Reviews List
                    if (_reviews != null && _reviews!.reviews.isNotEmpty) ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reviews!.reviews.length,
                        separatorBuilder: (_, _) => const Divider(height: 24, thickness: 0.8, color: AppColors.divider),
                        itemBuilder: (context, idx) {
                          final review = _reviews!.reviews[idx];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // User Avatar / Initial
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryLight,
                                    backgroundImage: review.userAvatar != null && review.userAvatar!.isNotEmpty
                                        ? NetworkImage(review.userAvatar!)
                                        : null,
                                    child: review.userAvatar == null || review.userAvatar!.isEmpty
                                        ? Text(
                                            review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              review.userName,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                            ),
                                            if (review.isOwner) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('Bạn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Đã mua hàng',
                                              style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                                            ),
                                            if (review.createdAt != null) ...[
                                              const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              Text(
                                                _formatReviewDate(review.createdAt),
                                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Rating stars
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (starIdx) {
                                      return Icon(
                                        starIdx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: AppColors.starYellow,
                                        size: 15,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              if (review.comment.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  review.comment,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
                                ),
                              ],
                              if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF1D4ED8)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Phản hồi từ Người Bán:',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        review.adminReply!,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ] else if (_reviews != null && _reviews!.reviews.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 40, color: AppColors.textLight),
                            SizedBox(height: 8),
                            Text(
                              'Chưa có đánh giá nào cho sản phẩm này',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hãy mua và trải nghiệm để trở thành người đầu tiên đánh giá nhé!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Similar / Related Products Section
                    if (_relatedProducts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sản phẩm tương tự',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (product.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product.category!.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _relatedProducts.length,
                        itemBuilder: (context, idx) {
                          final item = _relatedProducts[idx];
                          return ProductCard(
                            product: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: item.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                  ),
                ),
              ),

              // 2. Floating Top Interactive Buttons (Sticky to Viewport, NO white bar!)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCircleButton(
                          icon: isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFavorite ? AppColors.danger : AppColors.textDark,
                          onTap: () async {
                            final isAdded = await favoriteProvider.toggleFavorite(product);
                            if (context.mounted) {
                              ToastHelper.showInfo(
                                context,
                                isAdded ? 'Đã thêm vào danh sách yêu thích' : 'Đã bỏ yêu thích',
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCircleButton(
                          icon: Icons.share_outlined,
                          onTap: () {
                            ToastHelper.showInfo(context, 'Chia sẻ sản phẩm ${product.name}');
                          },
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            _buildCircleButton(
                              icon: Icons.shopping_bag_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                            ),
                            if (cartProvider.totalItems > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${cartProvider.totalItems}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

            // Bottom Stacked Pill Buttons (Matching Screen 3 in image)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Button 1: Dark Button "Add to cart" (#1E2024)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: product.isInStock
                          ? () async {
                              if (!authProvider.isAuthenticated) {
                                ToastHelper.showInfo(context, 'Vui lòng đăng nhập để mua hàng');
                                return;
                              }
                              final ok = await cartProvider.addToCart(product.id, quantity: _quantity);
                              if (context.mounted) {
                                if (ok) {
                                  ToastHelper.showSuccess(context, 'Đã thêm $_quantity sản phẩm vào giỏ hàng!');
                                } else {
                                  ToastHelper.showError(context, cartProvider.errorMessage ?? 'Lỗi khi thêm giỏ');
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkButton,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Thêm vào giỏ hàng',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button 2: Vibrant Orange Pill Button "Buy Now" (#FF5400)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: product.isInStock
                          ? () {
                              if (!authProvider.isAuthenticated) {
                                ToastHelper.showInfo(context, 'Vui lòng đăng nhập để mua hàng');
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    directProduct: product,
                                    directQuantity: _quantity,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Mua ngay',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.textDark,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 19, color: color),
        onPressed: onTap,
      ),
    );
  }
}
