import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/address_provider.dart';
import '../../utils/toast_helper.dart';
import '../address/address_list_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../order/buy_again_screen.dart';
import '../cart/cart_screen.dart';
import '../order/my_orders_screen.dart';
import '../order/order_reviews_screen.dart';
import '../coupon/customer_coupons_screen.dart';
import '../product/wishlist_screen.dart';
import '../product/product_detail_screen.dart';
import '../../utils/currency_format.dart';
import '../../widgets/safe_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart';
import 'recently_viewed_screen.dart';
import '../../services/recently_viewed_service.dart';
import '../../services/review_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _pendingReviewCount = 0;
  int _reviewedCount = 0;
  int _recentlyViewedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviewCounts();
    _loadRecentlyViewedCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(silent: true);
      }
    });
  }

  Future<void> _loadRecentlyViewedCount() async {
    try {
      final list = await RecentlyViewedService.getRecentlyViewed();
      if (mounted) {
        setState(() {
          _recentlyViewedCount = list.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadReviewCounts() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;
    try {
      final counts = await ReviewService.getMyReviewCounts();
      if (mounted) {
        setState(() {
          _pendingReviewCount = counts['pendingCount'] ?? 0;
          _reviewedCount = counts['reviewedCount'] ?? 0;
        });
      }
    } catch (_) {}
  }

  void _showApiConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình REST API Base URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấu hình URL kết nối tới Spring Boot backend:\n'
              '• Android Emulator: http://10.0.2.2:8080/api/v1\n'
              '• Windows / Web: http://localhost:8080/api/v1\n'
              '• Máy thật (WiFi): http://<IP-May-Tinh>:8080/api/v1',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://localhost:8080/api/v1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiConfig.resetToDefault();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ToastHelper.showSuccess(context, 'Đã đặt lại về URL mặc định: ${ApiConfig.baseUrl}');
              }
            },
            child: const Text('Mặc định'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                await ApiConfig.setBaseUrl(val);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ToastHelper.showSuccess(context, 'Đã lưu cấu hình API: ${ApiConfig.baseUrl}');
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final favorites = Provider.of<FavoriteProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản của tôi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: auth.isAuthenticated
                  ? Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                          ),
                          child: ClipOval(
                            child: (auth.user!.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: auth.user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    errorWidget: (_, _, _) => Center(
                                      child: Text(
                                        auth.user!.fullName.isNotEmpty ? auth.user!.fullName[0].toUpperCase() : 'U',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      auth.user!.fullName.isNotEmpty ? auth.user!.fullName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          auth.user!.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.user!.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        if (auth.user!.phone != null && auth.user!.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            auth.user!.phone!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: auth.user!.roles.map((r) {
                            String roleLabel = r.replaceFirst('ROLE_', '');
                            Color bgColor = Colors.blue.shade50;
                            Color borderColor = Colors.blue.shade200;
                            Color textColor = AppColors.primary;

                            if (r.contains('ADMIN')) {
                              roleLabel = 'Quản trị viên';
                              bgColor = Colors.purple.shade50;
                              borderColor = Colors.purple.shade200;
                              textColor = Colors.purple.shade700;
                            } else if (r.contains('STAFF')) {
                              roleLabel = 'Nhân viên';
                              bgColor = Colors.amber.shade50;
                              borderColor = Colors.amber.shade300;
                              textColor = Colors.amber.shade900;
                            } else if (r.contains('CUSTOMER')) {
                              roleLabel = 'Khách hàng';
                              bgColor = Colors.blue.shade50;
                              borderColor = Colors.blue.shade200;
                              textColor = AppColors.primary;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.textDark),
                          label: const Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFFF0F2F5),
                          child: Icon(Icons.person_outline, size: 36, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Bạn chưa đăng nhập',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Đăng nhập để xem lịch sử đơn hàng và nhận ưu đãi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: const Text('Đăng ký'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Text('Đăng nhập'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            if (auth.isManager) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Bảng điều khiển Quản trị',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Đơn hàng, kho sản phẩm & doanh thu',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        auth.setAdminMode(true);
                      },
                      child: const Text('Mở Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Quick Buy Again section if user has purchased items
            Consumer<OrderProvider>(
              builder: (context, orderProv, _) {
                final purchased = orderProv.purchasedProducts;
                if (!auth.isAuthenticated || purchased.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.replay_rounded, size: 20, color: Color(0xFF0D9488)),
                              SizedBox(width: 8),
                              Text(
                                'Mua lại nhanh',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BuyAgainScreen()),
                              );
                            },
                            child: Row(
                              children: const [
                                Text(
                                  'Xem tất cả',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: Color(0xFF0D9488)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 135,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: purchased.length > 8 ? 8 : purchased.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final p = purchased[idx];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (p.productId > 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(productId: p.productId),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 110,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SafeNetworkImage(
                                            imageUrl: p.productImageUrl,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fallbackIconSize: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      p.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyHelper.format(p.unitPrice),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Navigation Menu Options
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.primary),
                    title: const Text('Thông tin cá nhân', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tùy chỉnh họ tên, số điện thoại, avatar & mật khẩu', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () {
                      if (!auth.isAuthenticated) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                    title: const Text('Đơn mua của tôi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.rate_review_outlined, color: Color(0xFFF59E0B)),
                    title: const Text('Đánh giá đơn hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _pendingReviewCount > 0
                          ? 'Có $_pendingReviewCount sản phẩm chờ đánh giá'
                          : (_reviewedCount > 0
                              ? 'Đã đánh giá $_reviewedCount sản phẩm'
                              : 'Chưa đánh giá & Đã đánh giá'),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_pendingReviewCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_pendingReviewCount',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                    onTap: () async {
                      if (!auth.isAuthenticated) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        return;
                      }
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderReviewsScreen()),
                      );
                      _loadReviewCounts();
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.confirmation_num_outlined, color: Color(0xFF059669)),
                    title: const Text('Kho Voucher & Ưu đãi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Mã giảm giá mua sắm dành riêng cho bạn', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerCouponsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                    title: const Text('Giỏ hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cart.totalItems > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cart.totalItems}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.favorite_border_rounded, color: AppColors.danger),
                    title: const Text('Sản phẩm yêu thích', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (favorites.count > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${favorites.count}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WishlistScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Color(0xFF6366F1)),
                    title: const Text('Sản phẩm đã xem gần đây', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _recentlyViewedCount > 0
                          ? '$_recentlyViewedCount sản phẩm đã lưu'
                          : 'Lịch sử sản phẩm bạn vừa xem',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_recentlyViewedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_recentlyViewedCount',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecentlyViewedScreen()),
                      );
                      _loadRecentlyViewedCount();
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  Consumer<AddressProvider>(
                    builder: (context, addrProv, _) {
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: Color(0xFF0284C7)),
                        title: const Text('Sổ địa chỉ nhận hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          addrProv.addresses.isEmpty
                              ? 'Chưa lưu địa chỉ (Hỗ trợ định vị GPS)'
                              : '${addrProv.addresses.length} địa chỉ đã lưu',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                        onTap: () {
                          if (!auth.isAuthenticated) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddressListScreen()),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  Consumer<OrderProvider>(
                    builder: (context, orderProv, _) {
                      final count = orderProv.purchasedProducts.length;
                      return ListTile(
                        leading: const Icon(Icons.replay_rounded, color: Color(0xFF0D9488)),
                        title: const Text('Mua lại sản phẩm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          count > 0 ? '$count sản phẩm bạn đã từng mua' : 'Dễ dàng đặt lại các món đồ đã mua',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (count > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: AppColors.textLight),
                          ],
                        ),
                        onTap: () {
                          if (!auth.isAuthenticated) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BuyAgainScreen()),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 0.8, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.settings_ethernet, color: AppColors.primary),
                    title: const Text('Cấu hình API Backend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      ApiConfig.baseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textLight),
                    onTap: () => _showApiConfigDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Info Card
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.primary),
                    title: Text('Phiên bản ứng dụng', style: TextStyle(fontSize: 14)),
                    trailing: Text('TechStore v1.0.0 (Flutter)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            if (auth.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi TechStore?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await auth.logout();
                      cart.clearCart();
                      if (context.mounted) {
                        Provider.of<OrderProvider>(context, listen: false).clearOrders();
                        Provider.of<FavoriteProvider>(context, listen: false).clearOnLogout();
                        Provider.of<NotificationProvider>(context, listen: false).clearOnLogout();
                        Provider.of<AddressProvider>(context, listen: false).clearOnLogout();
                        ToastHelper.showInfo(context, 'Đã đăng xuất tài khoản');
                      }
                    }
                  },
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
