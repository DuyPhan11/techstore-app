import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/brand_model.dart';
import '../../services/admin_service.dart';

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BrandModel> _brands = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'ALL'; // ALL, ACTIVE, INACTIVE

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AdminService.getBrands();
      if (mounted) {
        setState(() {
          _brands = list;
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

  List<BrandModel> get _filteredBrands {
    final query = _searchController.text.trim().toLowerCase();
    return _brands.where((b) {
      final matchesQuery = query.isEmpty ||
          b.name.toLowerCase().contains(query) ||
          b.slug.toLowerCase().contains(query) ||
          (b.description?.toLowerCase().contains(query) ?? false);

      final isBrandActive = b.status == null || b.status == 'ACTIVE';
      if (_statusFilter == 'ACTIVE' && !isBrandActive) return false;
      if (_statusFilter == 'INACTIVE' && isBrandActive) return false;

      return matchesQuery;
    }).toList();
  }

  String _generateSlug(String text) {
    var str = text.toLowerCase().trim();
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'đ'), 'd');
    str = str.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    str = str.replaceAll(RegExp(r'\s+'), '-');
    return str.replaceAll(RegExp(r'-+'), '-');
  }

  void _showBrandFormDialog({BrandModel? brand}) {
    final isEditing = brand != null;
    final nameCtrl = TextEditingController(text: brand?.name ?? '');
    final slugCtrl = TextEditingController(text: brand?.slug ?? '');
    final descCtrl = TextEditingController(text: brand?.description ?? '');
    final logoCtrl = TextEditingController(text: brand?.logoUrl ?? '');
    bool isActive = brand == null || (brand.status == null || brand.status == 'ACTIVE');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Chỉnh sửa thương hiệu' : 'Thêm thương hiệu mới',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(bottomSheetCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Tên thương hiệu
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên thương hiệu *',
                      hintText: 'VD: Apple, Asus, Dell, Sony...',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên thương hiệu';
                      return null;
                    },
                    onChanged: (val) {
                      if (!isEditing || slugCtrl.text.isEmpty) {
                        setModalState(() {
                          slugCtrl.text = _generateSlug(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Đường dẫn slug
                  TextFormField(
                    controller: slugCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Slug (Đường dẫn tĩnh) *',
                      hintText: 'VD: apple, asus, dell',
                      prefixIcon: Icon(Icons.link, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập slug';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Logo URL
                  TextFormField(
                    controller: logoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL Logo thương hiệu',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.image_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả thương hiệu',
                      hintText: 'Thông tin ngắn gọn về thương hiệu...',
                      prefixIcon: Icon(Icons.description_outlined, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isActive ? Icons.check_circle_outline : Icons.visibility_off_outlined,
                              color: isActive ? AppColors.success : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'Đang hoạt động (Hiển thị)' : 'Tạm ẩn (Không hiển thị cho khách)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive ? AppColors.success : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setModalState(() => isActive = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(bottomSheetCtx),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSaving = true);

                                  final payload = {
                                    'name': nameCtrl.text.trim(),
                                    'slug': slugCtrl.text.trim(),
                                    'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                    'logoUrl': logoCtrl.text.trim().isEmpty ? null : logoCtrl.text.trim(),
                                    'status': isActive ? 'ACTIVE' : 'INACTIVE',
                                  };

                                  try {
                                    if (isEditing) {
                                      await AdminService.updateBrand(brand.id, payload);
                                    } else {
                                      await AdminService.createBrand(payload);
                                    }

                                    if (bottomSheetCtx.mounted) {
                                      Navigator.pop(bottomSheetCtx);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing
                                              ? 'Cập nhật thương hiệu thành công'
                                              : 'Thêm thương hiệu mới thành công'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      _fetchBrands();
                                    }
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEditing ? 'Lưu thay đổi' : 'Tạo thương hiệu',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBrandStatus(BrandModel brand) async {
    final isCurrentlyActive = brand.status == null || brand.status == 'ACTIVE';
    final actionText = isCurrentlyActive ? 'ẩn' : 'mở lại';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionText thương hiệu'),
        content: Text(isCurrentlyActive
            ? 'Khi ẩn thương hiệu "${brand.name}", khách hàng sẽ không thấy thương hiệu này trong danh sách lọc mua sắm. Bạn có muốn tiếp tục?'
            : 'Bạn có muốn mở hoạt động lại cho thương hiệu "${brand.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? Colors.orange.shade800 : AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCurrentlyActive ? 'Ẩn thương hiệu' : 'Mở lại', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isCurrentlyActive) {
          // Soft delete sets status to INACTIVE
          await AdminService.deleteBrand(brand.id);
        } else {
          // Activate by updating status
          await AdminService.updateBrand(brand.id, {
            'name': brand.name,
            'slug': brand.slug,
            'description': brand.description,
            'logoUrl': brand.logoUrl,
            'status': 'ACTIVE',
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã $actionText thương hiệu "${brand.name}" thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchBrands();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thao tác thất bại: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBrands;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Quản lý Thương hiệu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchBrands,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBrandFormDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm thương hiệu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, slug hoặc mô tả...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFilterChip('Tất cả (${_brands.length})', 'ALL'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Đang hoạt động (${_brands.where((b) => b.status == null || b.status == 'ACTIVE').length})',
                      'ACTIVE',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Tạm ẩn (${_brands.where((b) => b.status == 'INACTIVE').length})',
                      'INACTIVE',
                      color: Colors.orange.shade800,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Result Count Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Text(
              'Hiển thị ${filtered.length} thương hiệu',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),

          // Main list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchBrands, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Không tìm thấy thương hiệu nào',
                                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm thương hiệu mới'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  onPressed: () => _showBrandFormDialog(),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchBrands,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final brand = filtered[index];
                                final isActive = brand.status == null || brand.status == 'ACTIVE';

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isActive ? const Color(0xFFE2E8F0) : Colors.orange.shade200,
                                    ),
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Brand Logo
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            color: const Color(0xFFF1F5F9),
                                            child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                                                ? Image.network(
                                                    brand.logoUrl!,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, _, _) => const Icon(
                                                      Icons.business_outlined,
                                                      color: AppColors.primary,
                                                      size: 26,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.business_outlined,
                                                    color: AppColors.primary,
                                                    size: 26,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Brand Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      brand.name,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade600,
                                                        decoration: isActive ? null : TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  ),
                                                  // Status Badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? AppColors.success.withValues(alpha: 0.12)
                                                          : Colors.orange.shade100,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      isActive ? 'Hoạt động' : 'Tạm ẩn',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isActive ? AppColors.success : Colors.orange.shade900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'slug: ${brand.slug}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                                                ),
                                              ),
                                              if (brand.description != null && brand.description!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  brand.description!,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                              const SizedBox(height: 4),

                                              // Actions Row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    icon: const Icon(Icons.edit_outlined, size: 15),
                                                    label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                                                    style: TextButton.styleFrom(
                                                      visualDensity: VisualDensity.compact,
                                                      foregroundColor: AppColors.primary,
                                                    ),
                                                    onPressed: () => _showBrandFormDialog(brand: brand),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  TextButton.icon(
                                                    icon: Icon(
                                                      isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                      size: 15,
                                                      color: isActive ? Colors.orange.shade800 : AppColors.success,
                                                    ),
                                                    label: Text(
                                                      isActive ? 'Ẩn' : 'Mở lại',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isActive ? Colors.orange.shade800 : AppColors.success,
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                                    onPressed: () => _toggleBrandStatus(brand),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _statusFilter == value;
    final primaryColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
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
}
