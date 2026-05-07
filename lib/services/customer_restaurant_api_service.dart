import '../config/api_config.dart';
import '../models/auth_session.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'authenticated_api_client.dart';
import 'restaurant_menu_api_service.dart';

class CustomerRestaurantApiService {
  CustomerRestaurantApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<CustomerRestaurantPage> fetchRestaurants({
    required AuthSession session,
    int page = 1,
    int perPage = 20,
    String? query,
    String? cuisine,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: _endpoint('/v1/customer/restaurants', <String, String>{
        'page': page.toString(),
        'per_page': perPage.clamp(1, 100).toString(),
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (cuisine != null && cuisine.trim().isNotEmpty)
          'cuisine': cuisine.trim(),
      }),
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load restaurants.',
    );

    final restaurants = _extractList(payload)
        .map(_restaurantPayloadFromNode)
        .map(CustomerRestaurantItem.fromJson)
        .toList(growable: false);
    return CustomerRestaurantPage(
      restaurants: restaurants,
      meta: CustomerRestaurantMeta.fromJson(_extractMeta(payload)),
    );
  }

  Future<List<CustomerCuisineCategory>> fetchCuisines({
    required AuthSession session,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/restaurants/cuisines',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load cuisines.',
    );

    return _extractList(
      payload,
    ).map(CustomerCuisineCategory.fromJson).toList(growable: false);
  }

  Future<List<CustomerQuickCravingItem>> fetchQuickCravings({
    required AuthSession session,
    int perPage = 6,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: _endpoint('/v1/customer/quick-cravings', <String, String>{
        'per_page': perPage.clamp(1, 20).toString(),
      }),
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load quick cravings.',
    );

    return _extractList(
      payload,
    ).map(CustomerQuickCravingItem.fromJson).toList(growable: false);
  }

  Future<List<CustomerRestaurantItem>> fetchFollowing({
    required AuthSession session,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/restaurants/following',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load followed restaurants.',
    );

    return _extractList(payload)
        .map(_restaurantPayloadFromNode)
        .map(CustomerRestaurantItem.fromJson)
        .toList(growable: false);
  }

  Future<CustomerRestaurantItem> fetchRestaurant({
    required AuthSession session,
    required String restaurantId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      throw const AuthApiException('Restaurant is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load restaurant.',
    );

    final data = payload['data'];
    return CustomerRestaurantItem.fromJson(
      data is Map ? _restaurantPayloadFromNode(_stringMap(data)) : payload,
    );
  }

  Future<void> followRestaurant({
    required AuthSession session,
    required String restaurantId,
  }) {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return Future<void>.value();
    }
    return _requestVoid(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/follow',
      fallback: 'Failed to follow restaurant.',
    );
  }

