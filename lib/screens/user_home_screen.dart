import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/demo_app_models.dart';
import '../services/demo_app_repository.dart';
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

void _showFeatureComingSoonSnackBar(BuildContext context, String buttonName) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Feature Coming Soon: $buttonName')));
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
  });

  final String userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? accountLabel;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTopTab = 1;
  int _selectedBottomIndex = 0;

  String get _userHandle {
    final cleaned = widget.userName.trim();
    if (cleaned.isEmpty) {
      return 'FoodExplorer';
    }
    return cleaned.replaceAll(RegExp(r'\s+'), '');
  }

  void _openProfileMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final showDiscover = _selectedBottomIndex == 1;
    final showOrders = _selectedBottomIndex == 2;
    final showMessages = _selectedBottomIndex == 3;
    final showProfile = _selectedBottomIndex == 4;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: showProfile || showDiscover || showOrders || showMessages
          ? const Color(0xFFF8EFE5)
          : const Color(0xFF0A2230),
      endDrawer: _UserProfileMenuDrawer(
        userName: widget.userName,
        userEmail: widget.userEmail,
        userAvatarUrl: widget.userAvatarUrl,
      ),
      body: showProfile
          ? _ProfileTabBody(
              userName: widget.userName,
              userHandle: _userHandle,
              userEmail: widget.userEmail,
              userAvatarUrl: widget.userAvatarUrl,
              accountLabel: widget.accountLabel,
              selectedBottomIndex: _selectedBottomIndex,
              onOpenMenu: _openProfileMenu,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : showDiscover
          ? _DiscoverTabBody(
              userName: widget.userName,
              selectedBottomIndex: _selectedBottomIndex,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : showOrders
          ? _OrdersTabBody(
              userName: widget.userName,
              selectedBottomIndex: _selectedBottomIndex,
              onBottomNavSelected: (index) {
                setState(() => _selectedBottomIndex = index);
              },
            )
          : showMessages
          ? _MessagesTabBody(
              userName: widget.userName,
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
    ),
    _FeedVideoPostData(
      videoAssetPath: 'assets/videos/home_video_2.mp4',
      postId: 'following',
      priceLabel: '\$12.40',
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
      controller.setVolume(0);
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

  Future<void> _openSearch() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openRestaurantDetails(DemoFeedPost post) async {
    await showRestaurantProfilePopup(
      context,
      restaurantName: post.restaurantName,
      handle: post.restaurantHandle,
      rating: post.rating,
      caption: post.caption,
      followersCountLabel:
          '${_formatCompactCount(post.followersCount)} followers',
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

  Future<void> _openComments(DemoFeedPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedCommentsBottomSheet(
        postId: post.id,
        postTitle: post.restaurantName,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _feedPostsById[post.id] = _loadPostForId(post.id));
  }

  Future<void> _sharePromo(DemoFeedPost post) async {
    await showShareFallbackDialog(
      context,
      title: post.restaurantName,
      body: post.caption,
    );
  }

  Future<void> _openPromoDetails(DemoFeedPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PromoDetailsScreen(
          title: post.restaurantName,
          caption: post.caption,
          audioLabel: post.audioLabel,
        ),
      ),
    );
  }

  void _handleVideoPageChanged(int index) {
    final previousIndex = _currentVideoIndex;
    _currentVideoIndex = index;
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
      if (i == _currentVideoIndex) {
        controller.play();
      } else {
        controller.pause();
      }
    }
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
                                            onOpenAudio: () =>
                                                _openPromoDetails(post),
                                            showOrderNow: showOrderNow,
                                            orderNowPriceLabel:
                                                video.priceLabel,
                                            onDismissOrderNow: () =>
                                                _dismissOrderNowForVideoIndex(
                                                  index,
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
                                          onToggleLike: () => _toggleLike(post),
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
                onSelected: widget.onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
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
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
  final int selectedBottomIndex;
  final ValueChanged<int> onBottomNavSelected;

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
                  child: _CustomerMessagesSection(
                    metrics: metrics,
                    userName: userName,
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
  });

  final _ResponsiveMetrics metrics;
  final String userName;

  @override
  State<_CustomerMessagesSection> createState() =>
      _CustomerMessagesSectionState();
}

class _CustomerMessagesSectionState extends State<_CustomerMessagesSection> {
  final _repository = DemoAppRepository.instance;

  static const Map<String, String> _restaurantNamesByThreadId =
      <String, String>{
        't1': 'Bella Italia',
        't2': 'Smash House',
        't3': 'Cedars Kitchen',
        't4': 'Levant Grill',
        't5': 'Green Bowl',
        't6': 'Falafel Spot',
      };

  List<DemoConversationThread> _threads = const <DemoConversationThread>[];
  MessageFilterType _selectedFilter = MessageFilterType.all;
  String? _selectedThreadId;
  bool _needsReplyOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final threads = await _repository.getThreads();
    if (!mounted) {
      return;
    }
    setState(() {
      _threads = threads;
      _isLoading = false;
    });
  }

  String _counterpartyName(DemoConversationThread thread) {
    return _restaurantNamesByThreadId[thread.id] ?? thread.customerName;
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
    if (_needsReplyOnly) {
      items = items.where((thread) => thread.needsReply);
    }
    if (_selectedThreadId != null) {
      items = items.where((thread) => thread.id == _selectedThreadId);
    }
    return items.toList();
  }

  void _selectFilter(MessageFilterType filter) {
    setState(() => _selectedFilter = filter);
  }

  void _toggleNeedsReplyOnly() {
    setState(() => _needsReplyOnly = !_needsReplyOnly);
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
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                _CustomerMessagesHeaderCard(
                  metrics: widget.metrics,
                  unreadThreads: unreadThreads,
                  needsReplyThreads: needsReplyThreads,
                  needsReplySelected: _needsReplyOnly,
                  onSelectUnread: () => _selectFilter(MessageFilterType.unread),
                  onToggleNeedsReply: _toggleNeedsReplyOnly,
                ),
                SizedBox(
                  height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                ),
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

class _CustomerMessagesHeaderCard extends StatelessWidget {
  const _CustomerMessagesHeaderCard({
    required this.metrics,
    required this.unreadThreads,
    required this.needsReplyThreads,
    required this.needsReplySelected,
    required this.onSelectUnread,
    required this.onToggleNeedsReply,
  });

  final _ResponsiveMetrics metrics;
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
                      'Stay on top of restaurant replies',
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
                child: _CustomerMessageHeaderStat(
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
                child: _CustomerMessageHeaderStat(
                  metrics: metrics,
                  icon: Icons.reply_rounded,
                  iconColor: const Color(0xFF2E9B57),
                  iconBackground: const Color(0xFFE1F5E8),
                  label: 'Waiting on You',
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

class _CustomerMessageHeaderStat extends StatelessWidget {
  const _CustomerMessageHeaderStat({
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
  });

  final String videoAssetPath;
  final String postId;
  final String priceLabel;
}

class _DiscoverTabBody extends StatefulWidget {
  const _DiscoverTabBody({
    required this.userName,
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
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
  final Set<String> _favoriteSpotTitles = <String>{};
  Set<String> _activeCuisineFilters = <String>{};
  double _minimumRatingFilter = 0;
  int? _maximumDeliveryMinutesFilter;
  int? _maximumPriceTierFilter;

  List<_DiscoverSpotData> get _filteredPopularSpots {
    return _DiscoverTabBody._popularSpots.where((spot) {
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
    }).toList(growable: false);
  }

  List<_DiscoverSpotData> _spotsForCuisine(String cuisineTitle) {
    return _DiscoverTabBody._popularSpots
        .where((spot) => spot.categoryTitle == cuisineTitle)
        .toList(growable: false);
  }

  Future<void> _openDiscoverSearch(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }

  void _openVoiceSearch(BuildContext context) {
    _showFeatureComingSoonSnackBar(context, 'Voice Search');
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
                      children: _DiscoverTabBody._categories.map((category) {
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
                      }).toList(growable: false),
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
                              onSelected: (_) => setModalState(
                                () => minimumRating = value,
                              ),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(
                                color: Color(0xFFEAD9CB),
                              ),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: chips,
                        );
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
                              side: const BorderSide(
                                color: Color(0xFFEAD9CB),
                              ),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: chips,
                        );
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
                              onSelected: (_) => setModalState(
                                () => maximumPriceTier = value,
                              ),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(
                                color: Color(0xFFEAD9CB),
                              ),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: chips,
                        );
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
  }

  Future<void> _openPopularSpotMenu(
    BuildContext context,
    _DiscoverSpotData spot,
  ) async {
    await _openDiscoverRestaurantProfile(
      context,
      spot,
      initialTabIndex: 1,
    );
  }

  Future<void> _openPopularSpotList(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DiscoverPopularSpotsScreen(spots: _filteredPopularSpots),
      ),
    );
  }

  void _toggleSpotFavorite(_DiscoverSpotData spot) {
    setState(() {
      if (_favoriteSpotTitles.contains(spot.title)) {
        _favoriteSpotTitles.remove(spot.title);
      } else {
        _favoriteSpotTitles.add(spot.title);
      }
    });
  }

  void _openQuickCravingDetails(BuildContext context, _DiscoverDealData deal) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DiscoverDealDetailsSheet(data: deal),
    );
  }

  void _startExploring(BuildContext context) {
    if (_DiscoverTabBody._categories.isEmpty) {
      return;
    }
    _openCuisineDetails(context, _DiscoverTabBody._categories.first);
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
                              onTapVoiceSearch: () => _openVoiceSearch(context),
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
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DiscoverFeatureCard(
                                metrics: metrics,
                                onStartExploring: () =>
                                    _startExploring(context),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  24 * metrics.scale,
                                  18,
                                  24,
                                ),
                              ),
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
                                  itemCount: _DiscoverTabBody._categories.length,
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
                                      onTap: () =>
                                          _openCuisineDetails(context, category),
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
                                onActionTap: () => _openPopularSpotList(context),
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
                                        isFavorite: _favoriteSpotTitles.contains(
                                          spot.title,
                                        ),
                                        onTap: () =>
                                            _openPopularSpot(context, spot),
                                        onViewMenuTap: () =>
                                            _openPopularSpotMenu(
                                              context,
                                              spot,
                                            ),
                                        onFavoriteTap: () =>
                                            _toggleSpotFavorite(spot),
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
                                      final item =
                                          _DiscoverTabBody._quickCravings[index];
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
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
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
    ),
    _PastOrderEntryData(
      title: 'Napoli Fire',
      summary: '1 item - Pepperoni feast with extra mozzarella',
      dateLabel: 'Yesterday, 7:18 PM',
      totalLabel: '\$18.90',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    ),
    _PastOrderEntryData(
      title: 'Bean & Brew',
      summary: '3 items - iced latte, brownie, and turkey sandwich',
      dateLabel: 'Apr 25, 9:06 AM',
      totalLabel: '\$16.40',
      status: _OrderStatus.rejected,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  static List<DemoOrder> _buildOrderHistoryItems() {
    return List<DemoOrder>.generate(_pastOrders.length, (index) {
      final item = _pastOrders[index];
      final completed =
          item.status == _OrderStatus.delivered ||
          item.status == _OrderStatus.canceled ||
          item.status == _OrderStatus.rejected;
      return DemoOrder(
        id: '#${4700 - index}',
        customerName: item.title,
        itemSummary: item.summary,
        etaLabel: item.dateLabel,
        statusLabel: _orderStatusLabel(item.status),
        channelLabel: 'Delivery',
        highlighted: false,
        totalLabel: item.totalLabel,
        completed: completed,
      );
    });
  }

  void _openOrderHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderListScreen(
          title: 'Order History',
          orders: _buildOrderHistoryItems(),
        ),
      ),
    );
  }

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
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(20 * metrics.scale, 16, 20),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OrdersHeroCard(
                                metrics: metrics,
                                greetingName: greetingName,
                                metricsData: _heroMetrics,
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
                                currentStatus: _activeStatus,
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
                              Column(
                                children: List.generate(_pastOrders.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == _pastOrders.length - 1
                                          ? 0
                                          : _clampDouble(
                                              14 * metrics.scale,
                                              10,
                                              14,
                                            ),
                                    ),
                                    child: _PastOrderCard(
                                      data: _pastOrders[index],
                                      metrics: metrics,
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              const _ProfileSectionHeader(
                                title: 'Reorder Tonight',
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              _OrdersRewardCard(metrics: metrics),
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
  const _OrdersHeroCard({
    required this.metrics,
    required this.greetingName,
    required this.metricsData,
  });

  final _ResponsiveMetrics metrics;
  final String greetingName;
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Everything on track for $greetingName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF231A16),
                        fontSize: _clampDouble(24 * metrics.scale, 19, 24),
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                  SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _clampDouble(12 * metrics.scale, 10, 12),
                      vertical: _clampDouble(8 * metrics.scale, 6, 8),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCFA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Gold perks',
                      style: TextStyle(
                        color: const Color(0xFFFF7E4D),
                        fontSize: _clampDouble(13 * metrics.scale, 11, 13),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
              Text(
                'One live delivery, fresh order history, and bonus points waiting on your next reorder.',
                maxLines: metrics.compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF745F52),
                  fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              SizedBox(height: _clampDouble(18 * metrics.scale, 14, 18)),
              Wrap(
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
              ),
            ],
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
  const _PastOrderCard({required this.data, required this.metrics});

  final _PastOrderEntryData data;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final imageSize = _clampDouble(82 * metrics.scale, 68, 82);
    return _ProfilePanel(
      child: Padding(
        padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 330;
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
                SizedBox(width: _clampDouble(14 * metrics.scale, 10, 14)),
                Expanded(child: details),
                SizedBox(width: _clampDouble(12 * metrics.scale, 10, 12)),
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

class _OrdersRewardCard extends StatelessWidget {
  const _OrdersRewardCard({required this.metrics});

  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_clampDouble(20 * metrics.scale, 16, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F2), Color(0xFFFFE2CC)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF3DFCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10A7633A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat your best combo',
            style: TextStyle(
              color: const Color(0xFF231A16),
              fontSize: _clampDouble(22 * metrics.scale, 17, 22),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
          Text(
            'Reorder Burger Station tonight and unlock 120 bonus points toward your next free delivery.',
            maxLines: metrics.compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF755F52),
              fontSize: _clampDouble(14 * metrics.scale, 11, 14),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          SizedBox(height: _clampDouble(16 * metrics.scale, 12, 16)),
          Wrap(
            spacing: _clampDouble(10 * metrics.scale, 8, 10),
            runSpacing: _clampDouble(10 * metrics.scale, 8, 10),
            children: [
              _OrdersActionPill(
                label: 'Reorder combo',
                filled: true,
                metrics: metrics,
              ),
              _OrdersActionPill(
                label: 'Use points',
                filled: false,
                metrics: metrics,
              ),
            ],
          ),
        ],
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
                    final previousTime = index == 0
                        ? null
                        : checkpoints[index - 1].time;
                    final durationLabel = previousTime == null
                        ? 'Start'
                        : '${step.time.difference(previousTime).inMinutes} min';
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == checkpoints.length - 1 ? 0 : 10,
                      ),
                      child: _OrderTrackingTimelineTile(
                        step: step,
                        isComplete: isComplete,
                        isCurrent: isCurrent,
                        timeLabel: _formatClockTime(step.time),
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
                          onTap: () => _showFeatureComingSoonSnackBar(
                            context,
                            'Contact Restaurant',
                          ),
                        ),
                        _OrdersActionPill(
                          label: 'Support chat',
                          filled: true,
                          metrics: trackingMetrics,
                          onTap: () => _showFeatureComingSoonSnackBar(
                            context,
                            'Support Chat',
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
  final String timeLabel;
  final String durationLabel;

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
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
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
                    _TrackingMetaPill(
                      icon: Icons.schedule_rounded,
                      label: timeLabel,
                    ),
                    _TrackingMetaPill(
                      icon: Icons.timelapse_rounded,
                      label: durationLabel,
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
    this.accountLabel,
    required this.selectedBottomIndex,
    required this.onOpenMenu,
    required this.onBottomNavSelected,
  });

  final String userName;
  final String userHandle;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? accountLabel;
  final int selectedBottomIndex;
  final VoidCallback onOpenMenu;
  final ValueChanged<int> onBottomNavSelected;

  static const List<_RecentOrderData> _recentOrders = [
    _RecentOrderData(
      title: 'Burger Station',
      summary: '2 items - \$24.50',
      dateLabel: 'Yesterday',
      actionLabel: 'Reorder',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
    ),
    _RecentOrderData(
      title: 'Napoli Fire',
      summary: '1 pizza - \$18.90',
      dateLabel: '2 days ago',
      actionLabel: 'Order Again',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  static const List<_SavedPlaceData> _savedPlaces = [
    _SavedPlaceData(
      title: 'The Golden Spoon',
      subtitle: 'Italian - 1.2 mi',
      icon: Icons.restaurant_rounded,
    ),
    _SavedPlaceData(
      title: 'Bean & Brew',
      subtitle: 'Cafe - 0.5 mi',
      icon: Icons.local_cafe_rounded,
    ),
  ];

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
                                accountLabel: accountLabel,
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
                              _ProfilePanel(
                                child: Column(
                                  children: List.generate(_savedPlaces.length, (
                                    index,
                                  ) {
                                    final place = _savedPlaces[index];
                                    return Column(
                                      children: [
                                        _SavedPlaceTile(
                                          data: place,
                                          metrics: metrics,
                                        ),
                                        if (index != _savedPlaces.length - 1)
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
                                  }),
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
  const _DiscoverSearchBar({
    required this.metrics,
    required this.onTapSearch,
    required this.onTapVoiceSearch,
  });

  final _ResponsiveMetrics metrics;
  final VoidCallback onTapSearch;
  final VoidCallback onTapVoiceSearch;

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
              GestureDetector(
                onTap: onTapVoiceSearch,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.mic_none_rounded,
                    color: const Color(0xFFB9A596),
                    size: _clampDouble(22 * metrics.scale, 18, 22),
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

class _DiscoverFeatureCard extends StatelessWidget {
  const _DiscoverFeatureCard({
    required this.metrics,
    required this.onStartExploring,
  });

  static const _featureImage =
      'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80';

  final _ResponsiveMetrics metrics;
  final VoidCallback onStartExploring;

  @override
  Widget build(BuildContext context) {
    final useStackedLayout = metrics.compact;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(12 * metrics.scale, 10, 12),
            vertical: _clampDouble(7 * metrics.scale, 5, 7),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Editor\'s Pick',
            style: TextStyle(
              color: const Color(0xFFFF7E4D),
              fontSize: _clampDouble(13 * metrics.scale, 11, 13),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
        Text(
          'Dinner plans made easy',
          maxLines: useStackedLayout ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF231A16),
            fontSize: _clampDouble(24 * metrics.scale, 18, 24),
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
        Text(
          'Tap into cozy pasta bars, sizzling grills, and quick comfort food near you.',
          maxLines: useStackedLayout ? 4 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF745F52),
            fontSize: _clampDouble(14 * metrics.scale, 11, 14),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        SizedBox(height: _clampDouble(16 * metrics.scale, 12, 16)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onStartExploring,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: _clampDouble(16 * metrics.scale, 12, 16),
                vertical: _clampDouble(10 * metrics.scale, 8, 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7E4D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Start exploring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: useStackedLayout
            ? double.infinity
            : _clampDouble(108 * metrics.scale, 92, 108),
        height: useStackedLayout
            ? _clampDouble(132 * metrics.scale, 112, 132)
            : _clampDouble(160 * metrics.scale, 132, 160),
        child: Image.network(
          _featureImage,
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
                Icons.restaurant_menu_rounded,
                color: Colors.white,
                size: _clampDouble(42 * metrics.scale, 34, 42),
              ),
            );
          },
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(_clampDouble(20 * metrics.scale, 16, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF2E5), Color(0xFFFFD8BB)],
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
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: _clampDouble(118 * metrics.scale, 96, 118),
              height: _clampDouble(118 * metrics.scale, 96, 118),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x24FFFFFF),
              ),
            ),
          ),
          useStackedLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    SizedBox(height: _clampDouble(14 * metrics.scale, 10, 14)),
                    preview,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    SizedBox(width: _clampDouble(14 * metrics.scale, 10, 14)),
                    preview,
                  ],
                ),
        ],
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
                              horizontal: _clampDouble(12 * metrics.scale, 9, 12),
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
                                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
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
                          SizedBox(width: _clampDouble(4 * metrics.scale, 2, 4)),
                          Text(
                            data.ratingLabel,
                            style: TextStyle(
                              color: const Color(0xFF5A4A40),
                              fontSize: _clampDouble(14 * metrics.scale, 11, 14),
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
                              horizontal: _clampDouble(13 * metrics.scale, 10, 13),
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
}
) {
  return showRestaurantProfilePopup(
    context,
    restaurantName: spot.title,
    handle: spot.handle,
    rating: spot.ratingValue,
    caption: spot.subtitle,
    initialTabIndex: initialTabIndex,
    followersCountLabel:
        '${_formatCompactCount(8400 + (spot.deliveryMinutes * 28))} followers',
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
                      children: List.generate(spots.length.clamp(0, 4), (index) {
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9E8A7E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverDealDetailsSheet extends StatelessWidget {
  const _DiscoverDealDetailsSheet({required this.data});

  final _DiscoverDealData data;

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
    required this.onOpenAudio,
    required this.showOrderNow,
    required this.orderNowPriceLabel,
    required this.onDismissOrderNow,
  });

  final DemoFeedPost post;
  final _ResponsiveMetrics metrics;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onOpenAudio;
  final bool showOrderNow;
  final String orderNowPriceLabel;
  final VoidCallback onDismissOrderNow;

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
                    ),
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey<String>('order-now-hidden'),
                ),
        ),
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
  });

  final _ResponsiveMetrics metrics;
  final String priceLabel;
  final bool compactStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = compactStyle || constraints.maxWidth < 360;
        final compactScale = compactStyle ? 0.82 : 1.0;
        final showMoreButton =
            constraints.maxWidth >= (compactStyle ? 260 : 340);

        return Container(
          height: _clampDouble(
            metrics.ctaHeight * compactScale,
            42,
            metrics.ctaHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(12 * metrics.scale * compactScale, 7, 12),
            vertical: _clampDouble(8 * metrics.scale * compactScale, 4, 8),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A5B),
            borderRadius: BorderRadius.circular(
              _clampDouble(
                metrics.ctaRadius * (compactStyle ? 0.88 : 1.0),
                18,
                metrics.ctaRadius,
              ),
            ),
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
                width: _clampDouble(42 * metrics.scale * compactScale, 24, 42),
                height: _clampDouble(42 * metrics.scale * compactScale, 24, 42),
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
                width: _clampDouble(12 * metrics.scale * compactScale, 5, 12),
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
                            border: Border.all(color: const Color(0x49FFFFFF)),
                          ),
                          child: Text(
                            priceLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact
                                  ? _clampDouble(
                                      (metrics.ctaPriceSize - 3) * compactScale,
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
                        if (showMoreButton) ...[
                          SizedBox(
                            width: _clampDouble(
                              8 * metrics.scale * compactScale,
                              3,
                              8,
                            ),
                          ),
                          Container(
                            width: _clampDouble(
                              34 * metrics.scale * compactScale,
                              20,
                              34,
                            ),
                            height: _clampDouble(
                              34 * metrics.scale * compactScale,
                              20,
                              34,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0x1DFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                              size: _clampDouble(
                                22 * metrics.scale * compactScale,
                                10,
                                22,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
    this.userEmail,
    this.userAvatarUrl,
  });

  final String userName;
  final String? userEmail;
  final String? userAvatarUrl;

  static const List<_ProfileSettingsItemData> _settingsItems = [
    _ProfileSettingsItemData(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
    ),
    _ProfileSettingsItemData(
      title: 'Payment Methods',
      icon: Icons.credit_card_rounded,
    ),
    _ProfileSettingsItemData(
      title: 'Privacy & Security',
      icon: Icons.lock_outline_rounded,
    ),
    _ProfileSettingsItemData(
      title: 'Help & Support',
      icon: Icons.help_outline_rounded,
    ),
  ];

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
                            child: hasAvatarUrl
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
                              onTap: () => Navigator.of(context).pop(),
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
                      onPressed: () {
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.userName,
    required this.userHandle,
    this.userEmail,
    this.userAvatarUrl,
    this.accountLabel,
    required this.metrics,
  });

  final String userName;
  final String userHandle;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? accountLabel;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final avatarSize = _clampDouble(76 * metrics.scale, 60, 76);
    final displayName = userName.trim().isEmpty
        ? 'Hungry Explorer'
        : userName.trim();
    final displayEmail = _profileEmail(handle: userHandle, email: userEmail);
    final avatarUrl = userAvatarUrl?.trim();
    final hasAvatarUrl = _looksLikeHttpUrl(avatarUrl);
    final displayAccountLabel = accountLabel?.trim().isNotEmpty == true
        ? accountLabel!.trim()
        : 'Customer Account';

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
                  child: hasAvatarUrl
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
                    fontSize: _clampDouble(24 * metrics.scale, 18, 24),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _clampDouble(12 * metrics.scale, 10, 12),
                    vertical: _clampDouble(7 * metrics.scale, 5, 7),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    displayAccountLabel,
                    style: TextStyle(
                      color: const Color(0xFFFF7E4D),
                      fontSize: _clampDouble(13 * metrics.scale, 11, 13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _clampDouble(12 * metrics.scale, 8, 12)),
          Container(
            width: _clampDouble(46 * metrics.scale, 38, 46),
            height: _clampDouble(46 * metrics.scale, 38, 46),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: const Color(0xFFFF7E4D),
              size: _clampDouble(22 * metrics.scale, 18, 22),
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
  const _RecentOrderCard({required this.data, required this.metrics});

  final _RecentOrderData data;
  final _ResponsiveMetrics metrics;

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
                Wrap(
                  spacing: _clampDouble(10 * metrics.scale, 6, 10),
                  runSpacing: _clampDouble(6 * metrics.scale, 4, 6),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _clampDouble(14 * metrics.scale, 10, 14),
                        vertical: _clampDouble(8 * metrics.scale, 6, 8),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7E4D),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        data.actionLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      data.dateLabel,
                      style: TextStyle(
                        color: const Color(0xFF9C8A7C),
                        fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                        fontWeight: FontWeight.w600,
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
  const _SavedPlaceTile({required this.data, required this.metrics});

  final _SavedPlaceData data;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
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

class _RecentOrderData {
  const _RecentOrderData({
    required this.title,
    required this.summary,
    required this.dateLabel,
    required this.actionLabel,
    required this.imageUrl,
  });

  final String title;
  final String summary;
  final String dateLabel;
  final String actionLabel;
  final String imageUrl;
}

class _SavedPlaceData {
  const _SavedPlaceData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
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
  });

  final String title;
  final String summary;
  final String dateLabel;
  final String totalLabel;
  final _OrderStatus status;
  final String imageUrl;
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

class _ProfileSettingsItemData {
  const _ProfileSettingsItemData({required this.title, required this.icon});

  final String title;
  final IconData icon;
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
