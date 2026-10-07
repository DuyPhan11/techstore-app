import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/product_service.dart';
import '../../services/recently_viewed_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../notification/notification_screen.dart';
import 'package:flutter/services.dart';
import '../../models/banner_model.dart';
import '../../services/banner_service.dart';
import '../../widgets/promo_banner_card.dart';
import '../coupon/customer_coupons_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../../widgets/ai_sparkles_icon.dart';
import '../../utils/toast_helper.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBackendOnline = false;
  bool _isCheckingBackend = true;
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Recommendation State
  List<ProductModel> _recommendedProducts = [];
  bool _isLoadingRecommendations = false;
  bool _hasViewedHistory = false;

  // Banner Carousel State
  List<BannerModel> _banners = [];
  late final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Scroll Controller for Infinite Scrolling
  late final ScrollController _scrollController;

  final List<String> _sampleCategories = [
    'Tất cả',
    'Điện thoại',
    'Laptop',
    'Phụ kiện',
    'Tai nghe',
    'Đồng hồ',
    'Gaming',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkBackendHealth();
    _loadBanners();
    _loadRecommendations();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.hasMore &&
          !productProvider.isLoadingMore &&
          !productProvider.isLoading) {
        productProvider.fetchProducts(reset: false);
      }
    }
  }

  Future<void> _loadBanners() async {
    try {
      final list = await BannerService.getActiveBanners();
      if (mounted) {
        setState(() {
          _banners = list;
        });
        _startBannerTimer();
      }
    } catch (_) {}
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_banners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || !_bannerPageController.hasClients) return;
      final nextIndex = (_currentBannerIndex + 1) % _banners.length;
      _bannerPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _handleBannerTap(BannerModel banner) {
    if (banner.linkType == 'COUPON') {
      if (banner.linkValue != null && banner.linkValue!.trim().isNotEmpty) {
        Clipboard.setData(ClipboardData(text: banner.linkValue!.trim()));
        ToastHelper.showSuccess(context, 'Đã sao chép mã ưu đãi "${banner.linkValue!.trim()}"!');
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerCouponsScreen()),
      );
    } else if (banner.linkType == 'PRODUCT') {
      final productId = int.tryParse(banner.linkValue ?? '');
      if (productId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
        );
      } else {
        widget.onTabChange(1);
      }
    } else if (banner.linkType == 'CATEGORY') {
      widget.onTabChange(1);
    } else {
      widget.onTabChange(1);
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final viewed = await RecentlyViewedService.getRecentlyViewed();
      final viewedIds = viewed.map((p) => p.id).toList();
      final hasHistory = viewedIds.isNotEmpty;

      final list = await ProductService.getRecommendations(viewedIds: viewedIds, limit: 6);
      if (mounted) {
        setState(() {
          _recommendedProducts = list;
          _hasViewedHistory = hasHistory;
          _isLoadingRecommendations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isCheckingBackend = true;
    });

    try {
      await ApiService.get(ApiConfig.health);
      if (mounted) {
        setState(() {
          _isBackendOnline = true;
          _isCheckingBackend = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBackendOnline = false;
          _isCheckingBackend = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    if (productProvider.keyword != _searchController.text && !FocusScope.of(context).hasFocus) {
      _searchController.text = productProvider.keyword;
    }

    // Merge backend categories with pill list if available
    final categories = productProvider.categories.isNotEmpty
        ? ['Tất cả', ...productProvider.categories.map((c) => c.name)]
        : _sampleCategories;

    int activeCategoryIndex = _selectedCategoryIndex;
    if (productProvider.selectedCategoryId == null) {
      activeCategoryIndex = 0;
    } else if (productProvider.categories.isNotEmpty) {
      final idx = productProvider.categories.indexWhere((c) => c.id == productProvider.selectedCategoryId);
      if (idx != -1) {
        activeCategoryIndex = idx + 1;
      }
    }

    final isCategoryFiltered = activeCategoryIndex > 0;
    final isSearching = productProvider.keyword.isNotEmpty;
    final isFiltered = isCategoryFiltered || isSearching;
    final selectedCategoryName = activeCategoryIndex < categories.length
        ? categories[activeCategoryIndex]
        : 'Sản phẩm';

    String sectionTitle;
    if (isSearching) {
      sectionTitle = 'Kết quả: "${productProvider.keyword}"';
    } else if (isCategoryFiltered) {
      sectionTitle = selectedCategoryName;
    } else {
      sectionTitle = _hasViewedHistory
          ? 'Gợi ý dành riêng cho bạn'
          : 'Sản phẩm nổi bật';
    }

    final List<ProductModel> displayList;
    if (isFiltered) {
      displayList = productProvider.products;
    } else if (_recommendedProducts.isNotEmpty) {
      final recommendedIds = _recommendedProducts.map((p) => p.id).toSet();
      final additional = productProvider.products
          .where((p) => !recommendedIds.contains(p.id))
          .toList();
      displayList = [..._recommendedProducts, ...additional];
    } else {
      displayList = productProvider.products;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AiSparklesIcon(size: 20),
                  SizedBox(width: 6),
                  Text(
                    'TechBot AI',
                    style: TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _searchController.clear();
            await Future.wait([
              _checkBackendHealth(),
              productProvider.fetchProducts(reset: true),
              productProvider.fetchCategories(),
              productProvider.fetchBrands(),
              cartProvider.fetchCart(),
              _loadBanners(),
              _loadRecommendations(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search Bar + Store Icon + Notification Bell Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          productProvider.requestSearchFocus();
                          widget.onTabChange(1);
                        },
                        child: TextField(
                          controller: _searchController,
                          readOnly: true,
                          onTap: () {
                            productProvider.requestSearchFocus();
                            widget.onTabChange(1);
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm sản phẩm, thương hiệu...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      productProvider.setKeyword('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Circular Cart Icon (Giỏ hàng)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textDark, size: 21),
                            tooltip: 'Giỏ hàng',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          ),
                          if (cartProvider.totalItems > 0)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${cartProvider.totalItems > 99 ? '99+' : cartProvider.totalItems}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Circular Notification Bell with Badge Dot
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Consumer<NotificationProvider>(
                        builder: (context, notifProvider, _) {
                          final unreadCount = notifProvider.unreadCount;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark, size: 22),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                  );
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Circular AI TechBot Assistant Button (Blue Stars Icon)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const AiSparklesIcon(size: 21),
                        tooltip: 'TechBot AI Tư vấn',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiChatScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Backend diagnostic pill (compact)
                if (!_isBackendOnline && !_isCheckingBackend)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mất kết nối máy chủ (${ApiConfig.baseUrl})',
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ),
                        GestureDetector(
                          onTap: _checkBackendHealth,
                          child: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                // Auto-playing Promotional Banner Carousel (Admin Managed)
                if (_banners.isNotEmpty) ...[
                  SizedBox(
                    height: 172,
                    child: PageView.builder(
                      controller: _bannerPageController,
                      itemCount: _banners.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentBannerIndex = idx;
                        });
                      },
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: PromoBannerCard(
                            banner: banner,
                            onTap: () => _handleBannerTap(banner),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_banners.length > 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (index) {
                        final isSelected = _currentBannerIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isSelected ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ] else ...[
                  // Fallback banner when no banners loaded
                  PromoBannerCard(
                    banner: BannerModel(
                      id: 0,
                      title: 'CYBER\nTECHSTORE',
                      subtitle: 'cho thiết bị công nghệ & phụ kiện thông minh',
                      badgeText1: 'GIẢM 40%',
                      badgeText2: 'FREESHIP',
                      titleColor: '#FFEB3B',
                      backgroundColor: '#581C87',
                      backgroundGradientEnd: '#3B0764',
                      iconName: 'devices_other',
                      linkType: 'CATEGORY',
                      displayOrder: 1,
                      isActive: true,
                    ),
                    onTap: () => widget.onTabChange(1),
                  ),
                ],
                const SizedBox(height: 18),

                // Category Pills Horizontal List (Matching Screen 2)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = activeCategoryIndex == index;
                      final name = categories[index];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                          if (index > 0 && productProvider.categories.isNotEmpty) {
                            productProvider.setCategory(productProvider.categories[index - 1].id);
                          } else {
                            _searchController.clear();
                            productProvider.clearFilters();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.textDark : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.textDark : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // Category or Hot Sales Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              sectionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onTabChange(1),
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (productProvider.isLoading || (_isLoadingRecommendations && displayList.isEmpty))
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Đang tải sản phẩm...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else if (displayList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(isSearching ? Icons.search_off_rounded : Icons.inventory_2_outlined, size: 48, color: AppColors.textLight),
                          const SizedBox(height: 8),
                          Text(
                            isSearching
                                ? 'Không tìm thấy sản phẩm nào khớp với "${productProvider.keyword}"'
                                : (isCategoryFiltered
                                    ? 'Chưa có sản phẩm nào thuộc $selectedCategoryName'
                                    : 'Không có sản phẩm nào'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _selectedCategoryIndex = 0);
                              productProvider.clearFilters();
                            },
                            child: const Text('Xem tất cả sản phẩm'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final product = displayList[index];
                      return ProductCard(
                        product: product,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(productId: product.id),
                            ),
                          );
                          _loadRecommendations();
                        },
                      );
                    },
                  ),
                  if (productProvider.isLoadingMore)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Đang tải thêm sản phẩm...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!productProvider.hasMore && displayList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          const Text(
                            'Đã hiển thị tất cả sản phẩm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 32,
                            height: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
