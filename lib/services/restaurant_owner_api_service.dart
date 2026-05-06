import '../models/auth_session.dart';
import 'api_client.dart';
import 'authenticated_api_client.dart';
import 'restaurant_menu_api_service.dart';

class RestaurantOwnerApiService {
  RestaurantOwnerApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<RestaurantAnalytics> fetchAnalytics({
    required AuthSession session,
    String period = 'monthly',
  }) async {
    final endpoint = Uri(
      path: '/v1/restaurant/analytics',
      queryParameters: <String, String>{'period': period},
    ).toString();
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: endpoint,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load analytics.',
    );
    return RestaurantAnalytics.fromJson(_extractObject(payload));
  }

  Future<Map<String, dynamic>> fetchProfile({required AuthSession session}) {
    return _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/profile',
      fallback: 'Failed to load restaurant profile.',
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required AuthSession session,
    required Map<String, dynamic> body,
  }) {
    return _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/profile',
      body: body,
      fallback: 'Could not update restaurant profile.',
    );
  }

  Future<String> uploadProfilePhoto({
    required AuthSession session,
    required String path,
  }) async {
    return _uploadSingleUrl(
      session: session,
      endpoint: '/v1/restaurant/profile-photo/upload',
      fileField: 'photo',
      path: path,
      fallback: 'Could not upload profile photo.',
    );
  }

  Future<Map<String, dynamic>> fetchSettings({required AuthSession session}) {
    return _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/settings',
      fallback: 'Failed to load settings.',
    );
  }

  Future<Map<String, dynamic>> updateSettings({
    required AuthSession session,
    required Map<String, dynamic> body,
  }) {
    return _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/settings',
      body: body,
      fallback: 'Could not update settings.',
    );
  }

  Future<List<RestaurantMenuCategory>> fetchMenuCategories({
    required AuthSession session,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/menu/categories',
      fallback: 'Failed to load menu categories.',
      keepListData: true,
    );
    return _extractListFromObject(
      payload,
    ).map(RestaurantMenuCategory.fromJson).toList(growable: false);
  }

  Future<RestaurantMenuCategory> createMenuCategory({
    required AuthSession session,
    required String name,
    int? sortOrder,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'POST',
      endpoint: '/v1/restaurant/menu/categories',
      body: <String, dynamic>{
        'name': name.trim(),
        // ignore: use_null_aware_elements
        if (sortOrder != null) 'sort_order': sortOrder,
      },
      fallback: 'Could not create category.',
    );
    return RestaurantMenuCategory.fromJson(payload);
  }

  Future<RestaurantMenuCategory> updateMenuCategory({
    required AuthSession session,
    required String categoryId,
    required Map<String, dynamic> body,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/menu/categories/${categoryId.trim()}',
      body: body,
      fallback: 'Could not update category.',
    );
    return RestaurantMenuCategory.fromJson(payload);
  }

  Future<void> deleteMenuCategory({
    required AuthSession session,
    required String categoryId,
  }) async {
    await _requestObject(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/restaurant/menu/categories/${categoryId.trim()}',
      fallback: 'Could not delete category.',
    );
  }

  Future<List<RestaurantMenuItem>> fetchMenuItems({
    required AuthSession session,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/menu/items',
      fallback: 'Failed to load menu items.',
      keepListData: true,
    );
    return _extractListFromObject(
      payload,
    ).map(RestaurantMenuItem.fromJson).toList(growable: false);
  }

  Future<RestaurantMenuItem> createMenuItem({
    required AuthSession session,
    required Map<String, dynamic> body,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'POST',
      endpoint: '/v1/restaurant/menu/items',
      body: body,
      fallback: 'Could not create menu item.',
    );
    return RestaurantMenuItem.fromJson(payload);
  }

  Future<RestaurantMenuItem> updateMenuItem({
    required AuthSession session,
    required String menuItemId,
    required Map<String, dynamic> body,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/menu/items/${menuItemId.trim()}',
      body: body,
      fallback: 'Could not update menu item.',
    );
    return RestaurantMenuItem.fromJson(payload);
  }

  Future<RestaurantMenuItem> updateMenuItemAvailability({
    required AuthSession session,
    required String menuItemId,
    required bool isAvailable,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/menu/items/${menuItemId.trim()}/availability',
      body: <String, dynamic>{'is_available': isAvailable},
      fallback: 'Could not update menu item availability.',
    );
    return RestaurantMenuItem.fromJson(payload);
  }

  Future<void> deleteMenuItem({
    required AuthSession session,
    required String menuItemId,
  }) async {
    await _requestObject(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/restaurant/menu/items/${menuItemId.trim()}',
      fallback: 'Could not delete menu item.',
    );
  }

  Future<List<String>> uploadMenuImages({
    required AuthSession session,
    required List<String> paths,
  }) async {
    final files = paths
        .where((path) => path.trim().isNotEmpty)
        .map(
          (path) =>
              AuthenticatedMultipartFile(field: 'images[]', path: path.trim()),
        )
        .toList(growable: false);
    final result = await _apiClient.multipartRequest(
      session: session,
      method: 'POST',
      endpoint: '/v1/restaurant/menu/images/upload',
      files: files,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not upload menu images.',
    );
    final data = _stringMap(payload['data']);
    final urls = data['urls'];
    if (urls is List) {
      return urls
          .whereType<String>()
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  Future<List<RestaurantVideoItem>> fetchVideos({
    required AuthSession session,
    String? status,
  }) async {
    final endpoint = Uri(
      path: '/v1/restaurant/videos',
      queryParameters: <String, String>{
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    ).toString();
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: endpoint,
      fallback: 'Failed to load videos.',
      keepListData: true,
    );
    return _extractListFromObject(
      payload,
    ).map(RestaurantVideoItem.fromJson).toList(growable: false);
  }

  Future<RestaurantVideoItem> createVideo({
    required AuthSession session,
    required String videoPath,
    required String title,
    String description = '',
    String status = 'draft',
    String? menuItemId,
  }) async {
    final result = await _apiClient.multipartRequest(
      session: session,
      method: 'POST',
      endpoint: '/v1/restaurant/videos',
      fields: <String, String>{
        'title': title.trim(),
        'description': description.trim(),
        'status': status.trim().isEmpty ? 'draft' : status.trim(),
        if (menuItemId != null && menuItemId.trim().isNotEmpty)
          'menu_item_id': menuItemId.trim(),
      },
      files: <AuthenticatedMultipartFile>[
        AuthenticatedMultipartFile(field: 'video', path: videoPath.trim()),
      ],
      timeout: const Duration(minutes: 3),
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not upload video.',
    );
    return RestaurantVideoItem.fromJson(_extractObject(payload));
  }

  Future<RestaurantVideoItem> updateVideo({
    required AuthSession session,
    required String videoId,
    required Map<String, dynamic> body,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/videos/${videoId.trim()}',
      body: body,
      fallback: 'Could not update video.',
    );
    return RestaurantVideoItem.fromJson(payload);
  }

  Future<void> deleteVideo({
    required AuthSession session,
    required String videoId,
  }) async {
    await _requestObject(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/restaurant/videos/${videoId.trim()}',
      fallback: 'Could not delete video.',
    );
  }

  Future<String> uploadVideoThumbnail({
    required AuthSession session,
    required String path,
  }) {
    return _uploadSingleUrl(
      session: session,
      endpoint: '/v1/restaurant/videos/assets/upload',
      fileField: 'file',
      path: path,
      fields: const <String, String>{'asset_type': 'thumbnail'},
      fallback: 'Could not upload thumbnail.',
    );
  }

  Future<RestaurantReviewSummary> fetchReviewSummary({
    required AuthSession session,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/reviews/summary',
      fallback: 'Failed to load review summary.',
    );
    return RestaurantReviewSummary.fromJson(payload);
  }

  Future<List<RestaurantReviewItem>> fetchReviews({
    required AuthSession session,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/reviews',
      fallback: 'Failed to load reviews.',
      keepListData: true,
    );
    return _extractListFromObject(
      payload,
    ).map(RestaurantReviewItem.fromJson).toList(growable: false);
  }

  Future<RestaurantReviewItem> replyReview({
    required AuthSession session,
    required String reviewId,
    required String reply,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/reviews/${reviewId.trim()}/reply',
      body: <String, dynamic>{'reply': reply.trim()},
      fallback: 'Could not save review reply.',
    );
    return RestaurantReviewItem.fromJson(payload);
  }

  Future<Map<String, dynamic>> _requestObject({
    required AuthSession session,
    required String method,
    required String endpoint,
    Object? body,
    required String fallback,
    bool keepListData = false,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: method,
      endpoint: endpoint,
      body: body,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(result.response.statusCode, payload, fallback: fallback);
    if (keepListData) {
      return payload;
    }
    return _extractObject(payload);
  }

  Future<String> _uploadSingleUrl({
    required AuthSession session,
    required String endpoint,
    required String fileField,
    required String path,
    required String fallback,
    Map<String, String> fields = const <String, String>{},
  }) async {
    final result = await _apiClient.multipartRequest(
      session: session,
      method: 'POST',
      endpoint: endpoint,
      fields: fields,
      files: <AuthenticatedMultipartFile>[
        AuthenticatedMultipartFile(field: fileField, path: path.trim()),
      ],
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(result.response.statusCode, payload, fallback: fallback);
    final data = _stringMap(payload['data']);
    return _readString(data['url']) ?? '';
  }
}

class RestaurantAnalytics {
  const RestaurantAnalytics({
    required this.period,
    required this.periodLabel,
    required this.metrics,
    required this.revenueTrend,
    required this.orderSplit,
    required this.topDishes,
    required this.videoFunnel,
    required this.topVideo,
  });

  final String period;
  final String periodLabel;
  final Map<String, RestaurantMetricValue> metrics;
  final List<RestaurantRevenuePoint> revenueTrend;
  final Map<String, int> orderSplit;
  final List<RestaurantTopDish> topDishes;
  final Map<String, int> videoFunnel;
  final RestaurantVideoItem? topVideo;

  double metricValue(String key) => metrics[key]?.value ?? 0;

  factory RestaurantAnalytics.fromJson(Map<String, dynamic> json) {
    final metrics = <String, RestaurantMetricValue>{};
    final metricsMap = _stringMap(json['metrics']);
    for (final entry in metricsMap.entries) {
      metrics[entry.key] = RestaurantMetricValue.fromJson(
        _stringMap(entry.value),
      );
    }
    return RestaurantAnalytics(
      period: _readString(json['period']) ?? 'monthly',
      periodLabel: _readString(json['period_label']) ?? '',
      metrics: metrics,
      revenueTrend: _listOfMaps(
        json['revenue_trend'],
      ).map(RestaurantRevenuePoint.fromJson).toList(growable: false),
      orderSplit: _intMap(_stringMap(json['order_split'])),
      topDishes: _listOfMaps(
        json['top_dishes'],
      ).map(RestaurantTopDish.fromJson).toList(growable: false),
      videoFunnel: _intMap(_stringMap(json['video_funnel'])),
      topVideo: json['top_video'] is Map
          ? RestaurantVideoItem.fromJson(_stringMap(json['top_video']))
          : null,
    );
  }
}

class RestaurantMetricValue {
  const RestaurantMetricValue({
    required this.value,
    required this.changePercent,
  });

  final double value;
  final double changePercent;

  factory RestaurantMetricValue.fromJson(Map<String, dynamic> json) {
    return RestaurantMetricValue(
      value: _readDouble(json['value']) ?? 0,
      changePercent: _readDouble(json['change_percent']) ?? 0,
    );
  }
}

class RestaurantRevenuePoint {
  const RestaurantRevenuePoint({
    required this.label,
    required this.fullLabel,
    required this.ordersCount,
    required this.revenue,
  });

  final String label;
  final String fullLabel;
  final int ordersCount;
  final double revenue;

  factory RestaurantRevenuePoint.fromJson(Map<String, dynamic> json) {
    return RestaurantRevenuePoint(
      label: _readString(json['label']) ?? '',
      fullLabel: _readString(json['full_label']) ?? '',
      ordersCount: _readInt(json['orders_count']) ?? 0,
      revenue: _readDouble(json['revenue']) ?? 0,
    );
  }
}

class RestaurantTopDish {
  const RestaurantTopDish({
    required this.menuItemId,
    required this.name,
    required this.sold,
  });

  final String menuItemId;
  final String name;
  final int sold;

  factory RestaurantTopDish.fromJson(Map<String, dynamic> json) {
    return RestaurantTopDish(
      menuItemId: _readString(json['menu_item_id']) ?? '',
      name: _readString(json['name']) ?? 'Menu item',
      sold: _readInt(json['sold']) ?? 0,
    );
  }
}

class RestaurantMenuCategory {
  const RestaurantMenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.items,
  });

  final String id;
  final String name;
  final int sortOrder;
  final List<RestaurantMenuItem> items;

  factory RestaurantMenuCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuCategory(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? 'Category',
      sortOrder: _readInt(json['sort_order']) ?? 0,
      items: _listOfMaps(
        json['items'],
      ).map(RestaurantMenuItem.fromJson).toList(growable: false),
    );
  }
}

