import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/safe_network_image.dart';
import '../product/product_detail_screen.dart';

class OrderReviewsScreen extends StatefulWidget {
  final int initialTabIndex;

  const OrderReviewsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<OrderReviewsScreen> createState() => _OrderReviewsScreenState();
}

class _OrderReviewsScreenState extends State<OrderReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingPending = true;
  bool _isLoadingReviewed = true;

  List<PendingReviewItemModel> _pendingReviews = [];
  List<ReviewModel> _myReviews = [];

  final List<String> _quickTags = [
    'Sản phẩm chính hãng',
    'Đóng gói rất cẩn thận',
    'Giao hàng siêu nhanh',
    'Chất lượng tuyệt vời',
    'Đúng như mô tả',
    'Hỗ trợ nhiệt tình',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPendingReviews(),
      _loadReviewedList(),
    ]);
  }

  Future<void> _loadPendingReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);
    try {
      final list = await ReviewService.getMyPendingReviews();
      if (mounted) {
        setState(() {
          _pendingReviews = list;
          _isLoadingPending = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _loadReviewedList() async {
    if (!mounted) return;
    setState(() => _isLoadingReviewed = true);
    try {
      final list = await ReviewService.getMyReviews(page: 0, size: 50);
      if (mounted) {
        setState(() {
          _myReviews = list;
          _isLoadingReviewed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviewed = false);
    }
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
        return 'Tuyệt vời & Rất hài lòng (5/5)';
      default:
        return '$stars/5 sao';
    }
  }

  Color _getRatingColor(int stars) {
    if (stars >= 4) return Colors.amber.shade700;
    if (stars == 3) return Colors.orange;
    return Colors.redAccent;
  }

  void _openCreateReviewModal(PendingReviewItemModel item) {
    int rating = 5;
    final commentCtrl = TextEditingController();
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
                maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    // Drag bar
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
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đánh giá sản phẩm',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đơn hàng: #${item.orderCode}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 22, color: AppColors.textMuted),
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
                            // Product preview card
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SafeNetworkImage(
                                      imageUrl: item.productImage,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${CurrencyHelper.format(item.unitPrice)}  •  SL: ${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Star Selector Section
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'Chất lượng sản phẩm thế nào?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      final starNum = index + 1;
                                      final isSelected = starNum <= rating;
                                      return GestureDetector(
                                        onTap: isSubmitting
                                            ? null
                                            : () => setModalState(() => rating = starNum),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 38,
                                            color: isSelected ? Colors.amber.shade600 : Colors.grey.shade400,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRatingColor(rating).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getRatingLabel(rating),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _getRatingColor(rating),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Quick feedback chips
                            const Text(
                              'Gợi ý nhận xét nhanh:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _quickTags.map((tag) {
                                return ActionChip(
                                  label: Text(tag, style: const TextStyle(fontSize: 11.5)),
                                  backgroundColor: Colors.grey.shade100,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          final current = commentCtrl.text.trim();
                                          if (current.isEmpty) {
                                            commentCtrl.text = tag;
                                          } else if (!current.contains(tag)) {
                                            commentCtrl.text = '$current, $tag';
                                          }
                                          setModalState(() {});
                                        },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Comment field
                            const Text(
                              'Nhận xét chi tiết:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: commentCtrl,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 1000,
                              enabled: !isSubmitting,
                              decoration: InputDecoration(
                                hintText: 'Hãy chia sẻ trải nghiệm sử dụng, cảm nhận về chất lượng và đóng gói sản phẩm...',
                                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final comment = commentCtrl.text.trim();
                                        if (comment.length < 5) {
                                          ToastHelper.showError(ctx, 'Nội dung nhận xét phải có tối thiểu 5 ký tự.');
                                          return;
                                        }

                                        setModalState(() => isSubmitting = true);
                                        try {
                                          await ReviewService.createReview(
                                            item.productId,
                                            rating,
                                            comment,
                                            orderId: item.orderId,
                                          );
                                          if (bottomSheetCtx.mounted) {
                                            Navigator.pop(bottomSheetCtx);
                                          }
                                          if (mounted) {
                                            ToastHelper.showSuccess(context, 'Đánh giá sản phẩm thành công!');
                                            await _loadData();
                                            _tabController.animateTo(1); // Chuyển sang tab Đã đánh giá
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            setModalState(() => isSubmitting = false);
                                            final errorMsg = e.toString().replaceAll('Exception: ', '');
                                            ToastHelper.showError(ctx, errorMsg.isNotEmpty ? errorMsg : 'Không thể gửi đánh giá.');
                                          }
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'Gửi đánh giá',
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                      ),
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

  void _openEditReviewModal(ReviewModel review) {
    int rating = review.rating;
    final commentCtrl = TextEditingController(text: review.comment);
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chỉnh sửa đánh giá',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (review.orderCode != null)
                                Text(
                                  'Đơn hàng: #${review.orderCode}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 22, color: AppColors.textMuted),
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
                            if (review.productName.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    if (review.productImage != null && review.productImage!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SafeNetworkImage(
                                          imageUrl: review.productImage,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        review.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      final starNum = index + 1;
                                      final isSelected = starNum <= rating;
                                      return GestureDetector(
                                        onTap: isSubmitting
                                            ? null
                                            : () => setModalState(() => rating = starNum),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 38,
                                            color: isSelected ? Colors.amber.shade600 : Colors.grey.shade400,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getRatingLabel(rating),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _getRatingColor(rating),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Nội dung nhận xét:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: commentCtrl,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 1000,
                              enabled: !isSubmitting,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final comment = commentCtrl.text.trim();
                                        if (comment.length < 5) {
                                          ToastHelper.showError(ctx, 'Nội dung nhận xét phải có tối thiểu 5 ký tự.');
                                          return;
                                        }

                                        setModalState(() => isSubmitting = true);
                                        try {
                                          await ReviewService.updateReview(review.id, rating, comment);
                                          if (bottomSheetCtx.mounted) {
                                            Navigator.pop(bottomSheetCtx);
                                          }
                                          if (mounted) {
                                            ToastHelper.showSuccess(context, 'Cập nhật đánh giá thành công!');
                                            await _loadReviewedList();
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            setModalState(() => isSubmitting = false);
                                            final errorMsg = e.toString().replaceAll('Exception: ', '');
                                            ToastHelper.showError(ctx, errorMsg.isNotEmpty ? errorMsg : 'Không thể cập nhật đánh giá.');
                                          }
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'Lưu thay đổi',
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                      ),
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
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đánh giá này không?'),
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
                  ToastHelper.showSuccess(context, 'Đã xóa đánh giá');
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ToastHelper.showError(context, 'Không thể xóa đánh giá');
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa đánh giá'),
                  if (_pendingReviews.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingReviews.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã đánh giá'),
                  if (_myReviews.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_myReviews.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Chưa đánh giá
          _buildPendingTab(),
          // TAB 2: Đã đánh giá
          _buildReviewedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingReviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPendingReviews,
        child: ListView(
          children: const [
            SizedBox(height: 60),
            EmptyStateWidget(
              icon: Icons.rate_review_outlined,
              title: 'Không có đơn chờ đánh giá',
              subtitle: 'Bạn đã đánh giá tất cả các sản phẩm đã mua hoặc chưa có đơn hàng nào hoàn thành.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingReviews,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _pendingReviews.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _pendingReviews[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order info header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '#${item.orderCode}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 3),
                            Text(
                              'Đã nhận hàng',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.orderDate != null && item.orderDate!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ngày đặt: ${CurrencyHelper.formatDate(item.orderDate)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                  const Divider(height: 16, color: AppColors.divider),

                  // Product info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SafeNetworkImage(
                          imageUrl: item.productImage,
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${CurrencyHelper.format(item.unitPrice)} × ${item.quantity}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyHelper.format(item.unitPrice * item.quantity),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, size: 15, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Chia sẻ để giúp người mua sau',
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text(
                          'Đánh giá ngay',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _openCreateReviewModal(item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewedTab() {
    if (_isLoadingReviewed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myReviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReviewedList,
        child: ListView(
          children: const [
            SizedBox(height: 60),
            EmptyStateWidget(
              icon: Icons.star_border_rounded,
              title: 'Chưa có đánh giá nào',
              subtitle: 'Các đánh giá của bạn cho các sản phẩm đã mua sẽ xuất hiện tại đây.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviewedList,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _myReviews.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final review = _myReviews[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Review header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (review.orderCode != null && review.orderCode!.isNotEmpty) ...[
                            Icon(Icons.receipt_long_outlined, size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '#${review.orderCode}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (review.createdAt != null)
                            Text(
                              CurrencyHelper.formatDate(review.createdAt),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'Đã đánh giá',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: AppColors.divider),

                  // Product info
                  if (review.productName.isNotEmpty) ...[
                    GestureDetector(
                      onTap: review.productId > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: review.productId),
                                ),
                              );
                            }
                          : null,
                      child: Row(
                        children: [
                          if (review.productImage != null && review.productImage!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SafeNetworkImage(
                                imageUrl: review.productImage,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (review.unitPrice != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyHelper.format(review.unitPrice!),
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Rating Stars
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (sIdx) {
                          return Icon(
                            sIdx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 18,
                            color: Colors.amber.shade600,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getRatingLabel(review.rating),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _getRatingColor(review.rating),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Comment bubble
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      review.comment.isNotEmpty ? review.comment : '(Không có lời bình luận)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                                'Phản hồi từ Người Bán:',
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

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (review.productId > 0)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.storefront_outlined, size: 15),
                          label: const Text('Xem sản phẩm', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: review.productId),
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                        onPressed: () => _openEditReviewModal(review),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Xóa đánh giá',
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        onPressed: () => _confirmDeleteReview(review),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
