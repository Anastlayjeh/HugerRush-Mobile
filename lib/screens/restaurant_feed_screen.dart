import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

import '../models/demo_app_models.dart';
import '../services/conversation_api_service.dart';
import '../services/demo_app_repository.dart';
import 'login_screen.dart';
import '../services/restaurant_menu_api_service.dart';
import '../services/restaurant_owner_api_service.dart';
import '../services/restaurant_profile_api_service.dart';
import '../services/support_report_api_service.dart';
import 'app_support_screens.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
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

enum _VideoHoldAction { none, pause, speed2x }

class RestaurantFeedScreen extends StatefulWidget {
  const RestaurantFeedScreen({
    super.key,
    required this.restaurantName,
    this.authToken,
    this.initialUserData,
    this.onLogout,
  });

  final String restaurantName;
  final String? authToken;
  final Map<String, dynamic>? initialUserData;
  final Future<void> Function()? onLogout;

  @override
  State<RestaurantFeedScreen> createState() => _RestaurantFeedScreenState();
}

class _RestaurantFeedScreenState extends State<RestaurantFeedScreen> {
  static const int _menuTabIndex = 1;
  static const int _dashboardTabIndex = 2;
  static const int _messagesTabIndex = 3;
  static const int _profileTabIndex = 4;
  static const int _profileMenuTabIndex = 1;
  static const List<_FeedVideoPostData> _feedVideos = [
    _FeedVideoPostData(
      videoAssetPath: 'assets/videos/home_video_1.mp4',
      postId: 'for-you',
    ),
    _FeedVideoPostData(
      videoAssetPath: 'assets/videos/home_video_2.mp4',
      postId: 'vendor-feed',
    ),
  ];
  static const String _sampleProfileVideoAssetPath =
      'assets/videos/home_video_2.mp4';

  final _profileScaffoldKey = GlobalKey<ScaffoldState>();
  final _demoRepository = DemoAppRepository.instance;
  final Map<String, DemoFeedPost> _feedPostsById = <String, DemoFeedPost>{};
  final Map<String, Offset> _lastDoubleTapOffsetsByPostId = <String, Offset>{};
  final List<_FeedLikeBurstData> _activeLikeBursts = <_FeedLikeBurstData>[];
  final Set<String> _pendingDoubleTapLikePostIds = <String>{};
  int _selectedBottomIndex = 0;
  int _selectedTopTab = 1;
  int _selectedProfileTabIndex = _profileMenuTabIndex;
  final _profileApiService = RestaurantProfileApiService();
  final _menuApiService = RestaurantMenuApiService();
  final _ownerApiService = RestaurantOwnerApiService();
  PlatformFile? _selectedPostVideo;
  bool _isPickingPostVideo = false;
  bool _isCreatingPost = false;
  final List<_UploadedRestaurantVideo> _uploadedVideos =
      <_UploadedRestaurantVideo>[];
  late final List<VideoPlayerController> _videoControllers;
  late final List<bool> _videoErrorLogged;
  int _currentVideoIndex = 0;
  int _videoPlaybackSyncVersion = 0;
  int _nextLikeBurstId = 0;
  bool _isVideoHoldActive = false;
  _VideoHoldAction _videoHoldAction = _VideoHoldAction.none;
  bool _isVideoManuallyPaused = false;

  late _RestaurantProfileInfo _profileInfo;
  bool _isRefreshingProfile = false;
  String? _profileSyncError;
  List<RestaurantMenuItem> _restaurantMenuItems = const [];
  bool _isRefreshingMenu = false;
  bool _hasLoadedMenu = false;
  String? _menuSyncError;
  List<OwnerOrder> _restaurantOrders = const <OwnerOrder>[];
  List<OwnerReview> _restaurantReviews = const <OwnerReview>[];
  RestaurantAnalyticsSnapshot? _analyticsSnapshot;
  bool _isRefreshingDashboard = false;
  bool _hasLoadedDashboard = false;
  String? _dashboardSyncError;