class RestaurantVideoItem {
  const RestaurantVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.streamHlsUrl,
    required this.hlsUrl,
    required this.playbackUrlValue,
    required this.videoUrl,
    required this.streamPreviewUrl,
    required this.status,
    required this.moderationStatus,
    required this.moderationReason,
    required this.streamReady,
    required this.viewsCount,
    required this.likesCount,
    required this.sharesCount,
    this.createdAt,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String mediaUrl;
  final String thumbnailUrl;
  final String streamHlsUrl;
  final String hlsUrl;
  final String playbackUrlValue;
  final String videoUrl;
  final String streamPreviewUrl;
  final String status;
  final String moderationStatus;
  final String moderationReason;
  final bool streamReady;
  final int viewsCount;
  final int likesCount;
  final int sharesCount;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  String get playbackUrl {
    final candidates = <String>[
      streamHlsUrl,
      hlsUrl,
      playbackUrlValue,
      videoUrl,
      mediaUrl,
    ];
    for (final value in candidates.where(_isHlsUrl)) {
      final cleaned = value.trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }
    for (final value in candidates) {
      final cleaned = value.trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }
    return '';
  }

  String get moderationLabel {
    switch (moderationStatus.trim().toLowerCase()) {
      case 'pending':
        return 'Under review';
      case 'approved':
        return status.trim().toLowerCase() == 'published'
            ? 'Published'
            : 'Approved';
      case 'rejected':
        return 'Rejected / Not food-related';
      case 'failed':
        return 'Review failed';
    }
    return status.trim().isEmpty ? 'Draft' : status;
  }

