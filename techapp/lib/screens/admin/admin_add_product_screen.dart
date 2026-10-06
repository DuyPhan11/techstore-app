import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../models/brand_model.dart';
import '../../models/branch_model.dart';
import '../../models/category_model.dart';
import '../../services/admin_service.dart';
import '../../services/product_service.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/product_image_picker_widget.dart';
import '../../widgets/product_specifications_editor.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _initialStockController = TextEditingController(text: '10');
  final _descController = TextEditingController();
  final _specsEditorController = ProductSpecificationsEditorController();

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<BranchModel> _branches = [];

  int? _selectedCategoryId;
  int? _selectedBrandId;
  int? _selectedBranchId;

  bool _isLoadingInitialData = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _imageUrlController.dispose();
    _initialStockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoadingInitialData = true);
    try {
      final results = await Future.wait([
        ProductService.getCategories(),
        ProductService.getBrands(),
        ProductService.getBranches(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _brands = results[1] as List<BrandModel>;
          _branches = results[2] as List<BranchModel>;

          if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
          if (_brands.isNotEmpty) _selectedBrandId = _brands.first.id;
          if (_branches.isNotEmpty) _selectedBranchId = _branches.first.id;

          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInitialData = false);
        ToastHelper.showError(context, 'Lỗi tải danh mục / chi nhánh: $e');
      }
    }
  }

  Future<void> _submit() async {
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
    final initialStock = int.tryParse(_initialStockController.text.trim()) ?? 0;
    final specsJson = _specsEditorController.toJsonString();

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim().toUpperCase(),
      'price': price,
      'costPrice': costPrice,
      'categoryId': _selectedCategoryId,
      'brandId': _selectedBrandId,
      'status': 'ACTIVE',
      if (_descController.text.trim().isNotEmpty)
        'description': _descController.text.trim(),
      if (specsJson.isNotEmpty)
        'specifications': specsJson,
      if (imgUrl.isNotEmpty)
        'images': [
          {
            'imageUrl': imgUrl,
            'isPrimary': true,
            'displayOrder': 0,
          }
        ],
      if (_selectedBranchId != null && initialStock > 0) ...{
        'initialBranchId': _selectedBranchId,
        'initialStock': initialStock,
      },
    };

    setState(() => _isSubmitting = true);
    try {
      await AdminService.createProduct(payload);
      if (mounted) {
        ToastHelper.showSuccess(context, 'Thêm sản phẩm "${_nameController.text.trim()}" thành công!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi tạo sản phẩm: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Thêm sản phẩm mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 1,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingInitialData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Thông tin cơ bản',
                      icon: Icons.inventory_2_outlined,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên sản phẩm *',
                            hintText: 'Ví dụ: Laptop Dell XPS 15 9530',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _skuController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Mã SKU *',
                                  hintText: 'DELL-XPS-15',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập SKU' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'Giá bán (VNĐ) *',
                                  hintText: '45000000',
                                  suffixText: '₫',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập giá bán' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _costPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'Giá vốn (VNĐ) *',
                                  hintText: '38000000',
                                  suffixText: '₫',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập giá vốn' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Phân loại',
                      icon: Icons.category_outlined,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(labelText: 'Danh mục sản phẩm *'),
                          items: _categories.map((c) {
                            return DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBrandId,
                          decoration: const InputDecoration(labelText: 'Thương hiệu *'),
                          items: _brands.map((b) {
                            return DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.name),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedBrandId = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Tồn kho ban đầu theo chi nhánh',
                      icon: Icons.storefront_outlined,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBranchId,
                          decoration: const InputDecoration(labelText: 'Chọn chi nhánh nhập kho'),
                          items: _branches.map((b) {
                            return DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.name),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedBranchId = val),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _initialStockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Số lượng tồn kho ban đầu',
                            hintText: 'Ví dụ: 20',
                            suffixText: 'sản phẩm',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sản phẩm sẽ được khởi tạo số lượng tồn ngay tại chi nhánh đã chọn.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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

                    _buildSectionCard(
                      title: 'Mô tả & Thông số kỹ thuật',
                      icon: Icons.description_outlined,
                      children: [
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả sản phẩm',
                            hintText: 'Thông tin chi tiết về sản phẩm...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ProductSpecificationsEditor(
                          controller: _specsEditorController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_circle_outline),
                        label: Text(
                          _isSubmitting ? 'Đang tạo sản phẩm...' : 'Hoàn tất & Thêm sản phẩm',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }
}
