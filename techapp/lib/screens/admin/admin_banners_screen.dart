import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/banner_model.dart';
import '../../models/product_model.dart';
import '../../services/banner_service.dart';
import '../../services/product_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_banner_card.dart';
import '../../widgets/safe_network_image.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  bool _isLoading = true;
  List<BannerModel> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final list = await BannerService.getAllBanners();
      if (mounted) {
        setState(() {
          _banners = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(context, 'Lỗi tải danh sách banner: $e');
      }
    }
  }

  Future<void> _handleToggleStatus(BannerModel banner, bool newStatus) async {
    try {
      final updated = await BannerService.toggleStatus(banner.id, newStatus);
      if (mounted) {
        setState(() {
          final idx = _banners.indexWhere((b) => b.id == banner.id);
          if (idx != -1) _banners[idx] = updated;
        });
        ToastHelper.showSuccess(
          context,
          newStatus ? 'Đã kích hoạt hiển thị banner' : 'Đã ẩn banner khỏi trang chủ',
        );
      }
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Thao tác thất bại: $e');
    }
  }

  Future<void> _handleDeleteBanner(BannerModel banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Xóa Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa banner "${banner.title.replaceAll('\n', ' ')}"?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await BannerService.deleteBanner(banner.id);
      if (mounted) {
        setState(() {
          _banners.removeWhere((b) => b.id == banner.id);
        });
        ToastHelper.showSuccess(context, 'Đã xóa banner thành công');
      }
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Xóa thất bại: $e');
    }
  }

  void _openBannerForm({BannerModel? banner}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BannerFormBottomSheet(
        banner: banner,
        onSaved: _loadBanners,
      ),
    );
  }

  Future<void> _seedDefaults() async {
    try {
      await BannerService.seedDefaultBanners();
      await _loadBanners();
      if (mounted) ToastHelper.showSuccess(context, 'Đã tạo lại các mẫu banner mặc định!');
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _banners.where((b) => b.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý Banner Quảng Cáo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            Text(
              'Tùy biến banner & slider trang chủ',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadBanners,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'seed') _seedDefaults();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: Color(0xFF4F46E5)),
                    SizedBox(width: 8),
                    Text('Tải lại các mẫu mặc định'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBannerForm(),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Banner Mới', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBanners,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Top Stats Overview Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.view_carousel_rounded, color: Color(0xFF4F46E5), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Slider Trang Chủ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tất cả banner bật sẽ tự động chạy luân phiên trên Trang Chủ',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$activeCount / ${_banners.length} Đang chạy',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                ),
              )
            else if (_banners.isEmpty)
              EmptyStateWidget(
                icon: Icons.view_carousel_outlined,
                title: 'Chưa có banner nào',
                subtitle: 'Hãy bấm nút bên dưới để tạo banner mới hoặc khôi phục các mẫu banner mặc định.',
                buttonText: 'Tạo banner mới',
                onButtonPressed: () => _openBannerForm(),
              )
            else
              ..._banners.map((b) => _buildBannerAdminItem(b)),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAdminItem(BannerModel banner) {
    String linkDescription = 'Không liên kết';
    if (banner.linkType == 'COUPON') {
      linkDescription = 'Mã Voucher: ${banner.linkValue ?? 'Kho Voucher'}';
    } else if (banner.linkType == 'PRODUCT') {
      linkDescription = 'Chi tiết Sản phẩm ID: ${banner.linkValue ?? '--'}';
    } else if (banner.linkType == 'CATEGORY') {
      linkDescription = 'Chuyển sang Trang Danh mục';
    }

    final hasImage = banner.imageUrl != null && banner.imageUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: banner.isActive ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: banner.isActive ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Visual Card Preview
          Padding(
            padding: const EdgeInsets.all(12),
            child: PromoBannerCard(banner: banner),
          ),

          // Action and metadata row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Info badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Thứ tự: ${banner.displayOrder}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: banner.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              banner.isActive ? 'Đang hiển thị' : 'Đang ẩn',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: banner.isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (hasImage)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image_outlined, size: 11, color: Color(0xFF2563EB)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Có ảnh SP',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            banner.linkType == 'PRODUCT'
                                ? Icons.shopping_bag_outlined
                                : (banner.linkType == 'COUPON' ? Icons.local_offer_outlined : Icons.link_rounded),
                            size: 14,
                            color: const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              linkDescription,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Switch Bật/Tắt (thu nhỏ gọn gàng chống tràn)
                Transform.scale(
                  scale: 0.82,
                  child: Switch.adaptive(
                    value: banner.isActive,
                    activeTrackColor: const Color(0xFF16A34A),
                    onChanged: (val) => _handleToggleStatus(banner, val),
                  ),
                ),

                const SizedBox(width: 8),
                // Nút Sửa
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0F172A)),
                  tooltip: 'Chỉnh sửa',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openBannerForm(banner: banner),
                ),

                const SizedBox(width: 4),
                // Nút Xóa
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Xóa banner',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleDeleteBanner(banner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORM BOTTOM SHEET TẠO / SỬA BANNER
// CÓ CHỌN SẢN PHẨM TRỰC QUAN & LIVE PREVIEW
// ==========================================
class _BannerFormBottomSheet extends StatefulWidget {
  final BannerModel? banner;
  final VoidCallback onSaved;