  bool get canAppearPublished {
    final normalizedStatus = status.trim().toLowerCase();
    final normalizedModeration = moderationStatus.trim().toLowerCase();
    return streamReady &&
        normalizedStatus == 'published' &&
        (normalizedModeration.isEmpty || normalizedModeration == 'approved');
  }

  factory RestaurantVideoItem.fromJson(Map<String, dynamic> json) {
    return RestaurantVideoItem(
      id: _readString(json['id']) ?? '',
      title: _readString(json['title']) ?? 'Video',
      description: _readString(json['description']) ?? '',
      mediaUrl: _readString(json['media_url']) ?? '',
      thumbnailUrl: _readString(json['thumbnail_url']) ?? '',
      streamHlsUrl: _readString(json['stream_hls_url']) ?? '',
      hlsUrl: _readString(json['hls_url']) ?? '',
      playbackUrlValue: _readString(json['playback_url']) ?? '',
      videoUrl: _readString(json['video_url']) ?? '',
      streamPreviewUrl: _readString(json['stream_preview_url']) ?? '',
      status: _readString(json['status']) ?? '',
      moderationStatus: _readString(json['moderation_status']) ?? '',
      moderationReason: _readString(json['moderation_reason']) ?? '',
      streamReady: _readBool(json['stream_ready']) ?? true,
      viewsCount: _readInt(json['views_count']) ?? 0,
      likesCount: _readInt(json['likes_count']) ?? 0,
      sharesCount: _readInt(json['shares_count']) ?? 0,
      createdAt: _readDate(json['created_at']),
      publishedAt: _readDate(json['published_at']),
    );
  }
}

