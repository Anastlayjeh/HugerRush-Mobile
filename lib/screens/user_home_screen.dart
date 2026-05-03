import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/auth_session.dart';
import '../models/demo_app_models.dart';
import '../services/auth_session_service.dart';
import '../services/conversation_api_service.dart';
import '../services/customer_api_service.dart';
import '../services/demo_app_repository.dart';
import '../services/restaurant_menu_api_service.dart';
import '../services/support_report_api_service.dart';
import 'app_support_screens.dart';
import 'login_screen.dart';

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

String _reviewTimeLabel(DateTime createdAt) {
  final delta = DateTime.now().difference(createdAt);
  if (delta.inMinutes < 1) {
    return 'Just now';
  }
  if (delta.inHours < 1) {
    return '${delta.inMinutes}m ago';
  }
  if (delta.inDays < 1) {
    return '${delta.inHours}h ago';
  }
  if (delta.inDays == 1) {
    return 'Yesterday';
  }
  return '${delta.inDays}d ago';
}

List<RestaurantProfileReviewPreview> _reviewPreviewsFromComments({
  required List<DemoComment> comments,
  required double baseRating,
}) {
  return comments
      .asMap()
      .entries
      .map((entry) {
        final index = entry.key;
        final comment = entry.value;
        final ratingAdjustment = ((index % 3) - 1) * 0.1;
        final simulatedRating = (baseRating + ratingAdjustment).clamp(3.6, 5.0);
        return RestaurantProfileReviewPreview(
          customerName: comment.authorName,
          rating: simulatedRating.toDouble(),
          comment: comment.body,
          timeLabel: _reviewTimeLabel(comment.createdAt),
          orderLabel: '#47${20 + index}',
        );
      })
      .toList(growable: false);
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

enum _OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  onTheWay,
  delivered,
  canceled,
  rejected,
}

const List<_OrderStatus> _orderStatusFlow = [
  _OrderStatus.pending,
  _OrderStatus.accepted,
  _OrderStatus.preparing,
  _OrderStatus.ready,
  _OrderStatus.onTheWay,
  _OrderStatus.delivered,
];

String _orderStatusLabel(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.pending:
      return 'Pending';
    case _OrderStatus.accepted:
      return 'Accepted';
    case _OrderStatus.preparing:
      return 'Preparing';
    case _OrderStatus.ready:
      return 'Ready';
    case _OrderStatus.onTheWay:
      return 'On the way';
    case _OrderStatus.delivered:
      return 'Delivered';
    case _OrderStatus.canceled:
      return 'Canceled';
    case _OrderStatus.rejected:
      return 'Rejected';
  }
}

String _orderStatusDescription(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.pending:
      return 'Your order has been placed and is waiting for review.';
    case _OrderStatus.accepted:
      return 'The restaurant accepted your order and queued it up.';
    case _OrderStatus.preparing:
      return 'The kitchen is preparing your food right now.';
    case _OrderStatus.ready:
      return 'Your order is packed and ready for pickup.';
    case _OrderStatus.onTheWay:
      return 'A rider is heading to you with your order.';
    case _OrderStatus.delivered:
      return 'Your delivery was completed successfully.';
    case _OrderStatus.canceled:
      return 'This order was canceled before delivery was completed.';
    case _OrderStatus.rejected:
      return 'The restaurant rejected this order request.';
  }
}

Color _orderStatusAccentColor(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.pending:
      return const Color(0xFFB56A45);
    case _OrderStatus.accepted:
      return const Color(0xFFFF8A57);
    case _OrderStatus.preparing:
      return const Color(0xFFE5A535);
    case _OrderStatus.ready:
      return const Color(0xFF2F8A7E);
    case _OrderStatus.onTheWay:
      return const Color(0xFFFF7E4D);
    case _OrderStatus.delivered:
      return const Color(0xFF2F8A7E);
    case _OrderStatus.canceled:
      return const Color(0xFFC8674C);
    case _OrderStatus.rejected:
      return const Color(0xFFB7372B);
  }
}

Color _orderStatusBackgroundColor(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.pending:
      return const Color(0xFFFFF4EC);
    case _OrderStatus.accepted:
      return const Color(0xFFFFF1E7);
    case _OrderStatus.preparing:
      return const Color(0xFFFFF6E7);
    case _OrderStatus.ready:
      return const Color(0xFFF1F8F5);
    case _OrderStatus.onTheWay:
      return const Color(0xFFFFF0E6);
    case _OrderStatus.delivered:
      return const Color(0xFFF1F8F5);
    case _OrderStatus.canceled:
      return const Color(0xFFFFF1EC);
    case _OrderStatus.rejected:
      return const Color(0xFFFDECEA);
  }
}

IconData _orderStatusIcon(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.pending:
      return Icons.pending_actions_rounded;
    case _OrderStatus.accepted:
      return Icons.receipt_long_rounded;
    case _OrderStatus.preparing:
      return Icons.restaurant_rounded;
    case _OrderStatus.ready:
      return Icons.inventory_2_rounded;
    case _OrderStatus.onTheWay:
      return Icons.delivery_dining_rounded;
    case _OrderStatus.delivered:
      return Icons.check_circle_rounded;
    case _OrderStatus.canceled:
      return Icons.cancel_rounded;
    case _OrderStatus.rejected:
      return Icons.highlight_off_rounded;
  }
}

double _orderStatusProgress(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.pending:
      return 0.12;
    case _OrderStatus.accepted:
      return 0.28;
    case _OrderStatus.preparing:
      return 0.46;
    case _OrderStatus.ready:
      return 0.66;
    case _OrderStatus.onTheWay:
      return 0.82;
    case _OrderStatus.delivered:
      return 1;
    case _OrderStatus.canceled:
      return 0.16;
    case _OrderStatus.rejected:
      return 0.16;
  }
}

bool _orderStatusIsTerminal(_OrderStatus status) {
  return status == _OrderStatus.delivered ||
      status == _OrderStatus.canceled ||
      status == _OrderStatus.rejected;
}

