import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/brand_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/product_card.dart';
import '../../widgets/empty_state.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProductProvider>(context, listen: false);
    _searchController.text = provider.keyword;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        provider.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildModalPillChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    int? tempCategoryId = provider.selectedCategoryId;
    int? tempBrandId = provider.selectedBrandId;
    double? tempMinPrice = provider.minPrice;
    double? tempMaxPrice = provider.maxPrice;
    String tempSortBy = provider.sortBy;
    String tempSortDir = provider.sortDir;

    final minPriceController = TextEditingController(
      text: tempMinPrice != null ? tempMinPrice.toInt().toString() : '',
    );
    final maxPriceController = TextEditingController(
      text: tempMaxPrice != null ? tempMaxPrice.toInt().toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0D5DD),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Bộ lọc sản phẩm',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              setModalState(() {
                                tempCategoryId = null;
                                tempBrandId = null;
                                tempMinPrice = null;
                                tempMaxPrice = null;
                                minPriceController.clear();
                                maxPriceController.clear();
                                tempSortBy = 'createdAt';
                                tempSortDir = 'desc';
                              });
                            },
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                      const SizedBox(height: 14),

                      // Filter Options List
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // Danh mục
                            _buildModalSectionTitle('Danh mục', Icons.category_outlined),
                            Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: [
                                _buildModalPillChip(
                                  label: 'Tất cả',
                                  isSelected: tempCategoryId == null,
                                  onTap: () => setModalState(() => tempCategoryId = null),
                                ),
                                ...provider.categories.map((cat) {
                                  final isSel = tempCategoryId == cat.id;
                                  return _buildModalPillChip(
                                    label: cat.name,
                                    isSelected: isSel,
                                    onTap: () => setModalState(() => tempCategoryId = isSel ? null : cat.id),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Thương hiệu
                            _buildModalSectionTitle('Thương hiệu', Icons.verified_outlined),
                            Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: [
                                _buildModalPillChip(
                                  label: 'Tất cả',
                                  isSelected: tempBrandId == null,
                                  onTap: () => setModalState(() => tempBrandId = null),
                                ),
                                ...provider.brands.map((brand) {
                                  final isSel = tempBrandId == brand.id;
                                  return _buildModalPillChip(
                                    label: brand.name,
                                    isSelected: isSel,
                                    onTap: () => setModalState(() => tempBrandId = isSel ? null : brand.id),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Khoảng giá
                            _buildModalSectionTitle('Khoảng giá (VNĐ)', Icons.monetization_on_outlined),
                            // Quick presets
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildModalPillChip(
                                  label: 'Tất cả giá',
                                  isSelected: tempMinPrice == null && tempMaxPrice == null,
                                  onTap: () {
                                    setModalState(() {
                                      tempMinPrice = null;
                                      tempMaxPrice = null;
                                      minPriceController.clear();
                                      maxPriceController.clear();
                                    });
                                  },
                                ),
                                _buildModalPillChip(
                                  label: '< 5 triệu',
                                  isSelected: tempMinPrice == null && tempMaxPrice == 5000000.0,
                                  onTap: () {
                                    setModalState(() {
                                      tempMinPrice = null;
                                      tempMaxPrice = 5000000.0;
                                      minPriceController.clear();
                                      maxPriceController.text = '5000000';
                                    });
                                  },
                                ),
                                _buildModalPillChip(
                                  label: '5 - 15 triệu',
                                  isSelected: tempMinPrice == 5000000.0 && tempMaxPrice == 15000000.0,
                                  onTap: () {
                                    setModalState(() {
                                      tempMinPrice = 5000000.0;
                                      tempMaxPrice = 15000000.0;
                                      minPriceController.text = '5000000';
                                      maxPriceController.text = '15000000';
                                    });
                                  },
                                ),
                                _buildModalPillChip(
                                  label: '15 - 30 triệu',
                                  isSelected: tempMinPrice == 15000000.0 && tempMaxPrice == 30000000.0,
                                  onTap: () {
                                    setModalState(() {
                                      tempMinPrice = 15000000.0;
                                      tempMaxPrice = 30000000.0;
                                      minPriceController.text = '15000000';
                                      maxPriceController.text = '30000000';
                                    });
                                  },
                                ),
                                _buildModalPillChip(
                                  label: '> 30 triệu',
                                  isSelected: tempMinPrice == 30000000.0 && tempMaxPrice == null,
                                  onTap: () {
                                    setModalState(() {
                                      tempMinPrice = 30000000.0;
                                      tempMaxPrice = null;
                                      minPriceController.text = '30000000';
                                      maxPriceController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Price Inputs
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F5F7),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: TextField(
                                      controller: minPriceController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: const InputDecoration(
                                        hintText: 'Tối thiểu',
                                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                        prefixText: '₫ ',
                                        prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                      ),
                                      onChanged: (val) {
                                        setModalState(() {
                                          final parsed = double.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                                          tempMinPrice = (parsed != null && parsed >= 0) ? parsed : null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F5F7),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: TextField(
                                      controller: maxPriceController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: const InputDecoration(
                                        hintText: 'Tối đa',
                                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                        prefixText: '₫ ',
                                        prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                      ),
                                      onChanged: (val) {
                                        setModalState(() {
                                          final parsed = double.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                                          tempMaxPrice = (parsed != null && parsed >= 0) ? parsed : null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Sắp xếp
                            _buildModalSectionTitle('Sắp xếp theo', Icons.sort_rounded),
                            Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: [
                                _buildModalPillChip(
                                  label: 'Mới nhất',
                                  icon: Icons.access_time_rounded,
                                  isSelected: tempSortBy == 'createdAt' && tempSortDir == 'desc',
                                  onTap: () => setModalState(() {
                                    tempSortBy = 'createdAt';
                                    tempSortDir = 'desc';
                                  }),
                                ),
                                _buildModalPillChip(
                                  label: 'Giá: Thấp → Cao',
                                  icon: Icons.trending_up_rounded,
                                  isSelected: tempSortBy == 'price' && tempSortDir == 'asc',
                                  onTap: () => setModalState(() {
                                    tempSortBy = 'price';
                                    tempSortDir = 'asc';
                                  }),
                                ),
                                _buildModalPillChip(
                                  label: 'Giá: Cao → Thấp',
                                  icon: Icons.trending_down_rounded,
                                  isSelected: tempSortBy == 'price' && tempSortDir == 'desc',
                                  onTap: () => setModalState(() {
                                    tempSortBy = 'price';
                                    tempSortDir = 'desc';
                                  }),
                                ),
                                _buildModalPillChip(
                                  label: 'Tên: A → Z',
                                  icon: Icons.sort_by_alpha_rounded,
                                  isSelected: tempSortBy == 'name' && tempSortDir == 'asc',
                                  onTap: () => setModalState(() {
                                    tempSortBy = 'name';
                                    tempSortDir = 'asc';
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: AppColors.primary.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {
                            final minVal = double.tryParse(minPriceController.text.trim().replaceAll('.', '').replaceAll(',', ''));
                            final maxVal = double.tryParse(maxPriceController.text.trim().replaceAll('.', '').replaceAll(',', ''));

                            final min = (minVal != null && minVal >= 0) ? minVal : null;
                            final max = (maxVal != null && maxVal >= 0) ? maxVal : null;

                            if (min != null && max != null && min > max) {
                              ToastHelper.showError(context, 'Giá tối thiểu không được lớn hơn giá tối đa');
                              return;
                            }

                            Navigator.pop(ctx);

                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }

                            provider.applyFilters(
                              categoryId: tempCategoryId,
                              brandId: tempBrandId,
                              minPrice: min,
                              maxPrice: max,
                              sortBy: tempSortBy,
                              sortDir: tempSortDir,
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Áp dụng bộ lọc',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActiveFilterTag({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    if (provider.shouldFocusSearch) {
      provider.consumeSearchFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }

    if (_searchController.text != provider.keyword && !FocusScope.of(context).hasFocus) {
      _searchController.text = provider.keyword;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả sản phẩm'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm, thương hiệu...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _debounce?.cancel();
                                _searchController.clear();
                                provider.setKeyword('');
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), () {
                        if (mounted) {
                          provider.setKeyword(value.trim());
                        }
                      });
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      provider.setKeyword(value.trim());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: provider.hasActiveFilters ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: provider.hasActiveFilters ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: provider.hasActiveFilters
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      color: provider.hasActiveFilters ? Colors.white : AppColors.textDark,
                    ),
                    onPressed: () => _showFilterModal(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips summary
          if (provider.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Đang lọc: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    if (provider.keyword.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildActiveFilterTag(
                        label: 'Từ khóa: "${provider.keyword}"',
                        onDelete: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          provider.setKeyword('');
                          setState(() {});
                        },
                      ),
                    ],
                    if (provider.selectedCategoryId != null) ...[
                      const SizedBox(width: 6),
                      _buildActiveFilterTag(
                        label: provider.categories.firstWhere(
                          (c) => c.id == provider.selectedCategoryId,
                          orElse: () => CategoryModel(id: 0, name: '', slug: ''),
                        ).name,
                        onDelete: () => provider.setCategory(null),
                      ),
                    ],
                    if (provider.selectedBrandId != null) ...[
                      const SizedBox(width: 6),
                      _buildActiveFilterTag(
                        label: provider.brands.firstWhere(
                          (b) => b.id == provider.selectedBrandId,
                          orElse: () => BrandModel(id: 0, name: '', slug: ''),
                        ).name,
                        onDelete: () => provider.setBrand(null),
                      ),
                    ],
                    if (provider.minPrice != null || provider.maxPrice != null) ...[
                      const SizedBox(width: 6),
                      _buildActiveFilterTag(
                        label: 'Giá: ${provider.minPrice != null ? "${(provider.minPrice! / 1e6).toStringAsFixed(provider.minPrice! % 1e6 == 0 ? 0 : 1)}tr" : "0"} - ${provider.maxPrice != null ? "${(provider.maxPrice! / 1e6).toStringAsFixed(provider.maxPrice! % 1e6 == 0 ? 0 : 1)}tr" : "∞"}',
                        onDelete: () => provider.setPriceFilter(null, null),
                      ),
                    ],
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.resetFilters();
                      },
                      child: const Text('Xóa tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

          // Total Count bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tìm thấy ${provider.totalElements} sản phẩm',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.fetchProducts(reset: true);
              },
              child: provider.isLoading && provider.products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.products.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.search_off,
                          title: 'Không tìm thấy sản phẩm nào',
                          subtitle: 'Hãy thử tìm kiếm với từ khóa khác hoặc xóa bớt các bộ lọc.',
                          buttonText: 'Xóa bộ lọc',
                          onButtonPressed: () {
                            _searchController.clear();
                            provider.resetFilters();
                          },
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: provider.products.length + (provider.isLoadingMore ? 2 : 0),
                          itemBuilder: (context, index) {
                            if (index >= provider.products.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final product = provider.products[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(productId: product.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
