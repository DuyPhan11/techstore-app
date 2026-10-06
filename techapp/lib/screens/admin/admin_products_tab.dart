import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../utils/currency_format.dart';
import 'admin_add_product_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_brands_screen.dart';
import 'admin_product_detail_screen.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  static const int _pageSize = 20;

  String _filterStock = 'ALL'; // ALL, LOW, OUT
  String _filterStatus = 'ALL'; // ALL, ACTIVE, INACTIVE

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _currentPage + 1 < _totalPages) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await AdminService.getManagementProducts(
        page: _currentPage,
        size: _pageSize,
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _filterStatus == 'ALL' ? null : _filterStatus,
      );

      var list = res.content;
      if (_filterStock == 'LOW') {
        list = list.where((p) => p.totalStock > 0 && p.totalStock <= 5).toList();
      } else if (_filterStock == 'OUT') {
        list = list.where((p) => p.totalStock == 0).toList();
      }

      if (mounted) {
        setState(() {
          _products = list;
          _totalElements = res.totalElements;
          _totalPages = res.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final res = await AdminService.getManagementProducts(
        page: nextPage,
        size: _pageSize,
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _filterStatus == 'ALL' ? null : _filterStatus,
      );

      var list = res.content;
      if (_filterStock == 'LOW') {
        list = list.where((p) => p.totalStock > 0 && p.totalStock <= 5).toList();
      } else if (_filterStock == 'OUT') {
        list = list.where((p) => p.totalStock == 0).toList();
      }

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _products.addAll(list);
          _totalElements = res.totalElements;
          _totalPages = res.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminAddProductScreen()),
    );

    if (result == true) {
      _fetchProducts(reset: true);
    }
  }

  Future<void> _navigateToProductDetail(ProductModel product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductDetailScreen(productId: product.id),
      ),
    );

    if (result == true) {
      _fetchProducts(reset: true);
    }
  }

  Future<void> _toggleProductVisibility(ProductModel product) async {
    final bool isCurrentlyActive = product.status == 'ACTIVE';
    final String actionText = isCurrentlyActive ? 'ẩn' : 'mở bán lại';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionText sản phẩm'),
        content: Text(
          isCurrentlyActive
              ? 'Bạn có chắc chắn muốn ẩn sản phẩm "${product.name}" (SKU: ${product.sku}) khỏi gian hàng? Sau khi ẩn, khách hàng sẽ không thấy sản phẩm này khi mua sắm, nhưng thông tin và tồn kho vẫn được lưu trữ nguyên vẹn.'
              : 'Bạn có muốn kích hoạt và mở bán lại sản phẩm "${product.name}" (SKU: ${product.sku}) trên gian hàng cho khách hàng nhìn thấy và đặt mua?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? Colors.orange.shade800 : AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isCurrentlyActive ? 'Ẩn sản phẩm' : 'Mở bán lại',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.updateProductStatus(
          product.id,
          status: isCurrentlyActive ? 'INACTIVE' : 'ACTIVE',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã $actionText sản phẩm: ${product.name}'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchProducts(reset: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _showBranchStockSheet(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.storefront, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tồn kho chi nhánh: ${product.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Mã SKU: ${product.sku} • Tổng tồn kho toàn hệ thống: ${product.totalStock} sản phẩm',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(height: 24),
              if (product.branchInventories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu tồn kho theo từng chi nhánh cho sản phẩm này.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.branchInventories.length,
                  separatorBuilder: (_, _) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) {
                    final b = product.branchInventories[i];
                    final isOutOfStock = b.quantity == 0;
                    final isLow = b.quantity > 0 && b.quantity <= 5;
                    final color = isOutOfStock
                        ? AppColors.danger
                        : (isLow ? Colors.orange.shade800 : AppColors.success);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on_outlined, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.branchName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              if (b.branchAddress != null && b.branchAddress!.isNotEmpty)
                                Text(
                                  b.branchAddress!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isOutOfStock ? 'Hết hàng' : '${b.quantity} sản phẩm',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: AppColors.textDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sản phẩm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(reset: true),
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Shortcuts to Category & Brand Management
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.category_outlined, size: 15, color: Color(0xFF9333EA)),
                  label: const Text('QL Danh mục', style: TextStyle(fontSize: 12, color: Color(0xFF9333EA), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                    backgroundColor: const Color(0xFFFAF5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                    );
                    _fetchProducts(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.business_outlined, size: 15, color: Color(0xFF0284C7)),
                  label: const Text('QL Thương hiệu', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    backgroundColor: const Color(0xFFF0F9FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminBrandsScreen()),
                    );
                    _fetchProducts(reset: true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    _debounce?.cancel();
                    _fetchProducts(reset: true);
                  },
                  onChanged: (val) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      if (mounted) _fetchProducts(reset: true);
                    });
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc mã SKU...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchController.clear();
                              _fetchProducts(reset: true);
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _fetchProducts(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tìm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter row 1: Trạng thái hiển thị (Đang bán / Đã ẩn)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('Tất cả trạng thái', 'ALL'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('Đang bán', 'ACTIVE', color: AppColors.success),
                const SizedBox(width: 6),
                _buildStatusFilterChip('Đã ẩn', 'INACTIVE', color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Container(height: 16, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                _buildStockFilterChip('Tất cả kho', 'ALL'),
                const SizedBox(width: 6),
                _buildStockFilterChip('Sắp hết (≤ 5)', 'LOW', color: Colors.amber.shade800),
                const SizedBox(width: 6),
                _buildStockFilterChip('Hết hàng (0)', 'OUT', color: AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, {Color? color}) {
    final isSelected = _filterStatus == value;
    final primaryColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
        _fetchProducts(reset: true);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStockFilterChip(String label, String value, {Color? color}) {
    final isSelected = _filterStock == value;
    final primaryColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _filterStock = value;
        });
        _fetchProducts(reset: true);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _fetchProducts(reset: true),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm nào',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm mới'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _navigateToAddProduct,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF1F5F9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hiển thị ${_products.length} trên tổng số $_totalElements sản phẩm',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              if (_products.length < _totalElements)
                const Text(
                  'Cuộn để tải thêm',
                  style: TextStyle(fontSize: 11, color: AppColors.primary, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: _products.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= _products.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    Color stockBadgeColor;
    String stockText;
    if (product.totalStock == 0) {
      stockBadgeColor = AppColors.danger;
      stockText = 'Hết hàng';
    } else if (product.totalStock <= 5) {
      stockBadgeColor = Colors.orange.shade800;
      stockText = 'Còn ${product.totalStock} (Sắp hết)';
    } else {
      stockBadgeColor = AppColors.success;
      stockText = 'Còn ${product.totalStock} sp';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFFF1F5F9),
                    child: product.primaryImageUrl != null && product.primaryImageUrl!.isNotEmpty
                        ? Image.network(
                            product.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, color: Colors.grey),
                          )
                        : const Icon(Icons.devices, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SKU: ${product.sku}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.status == 'ACTIVE'
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.status == 'ACTIVE' ? 'Đang bán' : 'Đã ẩn',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: product.status == 'ACTIVE' ? AppColors.success : Colors.orange.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (product.category != null)
                            Expanded(
                              child: Text(
                                product.category!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyHelper.format(product.price),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showBranchStockSheet(context, product),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stockBadgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: stockBadgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    stockText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: stockBadgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.info_outline, size: 12, color: stockBadgeColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Branch breakdown display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  const Text('Kho chi nhánh: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  Expanded(
                    child: product.branchInventories.isEmpty
                        ? const Text('Chưa phân bổ tồn kho', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: product.branchInventories.map((b) {
                                final isOut = b.quantity == 0;
                                final isLow = b.quantity > 0 && b.quantity <= 5;
                                final bColor = isOut ? AppColors.danger : (isLow ? Colors.orange.shade800 : AppColors.success);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: bColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: bColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '${b.branchName}: ${b.quantity}',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bColor),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 4),

            // Card Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.location_searching, size: 14),
                  label: const Text('Xem tồn chi nhánh', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () => _showBranchStockSheet(context, product),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                      label: const Text('Chi tiết', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _navigateToProductDetail(product),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      icon: Icon(
                        product.status == 'ACTIVE' ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 14,
                        color: product.status == 'ACTIVE' ? Colors.orange.shade800 : AppColors.success,
                      ),
                      label: Text(
                        product.status == 'ACTIVE' ? 'Ẩn' : 'Hiện',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: product.status == 'ACTIVE' ? Colors.orange.shade800 : AppColors.success,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: product.status == 'ACTIVE' ? Colors.orange.shade300 : AppColors.success.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _toggleProductVisibility(product),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