class RestaurantReviewSummary {
  const RestaurantReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.pendingReplyCount,
    required this.repliedCount,
  });

  final double averageRating;
  final int totalReviews;
  final int pendingReplyCount;
  final int repliedCount;

  factory RestaurantReviewSummary.fromJson(Map<String, dynamic> json) {
    return RestaurantReviewSummary(
      averageRating: _readDouble(json['average_rating']) ?? 0,
      totalReviews: _readInt(json['total_reviews']) ?? 0,
      pendingReplyCount: _readInt(json['pending_reply_count']) ?? 0,
      repliedCount: _readInt(json['replied_count']) ?? 0,
    );
  }
}

class RestaurantReviewItem {
  const RestaurantReviewItem({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.reply,
    required this.orderId,
    this.createdAt,
  });

  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final String reply;
  final String orderId;
  final DateTime? createdAt;

  factory RestaurantReviewItem.fromJson(Map<String, dynamic> json) {
    final customer = _stringMap(json['customer']);
    return RestaurantReviewItem(
      id: _readString(json['id']) ?? '',
      customerName: _readString(customer['name']) ?? 'Customer',
      rating: _readInt(json['rating']) ?? 0,
      comment: _readString(json['comment']) ?? '',
      reply: _readString(json['reply']) ?? '',
      orderId: _readString(json['order_id']) ?? '',
      createdAt: _readDate(json['created_at']),
    );
  }
}

