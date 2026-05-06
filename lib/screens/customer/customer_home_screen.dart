part of '../user_home_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({
    super.key,
    required this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.accountLabel,
    this.authSession,
    this.onSessionUpdated,
    this.onSessionExpired,
  });

  final String userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? accountLabel;
  final AuthSession? authSession;
  final Future<void> Function(AuthSession session)? onSessionUpdated;
  final Future<void> Function()? onSessionExpired;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTopTab = 1;
  int _selectedBottomIndex = 0;
  final Set<String> _favoriteDiscoverSpotTitles = <String>{};
  late _EditableCustomerProfileData _customerProfileData;

  @override
  void initState() {
    super.initState();
    _customerProfileData = _EditableCustomerProfileData.fromUserHome(widget);
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

    setState(() {
      _customerProfileData = updatedData;
    });

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
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
              authSession: widget.authSession,
              onSessionUpdated: widget.onSessionUpdated,
              onSessionExpired: widget.onSessionExpired,
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
              authSession: widget.authSession,
              onSessionUpdated: widget.onSessionUpdated,
              onSessionExpired: widget.onSessionExpired,
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
    required this.authSession,
    required this.onSessionUpdated,
    required this.onSessionExpired,
    required this.selectedTopTab,
    required this.selectedBottomIndex,
    required this.onTopTabSelected,
    required this.onBottomNavSelected,
  });

  final AuthSession? authSession;
  final Future<void> Function(AuthSession session)? onSessionUpdated;
  final Future<void> Function()? onSessionExpired;
  final int selectedTopTab;
  final int selectedBottomIndex;
  final ValueChanged<int> onTopTabSelected;
  final ValueChanged<int> onBottomNavSelected;

  @override
  State<_FeedTabBody> createState() => _FeedTabBodyState();
}

class _FeedTabBodyState extends State<_FeedTabBody> {
  final _authSessionService = AuthSessionService();
  final Map<String, DemoFeedPost> _feedPostsById = <String, DemoFeedPost>{};
  final Map<String, CustomerVideoFeedItem> _feedItemsByPostId =
      <String, CustomerVideoFeedItem>{};
  final Map<String, Offset> _lastDoubleTapOffsetsByPostId = <String, Offset>{};
  final List<_FeedLikeBurstData> _activeLikeBursts = <_FeedLikeBurstData>[];
  final List<_FeedVideoPostData> _feedVideos = <_FeedVideoPostData>[];
  final List<bool> _hasShownOrderNowByVideoIndex = <bool>[];
  final List<bool> _isOrderNowVisibleByVideoIndex = <bool>[];
  final List<bool> _wasNearVideoEndByIndex = <bool>[];
  final List<VideoPlayerController> _videoControllers =
      <VideoPlayerController>[];
  final List<bool> _videoErrorLogged = <bool>[];
  final Set<String> _pendingDoubleTapLikePostIds = <String>{};
  final Set<String> _pendingLikePostIds = <String>{};
  final Set<String> _pendingSavePostIds = <String>{};
  final Set<String> _pendingFollowRestaurantIds = <String>{};
  final Set<String> _viewedPostIdsThisSession = <String>{};
  late final CustomerVideoFeedApiService _videoFeedApiService;
  AuthSession? _session;
  Timer? _viewEngagementTimer;
  int _currentVideoIndex = 0;
  int _feedRequestId = 0;
  int _nextFeedPage = 1;
  int _nextLikeBurstId = 0;
  bool _isLoadingFeed = true;
  bool _isLoadingMoreFeed = false;
  bool _hasMoreFeed = true;
  bool _isVideoHoldActive = false;
  String? _feedError;
  String? _activeSearchQuery;

