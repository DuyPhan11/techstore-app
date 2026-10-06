import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../models/branch_model.dart';
import '../../models/brand_model.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../services/product_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/product_image_picker_widget.dart';
import '../../widgets/product_specifications_editor.dart';
import '../product/product_detail_screen.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final int productId;

  const AdminProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _slugController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descController = TextEditingController();
  final _specsEditorController = ProductSpecificationsEditorController();

  ProductModel? _product;
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<BranchModel> _allBranches = [];

  int? _selectedCategoryId;
  int? _selectedBrandId;
  String _status = 'ACTIVE';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _slugController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _imageUrlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        AdminService.getProductForManagement(widget.productId),
        ProductService.getCategories(),
        ProductService.getBrands(),
        ProductService.getBranches(),
      ]);

      final product = results[0] as ProductModel;
      final categories = results[1] as List<CategoryModel>;
      final brands = results[2] as List<BrandModel>;
      final branches = results[3] as List<BranchModel>;

      if (mounted) {
        setState(() {
          _product = product;
          _categories = categories;
          _brands = brands;
          _allBranches = branches;

          _nameController.text = product.name;
          _skuController.text = product.sku;
          _slugController.text = product.slug;
          _priceController.text = product.price.toStringAsFixed(0);
          _costPriceController.text =
              (product.costPrice ?? (product.price * 0.8)).toStringAsFixed(0);
          _imageUrlController.text = product.primaryImageUrl ?? '';
          _descController.text = product.description ?? '';
          _specsEditorController.loadFromRaw(product.specifications);

          _selectedCategoryId = product.category?.id;
          _selectedBrandId = product.brand?.id;
          _status = product.status;

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ToastHelper.showError(context, 'Vui lòng chọn danh mục sản phẩm');
      return;
    }
    if (_selectedBrandId == null) {
      ToastHelper.showError(context, 'Vui lòng chọn thương hiệu sản phẩm');
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;

    if (price <= 0) {
      ToastHelper.showError(context, 'Giá bán phải lớn hơn 0');
      return;
    }
    if (costPrice <= 0) {
      ToastHelper.showError(context, 'Giá vốn phải lớn hơn 0');
      return;
    }

    final imgUrl = _imageUrlController.text.trim();
    final specsJson = _specsEditorController.toJsonString();

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim().toUpperCase(),
      if (_slugController.text.trim().isNotEmpty)
        'slug': _slugController.text.trim(),
      'price': price,
      'costPrice': costPrice,
      'categoryId': _selectedCategoryId,
      'brandId': _selectedBrandId,
      'status': _status,
      'description': _descController.text.trim(),
      'specifications': specsJson,
      if (imgUrl.isNotEmpty)
        'images': [
          {
            'imageUrl': imgUrl,
            'isPrimary': true,
            'displayOrder': 0,
          }
        ],
    };

    setState(() => _isSaving = true);
    try {
      final updated = await AdminService.updateProduct(widget.productId, payload);
      if (mounted) {
        setState(() {
          _product = updated;
          _hasChanges = true;
          _isSaving = false;
        });
        ToastHelper.showSuccess(context, 'Cập nhật sản phẩm thành công!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastHelper.showError(context, 'Lỗi cập nhật: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus = _status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final actionText = newStatus == 'ACTIVE' ? 'mở bán' : 'ẩn khỏi cửa hàng';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận $actionText'),
        content: Text(
          newStatus == 'ACTIVE'
              ? 'Sản phẩm sẽ được hiển thị công khai để khách hàng có thể đặt mua.'
              : 'Sản phẩm sẽ bị ẩn khỏi danh sách tìm kiếm và trang chủ của khách hàng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'ACTIVE' ? AppColors.success : Colors.orange.shade800,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus == 'ACTIVE' ? 'Mở bán' : 'Ẩn sản phẩm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminService.updateProductStatus(widget.productId, status: newStatus);
      if (mounted) {
        setState(() {
          _status = newStatus;
          _hasChanges = true;
        });
        ToastHelper.showSuccess(
          context,
          newStatus == 'ACTIVE' ? 'Đã mở bán lại sản phẩm' : 'Đã ẩn sản phẩm thành công',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi cập nhật trạng thái: $e');
      }
    }
  }

  Future<void> _showAdjustStockDialog(BranchModel branch, int currentStock) async {
    String adjustmentType = 'SET'; // SET, ADD, SUBTRACT
    final qtyController = TextEditingController(text: currentStock.toString());
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Điều chỉnh kho: ${branch.name}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tồn kho hiện tại:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text(
                            '$currentStock sản phẩm',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Hình thức điều chỉnh:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTypeChip('Đặt lại', 'SET', adjustmentType, (v) {
                          setDialogState(() {
                            adjustmentType = v;
                            qtyController.text = currentStock.toString();
                          });
                        }),
                        const SizedBox(width: 6),
                        _buildTypeChip('Nhập thêm (+)', 'ADD', adjustmentType, (v) {
                          setDialogState(() {
                            adjustmentType = v;
                            qtyController.text = '10';
                          });
                        }),
                        const SizedBox(width: 6),
                        _buildTypeChip('Xuất bớt (-)', 'SUBTRACT', adjustmentType, (v) {
                          setDialogState(() {
                            adjustmentType = v;
                            qtyController.text = '1';
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: adjustmentType == 'SET'
                            ? 'Số lượng tồn kho mới'
                            : (adjustmentType == 'ADD' ? 'Số lượng nhập thêm' : 'Số lượng xuất bớt'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Lý do (tùy chọn)',
                        hintText: 'VD: Kiểm kê kho, Hàng mới về...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final qty = int.tryParse(qtyController.text.trim()) ?? -1;
                    if (qty < 0) {
                      if (ctx.mounted) ToastHelper.showError(ctx, 'Số lượng không hợp lệ');
                      return;
                    }
                    if (adjustmentType == 'SUBTRACT' && qty > currentStock) {
                      if (ctx.mounted) ToastHelper.showError(ctx, 'Số lượng xuất bớt không thể lớn hơn tồn hiện có ($currentStock)');
                      return;
                    }

                    try {
                      await AdminService.adjustBranchStock(
                        productId: widget.productId,
                        branchId: branch.id,
                        adjustmentType: adjustmentType,
                        quantity: qty,
                        reason: reasonController.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) ToastHelper.showError(ctx, 'Lỗi điều chỉnh tồn kho: $e');
                    }
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ToastHelper.showSuccess(context, 'Cập nhật tồn kho thành công!');
      _hasChanges = true;
      _loadData(); // Tải lại chi tiết sản phẩm và tồn kho
    }
  }

  Widget _buildTypeChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelect,
  ) {
    final isSelected = value == currentValue;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Trả về true nếu đã có thay đổi để trang cha tự refresh
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chi tiết sản phẩm (Admin)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              if (_product != null)
                Text(
                  'SKU: ${_product!.sku}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            // Preview as Customer Button
            IconButton(
              icon: const Icon(Icons.storefront_outlined, color: AppColors.primary),
              tooltip: 'Xem giao diện khách hàng',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: widget.productId),
                  ),
                );
              },
            ),
            // Quick Save Button
            if (!_isLoading)
              TextButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 16, color: AppColors.primary),
                label: const Text(
                  'Lưu',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _isLoading || _product == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text('Đang lưu thay đổi...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Text(
                            'LƯU CẬP NHẬT SẢN PHẨM',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
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
              const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại'),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final price = double.tryParse(_priceController.text) ?? product.price;
    final costPrice = double.tryParse(_costPriceController.text) ?? (product.costPrice ?? 0);
    final profit = price - costPrice;
    final marginPercent = price > 0 ? (profit / price) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Executive Top Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Primary Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFFF1F5F9),
                          child: _imageUrlController.text.trim().isNotEmpty
                              ? Image.network(
                                  _imageUrlController.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                )
                              : const Icon(Icons.devices, size: 36, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Key details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mã ID: #${product.id} • SKU: ${product.sku}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 8),
                            // Selling status toggle row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _status == 'ACTIVE'
                                        ? AppColors.success.withValues(alpha: 0.12)
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _status == 'ACTIVE' ? 'ĐANG BÁN' : 'ĐÃ ẨN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _status == 'ACTIVE' ? AppColors.success : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _status == 'ACTIVE' ? 'Hiện' : 'Ẩn',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                    ),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: _status == 'ACTIVE',
                                        activeThumbColor: AppColors.success,
                                        onChanged: (_) => _toggleStatus(),
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
                  const Divider(height: 20, thickness: 0.8, color: Color(0xFFF1F5F9)),
                  // Financial Quick Metrics
                  Row(
                    children: [
                      _buildMetricMini('Giá bán', CurrencyHelper.format(price), AppColors.primary),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _buildMetricMini('Giá vốn', CurrencyHelper.format(costPrice), const Color(0xFF64748B)),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _buildMetricMini('Biên lợi nhuận', '${marginPercent.toStringAsFixed(1)}%', const Color(0xFF10B981)),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _buildMetricMini('Tổng tồn kho', '${product.totalStock} sp', const Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Branch Inventories Management Section
            _buildBranchInventoriesSection(product),
            const SizedBox(height: 16),

            // 3. Basic Information Form Card
            _buildSectionCard(
              title: 'Thông tin sản phẩm & Giá bán',
              icon: Icons.edit_note_rounded,
              children: [
                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    hintText: 'Nhập tên sản phẩm',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 12),

                // SKU & Slug
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Mã SKU *',
                          hintText: 'VD: IP15-128-BLK',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập SKU' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug (URL)',
                          hintText: 'tự động tạo',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price & Cost Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Giá bán (VNĐ) *',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixText: '₫',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập giá' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Giá vốn (VNĐ) *',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixText: '₫',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập giá vốn' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category & Brand Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                        validator: (v) => v == null ? 'Chọn danh mục' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedBrandId,
                        decoration: const InputDecoration(
                          labelText: 'Thương hiệu *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedBrandId = val),
                        validator: (v) => v == null ? 'Chọn thương hiệu' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Image Section Card
            _buildSectionCard(
              title: 'Hình ảnh sản phẩm',
              icon: Icons.image_outlined,
              children: [
                ProductImagePickerWidget(
                  imageUrlController: _imageUrlController,
                  onImageChanged: () => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Description & Specifications Section Card
            _buildSectionCard(
              title: 'Mô tả & Thông số kỹ thuật',
              icon: Icons.description_outlined,
              children: [
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết sản phẩm',
                    hintText: 'Nhập thông tin giới thiệu, đặc điểm nổi bật...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ProductSpecificationsEditor(
                  controller: _specsEditorController,
                  initialSpecifications: _product?.specifications,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchInventoriesSection(ProductModel product) {
    // Map branch inventories
    final Map<int, int> branchStockMap = {};
    for (var b in product.branchInventories) {
      branchStockMap[b.branchId] = b.quantity;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.warehouse_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Quản lý tồn kho tại các chi nhánh',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tổng: ${product.totalStock} sp',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_allBranches.isEmpty)
            const Text('Chưa có danh sách chi nhánh trong hệ thống.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allBranches.length,
              separatorBuilder: (_, _) => const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, idx) {
                final branch = _allBranches[idx];
                final currentStock = branchStockMap[branch.id] ?? 0;
                final isOut = currentStock == 0;
                final isLow = currentStock > 0 && currentStock <= 5;
                final statusColor = isOut ? AppColors.danger : (isLow ? Colors.orange.shade800 : AppColors.success);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_mall_directory_outlined, size: 16, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            if (branch.address != null && branch.address!.isNotEmpty)
                              Text(
                                branch.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stock Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isOut ? 'Hết hàng' : '$currentStock sp',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Adjust Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 13),
                        label: const Text('Chỉnh kho', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => _showAdjustStockDialog(branch, currentStock),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricMini(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