class RestaurantOwnerApiException implements Exception {
  const RestaurantOwnerApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _extractObject(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is Map) {
    return _stringMap(data);
  }
  return payload;
}

List<Map<String, dynamic>> _extractListFromObject(
  Map<String, dynamic> payload,
) {
  final candidates = <dynamic>[
    payload['data'],
    payload['items'],
    payload['videos'],
    payload['reviews'],
    payload['data'] is Map ? payload['data']['data'] : null,
    payload['data'] is Map ? payload['data']['items'] : null,
  ];
  for (final candidate in candidates) {
    final parsed = _listOfMaps(candidate);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.whereType<Map>().map(_stringMap).toList(growable: false);
}

Map<String, dynamic> _stringMap(dynamic value) {
  if (value is! Map) {
    return <String, dynamic>{};
  }
  final result = <String, dynamic>{};
  value.forEach((key, item) {
    if (key is String) {
      result[key] = item;
    }
  });
  return result;
}

Map<String, int> _intMap(Map<String, dynamic> input) {
  final result = <String, int>{};
  for (final entry in input.entries) {
    result[entry.key] = _readInt(entry.value) ?? 0;
  }
  return result;
}

void _throwForFailure(
  int statusCode,
  Map<String, dynamic> payload, {
  required String fallback,
}) {
  if (statusCode >= 200 && statusCode < 300) {
    return;
  }
  throw RestaurantOwnerApiException(
    '${ApiClient.errorMessageForStatus(statusCode, payload, fallback: fallback)} (HTTP $statusCode)',
  );
}

String? _readString(dynamic value) {
  if (value is String) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }
  if (value is num) {
    return value.toString();
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

bool? _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}

DateTime? _readDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toLocal();
  }
  return null;
}

bool _isHlsUrl(String value) {
  return value.toLowerCase().contains('.m3u8');
}
