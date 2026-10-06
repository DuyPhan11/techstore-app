import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/safe_network_image.dart';
import '../order/order_detail_screen.dart';
import 'admin_product_detail_screen.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool _isLoading = true;
  bool _isLoadingStats = true;

  AdminReviewStatsModel? _stats;
  List<ReviewModel> _reviews = [];

  int? _selectedRatingFilter; // null = all, 1..5 = specific, -1 = negative (1-2 stars)
  final TextEditingController _searchCtrl = TextEditingController();
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadStats(),
      _loadReviews(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final s = await ReviewService.getAdminReviewStats();
      if (mounted) {
        setState(() {
          _stats = s;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      int? queryRating;
      if (_selectedRatingFilter != null && _selectedRatingFilter! > 0) {
        queryRating = _selectedRatingFilter;
      }

      final list = await ReviewService.getAdminReviews(
        rating: queryRating,
        search: _currentSearchQuery,
        page: 0,
        size: 50,
      );

      List<ReviewModel> filteredList = list;
      // If negative reviews filter (1-2 stars) is active, do client-side filter if needed
      if (_selectedRatingFilter == -1) {
        filteredList = list.where((r) => r.rating <= 2).toList();
      }

      if (mounted) {
        setState(() {
          _reviews = filteredList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchSubmitted(String val) {
    setState(() {
      _currentSearchQuery = val.trim();
    });
    _loadReviews();
  }

  void _onFilterRatingChanged(int? rating) {
    setState(() {
      _selectedRatingFilter = rating;
    });
    _loadReviews();
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Rất tệ (1/5)';
      case 2:
        return 'Không hài lòng (2/5)';
      case 3:
        return 'Bình thường (3/5)';
      case 4:
        return 'Hài lòng (4/5)';
      case 5:
        return 'Tuyệt vời (5/5)';
      default:
        return '$stars/5 sao';
    }
  }

  Color _getRatingColor(int stars) {
    if (stars >= 4) return Colors.amber.shade700;
    if (stars == 3) return Colors.orange;
    return Colors.redAccent;
  }

  void _openReplyModal(ReviewModel review) {
    final replyCtrl = TextEditingController(text: review.adminReply ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.reply_rounded, color: Color(0xFF4F46E5), size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Phản hồi đánh giá của khách',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer review snippet
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        review.userName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 14,
                                            color: Colors.amber.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    review.comment.isNotEmpty ? review.comment : '(Không có nhận xét viết chữ)',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Quick reply templates
                            const Text(
                              'Mẫu phản hồi nhanh:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                'Dạ TechStore cảm ơn quý khách đã tin tưởng và đánh giá 5 sao!',
                                'Dạ TechStore rất tiếc vì trải nghiệm chưa trọn vẹn, shop sẽ liên hệ hỗ trợ ngay ạ!',
                                'Cảm ơn bạn đã phản hồi, shop sẽ tiếp tục hoàn thiện chất lượng dịch vụ!',
                              ].map((t) {
                                return ActionChip(
                                  label: Text(
                                    t.length > 32 ? '${t.substring(0, 32)}...' : t,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          replyCtrl.text = t;
                                          setModalState(() {});
                                        },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Text area
                            const Text(
                              'Nội dung phản hồi từ Cửa hàng:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: replyCtrl,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 1000,
                              enabled: !isSubmitting,
                              decoration: InputDecoration(
                                hintText: 'Nhập nội dung phản hồi chính thức từ TechStore...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final txt = replyCtrl.text.trim();
                                        if (txt.length < 2) {
                                          ToastHelper.showError(ctx, 'Nội dung phản hồi tối thiểu 2 ký tự.');
                                          return;
                                        }

                                        setModalState(() => isSubmitting = true);
                                        try {
                                          await ReviewService.replyReview(review.id, txt);
                                          if (bottomSheetCtx.mounted) {
                                            Navigator.pop(bottomSheetCtx);
                                          }
                                          if (mounted) {
                                            ToastHelper.showSuccess(context, 'Đã gửi phản hồi thành công!');
                                            _loadReviews();
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            setModalState(() => isSubmitting = false);
                                            final errorMsg = e.toString().replaceAll('Exception: ', '');
                                            ToastHelper.showError(ctx, errorMsg.isNotEmpty ? errorMsg : 'Không thể gửi phản hồi.');
                                          }
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Lưu phản hồi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteReview(ReviewModel review) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa đánh giá'),
        content: Text(
          'Bạn có chắc chắn muốn xóa đánh giá của khách hàng "${review.userName}" không?\n\n'
          'Thao tác này sẽ gỡ bỏ đánh giá khỏi hệ thống vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ReviewService.deleteReview(review.id);
                if (mounted) {
                  ToastHelper.showSuccess(context, 'Đã xóa đánh giá thành công.');
                  _loadAll();
                }
              } catch (e) {
                if (mounted) {
                  ToastHelper.showError(context, 'Không thể xóa đánh giá.');
                }
              }
            },
            child: const Text('Xóa đánh giá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Quản lý Đánh giá',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Làm mới',
            onPressed: _loadAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Top Overview Stats Card
            _buildStatsCard(),
            const SizedBox(height: 14),

            // Search Bar & Filter Chips
            _buildFilterSection(),
            const SizedBox(height: 14),

            // Reviews List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách đánh giá (${_reviews.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                if (_selectedRatingFilter != null || _currentSearchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _selectedRatingFilter = null;
                        _currentSearchQuery = '';
                      });
                      _loadReviews();
                    },
                    child: const Text('Đặt lại bộ lọc', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Reviews List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EmptyStateWidget(
                  icon: Icons.rate_review_outlined,
                  title: 'Không tìm thấy đánh giá nào',
                  subtitle: 'Không có đánh giá phù hợp với từ khóa hoặc bộ lọc đã chọn.',
                ),
              )
            else
              ..._reviews.map((r) => _buildReviewCard(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isLoadingStats) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _stats;
    final avg = stats?.averageRating ?? 0.0;
    final total = stats?.totalReviews ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Big Rating Average
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ 5.0',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: Colors.amber.shade600,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$total lượt đánh giá',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Star bars breakdown
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, stats?.count5Star ?? 0, total),
                      _buildRatingBar(4, stats?.count4Star ?? 0, total),
                      _buildRatingBar(3, stats?.count3Star ?? 0, total),
                      _buildRatingBar(2, stats?.count2Star ?? 0, total),
                      _buildRatingBar(1, stats?.count1Star ?? 0, total),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int star, int count, int total) {
    final double pct = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  star >= 4 ? Colors.amber.shade600 : (star == 3 ? Colors.orange : Colors.redAccent),
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 26,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên khách, sản phẩm, mã đơn...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchSubmitted('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onSubmitted: _onSearchSubmitted,
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _selectedRatingFilter == null,
                onSelected: (_) => _onFilterRatingChanged(null),
                selectedColor: const Color(0xFF0F172A),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _selectedRatingFilter == null ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(width: 6),
              ...[5, 4, 3, 2, 1].map((s) {
                final isSelected = _selectedRatingFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$s'),
                        const SizedBox(width: 2),
                        const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onFilterRatingChanged(isSelected ? null : s),
                    selectedColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                );
              }),
              // Negative quick filter
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Cần xử lý (1-2 ⭐)'),
                  ],
                ),
                selected: _selectedRatingFilter == -1,
                onSelected: (_) => _onFilterRatingChanged(_selectedRatingFilter == -1 ? null : -1),
                selectedColor: Colors.red.shade900,
                backgroundColor: const Color(0xFFFEF2F2),
                side: BorderSide(color: Colors.red.shade200),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _selectedRatingFilter == -1 ? Colors.white : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User & Rating & Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              review.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.createdAt != null)
                            Text(
                              CurrencyHelper.formatDateTime(review.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 15,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getRatingLabel(review.rating),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getRatingColor(review.rating),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.divider),

            // Product & Order info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  if (review.productImage != null && review.productImage!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SafeNetworkImage(
                        imageUrl: review.productImage,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.productName.isNotEmpty ? review.productName : 'Sản phẩm #${review.productId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (review.orderCode != null && review.orderCode!.isNotEmpty)
                              GestureDetector(
                                onTap: review.orderId != null && review.orderId! > 0
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OrderDetailScreen(
                                              orderId: review.orderId!,
                                              isAdmin: true,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(
                                  'Đơn: #${review.orderCode}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (review.unitPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${CurrencyHelper.format(review.unitPrice!)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (review.productId > 0)
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                      tooltip: 'Xem trang sản phẩm',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminProductDetailScreen(productId: review.productId),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Customer Comment
            Text(
              review.comment.isNotEmpty ? review.comment : '(Khách hàng không để lại nhận xét bằng chữ)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.35),
            ),

            // Shop Reply (if any)
            if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 4),
                        const Text(
                          'Phản hồi từ Cửa hàng (Admin):',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                        const Spacer(),
                        if (review.adminReplyAt != null)
                          Text(
                            CurrencyHelper.formatDateTime(review.adminReplyAt),
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.adminReply!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Order detail button
                if (review.orderId != null && review.orderId! > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 14),
                    label: const Text('Xem đơn', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                            orderId: review.orderId!,
                            isAdmin: true,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 4),

                // Reply button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: Icon(
                    review.adminReply != null ? Icons.edit_outlined : Icons.reply_rounded,
                    size: 13,
                  ),
                  label: Text(
                    review.adminReply != null ? 'Sửa phản hồi' : 'Phản hồi',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openReplyModal(review),
                ),
                const SizedBox(width: 4),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  tooltip: 'Xóa đánh giá vi phạm',
                  onPressed: () => _confirmDeleteReview(review),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