  @override
  void initState() {
    super.initState();
    _syncFeedPosts();
    _videoControllers = List<VideoPlayerController>.generate(
      _feedVideos.length,
      (index) => VideoPlayerController.asset(_feedVideos[index].videoAssetPath),
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
            'Restaurant feed video playback error for index $i: ${controller.value.errorDescription}',
          );
        }
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
            unawaited(_syncVideoPlayback());
          })
          .catchError((error) {
            debugPrint(
              'Restaurant feed video init failed for index $i: $error',
            );
          });
    }
    _profileInfo = _RestaurantProfileInfo.fromData(
      primary: widget.initialUserData,
      fallbackName: widget.restaurantName,
    );
    _addSampleProfileVideo();
    _refreshRestaurantProfile();
    _refreshRestaurantMenu();
    _refreshDashboardData();
  }

  @override
  void dispose() {
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    _profileApiService.dispose();
    _menuApiService.dispose();
    _ownerApiService.dispose();
    super.dispose();
  }

  Future<void> _refreshRestaurantProfile() async {
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      return;
    }

    setState(() {
      _isRefreshingProfile = true;
      _profileSyncError = null;
    });

    try {
      final payload = await _profileApiService.fetchProfile(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _profileInfo = _RestaurantProfileInfo.fromData(
          primary: payload,
          secondary: widget.initialUserData,
          fallbackName: widget.restaurantName,
          localProfileImagePath: _profileInfo.localProfileImagePath,
        );
        _isRefreshingProfile = false;
      });
    } on RestaurantProfileApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshingProfile = false;
        _profileSyncError = e.message;
      });
    }
  }

  String get _restaurantName => _profileInfo.name;

  bool get _isProfileTabSelected => _selectedBottomIndex == _profileTabIndex;
  bool get _isMenuTabSelected => _selectedBottomIndex == _menuTabIndex;
  bool get _isDashboardTabSelected =>
      _selectedBottomIndex == _dashboardTabIndex;
  bool get _isMessagesTabSelected => _selectedBottomIndex == _messagesTabIndex;
  List<RestaurantMenuItem> get _menuItemsForDisplay => _restaurantMenuItems;

  void _addSampleProfileVideo() {
    if (_uploadedVideos.isNotEmpty) {
      return;
    }
    _uploadedVideos.add(
      _UploadedRestaurantVideo(
        name: 'sample_promo.mp4',
        sizeBytes: 12400000,
        uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
        caption: 'Fresh out of the oven and ready for tonight.',
        hashtags: '#pizza #fresh #hugerush',
        videoAssetPath: _sampleProfileVideoAssetPath,
      ),
    );
  }

  DemoFeedPost get _activeFeedPost {
    final index = _currentVideoIndex.clamp(0, _feedVideos.length - 1);
    final video = _feedVideos[index];
    return _postForVideo(video);
  }

  DemoFeedPost _loadPostForId(String postId) {
    final post = postId == 'vendor-feed'
        ? _demoRepository.getFeedPost(following: true, vendorView: true)
        : _demoRepository.getFeedPost(following: false);
    return post;
  }

  void _syncFeedPosts() {
    for (final video in _feedVideos) {
      _feedPostsById[video.postId] = _loadPostForId(video.postId);
    }
  }

  DemoFeedPost _postForVideo(_FeedVideoPostData video) {
    return _feedPostsById[video.postId] ?? _loadPostForId(video.postId);
  }

  void _pauseFeedPlaybackForNavigation() {
    for (final controller in _videoControllers) {
      if (!controller.value.isInitialized) {
        continue;
      }
      controller.pause();
    }
  }

  Future<T?> _withFeedPlaybackPaused<T>(Future<T?> Function() action) async {
    final shouldPauseFeed = _selectedBottomIndex == 0;
    if (shouldPauseFeed) {
      _pauseFeedPlaybackForNavigation();
    }
    try {
      return await action();
    } finally {
      if (mounted && shouldPauseFeed && _selectedBottomIndex == 0) {
        unawaited(_syncVideoPlayback());
      }
    }
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

  Future<void> _openSearch() async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const SearchScreen(includeCustomers: false),
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotificationsScreen(authToken: widget.authToken),
        ),
      ),
    );
  }

  Future<void> _openRestaurantDetails([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    final videoPreviews = _uploadedVideos
        .map(
          (video) => RestaurantProfileVideoPreview(
            title: video.name,
            meta:
                '${_formatFileSize(video.sizeBytes)} - ${_timeAgoShort(video.uploadedAt)}',
          ),
        )
        .toList();
    final customerComments = _demoRepository
        .getComments(targetPost.id)
        .where((comment) => !comment.isRestaurantReply)
        .toList();
    final reviewPreviews = customerComments.asMap().entries.map((entry) {
      final index = entry.key;
      final comment = entry.value;
      final simulatedRating = (4.9 - (index * 0.15)).clamp(4.0, 5.0).toDouble();
      return RestaurantProfileReviewPreview(
        customerName: comment.authorName,
        rating: simulatedRating,
        comment: comment.body,
        timeLabel: _timeAgoShort(comment.createdAt),
        orderLabel: '#47${20 + index}',
      );
    }).toList();

    await _withFeedPlaybackPaused<void>(
      () => showRestaurantProfilePopup(
        context,
        restaurantName: targetPost.restaurantName,
        handle: targetPost.restaurantHandle,
        rating: targetPost.rating,
        caption: targetPost.caption,
        cuisineSummary: _profileInfo.cuisineSummary,
        phoneLabel: _profileInfo.phoneLabel,
        locationLabel: _profileInfo.locationLabel,
        followersCountLabel: _profileInfo.followersCountLabel,
        onOpenFollowers: () =>
            _openFollowersList(restaurantName: targetPost.restaurantName),
        profileImageUrl: _profileInfo.coverImageUrl,
        menuItems: _menuItemsForDisplay,
        uploadedVideos: videoPreviews,
        reviews: reviewPreviews,
      ),
    );
  }

  Future<void> _openUploadedVideo(_UploadedRestaurantVideo video) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _UploadedVideoPlayerScreen(
          video: video,
          profileInfo: _profileInfo,
          uploadedVideos: _uploadedVideos,
          menuItems: _menuItemsForDisplay,
          onOpenFollowers: () =>
              _openFollowersList(restaurantName: _profileInfo.name),
          onUpdateVideo: _updateUploadedVideo,
          onDeleteVideo: _deleteUploadedVideo,
        ),
      ),
    );
  }

  int _indexOfUploadedVideo(_UploadedRestaurantVideo target) {
    final identityIndex = _uploadedVideos.indexWhere(
      (item) => identical(item, target),
    );
    if (identityIndex >= 0) {
      return identityIndex;
    }
    return _uploadedVideos.indexWhere(
      (item) =>
          item.name == target.name &&
          item.sizeBytes == target.sizeBytes &&
          item.uploadedAt == target.uploadedAt &&
          item.videoFilePath == target.videoFilePath &&
          item.videoAssetPath == target.videoAssetPath,
    );
  }

  void _updateUploadedVideo(
    _UploadedRestaurantVideo original,
    _UploadedRestaurantVideo updated,
  ) {
    final index = _indexOfUploadedVideo(original);
    if (index < 0 || !mounted) {
      return;
    }
    setState(() {
      _uploadedVideos[index] = updated;
    });
  }

  void _deleteUploadedVideo(_UploadedRestaurantVideo target) {
    final index = _indexOfUploadedVideo(target);
    if (index < 0 || !mounted) {
      return;
    }
    setState(() {
      _uploadedVideos.removeAt(index);
    });
  }

  Future<void> _toggleVendorLike([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    final updated = await _demoRepository.toggleLike(targetPost.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _feedPostsById[targetPost.id] = updated;
    });
  }

  Future<void> _openVendorComments([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    await _withFeedPlaybackPaused<void>(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FeedCommentsBottomSheet(
          postId: targetPost.id,
          postTitle: targetPost.restaurantName,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _feedPostsById[targetPost.id] = _loadPostForId(targetPost.id);
    });
  }

  Future<void> _shareVendorPromo([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    await _withFeedPlaybackPaused<void>(
      () => showShareFallbackDialog(
        context,
        title: targetPost.restaurantName,
        body: targetPost.caption,
      ),
    );
  }

  Future<void> _openVendorPromoDetails([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PromoDetailsScreen(
            title: targetPost.restaurantName,
            caption: targetPost.caption,
            audioLabel: targetPost.audioLabel,
          ),
        ),
      ),
    );
  }

  Future<void> _openCompletedOrders() async {
    final orders = _demoOrdersFromOwnerOrders(completed: true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrderListScreen(title: 'Completed Orders', orders: orders),
      ),
    );
  }

  Future<void> _openRevenueAnalytics() async {
    final completedOrders =
        _analyticsSnapshot?.ordersToday ??
        _restaurantOrders.where((order) => order.completed).length;
    final revenueToday =
        _analyticsSnapshot?.revenueToday ??
        _restaurantOrders.fold<double>(
          0,
          (total, order) => total + order.total,
        );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RevenueAnalyticsScreen(
          revenueLabel: _formatUsd(revenueToday),
          completedOrders: completedOrders,
        ),
      ),
    );
  }

  Future<void> _openActiveOrders() async {
    final orders = _demoOrdersFromOwnerOrders(completed: false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrderListScreen(title: 'Orders In Progress', orders: orders),
      ),
    );
  }

  Future<void> _openOrderManagement() async {
    final orders = _demoOrdersFromOwnerOrders();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderManagementScreen(orders: orders),
      ),
    );
  }

  Future<void> _openOrderDetails(String orderId) async {
    DemoOrder? order;
    for (final item in _demoOrdersFromOwnerOrders()) {
      if (item.id == orderId ||
          item.id.replaceAll('#', '') == orderId.replaceAll('#', '')) {
        order = item;
        break;
      }
    }
    if (order == null) {
      return;
    }
    final selectedOrder = order;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(order: selectedOrder),
      ),
    );
  }

  void _openMenuItemDetails(RestaurantMenuItem item) {
    showRestaurantMenuItemDetailsPopup(context, item: item);
  }

  List<DemoOrder> _demoOrdersFromOwnerOrders({bool? completed}) {
    final realOrders = _restaurantOrders
        .where((order) => completed == null || order.completed == completed)
        .map((order) => order.toDemoOrder())
        .toList(growable: false);
    if (realOrders.isNotEmpty) {
      return realOrders;
    }
    return const <DemoOrder>[];
  }

  void _onBottomNavSelected(int index) {
    setState(() => _selectedBottomIndex = index);
    if (index == 0) {
      unawaited(_syncVideoPlayback());
    } else {
      _pauseAllFeedVideos();
    }
    if (index == _menuTabIndex || index == _dashboardTabIndex) {
      _refreshRestaurantMenu();
    }
    if (index == _dashboardTabIndex) {
      _refreshDashboardData();
    }
    if (index == _profileTabIndex && _selectedProfileTabIndex == 2) {
      _refreshRestaurantReviews();
    }
  }

  void _openMenuSection() {
    _onBottomNavSelected(_menuTabIndex);
    _refreshRestaurantMenu(force: true);
  }

  void _onProfileTabSelected(int index) {
    setState(() => _selectedProfileTabIndex = index);
    if (index == _profileMenuTabIndex) {
      _refreshRestaurantMenu();
    }
    if (index == 2) {
      _refreshRestaurantReviews();
    }
  }

  void _handleVideoPageChanged(int index) {
    _currentVideoIndex = index;
    _isVideoHoldActive = false;
    _videoHoldAction = _VideoHoldAction.none;
    _isVideoManuallyPaused = false;
    unawaited(
      _syncVideoPlayback(resetCurrentToStart: true, resetInactiveToStart: true),
    );
  }

  Future<void> _syncVideoPlayback({
    bool resetCurrentToStart = false,
    bool resetInactiveToStart = false,
  }) async {
    final syncVersion = ++_videoPlaybackSyncVersion;
    for (var i = 0; i < _videoControllers.length; i++) {
      if (!mounted || syncVersion != _videoPlaybackSyncVersion) {
        return;
      }
      final controller = _videoControllers[i];
      if (!controller.value.isInitialized) {
        continue;
      }
      final isCurrentVideo = i == _currentVideoIndex;
      final isSpeedHold =
          _isVideoHoldActive && _videoHoldAction == _VideoHoldAction.speed2x;
      await controller.pause();
      if (isCurrentVideo && resetCurrentToStart) {
        await controller.seekTo(Duration.zero);
      } else if (!isCurrentVideo && resetInactiveToStart) {
        await controller.seekTo(Duration.zero);
      }
      if (!mounted || syncVersion != _videoPlaybackSyncVersion) {
        return;
      }
      final shouldPlayCurrent =
          isCurrentVideo &&
          ((_isVideoHoldActive && isSpeedHold) ||
              (!_isVideoHoldActive && !_isVideoManuallyPaused));
      final targetSpeed = shouldPlayCurrent && isSpeedHold ? 2.0 : 1.0;
      if ((controller.value.playbackSpeed - targetSpeed).abs() > 0.01) {
        await controller.setPlaybackSpeed(targetSpeed);
      }
      if (shouldPlayCurrent) {
        await controller.play();
      }
    }
  }

  void _pauseAllFeedVideos() {
    _videoPlaybackSyncVersion++;
    _isVideoHoldActive = false;
    _videoHoldAction = _VideoHoldAction.none;
    _isVideoManuallyPaused = false;
    for (final controller in _videoControllers) {
      if (!controller.value.isInitialized) {
        continue;
      }
      if ((controller.value.playbackSpeed - 1.0).abs() > 0.01) {
        unawaited(controller.setPlaybackSpeed(1.0));
      }
      controller.pause();
    }
  }

  _VideoHoldAction _holdActionForPosition({
    required double localDx,
    required double surfaceWidth,
  }) {
    if (surfaceWidth <= 0) {
      return _VideoHoldAction.pause;
    }
    final sideWidth = surfaceWidth * 0.3;
    if (localDx <= sideWidth || localDx >= surfaceWidth - sideWidth) {
      return _VideoHoldAction.speed2x;
    }
    return _VideoHoldAction.pause;
  }

  void _handleVideoLongPressStart({
    required int index,
    required double localDx,
    required double surfaceWidth,
  }) {
    if (index != _currentVideoIndex || _isVideoHoldActive) {
      return;
    }
    final holdAction = _holdActionForPosition(
      localDx: localDx,
      surfaceWidth: surfaceWidth,
    );
    setState(() {
      _isVideoHoldActive = true;
      _videoHoldAction = holdAction;
    });
    final controller = _videoControllers[index];
    if (!controller.value.isInitialized) {
      return;
    }
    if (holdAction == _VideoHoldAction.speed2x) {
      if ((controller.value.playbackSpeed - 2.0).abs() > 0.01) {
        unawaited(controller.setPlaybackSpeed(2.0));
      }
      unawaited(controller.play());
      return;
    }
    controller.pause();
  }

  void _handleVideoLongPressEnd() {
    if (!_isVideoHoldActive) {
      return;
    }
    setState(() {
      _isVideoHoldActive = false;
      _videoHoldAction = _VideoHoldAction.none;
    });
    unawaited(_syncVideoPlayback());
  }

  void _toggleVideoTapPlayback(int index) {
    if (index != _currentVideoIndex || _isVideoHoldActive) {
      return;
    }
    final controller = _videoControllers[index];
    if (!controller.value.isInitialized) {
      return;
    }
    setState(() => _isVideoManuallyPaused = !_isVideoManuallyPaused);
    if (_isVideoManuallyPaused) {
      if ((controller.value.playbackSpeed - 1.0).abs() > 0.01) {
        unawaited(controller.setPlaybackSpeed(1.0));
      }
      unawaited(controller.pause());
      return;
    }
    unawaited(_syncVideoPlayback());
  }

  static String _timeAgoShort(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  Future<void> _openEditProfile() async {
    final updatedData = await Navigator.of(context).push<_EditableProfileData>(
      MaterialPageRoute<_EditableProfileData>(
        builder: (_) => _EditProfileScreen(
          initialData: _EditableProfileData.fromProfile(_profileInfo),
        ),
      ),
    );

    if (!mounted || updatedData == null) {
      return;
    }

    setState(() {
      _profileInfo = _profileInfo.copyWithEditable(updatedData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  Future<void> _openFollowersList({String? restaurantName}) async {
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to load followers.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FollowersListScreen(
          token: token,
          restaurantName: (restaurantName?.trim().isNotEmpty ?? false)
              ? restaurantName!.trim()
              : _restaurantName,
          restaurantId: _profileInfo.id,
          profileApiService: _profileApiService,
        ),
      ),
    );
  }

  void _openProfileSettingsDrawer() {
    _profileScaffoldKey.currentState?.openEndDrawer();
  }

  void _logoutToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _refreshRestaurantMenu({bool force = false}) async {
    if (_isRefreshingMenu) {
      return;
    }
    if (_hasLoadedMenu && !force) {
      return;
    }

    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      setState(() {
        _restaurantMenuItems = const <RestaurantMenuItem>[];
        _hasLoadedMenu = true;
        _isRefreshingMenu = false;
        _menuSyncError = 'Missing auth token. Please log in again.';
      });
      return;
    }

    setState(() {
      _isRefreshingMenu = true;
      _menuSyncError = null;
    });

    try {
      final items = await _menuApiService.fetchMenu(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantMenuItems = items;
        _hasLoadedMenu = true;
        _isRefreshingMenu = false;
        _menuSyncError = null;
      });
    } on RestaurantMenuApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantMenuItems = const <RestaurantMenuItem>[];
        _hasLoadedMenu = true;
        _isRefreshingMenu = false;
        _menuSyncError = e.message;
      });
    }
  }

  Future<void> _refreshDashboardData({bool force = false}) async {
    if (_isRefreshingDashboard) {
      return;
    }
    if (_hasLoadedDashboard && !force) {
      return;
    }
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      setState(() {
        _restaurantOrders = const <OwnerOrder>[];
        _restaurantReviews = const <OwnerReview>[];
        _analyticsSnapshot = null;
        _hasLoadedDashboard = true;
        _dashboardSyncError = 'Missing auth token. Please log in again.';
      });
      return;
    }

    setState(() {
      _isRefreshingDashboard = true;
      _dashboardSyncError = null;
    });
    try {
      final results = await Future.wait<Object>([
        _ownerApiService.fetchOrders(token: token),
        _ownerApiService.fetchAnalytics(token: token),
        _ownerApiService.fetchReviews(token: token),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantOrders = results[0] as List<OwnerOrder>;
        _analyticsSnapshot = results[1] as RestaurantAnalyticsSnapshot;
        _restaurantReviews = results[2] as List<OwnerReview>;
        _hasLoadedDashboard = true;
        _isRefreshingDashboard = false;
      });
    } on RestaurantOwnerApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshingDashboard = false;
        _hasLoadedDashboard = true;
        _dashboardSyncError = e.message;
      });
    }
  }

  Future<void> _refreshRestaurantReviews() async {
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      return;
    }
    try {
      final reviews = await _ownerApiService.fetchReviews(token: token);
      if (!mounted) {
        return;
      }
      setState(() => _restaurantReviews = reviews);
    } on RestaurantOwnerApiException {
      // The profile tab already has a dashboard-level retry surface.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfileTabSelected) {
      return _buildProfileScaffold();
    }
    if (_isMenuTabSelected) {
      return _buildMenuScaffold();
    }
    if (_isDashboardTabSelected) {
      return _buildDashboardScaffold();
    }
    if (_isMessagesTabSelected) {
      return _buildMessagesScaffold();
    }
    return _buildFeedScaffold();
  }

  Widget _buildFeedScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2230),
      body: LayoutBuilder(
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
                  itemCount: _feedVideos.length,
                  itemBuilder: (context, index) {
                    final video = _feedVideos[index];
                    final post = _postForVideo(video);
                    final itemSize = Size(
                      constraints.maxWidth,
                      safeHeight > 0 ? safeHeight : constraints.maxHeight,
                    );
                    final likeBursts = _likeBurstsForPost(post.id);
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _toggleVideoTapPlayback(index),
                      onLongPressStart: (details) => _handleVideoLongPressStart(
                        index: index,
                        localDx: details.localPosition.dx,
                        surfaceWidth: itemSize.width,
                      ),
                      onLongPressEnd: (_) => _handleVideoLongPressEnd(),
                      onDoubleTapDown: (details) =>
                          _rememberDoubleTapPosition(post.id, details),
                      onDoubleTap: () =>
                          _handleFeedDoubleTapLike(post, itemSize),
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
                                                    _openRestaurantDetails(
                                                      post,
                                                    ),
                                                onOpenAudio: () =>
                                                    _openVendorPromoDetails(
                                                      post,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(width: metrics.railGap),
                                            _ActionRail(
                                              metrics: metrics,
                                              post: post,
                                              onOpenRestaurant: () =>
                                                  _openRestaurantDetails(post),
                                              onToggleLike: () =>
                                                  _toggleVendorLike(post),
                                              onOpenComments: () =>
                                                  _openVendorComments(post),
                                              onShare: () =>
                                                  _shareVendorPromo(post),
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
                          ],
                          if (!_isVideoHoldActive && likeBursts.isNotEmpty)
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
                          if (!_isVideoHoldActive)
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
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomNavBar(
                  metrics: metrics,
                  selectedIndex: _selectedBottomIndex,
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
                          selectedTab: _selectedTopTab,
                          onTabSelected: (index) {
                            setState(() => _selectedTopTab = index);
                          },
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
      ),
    );
  }

  Widget _buildProfileScaffold() {
    return Scaffold(
      key: _profileScaffoldKey,
      backgroundColor: const Color(0xFFF8EFE8),
      endDrawer: _ProfileSettingsDrawer(
        restaurantName: _profileInfo.name,
        restaurantHandle: _profileInfo.handle,
        profileImagePath: _profileInfo.localProfileImagePath,
        onEditProfile: _openEditProfile,
        onManageMenu: _openMenuSection,
        onOpenFollowers: () =>
            _openFollowersList(restaurantName: _profileInfo.name),
        authToken: widget.authToken,
        onLogout: _logoutToLogin,
      ),
      body: LayoutBuilder(
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
                      metrics.topPadding,
                      metrics.horizontalPadding,
                      0,
                    ),
                    child: _ProfileSection(
                      metrics: metrics,
                      profileInfo: _profileInfo,
                      menuItems: _menuItemsForDisplay,
                      reviews: _restaurantReviews,
                      isSyncingProfile: _isRefreshingProfile,
                      profileSyncError: _profileSyncError,
                      onRetryProfileSync: _refreshRestaurantProfile,
                      onManageFullMenu: _openMenuSection,
                      onOpenMenuItemDetails: _openMenuItemDetails,
                      onOpenFollowers: _openFollowersList,
                      onOpenSettings: _openProfileSettingsDrawer,
                      selectedTabIndex: _selectedProfileTabIndex,
                      onTabSelected: _onProfileTabSelected,
                      uploadedVideos: _uploadedVideos,
                      onOpenUploadedVideo: _openUploadedVideo,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomNavBar(
                  metrics: metrics,
                  selectedIndex: _selectedBottomIndex,
                  onSelected: _onBottomNavSelected,
                  fullWidth: true,
                  bottomInset: navBarBottomInset,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      body: LayoutBuilder(
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
          final menuItems = _menuItemsForDisplay;
          final availableCount = menuItems
              .where((item) => item.isAvailable)
              .length;
          final popularCount = menuItems.where((item) => item.isPopular).length;
          final averagePrice = _computeAveragePrice(menuItems);

          return Stack(
            children: [
              Positioned.fill(
                bottom: navBarTotalHeight,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.horizontalPadding,
                      metrics.topPadding,
                      metrics.horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MenuScreenHeader(
                          metrics: metrics,
                          restaurantName: _restaurantName,
                          isRefreshing: _isRefreshingMenu,
                          onRefresh: () => _refreshRestaurantMenu(force: true),
                        ),
                        SizedBox(
                          height: _clampDouble(12 * metrics.scale, 8, 12),
                        ),
                        _MenuStatsRow(
                          metrics: metrics,
                          totalItems: menuItems.length,
                          availableItems: availableCount,
                          popularItems: popularCount,
                          averagePrice: averagePrice,
                        ),
                        SizedBox(
                          height: _clampDouble(12 * metrics.scale, 8, 12),
                        ),
                        Expanded(
                          child: _MenuSection(
                            metrics: metrics,
                            items: menuItems,
                            isLoading: _isRefreshingMenu,
                            errorMessage: _menuSyncError,
                            onRetry: () => _refreshRestaurantMenu(force: true),
                            onItemTap: _openMenuItemDetails,
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
                  selectedIndex: _selectedBottomIndex,
                  onSelected: _onBottomNavSelected,
                  fullWidth: true,
                  bottomInset: navBarBottomInset,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardScaffold() {
    final completedOrdersToday =
        _analyticsSnapshot?.ordersToday ??
        _restaurantOrders.where((order) => order.completed).length;
    final ordersInProgress =
        _analyticsSnapshot?.ordersInProgress ??
        _restaurantOrders.where((order) => !order.completed).length;
    final revenueToday =
        _analyticsSnapshot?.revenueToday ??
        _restaurantOrders.fold<double>(
          0,
          (total, order) => total + order.total,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      body: LayoutBuilder(
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
                      metrics.topPadding,
                      metrics.horizontalPadding,
                      0,
                    ),
                    child: _DashboardSection(
                      metrics: metrics,
                      restaurantName: _restaurantName,
                      isRefreshing: _isRefreshingDashboard,
                      errorMessage: _dashboardSyncError,
                      ordersCompletedToday: completedOrdersToday,
                      revenueToday: revenueToday,
                      ordersInProgress: ordersInProgress,
                      liveOrders: _demoOrdersFromOwnerOrders(completed: false),
                      selectedVideoName: _selectedPostVideo?.name,
                      selectedVideoSizeBytes: _selectedPostVideo?.size,
                      isPickingVideo: _isPickingPostVideo,
                      isCreatingPost: _isCreatingPost,
                      onSelectVideo: _pickPostVideo,
                      onClearVideo: _clearSelectedPostVideo,
                      onRefresh: () async {
                        await Future.wait([
                          _refreshRestaurantMenu(force: true),
                          _refreshDashboardData(force: true),
                        ]);
                      },
                      onCreatePost: _createVideoPost,
                      onOpenCompletedOrders: _openCompletedOrders,
                      onOpenRevenueAnalytics: _openRevenueAnalytics,
                      onOpenActiveOrders: _openActiveOrders,
                      onOpenOrderManagement: _openOrderManagement,
                      onOpenOrderDetails: _openOrderDetails,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomNavBar(
                  metrics: metrics,
                  selectedIndex: _selectedBottomIndex,
                  onSelected: _onBottomNavSelected,
                  fullWidth: true,
                  bottomInset: navBarBottomInset,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessagesScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      body: LayoutBuilder(
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
                      metrics.topPadding,
                      metrics.horizontalPadding,
                      0,
                    ),
                    child: _MessagesSection(
                      metrics: metrics,
                      restaurantName: _restaurantName,
                      authToken: widget.authToken,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomNavBar(
                  metrics: metrics,
                  selectedIndex: _selectedBottomIndex,
                  onSelected: _onBottomNavSelected,
                  fullWidth: true,
                  bottomInset: navBarBottomInset,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickPostVideo() async {
    if (_isPickingPostVideo) {
      return;
    }

    setState(() => _isPickingPostVideo = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (!mounted || picked == null || picked.files.isEmpty) {
        return;
      }
      setState(() {
        _selectedPostVideo = picked.files.first;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pick video right now. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingPostVideo = false);
      }
    }
  }

  void _clearSelectedPostVideo() {
    setState(() => _selectedPostVideo = null);
  }

  Future<void> _createVideoPost() async {
    if (_selectedPostVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a video before publishing your post.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedVideo = _selectedPostVideo!;
    FocusScope.of(context).unfocus();
    final composerResult = await Navigator.of(context)
        .push<_CreatePostComposerResult>(
          MaterialPageRoute(
            builder: (context) => _CreatePostComposerScreen(
              selectedVideoName: selectedVideo.name,
            ),
          ),
        );
    if (!mounted || composerResult == null) {
      return;
    }
    setState(() => _isCreatingPost = true);
    try {
      final created = await _demoRepository.createPost(
        fileName: selectedVideo.name,
        fileSizeBytes: selectedVideo.size,
        caption: composerResult.caption,
        hashtags: composerResult.hashtags,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedVideos.insert(
          0,
          _UploadedRestaurantVideo(
            name: created.fileName,
            sizeBytes: created.fileSizeBytes,
            uploadedAt: created.createdAt,
            caption: created.caption,
            hashtags: created.hashtags,
            videoFilePath: selectedVideo.path,
          ),
        );
        _selectedPostVideo = null;
        _selectedProfileTabIndex = 0;
        _isCreatingPost = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video post published. It is now visible in your profile videos.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreatingPost = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create the post right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double? _computeAveragePrice(List<RestaurantMenuItem> items) {
    final prices = items.map((item) => item.price).whereType<double>().toList();
    if (prices.isEmpty) {
      return null;
    }
    final sum = prices.fold<double>(0, (value, item) => value + item);
    return sum / prices.length;
  }
}

class _FeedVideoPostData {
  const _FeedVideoPostData({
    required this.videoAssetPath,
    required this.postId,
  });

  final String videoAssetPath;
  final String postId;
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

class _UploadedVideoPlayerScreen extends StatefulWidget {
  const _UploadedVideoPlayerScreen({
    required this.video,
    required this.profileInfo,
    required this.uploadedVideos,
    required this.menuItems,
    required this.onOpenFollowers,
    required this.onUpdateVideo,
    required this.onDeleteVideo,
  });

  final _UploadedRestaurantVideo video;
  final _RestaurantProfileInfo profileInfo;
  final List<_UploadedRestaurantVideo> uploadedVideos;
  final List<RestaurantMenuItem> menuItems;
  final VoidCallback onOpenFollowers;
  final void Function(
    _UploadedRestaurantVideo original,
    _UploadedRestaurantVideo updated,
  )
  onUpdateVideo;
  final ValueChanged<_UploadedRestaurantVideo> onDeleteVideo;

  @override
  State<_UploadedVideoPlayerScreen> createState() =>
      _UploadedVideoPlayerScreenState();
}

class _UploadedVideoPlayerScreenState
    extends State<_UploadedVideoPlayerScreen> {
  final _repository = DemoAppRepository.instance;
  VideoPlayerController? _controller;
  late _UploadedRestaurantVideo _videoData;
  late DemoFeedPost _socialPost;
  String? _loadError;
  bool _isInitialized = false;
  bool _isVideoHoldActive = false;
  _VideoHoldAction _videoHoldAction = _VideoHoldAction.none;
  bool _isVideoManuallyPaused = false;
  bool _isTogglingLike = false;

  @override
  void initState() {
    super.initState();
    _videoData = widget.video;
    _socialPost = _repository.getFeedPost(following: true, vendorView: true);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final filePath = _videoData.videoFilePath?.trim() ?? '';
    final assetPath = _videoData.videoAssetPath?.trim() ?? '';
    VideoPlayerController? controller;
    if (filePath.isNotEmpty) {
      final file = File(filePath);
      if (file.existsSync()) {
        controller = VideoPlayerController.file(file);
      } else if (assetPath.isEmpty) {
        setState(() {
          _loadError = 'Video file is no longer available on this device.';
        });
        return;
      }
    }
    controller ??= assetPath.isNotEmpty
        ? VideoPlayerController.asset(assetPath)
        : null;
    if (controller == null) {
      setState(() {
        _loadError =
            'Video source is missing. Upload again to view this video.';
      });
      return;
    }
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        return;
      }
      setState(() => _isInitialized = true);
      unawaited(_syncViewerPlayback());
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = 'Unable to play this video right now.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_isInitialized || _isVideoHoldActive) {
      return;
    }
    setState(() => _isVideoManuallyPaused = !_isVideoManuallyPaused);
    unawaited(_syncViewerPlayback());
  }

  double _parseRatingLabel(String value) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value);
    if (match == null) {
      return 4.7;
    }
    return double.tryParse(match.group(0) ?? '') ?? 4.7;
  }

  _VideoHoldAction _holdActionForPosition({
    required double localDx,
    required double surfaceWidth,
  }) {
    if (surfaceWidth <= 0) {
      return _VideoHoldAction.pause;
    }
    final safeWidth = surfaceWidth < 1 ? 1 : surfaceWidth;
    final normalizedDx = localDx.clamp(0.0, safeWidth);
    final middleStart = safeWidth * 0.33;
    final middleEnd = safeWidth * 0.67;
    if (normalizedDx >= middleStart && normalizedDx <= middleEnd) {
      return _VideoHoldAction.pause;
    }
    if (normalizedDx <= safeWidth * 0.2 || normalizedDx >= safeWidth * 0.8) {
      return _VideoHoldAction.speed2x;
    }
    return _VideoHoldAction.pause;
  }

  void _handleVideoLongPressStart({
    required double localDx,
    required double surfaceWidth,
  }) {
    final controller = _controller;
    if (controller == null || !_isInitialized || _isVideoHoldActive) {
      return;
    }
    final holdAction = _holdActionForPosition(
      localDx: localDx,
      surfaceWidth: surfaceWidth,
    );
    setState(() {
      _isVideoHoldActive = true;
      _videoHoldAction = holdAction;
    });
    if (holdAction == _VideoHoldAction.speed2x) {
      unawaited(controller.setPlaybackSpeed(2));
      if (!controller.value.isPlaying) {
        unawaited(controller.play());
      }
      return;
    }
    unawaited(controller.pause());
  }

  void _handleVideoLongPressEnd() {
    if (!_isVideoHoldActive) {
      return;
    }
    setState(() {
      _isVideoHoldActive = false;
      _videoHoldAction = _VideoHoldAction.none;
    });
    unawaited(_syncViewerPlayback());
  }

  Future<void> _syncViewerPlayback() async {
    final controller = _controller;
    if (controller == null || !_isInitialized) {
      return;
    }
    final isSpeedHold =
        _isVideoHoldActive && _videoHoldAction == _VideoHoldAction.speed2x;
    await controller.setPlaybackSpeed(isSpeedHold ? 2 : 1);
    final shouldPlay =
        (_isVideoHoldActive && isSpeedHold) ||
        (!_isVideoHoldActive && !_isVideoManuallyPaused);
    if (shouldPlay) {
      if (!controller.value.isPlaying) {
        await controller.play();
      }
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    }
  }

  void _openRestaurantDetails() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This is your profile.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _normalizeHashtags(String rawValue) {
    final normalized = <String>[];
    final seen = <String>{};
    final parts = rawValue.split(RegExp(r'[\s,]+'));
    for (final part in parts) {
      final cleaned = part.trim().replaceAll(RegExp(r'[^A-Za-z0-9_#]'), '');
      if (cleaned.isEmpty) {
        continue;
      }
      final withoutPrefix = cleaned.replaceAll('#', '');
      if (withoutPrefix.isEmpty) {
        continue;
      }
      final tag = '#$withoutPrefix';
      final key = tag.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      normalized.add(tag);
    }
    return normalized.join(' ');
  }

  Future<void> _openEditPostSheet() async {
    final captionController = TextEditingController(text: _videoData.caption);
    final hashtagsController = TextEditingController(text: _videoData.hashtags);
    try {
      final updated = await showModalBottomSheet<_UploadedRestaurantVideo>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF8EFE8),
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Post',
                    style: TextStyle(
                      color: Color(0xFF1F1B19),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: captionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Caption',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7E4D),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hashtagsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Hashtags',
                      hintText: '#pizza #fresh',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7E4D),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final caption = captionController.text.trim();
                        final hashtags = _normalizeHashtags(
                          hashtagsController.text,
                        );
                        if (caption.isEmpty || hashtags.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add both caption and hashtags.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.of(sheetContext).pop(
                          _videoData.copyWith(
                            caption: caption,
                            hashtags: hashtags,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7E4D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
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
      if (updated == null || !mounted) {
        return;
      }
      final original = _videoData;
      setState(() => _videoData = updated);
      widget.onUpdateVideo(original, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      captionController.dispose();
      hashtagsController.dispose();
    }
  }

  Future<void> _removePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Post'),
          content: const Text('Are you sure you want to remove this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB7372B),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    final deleted = _videoData;
    widget.onDeleteVideo(deleted);
    Navigator.of(context).pop();
  }

  Future<void> _openEditMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF8EFE8),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFFF7E4D),
                ),
                title: const Text('Edit Post'),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB7372B),
                ),
                title: const Text(
                  'Remove Post',
                  style: TextStyle(color: Color(0xFFB7372B)),
                ),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == 'edit') {
      await _openEditPostSheet();
      return;
    }
    if (action == 'remove') {
      await _removePost();
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) {
      return;
    }
    _isTogglingLike = true;
    try {
      final updated = await _repository.toggleLike(_socialPost.id);
      if (!mounted) {
        return;
      }
      setState(() => _socialPost = updated);
    } finally {
      _isTogglingLike = false;
    }
  }

  Future<void> _openComments() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedCommentsBottomSheet(
        postId: _socialPost.id,
        postTitle: _socialPost.restaurantName,
      ),
    );
    if (!mounted) {
      return;
    }
    final refreshed = _repository.findFeedPost(_socialPost.id);
    if (refreshed == null) {
      return;
    }
    setState(() => _socialPost = refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoReady = controller != null && _isInitialized;
    final postCaption = _videoData.caption.trim();
    final postHashtags = _videoData.hashtags.trim();
    final restaurantName = widget.profileInfo.name.trim().isEmpty
        ? 'Restaurant'
        : widget.profileInfo.name.trim();
    final restaurantHandle = widget.profileInfo.handle.trim().isEmpty
        ? restaurantName.toLowerCase().replaceAll(RegExp(r'\s+'), '')
        : widget.profileInfo.handle.trim();
    final caption = postCaption.isEmpty
        ? 'No caption was added for this post.'
        : postCaption;
    final hashtags = postHashtags.isEmpty ? '#hugerush' : postHashtags;
    final feedPost = _socialPost.copyWith(
      restaurantName: restaurantName,
      restaurantHandle: restaurantHandle,
      caption: caption,
      tags: hashtags,
      audioLabel: 'Original Audio - $restaurantName',
      rating: _parseRatingLabel(widget.profileInfo.ratingLabel),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A2230),
      body: LayoutBuilder(
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
          final topOverlayReservedHeight =
              metrics.topControlButtonSize + metrics.gapAfterTop;

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: navBarTotalHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _togglePlayback,
                  onLongPressStart: (details) => _handleVideoLongPressStart(
                    localDx: details.localPosition.dx,
                    surfaceWidth: constraints.maxWidth,
                  ),
                  onLongPressEnd: (_) => _handleVideoLongPressEnd(),
                  child: Stack(
                    children: [
                      if (videoReady)
                        Positioned.fill(
                          child: _FeedBackground(controller: controller),
                        )
                      else
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black),
                          ),
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0x09000000),
                                const Color(0x6B000000),
                                const Color(0xD100131A),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      if (!videoReady && _loadError == null)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF7E4D),
                          ),
                        ),
                      if (_loadError != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (videoReady && !_isVideoHoldActive)
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
                                            post: feedPost,
                                            metrics: metrics,
                                            onOpenRestaurant:
                                                _openRestaurantDetails,
                                            onOpenAudio: () {},
                                          ),
                                        ),
                                        SizedBox(width: metrics.railGap),
                                        _ActionRail(
                                          metrics: metrics,
                                          post: feedPost,
                                          onOpenRestaurant:
                                              _openRestaurantDetails,
                                          onToggleLike: _toggleLike,
                                          onOpenComments: _openComments,
                                          onShare: () {},
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
                      if (!_isVideoHoldActive)
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).pop(),
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x45000000),
                                        border: Border.all(
                                          color: const Color(0x2FFFFFFF),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _openEditMenu,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x45000000),
                                        border: Border.all(
                                          color: const Color(0x2FFFFFFF),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (videoReady && !_isVideoHoldActive)
                        Positioned(
                          left: _clampDouble(10 * metrics.scale, 8, 14),
                          right: _clampDouble(10 * metrics.scale, 8, 14),
                          bottom: _clampDouble(8 * metrics.scale, 6, 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: VideoProgressIndicator(
                              controller,
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
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomNavBar(
                  metrics: metrics,
                  selectedIndex: 4,
                  onSelected: (_) {},
                  fullWidth: true,
                  bottomInset: navBarBottomInset,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreatePostComposerResult {
  const _CreatePostComposerResult({
    required this.caption,
    required this.hashtags,
  });

  final String caption;
  final String hashtags;
}

class _CreatePostComposerScreen extends StatefulWidget {
  const _CreatePostComposerScreen({required this.selectedVideoName});

  final String selectedVideoName;

  @override
  State<_CreatePostComposerScreen> createState() =>
      _CreatePostComposerScreenState();
}

class _CreatePostComposerScreenState extends State<_CreatePostComposerScreen> {
  late final TextEditingController _captionController;
  late final TextEditingController _hashtagsController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _hashtagsController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  String _normalizeHashtags(String rawValue) {
    final normalized = <String>[];
    final seen = <String>{};
    final parts = rawValue.split(RegExp(r'[\s,]+'));
    for (final part in parts) {
      final cleaned = part.trim().replaceAll(RegExp(r'[^A-Za-z0-9_#]'), '');
      if (cleaned.isEmpty) {
        continue;
      }
      final withoutPrefix = cleaned.replaceAll('#', '');
      if (withoutPrefix.isEmpty) {
        continue;
      }
      final tag = '#$withoutPrefix';
      final key = tag.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      normalized.add(tag);
    }
    return normalized.join(' ');
  }

  void _submit() {
    final caption = _captionController.text.trim();
    final hashtags = _normalizeHashtags(_hashtagsController.text);
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a caption.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (hashtags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one hashtag.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(_CreatePostComposerResult(caption: caption, hashtags: hashtags));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EFE8),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1B19),
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedVideoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8D7E73),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Caption',
                    style: TextStyle(
                      color: Color(0xFF1F1B19),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a short caption for your post...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7E4D),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hashtags',
                    style: TextStyle(
                      color: Color(0xFF1F1B19),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hashtagsController,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '#pizza #burger #fresh',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7E4D),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7E4D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.metrics,
    required this.restaurantName,
    required this.isRefreshing,
    required this.errorMessage,
    required this.ordersCompletedToday,
    required this.revenueToday,
    required this.ordersInProgress,
    required this.liveOrders,
    required this.selectedVideoName,
    required this.selectedVideoSizeBytes,
    required this.isPickingVideo,
    required this.isCreatingPost,
    required this.onSelectVideo,
    required this.onClearVideo,
    required this.onRefresh,
    required this.onCreatePost,
    required this.onOpenCompletedOrders,
    required this.onOpenRevenueAnalytics,
    required this.onOpenActiveOrders,
    required this.onOpenOrderManagement,
    required this.onOpenOrderDetails,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final bool isRefreshing;
  final String? errorMessage;
  final int ordersCompletedToday;
  final double revenueToday;
  final int ordersInProgress;
  final List<DemoOrder> liveOrders;
  final String? selectedVideoName;
  final int? selectedVideoSizeBytes;
  final bool isPickingVideo;
  final bool isCreatingPost;
  final Future<void> Function() onSelectVideo;
  final VoidCallback onClearVideo;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreatePost;
  final Future<void> Function() onOpenCompletedOrders;
  final Future<void> Function() onOpenRevenueAnalytics;
  final Future<void> Function() onOpenActiveOrders;
  final Future<void> Function() onOpenOrderManagement;
  final Future<void> Function(String orderId) onOpenOrderDetails;

  @override
  Widget build(BuildContext context) {
    final sectionGap = _clampDouble(12 * metrics.scale, 8, 12);

    return RefreshIndicator(
      color: const Color(0xFFFF7E4D),
      onRefresh: onRefresh,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _DashboardHeaderCard(
            metrics: metrics,
            restaurantName: restaurantName,
            isRefreshing: isRefreshing,
            onRefresh: onRefresh,
          ),
          if (errorMessage != null) ...[
            SizedBox(height: sectionGap),
            _DashboardErrorBanner(
              metrics: metrics,
              message: errorMessage!,
              onRetry: onRefresh,
            ),
          ],
          SizedBox(height: sectionGap),
          _DashboardStatsPanel(
            metrics: metrics,
            ordersCompletedToday: ordersCompletedToday,
            revenueToday: revenueToday,
            ordersInProgress: ordersInProgress,
            onOpenCompletedOrders: onOpenCompletedOrders,
            onOpenRevenueAnalytics: onOpenRevenueAnalytics,
            onOpenActiveOrders: onOpenActiveOrders,
          ),
          SizedBox(height: sectionGap),
          _CreatePostPanel(
            metrics: metrics,
            selectedVideoName: selectedVideoName,
            selectedVideoSizeBytes: selectedVideoSizeBytes,
            isPickingVideo: isPickingVideo,
            isCreatingPost: isCreatingPost,
            onSelectVideo: onSelectVideo,
            onClearVideo: onClearVideo,
            onCreatePost: onCreatePost,
          ),
          SizedBox(height: sectionGap),
          _DashboardLiveOrdersPanel(
            metrics: metrics,
            ordersInProgress: ordersInProgress,
            orders: liveOrders,
            onOpenOrderManagement: onOpenOrderManagement,
            onOpenOrderDetails: onOpenOrderDetails,
          ),
          SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
        ],
      ),
    );
  }
}

class _DashboardHeaderCard extends StatelessWidget {
  const _DashboardHeaderCard({
    required this.metrics,
    required this.restaurantName,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final titleSize = _clampDouble(32 * metrics.scale, 22, 32) * 0.56;
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(24 * metrics.scale, 18, 24),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                    Text(
                      'Today at $restaurantName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8F7F73),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD9CC)),
                ),
                child: IconButton(
                  onPressed: isRefreshing ? null : () => onRefresh(),
                  icon: isRefreshing
                      ? SizedBox(
                          width: _clampDouble(18 * metrics.scale, 14, 18),
                          height: _clampDouble(18 * metrics.scale, 14, 18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF7E4D),
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: const Color(0xFFFF7E4D),
                          size: _clampDouble(22 * metrics.scale, 18, 22),
                        ),
                  tooltip: 'Refresh dashboard',
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(12 * metrics.scale, 10, 12),
              vertical: _clampDouble(9 * metrics.scale, 7, 9),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(18 * metrics.scale, 14, 18),
                ),
                SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                Expanded(
                  child: Text(
                    'Track daily flow and publish updates for your followers.',
                    style: TextStyle(
                      color: const Color(0xFF7D6D61),
                      fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                      fontWeight: FontWeight.w600,
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

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({
    required this.metrics,
    required this.message,
    required this.onRetry,
  });

  final _ResponsiveMetrics metrics;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 10, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFB7372B)),
          SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7E3B2E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DashboardStatsPanel extends StatelessWidget {
  const _DashboardStatsPanel({
    required this.metrics,
    required this.ordersCompletedToday,
    required this.revenueToday,
    required this.ordersInProgress,
    required this.onOpenCompletedOrders,
    required this.onOpenRevenueAnalytics,
    required this.onOpenActiveOrders,
  });

  final _ResponsiveMetrics metrics;
  final int ordersCompletedToday;
  final double revenueToday;
  final int ordersInProgress;
  final Future<void> Function() onOpenCompletedOrders;
  final Future<void> Function() onOpenRevenueAnalytics;
  final Future<void> Function() onOpenActiveOrders;

  @override
  Widget build(BuildContext context) {
    final itemGap = _clampDouble(8 * metrics.scale, 6, 8);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashboardStatCard(
                metrics: metrics,
                icon: Icons.task_alt_rounded,
                label: 'Orders Completed Today',
                value: '$ordersCompletedToday',
                iconColor: const Color(0xFF2E9B57),
                iconBackgroundColor: const Color(0xFFE1F5E8),
                onTap: onOpenCompletedOrders,
              ),
            ),
            SizedBox(width: itemGap),
            Expanded(
              child: _DashboardStatCard(
                metrics: metrics,
                icon: Icons.payments_rounded,
                label: 'Revenue Today',
                value: _formatUsd(revenueToday),
                iconColor: const Color(0xFFFF7E4D),
                iconBackgroundColor: const Color(0xFFFFEFE8),
                onTap: onOpenRevenueAnalytics,
              ),
            ),
          ],
        ),
        SizedBox(height: itemGap),
        _DashboardStatCard(
          metrics: metrics,
          icon: Icons.timelapse_rounded,
          label: 'Orders In Progress',
          value: '$ordersInProgress',
          iconColor: const Color(0xFF43739C),
          iconBackgroundColor: const Color(0xFFE8EFF7),
          onTap: onOpenActiveOrders,
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(
        _clampDouble(18 * metrics.scale, 14, 18),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(12 * metrics.scale, 10, 12),
          vertical: _clampDouble(10 * metrics.scale, 8, 10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0EC),
          borderRadius: BorderRadius.circular(
            _clampDouble(18 * metrics.scale, 14, 18),
          ),
          border: Border.all(color: const Color(0xFFE5DACF)),
        ),
        child: Row(
          children: [
            Container(
              width: _clampDouble(34 * metrics.scale, 28, 34),
              height: _clampDouble(34 * metrics.scale, 28, 34),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: _clampDouble(18 * metrics.scale, 14, 18),
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1F1B19),
                      fontSize: _clampDouble(18 * metrics.scale, 13, 18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8D7E73),
                      fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
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

class _CreatePostPanel extends StatelessWidget {
  const _CreatePostPanel({
    required this.metrics,
    required this.selectedVideoName,
    required this.selectedVideoSizeBytes,
    required this.isPickingVideo,
    required this.isCreatingPost,
    required this.onSelectVideo,
    required this.onClearVideo,
    required this.onCreatePost,
  });

  final _ResponsiveMetrics metrics;
  final String? selectedVideoName;
  final int? selectedVideoSizeBytes;
  final bool isPickingVideo;
  final bool isCreatingPost;
  final Future<void> Function() onSelectVideo;
  final VoidCallback onClearVideo;
  final Future<void> Function() onCreatePost;

  @override
  Widget build(BuildContext context) {
    final hasSelectedVideo =
        selectedVideoName != null && selectedVideoName!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 11, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(22 * metrics.scale, 16, 22),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: _clampDouble(34 * metrics.scale, 30, 34),
                height: _clampDouble(34 * metrics.scale, 30, 34),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEFE8),
                ),
                child: Icon(
                  Icons.video_call_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(20 * metrics.scale, 16, 20),
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Post',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Upload a short promo or kitchen update video.',
                      style: TextStyle(
                        color: const Color(0xFF8D7E73),
                        fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(12 * metrics.scale, 10, 12),
              vertical: _clampDouble(10 * metrics.scale, 8, 10),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0D4C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_file_rounded,
                      color: const Color(0xFFFF7E4D),
                      size: _clampDouble(18 * metrics.scale, 14, 18),
                    ),
                    SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                    Expanded(
                      child: Text(
                        hasSelectedVideo
                            ? selectedVideoName!
                            : 'No video selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasSelectedVideo
                              ? const Color(0xFF2A231E)
                              : const Color(0xFF9B8C81),
                          fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasSelectedVideo)
                      IconButton(
                        onPressed: isPickingVideo ? null : onClearVideo,
                        icon: Icon(
                          Icons.close_rounded,
                          color: const Color(0xFF9B8C81),
                          size: _clampDouble(18 * metrics.scale, 14, 18),
                        ),
                        tooltip: 'Remove video',
                      ),
                  ],
                ),
                if (hasSelectedVideo && selectedVideoSizeBytes != null)
                  Padding(
                    padding: EdgeInsets.only(
                      left: _clampDouble(26 * metrics.scale, 20, 26),
                    ),
                    child: Text(
                      _formatFileSize(selectedVideoSizeBytes!),
                      style: TextStyle(
                        color: const Color(0xFF8D7E73),
                        fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPickingVideo ? null : () => onSelectVideo(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7E4D),
                    side: const BorderSide(color: Color(0xFFFFC8B4)),
                    padding: EdgeInsets.symmetric(
                      vertical: _clampDouble(12 * metrics.scale, 10, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isPickingVideo
                      ? SizedBox(
                          width: _clampDouble(16 * metrics.scale, 13, 16),
                          height: _clampDouble(16 * metrics.scale, 13, 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF7E4D),
                          ),
                        )
                      : Icon(
                          Icons.video_library_rounded,
                          size: _clampDouble(18 * metrics.scale, 14, 18),
                        ),
                  label: Text(
                    isPickingVideo ? 'Picking...' : 'Upload Video',
                    style: TextStyle(
                      fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      hasSelectedVideo && !isPickingVideo && !isCreatingPost
                      ? onCreatePost
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE8DBD1),
                    disabledForegroundColor: const Color(0xFFA69488),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      vertical: _clampDouble(12 * metrics.scale, 10, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isCreatingPost
                      ? SizedBox(
                          width: _clampDouble(16 * metrics.scale, 13, 16),
                          height: _clampDouble(16 * metrics.scale, 13, 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.cloud_upload_rounded,
                          size: _clampDouble(18 * metrics.scale, 14, 18),
                        ),
                  label: Text(
                    isCreatingPost ? 'Creating...' : 'Create Post',
                    style: TextStyle(
                      fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardLiveOrdersPanel extends StatelessWidget {
  const _DashboardLiveOrdersPanel({
    required this.metrics,
    required this.ordersInProgress,
    required this.orders,
    required this.onOpenOrderManagement,
    required this.onOpenOrderDetails,
  });

  final _ResponsiveMetrics metrics;
  final int ordersInProgress;
  final List<DemoOrder> orders;
  final Future<void> Function() onOpenOrderManagement;
  final Future<void> Function(String orderId) onOpenOrderDetails;

  @override
  Widget build(BuildContext context) {
    final cardRadius = _clampDouble(22 * metrics.scale, 16, 22);
    final listGap = _clampDouble(8 * metrics.scale, 6, 8);
    final displayOrders = orders
        .map(
          (order) => _DashboardLiveOrderData(
            orderId: order.id,
            customerName: order.customerName,
            itemSummary: order.itemSummary,
            etaLabel: order.etaLabel,
            statusLabel: order.statusLabel,
            highlighted: order.highlighted,
          ),
        )
        .toList(growable: false);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: _clampDouble(metrics.height * 0.24, 160, 230),
      ),
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 11, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: _clampDouble(34 * metrics.scale, 30, 34),
                height: _clampDouble(34 * metrics.scale, 30, 34),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEFE8),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(20 * metrics.scale, 16, 20),
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Order Queue',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$ordersInProgress orders currently in progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8D7E73),
                        fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _clampDouble(10 * metrics.scale, 8, 10),
                  vertical: _clampDouble(5 * metrics.scale, 4, 5),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: const Color(0xFF2E9B57),
                    fontSize: _clampDouble(10 * metrics.scale, 8, 10),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          if (displayOrders.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 10, 14)),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EFE8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2D6CB)),
              ),
              child: const Text(
                'No active orders in the database right now.',
                style: TextStyle(
                  color: Color(0xFF7D6C60),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...List.generate(displayOrders.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == displayOrders.length - 1 ? 0 : listGap,
                ),
                child: _DashboardLiveOrderRow(
                  metrics: metrics,
                  data: displayOrders[index],
                  onTap: () => onOpenOrderDetails(displayOrders[index].orderId),
                ),
              );
            }),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => onOpenOrderManagement(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7E4D),
                backgroundColor: const Color(0xFFFFEFE8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: _clampDouble(11 * metrics.scale, 9, 11),
                ),
              ),
              icon: Icon(
                Icons.receipt_long_rounded,
                size: _clampDouble(18 * metrics.scale, 14, 18),
              ),
              label: Text(
                'Open Order Management',
                style: TextStyle(
                  fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLiveOrderRow extends StatelessWidget {
  const _DashboardLiveOrderRow({
    required this.metrics,
    required this.data,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final _DashboardLiveOrderData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = data.highlighted
        ? const Color(0xFFB95533)
        : const Color(0xFF7D6C60);
    final statusBackground = data.highlighted
        ? const Color(0xFFFFE8DE)
        : const Color(0xFFEDE5DE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(10 * metrics.scale, 8, 10),
          vertical: _clampDouble(9 * metrics.scale, 7, 9),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EFE8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: data.highlighted
                ? const Color(0xFFFFD8C9)
                : const Color(0xFFE2D6CB),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data.orderId,
                        style: TextStyle(
                          color: const Color(0xFF1F1B19),
                          fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                      Flexible(
                        child: Text(
                          data.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF7E7064),
                            fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _clampDouble(3 * metrics.scale, 2, 3)),
                  Text(
                    data.itemSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8D7E73),
                      fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.etaLabel,
                  style: TextStyle(
                    color: const Color(0xFF2A231E),
                    fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _clampDouble(8 * metrics.scale, 6, 8),
                    vertical: _clampDouble(3 * metrics.scale, 2, 3),
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: _clampDouble(10 * metrics.scale, 8, 10),
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

class _DashboardLiveOrderData {
  const _DashboardLiveOrderData({
    required this.orderId,
    required this.customerName,
    required this.itemSummary,
    required this.etaLabel,
    required this.statusLabel,
    required this.highlighted,
  });

  final String orderId;
  final String customerName;
  final String itemSummary;
  final String etaLabel;
  final String statusLabel;
  final bool highlighted;
}

class _MessagesSection extends StatefulWidget {
  const _MessagesSection({
    required this.metrics,
    required this.restaurantName,
    this.authToken,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final String? authToken;

  @override
  State<_MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<_MessagesSection> {
  final _repository = DemoAppRepository.instance;
  final _conversationApiService = ConversationApiService();

  List<DemoConversationThread> _threads = const <DemoConversationThread>[];
  MessageFilterType _selectedFilter = MessageFilterType.all;
  String? _selectedCustomerName;
  bool _needsReplyOnly = false;
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
      final token = widget.authToken?.trim() ?? '';
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
    if (_needsReplyOnly) {
      items = items.where((thread) => thread.needsReply);
    }
    if (_selectedCustomerName != null) {
      items = items.where(
        (thread) => thread.customerName == _selectedCustomerName,
      );
    }
    return items.toList();
  }

  void _selectFilter(MessageFilterType filter) {
    setState(() => _selectedFilter = filter);
  }

  void _toggleNeedsReplyOnly() {
    setState(() => _needsReplyOnly = !_needsReplyOnly);
  }

  void _selectCustomer(String? customerName) {
    setState(() {
      _selectedCustomerName = _selectedCustomerName == customerName
          ? null
          : customerName;
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
          restaurantName: widget.restaurantName,
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
    final unreadThreads = _threads.where((item) => item.unreadCount > 0).length;
    final needsReplyThreads = _threads.where((item) => item.needsReply).length;
    final priorityThreads = _threads.where((item) => item.priority).toList();
    final visibleThreads = _visibleThreads;

    return RefreshIndicator(
      color: const Color(0xFFFF7E4D),
      onRefresh: _loadThreads,
      child: _isLoading
          ? ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
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
                _MessagesHeaderCard(
                  metrics: widget.metrics,
                  restaurantName: widget.restaurantName,
                  unreadThreads: unreadThreads,
                  needsReplyThreads: needsReplyThreads,
                  needsReplySelected: _needsReplyOnly,
                  onSelectUnread: () => _selectFilter(MessageFilterType.unread),
                  onToggleNeedsReply: _toggleNeedsReplyOnly,
                ),
                SizedBox(
                  height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                ),
                _MessagesFilterRow(
                  metrics: widget.metrics,
                  selectedFilter: _selectedFilter,
                  onSelected: _selectFilter,
                ),
                if (priorityThreads.isNotEmpty) ...[
                  SizedBox(
                    height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                  ),
                  _PriorityInboxRow(
                    metrics: widget.metrics,
                    items: priorityThreads,
                    selectedCustomerName: _selectedCustomerName,
                    onSelectedCustomer: _selectCustomer,
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
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleThreads.length - 1
                            ? _clampDouble(6 * widget.metrics.scale, 4, 6)
                            : _clampDouble(10 * widget.metrics.scale, 8, 10),
                      ),
                      child: _MessageThreadCard(
                        metrics: widget.metrics,
                        thread: visibleThreads[index],
                        onOpenThread: () =>
                            _openConversation(visibleThreads[index]),
                        onReply: () => _openConversation(
                          visibleThreads[index],
                          openComposer: true,
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _MessagesHeaderCard extends StatelessWidget {
  const _MessagesHeaderCard({
    required this.metrics,
    required this.restaurantName,
    required this.unreadThreads,
    required this.needsReplyThreads,
    required this.needsReplySelected,
    required this.onSelectUnread,
    required this.onToggleNeedsReply,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final int unreadThreads;
  final int needsReplyThreads;
  final bool needsReplySelected;
  final VoidCallback onSelectUnread;
  final VoidCallback onToggleNeedsReply;

  @override
  Widget build(BuildContext context) {
    final titleSize = _clampDouble(32 * metrics.scale, 22, 32) * 0.56;
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);
    final labelSize = _clampDouble(12 * metrics.scale, 9, 12);
    final valueSize = _clampDouble(20 * metrics.scale, 14, 20);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(24 * metrics.scale, 18, 24),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                    Text(
                      'Stay on top of customer replies for $restaurantName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8F7F73),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: _clampDouble(42 * metrics.scale, 36, 42),
                height: _clampDouble(42 * metrics.scale, 36, 42),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD9CC)),
                ),
                child: Icon(
                  Icons.mark_chat_unread_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(22 * metrics.scale, 18, 22),
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
          Row(
            children: [
              Expanded(
                child: _MessageHeaderStat(
                  metrics: metrics,
                  icon: Icons.mark_chat_unread_rounded,
                  iconColor: const Color(0xFFFF7E4D),
                  iconBackground: const Color(0xFFFFEFE8),
                  label: 'Unread',
                  value: '$unreadThreads threads',
                  labelSize: labelSize,
                  valueSize: valueSize,
                  onTap: onSelectUnread,
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: _MessageHeaderStat(
                  metrics: metrics,
                  icon: Icons.reply_rounded,
                  iconColor: const Color(0xFF2E9B57),
                  iconBackground: const Color(0xFFE1F5E8),
                  label: 'Needs Reply',
                  value: '$needsReplyThreads now',
                  labelSize: labelSize,
                  valueSize: valueSize,
                  onTap: onToggleNeedsReply,
                  selected: needsReplySelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageHeaderStat extends StatelessWidget {
  const _MessageHeaderStat({
    required this.metrics,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueSize,
    required this.onTap,
    this.selected = false,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final double labelSize;
  final double valueSize;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(10 * metrics.scale, 8, 10),
          vertical: _clampDouble(9 * metrics.scale, 7, 9),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : const Color(0xFFF8EFE8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFD7C8) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: _clampDouble(32 * metrics.scale, 26, 32),
              height: _clampDouble(32 * metrics.scale, 26, 32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackground,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: _clampDouble(17 * metrics.scale, 13, 17),
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8D7E73),
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: _clampDouble(2 * metrics.scale, 1, 2)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF2A231E),
                      fontSize: valueSize * 0.72,
                      fontWeight: FontWeight.w800,
                    ),
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

class _MessagesFilterRow extends StatelessWidget {
  const _MessagesFilterRow({
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
            child: _MessageFilterChip(
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

class _MessageFilterChip extends StatelessWidget {
  const _MessageFilterChip({
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

class _PriorityInboxRow extends StatelessWidget {
  const _PriorityInboxRow({
    required this.metrics,
    required this.items,
    required this.selectedCustomerName,
    required this.onSelectedCustomer,
  });

  final _ResponsiveMetrics metrics;
  final List<DemoConversationThread> items;
  final String? selectedCustomerName;
  final ValueChanged<String?> onSelectedCustomer;

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
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1
                      ? 0
                      : _clampDouble(8 * metrics.scale, 6, 8),
                ),
                child: _PriorityThreadChip(
                  metrics: metrics,
                  item: item,
                  selected: selectedCustomerName == item.customerName,
                  onTap: () => onSelectedCustomer(item.customerName),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PriorityThreadChip extends StatelessWidget {
  const _PriorityThreadChip({
    required this.metrics,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final DemoConversationThread item;
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
                    _initials(item.customerName),
                    style: TextStyle(
                      color: const Color(0xFF9A3F1F),
                      fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (item.online)
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
              item.customerName,
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

class _MessageThreadCard extends StatelessWidget {
  const _MessageThreadCard({
    required this.metrics,
    required this.thread,
    required this.onOpenThread,
    required this.onReply,
  });

  final _ResponsiveMetrics metrics;
  final DemoConversationThread thread;
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
                        _initials(thread.customerName),
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
                              thread.customerName,
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
                _MessageMetaPill(
                  metrics: metrics,
                  icon: Icons.receipt_long_rounded,
                  label: thread.orderLabel,
                ),
                SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                _MessageMetaPill(
                  metrics: metrics,
                  icon: Icons.local_shipping_outlined,
                  label: thread.channelLabel,
                ),
                if (thread.priority) ...[
                  SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                  _MessageMetaPill(
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

class _MessageMetaPill extends StatelessWidget {
  const _MessageMetaPill({
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

class _UploadedRestaurantVideo {
  const _UploadedRestaurantVideo({
    required this.name,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.caption,
    required this.hashtags,
    this.videoFilePath,
    this.videoAssetPath,
  });

  final String name;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String caption;
  final String hashtags;
  final String? videoFilePath;
  final String? videoAssetPath;

  _UploadedRestaurantVideo copyWith({
    String? name,
    int? sizeBytes,
    DateTime? uploadedAt,
    String? caption,
    String? hashtags,
    String? videoFilePath,
    String? videoAssetPath,
  }) {
    return _UploadedRestaurantVideo(
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      videoFilePath: videoFilePath ?? this.videoFilePath,
      videoAssetPath: videoAssetPath ?? this.videoAssetPath,
    );
  }
}

class _RestaurantReviewData {
  const _RestaurantReviewData({
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.timeLabel,
    required this.orderLabel,
  });

  final String customerName;
  final double rating;
  final String comment;
  final String timeLabel;
  final String orderLabel;
}

class _FollowersListScreen extends StatefulWidget {
  const _FollowersListScreen({
    required this.token,
    required this.restaurantName,
    required this.profileApiService,
    this.restaurantId,
  });

  final String token;
  final String restaurantName;
  final String? restaurantId;
  final RestaurantProfileApiService profileApiService;

  @override
  State<_FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<_FollowersListScreen> {
  List<RestaurantFollower> _followers = const <RestaurantFollower>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final followers = await widget.profileApiService.fetchFollowers(
        token: widget.token,
        restaurantId: widget.restaurantId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _followers = followers;
        _isLoading = false;
      });
    } on RestaurantProfileApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load followers. Please try again.';
      });
    }
  }

  String _initials(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'U';
    }
    if (words.length == 1) {
      final first = words.first;
      return first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.restaurantName.trim().isEmpty
        ? 'Restaurant'
        : widget.restaurantName.trim();
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFF8EFE8),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB7372B),
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6E3A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadFollowers,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7E4D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_followers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No followers found for this page yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF73685D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        itemCount: _followers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final follower = _followers[index];
          final avatarUrl = follower.avatarUrl?.trim() ?? '';
          final secondary = follower.secondaryLabel;
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4D8CF)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8D8CA),
                backgroundImage: avatarUrl.isEmpty
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl.isEmpty
                    ? Text(
                        _initials(follower.name),
                        style: const TextStyle(
                          color: Color(0xFF4A3C31),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              title: Text(
                follower.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2D241F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: secondary == null
                  ? null
                  : Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A7A6E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.metrics,
    required this.profileInfo,
    required this.menuItems,
    required this.reviews,
    required this.isSyncingProfile,
    required this.profileSyncError,
    required this.onRetryProfileSync,
    required this.onManageFullMenu,
    required this.onOpenMenuItemDetails,
    required this.onOpenFollowers,
    required this.onOpenSettings,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.uploadedVideos,
    required this.onOpenUploadedVideo,
  });

  final _ResponsiveMetrics metrics;
  final _RestaurantProfileInfo profileInfo;
  final List<RestaurantMenuItem> menuItems;
  final List<OwnerReview> reviews;
  final bool isSyncingProfile;
  final String? profileSyncError;
  final VoidCallback onRetryProfileSync;
  final VoidCallback onManageFullMenu;
  final ValueChanged<RestaurantMenuItem> onOpenMenuItemDetails;
  final VoidCallback onOpenFollowers;
  final VoidCallback onOpenSettings;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final List<_UploadedRestaurantVideo> uploadedVideos;
  final ValueChanged<_UploadedRestaurantVideo> onOpenUploadedVideo;

  static const int _videosTabIndex = 0;
  static const int _reviewsTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    final sectionGap = _clampDouble(24 * metrics.scale, 16, 24);
    final sectionTitleSize = _clampDouble(36 * metrics.scale, 24, 36);
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);
    // Keep extra vertical room so the Popular Choices cards do not overflow
    // on smaller devices or when text scale is slightly increased.
    final popularCardHeight = _clampDouble(260 * metrics.scale, 214, 260);
    final itemGap = _clampDouble(12 * metrics.scale, 8, 12);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSyncingProfile || profileSyncError != null) ...[
            _ProfileSyncBanner(
              metrics: metrics,
              isLoading: isSyncingProfile,
              errorMessage: profileSyncError,
              onRetry: onRetryProfileSync,
            ),
            SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
          ],
          _OwnerProfileHero(
            metrics: metrics,
            profileInfo: profileInfo,
            onOpenFollowers: onOpenFollowers,
            onOpenSettings: onOpenSettings,
          ),
          SizedBox(height: sectionGap),
          _ProfileSectionTabs(
            metrics: metrics,
            selectedIndex: selectedTabIndex,
            onSelected: onTabSelected,
          ),
          SizedBox(height: sectionGap),
          if (selectedTabIndex == _videosTabIndex)
            ..._buildVideosTab(
              sectionGap: sectionGap,
              sectionTitleSize: sectionTitleSize,
            )
          else if (selectedTabIndex == _reviewsTabIndex)
            ..._buildReviewsTab(
              sectionGap: sectionGap,
              sectionTitleSize: sectionTitleSize,
            )
          else
            ..._buildMenuTab(
              sectionGap: sectionGap,
              sectionTitleSize: sectionTitleSize,
              subtitleSize: subtitleSize,
              popularCardHeight: popularCardHeight,
              itemGap: itemGap,
            ),
          SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
        ],
      ),
    );
  }

  List<Widget> _buildMenuTab({
    required double sectionGap,
    required double sectionTitleSize,
    required double subtitleSize,
    required double popularCardHeight,
    required double itemGap,
  }) {
    final popularItems = menuItems.isEmpty
        ? const <RestaurantMenuItem>[]
        : (menuItems.where((item) => item.isPopular).isEmpty
                  ? menuItems
                  : menuItems.where((item) => item.isPopular))
              .take(6)
              .toList(growable: false);
    return [
      Text(
        'Menu Highlights',
        style: TextStyle(
          color: const Color(0xFF1F1B19),
          fontSize: sectionTitleSize * 0.53,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: _clampDouble(10 * metrics.scale, 7, 10)),
      Text(
        'Pulled from your database menu',
        style: TextStyle(
          color: const Color(0xFF8E7E72),
          fontSize: subtitleSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
      if (popularItems.isEmpty)
        _ProfileTabEmptyState(
          metrics: metrics,
          icon: Icons.restaurant_menu_rounded,
          title: 'No Menu Items Yet',
          message:
              'Create menu items in Menu Management and they will appear here.',
        )
      else
        SizedBox(
          height: popularCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: popularItems.length,
            separatorBuilder: (_, index) => SizedBox(width: itemGap),
            itemBuilder: (context, index) {
              final menuItem = popularItems[index];
              return _PopularMenuCard(
                metrics: metrics,
                item: _PopularMenuItemData.fromMenuItem(menuItem),
                onTap: () => onOpenMenuItemDetails(menuItem),
              );
            },
          ),
        ),
      SizedBox(height: sectionGap),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onManageFullMenu,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFFF6D47),
            foregroundColor: Colors.white,
            minimumSize: Size(
              double.infinity,
              _clampDouble(58 * metrics.scale, 48, 58),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          icon: Icon(
            Icons.restaurant_menu_rounded,
            size: _clampDouble(23 * metrics.scale, 18, 23),
          ),
          label: Text(
            'View Full Menu',
            style: TextStyle(
              fontSize: _clampDouble(22 * metrics.scale, 16, 22) * 0.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildVideosTab({
    required double sectionGap,
    required double sectionTitleSize,
  }) {
    final titleFont = sectionTitleSize * 0.53;
    if (uploadedVideos.isEmpty) {
      return [
        _ProfileTabEmptyState(
          metrics: metrics,
          icon: Icons.video_library_rounded,
          title: 'No Videos Yet',
          message:
              'Upload videos from Dashboard > Create Post and they will appear here.',
        ),
      ];
    }

    return [
      Text(
        'Uploaded Videos',
        style: TextStyle(
          color: const Color(0xFF1F1B19),
          fontSize: titleFont,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: _clampDouble(10 * metrics.scale, 7, 10)),
      Text(
        '${uploadedVideos.length} video post${uploadedVideos.length == 1 ? '' : 's'} on your profile',
        style: TextStyle(
          color: const Color(0xFF8E7E72),
          fontSize: _clampDouble(15 * metrics.scale, 11, 15),
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(_clampDouble(10 * metrics.scale, 8, 10)),
        decoration: BoxDecoration(
          color: const Color(0xFFF3ECE4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4D8CA)),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: uploadedVideos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: _clampDouble(8 * metrics.scale, 6, 8),
            mainAxisSpacing: _clampDouble(8 * metrics.scale, 6, 8),
            childAspectRatio: metrics.tiny ? 0.68 : 0.74,
          ),
          itemBuilder: (context, index) {
            return _UploadedVideoGridTile(
              metrics: metrics,
              video: uploadedVideos[index],
              index: index,
              onTap: () => onOpenUploadedVideo(uploadedVideos[index]),
            );
          },
        ),
      ),
      SizedBox(height: sectionGap * 0.4),
    ];
  }

  List<Widget> _buildReviewsTab({
    required double sectionGap,
    required double sectionTitleSize,
  }) {
    final titleFont = sectionTitleSize * 0.53;
    final reviewCards = reviews
        .map(
          (review) => _RestaurantReviewData(
            customerName: review.customerName,
            rating: review.rating,
            comment: review.comment.isEmpty
                ? 'No written comment.'
                : review.comment,
            timeLabel: _formatRelativeTime(review.createdAt ?? DateTime.now()),
            orderLabel: review.orderLabel,
          ),
        )
        .toList(growable: false);
    final avgRating = reviewCards.isEmpty
        ? 0.0
        : reviewCards.fold<double>(
                0,
                (total, review) => total + review.rating,
              ) /
              reviewCards.length;

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              'Customer Reviews',
              style: TextStyle(
                color: const Color(0xFF1F1B19),
                fontSize: titleFont,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(10 * metrics.scale, 7, 10),
              vertical: _clampDouble(5 * metrics.scale, 4, 5),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1CC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFB07800),
                  size: _clampDouble(14 * metrics.scale, 11, 14),
                ),
                SizedBox(width: _clampDouble(4 * metrics.scale, 3, 4)),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: const Color(0xFFB07800),
                    fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
      if (reviewCards.isEmpty)
        _ProfileTabEmptyState(
          metrics: metrics,
          icon: Icons.reviews_rounded,
          title: 'No Reviews Yet',
          message: 'Customer reviews from the database will appear here.',
        )
      else
        ...List.generate(reviewCards.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == reviewCards.length - 1
                  ? 0
                  : _clampDouble(10 * metrics.scale, 8, 10),
            ),
            child: _ReviewCard(metrics: metrics, review: reviewCards[index]),
          );
        }),
      SizedBox(height: sectionGap * 0.4),
    ];
  }
}

class _ProfileTabEmptyState extends StatelessWidget {
  const _ProfileTabEmptyState({
    required this.metrics,
    required this.icon,
    required this.title,
    required this.message,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(16 * metrics.scale, 12, 16),
        vertical: _clampDouble(18 * metrics.scale, 14, 18),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        children: [
          Container(
            width: _clampDouble(52 * metrics.scale, 42, 52),
            height: _clampDouble(52 * metrics.scale, 42, 52),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEFE8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF7E4D),
              size: _clampDouble(26 * metrics.scale, 20, 26),
            ),
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF2A231E),
              fontSize: _clampDouble(18 * metrics.scale, 14, 18),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF8D7E73),
              fontSize: _clampDouble(13 * metrics.scale, 10, 13),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadedVideoGridTile extends StatelessWidget {
  const _UploadedVideoGridTile({
    required this.metrics,
    required this.video,
    required this.index,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final _UploadedRestaurantVideo video;
  final int index;
  final VoidCallback onTap;

  static String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(_clampDouble(7 * metrics.scale, 6, 7)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6DCCF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFE8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: const Color(0xFFFF7E4D),
                        size: _clampDouble(30 * metrics.scale, 22, 30),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xD9000000),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _clampDouble(9 * metrics.scale, 8, 9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
              Text(
                video.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1F1B19),
                  fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: _clampDouble(2 * metrics.scale, 1, 2)),
              Text(
                '${_formatFileSize(video.sizeBytes)} • ${_timeAgo(video.uploadedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF8D7E73),
                  fontSize: _clampDouble(9.5 * metrics.scale, 8, 9.5),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.metrics, required this.review});

  final _ResponsiveMetrics metrics;
  final _RestaurantReviewData review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(12 * metrics.scale, 10, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4D9CF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerName,
                  style: TextStyle(
                    color: const Color(0xFF1F1B19),
                    fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                review.timeLabel,
                style: TextStyle(
                  color: const Color(0xFF8D7E73),
                  fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: const Color(0xFFF5B826),
                size: _clampDouble(16 * metrics.scale, 13, 16),
              ),
              SizedBox(width: _clampDouble(4 * metrics.scale, 3, 4)),
              Text(
                review.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: const Color(0xFF7A5A00),
                  fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _clampDouble(7 * metrics.scale, 5, 7),
                  vertical: _clampDouble(3 * metrics.scale, 2, 3),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE8E1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  review.orderLabel,
                  style: TextStyle(
                    color: const Color(0xFF786658),
                    fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
          Text(
            review.comment,
            style: TextStyle(
              color: const Color(0xFF5D4E43),
              fontSize: _clampDouble(13 * metrics.scale, 10, 13),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuScreenHeader extends StatelessWidget {
  const _MenuScreenHeader({
    required this.metrics,
    required this.restaurantName,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final titleSize = _clampDouble(32 * metrics.scale, 22, 32) * 0.56;
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(24 * metrics.scale, 18, 24),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menu Section',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                    Text(
                      'Manage dishes for $restaurantName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8F7F73),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD9CC)),
                ),
                child: IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? SizedBox(
                          width: _clampDouble(18 * metrics.scale, 14, 18),
                          height: _clampDouble(18 * metrics.scale, 14, 18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF7E4D),
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: const Color(0xFFFF7E4D),
                          size: _clampDouble(22 * metrics.scale, 18, 22),
                        ),
                  tooltip: 'Refresh menu',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuStatsRow extends StatelessWidget {
  const _MenuStatsRow({
    required this.metrics,
    required this.totalItems,
    required this.availableItems,
    required this.popularItems,
    required this.averagePrice,
  });

  final _ResponsiveMetrics metrics;
  final int totalItems;
  final int availableItems;
  final int popularItems;
  final double? averagePrice;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (metrics.width - (metrics.horizontalPadding * 2) - 8) / 2;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MenuStatCard(
          metrics: metrics,
          width: cardWidth,
          icon: Icons.format_list_bulleted_rounded,
          label: 'Total Items',
          value: '$totalItems',
        ),
        _MenuStatCard(
          metrics: metrics,
          width: cardWidth,
          icon: Icons.check_circle_outline_rounded,
          label: 'Available',
          value: '$availableItems',
        ),
        _MenuStatCard(
          metrics: metrics,
          width: cardWidth,
          icon: Icons.local_fire_department_outlined,
          label: 'Popular',
          value: '$popularItems',
        ),
        _MenuStatCard(
          metrics: metrics,
          width: cardWidth,
          icon: Icons.payments_outlined,
          label: 'Avg Price',
          value: _formatUsd(averagePrice, fallback: '--'),
        ),
      ],
    );
  }
}

class _MenuStatCard extends StatelessWidget {
  const _MenuStatCard({
    required this.metrics,
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final _ResponsiveMetrics metrics;
  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(12 * metrics.scale, 10, 12),
        vertical: _clampDouble(10 * metrics.scale, 8, 10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(18 * metrics.scale, 14, 18),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Row(
        children: [
          Container(
            width: _clampDouble(32 * metrics.scale, 28, 32),
            height: _clampDouble(32 * metrics.scale, 28, 32),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEFE8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF7E4D),
              size: _clampDouble(18 * metrics.scale, 14, 18),
            ),
          ),
          SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1F1B19),
                    fontSize: _clampDouble(18 * metrics.scale, 13, 18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF8D7E73),
                    fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                    fontWeight: FontWeight.w600,
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

class _MenuSection extends StatefulWidget {
  const _MenuSection({
    required this.metrics,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onItemTap,
  });

  final _ResponsiveMetrics metrics;
  final List<RestaurantMenuItem> items;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<RestaurantMenuItem> onItemTap;

  @override
  State<_MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<_MenuSection> {
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

  @override
  void didUpdateWidget(covariant _MenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _allCategory;
    }
  }

  List<RestaurantMenuItem> _filterItems(List<RestaurantMenuItem> source) {
    if (_selectedCategory == _allCategory) {
      return source;
    }
    final normalized = _selectedCategory.toLowerCase();
    return source
        .where((item) => item.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorMessage != null && widget.errorMessage!.trim().isNotEmpty;
    final categories = _categories;
    final filteredItems = _filterItems(widget.items);

    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7E4D)),
      );
    }

    return Column(
      children: [
        if (hasError) ...[
          _MenuSyncBanner(
            metrics: widget.metrics,
            message: widget.errorMessage!.trim(),
            onRetry: widget.onRetry,
          ),
          SizedBox(height: _clampDouble(10 * widget.metrics.scale, 8, 10)),
        ],
        if (widget.items.isNotEmpty && categories.length > 1) ...[
          SizedBox(
            height: _clampDouble(34 * widget.metrics.scale, 32, 34),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (_, _) =>
                  SizedBox(width: _clampDouble(8 * widget.metrics.scale, 6, 8)),
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
                    fontSize: _clampDouble(12 * widget.metrics.scale, 10, 12),
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
          SizedBox(height: _clampDouble(10 * widget.metrics.scale, 8, 10)),
        ],
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF7E4D),
            onRefresh: widget.onRetry,
            child: widget.items.isEmpty
                ? _EmptyMenuState(metrics: widget.metrics)
                : filteredItems.isEmpty
                ? _EmptyMenuState(
                    metrics: widget.metrics,
                    title: 'No items in "$_selectedCategory"',
                    description: 'Try another category or pull to refresh.',
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => SizedBox(
                      height: _clampDouble(10 * widget.metrics.scale, 8, 10),
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _ManagedMenuItemCard(
                        metrics: widget.metrics,
                        item: item,
                        onTap: () => widget.onItemTap(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _MenuSyncBanner extends StatelessWidget {
  const _MenuSyncBanner({
    required this.metrics,
    required this.message,
    required this.onRetry,
  });

  final _ResponsiveMetrics metrics;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(12 * metrics.scale, 10, 12),
        vertical: _clampDouble(10 * metrics.scale, 8, 10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD3C5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFCE5A3E),
            size: _clampDouble(18 * metrics.scale, 14, 18),
          ),
          SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF8D4B39),
                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => onRetry(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF7E4D),
              padding: EdgeInsets.symmetric(
                horizontal: _clampDouble(8 * metrics.scale, 6, 8),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState({
    required this.metrics,
    this.title = 'No menu items found',
    this.description = 'Add dishes from your backend and pull to refresh.',
  });

  final _ResponsiveMetrics metrics;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: _clampDouble(80 * metrics.scale, 60, 80)),
        Center(
          child: Container(
            width: _clampDouble(78 * metrics.scale, 64, 78),
            height: _clampDouble(78 * metrics.scale, 64, 78),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEFE7),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: const Color(0xFFFF7E4D),
              size: _clampDouble(36 * metrics.scale, 28, 36),
            ),
          ),
        ),
        SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF2A231E),
            fontSize: _clampDouble(20 * metrics.scale, 15, 20),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF8D7E73),
            fontSize: _clampDouble(13 * metrics.scale, 10, 13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ManagedMenuItemCard extends StatelessWidget {
  const _ManagedMenuItemCard({
    required this.metrics,
    required this.item,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final RestaurantMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = _clampDouble(90 * metrics.scale, 72, 90);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          _clampDouble(22 * metrics.scale, 18, 22),
        ),
        child: Container(
          padding: EdgeInsets.all(_clampDouble(12 * metrics.scale, 10, 12)),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1ED),
            borderRadius: BorderRadius.circular(
              _clampDouble(22 * metrics.scale, 18, 22),
            ),
            border: Border.all(color: const Color(0xFFE4D9CF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: thumbnailSize,
                  height: thumbnailSize,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE7D9CC), Color(0xFFD9C8B8)],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.fastfood_rounded,
                            color: Color(0xFF816B5B),
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: _clampDouble(12 * metrics.scale, 8, 12)),
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
                        SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                        Text(
                          _formatUsd(item.price),
                          style: TextStyle(
                            color: const Color(0xFFFF7E4D),
                            fontSize: _clampDouble(16 * metrics.scale, 12, 16),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _clampDouble(5 * metrics.scale, 3, 5)),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8C7D71),
                        fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
                    Wrap(
                      spacing: _clampDouble(6 * metrics.scale, 4, 6),
                      runSpacing: _clampDouble(5 * metrics.scale, 3, 5),
                      children: [
                        _MenuBadge(
                          metrics: metrics,
                          label: item.category,
                          backgroundColor: const Color(0xFFEFE8E1),
                          textColor: const Color(0xFF786658),
                        ),
                        _MenuBadge(
                          metrics: metrics,
                          label: item.isAvailable ? 'Available' : 'Paused',
                          backgroundColor: item.isAvailable
                              ? const Color(0xFFE1F5E8)
                              : const Color(0xFFFDE4E2),
                          textColor: item.isAvailable
                              ? const Color(0xFF2E9B57)
                              : const Color(0xFFC6463E),
                        ),
                        if (item.isPopular)
                          _MenuBadge(
                            metrics: metrics,
                            label: 'Popular',
                            backgroundColor: const Color(0xFFE8EFF7),
                            textColor: const Color(0xFF43739C),
                          ),
                        if (item.rating != null)
                          _MenuBadge(
                            metrics: metrics,
                            label: '${item.rating!.toStringAsFixed(1)}*',
                            backgroundColor: const Color(0xFFFFF1CC),
                            textColor: const Color(0xFFB07800),
                          ),
                      ],
                    ),
                    if (item.ordersCount != null) ...[
                      SizedBox(height: _clampDouble(7 * metrics.scale, 5, 7)),
                      Text(
                        '${item.ordersCount} orders',
                        style: TextStyle(
                          color: const Color(0xFF9A8A7E),
                          fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _MenuBadge extends StatelessWidget {
  const _MenuBadge({
    required this.metrics,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final _ResponsiveMetrics metrics;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(8 * metrics.scale, 6, 8),
        vertical: _clampDouble(4 * metrics.scale, 3, 4),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: _clampDouble(11 * metrics.scale, 8, 11),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatUsd(double? value, {String fallback = '\$0.00'}) {
  if (value == null) {
    return fallback;
  }
  return '\$${value.toStringAsFixed(2)}';
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(1)} KB';
  }
  final megabytes = kilobytes / 1024;
  if (megabytes < 1024) {
    return '${megabytes.toStringAsFixed(1)} MB';
  }
  final gigabytes = megabytes / 1024;
  return '${gigabytes.toStringAsFixed(1)} GB';
}

class _ProfileSyncBanner extends StatelessWidget {
  const _ProfileSyncBanner({
    required this.metrics,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final _ResponsiveMetrics metrics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    final background = hasError
        ? const Color(0xFFFFF3EE)
        : const Color(0xFFEFF7F1);
    final borderColor = hasError
        ? const Color(0xFFFFD2C4)
        : const Color(0xFFCBE5D2);
    final message = isLoading
        ? 'Refreshing restaurant profile from database...'
        : (hasError
              ? errorMessage!.trim()
              : 'Restaurant profile data is up to date.');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(14 * metrics.scale, 10, 14),
        vertical: _clampDouble(10 * metrics.scale, 8, 10),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          _clampDouble(16 * metrics.scale, 12, 16),
        ),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: _clampDouble(17 * metrics.scale, 14, 17),
              height: _clampDouble(17 * metrics.scale, 14, 17),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2F8A4E),
              ),
            )
          else
            Icon(
              hasError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: hasError
                  ? const Color(0xFFCE5A3E)
                  : const Color(0xFF2F8A4E),
              size: _clampDouble(20 * metrics.scale, 16, 20),
            ),
          SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: hasError
                    ? const Color(0xFF8D4B39)
                    : const Color(0xFF2A6F3E),
                fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasError)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE16D4D),
                padding: EdgeInsets.symmetric(
                  horizontal: _clampDouble(8 * metrics.scale, 6, 8),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnerProfileHero extends StatelessWidget {
  const _OwnerProfileHero({
    required this.metrics,
    required this.profileInfo,
    required this.onOpenFollowers,
    required this.onOpenSettings,
  });

  final _ResponsiveMetrics metrics;
  final _RestaurantProfileInfo profileInfo;
  final VoidCallback onOpenFollowers;
  final VoidCallback onOpenSettings;

  static String _initials(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'HR';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final coverHeight = _clampDouble(220 * metrics.scale, 178, 220);
    final cardHeight = _clampDouble(286 * metrics.scale, 230, 286);
    final cardTop = coverHeight - _clampDouble(40 * metrics.scale, 30, 40);
    final avatarSize = _clampDouble(92 * metrics.scale, 72, 92);
    final totalHeight = cardTop + cardHeight;
    final avatarTop = cardTop - (avatarSize / 2);
    final localProfileImagePath =
        profileInfo.localProfileImagePath?.trim() ?? '';
    final hasLocalProfileImage =
        localProfileImagePath.isNotEmpty &&
        File(localProfileImagePath).existsSync();

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              _clampDouble(30 * metrics.scale, 24, 30),
            ),
            child: SizedBox(
              width: double.infinity,
              height: coverHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profileInfo.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF53C7D6),
                              Color(0xFF1F95A7),
                              Color(0xFF0D4C66),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x21000000),
                          Color(0x52000000),
                          Color(0x91000000),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _clampDouble(14 * metrics.scale, 10, 14),
                      _clampDouble(14 * metrics.scale, 10, 14),
                      _clampDouble(14 * metrics.scale, 10, 14),
                      _clampDouble(12 * metrics.scale, 8, 12),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        _ProfileTopOverlayButton(
                          metrics: metrics,
                          icon: Icons.menu_rounded,
                          onTap: onOpenSettings,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: cardTop,
            left: 0,
            right: 0,
            child: Container(
              height: cardHeight,
              padding: EdgeInsets.fromLTRB(
                _clampDouble(16 * metrics.scale, 12, 16),
                (avatarSize / 2) + _clampDouble(12 * metrics.scale, 8, 12),
                _clampDouble(16 * metrics.scale, 12, 16),
                _clampDouble(16 * metrics.scale, 12, 16),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0EC),
                borderRadius: BorderRadius.circular(
                  _clampDouble(30 * metrics.scale, 24, 30),
                ),
                border: Border.all(color: const Color(0xFFE6DBD0)),
              ),
              child: Column(
                children: [
                  Text(
                    profileInfo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1F1B19),
                      fontSize: _clampDouble(42 * metrics.scale, 30, 42) * 0.58,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _clampDouble(8 * metrics.scale, 5, 8)),
                  Text(
                    profileInfo.cuisineSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8F7F73),
                      fontSize: _clampDouble(15 * metrics.scale, 11, 15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: _clampDouble(14 * metrics.scale, 9, 14),
                    runSpacing: _clampDouble(8 * metrics.scale, 5, 8),
                    children: [
                      _HeroMetaItem(
                        metrics: metrics,
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF5B826),
                        label: profileInfo.ratingLabel,
                      ),
                      _HeroMetaItem(
                        metrics: metrics,
                        icon: Icons.call_rounded,
                        iconColor: const Color(0xFFFF7E4D),
                        label: profileInfo.phoneLabel,
                      ),
                      _HeroMetaItem(
                        metrics: metrics,
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF23A455),
                        label: profileInfo.locationLabel,
                      ),
                    ],
                  ),
                  SizedBox(height: _clampDouble(16 * metrics.scale, 10, 16)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: _clampDouble(7 * metrics.scale, 5, 7),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5D9CE)),
                    ),
                    child: Center(
                      child: _ProfileConnectionMetric(
                        metrics: metrics,
                        value: profileInfo.followersCountLabel,
                        label: 'Followers',
                        onTap: onOpenFollowers,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: avatarTop,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F5A3C),
                  border: Border.all(color: const Color(0xFFF3F0EC), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: hasLocalProfileImage
                    ? ClipOval(
                        child: SizedBox(
                          width: avatarSize,
                          height: avatarSize,
                          child: Image.file(
                            File(localProfileImagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const ColoredBox(
                                color: Color(0xFF0F5A3C),
                                child: Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _initials(profileInfo.name),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  _clampDouble(26 * metrics.scale, 18, 26) *
                                  0.55,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(
                            height: _clampDouble(2 * metrics.scale, 1, 2),
                          ),
                          Text(
                            '@${profileInfo.handle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xE0FFFFFF),
                              fontSize:
                                  _clampDouble(11 * metrics.scale, 8, 11) * 0.7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopOverlayButton extends StatelessWidget {
  const _ProfileTopOverlayButton({
    required this.metrics,
    required this.icon,
    this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = _clampDouble(44 * metrics.scale, 36, 44);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFFFFF),
            border: Border.all(color: const Color(0xFF121212)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF121212),
            size: _clampDouble(24 * metrics.scale, 18, 24),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsDrawer extends StatelessWidget {
  const _ProfileSettingsDrawer({
    required this.restaurantName,
    required this.restaurantHandle,
    this.profileImagePath,
    required this.onEditProfile,
    required this.onManageMenu,
    required this.onOpenFollowers,
    this.authToken,
    required this.onLogout,
  });

  final String restaurantName;
  final String restaurantHandle;
  final String? profileImagePath;
  final VoidCallback onEditProfile;
  final VoidCallback onManageMenu;
  final VoidCallback onOpenFollowers;
  final String? authToken;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final normalizedName = restaurantName.trim();
    final displayName = normalizedName.isEmpty
        ? 'Restaurant Owner'
        : normalizedName;
    final normalizedHandle = restaurantHandle.trim();
    final subtitle = normalizedHandle.isEmpty
        ? 'Business shortcuts and account tools'
        : '@$normalizedHandle - Business shortcuts and account tools';
    final normalizedProfilePath = profileImagePath?.trim() ?? '';
    final hasProfileImage =
        normalizedProfilePath.isNotEmpty &&
        File(normalizedProfilePath).existsSync();

    final settingsItems = <_ProfileSettingsItemData>[
      _ProfileSettingsItemData(
        title: 'Edit Profile',
        icon: Icons.edit_rounded,
        onTap: () {
          Navigator.of(context).pop();
          onEditProfile();
        },
      ),
      _ProfileSettingsItemData(
        title: 'Manage Menu',
        icon: Icons.restaurant_menu_rounded,
        onTap: () {
          Navigator.of(context).pop();
          onManageMenu();
        },
      ),
      _ProfileSettingsItemData(
        title: 'Followers',
        icon: Icons.groups_rounded,
        onTap: () {
          Navigator.of(context).pop();
          onOpenFollowers();
        },
      ),
      _ProfileSettingsItemData(
        title: 'Help & Support',
        icon: Icons.help_outline_rounded,
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  _RestaurantHelpSupportScreen(authToken: authToken),
            ),
          );
        },
      ),
    ];

    return Drawer(
      backgroundColor: const Color(0xFFF8EFE5),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ResponsiveMetrics.from(constraints);
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
                            child: hasProfileImage
                                ? Image.file(
                                    File(normalizedProfilePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) =>
                                        Icon(
                                          Icons.storefront_rounded,
                                          color: const Color(0xFF8B5C41),
                                          size: _clampDouble(
                                            28 * metrics.scale,
                                            22,
                                            28,
                                          ),
                                        ),
                                  )
                                : Icon(
                                    Icons.storefront_rounded,
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
                                subtitle,
                                maxLines: 2,
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
                    'Business Settings',
                    style: TextStyle(
                      color: const Color(0xFF231A16),
                      fontSize: _clampDouble(20 * metrics.scale, 17, 20),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _clampDouble(12 * metrics.scale, 10, 12)),
                  _ProfilePanel(
                    child: Column(
                      children: List.generate(settingsItems.length, (index) {
                        final item = settingsItems[index];
                        return Column(
                          children: [
                            _ProfileSettingsTile(
                              data: item,
                              metrics: metrics,
                              onTap: item.onTap,
                            ),
                            if (index != settingsItems.length - 1)
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
                      onPressed: () {
                        Navigator.of(context).pop();
                        onLogout();
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

class _ProfileSettingsItemData {
  const _ProfileSettingsItemData({
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
}

class _RestaurantHelpSupportScreen extends StatefulWidget {
  const _RestaurantHelpSupportScreen({this.authToken});

  final String? authToken;

  @override
  State<_RestaurantHelpSupportScreen> createState() =>
      _RestaurantHelpSupportScreenState();
}

class _RestaurantHelpSupportScreenState
    extends State<_RestaurantHelpSupportScreen> {
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
                            subject: 'Restaurant support via $channel',
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

class _SupportFaqItemData {
  const _SupportFaqItemData({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _EditableProfileData {
  const _EditableProfileData({
    required this.restaurantName,
    required this.cuisineType,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.street,
    required this.postalCode,
    required this.localProfileImagePath,
  });

  final String restaurantName;
  final String cuisineType;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String street;
  final String postalCode;
  final String localProfileImagePath;

  factory _EditableProfileData.fromProfile(_RestaurantProfileInfo profile) {
    return _EditableProfileData(
      restaurantName: profile.name,
      cuisineType: profile.cuisine ?? '',
      email: profile.email ?? '',
      phone: profile.phone ?? '',
      country: profile.country ?? '',
      city: profile.city ?? '',
      street: profile.street ?? '',
      postalCode: profile.postalCode ?? '',
      localProfileImagePath: profile.localProfileImagePath ?? '',
    );
  }

  bool matches(_EditableProfileData other) {
    return _normalized(restaurantName) == _normalized(other.restaurantName) &&
        _normalized(cuisineType) == _normalized(other.cuisineType) &&
        _normalized(email) == _normalized(other.email) &&
        _normalized(phone) == _normalized(other.phone) &&
        _normalized(country) == _normalized(other.country) &&
        _normalized(city) == _normalized(other.city) &&
        _normalized(street) == _normalized(other.street) &&
        _normalized(postalCode) == _normalized(other.postalCode) &&
        _normalized(localProfileImagePath) ==
            _normalized(other.localProfileImagePath);
  }

  String _normalized(String value) => value.trim();
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({required this.initialData});

  final _EditableProfileData initialData;

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _restaurantNameController;
  late final TextEditingController _cuisineTypeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final TextEditingController _streetController;
  late final TextEditingController _postalCodeController;
  late String _localProfileImagePath;
  bool _isPickingProfilePhoto = false;
  bool _hasChanges = false;

  List<TextEditingController> get _controllers => [
    _restaurantNameController,
    _cuisineTypeController,
    _emailController,
    _phoneController,
    _countryController,
    _cityController,
    _streetController,
    _postalCodeController,
  ];

  _EditableProfileData get _currentData => _EditableProfileData(
    restaurantName: _restaurantNameController.text.trim(),
    cuisineType: _cuisineTypeController.text.trim(),
    email: _emailController.text.trim(),
    phone: _phoneController.text.trim(),
    country: _countryController.text.trim(),
    city: _cityController.text.trim(),
    street: _streetController.text.trim(),
    postalCode: _postalCodeController.text.trim(),
    localProfileImagePath: _localProfileImagePath.trim(),
  );

  @override
  void initState() {
    super.initState();
    _restaurantNameController = TextEditingController(
      text: widget.initialData.restaurantName,
    );
    _cuisineTypeController = TextEditingController(
      text: widget.initialData.cuisineType,
    );
    _emailController = TextEditingController(text: widget.initialData.email);
    _phoneController = TextEditingController(text: widget.initialData.phone);
    _countryController = TextEditingController(
      text: widget.initialData.country,
    );
    _cityController = TextEditingController(text: widget.initialData.city);
    _streetController = TextEditingController(text: widget.initialData.street);
    _postalCodeController = TextEditingController(
      text: widget.initialData.postalCode,
    );
    _localProfileImagePath = widget.initialData.localProfileImagePath;

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
      );
      if (!mounted || picked == null || picked.files.isEmpty) {
        return;
      }
      final path = picked.files.first.path?.trim();
      if (path == null || path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access the selected image file.'),
            backgroundColor: Color(0xFFB7372B),
          ),
        );
        return;
      }
      setState(() {
        _localProfileImagePath = path;
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

    if (data.restaurantName.isEmpty ||
        data.cuisineType.isEmpty ||
        data.email.isEmpty ||
        data.phone.isEmpty ||
        data.country.isEmpty ||
        data.city.isEmpty ||
        data.street.isEmpty ||
        data.postalCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
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
      key: const ValueKey('save-action-bar'),
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
              _EditProfilePhotoPicker(
                imagePath: _localProfileImagePath,
                onPickPhoto: _pickProfilePhoto,
                isPicking: _isPickingProfilePhoto,
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Restaurant Name',
                hint: 'The Pizza Hub',
                controller: _restaurantNameController,
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Cuisine Type',
                hint: 'Italian',
                controller: _cuisineTypeController,
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Email',
                hint: 'contact@restaurant.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Phone Number',
                hint: '+961 03 123 456',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EditProfileField(
                      label: 'Country',
                      hint: 'Lebanon',
                      controller: _countryController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EditProfileField(
                      label: 'City',
                      hint: 'Beirut',
                      controller: _cityController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Street',
                hint: 'Hamra St, Bldg 42',
                controller: _streetController,
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Postal Code',
                hint: '1103',
                keyboardType: TextInputType.number,
                controller: _postalCodeController,
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
                  : const SizedBox.shrink(key: ValueKey('save-action-empty')),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfilePhotoPicker extends StatelessWidget {
  const _EditProfilePhotoPicker({
    required this.imagePath,
    required this.onPickPhoto,
    required this.isPicking,
  });

  final String imagePath;
  final VoidCallback onPickPhoto;
  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    final normalizedPath = imagePath.trim();
    final hasPhoto =
        normalizedPath.isNotEmpty && File(normalizedPath).existsSync();
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
                  ? Image.file(
                      File(normalizedPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF8B5C41),
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
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

class _EditProfileField extends StatelessWidget {
  const _EditProfileField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;

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

class _HeroMetaItem extends StatelessWidget {
  const _HeroMetaItem({
    required this.metrics,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: _clampDouble(20 * metrics.scale, 14, 20) * 0.82,
        ),
        SizedBox(width: _clampDouble(5 * metrics.scale, 3, 5)),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _clampDouble(140 * metrics.scale, 92, 140),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF2D241F),
              fontSize: _clampDouble(14 * metrics.scale, 10, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileConnectionMetric extends StatelessWidget {
  const _ProfileConnectionMetric({
    required this.metrics,
    required this.value,
    required this.label,
    this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF201A16),
            fontSize: _clampDouble(18 * metrics.scale, 13, 18),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: _clampDouble(3 * metrics.scale, 1, 3)),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF7C6E61),
            fontSize: _clampDouble(12 * metrics.scale, 9, 12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(8 * metrics.scale, 6, 8),
            vertical: _clampDouble(2 * metrics.scale, 1, 2),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _ProfileSectionTabs extends StatelessWidget {
  const _ProfileSectionTabs({
    required this.metrics,
    required this.selectedIndex,
    required this.onSelected,
  });

  final _ResponsiveMetrics metrics;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _tabs = ['Videos', 'Menu', 'Reviews'];

  @override
  Widget build(BuildContext context) {
    final textSize = _clampDouble(28 * metrics.scale, 20, 28) * 0.56;
    return Column(
      children: [
        Row(
          children: List.generate(_tabs.length, (index) {
            final selected = index == selectedIndex;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: _clampDouble(6 * metrics.scale, 4, 6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _tabs[index],
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFFF7E4D)
                                : const Color(0xFF6D7485),
                            fontSize: textSize,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: _clampDouble(8 * metrics.scale, 5, 8)),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          width: _clampDouble(66 * metrics.scale, 48, 66),
                          height: _clampDouble(3.6 * metrics.scale, 2.4, 3.6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFF7E4D)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Divider(height: 1, thickness: 1, color: const Color(0xFFD9D2CB)),
      ],
    );
  }
}

class _PopularMenuCard extends StatelessWidget {
  const _PopularMenuCard({
    required this.metrics,
    required this.item,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final _PopularMenuItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _clampDouble(198 * metrics.scale, 156, 198);
    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.all(_clampDouble(12 * metrics.scale, 9, 12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1ED),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4D9CF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _clampDouble(120 * metrics.scale, 98, 120),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox.expand(
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF3C1A8),
                                      Color(0xFFEFB18E),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.fastfood_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: _clampDouble(8 * metrics.scale, 6, 8),
                        right: _clampDouble(8 * metrics.scale, 6, 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _clampDouble(9 * metrics.scale, 6, 9),
                            vertical: _clampDouble(5 * metrics.scale, 3, 5),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F3ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xD8E8DED5)),
                          ),
                          child: Text(
                            item.price,
                            style: TextStyle(
                              color: const Color(0xFF2D251F),
                              fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _clampDouble(10 * metrics.scale, 7, 10)),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1F1B19),
                    fontSize: _clampDouble(28 * metrics.scale, 20, 28) * 0.56,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: _clampDouble(5 * metrics.scale, 3, 5)),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF8F7F73),
                    fontSize: _clampDouble(14 * metrics.scale, 10, 14),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
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

class _PopularMenuItemData {
  const _PopularMenuItemData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imageUrl,
  });

  factory _PopularMenuItemData.fromMenuItem(RestaurantMenuItem item) {
    return _PopularMenuItemData(
      title: item.title,
      subtitle: item.description,
      price: item.price == null
          ? 'Market price'
          : '\$${item.price!.toStringAsFixed(2)}',
      imageUrl: item.imageUrl,
    );
  }

  final String title;
  final String subtitle;
  final String price;
  final String imageUrl;

  RestaurantMenuItem toRestaurantMenuItem(int index) {
    final parsedPrice = double.tryParse(
      price.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final normalizedId = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return RestaurantMenuItem(
      id: 'popular-$index-$normalizedId',
      title: title,
      description: subtitle,
      price: parsedPrice,
      imageUrl: imageUrl,
      category: 'Popular',
      isAvailable: true,
      isPopular: true,
    );
  }
}

class _RestaurantProfileInfo {
  const _RestaurantProfileInfo({
    this.id,
    required this.name,
    required this.handle,
    required this.cuisineSummary,
    required this.ratingLabel,
    required this.phoneLabel,
    required this.locationLabel,
    required this.followersCountLabel,
    required this.coverImageUrl,
    this.localProfileImagePath,
    this.cuisine,
    this.email,
    this.phone,
    this.country,
    this.city,
    this.street,
    this.postalCode,
  });

  static const String _defaultCoverImage =
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1400&q=80';

  final String? id;
  final String name;
  final String handle;
  final String cuisineSummary;
  final String ratingLabel;
  final String phoneLabel;
  final String locationLabel;
  final String followersCountLabel;
  final String coverImageUrl;
  final String? localProfileImagePath;
  final String? cuisine;
  final String? email;
  final String? phone;
  final String? country;
  final String? city;
  final String? street;
  final String? postalCode;

  factory _RestaurantProfileInfo.fromData({
    required String fallbackName,
    Map<String, dynamic>? primary,
    Map<String, dynamic>? secondary,
    String? localProfileImagePath,
  }) {
    final allMaps = _collectMaps([primary, secondary]);
    final sanitizedFallback = fallbackName.trim();

    final name =
        _firstString(allMaps, const [
          'restaurant_name',
          'business_name',
          'store_name',
          'name',
          'full_name',
          'display_name',
        ]) ??
        (sanitizedFallback.isEmpty ? 'Restaurant' : sanitizedFallback);
    final restaurantId = _firstString(allMaps, const [
      'restaurant_id',
      'id',
      'user_id',
      'owner_id',
      'account_id',
    ]);

    final handle = _normalizeHandle(
      _firstString(allMaps, const [
            'handle',
            'username',
            'slug',
            'restaurant_slug',
          ]) ??
          name,
    );

    final cuisine = _firstString(allMaps, const [
      'cuisine_type',
      'cuisine',
      'cuisine_name',
      'category',
      'food_category',
    ]);
    final city = _firstString(allMaps, const ['city', 'town']);
    final country = _firstString(allMaps, const ['country']);
    final street = _firstString(allMaps, const [
      'street',
      'address',
      'location',
    ]);
    final email = _firstString(allMaps, const [
      'email',
      'business_email',
      'contact_email',
    ]);
    final postalCode = _firstString(allMaps, const [
      'postal_code',
      'zip',
      'zip_code',
    ]);

    final phone = _firstString(allMaps, const [
      'phone',
      'phone_number',
      'mobile',
      'mobile_number',
      'contact_number',
      'telephone',
    ]);

    final rating = _firstDouble(allMaps, const [
      'rating',
      'average_rating',
      'avg_rating',
      'restaurant_rating',
    ]);
    final reviewsCount = _firstInt(allMaps, const [
      'reviews_count',
      'ratings_count',
      'total_reviews',
      'reviews',
    ]);
    final followersCount = _firstInt(allMaps, const [
      'followers_count',
      'follower_count',
      'followers_total',
      'followers',
    ]);

    final coverImageUrl =
        _firstString(allMaps, const [
          'cover_image_url',
          'cover_image',
          'banner_url',
          'banner_image',
          'hero_image',
          'image_url',
          'image',
          'photo_url',
        ]) ??
        _defaultCoverImage;

    return _RestaurantProfileInfo(
      id: restaurantId,
      name: name,
      handle: handle,
      cuisineSummary: _buildCuisineSummary(
        cuisine: cuisine,
        city: city,
        country: country,
      ),
      ratingLabel: _buildRatingLabel(rating, reviewsCount),
      phoneLabel: phone ?? 'Phone unavailable',
      locationLabel: _buildLocationLabel(
        street: street,
        city: city,
        country: country,
      ),
      followersCountLabel: _buildConnectionCountLabel(followersCount),
      coverImageUrl: coverImageUrl,
      localProfileImagePath: localProfileImagePath,
      cuisine: cuisine,
      email: email,
      phone: phone,
      country: country,
      city: city,
      street: street,
      postalCode: postalCode,
    );
  }

  _RestaurantProfileInfo copyWithEditable(_EditableProfileData data) {
    final nextName = data.restaurantName.trim().isEmpty
        ? name
        : data.restaurantName.trim();
    final nextCuisine = _nullable(data.cuisineType);
    final nextEmail = _nullable(data.email);
    final nextPhone = _nullable(data.phone);
    final nextCountry = _nullable(data.country);
    final nextCity = _nullable(data.city);
    final nextStreet = _nullable(data.street);
    final nextPostalCode = _nullable(data.postalCode);
    final nextLocalProfileImagePath = _nullable(data.localProfileImagePath);

    return _RestaurantProfileInfo(
      id: id,
      name: nextName,
      handle: handle,
      cuisineSummary: _buildCuisineSummary(
        cuisine: nextCuisine,
        city: nextCity,
        country: nextCountry,
      ),
      ratingLabel: ratingLabel,
      phoneLabel: nextPhone ?? 'Phone unavailable',
      locationLabel: _buildLocationLabel(
        street: nextStreet,
        city: nextCity,
        country: nextCountry,
      ),
      followersCountLabel: followersCountLabel,
      coverImageUrl: coverImageUrl,
      localProfileImagePath: nextLocalProfileImagePath,
      cuisine: nextCuisine,
      email: nextEmail,
      phone: nextPhone,
      country: nextCountry,
      city: nextCity,
      street: nextStreet,
      postalCode: nextPostalCode,
    );
  }

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<Map<String, dynamic>> _collectMaps(
    List<Map<String, dynamic>?> sources,
  ) {
    final output = <Map<String, dynamic>>[];

    void visit(dynamic node, int depth) {
      if (depth > 4) {
        return;
      }

      if (node is Map) {
        final mapped = <String, dynamic>{};
        node.forEach((key, value) {
          if (key is String) {
            mapped[key] = value;
          }
        });
        if (mapped.isEmpty) {
          return;
        }
        output.add(mapped);
        for (final value in mapped.values) {
          if (value is Map || value is List) {
            visit(value, depth + 1);
          }
        }
        return;
      }

      if (node is List) {
        for (final item in node) {
          if (item is Map || item is List) {
            visit(item, depth + 1);
          }
        }
      }
    }

    for (final source in sources) {
      if (source != null) {
        visit(source, 0);
      }
    }
    return output;
  }

  static String? _firstString(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        final normalized = _asCleanString(value);
        if (normalized != null) {
          return normalized;
        }
      }
    }
    return null;
  }

  static double? _firstDouble(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          final cleaned = value.trim();
          if (cleaned.isEmpty) {
            continue;
          }
          final parsed = double.tryParse(cleaned);
          if (parsed != null) {
            return parsed;
          }
          final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(cleaned);
          if (match != null) {
            final fallbackParsed = double.tryParse(match.group(0)!);
            if (fallbackParsed != null) {
              return fallbackParsed;
            }
          }
        }
      }
    }
    return null;
  }

  static int? _firstInt(List<Map<String, dynamic>> maps, List<String> keys) {
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        if (value is int) {
          return value;
        }
        if (value is num) {
          return value.toInt();
        }
        if (value is String) {
          final cleaned = value.trim();
          if (cleaned.isEmpty) {
            continue;
          }
          final parsed = int.tryParse(cleaned);
          if (parsed != null) {
            return parsed;
          }
          final match = RegExp(r'\d+').firstMatch(cleaned);
          if (match != null) {
            final fallbackParsed = int.tryParse(match.group(0)!);
            if (fallbackParsed != null) {
              return fallbackParsed;
            }
          }
        }
      }
    }
    return null;
  }

  static String? _asCleanString(dynamic value) {
    if (value is String) {
      final cleaned = value.trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }
    return null;
  }

  static String _normalizeHandle(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9_.]'), '')
        .toLowerCase();
    if (cleaned.isEmpty) {
      return 'restaurant';
    }
    return cleaned;
  }

  static String _buildCuisineSummary({
    String? cuisine,
    String? city,
    String? country,
  }) {
    final parts = <String>[?cuisine, ?city, ?country];
    if (parts.isEmpty) {
      return 'Restaurant Partner';
    }
    return parts.take(3).join(' | ');
  }

  static String _buildLocationLabel({
    String? street,
    String? city,
    String? country,
  }) {
    final locality = <String>[?city, ?country].join(', ');
    if (locality.isNotEmpty) {
      return locality;
    }
    if (street != null) {
      return street;
    }
    return 'Location unavailable';
  }

  static String _buildRatingLabel(double? rating, int? reviewsCount) {
    if (rating == null) {
      return 'No ratings yet';
    }
    final ratingText = rating.toStringAsFixed(1);
    if (reviewsCount != null && reviewsCount > 0) {
      return '$ratingText (${_formatCompactCount(reviewsCount)})';
    }
    return ratingText;
  }

  static String _buildConnectionCountLabel(int? count) {
    if (count == null || count < 0) {
      return '0';
    }
    return _formatCompactCount(count);
  }

  static String _formatCompactCount(int value) {
    if (value >= 1000000) {
      return '${_trimTrailingZero((value / 1000000).toStringAsFixed(1))}M';
    }
    if (value >= 1000) {
      return '${_trimTrailingZero((value / 1000).toStringAsFixed(1))}k';
    }
    return value.toString();
  }

  static String _trimTrailingZero(String value) {
    if (value.endsWith('.0')) {
      return value.substring(0, value.length - 2);
    }
    return value;
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
  double get bottomPadding => compact
      ? _clampDouble(height * 0.007, 6, 10)
      : _clampDouble(height * 0.009, 8, 12);
  double get sideGap => _clampDouble(16 * scale, 8, 16);
  double get gapAfterTop => _clampDouble(12 * scale, 6, 12);
  double get sectionGapSmall {
    if (tiny) {
      return _clampDouble(10 * scale, 4, 10);
    }
    if (compact) {
      return _clampDouble(16 * scale, 8, 14);
    }
    return _clampDouble(20 * scale, 10, 18);
  }

  double get railGap => _clampDouble(10 * scale, 6, 10);
  double get railWidth => _clampDouble(70 * scale, 54, 70);
  double get railItemGap => _clampDouble(12 * scale, 7, 12);

  double get topControlButtonSize => _clampDouble(54 * scale, 42, 54);
  double get topControlIconSize => _clampDouble(28 * scale, 20, 28);
  double get topTabFontSize => _clampDouble(18 * scale, 14, 18);
  double get topTabIndicatorWidth => _clampDouble(58 * scale, 42, 58);
  double get topTabIndicatorHeight => _clampDouble(6 * scale, 4, 6);

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
    final textColor = selected ? Colors.white : const Color(0xB6FFFFFF);

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
    required this.onOpenAudio,
  });

  final DemoFeedPost post;
  final _ResponsiveMetrics metrics;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onOpenAudio;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onOpenRestaurant,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
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
              SizedBox(width: _clampDouble(8 * metrics.scale, 4, 8)),
              Container(
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
            ],
          ),
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
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onShare,
  });

  final _ResponsiveMetrics metrics;
  final DemoFeedPost post;
  final VoidCallback onOpenRestaurant;
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
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.favorite_rounded,
            value: _RestaurantProfileInfo._formatCompactCount(post.likeCount),
            iconColor: post.isLiked ? const Color(0xFFFF7E4D) : Colors.white,
            metrics: metrics,
            onTap: onToggleLike,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            value: _RestaurantProfileInfo._formatCompactCount(
              post.commentCount,
            ),
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
  });

  final _ResponsiveMetrics metrics;
  final DemoFeedPost post;
  final VoidCallback onOpenRestaurant;

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
  final Color iconColor;
  final VoidCallback onTap;

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
                        '${_RestaurantProfileInfo._formatCompactCount(_comments.length)} comments',
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
      (icon: Icons.home_rounded, label: 'Feed'),
      (icon: Icons.restaurant_menu_rounded, label: 'Menu'),
      (
        icon: Icons.grid_view_rounded,
        label: metrics.tiny ? 'Dash' : 'Dashboard',
      ),
      (icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    final navScale = metrics.navScaleFactor;
    // Keep restaurant nav sizing in lockstep with customer nav sizing.
    final customerNavIconSize = _clampDouble(30 * metrics.scale * 0.82, 18, 24);
    final customerNavLabelSize = _clampDouble(
      12.5 * metrics.scale * 0.6,
      9 * 0.6,
      12.5 * 0.6,
    );
    final customerNavHeight = _clampDouble(
      96 * metrics.scale * 0.6,
      72 * 0.6,
      96 * 0.6,
    );
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
      height: customerNavHeight + (fullWidth ? bottomInset : 0),
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
              iconSize: customerNavIconSize,
              labelSize: customerNavLabelSize,
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
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final _ResponsiveMetrics metrics;
  final double iconSize;
  final double labelSize;
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
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: _clampDouble(6 * metrics.scale * navScale, 1.5, 6)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: labelSize,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
