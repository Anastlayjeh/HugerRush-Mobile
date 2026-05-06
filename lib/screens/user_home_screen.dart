import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

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

List<RestaurantProfileReviewPreview> _buildDemoRestaurantReviews({
  required String restaurantName,
  required double rating,
}) {
  final base = rating.clamp(3.8, 5.0).toDouble();
  return <RestaurantProfileReviewPreview>[
    RestaurantProfileReviewPreview(
      customerName: 'Lina M.',
      rating: base,
      comment: 'Great food quality and clean packaging.',
      timeLabel: '2h ago',
      orderLabel: '#4731',
    ),
    RestaurantProfileReviewPreview(
      customerName: 'Karim D.',
      rating: (base - 0.1).clamp(3.6, 5.0).toDouble(),
      comment: 'Fast delivery and fresh taste from $restaurantName.',
      timeLabel: 'Yesterday',
      orderLabel: '#4728',
    ),
    RestaurantProfileReviewPreview(
      customerName: 'Maya K.',
      rating: (base + 0.1).clamp(3.6, 5.0).toDouble(),
      comment: 'Very good portions, will order again.',
      timeLabel: '2d ago',
      orderLabel: '#4722',
    ),
  ];
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

List<DemoFeedPost> _customerFeedPostsSnapshot(DemoAppRepository repository) {
  return <DemoFeedPost>[
    repository.getFeedPost(following: false),
    repository.getFeedPost(following: true),
  ];
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

String _savedPlaceKey({required String title, required String handle}) {
  final normalizedHandle = handle.trim().toLowerCase();
  if (normalizedHandle.isNotEmpty) {
    return normalizedHandle;
  }
  return title.trim().toLowerCase();
}

IconData _discoverSpotIcon(String categoryTitle) {
  switch (categoryTitle.trim().toLowerCase()) {
    case 'pizza':
      return Icons.local_pizza_rounded;
    case 'burgers':
      return Icons.lunch_dining_rounded;
    case 'sushi':
      return Icons.set_meal_rounded;
    case 'desserts':
      return Icons.icecream_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}

_SavedPlaceData _savedPlaceFromDiscoverSpot(_DiscoverSpotData spot) {
  return _SavedPlaceData(
    title: spot.title,
    subtitle: '${spot.categoryTitle} - ${spot.deliveryLabel}',
    handle: spot.handle,
    rating: spot.ratingValue,
    caption: spot.subtitle,
    cuisineSummary: '${spot.categoryTitle} Kitchen',
    phoneLabel: '+961 1 554 100',
    locationLabel: 'Nearby you',
    followersCount: 8400 + (spot.deliveryMinutes * 28),
    icon: _discoverSpotIcon(spot.categoryTitle),
  );
}

_SavedPlaceData _savedPlaceFromFeedPost(DemoFeedPost post) {
  return _SavedPlaceData(
    title: post.restaurantName,
    subtitle: 'Saved from profile - @${post.restaurantHandle}',
    handle: post.restaurantHandle,
    rating: post.rating,
    caption: post.caption,
    cuisineSummary: 'Trending Restaurant',
    phoneLabel: '+961 1 554 100',
    locationLabel: 'Saved from feed',
    followersCount: post.followersCount,
    icon: Icons.restaurant_rounded,
  );
}

List<_SavedPlaceData> _savedPlacesFromHeartedRestaurants({
  required DemoAppRepository repository,
  required Set<String> favoriteSpotTitles,
}) {
  final savedByKey = <String, _SavedPlaceData>{};
  final normalizedFavoriteTitles = favoriteSpotTitles
      .map((title) => title.trim().toLowerCase())
      .toSet();

  for (final spot in _DiscoverTabBody._popularSpots) {
    final key = spot.title.trim().toLowerCase();
    final savedFromDiscoverHeart = normalizedFavoriteTitles.contains(key);
    final savedFromProfileHeart = isCustomerRestaurantSaved(
      restaurantName: spot.title,
      handle: spot.handle,
    );
    if (!savedFromDiscoverHeart && !savedFromProfileHeart) {
      continue;
    }
    final saved = _savedPlaceFromDiscoverSpot(spot);
    savedByKey[_savedPlaceKey(title: saved.title, handle: saved.handle)] =
        saved;
  }

  for (final post in _customerFeedPostsSnapshot(repository)) {
    if (!isCustomerRestaurantSaved(
      restaurantName: post.restaurantName,
      handle: post.restaurantHandle,
    )) {
      continue;
    }
    final saved = _savedPlaceFromFeedPost(post);
    savedByKey[_savedPlaceKey(title: saved.title, handle: saved.handle)] =
        saved;
  }

  final items = savedByKey.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));
  return items;
}