  @override
  void initState() {
    super.initState();
    _session = widget.authSession;
    _videoFeedApiService = CustomerVideoFeedApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionUpdated: _handleApiSessionUpdated,
        onSessionExpired: widget.onSessionExpired,
      ),
    );
    _loadInitialFeed();
  }

  @override
  void didUpdateWidget(covariant _FeedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authSession?.token != widget.authSession?.token) {
      _session = widget.authSession;
    }
  }

  Future<void> _handleApiSessionUpdated(AuthSession session) async {
    _session = session;
    final onSessionUpdated = widget.onSessionUpdated;
    if (onSessionUpdated != null) {
      await onSessionUpdated(session);
    }
  }

  Future<AuthSession?> _resolveSession() async {
    final current = _session;
    if (current != null && current.token.trim().isNotEmpty) {
      return current;
    }
    final restored = await _authSessionService.readSession();
    if (restored != null && restored.token.trim().isNotEmpty) {
      _session = restored;
      return restored;
    }
    return null;
  }

  DemoFeedPost _postForVideo(_FeedVideoPostData video) {
    return _feedPostsById[video.postId] ?? video.post;
  }

  Future<void> _loadInitialFeed({String? query}) async {
    _viewEngagementTimer?.cancel();
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    _feedVideos.clear();
    _feedPostsById.clear();
    _feedItemsByPostId.clear();
    _hasShownOrderNowByVideoIndex.clear();
    _isOrderNowVisibleByVideoIndex.clear();
    _wasNearVideoEndByIndex.clear();
    _videoControllers.clear();
    _videoErrorLogged.clear();
    _currentVideoIndex = 0;
    final requestId = ++_feedRequestId;
    _nextFeedPage = 1;
    _hasMoreFeed = true;
    _activeSearchQuery = query?.trim().isEmpty ?? true ? null : query?.trim();
    if (mounted) {
      setState(() {
        _isLoadingFeed = true;
        _feedError = null;
      });
    }
    await _loadFeedPage(reset: true, requestId: requestId);
  }

  Future<void> _loadFeedPage({required bool reset, int? requestId}) async {
    if (_isLoadingMoreFeed && !reset) {
      return;
    }
    final activeRequestId = requestId ?? _feedRequestId;
    final session = await _resolveSession();
    if (activeRequestId != _feedRequestId) {
      return;
    }
    if (session == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFeed = false;
        _feedError = 'Please log in again to load your video feed.';
      });
      return;
    }

    if (!reset) {
      if (!_hasMoreFeed) {
        return;
      }
      setState(() => _isLoadingMoreFeed = true);
    }

    try {
      final page = await _videoFeedApiService.fetchFeed(
        session: session,
        page: _nextFeedPage,
        perPage: 15,
        query: _activeSearchQuery,
      );
      if (activeRequestId != _feedRequestId) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _appendFeedItems(page.items);
        _nextFeedPage = page.meta.currentPage + 1;
        _hasMoreFeed = page.meta.hasMore;
        _isLoadingFeed = false;
        _isLoadingMoreFeed = false;
        _feedError = null;
      });
      _syncVideoPlayback();
      _scheduleViewEngagementForCurrentVideo();
    } catch (error) {
      if (activeRequestId != _feedRequestId) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFeed = false;
        _isLoadingMoreFeed = false;
        _feedError = 'Unable to load videos. Please try again.';
      });
    }
  }

  void _appendFeedItems(List<CustomerVideoFeedItem> items) {
    for (final item in items) {
      if (item.id.trim().isEmpty || !item.isApprovedForFeed) {
        continue;
      }
      if (_feedItemsByPostId.containsKey(item.id)) {
        continue;
      }
      final post = _postFromFeedItem(item);
      final video = _FeedVideoPostData.fromFeedItem(item, post: post);
      _feedItemsByPostId[item.id] = item;
      _feedPostsById[item.id] = post;
      _feedVideos.add(video);
      _hasShownOrderNowByVideoIndex.add(false);
      _isOrderNowVisibleByVideoIndex.add(false);
      _wasNearVideoEndByIndex.add(false);
      _videoControllers.add(_buildVideoController(video));
      _videoErrorLogged.add(false);
    }
  }

  VideoPlayerController _buildVideoController(_FeedVideoPostData video) {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(video.videoUrl),
    );
    final index = _videoControllers.length;
    controller.addListener(() {
      if (index >= _videoErrorLogged.length) {
        return;
      }
      if (!_videoErrorLogged[index] && controller.value.hasError) {
        _videoErrorLogged[index] = true;
        debugPrint(
          'Home feed video playback error for ${video.postId}: ${controller.value.errorDescription}',
        );
      }
      if (index < _wasNearVideoEndByIndex.length) {
        _handleOrderNowTriggerByVideoProgress(index);
      }
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
          _scheduleViewEngagementForCurrentVideo();
        })
        .catchError((error) {
          debugPrint('Home feed video init failed for ${video.postId}: $error');
        });
    return controller;
  }

  DemoFeedPost _postFromFeedItem(CustomerVideoFeedItem item) {
    final restaurant = item.restaurant;
    final restaurantName = restaurant?.name.trim().isNotEmpty == true
        ? restaurant!.name
        : 'Restaurant';
    final menuName = item.menuItem?.name.trim();
    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : (menuName?.isNotEmpty == true ? menuName! : restaurantName);
    final caption = item.description.trim().isNotEmpty
        ? item.description.trim()
        : title;
    final tags = <String>[
      if (menuName != null && menuName.isNotEmpty) _feedTagFromName(menuName),
      _feedTagFromName(restaurantName),
    ].join(' ');
    return DemoFeedPost(
      id: item.id,
      restaurantName: restaurantName,
      restaurantHandle: _feedHandleFromName(restaurantName),
      followersCount: item.stats.viewsCount,
      caption: caption,
      tags: tags,
      audioLabel: 'Original Audio - $restaurantName',
      rating: 4.8,
      likeCount: item.stats.likesCount,
      commentCount: item.stats.commentsCount,
      isLiked: item.viewerState.isLiked,
      isFollowing: item.viewerState.isFollowingRestaurant,
      restaurantId: restaurant?.id,
      menuItemName: menuName,
      menuItemPrice: item.menuItem?.price,
      thumbnailUrl: item.thumbnailUrl,
      previewUrl: item.streamPreviewUrl,
      saveCount: item.stats.savesCount,
      shareCount: item.stats.sharesCount,
      isSaved: item.viewerState.isSaved,
    );
  }

  Future<void> _openSearch() async {
    final query = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const SearchScreen(
          includeCustomers: false,
          returnSubmittedQuery: true,
        ),
      ),
    );
    final cleanedQuery = query?.trim();
    if (cleanedQuery == null || cleanedQuery.isEmpty) {
      return;
    }
    final session = await _resolveSession();
    if (session != null) {
      unawaited(
        _videoFeedApiService
            .recordSearch(session: session, query: cleanedQuery)
            .catchError((_) {}),
      );
    }
    await _loadInitialFeed(query: cleanedQuery);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openRestaurantDetails(DemoFeedPost post) async {
    final reviewPreviews = <RestaurantProfileReviewPreview>[];
    await showRestaurantProfilePopup(
      context,
      restaurantName: post.restaurantName,
      handle: post.restaurantHandle,
      rating: post.rating,
      caption: post.caption,
      followersCountLabel:
          '${_formatCompactCount(post.followersCount)} followers',
      allowAddToCart: true,
      menuItems: _menuItemsForPost(post),
      showFollowButton: true,
      showSaveButton: true,
      initiallySaved: post.isSaved,
      initiallyFollowing: post.isFollowing,
      onToggleFollow: () {
        _toggleFollow(post);
      },
      onToggleSave: (_) {
        _toggleSave(post);
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
    );
  }

  Future<void> _openRestaurantReviews(DemoFeedPost post) async {
    final resolvedReviews = _buildDemoRestaurantReviews(
      restaurantName: post.restaurantName,
      rating: post.rating,
    );
    var shouldOpenFullReviewsPage = false;
    await showModalBottomSheet<void>(
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
    );

    if (!mounted || !shouldOpenFullReviewsPage) {
      return;
    }

    await openRestaurantReviewsPage(
      context,
      restaurantName: post.restaurantName,
      rating: post.rating,
      reviews: resolvedReviews,
    );
  }

  Future<void> _toggleFollow(DemoFeedPost post) async {
    final restaurantId = post.restaurantId?.trim();
    if (restaurantId == null || restaurantId.isEmpty) {
      _showFeedSnackBar('This restaurant cannot be followed yet.');
      return;
    }
    if (!_pendingFollowRestaurantIds.add(restaurantId)) {
      return;
    }
    final session = await _resolveSession();
    if (session == null) {
      _pendingFollowRestaurantIds.remove(restaurantId);
      _showFeedSnackBar('Please log in again to follow restaurants.');
      return;
    }
    final current = _feedPostsById[post.id] ?? post;
    final nextFollowing = !current.isFollowing;
    final previousPosts = Map<String, DemoFeedPost>.from(_feedPostsById);
    _setFollowingForRestaurant(current, nextFollowing);
    try {
      if (nextFollowing) {
        await _videoFeedApiService.followRestaurant(
          session: session,
          restaurantId: restaurantId,
        );
      } else {
        await _videoFeedApiService.unfollowRestaurant(
          session: session,
          restaurantId: restaurantId,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _feedPostsById
            ..clear()
            ..addAll(previousPosts);
        });
        _showFeedSnackBar('Could not update follow status. Try again.');
      }
    } finally {
      _pendingFollowRestaurantIds.remove(restaurantId);
    }
  }

  Future<void> _toggleLike(DemoFeedPost post) async {
    if (!_pendingLikePostIds.add(post.id)) {
      return;
    }
    final session = await _resolveSession();
    if (session == null) {
      _pendingLikePostIds.remove(post.id);
      _showFeedSnackBar('Please log in again to like videos.');
      return;
    }
    final current = _feedPostsById[post.id] ?? post;
    final nextLiked = !current.isLiked;
    final optimistic = current.copyWith(
      isLiked: nextLiked,
      likeCount: nextLiked
          ? current.likeCount + 1
          : (current.likeCount - 1).clamp(0, 1 << 31),
    );
    setState(() => _feedPostsById[post.id] = optimistic);
    try {
      if (nextLiked) {
        await _videoFeedApiService.recordEngagement(
          session: session,
          videoId: post.id,
          type: 'like',
        );
      } else {
        await _videoFeedApiService.removeEngagement(
          session: session,
          videoId: post.id,
          type: 'like',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _feedPostsById[post.id] = current);
        _showFeedSnackBar('Could not update like. Try again.');
      }
    } finally {
      _pendingLikePostIds.remove(post.id);
    }
  }

  Future<void> _toggleSave(DemoFeedPost post) async {
    if (!_pendingSavePostIds.add(post.id)) {
      return;
    }
    final session = await _resolveSession();
    if (session == null) {
      _pendingSavePostIds.remove(post.id);
      _showFeedSnackBar('Please log in again to save videos.');
      return;
    }
    final current = _feedPostsById[post.id] ?? post;
    final nextSaved = !current.isSaved;
    final optimistic = current.copyWith(
      isSaved: nextSaved,
      saveCount: nextSaved
          ? current.saveCount + 1
          : (current.saveCount - 1).clamp(0, 1 << 31),
    );
    setState(() => _feedPostsById[post.id] = optimistic);
    try {
      if (nextSaved) {
        await _videoFeedApiService.recordEngagement(
          session: session,
          videoId: post.id,
          type: 'save',
        );
      } else {
        await _videoFeedApiService.removeEngagement(
          session: session,
          videoId: post.id,
          type: 'save',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _feedPostsById[post.id] = current);
        _showFeedSnackBar('Could not update save. Try again.');
      }
    } finally {
      _pendingSavePostIds.remove(post.id);
    }
  }

  List<RestaurantMenuItem> _menuItemsForPost(DemoFeedPost post) {
    final title = post.menuItemName?.trim();
    if (title == null || title.isEmpty) {
      return const <RestaurantMenuItem>[];
    }
    return <RestaurantMenuItem>[
      RestaurantMenuItem(
        id: post.id,
        title: title,
        description: post.caption,
        price: post.menuItemPrice,
        imageUrl:
            post.thumbnailUrl ??
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
        category: post.restaurantName,
        isAvailable: true,
        isPopular: false,
      ),
    ];
  }

  void _setFollowingForRestaurant(DemoFeedPost source, bool isFollowing) {
    final restaurantId = source.restaurantId?.trim();
    final restaurantHandle = source.restaurantHandle.trim().toLowerCase();
    setState(() {
      for (final entry in List<MapEntry<String, DemoFeedPost>>.from(
        _feedPostsById.entries,
      )) {
        final post = entry.value;
        final sameRestaurantId =
            restaurantId != null &&
            restaurantId.isNotEmpty &&
            post.restaurantId == restaurantId;
        final sameHandle =
            restaurantHandle.isNotEmpty &&
            post.restaurantHandle.trim().toLowerCase() == restaurantHandle;
        if (sameRestaurantId || sameHandle) {
          _feedPostsById[entry.key] = post.copyWith(isFollowing: isFollowing);
        }
      }
    });
  }

  void _showFeedSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    final current = _feedPostsById[post.id] ?? post;
    if (current.isLiked || _pendingDoubleTapLikePostIds.contains(post.id)) {
      return;
    }
    _pendingDoubleTapLikePostIds.add(post.id);
    try {
      await _toggleLike(current);
    } finally {
      _pendingDoubleTapLikePostIds.remove(post.id);
    }
  }

  void _handleOrderNowTriggerByVideoProgress(int index) {
    if (index < 0 ||
        index >= _videoControllers.length ||
        index >= _wasNearVideoEndByIndex.length ||
        index >= _hasShownOrderNowByVideoIndex.length ||
        index >= _isOrderNowVisibleByVideoIndex.length) {
      return;
    }
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
    if (index < 0 || index >= _isOrderNowVisibleByVideoIndex.length) {
      return;
    }
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrdersCartScreen(
          initialItems: [item],
          restaurantName: post.restaurantName,
        ),
      ),
    );
  }

  Future<void> _openComments(DemoFeedPost post) async {
    final session = await _resolveSession();
    if (session == null) {
      _showFeedSnackBar('Please log in again to view comments.');
      return;
    }
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedCommentsBottomSheet(
        postId: post.id,
        postTitle: post.restaurantName,
        session: session,
        apiService: _videoFeedApiService,
        onCommentCountChanged: (count) {
          if (!mounted) {
            return;
          }
          final current = _feedPostsById[post.id] ?? post;
          setState(() {
            _feedPostsById[post.id] = current.copyWith(commentCount: count);
          });
        },
      ),
    );
  }

  Future<void> _sharePromo(DemoFeedPost post) async {
    final current = _feedPostsById[post.id] ?? post;
    setState(() {
      _feedPostsById[post.id] = current.copyWith(
        shareCount: current.shareCount + 1,
      );
    });
    await showShareFallbackDialog(
      context,
      title: post.restaurantName,
      body: post.caption,
    );
    final session = await _resolveSession();
    if (session == null) {
      return;
    }
    try {
      await _videoFeedApiService.recordEngagement(
        session: session,
        videoId: post.id,
        type: 'share',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _feedPostsById[post.id] = current);
      }
    }
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
    _scheduleViewEngagementForCurrentVideo();
    if (index >= _feedVideos.length - 3) {
      unawaited(_loadFeedPage(reset: false, requestId: _feedRequestId));
    }
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

  void _scheduleViewEngagementForCurrentVideo() {
    _viewEngagementTimer?.cancel();
    if (_currentVideoIndex < 0 || _currentVideoIndex >= _feedVideos.length) {
      return;
    }
    final scheduledIndex = _currentVideoIndex;
    final video = _feedVideos[scheduledIndex];
    if (_viewedPostIdsThisSession.contains(video.postId)) {
      return;
    }
    _viewEngagementTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted ||
          scheduledIndex != _currentVideoIndex ||
          scheduledIndex >= _videoControllers.length) {
        return;
      }
      final controller = _videoControllers[scheduledIndex];
      if (!controller.value.isInitialized ||
          !controller.value.isPlaying ||
          _viewedPostIdsThisSession.contains(video.postId)) {
        return;
      }
      _viewedPostIdsThisSession.add(video.postId);
      unawaited(_recordViewEngagement(video.postId));
    });
  }

  Future<void> _recordViewEngagement(String postId) async {
    final session = await _resolveSession();
    if (session == null) {
      return;
    }
    try {
      await _videoFeedApiService.recordEngagement(
        session: session,
        videoId: postId,
        type: 'view',
      );
    } catch (_) {
      _viewedPostIdsThisSession.remove(postId);
    }
  }

  void _handleVideoLongPressStart(int index) {
    if (_isVideoHoldActive ||
        index != _currentVideoIndex ||
        index < 0 ||
        index >= _videoControllers.length) {
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

  @override
  void dispose() {
    _viewEngagementTimer?.cancel();
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
                itemCount: _feedVideos.length,
                itemBuilder: (context, index) {
                  final video = _feedVideos[index];
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
                            thumbnailUrl: video.thumbnailUrl,
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
                                          onToggleLike: () => _toggleLike(post),
                                          onToggleSave: () => _toggleSave(post),
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
            if (_feedVideos.isEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: navBarTotalHeight,
                child: _FeedStatusOverlay(
                  isLoading: _isLoadingFeed,
                  message:
                      _feedError ??
                      (_activeSearchQuery == null
                          ? 'No videos available yet.'
                          : 'No videos matched "${_activeSearchQuery!}".'),
                  onRetry: () => _loadInitialFeed(query: _activeSearchQuery),
                ),
              ),
            if (_isLoadingMoreFeed)
              Positioned(
                left: 0,
                right: 0,
                bottom: navBarTotalHeight + 16,
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
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

class _FeedStatusOverlay extends StatelessWidget {
  const _FeedStatusOverlay({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A2230),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 14),
                    Text(
                      'Loading your feed...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else ...[
                const Icon(
                  Icons.video_library_outlined,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedVideoPostData {
  const _FeedVideoPostData({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.postId,
    required this.post,
    required this.priceLabel,
    required this.cartItemTitle,
    required this.cartItemSubtitle,
    required this.cartItemImageUrl,
    required this.cartItemPrice,
  });

  factory _FeedVideoPostData.fromFeedItem(
    CustomerVideoFeedItem item, {
    required DemoFeedPost post,
  }) {
    final menuName = item.menuItem?.name.trim();
    final price = item.menuItem?.price;
    return _FeedVideoPostData(
      videoUrl: item.playbackUrl,
      thumbnailUrl: item.thumbnailUrl,
      postId: item.id,
      post: post,
      priceLabel: price == null ? 'Order' : '\$${price.toStringAsFixed(2)}',
      cartItemTitle: menuName?.isNotEmpty == true
          ? menuName!
          : post.restaurantName,
      cartItemSubtitle: item.description.trim().isNotEmpty
          ? item.description.trim()
          : post.caption,
      cartItemImageUrl: item.thumbnailUrl.trim().isNotEmpty
          ? item.thumbnailUrl.trim()
          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
      cartItemPrice: price ?? 0,
    );
  }

  final String videoUrl;
  final String? thumbnailUrl;
  final String postId;
  final DemoFeedPost post;
  final String priceLabel;
  final String cartItemTitle;
  final String cartItemSubtitle;
  final String cartItemImageUrl;
  final double cartItemPrice;
}

class _FeedBackground extends StatelessWidget {
  const _FeedBackground({required this.controller, this.thumbnailUrl});

  final VideoPlayerController controller;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      final poster = thumbnailUrl?.trim();
      if (poster != null && poster.isNotEmpty) {
        return ColoredBox(
          color: Colors.black,
          child: Image.network(
            poster,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
            ),
          ),
        );
      }
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
    required this.onToggleSave,
    required this.onOpenComments,
    required this.onShare,
  });

  final _ResponsiveMetrics metrics;
  final DemoFeedPost post;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
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
            icon: post.isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            value: _formatCompactCount(post.saveCount),
            iconColor: post.isSaved ? const Color(0xFFFFC66D) : Colors.white,
            metrics: metrics,
            onTap: onToggleSave,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.share_outlined,
            value: post.shareCount > 0
                ? _formatCompactCount(post.shareCount)
                : 'Share',
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
    required this.session,
    required this.apiService,
    required this.onCommentCountChanged,
  });

  final String postId;
  final String postTitle;
  final AuthSession session;
  final CustomerVideoFeedApiService apiService;
  final ValueChanged<int> onCommentCountChanged;

  @override
  State<_FeedCommentsBottomSheet> createState() =>
      _FeedCommentsBottomSheetState();
}

class _FeedCommentsBottomSheetState extends State<_FeedCommentsBottomSheet> {
  final _controller = TextEditingController();

  List<CustomerVideoComment> _comments = const <CustomerVideoComment>[];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.apiService.fetchComments(
        session: widget.session,
        videoId: widget.postId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments = comments;
        _isLoading = false;
        _error = null;
      });
      widget.onCommentCountChanged(comments.length);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);
    try {
      final created = await widget.apiService.postComment(
        session: widget.session,
        videoId: widget.postId,
        body: text,
      );
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {
        if (created != null) {
          _comments = <CustomerVideoComment>[..._comments, created];
        }
        _isSending = false;
        _error = null;
      });
      widget.onCommentCountChanged(_comments.length);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _error = error.toString();
      });
    }
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF7E3D34),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _error = null;
                                  });
                                  _loadComments();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _comments.isEmpty
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
