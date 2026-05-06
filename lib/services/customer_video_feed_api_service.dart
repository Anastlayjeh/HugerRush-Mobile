import '../models/auth_session.dart';
import '../models/customer_video_feed_models.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'authenticated_api_client.dart';

class CustomerVideoFeedApiService {
  CustomerVideoFeedApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<CustomerVideoFeedPage> fetchFeed({
    required AuthSession session,
    int page = 1,
    int perPage = 15,
    String? query,
    bool debug = false,
  }) async {
    final endpoint = _endpoint('/v1/customer/videos/feed', <String, String>{
      'page': page.toString(),
      'per_page': perPage.clamp(1, 30).toString(),
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (debug) 'debug': '1',
    });
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: endpoint,
    );
    final payload = _decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load your video feed.',
    );
    final parsedPage = CustomerVideoFeedPage.fromJson(payload);
    return CustomerVideoFeedPage(
      items: parsedPage.items
          .where((item) => item.isApprovedForFeed)
          .toList(growable: false),
      meta: parsedPage.meta,
    );
  }

  Future<void> recordSearch({
    required AuthSession session,
    required String query,
    String context = 'video_feed',
  }) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) {
      return;
    }
    await _requestVoid(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/videos/searches',
      body: <String, dynamic>{'query': cleaned, 'context': context},
      fallback: 'Failed to record search.',
    );
  }

  Future<CustomerVideoEngagementSummary?> recordEngagement({
    required AuthSession session,
    required String videoId,
    required String type,
  }) async {
    final cleanedVideoId = videoId.trim();
    if (cleanedVideoId.isEmpty) {
      return null;
    }
    final payload = await _requestMap(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/videos/$cleanedVideoId/engagements',
      body: <String, dynamic>{'type': type},
      fallback: 'Failed to update video engagement.',
    );
    return CustomerVideoEngagementSummary.fromPayload(payload);
  }

  Future<CustomerVideoEngagementSummary?> removeEngagement({
    required AuthSession session,
    required String videoId,
    required String type,
  }) async {
    final cleanedVideoId = videoId.trim();
    final cleanedType = type.trim();
    if (cleanedVideoId.isEmpty || cleanedType.isEmpty) {
      return null;
    }
    final payload = await _requestMap(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/customer/videos/$cleanedVideoId/engagements/$cleanedType',
      fallback: 'Failed to update video engagement.',
    );
    return CustomerVideoEngagementSummary.fromPayload(payload);
  }

  Future<List<CustomerVideoComment>> fetchComments({
    required AuthSession session,
    required String videoId,
  }) async {
    final cleanedVideoId = videoId.trim();
    if (cleanedVideoId.isEmpty) {
      return const <CustomerVideoComment>[];
    }
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/videos/$cleanedVideoId/comments',
    );
    final payload = _decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load comments.',
    );
    return _extractList(
      payload,
    ).map(CustomerVideoComment.fromJson).toList(growable: false);
  }

  Future<CustomerVideoComment?> postComment({
    required AuthSession session,
    required String videoId,
    required String body,
  }) async {
    final cleanedVideoId = videoId.trim();
    final cleanedBody = body.trim();
    if (cleanedVideoId.isEmpty || cleanedBody.isEmpty) {
      return null;
    }
    final result = await _apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/videos/$cleanedVideoId/comments',
      body: <String, dynamic>{'body': cleanedBody},
    );
    final payload = _decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to send comment.',
    );
    final data = payload['data'];
    if (data is Map) {
      return CustomerVideoComment.fromJson(_stringMap(data));
    }
    return null;
  }

  Future<List<CustomerRestaurantSummary>> fetchFollowing({
    required AuthSession session,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/restaurants/following',
    );
    final payload = _decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load followed restaurants.',
    );
    return _extractList(
      payload,
    ).map(CustomerRestaurantSummary.fromJson).toList(growable: false);
  }

  Future<void> followRestaurant({
    required AuthSession session,
    required String restaurantId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return;
    }
    await _requestVoid(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/follow',
      fallback: 'Failed to follow restaurant.',
    );
  }

  Future<void> unfollowRestaurant({
    required AuthSession session,
    required String restaurantId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return;
    }
    await _requestVoid(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/follow',
      fallback: 'Failed to unfollow restaurant.',
    );
  }

  Future<void> _requestVoid({
    required AuthSession session,
    required String method,
    required String endpoint,
    Object? body,
    required String fallback,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: method,
      endpoint: endpoint,
      body: body,
    );
    _throwForFailure(
      result.response.statusCode,
      _decodeMap(result.response.body),
      fallback: fallback,
    );
  }

  Future<Map<String, dynamic>> _requestMap({
    required AuthSession session,
    required String method,
    required String endpoint,
    Object? body,
    required String fallback,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: method,
      endpoint: endpoint,
      body: body,
    );
    final payload = _decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: fallback,
    );
    return payload;
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

  Map<String, dynamic> _decodeMap(String body) {
    return ApiClient.decodeMap(body);
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
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _stringMap(Map value) {
    final result = <String, dynamic>{};
    value.forEach((key, item) {
      if (key is String) {
        result[key] = item;
      }
    });
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