List<_OrderTimelineStepData> _buildOrderTimeline(_OrderStatus status) {
  if (status == _OrderStatus.canceled || status == _OrderStatus.rejected) {
    return [
      _OrderTimelineStepData(
        status: _OrderStatus.pending,
        title: _orderStatusLabel(_OrderStatus.pending),
        subtitle: _orderStatusDescription(_OrderStatus.pending),
        icon: _orderStatusIcon(_OrderStatus.pending),
        isComplete: true,
        isCurrent: false,
      ),
      _OrderTimelineStepData(
        status: status,
        title: _orderStatusLabel(status),
        subtitle: _orderStatusDescription(status),
        icon: _orderStatusIcon(status),
        isComplete: false,
        isCurrent: true,
      ),
    ];
  }

  final currentIndex = _orderStatusFlow.indexOf(status);
  return List.generate(currentIndex + 1, (index) {
    final stepStatus = _orderStatusFlow[index];
    return _OrderTimelineStepData(
      status: stepStatus,
      title: _orderStatusLabel(stepStatus),
      subtitle: _orderStatusDescription(stepStatus),
      icon: _orderStatusIcon(stepStatus),
      isComplete: index < currentIndex,
      isCurrent: index == currentIndex,
    );
  });
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({
    super.key,
    required this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.accountLabel,
    this.authSession,
  });

  final String userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? accountLabel;
  final AuthSession? authSession;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTopTab = 1;
  int _selectedBottomIndex = 0;
  final Set<String> _favoriteDiscoverSpotTitles = <String>{};
  final _customerApiService = CustomerApiService();
  late _EditableCustomerProfileData _customerProfileData;
  List<CustomerRestaurant> _customerRestaurants = const <CustomerRestaurant>[];
  List<CustomerOrder> _customerOrders = const <CustomerOrder>[];
  bool _isLoadingCustomerData = false;
  String? _customerDataError;

  @override
  void initState() {
    super.initState();
    _customerProfileData = _EditableCustomerProfileData.fromUserHome(widget);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _customerApiService.dispose();
    super.dispose();
  }

  String get _authToken => widget.authSession?.token.trim() ?? '';

  Future<void> _loadCustomerData() async {
    final token = _authToken;
    if (token.isEmpty) {
      return;
    }
    setState(() {
      _isLoadingCustomerData = true;
      _customerDataError = null;
    });
    try {
      final results = await Future.wait<Object>([
        _customerApiService.fetchProfile(token: token),
        _customerApiService.fetchRestaurants(token: token),
        _customerApiService.fetchOrderHistory(token: token),
      ]);
      if (!mounted) {
        return;
      }
      final profile = results[0] as CustomerProfile;
      setState(() {
        _customerProfileData = _customerProfileData.copyWith(
          fullName: profile.name,
          email: profile.email,
          phone: profile.phone,
          accountLabel: profile.role,
          avatarUrl: profile.avatarUrl,
        );
        _customerRestaurants = results[1] as List<CustomerRestaurant>;
        _customerOrders = results[2] as List<CustomerOrder>;
        _isLoadingCustomerData = false;
      });
    } on CustomerApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _customerDataError = e.message;
        _isLoadingCustomerData = false;
      });
    }
  }

  String get _userHandle {
    final cleaned = _customerProfileData.fullName.trim();
    if (cleaned.isEmpty) {
      return 'FoodExplorer';
    }
    return cleaned.replaceAll(RegExp(r'\s+'), '');
  }

  void _openProfileMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openCustomerEditProfile() async {
    final updatedData = await Navigator.of(context)
        .push<_EditableCustomerProfileData>(
          MaterialPageRoute<_EditableCustomerProfileData>(
            builder: (_) =>
                _CustomerEditProfileScreen(initialData: _customerProfileData),
          ),
        );

    if (!mounted ||
        updatedData == null ||
        updatedData.matches(_customerProfileData)) {
      return;
    }

    final token = _authToken;
    try {
      if (token.isNotEmpty) {
        final profile = await _customerApiService.updateProfile(
          token: token,
          name: updatedData.fullName,
          email: updatedData.email,
          phone: updatedData.phone,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _customerProfileData = updatedData.copyWith(
            fullName: profile.name,
            email: profile.email,
            phone: profile.phone,
            avatarUrl: profile.avatarUrl,
          );
        });
      } else {
        setState(() {
          _customerProfileData = updatedData;
        });
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
    } on CustomerApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _setDiscoverSpotFavorite(_DiscoverSpotData spot, bool isFavorite) {
    setCustomerRestaurantSaved(
      restaurantName: spot.title,
      handle: spot.handle,
      isSaved: isFavorite,
    );
    setState(() {
      final key = spot.title.trim();
      if (isFavorite) {
        _favoriteDiscoverSpotTitles.add(key);
      } else {
        _favoriteDiscoverSpotTitles.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showDiscover = _selectedBottomIndex == 1;
    final showOrders = _selectedBottomIndex == 2;
    final showMessages = _selectedBottomIndex == 3;
    final showProfile = _selectedBottomIndex == 4;
    final savedPlaces = _savedPlacesFromHeartedRestaurants(
      repository: DemoAppRepository.instance,
      favoriteSpotTitles: _favoriteDiscoverSpotTitles,
    );
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: showProfile || showDiscover || showOrders || showMessages
          ? const Color(0xFFF8EFE5)
          : const Color(0xFF0A2230),
      endDrawer: _UserProfileMenuDrawer(
        userName: _customerProfileData.fullName,
        userEmail: _customerProfileData.nullableEmail,
        userAvatarUrl: _customerProfileData.nullableAvatarUrl,
        userAvatarBytes: _customerProfileData.profilePhotoBytes,
        authToken: _authToken,
        onEditProfile: _openCustomerEditProfile,
      ),
      body: showProfile
          ? _ProfileTabBody(
              userName: _customerProfileData.fullName,
              userHandle: _userHandle,
              userEmail: _customerProfileData.nullableEmail,
              userAvatarUrl: _customerProfileData.nullableAvatarUrl,
              userAvatarBytes: _customerProfileData.profilePhotoBytes,
              accountLabel: _customerProfileData.resolvedAccountLabel,
              savedPlaces: savedPlaces,
              selectedBottomIndex: _selectedBottomIndex,
              onOpenMenu: _openProfileMenu,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : showDiscover
          ? _DiscoverTabBody(
              userName: widget.userName,
              authToken: _authToken,
              restaurants: _customerRestaurants,
              isLoading: _isLoadingCustomerData,
              errorMessage: _customerDataError,
              onRefresh: _loadCustomerData,
              favoriteSpotTitles: _favoriteDiscoverSpotTitles,
              onSetSpotFavorite: _setDiscoverSpotFavorite,
              selectedBottomIndex: _selectedBottomIndex,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : showOrders
          ? _OrdersTabBody(
              userName: widget.userName,
              authToken: _authToken,
              orders: _customerOrders,
              isLoading: _isLoadingCustomerData,
              errorMessage: _customerDataError,
              onRefresh: _loadCustomerData,
              selectedBottomIndex: _selectedBottomIndex,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : showMessages
          ? _MessagesTabBody(
              userName: widget.userName,
              authToken: _authToken,
              selectedBottomIndex: _selectedBottomIndex,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : _FeedTabBody(
              selectedTopTab: _selectedTopTab,
              selectedBottomIndex: _selectedBottomIndex,
              onTopTabSelected: (index) {
                setState(() => _selectedTopTab = index);
              },
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            ),
    );
  }
}

class _FeedTabBody extends StatefulWidget {
  const _FeedTabBody({
    required this.selectedTopTab,
    required this.selectedBottomIndex,
    required this.onTopTabSelected,
    required this.onBottomNavSelected,
  });

  final int selectedTopTab;
  final int selectedBottomIndex;
  final ValueChanged<int> onTopTabSelected;
  final ValueChanged<int> onBottomNavSelected;

  static const List<_FeedVideoPostData> _feedVideos = [
    _FeedVideoPostData(
      videoAssetPath: 'assets/videos/home_video_1.mp4',
      postId: 'for-you',
      priceLabel: '\$14.99',
      cartItemTitle: 'Pepperoni Feast',
      cartItemSubtitle: 'Fresh pepperoni with extra cheese',
      cartItemImageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
      cartItemPrice: 14.99,
    ),
    _FeedVideoPostData(
      videoAssetPath: 'assets/videos/home_video_2.mp4',
      postId: 'following',
      priceLabel: '\$12.40',
      cartItemTitle: 'Garlic Knots',
      cartItemSubtitle: 'Warm knots with herb butter dip',
      cartItemImageUrl:
          'https://images.unsplash.com/photo-1548365328-9f547fb0953a?auto=format&fit=crop&w=900&q=80',
      cartItemPrice: 12.40,
    ),
  ];

  @override
  State<_FeedTabBody> createState() => _FeedTabBodyState();
}

class _FeedTabBodyState extends State<_FeedTabBody> {
  final _demoRepository = DemoAppRepository.instance;
  final Map<String, DemoFeedPost> _feedPostsById = <String, DemoFeedPost>{};
  final Map<String, Offset> _lastDoubleTapOffsetsByPostId = <String, Offset>{};
  final List<_FeedLikeBurstData> _activeLikeBursts = <_FeedLikeBurstData>[];
  final Set<String> _pendingDoubleTapLikePostIds = <String>{};
  late final List<bool> _hasShownOrderNowByVideoIndex;
  late final List<bool> _isOrderNowVisibleByVideoIndex;
  late final List<bool> _wasNearVideoEndByIndex;
  late final List<VideoPlayerController> _videoControllers;
  late final List<bool> _videoErrorLogged;
  int _currentVideoIndex = 0;
  int _nextLikeBurstId = 0;
  bool _isVideoHoldActive = false;

  @override
  void initState() {
    super.initState();
    _syncFeedPosts();
    _hasShownOrderNowByVideoIndex = List<bool>.filled(
      _FeedTabBody._feedVideos.length,
      false,
    );
    _isOrderNowVisibleByVideoIndex = List<bool>.filled(
      _FeedTabBody._feedVideos.length,
      false,
    );
    _wasNearVideoEndByIndex = List<bool>.filled(
      _FeedTabBody._feedVideos.length,
      false,
    );
    _videoControllers = List<VideoPlayerController>.generate(
      _FeedTabBody._feedVideos.length,
      (index) => VideoPlayerController.asset(
        _FeedTabBody._feedVideos[index].videoAssetPath,
      ),
    );
    _videoErrorLogged = List<bool>.filled(_videoControllers.length, false);
    for (var i = 0; i < _videoControllers.length; i++) {
      final controller = _videoControllers[i];
      controller.addListener(() {
        if (_videoErrorLogged[i]) {
          return;
        }
        if (controller.value.hasError) {
          _videoErrorLogged[i] = true;
          debugPrint(
            'Home feed video playback error for index $i: ${controller.value.errorDescription}',
          );
        }
        _handleOrderNowTriggerByVideoProgress(i);
      });
      controller.setLooping(true);
      controller.setVolume(1.0);
      controller
          .initialize()
          .then((_) {
            if (!mounted) {
              return;
            }
            setState(() {});
            _syncVideoPlayback();
          })
          .catchError((error) {
            debugPrint('Home feed video init failed for index $i: $error');
          });
    }
  }

  DemoFeedPost _loadPostForId(String postId) {
    var post = _demoRepository.getFeedPost(following: postId == 'following');
    if (postId == 'following' && post.isLiked) {
      post = post.copyWith(isLiked: false);
    }
    return post;
  }

  void _syncFeedPosts() {
    for (final video in _FeedTabBody._feedVideos) {
      _feedPostsById[video.postId] = _loadPostForId(video.postId);
    }
  }

  DemoFeedPost _postForVideo(_FeedVideoPostData video) {
    return _feedPostsById[video.postId] ?? _loadPostForId(video.postId);
  }

  void _pauseFeedPlayback() {
    for (final controller in _videoControllers) {
      if (!controller.value.isInitialized) {
        continue;
      }
      controller.pause();
    }
  }

  Future<T?> _withFeedPlaybackPaused<T>(Future<T?> Function() action) async {
    _pauseFeedPlayback();
    try {
      return await action();
    } finally {
      if (mounted && widget.selectedBottomIndex == 0) {
        _syncVideoPlayback();
      }
    }
  }

  Future<void> _openSearch() async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
    );
  }

  Future<void> _openNotifications() async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
    );
  }

  Future<void> _openRestaurantDetails(DemoFeedPost post) async {
    final reviewPreviews = _reviewPreviewsFromComments(
      comments: _demoRepository.getComments(post.id),
      baseRating: post.rating,
    );
    await _withFeedPlaybackPaused<void>(
      () => showRestaurantProfilePopup(
        context,
        restaurantName: post.restaurantName,
        handle: post.restaurantHandle,
        rating: post.rating,
        caption: post.caption,
        followersCountLabel:
            '${_formatCompactCount(post.followersCount)} followers',
        allowAddToCart: true,
        showFollowButton: true,
        showSaveButton: true,
        initiallyFollowing: post.isFollowing,
        onToggleFollow: () {
          _toggleFollow(post);
        },
        reviews: reviewPreviews,
        onOpenReviews: () {
          openRestaurantReviewsPage(
            context,
            restaurantName: post.restaurantName,
            rating: post.rating,
            reviews: reviewPreviews,
          );
        },
        onAddToCart: (item) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) {
            return;
          }
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text('${item.title} added to cart')),
          );
        },
      ),
    );
  }

  Future<void> _openRestaurantReviews(DemoFeedPost post) async {
    final reviewPreviews = _reviewPreviewsFromComments(
      comments: _demoRepository.getComments(post.id),
      baseRating: post.rating,
    );
    final resolvedReviews = reviewPreviews.isEmpty
        ? _buildDemoRestaurantReviews(
            restaurantName: post.restaurantName,
            rating: post.rating,
          )
        : reviewPreviews;
    var shouldOpenFullReviewsPage = false;
    await _withFeedPlaybackPaused<void>(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _FeedReviewsBottomSheet(
          restaurantName: post.restaurantName,
          rating: post.rating,
          reviews: resolvedReviews,
          onViewAllReviews: () {
            shouldOpenFullReviewsPage = true;
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
    if (!mounted || !shouldOpenFullReviewsPage) {
      return;
    }
    await _withFeedPlaybackPaused<void>(
      () => openRestaurantReviewsPage(
        context,
        restaurantName: post.restaurantName,
        rating: post.rating,
        reviews: resolvedReviews,
      ),
    );
  }

  Future<void> _toggleFollow(DemoFeedPost post) async {
    final updated = await _demoRepository.toggleFollow(post.id);
    if (!mounted) {
      return;
    }
    setState(() => _feedPostsById[post.id] = updated);
  }

  Future<void> _toggleLike(DemoFeedPost post) async {
    final updated = await _demoRepository.toggleLike(post.id);
    if (!mounted) {
      return;
    }
    setState(() => _feedPostsById[post.id] = updated);
  }

  void _rememberDoubleTapPosition(String postId, TapDownDetails details) {
    _lastDoubleTapOffsetsByPostId[postId] = details.localPosition;
  }

  List<_FeedLikeBurstData> _likeBurstsForPost(String postId) {
    return _activeLikeBursts
        .where((item) => item.postId == postId)
        .toList(growable: false);
  }

  void _spawnTastyLikeBurst({
    required String postId,
    required Offset tapPosition,
    required Size surfaceSize,
  }) {
    final maxWidth = surfaceSize.width <= 0 ? 390.0 : surfaceSize.width;
    final maxHeight = surfaceSize.height <= 0 ? 700.0 : surfaceSize.height;
    final clampedX = maxWidth <= 96
        ? maxWidth / 2
        : tapPosition.dx.clamp(48.0, maxWidth - 48.0).toDouble();
    final clampedY = maxHeight <= 180
        ? maxHeight / 2
        : tapPosition.dy.clamp(90.0, maxHeight - 90.0).toDouble();
    final burst = _FeedLikeBurstData(
      id: _nextLikeBurstId++,
      postId: postId,
      tapPosition: Offset(clampedX, clampedY),
    );
    setState(() => _activeLikeBursts.add(burst));
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _activeLikeBursts.removeWhere((item) => item.id == burst.id);
      });
    });
  }

  Future<void> _handleFeedDoubleTapLike(
    DemoFeedPost post,
    Size surfaceSize,
  ) async {
    final tapPosition =
        _lastDoubleTapOffsetsByPostId[post.id] ??
        Offset(surfaceSize.width / 2, surfaceSize.height * 0.55);
    _spawnTastyLikeBurst(
      postId: post.id,
      tapPosition: tapPosition,
      surfaceSize: surfaceSize,
    );
    if (post.isLiked || _pendingDoubleTapLikePostIds.contains(post.id)) {
      return;
    }
    _pendingDoubleTapLikePostIds.add(post.id);
    try {
      final updated = await _demoRepository.toggleLike(post.id);
      if (!mounted) {
        return;
      }
      setState(() => _feedPostsById[post.id] = updated);
    } finally {
      _pendingDoubleTapLikePostIds.remove(post.id);
    }
  }

  void _handleOrderNowTriggerByVideoProgress(int index) {
    final controller = _videoControllers[index];
    if (!controller.value.isInitialized) {
      return;
    }
    final duration = controller.value.duration;
    if (duration <= Duration.zero) {
      return;
    }
    final endThreshold = duration > const Duration(milliseconds: 300)
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 80);
    final isNearEnd = controller.value.position >= duration - endThreshold;
    final wasNearEnd = _wasNearVideoEndByIndex[index];
    _wasNearVideoEndByIndex[index] = isNearEnd;
    if (!isNearEnd || wasNearEnd || _hasShownOrderNowByVideoIndex[index]) {
      return;
    }
    _hasShownOrderNowByVideoIndex[index] = true;
    _isOrderNowVisibleByVideoIndex[index] = true;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _dismissOrderNowForVideoIndex(int index) {
    if (!_isOrderNowVisibleByVideoIndex[index]) {
      return;
    }
    setState(() => _isOrderNowVisibleByVideoIndex[index] = false);
  }

  Future<void> _openOrderNowCart(
    DemoFeedPost post,
    _FeedVideoPostData video, {
    required int videoIndex,
  }) async {
    _dismissOrderNowForVideoIndex(videoIndex);
    final item = _CartLineItemData(
      title: video.cartItemTitle,
      subtitle: '${post.restaurantName} • ${video.cartItemSubtitle}',
      imageUrl: video.cartItemImageUrl,
      price: video.cartItemPrice,
      quantity: 1,
      restaurantName: post.restaurantName,
    );
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OrdersCartScreen(
            initialItems: [item],
            restaurantName: post.restaurantName,
          ),
        ),
      ),
    );
  }

  Future<void> _openComments(DemoFeedPost post) async {
    await _withFeedPlaybackPaused<void>(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FeedCommentsBottomSheet(
          postId: post.id,
          postTitle: post.restaurantName,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _feedPostsById[post.id] = _loadPostForId(post.id));
  }

  Future<void> _sharePromo(DemoFeedPost post) async {
    await _withFeedPlaybackPaused<void>(
      () => showShareFallbackDialog(
        context,
        title: post.restaurantName,
        body: post.caption,
      ),
    );
  }

  Future<void> _openPromoDetails(DemoFeedPost post) async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PromoDetailsScreen(
            title: post.restaurantName,
            caption: post.caption,
            audioLabel: post.audioLabel,
          ),
        ),
      ),
    );
  }

  void _handleVideoPageChanged(int index) {
    final previousIndex = _currentVideoIndex;
    _currentVideoIndex = index;
    _isVideoHoldActive = false;
    if (previousIndex != index &&
        previousIndex >= 0 &&
        previousIndex < _isOrderNowVisibleByVideoIndex.length &&
        _isOrderNowVisibleByVideoIndex[previousIndex]) {
      _isOrderNowVisibleByVideoIndex[previousIndex] = false;
      if (mounted) {
        setState(() {});
      }
    }
    _syncVideoPlayback();
  }

  void _syncVideoPlayback() {
    for (var i = 0; i < _videoControllers.length; i++) {
      final controller = _videoControllers[i];
      if (!controller.value.isInitialized) {
        continue;
      }
      if (i == _currentVideoIndex && !_isVideoHoldActive) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  void _handleVideoLongPressStart(int index) {
    if (_isVideoHoldActive || index != _currentVideoIndex) {
      return;
    }
    final controller = _videoControllers[index];
    if (!controller.value.isInitialized) {
      return;
    }
    setState(() => _isVideoHoldActive = true);
    controller.pause();
  }

  void _handleVideoLongPressEnd() {
    if (!_isVideoHoldActive) {
      return;
    }
    setState(() => _isVideoHoldActive = false);
    _syncVideoPlayback();
  }

  void _onBottomNavSelected(int index) {
    if (index != 0) {
      _pauseFeedPlayback();
    } else {
      _syncVideoPlayback();
    }
    widget.onBottomNavSelected(index);
  }

  @override
  void dispose() {
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAreaPadding = MediaQuery.paddingOf(context);
        final safeHeight =
            constraints.maxHeight -
            safeAreaPadding.top -
            safeAreaPadding.bottom;
        final metrics = _ResponsiveMetrics.from(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight > 0 ? safeHeight : constraints.maxHeight,
          ),
        );
        final navBarBottomInset = safeAreaPadding.bottom;
        final navBarTotalHeight = metrics.navHeight + navBarBottomInset;
        final pageViewportHeight = _clampDouble(
          constraints.maxHeight - navBarTotalHeight,
          0,
          constraints.maxHeight,
        );
        final topOverlayReservedHeight =
            metrics.topControlButtonSize + metrics.gapAfterTop;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: navBarTotalHeight,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _handleVideoPageChanged,
                itemCount: _FeedTabBody._feedVideos.length,
                itemBuilder: (context, index) {
                  final video = _FeedTabBody._feedVideos[index];
                  final post = _postForVideo(video);
                  final showOrderNow = _isOrderNowVisibleByVideoIndex[index];
                  final itemSize = Size(
                    constraints.maxWidth,
                    pageViewportHeight > 0
                        ? pageViewportHeight
                        : (safeHeight > 0 ? safeHeight : constraints.maxHeight),
                  );
                  final likeBursts = _likeBurstsForPost(post.id);
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPressStart: (_) => _handleVideoLongPressStart(index),
                    onLongPressEnd: (_) => _handleVideoLongPressEnd(),
                    onDoubleTapDown: (details) =>
                        _rememberDoubleTapPosition(post.id, details),
                    onDoubleTap: () => _handleFeedDoubleTapLike(post, itemSize),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _FeedBackground(
                            controller: _videoControllers[index],
                          ),
                        ),
                        if (!_isVideoHoldActive) ...[
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0x08000000),
                                    const Color(0x6B000000),
                                    const Color(0xD100131A),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                metrics.horizontalPadding,
                                metrics.topPadding,
                                metrics.horizontalPadding,
                                0,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: topOverlayReservedHeight),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: _FeedDetails(
                                              post: post,
                                              metrics: metrics,
                                              onOpenRestaurant: () =>
                                                  _openRestaurantDetails(post),
                                              onOpenReviews: () =>
                                                  _openRestaurantReviews(post),
                                              onOpenAudio: () =>
                                                  _openPromoDetails(post),
                                              showOrderNow: showOrderNow,
                                              orderNowPriceLabel:
                                                  video.priceLabel,
                                              onDismissOrderNow: () =>
                                                  _dismissOrderNowForVideoIndex(
                                                    index,
                                                  ),
                                              onOrderNowTap: () =>
                                                  _openOrderNowCart(
                                                    post,
                                                    video,
                                                    videoIndex: index,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: metrics.railGap),
                                          _ActionRail(
                                            metrics: metrics,
                                            post: post,
                                            onOpenRestaurant: () =>
                                                _openRestaurantDetails(post),
                                            onToggleFollow: () =>
                                                _toggleFollow(post),
                                            onToggleLike: () =>
                                                _toggleLike(post),
                                            onOpenComments: () =>
                                                _openComments(post),
                                            onShare: () => _sharePromo(post),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: _clampDouble(
                                      10 * metrics.scale,
                                      6,
                                      12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (likeBursts.isNotEmpty)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Stack(
                                  children: [
                                    for (final burst in likeBursts)
                                      _TastyLikeBurst(
                                        key: ValueKey<int>(burst.id),
                                        tapPosition: burst.tapPosition,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            left: _clampDouble(10 * metrics.scale, 8, 14),
                            right: _clampDouble(10 * metrics.scale, 8, 14),
                            bottom: _clampDouble(8 * metrics.scale, 6, 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: VideoProgressIndicator(
                                _videoControllers[index],
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFFFF7E4D),
                                  bufferedColor: Color(0x80FFFFFF),
                                  backgroundColor: Color(0x50000000),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNavBar(
                metrics: metrics,
                selectedIndex: widget.selectedBottomIndex,
                onSelected: _onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
            if (!_isVideoHoldActive)
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.horizontalPadding,
                      metrics.topPadding,
                      metrics.horizontalPadding,
                      0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _TopControls(
                        metrics: metrics,
                        selectedTab: widget.selectedTopTab,
                        onTabSelected: widget.onTopTabSelected,
                        onOpenSearch: _openSearch,
                        onOpenNotifications: _openNotifications,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MessagesTabBody extends StatelessWidget {
  const _MessagesTabBody({
    required this.userName,
    required this.authToken,
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
  final String authToken;
  final int selectedBottomIndex;
  final ValueChanged<int> onBottomNavSelected;

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAreaPadding = MediaQuery.paddingOf(context);
        final safeHeight =
            constraints.maxHeight -
            safeAreaPadding.top -
            safeAreaPadding.bottom;
        final metrics = _ResponsiveMetrics.from(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight > 0 ? safeHeight : constraints.maxHeight,
          ),
        );
        final navBarBottomInset = safeAreaPadding.bottom;
        final navBarTotalHeight = metrics.navHeight + navBarBottomInset;
        return Stack(
          children: [
            Positioned.fill(
              bottom: navBarTotalHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    _clampDouble(metrics.topPadding + 6, 12, 20),
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Messages',
                        style: TextStyle(
                          color: const Color(0xFF231A16),
                          fontSize: _clampDouble(34 * metrics.scale, 26, 34),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
                      Text(
                        'Track conversations and restaurant updates for $greetingName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7F6D61),
                          fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: _clampDouble(20 * metrics.scale, 16, 20),
                      ),
                      Expanded(
                        child: _CustomerMessagesSection(
                          metrics: metrics,
                          userName: userName,
                          authToken: authToken,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNavBar(
                metrics: metrics,
                selectedIndex: selectedBottomIndex,
                onSelected: onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerMessagesSection extends StatefulWidget {
  const _CustomerMessagesSection({
    required this.metrics,
    required this.userName,
    required this.authToken,
  });

  final _ResponsiveMetrics metrics;
  final String userName;
  final String authToken;

  @override
  State<_CustomerMessagesSection> createState() =>
      _CustomerMessagesSectionState();
}

class _CustomerMessagesSectionState extends State<_CustomerMessagesSection> {
  final _repository = DemoAppRepository.instance;
  final _conversationApiService = ConversationApiService();

  List<DemoConversationThread> _threads = const <DemoConversationThread>[];
  MessageFilterType _selectedFilter = MessageFilterType.all;
  String? _selectedThreadId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final token = widget.authToken.trim();
      final threads = token.isEmpty
          ? await _repository.getThreads()
          : await _conversationApiService.fetchThreads(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _threads = threads;
        _isLoading = false;
      });
    } on ConversationApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _conversationApiService.dispose();
    super.dispose();
  }

  String _counterpartyName(DemoConversationThread thread) {
    return _customerRestaurantNamesByThreadId[thread.id] ?? thread.customerName;
  }

  String get _senderName {
    final cleaned = widget.userName.trim();
    if (cleaned.isEmpty) {
      return 'You';
    }
    return cleaned;
  }

  List<DemoConversationThread> get _visibleThreads {
    Iterable<DemoConversationThread> items = _threads;
    switch (_selectedFilter) {
      case MessageFilterType.all:
        break;
      case MessageFilterType.unread:
        items = items.where((thread) => thread.unreadCount > 0);
        break;
      case MessageFilterType.orders:
        items = items.where((thread) => thread.type == MessageThreadType.order);
        break;
      case MessageFilterType.offers:
        items = items.where((thread) => thread.type == MessageThreadType.offer);
        break;
    }
    if (_selectedThreadId != null) {
      items = items.where((thread) => thread.id == _selectedThreadId);
    }
    return items.toList();
  }

  void _selectFilter(MessageFilterType filter) {
    setState(() => _selectedFilter = filter);
  }

  void _selectThread(String threadId) {
    setState(() {
      _selectedThreadId = _selectedThreadId == threadId ? null : threadId;
    });
  }

  Future<void> _openConversation(
    DemoConversationThread thread, {
    bool openComposer = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          threadId: thread.id,
          restaurantName: _senderName,
          authToken: widget.authToken,
          openComposerOnStart: openComposer,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadThreads();
  }

  @override
  Widget build(BuildContext context) {
    final priorityThreads = _threads.where((item) => item.priority).toList();
    final visibleThreads = _visibleThreads;

    return RefreshIndicator(
      color: const Color(0xFFFF7E4D),
      onRefresh: _loadThreads,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _errorMessage != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 160),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadThreads,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                _CustomerMessagesFilterRow(
                  metrics: widget.metrics,
                  selectedFilter: _selectedFilter,
                  onSelected: _selectFilter,
                ),
                if (priorityThreads.isNotEmpty) ...[
                  SizedBox(
                    height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                  ),
                  _CustomerPriorityInboxRow(
                    metrics: widget.metrics,
                    items: priorityThreads,
                    selectedThreadId: _selectedThreadId,
                    counterpartyNameOf: _counterpartyName,
                    onSelectedThread: _selectThread,
                  ),
                ],
                SizedBox(
                  height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                ),
                if (visibleThreads.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1ED),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4D8CD)),
                    ),
                    child: const Text(
                      'No conversations match the current filters.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...List.generate(visibleThreads.length, (index) {
                    final thread = visibleThreads[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleThreads.length - 1
                            ? _clampDouble(6 * widget.metrics.scale, 4, 6)
                            : _clampDouble(10 * widget.metrics.scale, 8, 10),
                      ),
                      child: _CustomerMessageThreadCard(
                        metrics: widget.metrics,
                        thread: thread,
                        counterpartyName: _counterpartyName(thread),
                        onOpenThread: () => _openConversation(thread),
                        onReply: () =>
                            _openConversation(thread, openComposer: true),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _CustomerMessagesFilterRow extends StatelessWidget {
  const _CustomerMessagesFilterRow({
    required this.metrics,
    required this.selectedFilter,
    required this.onSelected,
  });

  final _ResponsiveMetrics metrics;
  final MessageFilterType selectedFilter;
  final ValueChanged<MessageFilterType> onSelected;

  static const _filters = [
    (icon: Icons.all_inbox_rounded, label: 'All', type: MessageFilterType.all),
    (
      icon: Icons.mark_chat_unread_rounded,
      label: 'Unread',
      type: MessageFilterType.unread,
    ),
    (
      icon: Icons.receipt_long_rounded,
      label: 'Orders',
      type: MessageFilterType.orders,
    ),
    (
      icon: Icons.local_offer_outlined,
      label: 'Offers',
      type: MessageFilterType.offers,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final item = _filters[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == _filters.length - 1
                  ? 0
                  : _clampDouble(8 * metrics.scale, 6, 8),
            ),
            child: _CustomerMessageFilterChip(
              metrics: metrics,
              icon: item.icon,
              label: item.label,
              selected: selectedFilter == item.type,
              onTap: () => onSelected(item.type),
            ),
          );
        }),
      ),
    );
  }
}

class _CustomerMessageFilterChip extends StatelessWidget {
  const _CustomerMessageFilterChip({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFF7E4D) : const Color(0xFF89786D);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(12 * metrics.scale, 10, 12),
          vertical: _clampDouble(8 * metrics.scale, 6, 8),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : const Color(0xFFF3ECE5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFFFD7C8) : const Color(0xFFE2D5CA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: _clampDouble(17 * metrics.scale, 14, 17),
            ),
            SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPriorityInboxRow extends StatelessWidget {
  const _CustomerPriorityInboxRow({
    required this.metrics,
    required this.items,
    required this.selectedThreadId,
    required this.counterpartyNameOf,
    required this.onSelectedThread,
  });

  final _ResponsiveMetrics metrics;
  final List<DemoConversationThread> items;
  final String? selectedThreadId;
  final String Function(DemoConversationThread) counterpartyNameOf;
  final ValueChanged<String> onSelectedThread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Inbox',
          style: TextStyle(
            color: const Color(0xFF1F1B19),
            fontSize: _clampDouble(21 * metrics.scale, 15, 21),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final counterpartyName = counterpartyNameOf(item);
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1
                      ? 0
                      : _clampDouble(8 * metrics.scale, 6, 8),
                ),
                child: _CustomerPriorityThreadChip(
                  metrics: metrics,
                  counterpartyName: counterpartyName,
                  online: item.online,
                  selected: selectedThreadId == item.id,
                  onTap: () => onSelectedThread(item.id),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CustomerPriorityThreadChip extends StatelessWidget {
  const _CustomerPriorityThreadChip({
    required this.metrics,
    required this.counterpartyName,
    required this.online,
    required this.selected,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final String counterpartyName;
  final bool online;
  final bool selected;
  final VoidCallback onTap;

  static String _initials(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'HR';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(10 * metrics.scale, 8, 10),
          vertical: _clampDouble(8 * metrics.scale, 6, 8),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : const Color(0xFFF3F0EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFD7C8) : const Color(0xFFE3D7CC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _clampDouble(30 * metrics.scale, 24, 30),
                  height: _clampDouble(30 * metrics.scale, 24, 30),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFE2D6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(counterpartyName),
                    style: TextStyle(
                      color: const Color(0xFF9A3F1F),
                      fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (online)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: _clampDouble(10 * metrics.scale, 8, 10),
                      height: _clampDouble(10 * metrics.scale, 8, 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF24A75A),
                        border: Border.all(
                          color: const Color(0xFFF3F0EC),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: _clampDouble(7 * metrics.scale, 5, 7)),
            Text(
              counterpartyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF2A231E),
                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerMessageThreadCard extends StatelessWidget {
  const _CustomerMessageThreadCard({
    required this.metrics,
    required this.thread,
    required this.counterpartyName,
    required this.onOpenThread,
    required this.onReply,
  });

  final _ResponsiveMetrics metrics;
  final DemoConversationThread thread;
  final String counterpartyName;
  final VoidCallback onOpenThread;
  final VoidCallback onReply;

  static String _initials(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'HR';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;
    final highlightColor = thread.priority
        ? const Color(0xFFFFE1D4)
        : const Color(0xFFE4D8CD);

    return InkWell(
      onTap: onOpenThread,
      borderRadius: BorderRadius.circular(
        _clampDouble(20 * metrics.scale, 16, 20),
      ),
      child: Container(
        padding: EdgeInsets.all(_clampDouble(12 * metrics.scale, 10, 12)),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1ED),
          borderRadius: BorderRadius.circular(
            _clampDouble(20 * metrics.scale, 16, 20),
          ),
          border: Border.all(color: highlightColor),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: _clampDouble(44 * metrics.scale, 36, 44),
                      height: _clampDouble(44 * metrics.scale, 36, 44),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE2D6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(counterpartyName),
                        style: TextStyle(
                          color: const Color(0xFF9A3F1F),
                          fontSize: _clampDouble(16 * metrics.scale, 13, 16),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (thread.online)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: _clampDouble(12 * metrics.scale, 10, 12),
                          height: _clampDouble(12 * metrics.scale, 10, 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF24A75A),
                            border: Border.all(
                              color: const Color(0xFFF4F1ED),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              counterpartyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1F1B19),
                                fontSize: _clampDouble(
                                  18 * metrics.scale,
                                  14,
                                  18,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _clampDouble(6 * metrics.scale, 4, 6),
                          ),
                          Text(
                            thread.timeLabel,
                            style: TextStyle(
                              color: const Color(0xFF8C7D71),
                              fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasUnread) ...[
                            SizedBox(
                              width: _clampDouble(6 * metrics.scale, 4, 6),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _clampDouble(
                                  7 * metrics.scale,
                                  5,
                                  7,
                                ),
                                vertical: _clampDouble(3 * metrics.scale, 2, 3),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7E4D),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${thread.unreadCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _clampDouble(
                                    10 * metrics.scale,
                                    8,
                                    10,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                      Text(
                        thread.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF8A7B6F),
                          fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: _clampDouble(9 * metrics.scale, 7, 9)),
            Row(
              children: [
                _CustomerMessageMetaPill(
                  metrics: metrics,
                  icon: Icons.receipt_long_rounded,
                  label: thread.orderLabel,
                ),
                SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                _CustomerMessageMetaPill(
                  metrics: metrics,
                  icon: Icons.local_shipping_outlined,
                  label: thread.channelLabel,
                ),
                if (thread.priority) ...[
                  SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                  _CustomerMessageMetaPill(
                    metrics: metrics,
                    icon: Icons.priority_high_rounded,
                    label: 'Priority',
                    highlighted: true,
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7E4D),
                    minimumSize: Size(
                      _clampDouble(84 * metrics.scale, 70, 84),
                      _clampDouble(34 * metrics.scale, 30, 34),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: _clampDouble(10 * metrics.scale, 8, 10),
                    ),
                    backgroundColor: const Color(0xFFFFEFE8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.reply_rounded,
                    size: _clampDouble(16 * metrics.scale, 13, 16),
                  ),
                  label: Text(
                    'Reply',
                    style: TextStyle(
                      fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerMessageMetaPill extends StatelessWidget {
  const _CustomerMessageMetaPill({
    required this.metrics,
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? const Color(0xFFC1502B)
        : const Color(0xFF7D6C60);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(7 * metrics.scale, 5, 7),
        vertical: _clampDouble(4 * metrics.scale, 3, 4),
      ),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFE8DD) : const Color(0xFFEDE5DE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: _clampDouble(13 * metrics.scale, 10, 13),
          ),
          SizedBox(width: _clampDouble(4 * metrics.scale, 3, 4)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: _clampDouble(11 * metrics.scale, 9, 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedVideoPostData {
  const _FeedVideoPostData({
    required this.videoAssetPath,
    required this.postId,
    required this.priceLabel,
    required this.cartItemTitle,
    required this.cartItemSubtitle,
    required this.cartItemImageUrl,
    required this.cartItemPrice,
  });

  final String videoAssetPath;
  final String postId;
  final String priceLabel;
  final String cartItemTitle;
  final String cartItemSubtitle;
  final String cartItemImageUrl;
  final double cartItemPrice;
}

class _DiscoverTabBody extends StatefulWidget {
  const _DiscoverTabBody({
    required this.userName,
    required this.authToken,
    required this.restaurants,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.favoriteSpotTitles,
    required this.onSetSpotFavorite,
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
  final String authToken;
  final List<CustomerRestaurant> restaurants;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Set<String> favoriteSpotTitles;
  final void Function(_DiscoverSpotData spot, bool isFavorite)
  onSetSpotFavorite;
  final int selectedBottomIndex;
  final ValueChanged<int> onBottomNavSelected;

  static const List<_DiscoverCategoryData> _categories = [
    _DiscoverCategoryData(
      title: 'Pizza',
      subtitle: 'Wood-fired',
      icon: Icons.local_pizza_rounded,
      backgroundColor: Color(0xFFFFF1E7),
      accentColor: Color(0xFFFF8D5B),
    ),
    _DiscoverCategoryData(
      title: 'Burgers',
      subtitle: 'Stacked',
      icon: Icons.lunch_dining_rounded,
      backgroundColor: Color(0xFFFFF4EC),
      accentColor: Color(0xFFB56A45),
    ),
    _DiscoverCategoryData(
      title: 'Sushi',
      subtitle: 'Fresh rolls',
      icon: Icons.set_meal_rounded,
      backgroundColor: Color(0xFFF2F8F5),
      accentColor: Color(0xFF2F8A7E),
    ),
    _DiscoverCategoryData(
      title: 'Desserts',
      subtitle: 'Sweet picks',
      icon: Icons.icecream_rounded,
      backgroundColor: Color(0xFFFFF1F5),
      accentColor: Color(0xFFE17B91),
    ),
  ];

  static const List<_DiscoverSpotData> _popularSpots = [
    _DiscoverSpotData(
      title: 'The Golden Spoon',
      handle: 'thegoldenspoon',
      categoryTitle: 'Pizza',
      subtitle: 'Italian comfort and signature pasta',
      deliveryLabel: '12 min',
      ratingLabel: '4.9',
      priceTier: 2,
      badge: 'Free delivery',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Ember Slice',
      handle: 'emberslice',
      categoryTitle: 'Burgers',
      subtitle: 'Stone-baked pizza and burrata bites',
      deliveryLabel: '18 min',
      ratingLabel: '4.8',
      priceTier: 2,
      badge: 'Top rated',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Cedar Bowl',
      handle: 'cedarbowl',
      categoryTitle: 'Sushi',
      subtitle: 'Fresh wraps, bowls, and grill plates',
      deliveryLabel: '14 min',
      ratingLabel: '4.7',
      priceTier: 1,
      badge: 'New menu',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Sweet Dock',
      handle: 'sweetdock',
      categoryTitle: 'Desserts',
      subtitle: 'Gelato cups, cookies, and warm brownies',
      deliveryLabel: '16 min',
      ratingLabel: '4.8',
      priceTier: 1,
      badge: 'Chef pick',
      imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  static const List<_DiscoverDealData> _quickCravings = [
    _DiscoverDealData(
      title: 'Lunch Box Express',
      subtitle: 'Wrap, fries, and a chilled drink',
      priceLabel: '\$11.90',
      promoLabel: '15% off',
      icon: Icons.lunch_dining_rounded,
      accentColor: Color(0xFFFF7E4D),
    ),
    _DiscoverDealData(
      title: 'Sushi Night Combo',
      subtitle: 'Eight rolls paired with miso soup',
      priceLabel: '\$17.50',
      promoLabel: 'Best seller',
      icon: Icons.set_meal_rounded,
      accentColor: Color(0xFF2F8A7E),
    ),
    _DiscoverDealData(
      title: 'Dessert Drop',
      subtitle: 'Cookies, brownies, and gelato cups',
      priceLabel: '\$9.80',
      promoLabel: 'Sweet pick',
      icon: Icons.icecream_rounded,
      accentColor: Color(0xFFE17B91),
    ),
  ];

  @override
  State<_DiscoverTabBody> createState() => _DiscoverTabBodyState();
}

class _DiscoverTabBodyState extends State<_DiscoverTabBody> {
  final _customerApiService = CustomerApiService();
  Set<String> _activeCuisineFilters = <String>{};
  double _minimumRatingFilter = 0;
  int? _maximumDeliveryMinutesFilter;
  int? _maximumPriceTierFilter;

  List<_DiscoverSpotData> get _availableSpots {
    if (widget.restaurants.isEmpty) {
      return widget.authToken.trim().isEmpty
          ? _DiscoverTabBody._popularSpots
          : const <_DiscoverSpotData>[];
    }
    return widget.restaurants.map(_spotFromRestaurant).toList(growable: false);
  }

  List<_DiscoverSpotData> get _filteredPopularSpots {
    return _availableSpots
        .where((spot) {
          if (_activeCuisineFilters.isNotEmpty &&
              !_activeCuisineFilters.contains(spot.categoryTitle)) {
            return false;
          }
          if (spot.ratingValue < _minimumRatingFilter) {
            return false;
          }
          if (_maximumDeliveryMinutesFilter != null &&
              spot.deliveryMinutes > _maximumDeliveryMinutesFilter!) {
            return false;
          }
          if (_maximumPriceTierFilter != null &&
              spot.priceTier > _maximumPriceTierFilter!) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<_DiscoverSpotData> _spotsForCuisine(String cuisineTitle) {
    return _availableSpots
        .where((spot) => spot.categoryTitle == cuisineTitle)
        .toList(growable: false);
  }

  _DiscoverSpotData _spotFromRestaurant(CustomerRestaurant restaurant) {
    return _DiscoverSpotData(
      restaurantId: restaurant.id,
      title: restaurant.name,
      handle: restaurant.handle,
      categoryTitle: restaurant.category,
      subtitle: restaurant.description,
      deliveryLabel: restaurant.deliveryLabel,
      ratingLabel: restaurant.rating <= 0
          ? 'New'
          : restaurant.rating.toStringAsFixed(1),
      priceTier: restaurant.priceTier,
      badge: restaurant.status == 'active'
          ? '${restaurant.menuItemsCount} menu items'
          : restaurant.status,
      imageUrl: restaurant.imageUrl,
    );
  }

  @override
  void dispose() {
    _customerApiService.dispose();
    super.dispose();
  }

  Future<void> _openDiscoverSearch(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }

  Future<void> _openDiscoverFilters(BuildContext context) async {
    final result = await showModalBottomSheet<_DiscoverFiltersState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFEFCFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        var selectedCuisines = Set<String>.from(_activeCuisineFilters);
        var minimumRating = _minimumRatingFilter;
        int? maximumDeliveryMinutes = _maximumDeliveryMinutesFilter;
        int? maximumPriceTier = _maximumPriceTierFilter;
        return StatefulBuilder(
          builder: (context, setModalState) {
            String ratingLabelFor(double value) {
              if (value == 0) {
                return 'Any';
              }
              return '${value.toStringAsFixed(1)}+';
            }

            String deliveryLabelFor(int? value) {
              if (value == null) {
                return 'Any';
              }
              return '<= ${value}m';
            }

            String priceLabelFor(int? value) {
              if (value == null) {
                return 'Any';
              }
              return '\$' * value;
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8C6B8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Discover Filters',
                      style: TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Cuisines',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _DiscoverTabBody._categories
                          .map((category) {
                            final isSelected = selectedCuisines.contains(
                              category.title,
                            );
                            return FilterChip(
                              label: Text(category.title),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedCuisines.add(category.title);
                                  } else {
                                    selectedCuisines.remove(category.title);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFFFFE2D0),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Minimum rating',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final chips = <Widget>[];
                        for (final value in const <double>[0, 4.5, 4.8]) {
                          final isSelected = minimumRating == value;
                          chips.add(
                            ChoiceChip(
                              label: Text(ratingLabelFor(value)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => minimumRating = value),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(spacing: 8, runSpacing: 8, children: chips);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Delivery time',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final chips = <Widget>[];
                        for (final value in const <int?>[null, 15, 20]) {
                          final isSelected = maximumDeliveryMinutes == value;
                          chips.add(
                            ChoiceChip(
                              label: Text(deliveryLabelFor(value)),
                              selected: isSelected,
                              onSelected: (_) => setModalState(
                                () => maximumDeliveryMinutes = value,
                              ),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(spacing: 8, runSpacing: 8, children: chips);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Price',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final chips = <Widget>[];
                        for (final value in const <int?>[null, 1, 2, 3]) {
                          final isSelected = maximumPriceTier == value;
                          chips.add(
                            ChoiceChip(
                              label: Text(priceLabelFor(value)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => maximumPriceTier = value),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(spacing: 8, runSpacing: 8, children: chips);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                sheetContext,
                              ).pop(const _DiscoverFiltersState());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7A6558),
                              side: const BorderSide(color: Color(0xFFE2D0C1)),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                _DiscoverFiltersState(
                                  selectedCuisineTitles: selectedCuisines,
                                  minimumRating: minimumRating,
                                  maximumDeliveryMinutes:
                                      maximumDeliveryMinutes,
                                  maximumPriceTier: maximumPriceTier,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7E4D),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _activeCuisineFilters = Set<String>.from(result.selectedCuisineTitles);
      _minimumRatingFilter = result.minimumRating;
      _maximumDeliveryMinutesFilter = result.maximumDeliveryMinutes;
      _maximumPriceTierFilter = result.maximumPriceTier;
    });
  }

  Future<void> _openLocationMap(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DiscoverMapPreviewScreen(spots: _filteredPopularSpots),
      ),
    );
  }

  Future<void> _openCuisineDetails(
    BuildContext context,
    _DiscoverCategoryData category,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DiscoverCuisineDetailsScreen(
          category: category,
          spots: _spotsForCuisine(category.title),
        ),
      ),
    );
  }

  Future<void> _openPopularSpot(
    BuildContext context,
    _DiscoverSpotData spot,
  ) async {
    await _openDiscoverRestaurantProfile(context, spot);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openPopularSpotMenu(
    BuildContext context,
    _DiscoverSpotData spot,
  ) async {
    final navigator = Navigator.of(context);
    final menuItems = await _discoverMenuItemsForSpot(spot);
    if (!mounted) {
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => _DiscoverRestaurantMenuScreen(
          spot: spot,
          items: menuItems,
          onItemTap: (item) =>
              _openDiscoverMenuItemDetails(context, spot, item),
        ),
      ),
    );
  }

  Future<List<RestaurantMenuItem>> _discoverMenuItemsForSpot(
    _DiscoverSpotData spot,
  ) async {
    final token = widget.authToken.trim();
    final restaurantId = spot.restaurantId?.trim() ?? '';
    if (token.isNotEmpty && restaurantId.isNotEmpty) {
      try {
        final menu = await _customerApiService.fetchRestaurantMenu(
          token: token,
          restaurantId: restaurantId,
        );
        return menu.items;
      } on CustomerApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(e.message)));
        }
        return const <RestaurantMenuItem>[];
      }
    }
    final category = spot.categoryTitle.trim().toLowerCase();
    switch (category) {
      case 'pizza':
        return _discoverPizzaMenuItems;
      case 'burgers':
        return _discoverBurgerMenuItems;
      case 'sushi':
        return _discoverSushiMenuItems;
      case 'desserts':
        return _discoverDessertMenuItems;
      default:
        return _discoverPizzaMenuItems;
    }
  }

  Future<void> _openDiscoverMenuItemDetails(
    BuildContext context,
    _DiscoverSpotData spot,
    RestaurantMenuItem item,
  ) async {
    await showRestaurantMenuItemDetailsPopup(
      context,
      item: item,
      allowAddToCart: true,
      onAddToCart: (selectedItem) {
        final cartItem = _CartLineItemData(
          title: selectedItem.title,
          subtitle: '${spot.title} - ${selectedItem.category}',
          imageUrl: selectedItem.imageUrl,
          price: selectedItem.price ?? 0,
          quantity: 1,
          restaurantName: spot.title,
          menuItemId: selectedItem.id,
        );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _OrdersCartScreen(
              initialItems: [cartItem],
              restaurantName: spot.title,
              authToken: widget.authToken,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPopularSpotList(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _DiscoverPopularSpotsScreen(spots: _filteredPopularSpots),
      ),
    );
  }

  bool _isSpotSaved(_DiscoverSpotData spot) {
    final savedFromDiscoverHeart = widget.favoriteSpotTitles.contains(
      spot.title.trim(),
    );
    final savedFromProfileHeart = isCustomerRestaurantSaved(
      restaurantName: spot.title,
      handle: spot.handle,
    );
    return savedFromDiscoverHeart || savedFromProfileHeart;
  }

  void _toggleSpotFavorite(_DiscoverSpotData spot) {
    final nextSaved = !_isSpotSaved(spot);
    widget.onSetSpotFavorite(spot, nextSaved);
  }

  void _openQuickCravingDetails(BuildContext context, _DiscoverDealData deal) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DiscoverDealDetailsSheet(
        data: deal,
        onAddToCart: (selectedDeal) =>
            _openQuickCravingCart(sheetContext, selectedDeal),
      ),
    );
  }

  void _openQuickCravingCart(
    BuildContext sheetContext,
    _DiscoverDealData deal,
  ) {
    final item = _CartLineItemData(
      title: deal.title,
      subtitle: 'Quick Cravings • ${deal.subtitle}',
      imageUrl: _quickCravingImageUrl(deal.title),
      price: _quickCravingPriceValue(deal.priceLabel),
      quantity: 1,
      restaurantName: 'Quick Cravings',
    );
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OrdersCartScreen(
            initialItems: [item],
            restaurantName: 'Quick Cravings',
          ),
        ),
      );
    });
  }

  double _quickCravingPriceValue(String priceLabel) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(priceLabel);
    if (match == null) {
      return 0;
    }
    return double.tryParse(match.group(1) ?? '') ?? 0;
  }

  String _quickCravingImageUrl(String title) {
    switch (title) {
      case 'Lunch Box Express':
        return 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80';
      case 'Sushi Night Combo':
        return 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=80';
      case 'Dessert Drop':
        return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80';
      default:
        return 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80';
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;
    final popularSpots = _filteredPopularSpots;

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAreaPadding = MediaQuery.paddingOf(context);
        final safeHeight =
            constraints.maxHeight -
            safeAreaPadding.top -
            safeAreaPadding.bottom;
        final metrics = _ResponsiveMetrics.from(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight > 0 ? safeHeight : constraints.maxHeight,
          ),
        );
        final navBarBottomInset = safeAreaPadding.bottom;
        final navBarTotalHeight = metrics.navHeight + navBarBottomInset;
        return Stack(
          children: [
            const Positioned.fill(child: _DiscoverBackground()),
            Positioned.fill(
              bottom: navBarTotalHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    _clampDouble(metrics.topPadding + 6, 12, 20),
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Discover',
                                  style: TextStyle(
                                    color: const Color(0xFF231A16),
                                    fontSize: _clampDouble(
                                      34 * metrics.scale,
                                      26,
                                      34,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                SizedBox(
                                  height: _clampDouble(6 * metrics.scale, 4, 6),
                                ),
                                Text(
                                  'Fresh picks for $greetingName tonight',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF7F6D61),
                                    fontSize: _clampDouble(
                                      15 * metrics.scale,
                                      12,
                                      15,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ProfileIconButton(
                            icon: Icons.tune_rounded,
                            metrics: metrics,
                            onTap: () => _openDiscoverFilters(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(18 * metrics.scale, 14, 18),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _DiscoverSearchBar(
                              metrics: metrics,
                              onTapSearch: () => _openDiscoverSearch(context),
                            ),
                          ),
                          SizedBox(
                            width: _clampDouble(12 * metrics.scale, 10, 12),
                          ),
                          _ProfileIconButton(
                            icon: Icons.place_outlined,
                            metrics: metrics,
                            onTap: () => _openLocationMap(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(20 * metrics.scale, 16, 20),
                      ),
                      if (widget.isLoading || widget.errorMessage != null) ...[
                        _ProfilePanel(
                          child: Padding(
                            padding: EdgeInsets.all(
                              _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            child: Row(
                              children: [
                                if (widget.isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.cloud_off_rounded,
                                    color: Color(0xFFB7372B),
                                  ),
                                SizedBox(
                                  width: _clampDouble(
                                    10 * metrics.scale,
                                    8,
                                    10,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.isLoading
                                        ? 'Loading restaurants from the database...'
                                        : widget.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF7D6C60),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!widget.isLoading)
                                  TextButton(
                                    onPressed: widget.onRefresh,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _clampDouble(16 * metrics.scale, 12, 16),
                        ),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProfileSectionHeader(
                                title: 'Browse Cuisines',
                                actionLabel: 'View Map',
                                onActionTap: () => _openLocationMap(context),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  126 * metrics.scale,
                                  112,
                                  126,
                                ),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount:
                                      _DiscoverTabBody._categories.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        width: _clampDouble(
                                          12 * metrics.scale,
                                          8,
                                          12,
                                        ),
                                      ),
                                  itemBuilder: (context, index) {
                                    final category =
                                        _DiscoverTabBody._categories[index];
                                    return _DiscoverCuisineChip(
                                      data: category,
                                      metrics: metrics,
                                      onTap: () => _openCuisineDetails(
                                        context,
                                        category,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              _ProfileSectionHeader(
                                title: 'Popular Near You',
                                actionLabel: 'See All',
                                onActionTap: () =>
                                    _openPopularSpotList(context),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              if (popularSpots.isEmpty)
                                _ProfilePanel(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      _clampDouble(18 * metrics.scale, 14, 18),
                                    ),
                                    child: const Text(
                                      'No restaurants match your filters yet.',
                                      style: TextStyle(
                                        color: Color(0xFF7D6C60),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: _clampDouble(
                                    320 * metrics.scale,
                                    286,
                                    320,
                                  ),
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: popularSpots.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                          width: _clampDouble(
                                            14 * metrics.scale,
                                            10,
                                            14,
                                          ),
                                        ),
                                    itemBuilder: (context, index) {
                                      final spot = popularSpots[index];
                                      return _DiscoverSpotCard(
                                        data: spot,
                                        metrics: metrics,
                                        isFavorite: _isSpotSaved(spot),
                                        onTap: () =>
                                            _openPopularSpot(context, spot),
                                        onViewMenuTap: () =>
                                            _openPopularSpotMenu(context, spot),
                                        onFavoriteTap: () =>
                                            _toggleSpotFavorite(spot),
                                      );
                                    },
                                  ),
                                ),
                              if (widget.authToken.trim().isEmpty) ...[
                                SizedBox(
                                  height: _clampDouble(
                                    26 * metrics.scale,
                                    20,
                                    26,
                                  ),
                                ),
                                const _ProfileSectionHeader(
                                  title: 'Quick Cravings',
                                ),
                                SizedBox(
                                  height: _clampDouble(
                                    14 * metrics.scale,
                                    10,
                                    14,
                                  ),
                                ),
                                _ProfilePanel(
                                  child: Column(
                                    children: List.generate(
                                      _DiscoverTabBody._quickCravings.length,
                                      (index) {
                                        final item = _DiscoverTabBody
                                            ._quickCravings[index];
                                        return Column(
                                          children: [
                                            _DiscoverDealTile(
                                              data: item,
                                              metrics: metrics,
                                              onTap: () =>
                                                  _openQuickCravingDetails(
                                                    context,
                                                    item,
                                                  ),
                                            ),
                                            if (index !=
                                                _DiscoverTabBody
                                                        ._quickCravings
                                                        .length -
                                                    1)
                                              const Divider(
                                                height: 1,
                                                color: Color(0xFFF0E2D3),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(
                                height: _clampDouble(12 * metrics.scale, 8, 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNavBar(
                metrics: metrics,
                selectedIndex: widget.selectedBottomIndex,
                onSelected: widget.onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DiscoverBackground extends StatelessWidget {
  const _DiscoverBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFBF7), Color(0xFFF5E6D7)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -72,
          left: -54,
          child: Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x35FFD3AE), Color(0x00FFD3AE)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 170,
          right: -72,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x24FFC08B), Color(0x00FFC08B)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -40,
          child: Container(
            width: 170,
            height: 170,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x1FD9B18C), Color(0x00D9B18C)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersTabBody extends StatelessWidget {
  const _OrdersTabBody({
    required this.userName,
    required this.authToken,
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
  final String authToken;
  final List<CustomerOrder> orders;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final int selectedBottomIndex;
  final ValueChanged<int> onBottomNavSelected;

  static const List<_OrdersMetricData> _heroMetrics = [
    _OrdersMetricData(
      label: 'Active',
      value: '1',
      icon: Icons.delivery_dining_rounded,
      accentColor: Color(0xFFFF7E4D),
      backgroundColor: Color(0xFFFFF2E8),
    ),
    _OrdersMetricData(
      label: 'Delivered',
      value: '18',
      icon: Icons.receipt_long_rounded,
      accentColor: Color(0xFF2F8A7E),
      backgroundColor: Color(0xFFF1F8F5),
    ),
    _OrdersMetricData(
      label: 'Saved',
      value: '\$42',
      icon: Icons.stars_rounded,
      accentColor: Color(0xFFB56A45),
      backgroundColor: Color(0xFFFFF4EC),
    ),
  ];

  static const _activeStatus = _OrderStatus.onTheWay;

  static const List<_PastOrderEntryData> _pastOrders = [
    _PastOrderEntryData(
      title: 'Burger Station',
      summary: '2 items - Angus burger and Cajun fries',
      dateLabel: 'Today, 12:24 PM',
      totalLabel: '\$24.50',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      reorderItems: [
        _CartLineItemData(
          title: 'Angus Burger Combo',
          subtitle: 'Burger Station - No onions',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
          price: 12.50,
          quantity: 1,
          restaurantName: 'Burger Station',
        ),
        _CartLineItemData(
          title: 'Cajun Fries',
          subtitle: 'Large - Extra crispy',
          imageUrl:
              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=900&q=80',
          price: 4.80,
          quantity: 1,
          restaurantName: 'Burger Station',
        ),
      ],
    ),
    _PastOrderEntryData(
      title: 'Napoli Fire',
      summary: '1 item - Pepperoni feast with extra mozzarella',
      dateLabel: 'Yesterday, 7:18 PM',
      totalLabel: '\$18.90',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
      reorderItems: [
        _CartLineItemData(
          title: 'Pepperoni Feast',
          subtitle: 'Napoli Fire - Extra mozzarella',
          imageUrl:
              'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
          price: 14.00,
          quantity: 1,
          restaurantName: 'Napoli Fire',
        ),
      ],
    ),
    _PastOrderEntryData(
      title: 'Bean & Brew',
      summary: '3 items - iced latte, brownie, and turkey sandwich',
      dateLabel: 'Apr 25, 9:06 AM',
      totalLabel: '\$16.40',
      status: _OrderStatus.rejected,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      reorderItems: [
        _CartLineItemData(
          title: 'Iced Latte',
          subtitle: 'Bean & Brew - Medium',
          imageUrl:
              'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
          price: 4.20,
          quantity: 1,
          restaurantName: 'Bean & Brew',
        ),
        _CartLineItemData(
          title: 'Brownie',
          subtitle: 'Chocolate',
          imageUrl:
              'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=900&q=80',
          price: 3.10,
          quantity: 1,
          restaurantName: 'Bean & Brew',
        ),
        _CartLineItemData(
          title: 'Turkey Sandwich',
          subtitle: 'Whole wheat',
          imageUrl:
              'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=900&q=80',
          price: 5.50,
          quantity: 1,
          restaurantName: 'Bean & Brew',
        ),
      ],
    ),
  ];

  static const List<_OrderReceiptData> _orderReceipts = [
    _OrderReceiptData(
      orderId: 'HR-2048',
      restaurantName: 'Burger Station',
      summary: '2 items - Angus burger and Cajun fries',
      placedAtLabel: 'Today, 12:24 PM',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      paymentMethodLabel: 'Paid online',
      deliveryFee: 2.75,
      serviceFee: 1.25,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: [
        _OrderReceiptLineItemData(
          title: 'Angus Burger Combo',
          subtitle: 'No onions',
          quantity: 1,
          unitPrice: 12.50,
        ),
        _OrderReceiptLineItemData(
          title: 'Cajun Fries',
          subtitle: 'Large, extra crispy',
          quantity: 1,
          unitPrice: 4.80,
        ),
        _OrderReceiptLineItemData(
          title: 'Cola',
          subtitle: 'Regular',
          quantity: 2,
          unitPrice: 1.60,
        ),
      ],
    ),
    _OrderReceiptData(
      orderId: 'HR-2047',
      restaurantName: 'Napoli Fire',
      summary: '1 item - Pepperoni feast with extra mozzarella',
      placedAtLabel: 'Yesterday, 7:18 PM',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
      paymentMethodLabel: 'On delivery',
      deliveryFee: 2.25,
      serviceFee: 1.15,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: [
        _OrderReceiptLineItemData(
          title: 'Pepperoni Feast',
          subtitle: 'Extra mozzarella',
          quantity: 1,
          unitPrice: 14.00,
        ),
        _OrderReceiptLineItemData(
          title: 'Garlic Bread',
          subtitle: '4 pieces',
          quantity: 1,
          unitPrice: 1.50,
        ),
      ],
    ),
    _OrderReceiptData(
      orderId: 'HR-2046',
      restaurantName: 'Bean & Brew',
      summary: '3 items - iced latte, brownie, and turkey sandwich',
      placedAtLabel: 'Apr 25, 9:06 AM',
      status: _OrderStatus.rejected,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      paymentMethodLabel: 'Refunded',
      deliveryFee: 2.30,
      serviceFee: 1.30,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: [
        _OrderReceiptLineItemData(
          title: 'Iced Latte',
          subtitle: 'Medium',
          quantity: 1,
          unitPrice: 4.20,
        ),
        _OrderReceiptLineItemData(
          title: 'Brownie',
          subtitle: 'Chocolate',
          quantity: 1,
          unitPrice: 3.10,
        ),
        _OrderReceiptLineItemData(
          title: 'Turkey Sandwich',
          subtitle: 'Whole wheat',
          quantity: 1,
          unitPrice: 5.50,
        ),
      ],
    ),
  ];

  List<_PastOrderEntryData> get _displayPastOrders {
    if (orders.isEmpty) {
      return authToken.trim().isEmpty
          ? _pastOrders
          : const <_PastOrderEntryData>[];
    }
    return orders.map(_pastOrderFromCustomerOrder).toList(growable: false);
  }

  List<_OrderReceiptData> get _displayReceipts {
    if (orders.isEmpty) {
      return authToken.trim().isEmpty
          ? _orderReceipts
          : const <_OrderReceiptData>[];
    }
    return orders.map(_receiptFromCustomerOrder).toList(growable: false);
  }

  List<_OrdersMetricData> get _displayHeroMetrics {
    if (orders.isEmpty) {
      return authToken.trim().isEmpty
          ? _heroMetrics
          : const <_OrdersMetricData>[
              _OrdersMetricData(
                label: 'Active',
                value: '0',
                icon: Icons.delivery_dining_rounded,
                accentColor: Color(0xFFFF7E4D),
                backgroundColor: Color(0xFFFFF2E8),
              ),
              _OrdersMetricData(
                label: 'Delivered',
                value: '0',
                icon: Icons.receipt_long_rounded,
                accentColor: Color(0xFF2F8A7E),
                backgroundColor: Color(0xFFF1F8F5),
              ),
              _OrdersMetricData(
                label: 'Spent',
                value: '\$0',
                icon: Icons.stars_rounded,
                accentColor: Color(0xFFB56A45),
                backgroundColor: Color(0xFFFFF4EC),
              ),
            ];
    }
    final active = orders
        .where(
          (order) => !_orderStatusIsTerminal(_statusFromString(order.status)),
        )
        .length;
    final delivered = orders
        .where(
          (order) => _statusFromString(order.status) == _OrderStatus.delivered,
        )
        .length;
    final spent = orders.fold<double>(0, (total, order) => total + order.total);
    return <_OrdersMetricData>[
      _OrdersMetricData(
        label: 'Active',
        value: '$active',
        icon: Icons.delivery_dining_rounded,
        accentColor: const Color(0xFFFF7E4D),
        backgroundColor: const Color(0xFFFFF2E8),
      ),
      _OrdersMetricData(
        label: 'Delivered',
        value: '$delivered',
        icon: Icons.receipt_long_rounded,
        accentColor: const Color(0xFF2F8A7E),
        backgroundColor: const Color(0xFFF1F8F5),
      ),
      _OrdersMetricData(
        label: 'Spent',
        value: '\$${spent.toStringAsFixed(0)}',
        icon: Icons.stars_rounded,
        accentColor: const Color(0xFFB56A45),
        backgroundColor: const Color(0xFFFFF4EC),
      ),
    ];
  }

  _OrderStatus get _liveOrderStatus {
    if (orders.isEmpty) {
      return _activeStatus;
    }
    final live = orders.where(
      (order) => !_orderStatusIsTerminal(_statusFromString(order.status)),
    );
    return live.isEmpty
        ? _OrderStatus.delivered
        : _statusFromString(live.first.status);
  }

  _PastOrderEntryData _pastOrderFromCustomerOrder(CustomerOrder order) {
    final firstImage = order.items.isEmpty ? null : order.items.first.imageUrl;
    return _PastOrderEntryData(
      title: order.restaurantName,
      summary: order.itemSummary,
      dateLabel: order.createdAt == null
          ? 'Recently'
          : _reviewTimeLabel(order.createdAt!),
      totalLabel: '\$${order.total.toStringAsFixed(2)}',
      status: _statusFromString(order.status),
      imageUrl:
          firstImage ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
      reorderItems: order.items
          .map((item) {
            return _CartLineItemData(
              title: item.title,
              subtitle: item.subtitle,
              imageUrl: item.imageUrl,
              price: item.unitPrice,
              quantity: item.quantity,
              restaurantName: order.restaurantName,
              menuItemId: item.menuItemId,
            );
          })
          .toList(growable: false),
    );
  }

  _OrderReceiptData _receiptFromCustomerOrder(CustomerOrder order) {
    return _OrderReceiptData(
      orderId: order.id.isEmpty ? 'HR' : 'HR-${order.id}',
      restaurantName: order.restaurantName,
      summary: order.itemSummary,
      placedAtLabel: order.createdAt == null
          ? 'Recently'
          : _reviewTimeLabel(order.createdAt!),
      status: _statusFromString(order.status),
      imageUrl: order.items.isEmpty
          ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80'
          : order.items.first.imageUrl,
      paymentMethodLabel: 'App order',
      deliveryFee: order.fees,
      serviceFee: 0,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: order.items
          .map((item) {
            return _OrderReceiptLineItemData(
              title: item.title,
              subtitle: item.subtitle,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            );
          })
          .toList(growable: false),
    );
  }

  _OrderStatus _statusFromString(String value) {
    switch (value.trim().toLowerCase().replaceAll('-', '_')) {
      case 'accepted':
        return _OrderStatus.accepted;
      case 'preparing':
      case 'in_progress':
        return _OrderStatus.preparing;
      case 'ready':
        return _OrderStatus.ready;
      case 'on_the_way':
      case 'out_for_delivery':
        return _OrderStatus.onTheWay;
      case 'delivered':
      case 'completed':
        return _OrderStatus.delivered;
      case 'canceled':
      case 'cancelled':
        return _OrderStatus.canceled;
      case 'rejected':
        return _OrderStatus.rejected;
      default:
        return _OrderStatus.pending;
    }
  }

  void _openOrderHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrdersReceiptsScreen(receipts: _displayReceipts),
      ),
    );
  }

  List<_RestaurantCartData> _cartListFromCustomerCart(CustomerCart cart) {
    final resolvedRestaurantName = cart.restaurantName.trim();
    final items = cart.items
        .map((item) {
          final menuItem = item.menuItem;
          final subtitle = item.notes.trim().isNotEmpty
              ? item.notes.trim()
              : menuItem.description;
          return _CartLineItemData(
            title: menuItem.title,
            subtitle: subtitle,
            imageUrl: menuItem.imageUrl,
            price: item.unitPrice > 0 ? item.unitPrice : (menuItem.price ?? 0),
            quantity: item.quantity,
            restaurantName: resolvedRestaurantName,
            menuItemId: item.menuItemId,
            cartItemId: item.id,
          );
        })
        .toList(growable: false);
    if (items.isEmpty) {
      return const <_RestaurantCartData>[];
    }
    final fallbackName = _firstRestaurantNameFromItems(items);
    final restaurantName = resolvedRestaurantName.isNotEmpty
        ? resolvedRestaurantName
        : (fallbackName.isEmpty ? 'Restaurant' : fallbackName);
    final normalizedItems = items
        .map((item) => item.copyWith(restaurantName: restaurantName))
        .toList(growable: false);
    return <_RestaurantCartData>[
      _RestaurantCartData(
        restaurantName: restaurantName,
        items: normalizedItems,
      ),
    ];
  }

  Future<void> _openCart(
    BuildContext context, {
    List<_CartLineItemData>? initialItems,
    String? restaurantName,
  }) async {
    if (initialItems == null) {
      final token = authToken.trim();
      var cartList = const <_RestaurantCartData>[];
      if (token.isNotEmpty) {
        final customerApiService = CustomerApiService();
        try {
          final cart = await customerApiService.fetchCart(token: token);
          cartList = _cartListFromCustomerCart(cart);
        } on CustomerApiException catch (e) {
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(e.message)));
        } finally {
          customerApiService.dispose();
        }
      }
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OrdersCartListScreen(
            carts: cartList,
            authToken: token.isEmpty ? null : token,
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrdersCartScreen(
          initialItems: initialItems,
          restaurantName: restaurantName,
          authToken: authToken,
        ),
      ),
    );
  }

  void _reorderPastOrder(BuildContext context, _PastOrderEntryData order) {
    _openCart(
      context,
      initialItems: order.reorderItems,
      restaurantName: order.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;
    final displayPastOrders = _displayPastOrders;

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAreaPadding = MediaQuery.paddingOf(context);
        final safeHeight =
            constraints.maxHeight -
            safeAreaPadding.top -
            safeAreaPadding.bottom;
        final metrics = _ResponsiveMetrics.from(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight > 0 ? safeHeight : constraints.maxHeight,
          ),
        );
        final navBarBottomInset = safeAreaPadding.bottom;
        final navBarTotalHeight = metrics.navHeight + navBarBottomInset;
        return Stack(
          children: [
            const Positioned.fill(child: _OrdersBackground()),
            Positioned.fill(
              bottom: navBarTotalHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    _clampDouble(metrics.topPadding + 6, 12, 20),
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orders',
                                  style: TextStyle(
                                    color: const Color(0xFF231A16),
                                    fontSize: _clampDouble(
                                      34 * metrics.scale,
                                      26,
                                      34,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                SizedBox(
                                  height: _clampDouble(6 * metrics.scale, 4, 6),
                                ),
                                Text(
                                  'Track deliveries and reorder favorites for $greetingName',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF7F6D61),
                                    fontSize: _clampDouble(
                                      15 * metrics.scale,
                                      12,
                                      15,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ProfileIconButton(
                            icon: Icons.receipt_long_rounded,
                            metrics: metrics,
                            onTap: () => _openOrderHistory(context),
                          ),
                          SizedBox(
                            width: _clampDouble(10 * metrics.scale, 8, 10),
                          ),
                          _ProfileIconButton(
                            icon: Icons.shopping_cart_checkout_rounded,
                            metrics: metrics,
                            onTap: () => _openCart(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(20 * metrics.scale, 16, 20),
                      ),
                      if (isLoading || errorMessage != null) ...[
                        _ProfilePanel(
                          child: Padding(
                            padding: EdgeInsets.all(
                              _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            child: Row(
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.cloud_off_rounded,
                                    color: Color(0xFFB7372B),
                                  ),
                                SizedBox(
                                  width: _clampDouble(
                                    10 * metrics.scale,
                                    8,
                                    10,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    isLoading
                                        ? 'Loading orders from the database...'
                                        : errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF7D6C60),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!isLoading)
                                  TextButton(
                                    onPressed: onRefresh,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _clampDouble(16 * metrics.scale, 12, 16),
                        ),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OrdersHeroCard(
                                metrics: metrics,
                                metricsData: _displayHeroMetrics,
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              const _ProfileSectionHeader(
                                title: 'Live Order',
                                actionLabel: 'Need Help?',
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              _ActiveOrderCard(
                                metrics: metrics,
                                currentStatus: _liveOrderStatus,
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              const _ProfileSectionHeader(
                                title: 'Recent Orders',
                                actionLabel: 'View All',
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              if (displayPastOrders.isEmpty)
                                _ProfilePanel(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      _clampDouble(18 * metrics.scale, 14, 18),
                                    ),
                                    child: const Text(
                                      'No order history found in the database yet.',
                                      style: TextStyle(
                                        color: Color(0xFF7D6C60),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: List.generate(
                                    displayPastOrders.length,
                                    (index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              index ==
                                                  displayPastOrders.length - 1
                                              ? 0
                                              : _clampDouble(
                                                  14 * metrics.scale,
                                                  10,
                                                  14,
                                                ),
                                        ),
                                        child: _PastOrderCard(
                                          data: displayPastOrders[index],
                                          metrics: metrics,
                                          onReorder: () => _reorderPastOrder(
                                            context,
                                            displayPastOrders[index],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(12 * metrics.scale, 8, 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNavBar(
                metrics: metrics,
                selectedIndex: selectedBottomIndex,
                onSelected: onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrdersReceiptsScreen extends StatelessWidget {
  const _OrdersReceiptsScreen({required this.receipts});

  final List<_OrderReceiptData> receipts;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final metrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Order Receipts',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: receipts.isEmpty
            ? const Center(
                child: Text(
                  'No receipts available yet.',
                  style: TextStyle(
                    color: Color(0xFF7D6C60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: receipts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final receipt = receipts[index];
                  return _OrderReceiptListTile(
                    receipt: receipt,
                    metrics: metrics,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _OrderReceiptDetailsScreen(receipt: receipt),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _OrderReceiptListTile extends StatelessWidget {
  const _OrderReceiptListTile({
    required this.receipt,
    required this.metrics,
    required this.onTap,
  });

  final _OrderReceiptData receipt;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final imageSize = _clampDouble(76 * metrics.scale, 64, 76);
    return _ProfilePanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 12, 14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FoodThumb(imageUrl: receipt.imageUrl, size: imageSize),
                SizedBox(width: _clampDouble(12 * metrics.scale, 10, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF231A16),
                          fontSize: _clampDouble(17 * metrics.scale, 14, 17),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                      Text(
                        '${receipt.orderId} - ${receipt.summary}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7E6D62),
                          fontSize: _clampDouble(
                            12.8 * metrics.scale,
                            11,
                            12.8,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
                      Wrap(
                        spacing: _clampDouble(8 * metrics.scale, 6, 8),
                        runSpacing: _clampDouble(8 * metrics.scale, 6, 8),
                        children: [
                          _OrdersInfoChip(
                            label: receipt.placedAtLabel,
                            icon: Icons.schedule_rounded,
                            metrics: metrics,
                          ),
                          _OrderStatusPill(
                            status: receipt.status,
                            metrics: metrics,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatUsd(receipt.totalUsd),
                      style: TextStyle(
                        color: const Color(0xFF231A16),
                        fontSize: _clampDouble(17 * metrics.scale, 14, 17),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFFB19D8F),
                      size: _clampDouble(24 * metrics.scale, 20, 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderReceiptDetailsScreen extends StatelessWidget {
  const _OrderReceiptDetailsScreen({required this.receipt});

  static const double _usdToLbpRate = 89500;

  final _OrderReceiptData receipt;

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatLbp(double usdValue) {
    final lbpValue = (usdValue * _usdToLbpRate).round();
    final withCommas = lbpValue.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas LBP';
  }

  List<_OrderTimelineStepData> _buildStages() {
    if (receipt.status == _OrderStatus.canceled ||
        receipt.status == _OrderStatus.rejected) {
      final steps = List<_OrderTimelineStepData>.generate(
        _orderStatusFlow.length,
        (index) {
          final stepStatus = _orderStatusFlow[index];
          return _OrderTimelineStepData(
            status: stepStatus,
            title: _orderStatusLabel(stepStatus),
            subtitle: _orderStatusDescription(stepStatus),
            icon: _orderStatusIcon(stepStatus),
            isComplete: index == 0,
            isCurrent: false,
          );
        },
      );
      steps.add(
        _OrderTimelineStepData(
          status: receipt.status,
          title: _orderStatusLabel(receipt.status),
          subtitle: _orderStatusDescription(receipt.status),
          icon: _orderStatusIcon(receipt.status),
          isComplete: false,
          isCurrent: true,
        ),
      );
      return steps;
    }

    final rawIndex = _orderStatusFlow.indexOf(receipt.status);
    final currentIndex = rawIndex.clamp(0, _orderStatusFlow.length - 1).toInt();
    return List<_OrderTimelineStepData>.generate(_orderStatusFlow.length, (
      index,
    ) {
      final stepStatus = _orderStatusFlow[index];
      return _OrderTimelineStepData(
        status: stepStatus,
        title: _orderStatusLabel(stepStatus),
        subtitle: _orderStatusDescription(stepStatus),
        icon: _orderStatusIcon(stepStatus),
        isComplete: index < currentIndex,
        isCurrent: index == currentIndex,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final metrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    final stages = _buildStages();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Receipt #${receipt.orderId}',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FoodThumb(
                      imageUrl: receipt.imageUrl,
                      size: _clampDouble(82 * metrics.scale, 70, 82),
                    ),
                    SizedBox(width: _clampDouble(12 * metrics.scale, 10, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF231A16),
                              fontSize: _clampDouble(
                                19 * metrics.scale,
                                16,
                                19,
                              ),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(
                            height: _clampDouble(4 * metrics.scale, 2, 4),
                          ),
                          Text(
                            receipt.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF7D6C60),
                              fontSize: _clampDouble(
                                13.5 * metrics.scale,
                                11,
                                13.5,
                              ),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(
                            height: _clampDouble(10 * metrics.scale, 8, 10),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _OrdersInfoChip(
                                label: receipt.placedAtLabel,
                                icon: Icons.schedule_rounded,
                                metrics: metrics,
                              ),
                              _OrdersInfoChip(
                                label: receipt.paymentMethodLabel,
                                icon: Icons.payments_rounded,
                                metrics: metrics,
                              ),
                              _OrderStatusPill(
                                status: receipt.status,
                                metrics: metrics,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CheckoutSectionCard(
              title: 'Order Stages',
              child: Column(
                children: List.generate(stages.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == stages.length - 1 ? 0 : 10,
                    ),
                    child: _OrderTimelineRow(
                      data: stages[index],
                      metrics: metrics,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _CheckoutSectionCard(
              title: 'Items Ordered (${receipt.totalItems})',
              child: Column(
                children: List.generate(receipt.items.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == receipt.items.length - 1 ? 0 : 8,
                    ),
                    child: _OrderReceiptItemTile(item: receipt.items[index]),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _CheckoutSectionCard(
              title: 'Receipt Details',
              child: Column(
                children: [
                  _OrdersPriceRow(
                    label: 'Subtotal',
                    value: _formatUsd(receipt.subtotalUsd),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Delivery fee',
                    value: _formatUsd(receipt.deliveryFee),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Service fee',
                    value: _formatUsd(receipt.serviceFee),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Discount (%)',
                    value: '${receipt.discountPercent.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Loyalty points used',
                    value: '${receipt.loyaltyPointsUsed} pts',
                  ),
                  if (receipt.loyaltyDiscountUsd > 0) ...[
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Loyalty discount',
                      value: '-${_formatUsd(receipt.loyaltyDiscountUsd)}',
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEADBCB)),
                  const SizedBox(height: 10),
                  _OrdersPriceRow(
                    label: 'Total (USD)',
                    value: _formatUsd(receipt.totalUsd),
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Total (LBP)',
                    value: _formatLbp(receipt.totalUsd),
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Payment',
                    value: receipt.paymentMethodLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderReceiptItemTile extends StatelessWidget {
  const _OrderReceiptItemTile({required this.item});

  final _OrderReceiptLineItemData item;

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E2D4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D6C60),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x${item.quantity}',
            style: const TextStyle(
              color: Color(0xFF7D6C60),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _formatUsd(item.totalPrice),
            style: const TextStyle(
              color: Color(0xFFFF7E4D),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersCartListScreen extends StatelessWidget {
  const _OrdersCartListScreen({required this.carts, this.authToken});

  final List<_RestaurantCartData> carts;
  final String? authToken;

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Your Carts',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: carts.isEmpty
              ? const Center(
                  child: Text(
                    'No carts yet. Add items from a restaurant first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7D6C60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF2D8C4)),
                      ),
                      child: const Text(
                        'Checkout supports one restaurant at a time.',
                        style: TextStyle(
                          color: Color(0xFF9B5B38),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: carts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cart = carts[index];
                          return _OrdersCartListTile(
                            restaurantName: cart.restaurantName,
                            totalItems: cart.totalItems,
                            subtotalLabel: _formatMoney(cart.subtotal),
                            coverImageUrl: cart.coverImageUrl,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _OrdersCartScreen(
                                    initialItems: cart.items,
                                    restaurantName: cart.restaurantName,
                                    authToken: authToken,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OrdersCartListTile extends StatelessWidget {
  const _OrdersCartListTile({
    required this.restaurantName,
    required this.totalItems,
    required this.subtotalLabel,
    required this.coverImageUrl,
    required this.onTap,
  });

  final String restaurantName;
  final int totalItems;
  final String subtotalLabel;
  final String coverImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0DCCB)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  coverImageUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: const Color(0xFFFFE9D7),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFFFF7E4D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalItems item${totalItems == 1 ? '' : 's'} • $subtotalLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E8A7E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersCartScreen extends StatefulWidget {
  const _OrdersCartScreen({
    required this.initialItems,
    this.restaurantName,
    this.authToken,
  });

  final List<_CartLineItemData> initialItems;
  final String? restaurantName;
  final String? authToken;

  @override
  State<_OrdersCartScreen> createState() => _OrdersCartScreenState();
}

class _OrdersCartScreenState extends State<_OrdersCartScreen> {
  static const double _deliveryFee = 2.75;
  static const double _serviceFee = 1.35;

  final _customerApiService = CustomerApiService();
  late List<_CartLineItemData> _items;
  late String _restaurantName;
  bool _isSyncingCart = false;
  String? _cartSyncError;

  @override
  void initState() {
    super.initState();
    final explicitRestaurant = widget.restaurantName?.trim() ?? '';
    final fallbackRestaurant = _firstRestaurantNameFromItems(
      widget.initialItems,
    );
    _restaurantName = explicitRestaurant.isNotEmpty
        ? explicitRestaurant
        : fallbackRestaurant;
    final targetRestaurant = _restaurantName.isEmpty
        ? fallbackRestaurant
        : _restaurantName;
    final normalizedTarget = _normalizeRestaurantKey(targetRestaurant);
    final removedRestaurants = <String>{};
    var removedCount = 0;

    _items = widget.initialItems
        .where((item) {
          if (normalizedTarget.isEmpty) {
            return true;
          }
          final resolvedRestaurant = _resolvedCartItemRestaurantName(item);
          if (resolvedRestaurant.isEmpty) {
            return true;
          }
          final matches =
              _normalizeRestaurantKey(resolvedRestaurant) == normalizedTarget;
          if (!matches) {
            removedCount += 1;
            removedRestaurants.add(resolvedRestaurant);
          }
          return matches;
        })
        .map(
          (item) => item.copyWith(
            title: item.title,
            subtitle: item.subtitle,
            imageUrl: item.imageUrl,
            price: item.price,
            quantity: item.quantity,
            restaurantName: item.restaurantName.trim().isEmpty
                ? _restaurantName
                : item.restaurantName,
          ),
        )
        .toList();
    if (removedCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final removedLabel = removedRestaurants.join(', ');
        final removedSource = removedLabel.isEmpty
            ? 'another restaurant'
            : removedLabel;
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'You can order from one restaurant only. Removed $removedCount item${removedCount == 1 ? '' : 's'} from $removedSource.',
              ),
            ),
          );
      });
    }
    _syncCartWithDatabase();
  }

  @override
  void dispose() {
    _customerApiService.dispose();
    super.dispose();
  }

  int get _totalItems =>
      _items.fold<int>(0, (total, item) => total + item.quantity);

  double get _subtotal => _items.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );

  double get _total => _subtotal + _deliveryFee + _serviceFee;

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  Future<void> _syncCartWithDatabase() async {
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      return;
    }
    setState(() {
      _isSyncingCart = true;
      _cartSyncError = null;
    });
    try {
      CustomerCart cart;
      final initialApiItems = _items
          .where((item) => (item.menuItemId ?? '').trim().isNotEmpty)
          .toList(growable: false);
      if (initialApiItems.isEmpty) {
        cart = await _customerApiService.fetchCart(token: token);
      } else {
        cart = await _customerApiService.fetchCart(token: token);
        for (final item in initialApiItems) {
          cart = await _customerApiService.addCartItem(
            token: token,
            menuItemId: item.menuItemId!.trim(),
            quantity: item.quantity,
          );
        }
      }
      if (!mounted) {
        return;
      }
      _applyCart(cart);
    } on CustomerApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncingCart = false;
        _cartSyncError = e.message;
      });
    }
  }

  void _applyCart(CustomerCart cart) {
    setState(() {
      final backendRestaurant = cart.restaurantName.trim();
      if (backendRestaurant.isNotEmpty) {
        _restaurantName = backendRestaurant;
      } else if (cart.items.isEmpty) {
        // Keep UI aligned with database state: no items means no active cart.
        _restaurantName = '';
      }
      _items = cart.items.map(_cartLineFromApi).toList(growable: false);
      _isSyncingCart = false;
      _cartSyncError = null;
    });
  }

  _CartLineItemData _cartLineFromApi(CustomerCartItem item) {
    return _CartLineItemData(
      title: item.menuItem.title,
      subtitle: item.notes.isEmpty ? item.menuItem.description : item.notes,
      imageUrl: item.menuItem.imageUrl,
      price: item.unitPrice > 0 ? item.unitPrice : item.menuItem.price ?? 0,
      quantity: item.quantity,
      restaurantName: _restaurantName,
      menuItemId: item.menuItemId,
      cartItemId: item.id,
    );
  }

  Future<void> _increaseQuantity(int index) async {
    final item = _items[index];
    final nextQuantity = item.quantity + 1;
    setState(() {
      _items[index] = item.copyWith(quantity: nextQuantity);
    });
    await _updateCartItemQuantity(index, nextQuantity);
  }

  Future<void> _decreaseQuantity(int index) async {
    final item = _items[index];
    if (item.quantity <= 1) {
      await _removeItem(index);
      return;
    }
    final nextQuantity = item.quantity - 1;
    setState(() {
      _items[index] = item.copyWith(quantity: nextQuantity);
    });
    await _updateCartItemQuantity(index, nextQuantity);
  }

  Future<void> _removeItem(int index) async {
    final item = _items[index];
    setState(() => _items.removeAt(index));
    final token = widget.authToken?.trim() ?? '';
    final cartItemId = item.cartItemId?.trim() ?? '';
    if (token.isEmpty || cartItemId.isEmpty) {
      return;
    }
    try {
      final cart = await _customerApiService.removeCartItem(
        token: token,
        cartItemId: cartItemId,
      );
      if (mounted) {
        _applyCart(cart);
      }
    } on CustomerApiException catch (e) {
      if (mounted) {
        setState(() => _cartSyncError = e.message);
      }
    }
  }

  Future<void> _updateCartItemQuantity(int index, int quantity) async {
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty || index >= _items.length) {
      return;
    }
    final cartItemId = _items[index].cartItemId?.trim() ?? '';
    if (cartItemId.isEmpty) {
      return;
    }
    try {
      final cart = await _customerApiService.updateCartItem(
        token: token,
        cartItemId: cartItemId,
        quantity: quantity,
      );
      if (mounted) {
        _applyCart(cart);
      }
    } on CustomerApiException catch (e) {
      if (mounted) {
        setState(() => _cartSyncError = e.message);
      }
    }
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) {
      return;
    }
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _OrdersCheckoutScreen(
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          serviceFee: _serviceFee,
          totalItems: _totalItems,
        ),
      ),
    );
    if (!mounted || placed != true) {
      return;
    }
    final placedTotal = _total;
    final placedItems = _totalItems;
    final token = widget.authToken?.trim() ?? '';
    if (token.isNotEmpty) {
      try {
        await _customerApiService.placeOrder(token: token);
      } on CustomerApiException catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _items.clear());
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Order placed for ${_formatMoney(placedTotal)} ($placedItems items)',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${_restaurantName.isEmpty ? 'Cart' : '$_restaurantName Cart'} ($_totalItems)',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF1E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Color(0xFFFF7E4D),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          color: Color(0xFF231A16),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add menu items to continue to checkout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7D6C60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7E4D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to orders',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_isSyncingCart || _cartSyncError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _cartSyncError == null
                              ? const Color(0xFFFFF3E9)
                              : const Color(0xFFFFF1EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _cartSyncError == null
                                ? const Color(0xFFF4D6BF)
                                : const Color(0xFFFFD2C2),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isSyncingCart)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: Color(0xFFB7372B),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isSyncingCart
                                    ? 'Syncing cart with the database...'
                                    : _cartSyncError!,
                                style: const TextStyle(
                                  color: Color(0xFF7D6C60),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _OrdersCartItemTile(
                            item: item,
                            onIncrease: () => _increaseQuantity(index),
                            onDecrease: () => _decreaseQuantity(index),
                            onRemove: () => _removeItem(index),
                            priceLabel: _formatMoney(
                              item.price * item.quantity,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0DCCB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12A7633A),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _OrdersPriceRow(
                            label: 'Subtotal',
                            value: _formatMoney(_subtotal),
                          ),
                          const SizedBox(height: 8),
                          _OrdersPriceRow(
                            label: 'Delivery fee',
                            value: _formatMoney(_deliveryFee),
                          ),
                          const SizedBox(height: 8),
                          _OrdersPriceRow(
                            label: 'Service fee',
                            value: _formatMoney(_serviceFee),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFEADBCB)),
                          const SizedBox(height: 10),
                          _OrdersPriceRow(
                            label: 'Total',
                            value: _formatMoney(_total),
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSyncingCart ? null : _checkout,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7E4D),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_rounded),
                        label: Text(
                          'Checkout ${_formatMoney(_total)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OrdersCartItemTile extends StatelessWidget {
  const _OrdersCartItemTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.priceLabel,
  });

  final _CartLineItemData item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCCB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 74,
              height: 74,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD6B4), Color(0xFFFF9C6C)],
                      ),
                    ),
                    child: Icon(
                      Icons.fastfood_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D6C60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Color(0xFFFF7E4D),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _OrdersQtyButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Color(0xFF231A16),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _OrdersQtyButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB66541),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text(
                      'Remove',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersQtyButton extends StatelessWidget {
  const _OrdersQtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF2DCCB)),
          ),
          child: Icon(icon, color: const Color(0xFF9D5F3E), size: 18),
        ),
      ),
    );
  }
}

class _OrdersPriceRow extends StatelessWidget {
  const _OrdersPriceRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFF231A16) : const Color(0xFF7D6C60);
    final weight = highlight ? FontWeight.w900 : FontWeight.w700;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: weight, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: weight, fontSize: 14),
        ),
      ],
    );
  }
}

enum _CheckoutPaymentMethod { onDelivery, visa, whishMoney }

enum _CheckoutChangeRequest { noNeed, usd50, usd100 }

enum _CheckoutDeliveryMode { now, scheduled }

class _CheckoutScheduledSlot {
  const _CheckoutScheduledSlot({
    required this.dayLabel,
    required this.timeRange,
  });

  final String dayLabel;
  final String timeRange;
}

class _CheckoutDeliverySelection {
  const _CheckoutDeliverySelection({
    required this.mode,
    required this.slotIndex,
  });

  final _CheckoutDeliveryMode mode;
  final int slotIndex;
}

class _CheckoutLocationData {
  const _CheckoutLocationData({
    required this.city,
    required this.street,
    required this.building,
    this.floor = '',
    this.apartment = '',
    this.landmark = '',
  });

  final String city;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String landmark;

  bool get hasRequiredFields =>
      city.trim().isNotEmpty &&
      street.trim().isNotEmpty &&
      building.trim().isNotEmpty;

  bool get hasAnyField =>
      city.trim().isNotEmpty ||
      street.trim().isNotEmpty ||
      building.trim().isNotEmpty ||
      floor.trim().isNotEmpty ||
      apartment.trim().isNotEmpty ||
      landmark.trim().isNotEmpty;
}

class _OrdersCheckoutScreen extends StatefulWidget {
  const _OrdersCheckoutScreen({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalItems,
  });

  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final int totalItems;

  @override
  State<_OrdersCheckoutScreen> createState() => _OrdersCheckoutScreenState();
}

class _OrdersCheckoutScreenState extends State<_OrdersCheckoutScreen> {
  static const double _usdToLbpRate = 89500;
  static const double _loyaltyDiscountRate = 0.10;
  static const int _loyaltyPointsPerUsdDiscount = 100;
  static const List<_CheckoutScheduledSlot> _deliverySlots = [
    _CheckoutScheduledSlot(dayLabel: 'Today', timeRange: '08:00 AM - 08:15 AM'),
    _CheckoutScheduledSlot(
      dayLabel: 'Tomorrow',
      timeRange: '08:15 AM - 08:30 AM',
    ),
    _CheckoutScheduledSlot(
      dayLabel: 'Monday, May 04',
      timeRange: '08:30 AM - 08:45 AM',
    ),
  ];

  _CheckoutDeliveryMode _deliveryMode = _CheckoutDeliveryMode.now;
  int _scheduledSlotIndex = 1;
  _CheckoutLocationData _location = const _CheckoutLocationData(
    city: '',
    street: '',
    building: '',
  );
  _CheckoutPaymentMethod _paymentMethod = _CheckoutPaymentMethod.onDelivery;
  _CheckoutChangeRequest _changeRequest = _CheckoutChangeRequest.noNeed;
  bool _useLoyalty = false;
  bool _saveChangeInWallet = false;

  double get _baseTotalUsd =>
      widget.subtotal + widget.deliveryFee + widget.serviceFee;

  double get _discountPercent => _useLoyalty ? (_loyaltyDiscountRate * 100) : 0;

  double get _loyaltyDiscountUsd =>
      _useLoyalty ? (_baseTotalUsd * _loyaltyDiscountRate) : 0;

  int get _loyaltyPointsUsed =>
      (_loyaltyDiscountUsd * _loyaltyPointsPerUsdDiscount).round();

  double get _totalUsd =>
      (_baseTotalUsd - _loyaltyDiscountUsd).clamp(0, double.infinity);

  int get _earnedPoints => (_totalUsd * 8).round();

  bool get _cashPayment => _paymentMethod == _CheckoutPaymentMethod.onDelivery;

  _CheckoutScheduledSlot get _selectedScheduledSlot {
    final maxIndex = _deliverySlots.length - 1;
    final safeIndex = _scheduledSlotIndex.clamp(0, maxIndex).toInt();
    return _deliverySlots[safeIndex];
  }

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatLbp(double usdValue) {
    final lbpValue = (usdValue * _usdToLbpRate).round();
    final withCommas = lbpValue.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas LBP';
  }

  String _paymentMethodLabel(_CheckoutPaymentMethod method) {
    switch (method) {
      case _CheckoutPaymentMethod.onDelivery:
        return 'On Delivery';
      case _CheckoutPaymentMethod.visa:
        return 'Visa';
      case _CheckoutPaymentMethod.whishMoney:
        return 'Whish Money';
    }
  }

  String _changeRequestLabel(_CheckoutChangeRequest request) {
    switch (request) {
      case _CheckoutChangeRequest.noNeed:
        return 'No need';
      case _CheckoutChangeRequest.usd50:
        return '\$50.00';
      case _CheckoutChangeRequest.usd100:
        return '\$100.00';
    }
  }

  String get _deliveryPrimaryLabel {
    if (_deliveryMode == _CheckoutDeliveryMode.now) {
      return 'Now';
    }
    return 'Schedule for later';
  }

  String get _deliverySecondaryLabel {
    if (_deliveryMode == _CheckoutDeliveryMode.now) {
      return 'Deliver immediately';
    }
    final slot = _selectedScheduledSlot;
    return '${slot.dayLabel} • ${slot.timeRange}';
  }

  String get _locationPrimaryLabel {
    if (_location.hasRequiredFields) {
      return '${_location.city}, ${_location.street}';
    }
    return 'Add delivery location';
  }

  String get _locationSecondaryLabel {
    if (!_location.hasAnyField) {
      return 'City, street, building';
    }
    final segments = <String>[
      if (_location.building.trim().isNotEmpty) 'Bldg ${_location.building}',
      if (_location.floor.trim().isNotEmpty) 'Floor ${_location.floor}',
      if (_location.apartment.trim().isNotEmpty) 'Apt ${_location.apartment}',
      if (_location.landmark.trim().isNotEmpty) _location.landmark,
    ];
    return segments.isEmpty ? 'City, street, building' : segments.join(', ');
  }

  void _selectPayment(_CheckoutPaymentMethod method) {
    setState(() {
      _paymentMethod = method;
      if (method != _CheckoutPaymentMethod.onDelivery) {
        _changeRequest = _CheckoutChangeRequest.noNeed;
        _saveChangeInWallet = false;
      }
    });
  }

  void _placeOrder() {
    if (!_location.hasRequiredFields) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please set your city, street, and building before placing the order.',
            ),
          ),
        );
      _openLocationEditor();
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _openDeliveryTimeSelector() async {
    final selection = await showModalBottomSheet<_CheckoutDeliverySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F2ED),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.none,
      builder: (context) => _CheckoutDeliveryTimeSheet(
        initialMode: _deliveryMode,
        initialSlotIndex: _scheduledSlotIndex,
        slots: _deliverySlots,
      ),
    );
    if (!mounted || selection == null) {
      return;
    }
    setState(() {
      _deliveryMode = selection.mode;
      final maxIndex = _deliverySlots.length - 1;
      _scheduledSlotIndex = selection.slotIndex.clamp(0, maxIndex).toInt();
    });
  }

  Future<void> _openLocationEditor() async {
    final location = await showModalBottomSheet<_CheckoutLocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F2ED),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.none,
      builder: (context) => _CheckoutLocationSheet(initialValue: _location),
    );
    if (!mounted || location == null) {
      return;
    }
    setState(() => _location = location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckoutSectionCard(
                title: 'Delivery Time',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openDeliveryTimeSelector,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFCFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8D8C8)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF1E7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _deliveryMode == _CheckoutDeliveryMode.now
                                      ? Icons.access_time_rounded
                                      : Icons.calendar_month_rounded,
                                  color: const Color(0xFFFF7E4D),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _deliveryPrimaryLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF2D251F),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _deliverySecondaryLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF8D7D71),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFB19D8F),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Default is now. Tap to schedule for later.',
                      style: TextStyle(
                        color: Color(0xFF8D7D71),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Location',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF1E7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF7E4D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationPrimaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF2D251F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _locationSecondaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8D7D71),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _openLocationEditor,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7E4D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Change',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set your city, street, and building details for delivery.',
                      style: TextStyle(
                        color: Color(0xFF8D7D71),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Payment Method',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _CheckoutPaymentMethod.values.map((method) {
                    final selected = _paymentMethod == method;
                    return ChoiceChip(
                      label: Text(_paymentMethodLabel(method)),
                      selected: selected,
                      onSelected: (value) {
                        if (!value) {
                          return;
                        }
                        _selectPayment(method);
                      },
                      selectedColor: const Color(0xFFFFE4D2),
                      side: const BorderSide(color: Color(0xFFEFD9C8)),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFFB65D37)
                            : const Color(0xFF7D6C60),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: const Color(0xFFFEFCFA),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Request Change',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _CheckoutChangeRequest.values.map((request) {
                        final selected = _changeRequest == request;
                        return ChoiceChip(
                          label: Text(_changeRequestLabel(request)),
                          selected: selected,
                          onSelected: !_cashPayment
                              ? null
                              : (value) {
                                  if (!value) {
                                    return;
                                  }
                                  setState(() => _changeRequest = request);
                                },
                          selectedColor: const Color(0xFFFFE4D2),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFFB65D37)
                                : const Color(0xFF7D6C60),
                            fontWeight: FontWeight.w700,
                          ),
                          side: const BorderSide(color: Color(0xFFEFD9C8)),
                          backgroundColor: const Color(0xFFFEFCFA),
                        );
                      }).toList(),
                    ),
                    if (!_cashPayment) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Change request is available for cash on delivery only.',
                        style: TextStyle(
                          color: Color(0xFF8D7D71),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Use Loyalty?',
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('No'),
                      selected: !_useLoyalty,
                      onSelected: (_) => setState(() => _useLoyalty = false),
                      selectedColor: const Color(0xFFFFE4D2),
                      side: const BorderSide(color: Color(0xFFEFD9C8)),
                      labelStyle: TextStyle(
                        color: !_useLoyalty
                            ? const Color(0xFFB65D37)
                            : const Color(0xFF7D6C60),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: const Color(0xFFFEFCFA),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Yes'),
                      selected: _useLoyalty,
                      onSelected: (_) => setState(() => _useLoyalty = true),
                      selectedColor: const Color(0xFFFFE4D2),
                      side: const BorderSide(color: Color(0xFFEFD9C8)),
                      labelStyle: TextStyle(
                        color: _useLoyalty
                            ? const Color(0xFFB65D37)
                            : const Color(0xFF7D6C60),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: const Color(0xFFFEFCFA),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Wallet',
                child: SwitchListTile.adaptive(
                  value: _saveChangeInWallet,
                  onChanged: _cashPayment
                      ? (value) => setState(() => _saveChangeInWallet = value)
                      : null,
                  activeThumbColor: const Color(0xFFFF7E4D),
                  activeTrackColor: const Color(0xFFFFD4BB),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Save change in my wallet',
                    style: TextStyle(
                      color: Color(0xFF2D251F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Turn on to save your returned cash as wallet credit.',
                    style: TextStyle(
                      color: Color(0xFF8D7D71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Receipt Details',
                child: Column(
                  children: [
                    _OrdersPriceRow(
                      label: 'Subtotal',
                      value: _formatUsd(widget.subtotal),
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Delivery fee',
                      value: _formatUsd(widget.deliveryFee),
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Service fee',
                      value: _formatUsd(widget.serviceFee),
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Loyalty points used',
                      value: '$_loyaltyPointsUsed pts',
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Discount (%)',
                      value: '${_discountPercent.toStringAsFixed(0)}%',
                    ),
                    if (_loyaltyDiscountUsd > 0) ...[
                      const SizedBox(height: 8),
                      _OrdersPriceRow(
                        label: 'Loyalty discount',
                        value: '-${_formatUsd(_loyaltyDiscountUsd)}',
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFEADBCB)),
                    const SizedBox(height: 10),
                    _OrdersPriceRow(
                      label: 'Total (USD)',
                      value: _formatUsd(_totalUsd),
                      highlight: true,
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Total (LBP)',
                      value: _formatLbp(_totalUsd),
                      highlight: true,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF6E5E53),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const TextSpan(text: 'You earned '),
                            TextSpan(
                              text: '$_earnedPoints',
                              style: const TextStyle(
                                color: Color(0xFFFF7E4D),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(text: ' points'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _placeOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    'Place Order (${widget.totalItems} items)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutLocationSheet extends StatefulWidget {
  const _CheckoutLocationSheet({required this.initialValue});

  final _CheckoutLocationData initialValue;

  @override
  State<_CheckoutLocationSheet> createState() => _CheckoutLocationSheetState();
}

class _CheckoutLocationSheetState extends State<_CheckoutLocationSheet> {
  late final TextEditingController _cityController;
  late final TextEditingController _streetController;
  late final TextEditingController _buildingController;
  late final TextEditingController _floorController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _landmarkController;
  bool _showRequiredError = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialValue.city);
    _streetController = TextEditingController(text: widget.initialValue.street);
    _buildingController = TextEditingController(
      text: widget.initialValue.building,
    );
    _floorController = TextEditingController(text: widget.initialValue.floor);
    _apartmentController = TextEditingController(
      text: widget.initialValue.apartment,
    );
    _landmarkController = TextEditingController(
      text: widget.initialValue.landmark,
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFEFCFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8D8C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8D8C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB893)),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF7D6C60),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB3A295),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _save() {
    final city = _cityController.text.trim();
    final street = _streetController.text.trim();
    final building = _buildingController.text.trim();
    if (city.isEmpty || street.isEmpty || building.isEmpty) {
      setState(() => _showRequiredError = true);
      return;
    }
    Navigator.of(context).pop(
      _CheckoutLocationData(
        city: city,
        street: street,
        building: building,
        floor: _floorController.text.trim(),
        apartment: _apartmentController.text.trim(),
        landmark: _landmarkController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ColoredBox(
      color: const Color(0xFFF6F2ED),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D5D1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delivery location',
                  style: TextStyle(
                    color: Color(0xFF1F1B19),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(label: 'City *', hint: 'Beirut'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _streetController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    label: 'Street *',
                    hint: 'Hamra Main Street',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _buildingController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    label: 'Building *',
                    hint: 'Building name or number',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _floorController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(label: 'Floor', hint: '3'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _apartmentController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          label: 'Apartment',
                          hint: 'A12',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _landmarkController,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDecoration(
                    label: 'Landmark',
                    hint: 'Near the pharmacy',
                  ),
                ),
                if (_showRequiredError) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Please fill city, street, and building.',
                    style: TextStyle(
                      color: Color(0xFFB7372B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E4D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save location',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutDeliveryTimeSheet extends StatefulWidget {
  const _CheckoutDeliveryTimeSheet({
    required this.initialMode,
    required this.initialSlotIndex,
    required this.slots,
  });

  final _CheckoutDeliveryMode initialMode;
  final int initialSlotIndex;
  final List<_CheckoutScheduledSlot> slots;

  @override
  State<_CheckoutDeliveryTimeSheet> createState() =>
      _CheckoutDeliveryTimeSheetState();
}

class _CheckoutDeliveryTimeSheetState
    extends State<_CheckoutDeliveryTimeSheet> {
  late _CheckoutDeliveryMode _mode;
  late int _slotIndex;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final maxIndex = widget.slots.length - 1;
    _slotIndex = widget.initialSlotIndex.clamp(0, maxIndex).toInt();
  }

  void _confirm() {
    Navigator.of(
      context,
    ).pop(_CheckoutDeliverySelection(mode: _mode, slotIndex: _slotIndex));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ColoredBox(
      color: const Color(0xFFF6F2ED),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D5D1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delivery time',
                  style: TextStyle(
                    color: Color(0xFF1F1B19),
                    fontSize: 34 * 0.56,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _CheckoutDeliveryModeTile(
                  title: 'Now',
                  icon: Icons.access_time_rounded,
                  selected: _mode == _CheckoutDeliveryMode.now,
                  onTap: () =>
                      setState(() => _mode = _CheckoutDeliveryMode.now),
                ),
                const SizedBox(height: 10),
                _CheckoutDeliveryModeTile(
                  title: 'Schedule For Later',
                  icon: Icons.calendar_month_rounded,
                  selected: _mode == _CheckoutDeliveryMode.scheduled,
                  onTap: () =>
                      setState(() => _mode = _CheckoutDeliveryMode.scheduled),
                ),
                if (_mode == _CheckoutDeliveryMode.scheduled) ...[
                  const SizedBox(height: 14),
                  ...List<Widget>.generate(widget.slots.length, (index) {
                    final slot = widget.slots[index];
                    final selected = index == _slotIndex;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.slots.length - 1 ? 0 : 8,
                      ),
                      child: _CheckoutScheduleSlotTile(
                        dayLabel: slot.dayLabel,
                        timeRange: slot.timeRange,
                        selected: selected,
                        onTap: () => setState(() => _slotIndex = index),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E4D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirm delivery time',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutDeliveryModeTile extends StatelessWidget {
  const _CheckoutDeliveryModeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEFE4) : const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFC5A8)
                  : const Color(0xFFE8D8C8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFFFF7E4D)
                    : const Color(0xFF8D7D71),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF2D251F),
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFFF7E4D)
                    : const Color(0xFFB7A89B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutScheduleSlotTile extends StatelessWidget {
  const _CheckoutScheduleSlotTile({
    required this.dayLabel,
    required this.timeRange,
    required this.selected,
    required this.onTap,
  });

  final String dayLabel;
  final String timeRange;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFF1F1B19)
        : const Color(0xFF9A8C82);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2ECE6) : const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE8D8C8)
                  : const Color(0xFFF0E6DC),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                timeRange,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSectionCard extends StatelessWidget {
  const _CheckoutSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF231A16),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _OrdersBackground extends StatelessWidget {
  const _OrdersBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFBF7), Color(0xFFF4E5D7)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -56,
          right: -46,
          child: Container(
            width: 210,
            height: 210,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x32FFD4B4), Color(0x00FFD4B4)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 210,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x22F3C49C), Color(0x00F3C49C)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 130,
          right: -54,
          child: Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x1FE6B58D), Color(0x00E6B58D)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersHeroCard extends StatelessWidget {
  const _OrdersHeroCard({required this.metrics, required this.metricsData});

  final _ResponsiveMetrics metrics;
  final List<_OrdersMetricData> metricsData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_clampDouble(20 * metrics.scale, 16, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF2E5), Color(0xFFFFD5B7)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF2D9C4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B56A45),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = _clampDouble(12 * metrics.scale, 8, 12);
          final compactGrid = metrics.tiny || constraints.maxWidth < 320;
          final tileWidth = compactGrid
              ? (constraints.maxWidth - gap) / 2
              : (constraints.maxWidth - (gap * 2)) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: metricsData
                .map(
                  (data) => SizedBox(
                    width: tileWidth,
                    child: _OrdersMetricCard(data: data, metrics: metrics),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _OrdersMetricCard extends StatelessWidget {
  const _OrdersMetricCard({required this.data, required this.metrics});

  final _OrdersMetricData data;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 12, 14)),
      decoration: BoxDecoration(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _clampDouble(38 * metrics.scale, 32, 38),
            height: _clampDouble(38 * metrics.scale, 32, 38),
            decoration: BoxDecoration(
              color: data.accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: _clampDouble(20 * metrics.scale, 16, 20),
            ),
          ),
          SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF231A16),
              fontSize: _clampDouble(22 * metrics.scale, 18, 22),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF7F6D61),
              fontSize: _clampDouble(13 * metrics.scale, 11, 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.metrics, required this.currentStatus});

  final _ResponsiveMetrics metrics;
  final _OrderStatus currentStatus;

  void _openOrderTracking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrderTrackingScreen(
          orderId: 'HR-2048',
          restaurantName: 'Burger Station',
          itemSummary: 'Double smash burger combo with Cajun fries',
          status: currentStatus,
          etaLabel: '8 min',
          totalLabel: '\$24.50',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildOrderTimeline(currentStatus);
    final actionLabel = currentStatus == _OrderStatus.onTheWay
        ? 'Track order'
        : _orderStatusIsTerminal(currentStatus)
        ? 'View details'
        : 'View progress';

    return _ProfilePanel(
      child: Padding(
        padding: EdgeInsets.all(_clampDouble(18 * metrics.scale, 14, 18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Burger Station',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF231A16),
                          fontSize: _clampDouble(22 * metrics.scale, 17, 22),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                      Text(
                        'Double smash burger combo with Cajun fries',
                        maxLines: metrics.compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7E6D62),
                          fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
                _OrderStatusPill(
                  status: currentStatus,
                  metrics: metrics,
                  showIcon: false,
                  compact: true,
                ),
              ],
            ),
            SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
            Text(
              _orderStatusDescription(currentStatus),
              maxLines: metrics.compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF7E6D62),
                fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
            Wrap(
              spacing: _clampDouble(10 * metrics.scale, 8, 10),
              runSpacing: _clampDouble(8 * metrics.scale, 6, 8),
              children: [
                _OrdersInfoChip(
                  label: currentStatus == _OrderStatus.onTheWay
                      ? 'ETA 8 min'
                      : _orderStatusLabel(currentStatus),
                  icon: currentStatus == _OrderStatus.onTheWay
                      ? Icons.timer_outlined
                      : _orderStatusIcon(currentStatus),
                  metrics: metrics,
                ),
                _OrdersInfoChip(
                  label: 'Order #HR-2048',
                  icon: Icons.tag_rounded,
                  metrics: metrics,
                ),
                _OrdersInfoChip(
                  label: 'Paid online',
                  icon: Icons.credit_card_rounded,
                  metrics: metrics,
                ),
              ],
            ),
            SizedBox(height: _clampDouble(18 * metrics.scale, 14, 18)),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _orderStatusProgress(currentStatus),
                minHeight: _clampDouble(10 * metrics.scale, 8, 10),
                backgroundColor: const Color(0xFFF2E4D7),
                color: _orderStatusAccentColor(currentStatus),
              ),
            ),
            SizedBox(height: _clampDouble(18 * metrics.scale, 14, 18)),
            Column(
              children: List.generate(steps.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == steps.length - 1
                        ? 0
                        : _clampDouble(12 * metrics.scale, 8, 12),
                  ),
                  child: _OrderTimelineRow(
                    data: steps[index],
                    metrics: metrics,
                  ),
                );
              }),
            ),
            SizedBox(height: _clampDouble(18 * metrics.scale, 14, 18)),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 330;
                final totalBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Total',
                      style: TextStyle(
                        color: const Color(0xFF8A796D),
                        fontSize: _clampDouble(13 * metrics.scale, 11, 13),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                    Text(
                      '\$24.50',
                      style: TextStyle(
                        color: const Color(0xFF231A16),
                        fontSize: _clampDouble(24 * metrics.scale, 18, 24),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
                final action = _OrdersActionPill(
                  label: actionLabel,
                  filled: true,
                  metrics: metrics,
                  onTap: () => _openOrderTracking(context),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      totalBlock,
                      SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                      action,
                    ],
                  );
                }
                return Row(children: [totalBlock, const Spacer(), action]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({
    required this.status,
    required this.metrics,
    this.showIcon = true,
    this.compact = false,
  });

  final _OrderStatus status;
  final _ResponsiveMetrics metrics;
  final bool showIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(
          compact ? 12 * metrics.scale : 10 * metrics.scale,
          8,
          12,
        ),
        vertical: _clampDouble(
          compact ? 8 * metrics.scale : 6 * metrics.scale,
          5,
          8,
        ),
      ),
      decoration: BoxDecoration(
        color: _orderStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _orderStatusIcon(status),
              color: _orderStatusAccentColor(status),
              size: _clampDouble(15 * metrics.scale, 13, 15),
            ),
            SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
          ],
          Text(
            _orderStatusLabel(status),
            style: TextStyle(
              color: _orderStatusAccentColor(status),
              fontSize: _clampDouble(12.5 * metrics.scale, 10, 12.5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersInfoChip extends StatelessWidget {
  const _OrdersInfoChip({
    required this.label,
    required this.icon,
    required this.metrics,
  });

  final String label;
  final IconData icon;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(12 * metrics.scale, 10, 12),
        vertical: _clampDouble(8 * metrics.scale, 6, 8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E2D3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF8A7060),
            size: _clampDouble(16 * metrics.scale, 14, 16),
          ),
          SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF5D4C42),
              fontSize: _clampDouble(12.5 * metrics.scale, 10, 12.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimelineRow extends StatelessWidget {
  const _OrderTimelineRow({required this.data, required this.metrics});

  final _OrderTimelineStepData data;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = data.isCurrent
        ? _orderStatusAccentColor(data.status)
        : data.isComplete
        ? const Color(0xFF2F8A7E)
        : const Color(0xFFD9CABC);
    final Color panelColor = data.isCurrent
        ? _orderStatusBackgroundColor(data.status)
        : data.isComplete
        ? const Color(0xFFF1F8F5)
        : const Color(0xFFF8F1EA);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _clampDouble(42 * metrics.scale, 34, 42),
          height: _clampDouble(42 * metrics.scale, 34, 42),
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Icon(
            data.icon,
            color: Colors.white,
            size: _clampDouble(20 * metrics.scale, 16, 20),
          ),
        ),
        SizedBox(width: _clampDouble(12 * metrics.scale, 8, 12)),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(14 * metrics.scale, 10, 14),
              vertical: _clampDouble(12 * metrics.scale, 10, 12),
            ),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF231A16),
                    fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF7A695E),
                    fontSize: _clampDouble(13 * metrics.scale, 11, 13),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PastOrderCard extends StatelessWidget {
  const _PastOrderCard({
    required this.data,
    required this.metrics,
    this.onReorder,
  });

  final _PastOrderEntryData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final imageSize = _clampDouble(82 * metrics.scale, 68, 82);
    return _ProfilePanel(
      child: Padding(
        padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageToDetailsGap = _clampDouble(14 * metrics.scale, 10, 14);
            final detailsToActionsGap = _clampDouble(
              12 * metrics.scale,
              10,
              12,
            );
            final minDetailsWidth = _clampDouble(172 * metrics.scale, 156, 184);
            final minActionsWidth = _clampDouble(106 * metrics.scale, 98, 112);
            final minWidthForSideBySide =
                imageSize +
                imageToDetailsGap +
                minDetailsWidth +
                detailsToActionsGap +
                minActionsWidth;
            final compact = constraints.maxWidth < minWidthForSideBySide;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF231A16),
                    fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                Text(
                  data.summary,
                  maxLines: compact ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF7E6D62),
                    fontSize: _clampDouble(13.5 * metrics.scale, 11, 13.5),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
                Wrap(
                  spacing: _clampDouble(8 * metrics.scale, 6, 8),
                  runSpacing: _clampDouble(8 * metrics.scale, 6, 8),
                  children: [
                    _OrdersInfoChip(
                      label: data.dateLabel,
                      icon: Icons.schedule_rounded,
                      metrics: metrics,
                    ),
                    _OrderStatusPill(status: data.status, metrics: metrics),
                  ],
                ),
              ],
            );
            final actions = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.totalLabel,
                  style: TextStyle(
                    color: const Color(0xFF231A16),
                    fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
                _OrdersActionPill(
                  label:
                      data.status == _OrderStatus.rejected ||
                          data.status == _OrderStatus.canceled
                      ? 'Order again'
                      : 'Reorder',
                  filled: false,
                  metrics: metrics,
                  onTap: onReorder,
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FoodThumb(imageUrl: data.imageUrl, size: imageSize),
                      SizedBox(width: _clampDouble(12 * metrics.scale, 10, 12)),
                      Expanded(child: details),
                    ],
                  ),
                  SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FoodThumb(imageUrl: data.imageUrl, size: imageSize),
                SizedBox(width: imageToDetailsGap),
                Expanded(child: details),
                SizedBox(width: detailsToActionsGap),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersActionPill extends StatelessWidget {
  const _OrdersActionPill({
    required this.label,
    required this.filled,
    required this.metrics,
    this.onTap,
  });

  final String label;
  final bool filled;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(14 * metrics.scale, 12, 14),
            vertical: _clampDouble(9 * metrics.scale, 7, 9),
          ),
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFFF7E4D) : const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : const Color(0xFFB66541),
              fontSize: _clampDouble(13 * metrics.scale, 11, 13),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTrackingScreen extends StatelessWidget {
  const _OrderTrackingScreen({
    required this.orderId,
    required this.restaurantName,
    required this.itemSummary,
    required this.status,
    required this.etaLabel,
    required this.totalLabel,
  });

  final String orderId;
  final String restaurantName;
  final String itemSummary;
  final _OrderStatus status;
  final String etaLabel;
  final String totalLabel;

  int _currentStepIndexForStatus() {
    switch (status) {
      case _OrderStatus.pending:
        return 0;
      case _OrderStatus.accepted:
        return 1;
      case _OrderStatus.preparing:
        return 2;
      case _OrderStatus.ready:
        return 3;
      case _OrderStatus.onTheWay:
        return 4;
      case _OrderStatus.delivered:
        return 5;
      case _OrderStatus.canceled:
      case _OrderStatus.rejected:
        return 1;
    }
  }

  String _formatClockTime(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final meridiem = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $meridiem';
  }

  String _normalizedName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _openRestaurantDirectMessage(BuildContext context) async {
    final repository = DemoAppRepository.instance;
    final threads = await repository.getThreads();
    if (!context.mounted) {
      return;
    }
    if (threads.isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No messages available yet for this restaurant.'),
          ),
        );
      return;
    }

    final targetName = _normalizedName(restaurantName);
    DemoConversationThread? matchedThread;

    for (final thread in threads) {
      final mappedName =
          _customerRestaurantNamesByThreadId[thread.id] ?? thread.customerName;
      if (_normalizedName(mappedName) == targetName) {
        matchedThread = thread;
        break;
      }
    }

    if (matchedThread == null) {
      for (final thread in threads) {
        final mappedName =
            _customerRestaurantNamesByThreadId[thread.id] ??
            thread.customerName;
        final normalizedMapped = _normalizedName(mappedName);
        if (normalizedMapped.contains(targetName) ||
            targetName.contains(normalizedMapped)) {
          matchedThread = thread;
          break;
        }
      }
    }

    if (matchedThread == null) {
      final fallbackOrderThread = threads.firstWhere(
        (thread) => thread.type == MessageThreadType.order,
        orElse: () => threads.first,
      );
      matchedThread = fallbackOrderThread;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          threadId: matchedThread!.id,
          restaurantName: 'You',
          openComposerOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final placedAt = now.subtract(const Duration(minutes: 26));
    final viewport = MediaQuery.sizeOf(context);
    final trackingMetrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    final checkpoints = <_OrderTrackingStep>[
      _OrderTrackingStep(
        label: 'Order placed',
        subtitle: 'Payment confirmed and ticket sent to the restaurant.',
        time: placedAt,
        icon: Icons.shopping_bag_rounded,
      ),
      _OrderTrackingStep(
        label: 'Restaurant accepted',
        subtitle: 'The kitchen accepted your order and queued it.',
        time: placedAt.add(const Duration(minutes: 3)),
        icon: Icons.receipt_long_rounded,
      ),
      _OrderTrackingStep(
        label: 'Preparing',
        subtitle: 'Your meal is being cooked fresh.',
        time: placedAt.add(const Duration(minutes: 12)),
        icon: Icons.restaurant_rounded,
      ),
      _OrderTrackingStep(
        label: 'Packed and ready',
        subtitle: 'Order packed and assigned to a rider.',
        time: placedAt.add(const Duration(minutes: 17)),
        icon: Icons.inventory_2_rounded,
      ),
      _OrderTrackingStep(
        label: 'On the way',
        subtitle: 'Rider is heading to your location.',
        time: placedAt.add(const Duration(minutes: 20)),
        icon: Icons.delivery_dining_rounded,
      ),
      _OrderTrackingStep(
        label: 'Delivered',
        subtitle: 'Enjoy your meal!',
        time: placedAt.add(const Duration(minutes: 29)),
        icon: Icons.check_circle_rounded,
      ),
    ];
    final currentStepIndex = _currentStepIndexForStatus();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Track Order #$orderId',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
          children: [
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemSummary,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OrdersInfoChip(
                          label: 'ETA $etaLabel',
                          icon: Icons.timer_outlined,
                          metrics: trackingMetrics,
                        ),
                        _OrdersInfoChip(
                          label: totalLabel,
                          icon: Icons.payments_rounded,
                          metrics: trackingMetrics,
                        ),
                        _OrdersInfoChip(
                          label: 'Status ${_orderStatusLabel(status)}',
                          icon: _orderStatusIcon(status),
                          metrics: trackingMetrics,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (currentStepIndex + 1) / checkpoints.length,
                      minHeight: 9,
                      color: _orderStatusAccentColor(status),
                      backgroundColor: const Color(0xFFF2E4D7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: List.generate(checkpoints.length, (index) {
                    final step = checkpoints[index];
                    final isComplete = index <= currentStepIndex;
                    final isCurrent = index == currentStepIndex;
                    final isStatusFinished =
                        index < currentStepIndex ||
                        (_orderStatusIsTerminal(status) &&
                            index == currentStepIndex);
                    final previousTime = index == 0
                        ? null
                        : checkpoints[index - 1].time;
                    final durationLabel =
                        isStatusFinished && previousTime != null
                        ? 'Took ${step.time.difference(previousTime).inMinutes} min'
                        : null;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == checkpoints.length - 1 ? 0 : 10,
                      ),
                      child: _OrderTrackingTimelineTile(
                        step: step,
                        isComplete: isComplete,
                        isCurrent: isCurrent,
                        timeLabel: isComplete || isCurrent
                            ? _formatClockTime(step.time)
                            : null,
                        durationLabel: durationLabel,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Helpful Actions',
                      style: TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OrdersActionPill(
                          label: 'Contact restaurant',
                          filled: false,
                          metrics: trackingMetrics,
                          onTap: () => _openRestaurantDirectMessage(context),
                        ),
                        _OrdersActionPill(
                          label: 'Support chat',
                          filled: true,
                          metrics: trackingMetrics,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _CustomerHelpSupportScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTrackingStep {
  const _OrderTrackingStep({
    required this.label,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final DateTime time;
  final IconData icon;
}

class _OrderTrackingTimelineTile extends StatelessWidget {
  const _OrderTrackingTimelineTile({
    required this.step,
    required this.isComplete,
    required this.isCurrent,
    required this.timeLabel,
    required this.durationLabel,
  });

  final _OrderTrackingStep step;
  final bool isComplete;
  final bool isCurrent;
  final String? timeLabel;
  final String? durationLabel;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCurrent
        ? const Color(0xFFFF7E4D)
        : isComplete
        ? const Color(0xFF2F8A7E)
        : const Color(0xFFD9CABC);
    final panelColor = isCurrent
        ? const Color(0xFFFFF2E8)
        : isComplete
        ? const Color(0xFFF1F8F5)
        : const Color(0xFFF8F1EA);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A695E),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (timeLabel != null)
                      _TrackingMetaPill(
                        icon: Icons.schedule_rounded,
                        label: timeLabel!,
                      ),
                    if (durationLabel != null)
                      _TrackingMetaPill(
                        icon: Icons.timelapse_rounded,
                        label: durationLabel!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMetaPill extends StatelessWidget {
  const _TrackingMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1E2D3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8A7060)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5D4C42),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({
    required this.userName,
    required this.userHandle,
    this.userEmail,
    this.userAvatarUrl,
    this.userAvatarBytes,
    this.accountLabel,
    required this.savedPlaces,
    required this.selectedBottomIndex,
    required this.onOpenMenu,
    required this.onBottomNavSelected,
  });

  final String userName;
  final String userHandle;
  final String? userEmail;
  final String? userAvatarUrl;
  final Uint8List? userAvatarBytes;
  final String? accountLabel;
  final List<_SavedPlaceData> savedPlaces;
  final int selectedBottomIndex;
  final VoidCallback onOpenMenu;
  final ValueChanged<int> onBottomNavSelected;

  static final List<_PastOrderEntryData> _recentOrders =
      List<_PastOrderEntryData>.unmodifiable(
        _OrdersTabBody._pastOrders.take(2),
      );

  void _openFollowingRestaurants(
    BuildContext context,
    List<DemoFeedPost> followedRestaurants,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _FollowingRestaurantsScreen(initialPosts: followedRestaurants),
      ),
    );
  }

  void _openReorderCart(
    BuildContext context, {
    required String restaurantName,
    required List<_CartLineItemData> initialItems,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrdersCartScreen(
          initialItems: initialItems,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  void _reorderRecentOrder(BuildContext context, _PastOrderEntryData order) {
    _openReorderCart(
      context,
      restaurantName: order.title,
      initialItems: order.reorderItems,
    );
  }

  Future<void> _openSavedPlaceProfile(
    BuildContext context,
    _SavedPlaceData place,
  ) async {
    final reviewPreviews = _buildDemoRestaurantReviews(
      restaurantName: place.title,
      rating: place.rating,
    );
    await showRestaurantProfilePopup(
      context,
      restaurantName: place.title,
      handle: place.handle,
      rating: place.rating,
      caption: place.caption,
      cuisineSummary: place.cuisineSummary,
      phoneLabel: place.phoneLabel,
      locationLabel: place.locationLabel,
      followersCountLabel:
          '${_formatCompactCount(place.followersCount)} followers',
      allowAddToCart: true,
      showFollowButton: true,
      showSaveButton: true,
      reviews: reviewPreviews,
      onOpenReviews: () {
        openRestaurantReviewsPage(
          context,
          restaurantName: place.title,
          rating: place.rating,
          reviews: reviewPreviews,
        );
      },
      onAddToCart: (item) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          return;
        }
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('${item.title} added to cart')),
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAreaPadding = MediaQuery.paddingOf(context);
        final safeHeight =
            constraints.maxHeight -
            safeAreaPadding.top -
            safeAreaPadding.bottom;
        final metrics = _ResponsiveMetrics.from(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight > 0 ? safeHeight : constraints.maxHeight,
          ),
        );
        final followedRestaurants = _followingRestaurantsFromPosts(
          _customerFeedPostsSnapshot(DemoAppRepository.instance),
        );
        final navBarBottomInset = safeAreaPadding.bottom;
        final navBarTotalHeight = metrics.navHeight + navBarBottomInset;
        return Stack(
          children: [
            const Positioned.fill(child: _ProfileBackground()),
            Positioned.fill(
              bottom: navBarTotalHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    _clampDouble(metrics.topPadding + 6, 12, 20),
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'My Profile',
                              style: TextStyle(
                                color: const Color(0xFF231A16),
                                fontSize: _clampDouble(
                                  34 * metrics.scale,
                                  26,
                                  34,
                                ),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          _ProfileIconButton(
                            icon: Icons.menu_rounded,
                            metrics: metrics,
                            onTap: onOpenMenu,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(22 * metrics.scale, 16, 22),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProfileHeroCard(
                                userName: userName,
                                userHandle: userHandle,
                                userEmail: userEmail,
                                userAvatarUrl: userAvatarUrl,
                                userAvatarBytes: userAvatarBytes,
                                accountLabel: accountLabel,
                                followingCountLabel: _formatCompactCount(
                                  followedRestaurants.length,
                                ),
                                onOpenFollowing: () =>
                                    _openFollowingRestaurants(
                                      context,
                                      followedRestaurants,
                                    ),
                                metrics: metrics,
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  18 * metrics.scale,
                                  14,
                                  18,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ProfileStatCard(
                                      title: 'Points Balance',
                                      value: '1,250',
                                      subtitle: '50 points expiring soon',
                                      accentColor: const Color(0xFFFF7E4D),
                                      icon: Icons.stars_rounded,
                                      metrics: metrics,
                                    ),
                                  ),
                                  SizedBox(
                                    width: _clampDouble(
                                      14 * metrics.scale,
                                      10,
                                      14,
                                    ),
                                  ),
                                  Expanded(
                                    child: _ProfileStatCard(
                                      title: 'Rewards',
                                      value: '3',
                                      subtitle: 'Active perks to use',
                                      accentColor: const Color(0xFF2F8A7E),
                                      icon: Icons.local_offer_rounded,
                                      metrics: metrics,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  28 * metrics.scale,
                                  20,
                                  28,
                                ),
                              ),
                              const _ProfileSectionHeader(
                                title: 'Recent Orders',
                                actionLabel: 'View All',
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  146 * metrics.scale,
                                  126,
                                  156,
                                ),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _recentOrders.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        width: _clampDouble(
                                          14 * metrics.scale,
                                          10,
                                          14,
                                        ),
                                      ),
                                  itemBuilder: (context, index) {
                                    return _RecentOrderCard(
                                      data: _recentOrders[index],
                                      metrics: metrics,
                                      onReorder: () => _reorderRecentOrder(
                                        context,
                                        _recentOrders[index],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  28 * metrics.scale,
                                  20,
                                  28,
                                ),
                              ),
                              const _ProfileSectionHeader(
                                title: 'Saved Places',
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              if (savedPlaces.isEmpty)
                                _ProfilePanel(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      _clampDouble(18 * metrics.scale, 14, 18),
                                    ),
                                    child: const Text(
                                      'Save a restaurant from its profile or heart it in Discover and it will appear here.',
                                      style: TextStyle(
                                        color: Color(0xFF7D6C60),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                _ProfilePanel(
                                  child: Column(
                                    children: List.generate(
                                      savedPlaces.length,
                                      (index) {
                                        final place = savedPlaces[index];
                                        return Column(
                                          children: [
                                            _SavedPlaceTile(
                                              data: place,
                                              metrics: metrics,
                                              onTap: () =>
                                                  _openSavedPlaceProfile(
                                                    context,
                                                    place,
                                                  ),
                                            ),
                                            if (index != savedPlaces.length - 1)
                                              Divider(
                                                height: 1,
                                                color: const Color(0xFFF0E2D3),
                                                indent: _clampDouble(
                                                  74 * metrics.scale,
                                                  58,
                                                  74,
                                                ),
                                                endIndent: _clampDouble(
                                                  18 * metrics.scale,
                                                  14,
                                                  18,
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNavBar(
                metrics: metrics,
                selectedIndex: selectedBottomIndex,
                onSelected: onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FollowingRestaurantsScreen extends StatefulWidget {
  const _FollowingRestaurantsScreen({required this.initialPosts});

  final List<DemoFeedPost> initialPosts;

  @override
  State<_FollowingRestaurantsScreen> createState() =>
      _FollowingRestaurantsScreenState();
}

class _FollowingRestaurantsScreenState
    extends State<_FollowingRestaurantsScreen> {
  final DemoAppRepository _repository = DemoAppRepository.instance;
  late List<DemoFeedPost> _followedRestaurants;

  @override
  void initState() {
    super.initState();
    _followedRestaurants = _followingRestaurantsFromPosts(widget.initialPosts);
    _refreshFollowedRestaurants();
  }

  List<DemoFeedPost> _currentFollowedRestaurants() {
    return _followingRestaurantsFromPosts(
      _customerFeedPostsSnapshot(_repository),
    );
  }

  void _refreshFollowedRestaurants() {
    if (!mounted) {
      return;
    }
    setState(() {
      _followedRestaurants = _currentFollowedRestaurants();
    });
  }

  void _toggleFollow(DemoFeedPost post) {
    _repository
        .toggleFollow(post.id)
        .then((_) {
          if (!mounted) {
            return;
          }
          _refreshFollowedRestaurants();
        })
        .catchError((Object error) {
          if (!mounted) {
            return;
          }
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) {
            return;
          }
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Could not update follow status. Try again.'),
              ),
            );
        });
  }

  Future<void> _openRestaurant(DemoFeedPost post) async {
    final reviewPreviews = _reviewPreviewsFromComments(
      comments: _repository.getComments(post.id),
      baseRating: post.rating,
    );
    await showRestaurantProfilePopup(
      context,
      restaurantName: post.restaurantName,
      handle: post.restaurantHandle,
      rating: post.rating,
      caption: post.caption,
      followersCountLabel:
          '${_formatCompactCount(post.followersCount)} followers',
      allowAddToCart: true,
      showFollowButton: true,
      showSaveButton: true,
      initiallyFollowing: post.isFollowing,
      onToggleFollow: () => _toggleFollow(post),
      reviews: reviewPreviews,
      onOpenReviews: () {
        openRestaurantReviewsPage(
          context,
          restaurantName: post.restaurantName,
          rating: post.rating,
          reviews: reviewPreviews,
        );
      },
      onAddToCart: (item) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          return;
        }
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('${item.title} added to cart')),
          );
      },
    );
    if (!mounted) {
      return;
    }
    _refreshFollowedRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F1),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Following',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_followedRestaurants.length} restaurants',
                style: const TextStyle(
                  color: Color(0xFF7D6E63),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _followedRestaurants.isEmpty
                    ? const _FollowingRestaurantsEmptyState()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _followedRestaurants.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = _followedRestaurants[index];
                          return _FollowingRestaurantTile(
                            post: post,
                            onTap: () => _openRestaurant(post),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowingRestaurantsEmptyState extends StatelessWidget {
  const _FollowingRestaurantsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF3DFCF)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_add_alt_rounded,
            color: Color(0xFFFF7E4D),
            size: 38,
          ),
          SizedBox(height: 10),
          Text(
            'You are not following any restaurants yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2B211D),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Follow a restaurant from Feed to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8A7A70),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowingRestaurantTile extends StatelessWidget {
  const _FollowingRestaurantTile({required this.post, required this.onTap});

  final DemoFeedPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF3DFCF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10A7633A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD8B6), Color(0xFFFFAE79)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _feedCreatorLabel(post.restaurantName),
                  style: const TextStyle(
                    color: Color(0xFF6A3D24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${post.restaurantHandle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF89796E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF5B63F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF5B4A40),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${_formatCompactCount(post.followersCount)} followers',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8F8075),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Following',
                  style: TextStyle(
                    color: Color(0xFF2F8A7E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF8F1), Color(0xFFF6E6D3)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x40FFD0B5), Color(0x00FFD0B5)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 220,
          left: -90,
          child: Container(
            width: 210,
            height: 210,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x26FFC794), Color(0x00FFC794)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 180,
          right: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x1FEAAE88), Color(0x00EAAE88)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverSearchBar extends StatelessWidget {
  const _DiscoverSearchBar({required this.metrics, required this.onTapSearch});

  final _ResponsiveMetrics metrics;
  final VoidCallback onTapSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapSearch,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: _clampDouble(56 * metrics.scale, 48, 56),
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(18 * metrics.scale, 14, 18),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF3DFCF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10A7633A),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: const Color(0xFFFF7E4D),
                size: _clampDouble(24 * metrics.scale, 20, 24),
              ),
              SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
              Expanded(
                child: Text(
                  'Search restaurants or dishes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF9D8A7D),
                    fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverCuisineChip extends StatelessWidget {
  const _DiscoverCuisineChip({
    required this.data,
    required this.metrics,
    required this.onTap,
  });

  final _DiscoverCategoryData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: _clampDouble(104 * metrics.scale, 90, 104),
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(12 * metrics.scale, 10, 12),
            vertical: _clampDouble(
              (metrics.compact ? 10 : 12) * metrics.scale,
              8,
              metrics.compact ? 10 : 12,
            ),
          ),
          decoration: BoxDecoration(
            color: data.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF3DFCF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: _clampDouble(38 * metrics.scale, 32, 38),
                height: _clampDouble(38 * metrics.scale, 32, 38),
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.icon,
                  color: Colors.white,
                  size: _clampDouble(20 * metrics.scale, 16, 20),
                ),
              ),
              SizedBox(
                height: _clampDouble(
                  (metrics.compact ? 8 : 12) * metrics.scale,
                  6,
                  12,
                ),
              ),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF231A16),
                  fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: _clampDouble(2 * metrics.scale, 1, 2)),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF857467),
                  fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverSpotCard extends StatelessWidget {
  const _DiscoverSpotCard({
    required this.data,
    required this.metrics,
    required this.isFavorite,
    required this.onTap,
    required this.onViewMenuTap,
    required this.onFavoriteTap,
  });

  final _DiscoverSpotData data;
  final _ResponsiveMetrics metrics;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onViewMenuTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _clampDouble(metrics.width * 0.72, 244, 284);
    final imageHeight = _clampDouble(
      (metrics.compact ? 110 : 128) * metrics.scale,
      metrics.compact ? 96 : 112,
      metrics.compact ? 110 : 128,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          width: cardWidth,
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFF3DFCF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10A7633A),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: imageHeight,
                      child: Image.network(
                        data.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFD6B4), Color(0xFFFF9C6C)],
                              ),
                            ),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: Colors.white,
                              size: _clampDouble(44 * metrics.scale, 34, 44),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: _clampDouble(14 * metrics.scale, 10, 14),
                    left: _clampDouble(14 * metrics.scale, 10, 14),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _clampDouble(12 * metrics.scale, 9, 12),
                        vertical: _clampDouble(7 * metrics.scale, 5, 7),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF9F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        data.badge,
                        style: TextStyle(
                          color: const Color(0xFFFF7E4D),
                          fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _clampDouble(12 * metrics.scale, 10, 12),
                    right: _clampDouble(12 * metrics.scale, 10, 12),
                    child: Material(
                      color: const Color(0xFFFDF9F6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onFavoriteTap,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: _clampDouble(34 * metrics.scale, 30, 34),
                          height: _clampDouble(34 * metrics.scale, 30, 34),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? const Color(0xFFFF7E4D)
                                : const Color(0xFF8D7464),
                            size: _clampDouble(20 * metrics.scale, 16, 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _clampDouble(15 * metrics.scale, 12, 15),
                    _clampDouble(
                      (metrics.compact ? 12 : 14) * metrics.scale,
                      10,
                      metrics.compact ? 12 : 14,
                    ),
                    _clampDouble(15 * metrics.scale, 12, 15),
                    _clampDouble(
                      (metrics.compact ? 12 : 16) * metrics.scale,
                      10,
                      metrics.compact ? 12 : 16,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF231A16),
                          fontSize: _clampDouble(19 * metrics.scale, 15, 19),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                      Text(
                        data.subtitle,
                        maxLines: metrics.compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7D6C60),
                          fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(
                        height: _clampDouble(
                          (metrics.compact ? 10 : 12) * metrics.scale,
                          8,
                          metrics.compact ? 10 : 12,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _clampDouble(
                                12 * metrics.scale,
                                9,
                                12,
                              ),
                              vertical: _clampDouble(7 * metrics.scale, 5, 7),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              data.deliveryLabel,
                              style: TextStyle(
                                color: const Color(0xFFFF7E4D),
                                fontSize: _clampDouble(
                                  12 * metrics.scale,
                                  10,
                                  12,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star_rounded,
                            color: const Color(0xFFF5B63F),
                            size: _clampDouble(18 * metrics.scale, 14, 18),
                          ),
                          SizedBox(
                            width: _clampDouble(4 * metrics.scale, 2, 4),
                          ),
                          Text(
                            data.ratingLabel,
                            style: TextStyle(
                              color: const Color(0xFF5A4A40),
                              fontSize: _clampDouble(
                                14 * metrics.scale,
                                11,
                                14,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onViewMenuTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: _clampDouble(
                                13 * metrics.scale,
                                10,
                                13,
                              ),
                              vertical: _clampDouble(8 * metrics.scale, 6, 8),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EEE8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'View menu',
                              style: TextStyle(
                                color: const Color(0xFF5A4A40),
                                fontSize: _clampDouble(
                                  12.5 * metrics.scale,
                                  10,
                                  12.5,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
      ),
    );
  }
}

class _DiscoverDealTile extends StatelessWidget {
  const _DiscoverDealTile({
    required this.data,
    required this.metrics,
    required this.onTap,
  });

  final _DiscoverDealData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF231A16),
            fontSize: _clampDouble(17 * metrics.scale, 14, 17),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
        Text(
          data.subtitle,
          maxLines: metrics.compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF837266),
            fontSize: _clampDouble(13 * metrics.scale, 11, 13),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );

    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          data.priceLabel,
          style: TextStyle(
            color: const Color(0xFF231A16),
            fontSize: _clampDouble(17 * metrics.scale, 14, 17),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(10 * metrics.scale, 8, 10),
            vertical: _clampDouble(6 * metrics.scale, 4, 6),
          ),
          decoration: BoxDecoration(
            color: data.accentColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            data.promoLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: _clampDouble(11 * metrics.scale, 9, 11),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    final iconTile = Container(
      width: _clampDouble(52 * metrics.scale, 44, 52),
      height: _clampDouble(52 * metrics.scale, 44, 52),
      decoration: BoxDecoration(
        color: data.accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        data.icon,
        color: data.accentColor,
        size: _clampDouble(28 * metrics.scale, 22, 28),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useStackedMeta = metrics.tiny || constraints.maxWidth < 315;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _clampDouble(18 * metrics.scale, 14, 18),
                vertical: _clampDouble(16 * metrics.scale, 12, 16),
              ),
              child: useStackedMeta
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            iconTile,
                            SizedBox(
                              width: _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            Expanded(child: details),
                          ],
                        ),
                        SizedBox(
                          height: _clampDouble(12 * metrics.scale, 8, 12),
                        ),
                        Align(alignment: Alignment.centerRight, child: meta),
                      ],
                    )
                  : Row(
                      children: [
                        iconTile,
                        SizedBox(
                          width: _clampDouble(14 * metrics.scale, 10, 14),
                        ),
                        Expanded(child: details),
                        SizedBox(
                          width: _clampDouble(10 * metrics.scale, 8, 10),
                        ),
                        meta,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _openDiscoverRestaurantProfile(
  BuildContext context,
  _DiscoverSpotData spot, {
  int initialTabIndex = 0,
}) {
  final reviewPreviews = _buildDemoRestaurantReviews(
    restaurantName: spot.title,
    rating: spot.ratingValue,
  );
  return showRestaurantProfilePopup(
    context,
    restaurantName: spot.title,
    handle: spot.handle,
    rating: spot.ratingValue,
    caption: spot.subtitle,
    initialTabIndex: initialTabIndex,
    followersCountLabel:
        '${_formatCompactCount(8400 + (spot.deliveryMinutes * 28))} followers',
    allowAddToCart: true,
    showFollowButton: true,
    showSaveButton: true,
    reviews: reviewPreviews,
    onOpenReviews: () {
      openRestaurantReviewsPage(
        context,
        restaurantName: spot.title,
        rating: spot.ratingValue,
        reviews: reviewPreviews,
      );
    },
    onAddToCart: (item) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('${item.title} added to cart')),
      );
    },
  );
}

class _DiscoverCuisineDetailsScreen extends StatelessWidget {
  const _DiscoverCuisineDetailsScreen({
    required this.category,
    required this.spots,
  });

  final _DiscoverCategoryData category;
  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    return _DiscoverSpotsCatalogScreen(
      title: category.title,
      subtitle: category.subtitle,
      spots: spots,
    );
  }
}

class _DiscoverPopularSpotsScreen extends StatelessWidget {
  const _DiscoverPopularSpotsScreen({required this.spots});

  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    return _DiscoverSpotsCatalogScreen(
      title: 'Popular Near You',
      subtitle: 'Top picks around your area',
      spots: spots,
    );
  }
}

class _DiscoverSpotsCatalogScreen extends StatelessWidget {
  const _DiscoverSpotsCatalogScreen({
    required this.title,
    required this.subtitle,
    required this.spots,
  });

  final String title;
  final String subtitle;
  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7C6A5F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: spots.isEmpty
                    ? const Center(
                        child: Text(
                          'No restaurants available yet.',
                          style: TextStyle(
                            color: Color(0xFF7D6C60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: spots.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _DiscoverSpotPreviewTile(spot: spots[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverMapPreviewScreen extends StatelessWidget {
  const _DiscoverMapPreviewScreen({required this.spots});

  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    const pinOffsets = <Offset>[
      Offset(0.2, 0.22),
      Offset(0.72, 0.3),
      Offset(0.34, 0.58),
      Offset(0.64, 0.72),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nearby Map',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            children: [
              Container(
                height: 230,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9E9D7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFECCFB7)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: List.generate(spots.length.clamp(0, 4), (
                        index,
                      ) {
                        final pinPosition = pinOffsets[index];
                        final spot = spots[index];
                        return Positioned(
                          left: constraints.maxWidth * pinPosition.dx - 44,
                          top: constraints.maxHeight * pinPosition.dy - 20,
                          child: Material(
                            color: const Color(0xFFFF7E4D),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: () =>
                                  _openDiscoverRestaurantProfile(context, spot),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  spot.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: spots.isEmpty
                    ? const Center(
                        child: Text(
                          'No restaurants match your filters.',
                          style: TextStyle(
                            color: Color(0xFF7D6C60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: spots.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _DiscoverSpotPreviewTile(spot: spots[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverSpotPreviewTile extends StatelessWidget {
  const _DiscoverSpotPreviewTile({required this.spot});

  final _DiscoverSpotData spot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEFCFA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openDiscoverRestaurantProfile(context, spot),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  spot.imageUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFFFE6D3),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFFFF7E4D),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFFFF7E4D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          spot.deliveryLabel,
                          style: const TextStyle(
                            color: Color(0xFFFF7E4D),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF5B63F),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          spot.ratingLabel,
                          style: const TextStyle(
                            color: Color(0xFF6B594D),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E8A7E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverRestaurantMenuScreen extends StatefulWidget {
  const _DiscoverRestaurantMenuScreen({
    required this.spot,
    required this.items,
    required this.onItemTap,
  });

  final _DiscoverSpotData spot;
  final List<RestaurantMenuItem> items;
  final ValueChanged<RestaurantMenuItem> onItemTap;

  @override
  State<_DiscoverRestaurantMenuScreen> createState() =>
      _DiscoverRestaurantMenuScreenState();
}

class _DiscoverRestaurantMenuScreenState
    extends State<_DiscoverRestaurantMenuScreen> {
  static const String _allCategory = 'All';
  String _selectedCategory = _allCategory;

  List<String> get _categories {
    final categories = <String>{};
    for (final item in widget.items) {
      final category = item.category.trim();
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }
    final sorted = categories.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return <String>[_allCategory, ...sorted];
  }

  List<RestaurantMenuItem> get _filteredItems {
    if (_selectedCategory == _allCategory) {
      return widget.items;
    }
    final normalized = _selectedCategory.toLowerCase();
    return widget.items
        .where((item) => item.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  String _formatUsd(double? value) {
    if (value == null) {
      return '--';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  double _averagePrice(List<RestaurantMenuItem> menuItems) {
    if (menuItems.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    for (final item in menuItems) {
      sum += item.price ?? 0;
    }
    return sum / menuItems.length;
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final metrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    final categories = _categories;
    final filteredItems = _filteredItems;
    final availableCount = filteredItems
        .where((item) => item.isAvailable)
        .length;
    final popularCount = filteredItems.where((item) => item.isPopular).length;
    final averagePrice = _averagePrice(filteredItems);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.spot.title} Menu',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF4D6BF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7E4D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Section',
                            style: TextStyle(
                              color: const Color(0xFF2C231D),
                              fontSize: _clampDouble(
                                16 * metrics.scale,
                                13,
                                16,
                              ),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.spot.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF7E6D62),
                              fontSize: _clampDouble(
                                12.5 * metrics.scale,
                                10.5,
                                12.5,
                              ),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Items',
                      value: '${filteredItems.length}',
                      icon: Icons.format_list_bulleted_rounded,
                      iconColor: const Color(0xFFFF7E4D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Available',
                      value: '$availableCount',
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF2E9B57),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Popular',
                      value: '$popularCount',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF0A523),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Avg',
                      value: _formatUsd(averagePrice),
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF4B7AA3),
                    ),
                  ),
                ],
              ),
              if (categories.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = category);
                        },
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFFFF7E4D)
                              : const Color(0xFF7D6C60),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        backgroundColor: const Color(0xFFF7EFE7),
                        selectedColor: const Color(0xFFFFEFE5),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFFFFC9B2)
                              : const Color(0xFFE7D6C8),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No menu items found.',
                          style: TextStyle(
                            color: Color(0xFF7D6C60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _DiscoverMenuItemCard(
                            item: item,
                            priceLabel: _formatUsd(item.price),
                            onTap: () => widget.onItemTap(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverMenuStatCard extends StatelessWidget {
  const _DiscoverMenuStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DACD)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1F1B19),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8D7E73),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverMenuItemCard extends StatelessWidget {
  const _DiscoverMenuItemCard({
    required this.item,
    required this.priceLabel,
    required this.onTap,
  });

  final RestaurantMenuItem item;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9DACD)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD6B4), Color(0xFFFF9C6C)],
                          ),
                        ),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1F1B19),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFFF7E4D),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C7D71),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _DiscoverMenuBadge(
                          label: item.category,
                          backgroundColor: const Color(0xFFEFE8E1),
                          textColor: const Color(0xFF786658),
                        ),
                        _DiscoverMenuBadge(
                          label: item.isAvailable ? 'Available' : 'Paused',
                          backgroundColor: item.isAvailable
                              ? const Color(0xFFE1F5E8)
                              : const Color(0xFFFDE4E2),
                          textColor: item.isAvailable
                              ? const Color(0xFF2E9B57)
                              : const Color(0xFFC6463E),
                        ),
                        if (item.isPopular)
                          const _DiscoverMenuBadge(
                            label: 'Popular',
                            backgroundColor: Color(0xFFE8EFF7),
                            textColor: Color(0xFF43739C),
                          ),
                        if (item.rating != null)
                          _DiscoverMenuBadge(
                            label: '${item.rating!.toStringAsFixed(1)}*',
                            backgroundColor: const Color(0xFFFFF1CC),
                            textColor: const Color(0xFFB07800),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverMenuBadge extends StatelessWidget {
  const _DiscoverMenuBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DiscoverDealDetailsSheet extends StatelessWidget {
  const _DiscoverDealDetailsSheet({required this.data, this.onAddToCart});

  final _DiscoverDealData data;
  final ValueChanged<_DiscoverDealData>? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEFCFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8C6B8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: data.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(data.icon, color: data.accentColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.subtitle,
                style: const TextStyle(
                  color: Color(0xFF7F6D61),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    data.priceLabel,
                    style: const TextStyle(
                      color: Color(0xFF231A16),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: data.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.promoLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (onAddToCart != null) {
                      onAddToCart!(data);
                      return;
                    }
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger
                      ?..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text('${data.title} added to cart')),
                      );
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text(
                    'Add To Cart',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedBackground extends StatelessWidget {
  const _FeedBackground({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const DecoratedBox(decoration: BoxDecoration(color: Colors.black));
    }

    final aspectRatio = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : (9 / 16);

    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1080,
            height: 1080 / aspectRatio,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveMetrics {
  const _ResponsiveMetrics({
    required this.width,
    required this.height,
    required this.scale,
    required this.compact,
    required this.tiny,
  });

  factory _ResponsiveMetrics.from(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final widthScale = _clampDouble(width / 390, 0.82, 1.12);
    final heightScale = _clampDouble(height / 844, 0.78, 1.1);
    final scale = widthScale < heightScale ? widthScale : heightScale;

    return _ResponsiveMetrics(
      width: width,
      height: height,
      scale: scale,
      compact: width < 370 || height < 760,
      tiny: width < 345 || height < 690,
    );
  }

  final double width;
  final double height;
  final double scale;
  final bool compact;
  final bool tiny;

  double get horizontalPadding => _clampDouble(width * 0.043, 12, 18);
  double get topPadding => _clampDouble(height * 0.012, 8, 14);
  double get bottomPadding => _clampDouble(height * 0.009, 8, 12);
  double get sideGap => _clampDouble(16 * scale, 8, 16);
  double get gapAfterTop => _clampDouble(12 * scale, 6, 12);
  double get sectionGapSmall => _clampDouble(14 * scale, 8, 14);
  double get railGap => _clampDouble(10 * scale, 6, 10);
  double get railWidth => _clampDouble(70 * scale, 54, 70);
  double get railItemGap => _clampDouble(12 * scale, 7, 12);

  double get topControlButtonSize => _clampDouble(54 * scale, 42, 54);
  double get topControlIconSize => _clampDouble(28 * scale, 20, 28);
  double get topTabFontSize => _clampDouble(17 * scale, 13, 17);
  double get topTabIndicatorWidth => _clampDouble(52 * scale, 40, 52);
  double get topTabIndicatorHeight => _clampDouble(5 * scale, 3, 5);

  double get handleFontSize => _clampDouble(24 * scale, 16, 24);
  double get handleAtFontSize => _clampDouble(16 * scale, 11, 16);
  double get captionFontSize => _clampDouble(17 * scale, 13, 17);
  double get tagsFontSize => _clampDouble(17 * scale, 13, 17);
  double get audioFontSize => _clampDouble(13 * scale, 10.5, 13);
  double get ratingFontSize => _clampDouble(17 * scale, 12, 17);
  double get ratingStarSize => _clampDouble(18 * scale, 13, 18);

  double get creatorSize => _clampDouble(58 * scale, 44, 58);
  double get creatorPlusSize => _clampDouble(24 * scale, 17, 24);
  double get actionBubbleSize => _clampDouble(52 * scale, 38, 52);
  double get actionIconSize => _clampDouble(27 * scale, 19, 27);
  double get actionTextSize => _clampDouble(14 * scale, 11, 14);

  double get ctaHeight => _clampDouble(66 * scale, 50, 66);
  double get ctaRadius => _clampDouble(33 * scale, 24, 33);
  double get ctaMainSize => _clampDouble(28 * scale, 20, 28);
  double get ctaSubSize => _clampDouble(11 * scale, 8.5, 11);
  double get ctaPriceSize => _clampDouble(24 * scale, 16, 24);
  double get ctaIconSize => _clampDouble(22 * scale, 15, 22);

  double get navScaleFactor => 0.6;
  double get navHeight => _clampDouble(
    96 * scale * navScaleFactor,
    72 * navScaleFactor,
    96 * navScaleFactor,
  );
  double get navRadius => _clampDouble(
    32 * scale * navScaleFactor,
    22 * navScaleFactor,
    32 * navScaleFactor,
  );
  double get navIconScaleFactor => 0.82;
  double get navIconSize =>
      _clampDouble(30 * scale * navIconScaleFactor, 18, 24);
  double get navLabelSize => _clampDouble(
    12.5 * scale * navScaleFactor,
    9 * navScaleFactor,
    12.5 * navScaleFactor,
  );
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.metrics,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onOpenSearch,
    required this.onOpenNotifications,
  });

  final _ResponsiveMetrics metrics;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: metrics.topControlButtonSize,
          child: Center(
            child: _RoundIconButton(
              icon: Icons.search_rounded,
              metrics: metrics,
              onTap: onOpenSearch,
              tooltip: 'Search',
            ),
          ),
        ),
        SizedBox(width: metrics.sideGap),
        Expanded(
          child: SizedBox(
            height: metrics.topControlButtonSize,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopTab(
                    label: 'Following',
                    selected: selectedTab == 0,
                    metrics: metrics,
                    onTap: () => onTabSelected(0),
                  ),
                  SizedBox(width: _clampDouble(18 * metrics.scale, 8, 18)),
                  _TopTab(
                    label: 'For You',
                    selected: selectedTab == 1,
                    metrics: metrics,
                    onTap: () => onTabSelected(1),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: metrics.sideGap),
        SizedBox(
          height: metrics.topControlButtonSize,
          child: Center(
            child: _RoundIconButton(
              icon: Icons.notifications_none_rounded,
              metrics: metrics,
              onTap: onOpenNotifications,
              tooltip: 'Notifications',
            ),
          ),
        ),
      ],
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : const Color(0xB7FFFFFF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(4 * metrics.scale, 2, 4),
          vertical: _clampDouble(4 * metrics.scale, 2, 4),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: metrics.topTabFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: _clampDouble(6 * metrics.scale, 3, 6)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: metrics.topTabIndicatorWidth,
              height: metrics.topTabIndicatorHeight,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF7E4D) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.metrics,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: metrics.topControlButtonSize,
            height: metrics.topControlButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x38FFFFFF),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: metrics.topControlIconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedDetails extends StatelessWidget {
  const _FeedDetails({
    required this.post,
    required this.metrics,
    required this.onOpenRestaurant,
    required this.onOpenReviews,
    required this.onOpenAudio,
    required this.showOrderNow,
    required this.orderNowPriceLabel,
    required this.onDismissOrderNow,
    required this.onOrderNowTap,
  });

  final DemoFeedPost post;
  final _ResponsiveMetrics metrics;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenAudio;
  final bool showOrderNow;
  final String orderNowPriceLabel;
  final VoidCallback onDismissOrderNow;
  final VoidCallback onOrderNowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          reverseDuration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.14),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          child: showOrderNow
              ? Padding(
                  key: ValueKey<String>('order-now-${post.id}'),
                  padding: EdgeInsets.only(
                    bottom: _clampDouble(8 * metrics.scale, 4, 10),
                  ),
                  child: _SwipeDismissSurface(
                    onDismissed: onDismissOrderNow,
                    child: _OrderNowBar(
                      metrics: metrics,
                      priceLabel: orderNowPriceLabel,
                      compactStyle: true,
                      onTap: onOrderNowTap,
                    ),
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey<String>('order-now-hidden'),
                ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpenRestaurant,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    post.restaurantHandle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.handleFontSize,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 4, 8)),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenReviews,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _clampDouble(10 * metrics.scale, 7, 10),
                    vertical: _clampDouble(6 * metrics.scale, 4, 6),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xBF2E2521),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFF9C949),
                        size: metrics.ratingStarSize,
                      ),
                      SizedBox(width: _clampDouble(4 * metrics.scale, 2, 4)),
                      Text(
                        post.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: metrics.ratingFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _clampDouble(8 * metrics.scale, 4, 8)),
        Text(
          post.caption,
          maxLines: metrics.tiny ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: metrics.captionFontSize,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
        Text(
          post.tags,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFFF7E4D),
            fontSize: metrics.tagsFontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(12 * metrics.scale, 6, 14)),
        InkWell(
          onTap: onOpenAudio,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: _clampDouble(metrics.audioFontSize + 4, 14, 20),
              ),
              SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
              Flexible(
                child: Text(
                  post.audioLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xD9FFFFFF),
                    fontSize: metrics.audioFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.metrics,
    required this.post,
    required this.onOpenRestaurant,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onShare,
  });

  final _ResponsiveMetrics metrics;
  final DemoFeedPost post;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.railWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CreatorAvatar(
            metrics: metrics,
            post: post,
            onOpenRestaurant: onOpenRestaurant,
            onToggleFollow: onToggleFollow,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.favorite_rounded,
            value: _formatCompactCount(post.likeCount),
            iconColor: post.isLiked ? const Color(0xFFFF7E4D) : Colors.white,
            metrics: metrics,
            onTap: onToggleLike,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            value: _formatCompactCount(post.commentCount),
            metrics: metrics,
            onTap: onOpenComments,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.share_outlined,
            value: 'Share',
            metrics: metrics,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({
    required this.metrics,
    required this.post,
    required this.onOpenRestaurant,
    required this.onToggleFollow,
  });

  final _ResponsiveMetrics metrics;
  final DemoFeedPost post;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onOpenRestaurant,
          customBorder: const CircleBorder(),
          child: Container(
            width: metrics.creatorSize,
            height: metrics.creatorSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF135D42), Color(0xFF0E3D2D)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _feedCreatorLabel(post.restaurantName),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: _clampDouble(8 * metrics.scale, 6, 8),
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: InkWell(
            onTap: onToggleFollow,
            customBorder: const CircleBorder(),
            child: Container(
              width: metrics.creatorPlusSize,
              height: metrics.creatorPlusSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF7E4D),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                post.isFollowing ? Icons.check_rounded : Icons.add_rounded,
                color: Colors.white,
                size: metrics.creatorPlusSize * 0.62,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.value,
    required this.metrics,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String value;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: metrics.actionBubbleSize,
              height: metrics.actionBubbleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x36FFFFFF),
                border: Border.all(color: const Color(0x2BFFFFFF)),
              ),
              child: Icon(icon, color: iconColor, size: metrics.actionIconSize),
            ),
          ),
        ),
        SizedBox(height: _clampDouble(6 * metrics.scale, 3, 6)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: metrics.actionTextSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FeedLikeBurstData {
  const _FeedLikeBurstData({
    required this.id,
    required this.postId,
    required this.tapPosition,
  });

  final int id;
  final String postId;
  final Offset tapPosition;
}

class _TastyLikeBurst extends StatelessWidget {
  const _TastyLikeBurst({super.key, required this.tapPosition});

  final Offset tapPosition;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: tapPosition.dx - 62,
      top: tapPosition.dy - 82,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          final fade = progress < 0.72
              ? 1.0
              : (1 - (progress - 0.72) / 0.28).clamp(0.0, 1.0);
          final rise = 34 * progress;
          final pop = progress < 0.2
              ? 0.55 + progress * 2.25
              : 1.0 + (1 - progress) * 0.1;
          final spread = 42 * Curves.easeOutBack.transform(progress);
          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, -rise),
              child: Transform.scale(
                scale: pop,
                child: SizedBox(
                  width: 124,
                  height: 124,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(-spread, -spread * 0.75),
                        child: _TastyBurstChip(
                          icon: Icons.local_pizza_rounded,
                          iconColor: const Color(0xFFCF562F),
                          backgroundColor: const Color(0xFFFFE2C8),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(spread * 0.9, -spread * 0.5),
                        child: _TastyBurstChip(
                          icon: Icons.icecream_rounded,
                          iconColor: const Color(0xFFC84A6D),
                          backgroundColor: const Color(0xFFFFE6EF),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, spread * 0.78),
                        child: _TastyBurstChip(
                          icon: Icons.ramen_dining_rounded,
                          iconColor: const Color(0xFFB56A2E),
                          backgroundColor: const Color(0xFFFFF0CF),
                        ),
                      ),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFAA72), Color(0xFFFF6D4F)],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFDF2E8),
                            width: 2.4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40A84329),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TastyBurstChip extends StatelessWidget {
  const _TastyBurstChip({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFF7EE), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22A45835),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

class _OrderNowBar extends StatelessWidget {
  const _OrderNowBar({
    required this.metrics,
    required this.priceLabel,
    this.compactStyle = false,
    this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final String priceLabel;
  final bool compactStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = compactStyle || constraints.maxWidth < 360;
        final compactScale = compactStyle ? 0.82 : 1.0;

        final borderRadius = BorderRadius.circular(
          _clampDouble(
            metrics.ctaRadius * (compactStyle ? 0.88 : 1.0),
            18,
            metrics.ctaRadius,
          ),
        );
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Ink(
              height: _clampDouble(
                metrics.ctaHeight * compactScale,
                42,
                metrics.ctaHeight,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _clampDouble(
                  12 * metrics.scale * compactScale,
                  7,
                  12,
                ),
                vertical: _clampDouble(8 * metrics.scale * compactScale, 4, 8),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A5B),
                borderRadius: borderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4A5A2B17),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: _clampDouble(
                      42 * metrics.scale * compactScale,
                      24,
                      42,
                    ),
                    height: _clampDouble(
                      42 * metrics.scale * compactScale,
                      24,
                      42,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0x2EFFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: _clampDouble(
                        metrics.ctaIconSize * compactScale,
                        12,
                        metrics.ctaIconSize,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _clampDouble(
                      12 * metrics.scale * compactScale,
                      5,
                      12,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact
                                ? _clampDouble(
                                    (metrics.ctaMainSize - 4) * compactScale,
                                    13,
                                    24,
                                  )
                                : _clampDouble(
                                    metrics.ctaMainSize * compactScale,
                                    13,
                                    metrics.ctaMainSize,
                                  ),
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(
                          height: _clampDouble(
                            3 * metrics.scale * compactScale,
                            1,
                            3,
                          ),
                        ),
                        Text(
                          'DELIVERY IN 25M',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xF2FFFFFF),
                            fontSize: _clampDouble(
                              metrics.ctaSubSize * compactScale,
                              7.5,
                              metrics.ctaSubSize,
                            ),
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: _clampDouble(6 * metrics.scale * compactScale, 2, 6),
                  ),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 1,
                              margin: EdgeInsets.symmetric(
                                horizontal: _clampDouble(
                                  8 * metrics.scale * compactScale,
                                  3,
                                  8,
                                ),
                                vertical: _clampDouble(
                                  6 * metrics.scale * compactScale,
                                  3,
                                  6,
                                ),
                              ),
                              color: const Color(0x58FFFFFF),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _clampDouble(
                                  14 * metrics.scale * compactScale,
                                  6,
                                  14,
                                ),
                                vertical: _clampDouble(
                                  8 * metrics.scale * compactScale,
                                  3,
                                  8,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1DFFFFFF),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0x49FFFFFF),
                                ),
                              ),
                              child: Text(
                                priceLabel,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact
                                      ? _clampDouble(
                                          (metrics.ctaPriceSize - 3) *
                                              compactScale,
                                          11,
                                          20,
                                        )
                                      : _clampDouble(
                                          metrics.ctaPriceSize * compactScale,
                                          11,
                                          metrics.ctaPriceSize,
                                        ),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SwipeDismissSurface extends StatefulWidget {
  const _SwipeDismissSurface({required this.child, required this.onDismissed});

  final Widget child;
  final VoidCallback onDismissed;

  @override
  State<_SwipeDismissSurface> createState() => _SwipeDismissSurfaceState();
}

class _SwipeDismissSurfaceState extends State<_SwipeDismissSurface> {
  double _accumulatedDragDistance = 0;
  bool _dismissed = false;

  void _dismiss() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    widget.onDismissed();
  }

  void _resetDrag() {
    _accumulatedDragDistance = 0;
    _dismissed = false;
  }

  void _trackDragDelta(double delta) {
    _accumulatedDragDistance += delta.abs();
    if (_accumulatedDragDistance >= 24) {
      _dismiss();
    }
  }

  void _dismissByVelocity(double velocity) {
    if (velocity.abs() >= 420) {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _resetDrag(),
      onVerticalDragStart: (_) => _resetDrag(),
      onHorizontalDragUpdate: (details) =>
          _trackDragDelta(details.primaryDelta ?? 0),
      onVerticalDragUpdate: (details) =>
          _trackDragDelta(details.primaryDelta ?? 0),
      onHorizontalDragEnd: (details) =>
          _dismissByVelocity(details.primaryVelocity ?? 0),
      onVerticalDragEnd: (details) =>
          _dismissByVelocity(details.primaryVelocity ?? 0),
      child: widget.child,
    );
  }
}

class _FeedReviewsBottomSheet extends StatelessWidget {
  const _FeedReviewsBottomSheet({
    required this.restaurantName,
    required this.rating,
    required this.reviews,
    required this.onViewAllReviews,
  });

  final String restaurantName;
  final double rating;
  final List<RestaurantProfileReviewPreview> reviews;
  final VoidCallback onViewAllReviews;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = _clampDouble(media.size.height * 0.56, 320, 520);
    return SafeArea(
      top: false,
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD2C5BB),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatCompactCount(reviews.length)} reviews',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF7A695E),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7E6D62),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF5B63F),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF5B4A41),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFECE1D7)),
            Expanded(
              child: reviews.isEmpty
                  ? const Center(
                      child: Text(
                        'No reviews yet.',
                        style: TextStyle(
                          color: Color(0xFF7E6D62),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4EC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0E2D5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFE4D1),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: Color(0xFF9A5A3B),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            review.customerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF231A16),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          review.timeLabel,
                                          style: const TextStyle(
                                            color: Color(0xFF8A7A6F),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFF5B63F),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          review.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Color(0xFF5B4A41),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            review.orderLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF8A7A6F),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      review.comment,
                                      style: const TextStyle(
                                        color: Color(0xFF5B4A41),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onViewAllReviews,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.reviews_rounded),
                  label: const Text(
                    'View All Reviews',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCommentsBottomSheet extends StatefulWidget {
  const _FeedCommentsBottomSheet({
    required this.postId,
    required this.postTitle,
  });

  final String postId;
  final String postTitle;

  @override
  State<_FeedCommentsBottomSheet> createState() =>
      _FeedCommentsBottomSheetState();
}

class _FeedCommentsBottomSheetState extends State<_FeedCommentsBottomSheet> {
  final _repository = DemoAppRepository.instance;
  final _controller = TextEditingController();

  late List<DemoComment> _comments;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _comments = _repository.getComments(widget.postId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);
    final comments = await _repository.addComment(
      postId: widget.postId,
      authorName: 'You',
      text: text,
    );
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() {
      _comments = comments;
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = _clampDouble(media.size.height * 0.56, 320, 520);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2C5BB),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatCompactCount(_comments.length)} comments',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF231A16),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF7A695E),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFECE1D7)),
              Expanded(
                child: _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet. Start the conversation.',
                          style: TextStyle(
                            color: Color(0xFF7E6D62),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        itemCount: _comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4EC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF0E2D5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFE4D1),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Color(0xFF9A5A3B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              comment.authorName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF231A16),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatRelativeTime(
                                              comment.createdAt,
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF8A7A6F),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.body,
                                        style: const TextStyle(
                                          color: Color(0xFF5B4A41),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEADACC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEADACC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF9E70),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _isSending ? null : _sendComment,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7E4D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.metrics,
    required this.onTap,
  });

  final IconData icon;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: _clampDouble(52 * metrics.scale, 44, 52),
          height: _clampDouble(52 * metrics.scale, 44, 52),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3DCC8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14B56A45),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2E2521),
            size: _clampDouble(26 * metrics.scale, 20, 26),
          ),
        ),
      ),
    );
  }
}

class _UserProfileMenuDrawer extends StatelessWidget {
  const _UserProfileMenuDrawer({
    required this.userName,
    required this.onEditProfile,
    required this.authToken,
    this.userEmail,
    this.userAvatarUrl,
    this.userAvatarBytes,
  });

  final String userName;
  final VoidCallback onEditProfile;
  final String authToken;
  final String? userEmail;
  final String? userAvatarUrl;
  final Uint8List? userAvatarBytes;

  static const List<_ProfileSettingsItemData> _settingsItems = [
    _ProfileSettingsItemData(
      title: 'Edit Profile',
      icon: Icons.edit_rounded,
      destination: _ProfileSettingsDestination.editProfile,
    ),
    _ProfileSettingsItemData(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      destination: _ProfileSettingsDestination.notifications,
    ),
    _ProfileSettingsItemData(
      title: 'Payment Methods',
      icon: Icons.credit_card_rounded,
      destination: _ProfileSettingsDestination.paymentMethods,
    ),
    _ProfileSettingsItemData(
      title: 'Privacy & Security',
      icon: Icons.lock_outline_rounded,
      destination: _ProfileSettingsDestination.privacySecurity,
    ),
    _ProfileSettingsItemData(
      title: 'Help & Support',
      icon: Icons.help_outline_rounded,
      destination: _ProfileSettingsDestination.helpSupport,
    ),
  ];

  void _openSettingsDestination(
    BuildContext context,
    _ProfileSettingsDestination destination,
  ) {
    final navigator = Navigator.of(context);
    navigator.pop();
    switch (destination) {
      case _ProfileSettingsDestination.editProfile:
        onEditProfile();
        return;
      case _ProfileSettingsDestination.notifications:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(authToken: authToken),
          ),
        );
        return;
      case _ProfileSettingsDestination.paymentMethods:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const _CustomerPaymentMethodsScreen(),
          ),
        );
        return;
      case _ProfileSettingsDestination.privacySecurity:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const _CustomerPrivacySecurityScreen(),
          ),
        );
        return;
      case _ProfileSettingsDestination.helpSupport:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => _CustomerHelpSupportScreen(authToken: authToken),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8EFE5),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ResponsiveMetrics.from(constraints);
            final displayName = userName.trim().isEmpty
                ? 'Hungry Explorer'
                : userName.trim();
            final displayEmail = _profileEmail(
              handle: displayName.replaceAll(RegExp(r'\s+'), ''),
              email: userEmail,
            );
            final avatarBytes = userAvatarBytes;
            final hasAvatarBytes =
                avatarBytes != null && avatarBytes.isNotEmpty;
            final avatarUrl = userAvatarUrl?.trim();
            final hasAvatarUrl = _looksLikeHttpUrl(avatarUrl);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                _clampDouble(20 * metrics.scale, 18, 20),
                _clampDouble(18 * metrics.scale, 16, 18),
                _clampDouble(20 * metrics.scale, 18, 20),
                _clampDouble(18 * metrics.scale, 16, 18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Navigation',
                          style: TextStyle(
                            color: const Color(0xFF231A16),
                            fontSize: _clampDouble(28 * metrics.scale, 22, 28),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF5A4A40),
                      ),
                    ],
                  ),
                  SizedBox(height: _clampDouble(20 * metrics.scale, 16, 20)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      _clampDouble(18 * metrics.scale, 14, 18),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCFA),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFF2DCCB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: _clampDouble(54 * metrics.scale, 44, 54),
                          height: _clampDouble(54 * metrics.scale, 44, 54),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFE4C0), Color(0xFFFFC18E)],
                            ),
                          ),
                          child: ClipOval(
                            child: hasAvatarBytes
                                ? Image.memory(
                                    avatarBytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) =>
                                        Icon(
                                          Icons.person_rounded,
                                          color: const Color(0xFF8B5C41),
                                          size: _clampDouble(
                                            28 * metrics.scale,
                                            22,
                                            28,
                                          ),
                                        ),
                                  )
                                : hasAvatarUrl
                                ? Image.network(
                                    avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) =>
                                        Icon(
                                          Icons.person_rounded,
                                          color: const Color(0xFF8B5C41),
                                          size: _clampDouble(
                                            28 * metrics.scale,
                                            22,
                                            28,
                                          ),
                                        ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: const Color(0xFF8B5C41),
                                    size: _clampDouble(
                                      28 * metrics.scale,
                                      22,
                                      28,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(
                          width: _clampDouble(14 * metrics.scale, 10, 14),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF231A16),
                                  fontSize: _clampDouble(
                                    18 * metrics.scale,
                                    15,
                                    18,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(4 * metrics.scale, 2, 4),
                              ),
                              Text(
                                displayEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF847468),
                                  fontSize: _clampDouble(
                                    13 * metrics.scale,
                                    11,
                                    13,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _clampDouble(22 * metrics.scale, 18, 22)),
                  Text(
                    'Account Settings',
                    style: TextStyle(
                      color: const Color(0xFF231A16),
                      fontSize: _clampDouble(20 * metrics.scale, 17, 20),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _clampDouble(12 * metrics.scale, 10, 12)),
                  _ProfilePanel(
                    child: Column(
                      children: List.generate(_settingsItems.length, (index) {
                        final item = _settingsItems[index];
                        return Column(
                          children: [
                            _ProfileSettingsTile(
                              data: item,
                              metrics: metrics,
                              onTap: () => _openSettingsDestination(
                                context,
                                item.destination,
                              ),
                            ),
                            if (index != _settingsItems.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0xFFF0E2D3),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        final authSessionService = AuthSessionService();
                        await authSessionService.clearSession();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF7E4D),
                        padding: EdgeInsets.symmetric(
                          vertical: _clampDouble(14 * metrics.scale, 12, 14),
                        ),
                        textStyle: TextStyle(
                          fontSize: _clampDouble(18 * metrics.scale, 16, 18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CustomerPaymentMethodsScreen extends StatefulWidget {
  const _CustomerPaymentMethodsScreen();

  @override
  State<_CustomerPaymentMethodsScreen> createState() =>
      _CustomerPaymentMethodsScreenState();
}

class _CustomerPaymentMethodsScreenState
    extends State<_CustomerPaymentMethodsScreen> {
  late List<_CustomerPaymentMethodData> _methods;
  int _defaultMethodIndex = 0;
  bool _saveNewCardsToWallet = true;

  @override
  void initState() {
    super.initState();
    _methods = <_CustomerPaymentMethodData>[
      const _CustomerPaymentMethodData(
        label: 'Cash on delivery',
        details: 'Pay with cash when your order arrives.',
        icon: Icons.local_shipping_rounded,
      ),
      const _CustomerPaymentMethodData(
        label: 'Visa ending 4821',
        details: 'Expires 11/29',
        icon: Icons.credit_card_rounded,
      ),
      const _CustomerPaymentMethodData(
        label: 'Whish Money',
        details: 'Primary wallet linked',
        icon: Icons.account_balance_wallet_rounded,
      ),
    ];
  }

  Future<void> _showAddCardDialog() async {
    final holderController = TextEditingController();
    final last4Controller = TextEditingController();
    final expiryController = TextEditingController();

    final added = await showDialog<_CustomerPaymentMethodData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: holderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Card holder name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: last4Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Last 4 digits'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: expiryController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final holder = holderController.text.trim();
                final last4 = last4Controller.text.trim();
                final expiry = expiryController.text.trim();
                final messenger = ScaffoldMessenger.maybeOf(context);
                if (holder.isEmpty ||
                    !RegExp(r'^\d{4}$').hasMatch(last4) ||
                    expiry.isEmpty) {
                  messenger
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter holder name, valid last 4 digits, and expiry.',
                        ),
                      ),
                    );
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _CustomerPaymentMethodData(
                    label: 'Visa ending $last4',
                    details: '$holder • Expires $expiry',
                    icon: Icons.credit_card_rounded,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E4D),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    holderController.dispose();
    last4Controller.dispose();
    expiryController.dispose();

    if (!mounted || added == null) {
      return;
    }
    setState(() {
      _methods = [..._methods, added];
      _defaultMethodIndex = _methods.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your default checkout method.',
                style: TextStyle(
                  color: Color(0xFF7D6C60),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _methods.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    final selected = index == _defaultMethodIndex;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _defaultMethodIndex = index),
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFCFA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFFFC2A5)
                                  : const Color(0xFFF0DCCB),
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFFFEFE6)
                                      : const Color(0xFFF7F2EC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method.icon,
                                  color: const Color(0xFF8A5A40),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.label,
                                      style: const TextStyle(
                                        color: Color(0xFF231A16),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      method.details,
                                      style: const TextStyle(
                                        color: Color(0xFF7D6C60),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? const Color(0xFFFF7E4D)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFFF7E4D)
                                        : const Color(0xFFDCCBBB),
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SwitchListTile.adaptive(
                value: _saveNewCardsToWallet,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                activeThumbColor: const Color(0xFFFF7E4D),
                activeTrackColor: const Color(0xFFFFD8C7),
                title: const Text(
                  'Save new cards to my wallet',
                  style: TextStyle(
                    color: Color(0xFF231A16),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Use saved methods on future checkouts.',
                  style: TextStyle(
                    color: Color(0xFF7D6C60),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _saveNewCardsToWallet = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add New Card',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerPrivacySecurityScreen extends StatefulWidget {
  const _CustomerPrivacySecurityScreen();

  @override
  State<_CustomerPrivacySecurityScreen> createState() =>
      _CustomerPrivacySecurityScreenState();
}

class _CustomerPrivacySecurityScreenState
    extends State<_CustomerPrivacySecurityScreen> {
  bool _biometricLogin = true;
  bool _twoFactorCode = false;
  bool _hidePhoneNumber = true;
  bool _shareUsageAnalytics = false;

  Future<void> _openChangePasswordDialog() async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nextController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final current = currentController.text.trim();
                final next = nextController.text.trim();
                final messenger = ScaffoldMessenger.maybeOf(context);
                if (current.isEmpty || next.length < 6) {
                  messenger
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter current password and a new one with at least 6 characters.',
                        ),
                      ),
                    );
                  return;
                }
                Navigator.of(dialogContext).pop();
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully.'),
                    ),
                  );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E4D),
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    currentController.dispose();
    nextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const Text(
              'Control how your account and personal data are protected.',
              style: TextStyle(
                color: Color(0xFF7D6C60),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ProfilePanel(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _biometricLogin,
                    activeThumbColor: const Color(0xFFFF7E4D),
                    activeTrackColor: const Color(0xFFFFD8C7),
                    title: const Text('Biometric login'),
                    subtitle: const Text(
                      'Use Face ID or fingerprint to sign in.',
                    ),
                    onChanged: (value) =>
                        setState(() => _biometricLogin = value),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0E2D3)),
                  SwitchListTile.adaptive(
                    value: _twoFactorCode,
                    activeThumbColor: const Color(0xFFFF7E4D),
                    activeTrackColor: const Color(0xFFFFD8C7),
                    title: const Text('Two-step verification'),
                    subtitle: const Text('Request a code when signing in.'),
                    onChanged: (value) =>
                        setState(() => _twoFactorCode = value),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0E2D3)),
                  SwitchListTile.adaptive(
                    value: _hidePhoneNumber,
                    activeThumbColor: const Color(0xFFFF7E4D),
                    activeTrackColor: const Color(0xFFFFD8C7),
                    title: const Text('Hide phone number on receipts'),
                    subtitle: const Text(
                      'Mask your number in receipt history.',
                    ),
                    onChanged: (value) =>
                        setState(() => _hidePhoneNumber = value),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0E2D3)),
                  SwitchListTile.adaptive(
                    value: _shareUsageAnalytics,
                    activeThumbColor: const Color(0xFFFF7E4D),
                    activeTrackColor: const Color(0xFFFFD8C7),
                    title: const Text('Share anonymous analytics'),
                    subtitle: const Text(
                      'Help us improve app performance and reliability.',
                    ),
                    onChanged: (value) =>
                        setState(() => _shareUsageAnalytics = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openChangePasswordDialog,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text(
                  'Change Password',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7E4D),
                  side: const BorderSide(color: Color(0xFFFFC9B2)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerHelpSupportScreen extends StatefulWidget {
  const _CustomerHelpSupportScreen({this.authToken});

  final String? authToken;

  @override
  State<_CustomerHelpSupportScreen> createState() =>
      _CustomerHelpSupportScreenState();
}

class _CustomerHelpSupportScreenState
    extends State<_CustomerHelpSupportScreen> {
  final _supportReportApiService = SupportReportApiService();

  static const List<_SupportFaqItemData> _faqs = [
    _SupportFaqItemData(
      question: 'How can I track my order?',
      answer:
          'Open Orders and tap your live order card. You can view every stage from pending to delivered.',
    ),
    _SupportFaqItemData(
      question: 'How do loyalty points work?',
      answer:
          'Points are added after successful orders. You can apply available points during checkout for a discount.',
    ),
    _SupportFaqItemData(
      question: 'Can I change delivery time after placing an order?',
      answer:
          'If the restaurant has not started preparing, support may help update delivery timing.',
    ),
  ];

  Future<void> _openSupportRequestSheet(String channel) async {
    final detailsController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact support via $channel',
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share your issue and our team will reply shortly.',
                  style: TextStyle(
                    color: Color(0xFF7D6C60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue',
                    filled: true,
                    fillColor: const Color(0xFFFEFCFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final details = detailsController.text.trim();
                      if (details.isEmpty) {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        messenger
                          ?..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Please add issue details first.'),
                            ),
                          );
                        return;
                      }
                      Navigator.of(sheetContext).pop();
                      final token = widget.authToken?.trim() ?? '';
                      if (token.isNotEmpty) {
                        try {
                          await _supportReportApiService.submitSupportRequest(
                            token: token,
                            channel: channel.toLowerCase(),
                            subject: 'Customer support via $channel',
                            message: details,
                          );
                        } on SupportReportApiException catch (e) {
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.maybeOf(context)
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(e.message)));
                          return;
                        }
                      }
                      if (!mounted) {
                        return;
                      }
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('Support request sent via $channel.'),
                          ),
                        );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E4D),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Send Request',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    detailsController.dispose();
  }

  @override
  void dispose() {
    _supportReportApiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const Text(
              'Need help? Choose a support channel or browse quick answers.',
              style: TextStyle(
                color: Color(0xFF7D6C60),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ProfilePanel(
              child: Column(
                children: [
                  _SupportActionTile(
                    icon: Icons.email_outlined,
                    title: 'Email support',
                    subtitle: 'support@hungerrush.app',
                    onTap: () => _openSupportRequestSheet('Email'),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0E2D3)),
                  _SupportActionTile(
                    icon: Icons.call_rounded,
                    title: 'Call support',
                    subtitle: '+961 1 234 567',
                    onTap: () {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Dialing support: +961 1 234 567'),
                          ),
                        );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: Color(0xFF231A16),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _ProfilePanel(
              child: Column(
                children: List.generate(_faqs.length, (index) {
                  final item = _faqs[index];
                  return Column(
                    children: [
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          14,
                          0,
                          14,
                          14,
                        ),
                        iconColor: const Color(0xFFFF7E4D),
                        collapsedIconColor: const Color(0xFF8A7A70),
                        title: Text(
                          item.question,
                          style: const TextStyle(
                            color: Color(0xFF231A16),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.answer,
                              style: const TextStyle(
                                color: Color(0xFF7D6C60),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (index != _faqs.length - 1)
                        const Divider(height: 1, color: Color(0xFFF0E2D3)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  const _SupportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFFF7E4D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFAE9B8D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.userName,
    required this.userHandle,
    this.userEmail,
    this.userAvatarUrl,
    this.userAvatarBytes,
    this.accountLabel,
    required this.followingCountLabel,
    this.onOpenFollowing,
    required this.metrics,
  });

  final String userName;
  final String userHandle;
  final String? userEmail;
  final String? userAvatarUrl;
  final Uint8List? userAvatarBytes;
  final String? accountLabel;
  final String followingCountLabel;
  final VoidCallback? onOpenFollowing;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final avatarSize = _clampDouble(76 * metrics.scale, 60, 76);
    final displayName = userName.trim().isEmpty
        ? 'Hungry Explorer'
        : userName.trim();
    final displayNameFontSize = displayName.length > 12
        ? _clampDouble(20 * metrics.scale, 15, 20)
        : _clampDouble(24 * metrics.scale, 18, 24);
    final displayEmail = _profileEmail(handle: userHandle, email: userEmail);
    final avatarBytes = userAvatarBytes;
    final hasAvatarBytes = avatarBytes != null && avatarBytes.isNotEmpty;
    final avatarUrl = userAvatarUrl?.trim();
    final hasAvatarUrl = _looksLikeHttpUrl(avatarUrl);
    final normalizedAccountLabel = accountLabel?.trim();
    final displayAccountLabel =
        normalizedAccountLabel != null && normalizedAccountLabel.isNotEmpty
        ? normalizedAccountLabel
        : 'Hungry Account';
    return Container(
      padding: EdgeInsets.all(_clampDouble(20 * metrics.scale, 16, 20)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF3DFCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16A7633A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFE7C7), Color(0xFFFFC79A)],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1EB56A45),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasAvatarBytes
                          ? Image.memory(
                              avatarBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) => Icon(
                                Icons.person_rounded,
                                color: const Color(0xFF8B5C41),
                                size: avatarSize * 0.56,
                              ),
                            )
                          : hasAvatarUrl
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) => Icon(
                                Icons.person_rounded,
                                color: const Color(0xFF8B5C41),
                                size: avatarSize * 0.56,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: const Color(0xFF8B5C41),
                              size: avatarSize * 0.56,
                            ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: _clampDouble(18 * metrics.scale, 14, 18),
                      height: _clampDouble(18 * metrics.scale, 14, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24B15F),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _clampDouble(10 * metrics.scale, 6, 10)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _clampDouble(10 * metrics.scale, 8, 10),
                  vertical: _clampDouble(6 * metrics.scale, 4, 6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  displayAccountLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFFF7E4D),
                    fontSize: _clampDouble(12.5 * metrics.scale, 10, 12.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: _clampDouble(16 * metrics.scale, 12, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF231A16),
                    fontSize: displayNameFontSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                Text(
                  displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF7D6E63),
                    fontSize: _clampDouble(16 * metrics.scale, 12, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpenFollowing,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: EdgeInsets.symmetric(
                        horizontal: _clampDouble(10 * metrics.scale, 8, 10),
                        vertical: _clampDouble(7 * metrics.scale, 5, 7),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_rounded,
                            color: const Color(0xFF2F8A7E),
                            size: _clampDouble(14 * metrics.scale, 12, 14),
                          ),
                          SizedBox(
                            width: _clampDouble(5 * metrics.scale, 4, 5),
                          ),
                          Text(
                            '$followingCountLabel following',
                            style: TextStyle(
                              color: const Color(0xFF2F8A7E),
                              fontSize: _clampDouble(
                                12.5 * metrics.scale,
                                10,
                                12.5,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.metrics,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _clampDouble(170 * metrics.scale, 146, 170),
      padding: EdgeInsets.all(_clampDouble(18 * metrics.scale, 14, 18)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3DFCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12A7633A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -18,
            child: Container(
              width: _clampDouble(96 * metrics.scale, 74, 96),
              height: _clampDouble(96 * metrics.scale, 74, 96),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF77675D),
                        fontSize: _clampDouble(14 * metrics.scale, 12, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: _clampDouble(32 * metrics.scale, 28, 32),
                    height: _clampDouble(32 * metrics.scale, 28, 32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: _clampDouble(18 * metrics.scale, 14, 18),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontSize: _clampDouble(30 * metrics.scale, 22, 30),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: _clampDouble(10 * metrics.scale, 6, 10)),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF8C7C71),
                  fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF231A16),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: Color(0xFFFF7E4D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3DFCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12A7633A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  const _RecentOrderCard({
    required this.data,
    required this.metrics,
    this.onReorder,
  });

  final _PastOrderEntryData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _clampDouble(metrics.width * 0.78, 250, 310);
    final imageSize = _clampDouble(78 * metrics.scale, 64, 78);
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 12, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3DFCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10A7633A),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _FoodThumb(imageUrl: data.imageUrl, size: imageSize),
          SizedBox(width: _clampDouble(14 * metrics.scale, 10, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF231A16),
                    fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                Text(
                  data.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF7E6D62),
                    fontSize: _clampDouble(15 * metrics.scale, 11, 15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onReorder,
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          padding: EdgeInsets.symmetric(
                            horizontal: _clampDouble(
                              14 * metrics.scale,
                              10,
                              14,
                            ),
                            vertical: _clampDouble(8 * metrics.scale, 6, 8),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7E4D),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            data.status == _OrderStatus.rejected ||
                                    data.status == _OrderStatus.canceled
                                ? 'Order again'
                                : 'Reorder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _clampDouble(
                                14 * metrics.scale,
                                11,
                                14,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                    Expanded(
                      child: Text(
                        data.dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF9C8A7C),
                          fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodThumb extends StatelessWidget {
  const _FoodThumb({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD6B4), Color(0xFFFF9C6C)],
                ),
              ),
              child: Icon(
                Icons.fastfood_rounded,
                color: Colors.white,
                size: size * 0.45,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SavedPlaceTile extends StatelessWidget {
  const _SavedPlaceTile({
    required this.data,
    required this.metrics,
    this.onTap,
  });

  final _SavedPlaceData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(18 * metrics.scale, 14, 18),
            vertical: _clampDouble(16 * metrics.scale, 12, 16),
          ),
          child: Row(
            children: [
              Container(
                width: _clampDouble(50 * metrics.scale, 42, 50),
                height: _clampDouble(50 * metrics.scale, 42, 50),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F0EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: const Color(0xFF7A6B61),
                  size: _clampDouble(26 * metrics.scale, 20, 26),
                ),
              ),
              SizedBox(width: _clampDouble(14 * metrics.scale, 10, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF231A16),
                        fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF847468),
                        fontSize: _clampDouble(15 * metrics.scale, 11, 15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.favorite_rounded,
                color: const Color(0xFFFF7E4D),
                size: _clampDouble(28 * metrics.scale, 22, 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsTile extends StatelessWidget {
  const _ProfileSettingsTile({
    required this.data,
    required this.metrics,
    this.onTap,
  });

  final _ProfileSettingsItemData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(18 * metrics.scale, 14, 18),
            vertical: _clampDouble(18 * metrics.scale, 14, 18),
          ),
          child: Row(
            children: [
              Icon(
                data.icon,
                color: const Color(0xFF7D6E63),
                size: _clampDouble(28 * metrics.scale, 22, 28),
              ),
              SizedBox(width: _clampDouble(16 * metrics.scale, 12, 16)),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: const Color(0xFF231A16),
                    fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFAE9B8D),
                size: _clampDouble(24 * metrics.scale, 20, 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedPlaceData {
  const _SavedPlaceData({
    required this.title,
    required this.subtitle,
    required this.handle,
    required this.rating,
    required this.caption,
    required this.cuisineSummary,
    required this.phoneLabel,
    required this.locationLabel,
    required this.followersCount,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String handle;
  final double rating;
  final String caption;
  final String cuisineSummary;
  final String phoneLabel;
  final String locationLabel;
  final int followersCount;
  final IconData icon;
}

class _OrdersMetricData {
  const _OrdersMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
}

class _OrderTimelineStepData {
  const _OrderTimelineStepData({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isComplete,
    required this.isCurrent,
  });

  final _OrderStatus status;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isComplete;
  final bool isCurrent;
}

class _PastOrderEntryData {
  const _PastOrderEntryData({
    required this.title,
    required this.summary,
    required this.dateLabel,
    required this.totalLabel,
    required this.status,
    required this.imageUrl,
    required this.reorderItems,
  });

  final String title;
  final String summary;
  final String dateLabel;
  final String totalLabel;
  final _OrderStatus status;
  final String imageUrl;
  final List<_CartLineItemData> reorderItems;
}

class _OrderReceiptData {
  const _OrderReceiptData({
    required this.orderId,
    required this.restaurantName,
    required this.summary,
    required this.placedAtLabel,
    required this.status,
    required this.imageUrl,
    required this.paymentMethodLabel,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discountPercent,
    required this.loyaltyPointsUsed,
    required this.loyaltyDiscountUsd,
    required this.items,
  });

  final String orderId;
  final String restaurantName;
  final String summary;
  final String placedAtLabel;
  final _OrderStatus status;
  final String imageUrl;
  final String paymentMethodLabel;
  final double deliveryFee;
  final double serviceFee;
  final double discountPercent;
  final int loyaltyPointsUsed;
  final double loyaltyDiscountUsd;
  final List<_OrderReceiptLineItemData> items;

  int get totalItems =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  double get subtotalUsd =>
      items.fold<double>(0, (total, item) => total + item.totalPrice);

  double get _baseTotalUsd => subtotalUsd + deliveryFee + serviceFee;

  double get _percentDiscountUsd => _baseTotalUsd * (discountPercent / 100);

  double get totalDiscountUsd => _percentDiscountUsd + loyaltyDiscountUsd;

  double get totalUsd =>
      (_baseTotalUsd - totalDiscountUsd).clamp(0, double.infinity);
}

class _OrderReceiptLineItemData {
  const _OrderReceiptLineItemData({
    required this.title,
    this.subtitle = '',
    required this.quantity,
    required this.unitPrice,
  });

  final String title;
  final String subtitle;
  final int quantity;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;
}

class _CartLineItemData {
  const _CartLineItemData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.restaurantName = '',
    this.menuItemId,
    this.cartItemId,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final double price;
  final int quantity;
  final String restaurantName;
  final String? menuItemId;
  final String? cartItemId;

  _CartLineItemData copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    double? price,
    int? quantity,
    String? restaurantName,
    String? menuItemId,
    String? cartItemId,
  }) {
    return _CartLineItemData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      restaurantName: restaurantName ?? this.restaurantName,
      menuItemId: menuItemId ?? this.menuItemId,
      cartItemId: cartItemId ?? this.cartItemId,
    );
  }
}

class _RestaurantCartData {
  const _RestaurantCartData({
    required this.restaurantName,
    required this.items,
  });

  final String restaurantName;
  final List<_CartLineItemData> items;

  int get totalItems =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  double get subtotal => items.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );

  String get coverImageUrl => items.isEmpty
      ? 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80'
      : items.first.imageUrl;
}

String _normalizeRestaurantKey(String value) {
  return value.trim().toLowerCase();
}

String _firstRestaurantNameFromItems(List<_CartLineItemData> items) {
  for (final item in items) {
    final name = _resolvedCartItemRestaurantName(item);
    if (name.isNotEmpty) {
      return name;
    }
  }
  return '';
}

String _resolvedCartItemRestaurantName(_CartLineItemData item) {
  final direct = item.restaurantName.trim();
  if (direct.isNotEmpty) {
    return direct;
  }
  final subtitle = item.subtitle.trim();
  if (subtitle.isEmpty) {
    return '';
  }
  const separators = ['•', '-', '–', '—', '|', '/'];
  for (final separator in separators) {
    final index = subtitle.indexOf(separator);
    if (index > 0) {
      return subtitle.substring(0, index).trim();
    }
  }
  return '';
}

class _DiscoverCategoryData {
  const _DiscoverCategoryData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
}

class _DiscoverSpotData {
  const _DiscoverSpotData({
    this.restaurantId,
    required this.title,
    required this.handle,
    required this.categoryTitle,
    required this.subtitle,
    required this.deliveryLabel,
    required this.ratingLabel,
    required this.priceTier,
    required this.badge,
    required this.imageUrl,
  });

  final String? restaurantId;
  final String title;
  final String handle;
  final String categoryTitle;
  final String subtitle;
  final String deliveryLabel;
  final String ratingLabel;
  final int priceTier;
  final String badge;
  final String imageUrl;

  int get deliveryMinutes =>
      int.tryParse(deliveryLabel.split(' ').first.trim()) ?? 999;

  double get ratingValue => double.tryParse(ratingLabel.trim()) ?? 0;
}

class _DiscoverDealData {
  const _DiscoverDealData({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.promoLabel,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
  final String promoLabel;
  final IconData icon;
  final Color accentColor;
}

const List<RestaurantMenuItem> _discoverPizzaMenuItems = [
  RestaurantMenuItem(
    id: 'pizza-margherita',
    title: 'Margherita Fire',
    description: 'Fresh mozzarella, basil leaves, tomato sauce, and olive oil.',
    price: 10.80,
    imageUrl:
        'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=900&q=80',
    category: 'Pizza',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 180,
  ),
  RestaurantMenuItem(
    id: 'pizza-pepperoni',
    title: 'Pepperoni Feast',
    description: 'Loaded pepperoni slices, melted mozzarella, and oregano.',
    price: 12.40,
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    category: 'Pizza',
    isAvailable: true,
    isPopular: true,
    rating: 4.9,
    ordersCount: 216,
  ),
  RestaurantMenuItem(
    id: 'pizza-truffle',
    title: 'Truffle Burrata',
    description: 'Burrata cream, mushrooms, truffle oil, and parmesan flakes.',
    price: 14.60,
    imageUrl:
        'https://images.unsplash.com/photo-1593504049359-74330189a345?auto=format&fit=crop&w=900&q=80',
    category: 'Signature',
    isAvailable: true,
    isPopular: false,
    rating: 4.7,
    ordersCount: 94,
  ),
  RestaurantMenuItem(
    id: 'pizza-garlic-knots',
    title: 'Garlic Knots',
    description: 'Six golden knots brushed with butter, parsley, and parmesan.',
    price: 4.90,
    imageUrl:
        'https://images.unsplash.com/photo-1619531038896-dc1a44a84f95?auto=format&fit=crop&w=900&q=80',
    category: 'Starters',
    isAvailable: true,
    isPopular: false,
    rating: 4.6,
    ordersCount: 102,
  ),
];

const List<RestaurantMenuItem> _discoverBurgerMenuItems = [
  RestaurantMenuItem(
    id: 'burger-angus',
    title: 'Double Angus Stack',
    description: 'Two smashed patties, cheddar, pickles, and signature sauce.',
    price: 13.20,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
    category: 'Burgers',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 228,
  ),
  RestaurantMenuItem(
    id: 'burger-classic',
    title: 'Classic Smash',
    description: 'Smash beef patty, lettuce, tomato, onion, and burger sauce.',
    price: 9.90,
    imageUrl:
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
    category: 'Burgers',
    isAvailable: true,
    isPopular: true,
    rating: 4.7,
    ordersCount: 172,
  ),
  RestaurantMenuItem(
    id: 'burger-cajun-fries',
    title: 'Cajun Fries',
    description: 'Seasoned crispy fries with smoky paprika and sea salt.',
    price: 4.30,
    imageUrl:
        'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=900&q=80',
    category: 'Sides',
    isAvailable: true,
    isPopular: false,
    rating: 4.5,
    ordersCount: 132,
  ),
  RestaurantMenuItem(
    id: 'burger-milkshake',
    title: 'Vanilla Milkshake',
    description: 'Creamy vanilla shake topped with whipped cream.',
    price: 3.80,
    imageUrl:
        'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=900&q=80',
    category: 'Drinks',
    isAvailable: true,
    isPopular: false,
    rating: 4.4,
    ordersCount: 88,
  ),
];

const List<RestaurantMenuItem> _discoverSushiMenuItems = [
  RestaurantMenuItem(
    id: 'sushi-salmon-roll',
    title: 'Salmon Crunch Roll',
    description: 'Salmon, avocado, cucumber, crispy flakes, and teriyaki.',
    price: 11.70,
    imageUrl:
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=80',
    category: 'Sushi',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 166,
  ),
  RestaurantMenuItem(
    id: 'sushi-dragon-roll',
    title: 'Dragon Roll',
    description: 'Shrimp tempura, avocado, eel sauce, and sesame.',
    price: 13.90,
    imageUrl:
        'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?auto=format&fit=crop&w=900&q=80',
    category: 'Sushi',
    isAvailable: true,
    isPopular: true,
    rating: 4.9,
    ordersCount: 145,
  ),
  RestaurantMenuItem(
    id: 'sushi-poke-bowl',
    title: 'Tuna Poke Bowl',
    description: 'Marinated tuna, rice, mango, edamame, and spicy mayo.',
    price: 12.50,
    imageUrl:
        'https://images.unsplash.com/photo-1604908554027-6e8f3f2b54f8?auto=format&fit=crop&w=900&q=80',
    category: 'Bowls',
    isAvailable: true,
    isPopular: false,
    rating: 4.6,
    ordersCount: 104,
  ),
  RestaurantMenuItem(
    id: 'sushi-miso-soup',
    title: 'Miso Soup',
    description: 'Warm miso broth with tofu cubes, seaweed, and scallions.',
    price: 3.20,
    imageUrl:
        'https://images.unsplash.com/photo-1623341214825-9f4f963727da?auto=format&fit=crop&w=900&q=80',
    category: 'Sides',
    isAvailable: true,
    isPopular: false,
    rating: 4.5,
    ordersCount: 93,
  ),
];

const List<RestaurantMenuItem> _discoverDessertMenuItems = [
  RestaurantMenuItem(
    id: 'dessert-lava-cake',
    title: 'Chocolate Lava Cake',
    description: 'Warm molten center cake with vanilla cream.',
    price: 7.10,
    imageUrl:
        'https://images.unsplash.com/photo-1621303837174-89787a7d4729?auto=format&fit=crop&w=900&q=80',
    category: 'Desserts',
    isAvailable: true,
    isPopular: true,
    rating: 4.9,
    ordersCount: 194,
  ),
  RestaurantMenuItem(
    id: 'dessert-gelato',
    title: 'Pistachio Gelato',
    description: 'Small-batch gelato topped with crushed pistachio.',
    price: 5.40,
    imageUrl:
        'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=900&q=80',
    category: 'Desserts',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 152,
  ),
  RestaurantMenuItem(
    id: 'dessert-cheesecake',
    title: 'Berry Cheesecake',
    description: 'Creamy cheesecake with mixed berry compote.',
    price: 6.70,
    imageUrl:
        'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=900&q=80',
    category: 'Desserts',
    isAvailable: true,
    isPopular: false,
    rating: 4.7,
    ordersCount: 98,
  ),
  RestaurantMenuItem(
    id: 'dessert-cookies',
    title: 'Chocolate Chip Cookies',
    description: 'Three soft-baked cookies with dark chocolate chunks.',
    price: 4.20,
    imageUrl:
        'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&w=900&q=80',
    category: 'Bakery',
    isAvailable: true,
    isPopular: false,
    rating: 4.5,
    ordersCount: 86,
  ),
];

class _DiscoverFiltersState {
  const _DiscoverFiltersState({
    this.selectedCuisineTitles = const <String>{},
    this.minimumRating = 0,
    this.maximumDeliveryMinutes,
    this.maximumPriceTier,
  });

  final Set<String> selectedCuisineTitles;
  final double minimumRating;
  final int? maximumDeliveryMinutes;
  final int? maximumPriceTier;
}

class _EditableCustomerProfileData {
  const _EditableCustomerProfileData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.streetAddress,
    required this.accountLabel,
    required this.avatarUrl,
    this.profilePhotoBytes,
  });

  final String fullName;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String streetAddress;
  final String accountLabel;
  final String avatarUrl;
  final Uint8List? profilePhotoBytes;

  factory _EditableCustomerProfileData.fromUserHome(UserHomeScreen source) {
    final initialAccountLabel = source.accountLabel?.trim();
    return _EditableCustomerProfileData(
      fullName: source.userName,
      email: source.userEmail?.trim() ?? '',
      phone: '',
      country: '',
      city: '',
      streetAddress: '',
      accountLabel: initialAccountLabel == null || initialAccountLabel.isEmpty
          ? 'Hungry Account'
          : initialAccountLabel,
      avatarUrl: source.userAvatarUrl?.trim() ?? '',
      profilePhotoBytes: null,
    );
  }

  _EditableCustomerProfileData copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? country,
    String? city,
    String? streetAddress,
    String? accountLabel,
    String? avatarUrl,
    Uint8List? profilePhotoBytes,
  }) {
    return _EditableCustomerProfileData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      streetAddress: streetAddress ?? this.streetAddress,
      accountLabel: accountLabel ?? this.accountLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profilePhotoBytes: profilePhotoBytes ?? this.profilePhotoBytes,
    );
  }

  bool matches(_EditableCustomerProfileData other) {
    return _normalized(fullName) == _normalized(other.fullName) &&
        _normalized(email) == _normalized(other.email) &&
        _normalized(phone) == _normalized(other.phone) &&
        _normalized(country) == _normalized(other.country) &&
        _normalized(city) == _normalized(other.city) &&
        _normalized(streetAddress) == _normalized(other.streetAddress) &&
        _normalized(accountLabel) == _normalized(other.accountLabel) &&
        _normalized(avatarUrl) == _normalized(other.avatarUrl) &&
        _bytesEqual(profilePhotoBytes, other.profilePhotoBytes);
  }

  String _normalized(String value) => value.trim();

  bool _bytesEqual(Uint8List? first, Uint8List? second) {
    if (identical(first, second)) {
      return true;
    }
    if (first == null || second == null || first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }

  String? get nullableEmail {
    final normalized = email.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? get nullableAvatarUrl {
    final normalized = avatarUrl.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String get resolvedAccountLabel {
    final normalized = accountLabel.trim();
    return normalized.isEmpty ? 'Hungry Account' : normalized;
  }
}

class _CustomerEditProfileScreen extends StatefulWidget {
  const _CustomerEditProfileScreen({required this.initialData});

  final _EditableCustomerProfileData initialData;

  @override
  State<_CustomerEditProfileScreen> createState() =>
      _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState
    extends State<_CustomerEditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final TextEditingController _streetController;
  Uint8List? _selectedProfilePhotoBytes;
  bool _isPickingProfilePhoto = false;
  bool _hasChanges = false;

  List<TextEditingController> get _controllers => [
    _fullNameController,
    _emailController,
    _phoneController,
    _countryController,
    _cityController,
    _streetController,
  ];

  _EditableCustomerProfileData get _currentData => _EditableCustomerProfileData(
    fullName: _fullNameController.text.trim(),
    email: _emailController.text.trim(),
    phone: _phoneController.text.trim(),
    country: _countryController.text.trim(),
    city: _cityController.text.trim(),
    streetAddress: _streetController.text.trim(),
    accountLabel: widget.initialData.accountLabel,
    avatarUrl: widget.initialData.avatarUrl,
    profilePhotoBytes: _selectedProfilePhotoBytes,
  );

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialData.fullName,
    );
    _emailController = TextEditingController(text: widget.initialData.email);
    _phoneController = TextEditingController(text: widget.initialData.phone);
    _countryController = TextEditingController(
      text: widget.initialData.country,
    );
    _cityController = TextEditingController(text: widget.initialData.city);
    _streetController = TextEditingController(
      text: widget.initialData.streetAddress,
    );
    _selectedProfilePhotoBytes = widget.initialData.profilePhotoBytes;

    for (final controller in _controllers) {
      controller.addListener(_handleFormChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_handleFormChanged);
      controller.dispose();
    }
    super.dispose();
  }

  bool _isValidEmail(String value) {
    if (value.trim().isEmpty) {
      return true;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  void _handleFormChanged() {
    final hasChanges = !_currentData.matches(widget.initialData);
    if (hasChanges == _hasChanges) {
      return;
    }
    setState(() {
      _hasChanges = hasChanges;
    });
  }

  Future<void> _pickProfilePhoto() async {
    if (_isPickingProfilePhoto) {
      return;
    }

    setState(() => _isPickingProfilePhoto = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || picked == null || picked.files.isEmpty) {
        return;
      }
      final bytes = picked.files.first.bytes;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load the selected photo. Try another one.',
            ),
            backgroundColor: Color(0xFFB7372B),
          ),
        );
        return;
      }
      setState(() {
        _selectedProfilePhotoBytes = bytes;
      });
      _handleFormChanged();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pick a photo right now. Please try again.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingProfilePhoto = false);
      }
    }
  }

  void _saveChanges() {
    final data = _currentData;
    if (data.fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your full name.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }
    if (!_isValidEmail(data.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }
    Navigator.of(context).pop(data);
  }

  Widget _buildSaveActionBar() {
    return Container(
      key: const ValueKey('customer-save-action-bar'),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE2D2), Color(0xFFFFF7F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC8AF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF7E4D),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          onPressed: _saveChanges,
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFFF7E4D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EFE8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF2E2521),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            children: [
              _CustomerProfilePhotoPicker(
                photoBytes: _selectedProfilePhotoBytes,
                avatarUrl: widget.initialData.nullableAvatarUrl,
                onPickPhoto: _pickProfilePhoto,
                isPicking: _isPickingProfilePhoto,
              ),
              const SizedBox(height: 12),
              _CustomerReadonlyProfileField(
                label: 'Account Label',
                value: widget.initialData.resolvedAccountLabel,
              ),
              const SizedBox(height: 12),
              _CustomerEditProfileField(
                label: 'Full Name',
                hint: 'Jane Doe',
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _CustomerEditProfileField(
                label: 'Email',
                hint: 'jane@email.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 12),
              _CustomerEditProfileField(
                label: 'Phone Number',
                hint: '+961 03 123 456',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CustomerEditProfileField(
                      label: 'Country',
                      hint: 'Lebanon',
                      controller: _countryController,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CustomerEditProfileField(
                      label: 'City',
                      hint: 'Beirut',
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CustomerEditProfileField(
                label: 'Street Address',
                hint: 'Hamra St, Building 12',
                controller: _streetController,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: _hasChanges,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, _hasChanges ? 8 : 0, 18, 18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slideAnimation =
                    Tween<Offset>(
                      begin: const Offset(0, 0.28),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                        reverseCurve: Curves.easeInCubic,
                      ),
                    );
                final scaleAnimation = Tween<double>(begin: 0.94, end: 1)
                    .animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                        reverseCurve: Curves.easeInCubic,
                      ),
                    );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: ScaleTransition(scale: scaleAnimation, child: child),
                  ),
                );
              },
              child: _hasChanges
                  ? _buildSaveActionBar()
                  : const SizedBox.shrink(
                      key: ValueKey('customer-save-action-empty'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerProfilePhotoPicker extends StatelessWidget {
  const _CustomerProfilePhotoPicker({
    required this.photoBytes,
    this.avatarUrl,
    required this.onPickPhoto,
    required this.isPicking,
  });

  final Uint8List? photoBytes;
  final String? avatarUrl;
  final VoidCallback onPickPhoto;
  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    final normalizedAvatarUrl = avatarUrl?.trim();
    final hasAvatarUrl = _looksLikeHttpUrl(normalizedAvatarUrl);
    final hasPhoto = photoBytes != null && photoBytes!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEEA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2D5C8)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE7C7), Color(0xFFFFC79A)],
              ),
              border: Border.all(color: Colors.white, width: 2.4),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF8B5C41),
                        size: 30,
                      ),
                    )
                  : hasAvatarUrl
                  ? Image.network(
                      normalizedAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF8B5C41),
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF8B5C41),
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    color: Color(0xFF2D201A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto
                      ? 'Photo selected from your device.'
                      : 'Choose a photo from your phone.',
                  style: const TextStyle(
                    color: Color(0xFF77665A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: isPicking ? null : onPickPhoto,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7E4D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isPicking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Change',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerReadonlyProfileField extends StatelessWidget {
  const _CustomerReadonlyProfileField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF46372D),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8E3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2D5C8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6C5B4F),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF9F8D80),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerEditProfileField extends StatelessWidget {
  const _CustomerEditProfileField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF46372D),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEEA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2D5C8)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFC0B1A4),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF2D201A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

enum _ProfileSettingsDestination {
  editProfile,
  notifications,
  paymentMethods,
  privacySecurity,
  helpSupport,
}

class _ProfileSettingsItemData {
  const _ProfileSettingsItemData({
    required this.title,
    required this.icon,
    required this.destination,
  });

  final String title;
  final IconData icon;
  final _ProfileSettingsDestination destination;
}

class _CustomerPaymentMethodData {
  const _CustomerPaymentMethodData({
    required this.label,
    required this.details,
    required this.icon,
  });

  final String label;
  final String details;
  final IconData icon;
}

class _SupportFaqItemData {
  const _SupportFaqItemData({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.metrics,
    required this.selectedIndex,
    required this.onSelected,
    this.fullWidth = false,
    this.bottomInset = 0,
  });

  final _ResponsiveMetrics metrics;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool fullWidth;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.explore_rounded, label: 'Discover'),
      (icon: Icons.shopping_bag_rounded, label: 'Orders'),
      (icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];
    final navScale = metrics.navScaleFactor;
    final horizontalPadding = fullWidth
        ? _clampDouble((metrics.compact ? 10 : 14) * navScale, 4, 14)
        : _clampDouble((metrics.compact ? 6 : 10) * navScale, 3, 10);
    final verticalPadding = _clampDouble(
      (metrics.compact ? 6 : 8) * navScale,
      2,
      8,
    );
    final insetPadding = fullWidth ? bottomInset / 2 : 0;
    final topPadding = verticalPadding + insetPadding;
    final bottomPadding = verticalPadding + insetPadding;

    return Container(
      height: metrics.navHeight + (fullWidth ? bottomInset : 0),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: _BottomNavItem(
              icon: item.icon,
              label: item.label,
              selected: index == selectedIndex,
              metrics: metrics,
              onTap: () => onSelected(index),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFF7E4D) : const Color(0xFF9E8B7D);
    final navScale = metrics.navScaleFactor;
    return InkWell(
      borderRadius: BorderRadius.circular(_clampDouble(16 * navScale, 8, 16)),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: metrics.navIconSize),
          SizedBox(height: _clampDouble(6 * metrics.scale * navScale, 1.5, 6)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: metrics.navLabelSize,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
