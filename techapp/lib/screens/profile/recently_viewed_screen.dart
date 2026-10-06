import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/recently_viewed_service.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  bool _isLoading = true;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final list = await RecentlyViewedService.getRecentlyViewed();
    if (mounted) {
      setState(() {
        _products = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRemoveProduct(ProductModel product) async {
    await RecentlyViewedService.removeProduct(product.id);
    if (mounted) {
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      ToastHelper.showSuccess(context, 'Đã xóa "${product.name}" khỏi lịch sử xem');
    }
  }

  Future<void> _handleClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Xóa lịch sử xem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ danh sách sản phẩm đã xem gần đây không?',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await RecentlyViewedService.clearRecentlyViewed();
    if (mounted) {
      setState(() {
        _products.clear();
      });
      ToastHelper.showSuccess(context, 'Đã xóa toàn bộ lịch sử xem');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: const Text('Sản phẩm đã xem'),
        actions: [
          if (_products.isNotEmpty)
            TextButton.icon(
              onPressed: _handleClearAll,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
              label: const Text(
                'Xóa tất cả',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      EmptyStateWidget(
                        icon: Icons.history_rounded,
                        title: 'Chưa có sản phẩm đã xem',
                        subtitle:
                            'Khi bạn xem chi tiết các sản phẩm trong cửa hàng, danh sách sẽ được lưu lại tại đây để bạn tiện xem lại.',
                        buttonText: 'Khám phá sản phẩm ngay',
                        onButtonPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle summary row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đã xem gần đây (${_products.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_outlined, size: 13, color: Color(0xFF6366F1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Bấm X để bỏ lưu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Products Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: ProductCard(
                                    product: product,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(productId: product.id),
                                        ),
                                      );
                                      _loadProducts();
                                    },
                                  ),
                                ),
                                // Remove from history button on top-left
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    shadowColor: Colors.black.withValues(alpha: 0.2),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _handleRemoveProduct(product),
                                      child: const Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 15,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }
}
