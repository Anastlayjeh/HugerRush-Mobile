import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../config/api_config.dart';
import '../models/auth_session.dart';
import '../models/customer_video_feed_models.dart';
import '../models/demo_app_models.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_service.dart';
import '../services/authenticated_api_client.dart';
import '../services/cart_api_service.dart';
import '../services/conversation_api_service.dart';
import '../services/customer_profile_api_service.dart';
import '../services/customer_restaurant_api_service.dart';
import '../services/customer_video_feed_api_service.dart';
import '../services/demo_app_repository.dart';
import '../services/loyalty_api_service.dart';
import '../services/moderation_support_models.dart';
import '../services/notification_api_service.dart';
import '../services/order_api_service.dart';
import '../services/post_share_service.dart';
import '../services/push_notification_service.dart';
import '../services/restaurant_menu_api_service.dart';
import 'app_support_screens.dart';
import 'login_screen.dart';

part 'customer/customer_home_screen.dart';
part 'customer/customer_messages_screen.dart';
part 'customer/customer_discover_screen.dart';
part 'customer/customer_orders_screen.dart';
part 'customer/customer_profile_screen.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

String _profileEmailFromHandle(String handle) {
  final cleaned = handle.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  return '${cleaned.isEmpty ? 'foodie' : cleaned}@hungerrush.app';
}

String _profileEmail({required String handle, String? email}) {
  final cleanedEmail = email?.trim();
  if (cleanedEmail != null && cleanedEmail.isNotEmpty) {
    return cleanedEmail;
  }
  return _profileEmailFromHandle(handle);
}

bool _looksLikeHttpUrl(String? value) {
  final parsed = Uri.tryParse(value?.trim() ?? '');
  return parsed != null &&
      parsed.hasScheme &&
      (parsed.scheme == 'http' || parsed.scheme == 'https');
}

String _formatCompactCount(int value) {
  if (value >= 1000000) {
    return '${_trimTrailingZero((value / 1000000).toStringAsFixed(1))}M';
  }
  if (value >= 1000) {
    return '${_trimTrailingZero((value / 1000).toStringAsFixed(1))}k';
  }
  return value.toString();
}

String _trimTrailingZero(String value) {
  if (value.endsWith('.0')) {
    return value.substring(0, value.length - 2);
  }
  return value;
}

String _formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) {
    return 'Now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h';
  }
  return '${difference.inDays}d';
}

String _restaurantVideoMeta(CustomerRestaurantVideoItem item) {
  final when = item.publishedAt ?? item.createdAt;
  final timeLabel = when == null
      ? 'Recent'
      : _formatRelativeTime(when.toLocal());
  if (item.viewsCount <= 0) {
    return timeLabel;
  }
  return '${_formatCompactCount(item.viewsCount)} views | $timeLabel';
}

List<RestaurantProfileVideoPreview> _restaurantVideoPreviewsFromItems(
  List<CustomerRestaurantVideoItem> items, {
  AuthSession? session,
}) {
  final videos = items
      .where((item) => item.resolvedPlaybackUrl.trim().isNotEmpty)
      .toList(growable: false);
  final playbackHeaders = _videoPlaybackHeadersForSession(session);
  videos.sort((a, b) {
    final aTime =
        a.publishedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime =
        b.publishedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return videos
      .map((video) {
        final playbackUrls = video.playbackUrls;
        return RestaurantProfileVideoPreview(
          id: video.id,
          title: video.title,
          meta: _restaurantVideoMeta(video),
          thumbnailUrl: ApiConfig.resolveMediaUrl(video.thumbnailUrl),
          videoUrl: playbackUrls.isEmpty ? '' : playbackUrls.first,
          fallbackVideoUrls: playbackUrls.skip(1).toList(growable: false),
          description: video.description,
          httpHeaders: playbackHeaders,
        );
      })
      .toList(growable: false);
}

Map<String, String> _videoPlaybackHeadersForSession(AuthSession? session) {
  final token = session?.token.trim();
  if (token == null || token.isEmpty) {
    return const <String, String>{};
  }
  return Map<String, String>.unmodifiable(<String, String>{
    'Authorization': 'Bearer $token',
  });
}

String _feedCreatorLabel(String restaurantName) {
  final label = restaurantName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .join(' ');
  return (label.isEmpty ? 'HR' : label).toUpperCase();
}

String _feedHandleFromName(String value) {
  final cleaned = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '',
  );
  return cleaned.isEmpty ? 'restaurant' : cleaned;
}

String _feedTagFromName(String value) {
  final cleaned = _feedHandleFromName(value);
  return cleaned.isEmpty ? '#food' : '#$cleaned';
}

List<DemoFeedPost> _followingRestaurantsFromPosts(List<DemoFeedPost> posts) {
  final uniqueByHandle = <String, DemoFeedPost>{};
  for (final post in posts) {
    if (!post.isFollowing) {
      continue;
    }
    final key = post.restaurantHandle.trim().toLowerCase();
    uniqueByHandle[key.isEmpty ? post.id : key] = post;
  }
  final items = uniqueByHandle.values.toList()
    ..sort((a, b) => a.restaurantName.compareTo(b.restaurantName));
  return items;
}

const Map<String, String> _customerRestaurantNamesByThreadId = <String, String>{
  't1': 'Bella Italia',
  't2': 'Smash House',
  't3': 'Cedars Kitchen',
  't4': 'Levant Grill',
  't5': 'Green Bowl',
  't6': 'Falafel Spot',
};