  Future<void> unfollowRestaurant({
    required AuthSession session,
    required String restaurantId,
  }) {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return Future<void>.value();
    }
    return _requestVoid(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/follow',
      fallback: 'Failed to unfollow restaurant.',
    );
  }

  Future<List<RestaurantMenuItem>> fetchRestaurantMenu({
    required AuthSession session,
    required String restaurantId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return const <RestaurantMenuItem>[];
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/menu',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load restaurant menu.',
    );

    final data = _stringMap(payload['data']);
    final menuItems = _extractNestedList(data, const ['menu_items']);
    if (menuItems.isNotEmpty) {
      return menuItems.map(RestaurantMenuItem.fromJson).toList(growable: false);
    }

    final categoryItems = <Map<String, dynamic>>[];
    for (final category in _extractNestedList(data, const ['categories'])) {
      categoryItems.addAll(_extractNestedList(category, const ['items']));
    }
    return categoryItems
        .map(RestaurantMenuItem.fromJson)
        .toList(growable: false);
  }

  Future<List<CustomerRestaurantVideoItem>> fetchRestaurantVideos({
    required AuthSession session,
    required String restaurantId,
    int page = 1,
    int perPage = 20,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return const <CustomerRestaurantVideoItem>[];
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: _endpoint(
        '/v1/customer/restaurants/$cleanedRestaurantId/videos',
        <String, String>{
          'page': page.toString(),
          'per_page': perPage.clamp(1, 50).toString(),
        },
      ),
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load restaurant videos.',
    );

    return _extractList(
      payload,
    ).map(CustomerRestaurantVideoItem.fromJson).toList(growable: false);
  }

  Future<List<CustomerRestaurantReviewItem>> fetchRestaurantReviews({
    required AuthSession session,
    required String restaurantId,
    int page = 1,
    int perPage = 20,
    int? rating,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return const <CustomerRestaurantReviewItem>[];
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: _endpoint(
        '/v1/customer/restaurants/$cleanedRestaurantId/reviews',
        <String, String>{
          'page': page.toString(),
          'per_page': perPage.clamp(1, 50).toString(),
          if (rating != null && rating >= 1 && rating <= 5)
            'rating': rating.toString(),
        },
      ),
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load restaurant reviews.',
    );

    return _extractList(
      payload,
    ).map(CustomerRestaurantReviewItem.fromJson).toList(growable: false);
  }

  Future<CustomerRestaurantReviewItem> submitRestaurantReview({
    required AuthSession session,
    required String restaurantId,
    required int rating,
    String? comment,
    String? orderId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      throw const AuthApiException('Restaurant is required.');
    }
    final normalizedRating = rating.clamp(1, 5);
    final cleanedComment = (comment ?? '').trim();
    final cleanedOrderId = (orderId ?? '').trim();
    final body = <String, dynamic>{
      'rating': normalizedRating,
      if (cleanedComment.isNotEmpty) 'comment': cleanedComment,
      if (cleanedOrderId.isNotEmpty) 'order_id': cleanedOrderId,
    };

    final result = await _apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/reviews',
      body: body,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to submit review.',
    );

    final data = _stringMap(payload['data']);
    return CustomerRestaurantReviewItem.fromJson(data.isEmpty ? payload : data);
  }

  String _endpoint(String path, Map<String, String> queryParameters) {
    final cleaned = <String, String>{};
    for (final entry in queryParameters.entries) {
      if (entry.value.trim().isNotEmpty) {
        cleaned[entry.key] = entry.value;
      }
    }
    if (cleaned.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: cleaned).toString();
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map>().map(_stringMap).toList(growable: false);
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map(_stringMap)
          .toList(growable: false);
    }
    if (data is Map && data['restaurants'] is List) {
      return (data['restaurants'] as List)
          .whereType<Map>()
          .map(_stringMap)
          .toList(growable: false);
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map(_stringMap)
          .toList(growable: false);
    }
    if (payload['restaurants'] is List) {
      return (payload['restaurants'] as List)
          .whereType<Map>()
          .map(_stringMap)
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _extractNestedList(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        return value.whereType<Map>().map(_stringMap).toList(growable: false);
      }
      if (value is Map && value['data'] is List) {
        return (value['data'] as List)
            .whereType<Map>()
            .map(_stringMap)
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
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

  Map<String, dynamic> _restaurantPayloadFromNode(Map<String, dynamic> node) {
    final restaurant = node['restaurant'];
    if (restaurant is Map) {
      final mapped = _stringMap(restaurant);
      mapped['is_following'] = true;
      return mapped;
    }
    return node;
  }

  Map<String, dynamic> _extractMeta(Map<String, dynamic> payload) {
    final direct = _stringMap(payload['meta']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final data = _stringMap(payload['data']);
    return _stringMap(data['meta']);
  }

  Future<void> _requestVoid({
    required AuthSession session,
    required String method,
    required String endpoint,
    required String fallback,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: method,
      endpoint: endpoint,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(result.response.statusCode, payload, fallback: fallback);
  }

  void _throwForFailure(
    int statusCode,
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    if (statusCode == 401) {
      throw const AuthApiException(
        'Your session expired. Please log in again.',
      );
    }
    if (statusCode == 403) {
      throw const AuthApiException(
        'You do not have permission to perform this action.',
      );
    }
    throw AuthApiException(
      '${ApiClient.errorMessageForStatus(statusCode, payload, fallback: fallback)} (HTTP $statusCode)',
    );
  }
}

class CustomerRestaurantPage {
  const CustomerRestaurantPage({required this.restaurants, required this.meta});

  final List<CustomerRestaurantItem> restaurants;
  final CustomerRestaurantMeta meta;
}

class CustomerRestaurantMeta {
  const CustomerRestaurantMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage * perPage < total;

  factory CustomerRestaurantMeta.fromJson(Map<String, dynamic> json) {
    return CustomerRestaurantMeta(
      currentPage: _readInt(json['current_page']) ?? 1,
      perPage: _readInt(json['per_page']) ?? 20,
      total: _readInt(json['total']) ?? 0,
    );
  }
}

class CustomerCuisineCategory {
  const CustomerCuisineCategory({required this.title, required this.count});

  final String title;
  final int count;

  factory CustomerCuisineCategory.fromJson(Map<String, dynamic> json) {
    return CustomerCuisineCategory(
      title:
          _firstString(json, const ['title', 'label', 'name', 'cuisine']) ??
          'Restaurants',
      count:
          _readInt(json['restaurants_count']) ??
          _readInt(json['count']) ??
          _readInt(json['total']) ??
          0,
    );
  }
}

class CustomerQuickCravingItem {
  const CustomerQuickCravingItem({
    required this.menuItem,
    required this.restaurant,
  });

  final RestaurantMenuItem menuItem;
  final CustomerRestaurantItem restaurant;

  factory CustomerQuickCravingItem.fromJson(Map<String, dynamic> json) {
    final menuItem = _stringMap(json['menu_item']);
    final restaurant = _stringMap(json['restaurant']);
    return CustomerQuickCravingItem(
      menuItem: RestaurantMenuItem.fromJson(menuItem.isEmpty ? json : menuItem),
      restaurant: CustomerRestaurantItem.fromJson(restaurant),
    );
  }
}

class CustomerRestaurantItem {
  const CustomerRestaurantItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.categoryLabel,
    required this.profilePhotoUrl,
    required this.address,
    required this.phone,
    required this.averageRating,
    required this.reviewsCount,
    required this.followersCount,
    required this.menuItemsCount,
    required this.ordersCount,
    required this.isFollowing,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final String categoryLabel;
  final String profilePhotoUrl;
  final String address;
  final String phone;
  final double? averageRating;
  final int reviewsCount;
  final int followersCount;
  final int menuItemsCount;
  final int ordersCount;
  final bool isFollowing;

  factory CustomerRestaurantItem.fromJson(Map<String, dynamic> json) {
    final settings = _stringMap(json['settings']);
    return CustomerRestaurantItem(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? 'Restaurant',
      description: _readString(json['description']) ?? '',
      status: _readString(json['status']) ?? '',
      categoryLabel:
          _firstString(json, const ['category', 'cuisine', 'type']) ??
          _firstString(settings, const [
            'category',
            'cuisine',
            'cuisine_type',
            'food_type',
          ]) ??
          'Restaurants',
      profilePhotoUrl:
          _readString(json['profile_photo_url']) ??
          _firstString(settings, const [
            'profile_photo_url',
            'cover_image_url',
            'image_url',
            'photo_url',
          ]) ??
          '',
      address: _readString(json['address']) ?? '',
      phone: _readString(json['phone']) ?? '',
      averageRating: _readDouble(json['average_rating']),
      reviewsCount: _readInt(json['reviews_count']) ?? 0,
      followersCount:
          _readInt(json['followers_count']) ??
          _readInt(json['follows_count']) ??
          _readInt(json['followers']) ??
          0,
      menuItemsCount: _readInt(json['menu_items_count']) ?? 0,
      ordersCount: _readInt(json['orders_count']) ?? 0,
      isFollowing:
          _readBool(json['is_following']) ??
          _readBool(json['is_following_restaurant']) ??
          _readBool(json['followed']) ??
          false,
    );
  }
}

class CustomerRestaurantVideoItem {
  const CustomerRestaurantVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.streamHlsUrl,
    required this.hlsUrl,
    required this.playbackUrl,
    required this.videoUrl,
    required this.mediaUrl,
    required this.streamPreviewUrl,
    required this.streamReady,
    required this.status,
    required this.moderationStatus,
    required this.createdAt,
    required this.publishedAt,
    required this.viewsCount,
    required this.likesCount,
    required this.sharesCount,
    required this.commentsCount,
  });

  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String streamHlsUrl;
  final String hlsUrl;
  final String playbackUrl;
  final String videoUrl;
  final String mediaUrl;
  final String streamPreviewUrl;
  final bool streamReady;
  final String status;
  final String moderationStatus;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final int viewsCount;
  final int likesCount;
  final int sharesCount;
  final int commentsCount;

  List<String> get playbackUrls {
    final streamCandidates = <String>[streamHlsUrl, hlsUrl, playbackUrl]
        .map(ApiConfig.resolveMediaUrl)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    final directCandidates = <String>[playbackUrl, videoUrl, mediaUrl]
        .map(ApiConfig.resolveMediaUrl)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    final ordered = streamReady
        ? <String>[
            ...streamCandidates.where(_isHlsUrl),
            ...directCandidates.where((url) => !_isHlsUrl(url)),
            ...streamCandidates.where((url) => !_isHlsUrl(url)),
            ...directCandidates.where(_isHlsUrl),
          ]
        : <String>[
            ...directCandidates.where((url) => !_isHlsUrl(url)),
            ...streamCandidates.where((url) => !_isHlsUrl(url)),
            ...streamCandidates.where(_isHlsUrl),
            ...directCandidates.where(_isHlsUrl),
          ];

    return _distinctStrings(ordered);
  }

  String get resolvedPlaybackUrl {
    final candidates = playbackUrls;
    if (candidates.isEmpty) {
      return '';
    }
    return candidates.first;
  }

  factory CustomerRestaurantVideoItem.fromJson(Map<String, dynamic> json) {
    final stats = _stringMap(json['stats']);
    return CustomerRestaurantVideoItem(
      id: _readString(json['id']) ?? '',
      title: _readString(json['title']) ?? 'Untitled video',
      description: _readString(json['description']) ?? '',
      thumbnailUrl: _readString(json['thumbnail_url']) ?? '',
      streamHlsUrl: _readString(json['stream_hls_url']) ?? '',
      hlsUrl: _readString(json['hls_url']) ?? '',
      playbackUrl: _readString(json['playback_url']) ?? '',
      videoUrl: _readString(json['video_url']) ?? '',
      mediaUrl: _readString(json['media_url']) ?? '',
      streamPreviewUrl: _readString(json['stream_preview_url']) ?? '',
      streamReady: _readBool(json['stream_ready']) ?? true,
      status: _readString(json['status']) ?? '',
      moderationStatus: _readString(json['moderation_status']) ?? '',
      createdAt: _readDateTime(json['created_at']),
      publishedAt: _readDateTime(json['published_at']),
      viewsCount:
          _readInt(stats['views_count']) ?? _readInt(json['views_count']) ?? 0,
      likesCount:
          _readInt(stats['likes_count']) ?? _readInt(json['likes_count']) ?? 0,
      sharesCount:
          _readInt(stats['shares_count']) ??
          _readInt(json['shares_count']) ??
          0,
      commentsCount:
          _readInt(stats['comments_count']) ??
          _readInt(json['comments_count']) ??
          0,
    );
  }
}

class CustomerRestaurantReviewItem {
  const CustomerRestaurantReviewItem({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.orderLabel,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final String orderLabel;
  final DateTime createdAt;

  factory CustomerRestaurantReviewItem.fromJson(Map<String, dynamic> json) {
    final customer = _stringMap(json['customer']);
    final orderId = _readString(json['order_id']) ?? '';
    final fallbackId = _readString(json['id']) ?? orderId;
    return CustomerRestaurantReviewItem(
      id: fallbackId,
      customerName: _readString(customer['name']) ?? 'Customer',
      rating: _readDouble(json['rating']) ?? 0,
      comment: _readString(json['comment']) ?? '',
      orderLabel: orderId.isEmpty ? '--' : '#$orderId',
      createdAt: _readDateTime(json['created_at']) ?? DateTime.now(),
    );
  }
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

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _readString(map[key]);
    if (value != null) {
      return value;
    }
  }
  return null;
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

DateTime? _readDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

bool _isHlsUrl(String value) {
  return value.toLowerCase().contains('.m3u8');
}

List<String> _distinctStrings(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    if (seen.add(value)) {
      result.add(value);
    }
  }
  return result;
}
