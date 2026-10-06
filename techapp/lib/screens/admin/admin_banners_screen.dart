import 'package:flutter/material.dart';
import '../../models/banner_model.dart';
import '../../services/banner_service.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_banner_card.dart';

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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Thứ tự: ${banner.displayOrder}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: banner.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              banner.isActive ? 'Đang hiển thị' : 'Đang ẩn',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: banner.isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 14, color: Color(0xFF4F46E5)),
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

                // Switch Bật/Tắt
                Switch.adaptive(
                  value: banner.isActive,
                  activeTrackColor: const Color(0xFF16A34A),
                  onChanged: (val) => _handleToggleStatus(banner, val),
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
// CÓ SẴN CÁC MẪU TEMPLATE & LIVE PREVIEW
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
  late TextEditingController _linkValueCtrl;
  late TextEditingController _orderCtrl;

  late String _iconName;
  late String _linkType;
  late bool _isActive;

  bool _isSaving = false;

  // Danh sách các mẫu Template có sẵn để Admin bấm chọn nhanh!
  final List<Map<String, dynamic>> _presetTemplates = [
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
      'linkType': 'COUPON',
      'linkValue': 'TECH10',
    },
    {
      'name': 'Kho Voucher Ưu Đãi (Xanh Dương - Cyan)',
      'title': 'KHO VOUCHER\nTRI ÂN KHÁCH HÀNG',
      'subtitle': 'Thu thập hàng ngàn mã giảm giá độc quyền',
      'badge1': 'GIẢM 500K',
      'badge2': 'HOÀN TIỀN',
      'titleColor': '#FDE047',
      'bgColor': '#1D4ED8',
      'gradientEnd': '#1E40AF',
      'iconName': 'local_offer',
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
      'linkType': 'NONE',
      'linkValue': '',
    },
    {
      'name': 'Flagship Cao Cấp (Titanium Đen Sang)',
      'title': 'FLAGSHIP\nIPHONE 15 PRO',
      'subtitle': 'Titan Tự Nhiên - Trả góp 0% lãi suất ngay hôm nay',
      'badge1': 'MỚI 2026',
      'badge2': 'TRẢ GÓP 0%',
      'titleColor': '#38BDF8',
      'bgColor': '#0F172A',
      'gradientEnd': '#1E293B',
      'iconName': 'phone_iphone',
      'linkType': 'PRODUCT',
      'linkValue': '1',
    },
    {
      'name': 'Laptop & Setup Công Nghệ (Indigo Hiện Đại)',
      'title': 'LAPTOP PRO\nHIỆU NĂNG ĐỈNH CAO',
      'subtitle': 'Tặng kèm chuột không dây & balo thời trang',
      'badge1': 'QUÀ 1.500K',
      'badge2': 'BẢO HÀNH 2 NĂM',
      'titleColor': '#FFFFFF',
      'bgColor': '#4F46E5',
      'gradientEnd': '#3730A3',
      'iconName': 'laptop',
      'linkType': 'CATEGORY',
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
    _linkValueCtrl = TextEditingController(text: b?.linkValue ?? '');
    _orderCtrl = TextEditingController(text: b != null ? '${b.displayOrder}' : '1');

    _iconName = b?.iconName ?? 'devices_other';
    _linkType = b?.linkType ?? 'CATEGORY';
    _isActive = b?.isActive ?? true;
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
      _linkType = t['linkType'];
      _linkValueCtrl.text = t['linkValue'];
    });
    ToastHelper.showSuccess(context, 'Đã áp dụng mẫu "${t['name']}"');
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
                            avatar: Icon(Icons.auto_awesome, size: 14, color: Color(int.parse('FF${t['bgColor'].replaceAll('#', '')}', radix: 16))),
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
                  const SizedBox(height: 16),

                  // 2. LIVE PREVIEW (XEM TRƯỚC TRỰC TIẾP)
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

                  // 3. TIÊU ĐỀ & PHỤ ĐỀ
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

                  // 4. BADGES
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

                  // 5. MÀU NỀN & MÀU CHỮ (HEX CODE)
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

                  // 6. CHỌN ICON MINH HỌA
                  const Text('Icon minh họa *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'devices_other',
                      'bolt',
                      'local_offer',
                      'local_shipping',
                      'phone_iphone',
                      'laptop',
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

                  // 7. LOẠI HÀNH ĐỘNG LIÊN KẾT (LINK TYPE)
                  const Text('Hành động khi khách bấm vào *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
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
                      DropdownMenuItem(value: 'COUPON', child: Text('Mã giảm giá / Kho Voucher')),
                      DropdownMenuItem(value: 'PRODUCT', child: Text('Mở trang chi tiết Sản phẩm')),
                      DropdownMenuItem(value: 'CATEGORY', child: Text('Mở Danh mục sản phẩm')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _linkType = val);
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
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 8. THỨ TỰ HIỂN THỊ & KÍCH HOẠT
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
