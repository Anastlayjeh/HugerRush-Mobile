class CustomerVideoFeedPage {
  const CustomerVideoFeedPage({required this.items, required this.meta});

  final List<CustomerVideoFeedItem> items;
  final CustomerVideoFeedMeta meta;

  factory CustomerVideoFeedPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    return CustomerVideoFeedPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => CustomerVideoFeedItem.fromJson(_stringMap(item)))
                .toList(growable: false)
          : const <CustomerVideoFeedItem>[],
      meta: CustomerVideoFeedMeta.fromJson(_stringMap(json['meta'])),
    );
  }
}

class CustomerVideoFeedMeta {
  const CustomerVideoFeedMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage * perPage < total;

  factory CustomerVideoFeedMeta.fromJson(Map<String, dynamic> json) {
    return CustomerVideoFeedMeta(
      currentPage: _readInt(json['current_page']) ?? 1,
      perPage: _readInt(json['per_page']) ?? 15,
      total: _readInt(json['total']) ?? 0,
    );
  }
}

class CustomerVideoFeedItem {
  const CustomerVideoFeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.moderationStatus,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.streamUid,
    required this.durationSeconds,
    required this.streamStatus,
    required this.streamReady,
    required this.streamHlsUrl,
    required this.hlsUrl,
    required this.playbackUrlValue,
    required this.videoUrl,
    required this.streamDashUrl,
    required this.streamPreviewUrl,
    required this.restaurant,
    required this.menuItem,
    required this.stats,
    required this.viewerState,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String moderationStatus;
  final String mediaUrl;
  final String thumbnailUrl;
  final String streamUid;
  final int? durationSeconds;
  final String streamStatus;
  final bool streamReady;
  final String streamHlsUrl;
  final String hlsUrl;
  final String playbackUrlValue;
  final String videoUrl;
  final String streamDashUrl;
  final String streamPreviewUrl;
  final CustomerRestaurantSummary? restaurant;
  final CustomerMenuItemSummary? menuItem;
  final CustomerVideoStats stats;
  final CustomerVideoViewerState viewerState;
  final DateTime? publishedAt;

  String get playbackUrl {
    final candidates =
        <String>[streamHlsUrl, hlsUrl, playbackUrlValue, videoUrl, mediaUrl]
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(growable: false);
    if (candidates.isEmpty) {
      return '';
    }
    for (final candidate in candidates) {
      if (_isHlsUrl(candidate)) {
        return candidate;
      }
    }
    return candidates.first;
  }

  bool get isApprovedForFeed {
    if (!streamReady || playbackUrl.isEmpty) {
      return false;
    }
    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus.isNotEmpty && normalizedStatus != 'published') {
      return false;
    }
    final normalizedModerationStatus = moderationStatus.trim().toLowerCase();
    if (normalizedModerationStatus.isNotEmpty &&
        normalizedModerationStatus != 'approved') {
      return false;
    }
    return true;
  }

  factory CustomerVideoFeedItem.fromJson(Map<String, dynamic> json) {
    final moderation = _stringMap(json['moderation']);
    return CustomerVideoFeedItem(
      id: _readString(json['id']) ?? '',
      title: _readString(json['title']) ?? '',
      description: _readString(json['description']) ?? '',
      status: _readString(json['status']) ?? '',
      moderationStatus:
          _readString(json['moderation_status']) ??
          _readString(json['moderationStatus']) ??
          _readString(moderation['status']) ??
          '',
      mediaUrl: _readString(json['media_url']) ?? '',
      thumbnailUrl: _readString(json['thumbnail_url']) ?? '',
      streamUid: _readString(json['stream_uid']) ?? '',
      durationSeconds: _readInt(json['duration_seconds']),
      streamStatus: _readString(json['stream_status']) ?? '',
      streamReady: _readBool(json['stream_ready']) ?? false,
      streamHlsUrl: _readString(json['stream_hls_url']) ?? '',
      hlsUrl: _readString(json['hls_url']) ?? '',
      playbackUrlValue: _readString(json['playback_url']) ?? '',
      videoUrl: _readString(json['video_url']) ?? '',
      streamDashUrl: _readString(json['stream_dash_url']) ?? '',
      streamPreviewUrl: _readString(json['stream_preview_url']) ?? '',
      restaurant: json['restaurant'] is Map
          ? CustomerRestaurantSummary.fromJson(_stringMap(json['restaurant']))
          : null,
      menuItem: json['menu_item'] is Map
          ? CustomerMenuItemSummary.fromJson(_stringMap(json['menu_item']))
          : null,
      stats: CustomerVideoStats.fromJson(_stringMap(json['stats'])),
      viewerState: CustomerVideoViewerState.fromJson(
        _stringMap(json['viewer_state']),
      ),
      publishedAt: _readDateTime(json['published_at']),
    );
  }
}