  const _BannerFormBottomSheet({
    this.banner,
    required this.onSaved,
  });

  @override
  State<_BannerFormBottomSheet> createState() => _BannerFormBottomSheetState();
}

class _BannerFormBottomSheetState extends State<_BannerFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _badge1Ctrl;
  late TextEditingController _badge2Ctrl;
  late TextEditingController _titleColorCtrl;
  late TextEditingController _bgColorCtrl;
  late TextEditingController _gradientEndCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _linkValueCtrl;
  late TextEditingController _orderCtrl;

  late String _iconName;
  late String _linkType;
  late bool _isActive;

  ProductModel? _selectedProduct;
  bool _isLoadingProduct = false;
  bool _isSaving = false;

  // Bảng màu gradient thịnh hành
  final List<Map<String, dynamic>> _colorPalettes = [
    {
      'name': 'Tím Cyber',
      'bg': '#581C87',
      'end': '#3B0764',
      'title': '#FFEB3B',
    },
    {
      'name': 'Titan Đen',
      'bg': '#0F172A',
      'end': '#1E293B',
      'title': '#38BDF8',
    },
    {
      'name': 'Đỏ Sale',
      'bg': '#DC2626',
      'end': '#991B1B',
      'title': '#FFFFFF',
    },
    {
      'name': 'Xanh Indigo',
      'bg': '#4F46E5',
      'end': '#3730A3',
      'title': '#FFFFFF',
    },
    {
      'name': 'Xanh Lá Eco',
      'bg': '#059669',
      'end': '#065F46',
      'title': '#FFFFFF',
    },
    {
      'name': 'Cam Rực Rỡ',
      'bg': '#EA580C',
      'end': '#9A3412',
      'title': '#FEF08A',
    },
    {
      'name': 'Đen Hoàng Gia',
      'bg': '#18181B',
      'end': '#09090B',
      'title': '#FBBF24',
    },
    {
      'name': 'Cyan Biển',
      'bg': '#0284C7',
      'end': '#0369A1',
      'title': '#FFFFFF',
    },
  ];

  // Danh sách các mẫu Template có sẵn để Admin bấm chọn nhanh!
  final List<Map<String, dynamic>> _presetTemplates = [
    {
      'name': 'Flagship iPhone 15 Pro (Titan Đen)',
      'title': 'FLAGSHIP\nIPHONE 15 PRO',
      'subtitle': 'Titan Tự Nhiên - Trả góp 0% lãi suất ngay hôm nay',
      'badge1': 'MỚI 2026',
      'badge2': 'TRẢ GÓP 0%',
      'titleColor': '#38BDF8',
      'bgColor': '#0F172A',
      'gradientEnd': '#1E293B',
      'iconName': 'phone_iphone',
      'imageUrl': 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500',
      'linkType': 'PRODUCT',
      'linkValue': '1',
    },
    {
      'name': 'Laptop Pro Hiệu Năng (Indigo)',
      'title': 'LAPTOP PRO\nHIỆU NĂNG ĐỈNH CAO',
      'subtitle': 'Tặng kèm chuột không dây & balo thời trang',
      'badge1': 'QUÀ 1.500K',
      'badge2': 'BẢO HÀNH 2 NĂM',
      'titleColor': '#FFFFFF',
      'bgColor': '#4F46E5',
      'gradientEnd': '#3730A3',
      'iconName': 'laptop',
      'imageUrl': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500',
      'linkType': 'PRODUCT',
      'linkValue': '2',
    },
    {
      'name': 'Cyber TechStore (Tím Neon - Vàng)',
      'title': 'CYBER\nTECHSTORE',
      'subtitle': 'cho thiết bị công nghệ & phụ kiện thông minh',
      'badge1': 'GIẢM 40%',
      'badge2': 'FREESHIP',
      'titleColor': '#FFEB3B',
      'bgColor': '#581C87',
      'gradientEnd': '#3B0764',
      'iconName': 'devices_other',
      'imageUrl': 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=500',
      'linkType': 'CATEGORY',
      'linkValue': '',
    },
    {
      'name': 'Siêu Sale Bùng Nổ (Đỏ Cam Rực)',
      'title': 'SIÊU SALE\nƯU ĐÃI KHỦNG',
      'subtitle': 'Nhập mã TECH10 giảm ngay 10% đơn hàng bất kỳ',
      'badge1': 'VOUCHER 10%',
      'badge2': 'HOT DEAL',
      'titleColor': '#FFFFFF',
      'bgColor': '#DC2626',
      'gradientEnd': '#991B1B',
      'iconName': 'bolt',
      'imageUrl': 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=500',
      'linkType': 'COUPON',
      'linkValue': 'TECH10',
    },
    {
      'name': 'Kho Voucher Tri Ân (Xanh Dương)',
      'title': 'KHO VOUCHER\nTRI ÂN KHÁCH HÀNG',
      'subtitle': 'Thu thập hàng ngàn mã giảm giá độc quyền',
      'badge1': 'GIẢM 500K',
      'badge2': 'HOÀN TIỀN',
      'titleColor': '#FDE047',
      'bgColor': '#1D4ED8',
      'gradientEnd': '#1E40AF',
      'iconName': 'local_offer',
      'imageUrl': '',
      'linkType': 'COUPON',
      'linkValue': '',
    },
    {
      'name': 'Freeship 0Đ Toàn Quốc (Xanh Lá Eco)',
      'title': 'FREESHIP 0Đ\nTOÀN QUỐC',
      'subtitle': 'Giao hỏa tốc 2H - Miễn phí vận chuyển cho đơn từ 5 triệu',
      'badge1': 'GIAO 2H',
      'badge2': '0Đ PHÍ SHIP',
      'titleColor': '#FFFFFF',
      'bgColor': '#059669',
      'gradientEnd': '#065F46',
      'iconName': 'local_shipping',
      'imageUrl': '',
      'linkType': 'NONE',
      'linkValue': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? 'CYBER\nTECHSTORE');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? 'cho thiết bị công nghệ & phụ kiện thông minh');
    _badge1Ctrl = TextEditingController(text: b?.badgeText1 ?? 'GIẢM 40%');
    _badge2Ctrl = TextEditingController(text: b?.badgeText2 ?? 'FREESHIP');
    _titleColorCtrl = TextEditingController(text: b?.titleColor ?? '#FFEB3B');
    _bgColorCtrl = TextEditingController(text: b?.backgroundColor ?? '#581C87');
    _gradientEndCtrl = TextEditingController(text: b?.backgroundGradientEnd ?? '#3B0764');
    _imageUrlCtrl = TextEditingController(text: b?.imageUrl ?? '');
    _linkValueCtrl = TextEditingController(text: b?.linkValue ?? '');
    _orderCtrl = TextEditingController(text: b != null ? '${b.displayOrder}' : '1');

    _iconName = b?.iconName ?? 'devices_other';
    _linkType = b?.linkType ?? 'CATEGORY';
    _isActive = b?.isActive ?? true;

    if (_linkType == 'PRODUCT' && _linkValueCtrl.text.isNotEmpty) {
      _loadInitialProduct(_linkValueCtrl.text);
    }
  }

  Future<void> _loadInitialProduct(String linkVal) async {
    final prodId = int.tryParse(linkVal.trim());
    if (prodId == null) return;
    setState(() => _isLoadingProduct = true);
    try {
      final p = await ProductService.getProductById(prodId);
      if (mounted) {
        setState(() {
          _selectedProduct = p;
          _isLoadingProduct = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _badge1Ctrl.dispose();
    _badge2Ctrl.dispose();
    _titleColorCtrl.dispose();
    _bgColorCtrl.dispose();
    _gradientEndCtrl.dispose();
    _imageUrlCtrl.dispose();
    _linkValueCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> t) {
    setState(() {
      _titleCtrl.text = t['title'];
      _subtitleCtrl.text = t['subtitle'];
      _badge1Ctrl.text = t['badge1'];
      _badge2Ctrl.text = t['badge2'];
      _titleColorCtrl.text = t['titleColor'];
      _bgColorCtrl.text = t['bgColor'];
      _gradientEndCtrl.text = t['gradientEnd'];
      _iconName = t['iconName'];
      _imageUrlCtrl.text = t['imageUrl'] ?? '';
      _linkType = t['linkType'];
      _linkValueCtrl.text = t['linkValue'];
      _selectedProduct = null;
    });
    if (_linkType == 'PRODUCT' && _linkValueCtrl.text.isNotEmpty) {
      _loadInitialProduct(_linkValueCtrl.text);
    }
    ToastHelper.showSuccess(context, 'Đã áp dụng mẫu "${t['name']}"');
  }

  void _applyColorPalette(Map<String, dynamic> p) {
    setState(() {
      _bgColorCtrl.text = p['bg'];
      _gradientEndCtrl.text = p['end'];
      _titleColorCtrl.text = p['title'];
    });
    ToastHelper.showSuccess(context, 'Đã đổi tông màu "${p['name']}"');
  }

  void _openProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(
        onSelectProduct: (product) {
          setState(() {
            _selectedProduct = product;
            _linkType = 'PRODUCT';
            _linkValueCtrl.text = product.id.toString();
            if (product.primaryImageUrl != null && product.primaryImageUrl!.isNotEmpty) {
              _imageUrlCtrl.text = product.primaryImageUrl!;
            }
          });
          ToastHelper.showSuccess(context, 'Đã chọn sản phẩm: ${product.name}');
        },
      ),
    );
  }

  void _applyProductDetailsToBanner() {
    if (_selectedProduct == null) return;
    setState(() {
      _titleCtrl.text = _selectedProduct!.name;
      _badge1Ctrl.text = CurrencyHelper.format(_selectedProduct!.price);
      _badge2Ctrl.text = _selectedProduct!.brand != null ? _selectedProduct!.brand!.name.toUpperCase() : 'HOT DEAL';
      _subtitleCtrl.text = 'Chính hãng - Bảo hành ${_selectedProduct!.warrantyMonths} tháng tại TechStore';
      if (_selectedProduct!.primaryImageUrl != null && _selectedProduct!.primaryImageUrl!.isNotEmpty) {
        _imageUrlCtrl.text = _selectedProduct!.primaryImageUrl!;
      }
    });
    ToastHelper.showSuccess(context, 'Đã tự động điền thông tin sản phẩm vào banner!');
  }

  void _clearSelectedProduct() {
    setState(() {
      _selectedProduct = null;
      _linkValueCtrl.clear();
      _linkType = 'NONE';
    });
  }

  BannerModel _buildPreviewModel() {
    return BannerModel(
      id: widget.banner?.id ?? 0,
      title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'TIÊU ĐỀ BANNER',
      subtitle: _subtitleCtrl.text.isNotEmpty ? _subtitleCtrl.text : null,
      badgeText1: _badge1Ctrl.text.isNotEmpty ? _badge1Ctrl.text : null,
      badgeText2: _badge2Ctrl.text.isNotEmpty ? _badge2Ctrl.text : null,
      titleColor: _titleColorCtrl.text.isNotEmpty ? _titleColorCtrl.text : '#FFEB3B',
      backgroundColor: _bgColorCtrl.text.isNotEmpty ? _bgColorCtrl.text : '#581C87',
      backgroundGradientEnd: _gradientEndCtrl.text.isNotEmpty ? _gradientEndCtrl.text : null,
      iconName: _iconName,
      imageUrl: _imageUrlCtrl.text.trim().isNotEmpty ? _imageUrlCtrl.text.trim() : null,
      linkType: _linkType,
      linkValue: _linkValueCtrl.text,
      displayOrder: int.tryParse(_orderCtrl.text) ?? 1,
      isActive: _isActive,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final body = {
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'badgeText1': _badge1Ctrl.text.trim(),
        'badgeText2': _badge2Ctrl.text.trim(),
        'titleColor': _titleColorCtrl.text.trim(),
        'backgroundColor': _bgColorCtrl.text.trim(),
        'backgroundGradientEnd': _gradientEndCtrl.text.trim().isNotEmpty ? _gradientEndCtrl.text.trim() : null,
        'iconName': _iconName,
        'imageUrl': _imageUrlCtrl.text.trim().isNotEmpty ? _imageUrlCtrl.text.trim() : null,
        'linkType': _linkType,
        'linkValue': _linkValueCtrl.text.trim().isNotEmpty ? _linkValueCtrl.text.trim() : null,
        'displayOrder': int.tryParse(_orderCtrl.text.trim()) ?? 1,
        'isActive': _isActive,
      };

      if (widget.banner == null) {
        await BannerService.createBanner(body);
        if (mounted) ToastHelper.showSuccess(context, 'Đã tạo banner mới thành công!');
      } else {
        await BannerService.updateBanner(widget.banner!.id, body);
        if (mounted) ToastHelper.showSuccess(context, 'Đã cập nhật banner thành công!');
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Lỗi lưu banner: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.banner != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit : Icons.add_to_photos,
                  color: const Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEdit ? 'Chỉnh Sửa Banner' : 'Tạo Banner Quảng Cáo Mới',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 16),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 1. CHỌN MẪU CÓ SẴN (PRESET TEMPLATES)
                  Row(
                    children: const [
                      Icon(Icons.palette_outlined, size: 16, color: Color(0xFF4F46E5)),
                      SizedBox(width: 6),
                      Text(
                        'Chọn nhanh mẫu có sẵn (Template)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetTemplates.length,
                      itemBuilder: (ctx, idx) {
                        final t = _presetTemplates[idx];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(int.parse('FF${t['bgColor'].replaceAll('#', '')}', radix: 16)),
                            ),
                            label: Text(t['name']),
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () => _applyTemplate(t),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. PHỐI MÀU THỊNH HÀNH (COLOR PALETTES)
                  Row(
                    children: const [
                      Icon(Icons.color_lens_outlined, size: 16, color: Color(0xFFEA580C)),
                      SizedBox(width: 6),
                      Text(
                        'Tông màu thịnh hành',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorPalettes.length,
                      itemBuilder: (ctx, idx) {
                        final p = _colorPalettes[idx];
                        final cBg = Color(int.parse('FF${p['bg'].replaceAll('#', '')}', radix: 16));
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: cBg),
                            ),
                            label: Text(p['name']),
                            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () => _applyColorPalette(p),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. LIVE PREVIEW (XEM TRƯỚC TRỰC TIẾP)
                  Row(
                    children: const [
                      Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text(
                        'Xem trước trực tiếp (Live Preview)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PromoBannerCard(banner: _buildPreviewModel()),
                  const SizedBox(height: 20),

                  // 4. CHỌN SẢN PHẨM LIÊN KẾT (TRỰC QUAN CHO ADMIN)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Sản phẩm liên kết & Ảnh đại diện Banner',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openProductPicker,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.search, size: 15),
                              label: const Text('Chọn sản phẩm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        // Card hiển thị sản phẩm đã chọn
                        if (_selectedProduct != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SafeNetworkImage(
                                          imageUrl: _selectedProduct!.primaryImageUrl,
                                          fit: BoxFit.contain,
                                          fallbackIconSize: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedProduct!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                CurrencyHelper.format(_selectedProduct!.price),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Color(0xFFFF5400),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ID: ${_selectedProduct!.id}',
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                                      tooltip: 'Gỡ liên kết',
                                      onPressed: _clearSelectedProduct,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _applyProductDetailsToBanner,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.auto_fix_high_rounded, size: 15, color: Color(0xFF2563EB)),
                                    label: const Text(
                                      'Tự động điền tiêu đề & giá vào banner',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_isLoadingProduct) ...[
                          const SizedBox(height: 10),
                          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. HÌNH ẢNH BANNER (IMAGE URL)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrlCtrl,
                          decoration: InputDecoration(
                            labelText: 'Link ảnh sản phẩm / Banner (Image URL)',
                            hintText: 'https://...',
                            prefixIcon: const Icon(Icons.image_outlined, size: 20),
                            suffixIcon: _imageUrlCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _imageUrlCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_imageUrlCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFF1F5F9),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SafeNetworkImage(
                              imageUrl: _imageUrlCtrl.text.trim(),
                              fit: BoxFit.contain,
                              fallbackIconSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. TIÊU ĐỀ & PHỤ ĐỀ
                  TextFormField(
                    controller: _titleCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề banner * (Dùng \\n để xuống dòng)',
                      hintText: 'VD: CYBER\\nTECHSTORE',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _subtitleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mô tả phụ (Subtitle)',
                      hintText: 'VD: cho thiết bị công nghệ & phụ kiện thông minh',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 7. BADGES
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _badge1Ctrl,
                          decoration: InputDecoration(
                            labelText: 'Badge 1 (Ví dụ: GIẢM 40%)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _badge2Ctrl,
                          decoration: InputDecoration(
                            labelText: 'Badge 2 (Ví dụ: FREESHIP)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 8. MÀU NỀN & MÀU CHỮ (HEX CODE)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bgColorCtrl,
                          decoration: InputDecoration(
                            labelText: 'Màu nền chính (Hex)',
                            hintText: '#581C87',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _gradientEndCtrl,
                          decoration: InputDecoration(
                            labelText: 'Màu Gradient kết thúc',
                            hintText: '#3B0764',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _titleColorCtrl,
                    decoration: InputDecoration(
                      labelText: 'Màu chữ tiêu đề (Hex)',
                      hintText: '#FFEB3B',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 9. CHỌN ICON MINH HỌA (KHI KHÔNG CÓ ẢNH SẢN PHẨM)
                  const Text(
                    'Icon minh họa (Hiển thị khi banner không có ảnh sản phẩm) *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'devices_other',
                      'phone_iphone',
                      'laptop',
                      'headphones',
                      'watch',
                      'bolt',
                      'local_offer',
                      'local_shipping',
                      'card_giftcard',
                      'star',
                    ].map((name) {
                      final isSelected = _iconName == name;
                      return ChoiceChip(
                        avatar: Icon(
                          BannerModel(
                            id: 0,
                            title: '',
                            titleColor: '',
                            backgroundColor: '',
                            iconName: name,
                            linkType: '',
                            displayOrder: 0,
                            isActive: true,
                          ).parsedIcon,
                          size: 16,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        label: Text(name),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _iconName = name);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 10. LOẠI HÀNH ĐỘNG LIÊN KẾT (LINK TYPE)
                  const Text(
                    'Hành động khi khách bấm vào banner *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_linkType),
                    initialValue: _linkType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('Không liên kết (Mặc định)')),
                      DropdownMenuItem(value: 'PRODUCT', child: Text('Mở trang chi tiết Sản phẩm')),
                      DropdownMenuItem(value: 'COUPON', child: Text('Mã giảm giá / Kho Voucher')),
                      DropdownMenuItem(value: 'CATEGORY', child: Text('Mở Danh mục sản phẩm')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _linkType = val);
                        if (val == 'PRODUCT' && _selectedProduct == null) {
                          _openProductPicker();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_linkType != 'NONE') ...[
                    TextFormField(
                      controller: _linkValueCtrl,
                      decoration: InputDecoration(
                        labelText: _linkType == 'COUPON'
                            ? 'Mã Voucher liên kết (VD: TECH10)'
                            : (_linkType == 'PRODUCT' ? 'ID Sản phẩm (VD: 1)' : 'Mã danh mục'),
                        hintText: _linkType == 'COUPON' ? 'Để trống nếu muốn mở Kho Voucher' : 'Nhập giá trị',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        if (_linkType == 'PRODUCT' && val.isNotEmpty) {
                          _loadInitialProduct(val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 11. THỨ TỰ HIỂN THỊ & KÍCH HOẠT
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _orderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Thứ tự ưu tiên',
                            hintText: '1, 2, 3...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kích hoạt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Switch.adaptive(
                                value: _isActive,
                                activeTrackColor: const Color(0xFF16A34A),
                                onChanged: (val) => setState(() => _isActive = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút Lưu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isEdit ? 'CẬP NHẬT BANNER' : 'TẠO BANNER MỚI',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL BOTTOM SHEET CHỌN SẢN PHẨM TRỰC QUAN
// TÌM KIẾM THEO TÊN, XEM HÌNH ẢNH & GIÁ TIỀN
// ==========================================
class _ProductPickerSheet extends StatefulWidget {
  final Function(ProductModel) onSelectProduct;

  const _ProductPickerSheet({required this.onSelectProduct});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String _keyword = '';
  Timer? _debounce;

  // Tiêu chí sắp xếp: Mặc định sắp xếp sản phẩm mới nhất lên đầu!
  String _sortBy = 'createdAt';
  String _sortDir = 'desc';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final pageResult = await ProductService.getProducts(
        page: 0,
        size: 50,
        keyword: _keyword.isNotEmpty ? _keyword : null,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      if (mounted) {
        setState(() {
          _products = pageResult.content;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _keyword = val.trim());
      _fetchProducts();
    });
  }

  Widget _buildSortChip(String label, String sortBy, String sortDir, IconData icon) {
    final isSelected = _sortBy == sortBy && _sortDir == sortDir;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (isSelected) return;
        setState(() {
          _sortBy = sortBy;
          _sortDir = sortDir;
        });
        _fetchProducts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Drag handle
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
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn Sản Phẩm Cho Banner',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Mặc định sản phẩm mới nhất xếp lên đầu',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, hãng sản phẩm...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Sorting Filter Chips Bar (Sắp xếp sản phẩm mới nhất lên đầu)
          Row(
            children: [
              const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              const Text(
                'Sắp xếp:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Mới nhất', 'createdAt', 'desc', Icons.auto_awesome),
                      const SizedBox(width: 6),
                      _buildSortChip('Giá cao', 'price', 'desc', Icons.arrow_downward_rounded),
                      const SizedBox(width: 6),
                      _buildSortChip('Giá thấp', 'price', 'asc', Icons.arrow_upward_rounded),
                      const SizedBox(width: 6),
                      _buildSortChip('Tên A-Z', 'name', 'asc', Icons.sort_by_alpha_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              _keyword.isEmpty ? 'Không có sản phẩm nào' : 'Không tìm thấy "$_keyword"',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final product = _products[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SafeNetworkImage(
                                  imageUrl: product.primaryImageUrl,
                                  fit: BoxFit.contain,
                                  fallbackIconSize: 24,
                                ),
                              ),
                            ),
                            title: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Text(
                                    CurrencyHelper.format(product.price),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFFF5400),
                                    ),
                                  ),
                                  if (product.brand != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.brand!.name,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                            onTap: () {
                              widget.onSelectProduct(product);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
