import '../models/review_model.dart';
import 'api_service.dart';

class ReviewService {
  static Future<ProductReviewSummaryModel> getProductReviews(int productId, {int page = 0, int size = 10}) async {
    final data = await ApiService.get(
      '/products/$productId/reviews',
      params: {'page': page, 'size': size},
    );
    return ProductReviewSummaryModel.fromJson(data);
  }

  static Future<bool> checkEligibility(int productId) async {
    try {
      final data = await ApiService.get('/products/$productId/reviews/eligibility');
      if (data is Map && data.containsKey('eligible')) {
        return data['eligible'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<ReviewModel> createReview(
    int productId,
    int rating,
    String comment, {
    int? orderId,
  }) async {
    final Map<String, dynamic> body = {
      'rating': rating,
      'comment': comment.trim(),
    };
    if (orderId != null) {
      body['orderId'] = orderId;
    }

    final data = await ApiService.post(
      '/products/$productId/reviews',
      body: body,
    );
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<ReviewModel> updateReview(int reviewId, int rating, String comment) async {
    final data = await ApiService.put(
      '/reviews/$reviewId',
      body: {
        'rating': rating,
        'comment': comment.trim(),
      },
    );
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteReview(int reviewId) async {
    await ApiService.delete('/reviews/$reviewId');
  }

  static Future<List<PendingReviewItemModel>> getMyPendingReviews() async {
    try {
      final data = await ApiService.get('/reviews/my/pending');
      if (data is List) {
        return data.map((e) => PendingReviewItemModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<ReviewModel>> getMyReviews({int page = 0, int size = 30}) async {
    try {
      final data = await ApiService.get(
        '/reviews/my',
        params: {'page': page, 'size': size},
      );
      if (data is Map<String, dynamic>) {
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (data is List) {
        return data.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getMyReviewCounts() async {
    try {
      final data = await ApiService.get('/reviews/my/counts');
      if (data is Map) {
        return {
          'pendingCount': (data['pendingCount'] as num?)?.toInt() ?? 0,
          'reviewedCount': (data['reviewedCount'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'pendingCount': 0, 'reviewedCount': 0};
  }

  static Future<List<ReviewModel>> getAdminReviews({
    int? rating,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
    };
    if (rating != null && rating > 0) {
      params['rating'] = rating;
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    try {
      final data = await ApiService.get('/admin/reviews', params: params);
      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        return data.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<AdminReviewStatsModel?> getAdminReviewStats() async {
    try {
      final data = await ApiService.get('/admin/reviews/stats');
      if (data is Map<String, dynamic>) {
        return AdminReviewStatsModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<ReviewModel> replyReview(int reviewId, String reply) async {
    final data = await ApiService.post(
      '/admin/reviews/$reviewId/reply',
      body: {'reply': reply.trim()},
    );
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }
}