class CustomerRestaurantSummary {
  const CustomerRestaurantSummary({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory CustomerRestaurantSummary.fromJson(Map<String, dynamic> json) {
    return CustomerRestaurantSummary(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? 'Restaurant',
      description: _readString(json['description']) ?? '',
    );
  }
}

class CustomerMenuItemSummary {
  const CustomerMenuItemSummary({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double? price;

  factory CustomerMenuItemSummary.fromJson(Map<String, dynamic> json) {
    return CustomerMenuItemSummary(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? '',
      price: _readDouble(json['price']),
    );
  }
}

class CustomerVideoStats {
  const CustomerVideoStats({
    required this.viewsCount,
    required this.likesCount,
    required this.sharesCount,
    required this.savesCount,
    required this.commentsCount,
  });

  final int viewsCount;
  final int likesCount;
  final int sharesCount;
  final int savesCount;
  final int commentsCount;

  factory CustomerVideoStats.fromJson(Map<String, dynamic> json) {
    return CustomerVideoStats(
      viewsCount: _readInt(json['views_count']) ?? 0,
      likesCount: _readInt(json['likes_count']) ?? 0,
      sharesCount: _readInt(json['shares_count']) ?? 0,
      savesCount: _readInt(json['saves_count']) ?? 0,
      commentsCount: _readInt(json['comments_count']) ?? 0,
    );
  }
}

class CustomerVideoViewerState {
  const CustomerVideoViewerState({
    required this.isLiked,
    required this.isSaved,
    required this.isFollowingRestaurant,
    required this.hasCommented,
    required this.viewCount,
  });

  final bool isLiked;
  final bool isSaved;
  final bool isFollowingRestaurant;
  final bool hasCommented;
  final int viewCount;

  factory CustomerVideoViewerState.fromJson(Map<String, dynamic> json) {
    return CustomerVideoViewerState(
      isLiked: _readBool(json['is_liked']) ?? false,
      isSaved: _readBool(json['is_saved']) ?? false,
      isFollowingRestaurant:
          _readBool(json['is_following_restaurant']) ?? false,
      hasCommented: _readBool(json['has_commented']) ?? false,
      viewCount: _readInt(json['view_count']) ?? 0,
    );
  }
}

class CustomerVideoComment {
  const CustomerVideoComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.isRestaurantReply,
  });

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final bool isRestaurantReply;

  factory CustomerVideoComment.fromJson(Map<String, dynamic> json) {
    final user = _stringMap(json['user']);
    final customer = _stringMap(json['customer']);
    final author =
        _readString(json['author_name']) ??
        _readString(user['name']) ??
        _readString(customer['name']) ??
        'Customer';
    return CustomerVideoComment(
      id: _readString(json['id']) ?? '',
      authorName: author,
      body: _readString(json['body']) ?? '',
      createdAt: _readDateTime(json['created_at']) ?? DateTime.now(),
      isRestaurantReply:
          _readBool(json['is_restaurant_reply']) ??
          _readBool(json['from_restaurant']) ??
          false,
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
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

bool _isHlsUrl(String value) {
  return value.toLowerCase().contains('.m3u8');
}
