part of '../restaurant_feed_screen.dart';

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
  // ignore: unused_field
  static const String _sampleProfileVideoAssetPath =
      'assets/videos/home_video_2.mp4';

  final _profileScaffoldKey = GlobalKey<ScaffoldState>();
  final _authSessionService = AuthSessionService();
  final _demoRepository = DemoAppRepository.instance;
  final Map<String, DemoFeedPost> _feedPostsById = <String, DemoFeedPost>{};
  final Map<String, Offset> _lastDoubleTapOffsetsByPostId = <String, Offset>{};
  final List<_FeedLikeBurstData> _activeLikeBursts = <_FeedLikeBurstData>[];
  final Set<String> _pendingDoubleTapLikePostIds = <String>{};
  int _selectedBottomIndex = 0;
  int _selectedTopTab = 1;
  int _selectedProfileTabIndex = _profileMenuTabIndex;
  late final RestaurantOwnerApiService _ownerApiService;
  late final LoyaltyApiService _loyaltyApiService;
  late final CustomerVideoFeedApiService _videoFeedApiService;
  late final RestaurantOrderApiService _restaurantOrderApiService;
  PlatformFile? _selectedPostVideo;
  bool _isPickingPostVideo = false;
  bool _isCreatingPost = false;
  bool _isLoadingFeedVideos = true;
  final List<_UploadedRestaurantVideo> _uploadedVideos =
      <_UploadedRestaurantVideo>[];
  final List<_FeedVideoPostData> _feedVideos = <_FeedVideoPostData>[];
  final List<VideoPlayerController> _videoControllers =
      <VideoPlayerController>[];
  final List<bool> _videoErrorLogged = <bool>[];
  int _currentVideoIndex = 0;
  int _videoPlaybackSyncVersion = 0;
  int _nextLikeBurstId = 0;
  bool _isVideoHoldActive = false;
  _VideoHoldAction _videoHoldAction = _VideoHoldAction.none;
  bool _isVideoManuallyPaused = false;
  String? _feedVideosError;

  late _RestaurantProfileInfo _profileInfo;
  bool _isRefreshingProfile = false;
  String? _profileSyncError;
  List<RestaurantMenuItem> _restaurantMenuItems = const [];
  RestaurantAnalytics? _restaurantAnalytics;
  List<AppOrder> _restaurantOrders = const <AppOrder>[];
  bool _isRefreshingDashboard = false;
  bool _isRefreshingMenu = false;
  bool _hasLoadedMenu = false;
  String? _menuSyncError;

  @override
  void initState() {
    super.initState();
    _ownerApiService = RestaurantOwnerApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionExpired: widget.onLogout,
      ),
    );
    _loyaltyApiService = LoyaltyApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionExpired: widget.onLogout,
      ),
    );
    _videoFeedApiService = CustomerVideoFeedApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionExpired: widget.onLogout,
      ),
    );
    _restaurantOrderApiService = RestaurantOrderApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionExpired: widget.onLogout,
      ),
    );
    _profileInfo = _RestaurantProfileInfo.fromData(
      primary: widget.initialUserData,
      fallbackName: widget.restaurantName,
    );
    unawaited(_refreshRestaurantVideos());
    unawaited(_refreshDashboardData());
    _refreshRestaurantProfile();
  }

  @override
  void dispose() {
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<AuthSession?> _resolveSession() async {
    final restored = await _authSessionService.readSession();
    if (restored != null && restored.token.trim().isNotEmpty) {
      return restored;
    }
    final token = widget.authToken?.trim() ?? '';
    if (token.isEmpty) {
      return null;
    }
    return AuthSession(
      token: token,
      role: 'restaurant_owner',
      restaurantName: widget.restaurantName,
      user: widget.initialUserData,
    );
  }

  Future<void> _refreshRestaurantProfile() async {
    final session = await _resolveSession();
    if (session == null) {
      return;
    }

    setState(() {
      _isRefreshingProfile = true;
      _profileSyncError = null;
    });

    try {
      final payload = await _ownerApiService.fetchProfile(session: session);
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
  bool get _isFollowingFeedSelected => false;
  List<RestaurantMenuItem> get _menuItemsForDisplay => _restaurantMenuItems;

  // ignore: unused_element
  void _addSampleProfileVideo() {
    // Restaurant videos are loaded from the owner API.
  }

  Future<void> _refreshRestaurantVideos() async {
    final session = await _resolveSession();
    if (session == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFeedVideos = false;
        _feedVideosError = 'Please log in again to load restaurant videos.';
      });
      return;
    }
    if (mounted) {
      setState(() {
        _isLoadingFeedVideos = true;
        _feedVideosError = null;
      });
    }
    var ownerVideos = const <RestaurantVideoItem>[];
    try {
      ownerVideos = await _ownerApiService.fetchVideos(session: session);
    } catch (error) {
      debugPrint('Restaurant owner videos refresh failed: $error');
    }

    try {
      var feedPage = await _videoFeedApiService.fetchFeed(
        session: session,
        page: 1,
        perPage: 15,
      );
      var nextFeedPage = feedPage.meta.currentPage + 1;
      var hasMoreFeed = feedPage.meta.hasMore;
      var visibleItems = _visibleFeedItems(feedPage.items);

      while (_isFollowingFeedSelected && visibleItems.isEmpty && hasMoreFeed) {
        feedPage = await _videoFeedApiService.fetchFeed(
          session: session,
          page: nextFeedPage,
          perPage: 15,
        );
        nextFeedPage = feedPage.meta.currentPage + 1;
        hasMoreFeed = feedPage.meta.hasMore;
        visibleItems = _visibleFeedItems(feedPage.items);
      }
      if (!mounted) {
        return;
      }
      final hasGlobalFeedVideos = visibleItems.isNotEmpty;
      setState(() {
        _uploadedVideos
          ..clear()
          ..addAll(ownerVideos.map(_uploadedVideoFromApiItem));
        if (hasGlobalFeedVideos) {
          _replaceFeedVideos(visibleItems);
        } else {
          _replaceFeedVideosFromOwnerVideos(ownerVideos);
        }
        _isLoadingFeedVideos = false;
        _feedVideosError = _feedVideos.isEmpty
            ? _emptyFeedMessage()
            : null;
      });
    } catch (error) {
      debugPrint('Restaurant global feed refresh failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedVideos
          ..clear()
          ..addAll(ownerVideos.map(_uploadedVideoFromApiItem));
        _replaceFeedVideosFromOwnerVideos(ownerVideos);
        _isLoadingFeedVideos = false;
        _feedVideosError = _feedVideos.isEmpty
            ? 'Unable to load feed videos. Please try again.'
            : null;
      });
    }
  }

  List<CustomerVideoFeedItem> _visibleFeedItems(
    List<CustomerVideoFeedItem> items,
  ) {
    return items
        .where(_isFeedItemVisibleForSelectedTopTab)
        .toList(growable: false);
  }

  bool _isFeedItemVisibleForSelectedTopTab(CustomerVideoFeedItem item) {
    if (!item.isApprovedForFeed || item.playbackUrl.isEmpty) {
      return false;
    }
    if (!_isFollowingFeedSelected) {
      return true;
    }
    return item.viewerState.isFollowingRestaurant;
  }

  void _resetFeedVideosState() {
    _videoPlaybackSyncVersion++;
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    _feedVideos.clear();
    _feedPostsById.clear();
    _videoControllers.clear();
    _videoErrorLogged.clear();
    _currentVideoIndex = 0;
    _isVideoHoldActive = false;
    _videoHoldAction = _VideoHoldAction.none;
    _isVideoManuallyPaused = false;
  }

  void _replaceFeedVideos(List<CustomerVideoFeedItem> videos) {
    _resetFeedVideosState();

    for (final item in videos) {
      if (!_isFeedItemVisibleForSelectedTopTab(item)) {
        continue;
      }
      final video = _FeedVideoPostData.fromFeedItem(item);
      final post = _postFromFeedItem(item);
      _feedVideos.add(video);
      _feedPostsById[video.postId] = post;
      _videoControllers.add(_buildFeedVideoController(video));
      _videoErrorLogged.add(false);
    }
  }

  void _replaceFeedVideosFromOwnerVideos(List<RestaurantVideoItem> videos) {
    _resetFeedVideosState();
    final fallbackVideos = _ownerVideosForFeed(videos);
    for (final item in fallbackVideos) {
      final video = _FeedVideoPostData.fromOwnerVideo(item);
      final post = _postFromOwnerVideoItem(item, postId: video.postId);
      _feedVideos.add(video);
      _feedPostsById[video.postId] = post;
      _videoControllers.add(_buildFeedVideoController(video));
      _videoErrorLogged.add(false);
    }
  }

  List<RestaurantVideoItem> _ownerVideosForFeed(List<RestaurantVideoItem> videos) {
    final published = videos.where((video) {
      return video.canAppearPublished && video.playbackUrl.trim().isNotEmpty;
    }).toList(growable: false);
    if (published.isNotEmpty) {
      return published;
    }
    return videos.where((video) {
      return video.playbackUrl.trim().isNotEmpty;
    }).toList(growable: false);
  }

  VideoPlayerController _buildFeedVideoController(_FeedVideoPostData video) {
    final source = video.videoUrl.trim();
    final uri = Uri.tryParse(source);
    final controller =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? VideoPlayerController.networkUrl(uri)
        : VideoPlayerController.file(File(source));
    final index = _videoControllers.length;
    controller.addListener(() {
      if (index >= _videoErrorLogged.length || _videoErrorLogged[index]) {
        return;
      }
      if (controller.value.hasError) {
        _videoErrorLogged[index] = true;
        debugPrint(
          'Restaurant feed video playback error for ${video.postId}: ${controller.value.errorDescription}',
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
            'Restaurant feed video init failed for ${video.postId}: $error',
          );
        });
    return controller;
  }

  _UploadedRestaurantVideo _uploadedVideoFromApiItem(RestaurantVideoItem item) {
    return _UploadedRestaurantVideo(
      backendId: item.id,
      name: item.title,
      sizeBytes: 0,
      uploadedAt: item.createdAt ?? item.publishedAt ?? DateTime.now(),
      caption: item.description,
      hashtags: item.status,
      moderationLabel: item.moderationLabel,
      moderationReason: item.moderationReason,
      videoFilePath: item.playbackUrl,
    );
  }

  DemoFeedPost _postFromFeedItem(CustomerVideoFeedItem item) {
    final restaurant = item.restaurant;
    final restaurantName = restaurant?.name.trim().isNotEmpty == true
        ? restaurant!.name
        : _restaurantName;
    final menuName = item.menuItem?.name.trim();
    final title = item.title.trim();
    final caption = item.description.trim().isNotEmpty
        ? item.description.trim()
        : (title.isNotEmpty
              ? title
              : (menuName?.isNotEmpty == true ? menuName! : restaurantName));
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
      audioLabel: '',
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
      shareCount: item.stats.sharesCount,
    );
  }

  DemoFeedPost _postFromOwnerVideoItem(
    RestaurantVideoItem item, {
    required String postId,
  }) {
    final restaurantName = _restaurantName;
    final title = item.title.trim();
    final caption = item.description.trim().isNotEmpty
        ? item.description.trim()
        : (title.isNotEmpty ? title : 'Restaurant video');
    final tags = _profileInfo.cuisineSummary.trim().isNotEmpty
        ? _profileInfo.cuisineSummary
        : _feedTagFromName(restaurantName);
    final thumbnailUrl = item.thumbnailUrl.trim();
    final previewUrl = item.streamPreviewUrl.trim();
    return DemoFeedPost(
      id: postId,
      restaurantName: restaurantName,
      restaurantHandle: _profileInfo.handle,
      followersCount: item.viewsCount,
      caption: caption,
      tags: tags,
      audioLabel: '',
      rating: _ratingValueFromLabel(_profileInfo.ratingLabel),
      likeCount: item.likesCount,
      commentCount: 0,
      isLiked: false,
      isFollowing: true,
      restaurantId: _profileInfo.id,
      thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
      previewUrl: previewUrl.isEmpty ? null : previewUrl,
      shareCount: item.sharesCount,
    );
  }

  double _ratingValueFromLabel(String label) {
    return double.tryParse(
          RegExp(r'\d+(?:\.\d+)?').firstMatch(label)?.group(0) ?? '',
        ) ??
        4.8;
  }

  Future<void> _refreshDashboardData() async {
    if (_isRefreshingDashboard) {
      return;
    }
    final session = await _resolveSession();
    if (session == null) {
      return;
    }
    setState(() => _isRefreshingDashboard = true);
    try {
      final results = await Future.wait<Object>([
        _ownerApiService.fetchAnalytics(session: session),
        _restaurantOrderApiService.fetchOrders(session: session),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantAnalytics = results[0] as RestaurantAnalytics;
        _restaurantOrders = results[1] as List<AppOrder>;
        _isRefreshingDashboard = false;
      });
    } catch (error) {
      debugPrint('Restaurant dashboard refresh failed: $error');
      if (!mounted) {
        return;
      }
      setState(() => _isRefreshingDashboard = false);
    }
  }

  DemoFeedPost get _activeFeedPost {
    if (_feedVideos.isEmpty) {
      return _loadPostForId('restaurant-feed');
    }
    final index = _currentVideoIndex.clamp(0, _feedVideos.length - 1);
    final video = _feedVideos[index];
    return _postForVideo(video);
  }

  DemoFeedPost _loadPostForId(String postId) {
    return DemoFeedPost(
      id: postId,
      restaurantName: _restaurantName,
      restaurantHandle: _profileInfo.handle,
      followersCount: 0,
      caption: 'Restaurant video',
      tags: _profileInfo.cuisineSummary,
      audioLabel: '',
      rating: _ratingValueFromLabel(_profileInfo.ratingLabel),
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isFollowing: true,
      restaurantId: _profileInfo.id,
    );
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
      if (!mounted) {
        return;
      }
      final current = _feedPostsById[post.id] ?? post;
      setState(() {
        _feedPostsById[post.id] = current.copyWith(
          isLiked: true,
          likeCount: current.likeCount + 1,
        );
      });
    } finally {
      _pendingDoubleTapLikePostIds.remove(post.id);
    }
  }

  Future<void> _openSearch() async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const SearchScreen(includeCustomers: true),
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await _withFeedPlaybackPaused<void>(
      () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
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
        restaurantId: targetPost.restaurantId,
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
        showMenuCategoryFilter: true,
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
    if (updated.backendId.trim().isNotEmpty) {
      unawaited(_syncUpdatedVideo(updated));
    }
  }

  void _deleteUploadedVideo(_UploadedRestaurantVideo target) {
    final index = _indexOfUploadedVideo(target);
    if (index < 0 || !mounted) {
      return;
    }
    setState(() {
      _uploadedVideos.removeAt(index);
    });
    if (target.backendId.trim().isNotEmpty) {
      unawaited(_deleteVideoFromApi(target));
    }
  }

  Future<void> _syncUpdatedVideo(_UploadedRestaurantVideo video) async {
    final session = await _resolveSession();
    if (session == null) {
      return;
    }
    try {
      await _ownerApiService.updateVideo(
        session: session,
        videoId: video.backendId,
        body: <String, dynamic>{
          'title': video.name.trim().isEmpty ? 'Video' : video.name.trim(),
          'description': video.caption.trim(),
          'status': 'published',
        },
      );
    } catch (error) {
      debugPrint('Video update failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update video details.')),
      );
    }
  }

  Future<void> _deleteVideoFromApi(_UploadedRestaurantVideo video) async {
    final session = await _resolveSession();
    if (session == null) {
      return;
    }
    try {
      await _ownerApiService.deleteVideo(
        session: session,
        videoId: video.backendId,
      );
    } catch (error) {
      debugPrint('Video delete failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete video from server.')),
      );
    }
  }

  Future<void> _toggleVendorLike([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    if (!mounted) {
      return;
    }
    final current = _feedPostsById[targetPost.id] ?? targetPost;
    final nextLiked = !current.isLiked;
    setState(() {
      _feedPostsById[targetPost.id] = current.copyWith(
        isLiked: nextLiked,
        likeCount: nextLiked
            ? current.likeCount + 1
            : (current.likeCount - 1).clamp(0, 1 << 31),
      );
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
  }

  Future<void> _shareVendorPromo([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    String? directUrl;
    for (final video in _feedVideos) {
      if (video.postId == targetPost.id && video.videoUrl.trim().isNotEmpty) {
        directUrl = video.videoUrl.trim();
        break;
      }
    }
    if ((directUrl == null || directUrl.isEmpty) &&
        (targetPost.previewUrl?.trim().isNotEmpty ?? false)) {
      directUrl = targetPost.previewUrl!.trim();
    }
    final result = await PostShareService.instance.sharePost(
      postId: targetPost.id,
      title: targetPost.restaurantName,
      caption: targetPost.caption,
      creatorHandle: targetPost.restaurantHandle,
      directUrl: directUrl,
    );
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    if (!result.success) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Unable to share this post right now. Please try again.',
          ),
        ),
      );
      return;
    }
    if (result.copiedToClipboard) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard.')),
      );
    }
  }

  Future<void> _reportFeedPost([DemoFeedPost? post]) async {
    final targetPost = post ?? _activeFeedPost;
    await showReportSheet(
      context,
      itemType: ReportItemType.feedPost,
      itemId: targetPost.id,
      itemTitle: targetPost.restaurantName,
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LiveRestaurantOrdersScreen(
          title: 'Completed Orders',
          filter: RestaurantOrderFilter.completed,
        ),
      ),
    );
  }

  Future<void> _openRevenueAnalytics() async {
    final completedOrders = _computeOrdersCompletedToday(_menuItemsForDisplay);
    final revenueToday = _computeRevenueToday(
      completedToday: completedOrders,
      averagePrice: _computeAveragePrice(_menuItemsForDisplay),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LiveRestaurantOrdersScreen(
          title: 'Orders In Progress',
          filter: RestaurantOrderFilter.active,
        ),
      ),
    );
  }

  Future<void> _openOrderManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LiveRestaurantOrdersScreen(
          title: 'Order Management',
          filter: RestaurantOrderFilter.all,
        ),
      ),
    );
  }

  Future<void> _openOrderDetails(String orderId) async {
    final cleanedOrderId = orderId.trim();
    if (cleanedOrderId.isEmpty || cleanedOrderId.startsWith('#')) {
      await _openOrderManagement();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LiveRestaurantOrderDetailScreen(orderId: cleanedOrderId),
      ),
    );
  }

  void _openMenuItemDetails(RestaurantMenuItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('View details'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showRestaurantMenuItemDetailsPopup(context, item: item);
                  },
                ),
                ListTile(
                  leading: Icon(
                    item.isAvailable
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                  ),
                  title: Text(
                    item.isAvailable ? 'Mark unavailable' : 'Mark available',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_toggleMenuItemAvailability(item));
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB7372B),
                  ),
                  title: const Text('Delete item'),
                  textColor: const Color(0xFFB7372B),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_deleteMenuItem(item));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleMenuItemAvailability(RestaurantMenuItem item) async {
    final session = await _resolveSession();
    if (session == null || item.id.trim().isEmpty) {
      return;
    }
    try {
      final updated = await _ownerApiService.updateMenuItemAvailability(
        session: session,
        menuItemId: item.id,
        isAvailable: !item.isAvailable,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantMenuItems = _restaurantMenuItems
            .map((current) => current.id == item.id ? updated : current)
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update availability: $error')),
      );
    }
  }

  Future<void> _deleteMenuItem(RestaurantMenuItem item) async {
    final session = await _resolveSession();
    if (session == null || item.id.trim().isEmpty) {
      return;
    }
    try {
      await _ownerApiService.deleteMenuItem(
        session: session,
        menuItemId: item.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantMenuItems = _restaurantMenuItems
            .where((current) => current.id != item.id)
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete menu item: $error')),
      );
    }
  }

  void _onBottomNavSelected(int index) {
    setState(() => _selectedBottomIndex = index);
    if (index == 0) {
      unawaited(_syncVideoPlayback());
      if (_feedVideos.isEmpty && !_isLoadingFeedVideos) {
        unawaited(_refreshRestaurantVideos());
      }
    } else {
      _pauseAllFeedVideos();
    }
    if (index == _menuTabIndex || index == _dashboardTabIndex) {
      _refreshRestaurantMenu();
    }
  }

  void _onTopFeedTabSelected(int index) {
    if (index == _selectedTopTab) {
      return;
    }
    setState(() => _selectedTopTab = 1);
  }

  String _emptyFeedMessage() {
    return _isFollowingFeedSelected
        ? 'No videos from followed restaurants yet.'
        : 'No published videos available yet.';
  }

  void _openMenuSection() {
    _onBottomNavSelected(_menuTabIndex);
    _refreshRestaurantMenu(force: true);
  }

  Future<void> _openLoyaltyOffersScreen() async {
    final session = await _resolveSession();
    if (session == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to manage loyalty offers.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RestaurantLoyaltyOffersScreen(
          authSession: session,
          loyaltyApiService: _loyaltyApiService,
        ),
      ),
    );
  }

  void _onProfileTabSelected(int index) {
    setState(() => _selectedProfileTabIndex = index);
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

    final session = await _resolveSession();
    if (session == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to update profile.')),
      );
      return;
    }

    try {
      String? uploadedPhotoUrl;
      final nextPhotoPath = updatedData.localProfileImagePath.trim();
      final currentPhotoPath = _profileInfo.localProfileImagePath?.trim() ?? '';
      if (nextPhotoPath.isNotEmpty && nextPhotoPath != currentPhotoPath) {
        uploadedPhotoUrl = await _ownerApiService.uploadProfilePhoto(
          session: session,
          path: nextPhotoPath,
        );
      }
      await _ownerApiService.updateSettings(
        session: session,
        body: <String, dynamic>{
          'name': updatedData.restaurantName.trim(),
          'owner_email': updatedData.email.trim(),
          'owner_phone': updatedData.phone.trim(),
          'settings': <String, dynamic>{
            'cuisine': updatedData.cuisineType.trim(),
            if (uploadedPhotoUrl != null && uploadedPhotoUrl.trim().isNotEmpty)
              'profile_photo_url': uploadedPhotoUrl.trim(),
          },
          'locations': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Main',
              'address': <String>[
                updatedData.street.trim(),
                updatedData.city.trim(),
                updatedData.country.trim(),
                updatedData.postalCode.trim(),
              ].where((value) => value.isNotEmpty).join(', '),
              'phone': updatedData.phone.trim(),
            },
          ],
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
      return;
    }

    setState(() {
      _profileInfo = _profileInfo.copyWithEditable(updatedData);
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  Future<void> _openFollowersList({String? restaurantName}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Followers list is not available from the API yet.'),
      ),
    );
  }

  void _openProfileSettingsDrawer() {
    _profileScaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _logoutToLogin() async {
    final parentLogout = widget.onLogout;
    if (parentLogout != null) {
      await parentLogout();
      return;
    }

    final authSessionService = AuthSessionService();
    final session = await authSessionService.readSession();
    if (session != null) {
      unawaited(
        PushNotificationService.instance.deactivateCurrentDeviceToken(
          session: session,
        ),
      );
    }
    final token = widget.authToken?.trim();
    if (token != null && token.isNotEmpty) {
      try {
        await AuthApiService().logout(token: token);
      } on AuthApiException {
        // Local logout must still complete if the server token is invalid.
      }
    }
    await authSessionService.clearSession();
    if (!mounted) {
      return;
    }
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

    final session = await _resolveSession();
    if (session == null) {
      setState(() {
        _restaurantMenuItems = const <RestaurantMenuItem>[];
        _hasLoadedMenu = true;
        _isRefreshingMenu = false;
        _menuSyncError = 'Please log in again to load menu items.';
      });
      return;
    }

    setState(() {
      _isRefreshingMenu = true;
      _menuSyncError = null;
    });

    try {
      final items = await _ownerApiService.fetchMenuItems(session: session);
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantMenuItems = items;
        _hasLoadedMenu = true;
        _isRefreshingMenu = false;
        _menuSyncError = items.isEmpty ? 'No menu items available yet.' : null;
      });
    } on RestaurantOwnerApiException catch (e) {
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
                              thumbnailUrl: video.thumbnailUrl,
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
                                              onReport: () =>
                                                  _reportFeedPost(post),
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
              if (_feedVideos.isEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: navBarTotalHeight,
                  child: _RestaurantFeedStatusOverlay(
                    isLoading: _isLoadingFeedVideos,
                    message: _feedVideosError ?? _emptyFeedMessage(),
                    onRetry: _refreshRestaurantVideos,
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
                          onTabSelected: _onTopFeedTabSelected,
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
        onManageLoyaltyOffers: _openLoyaltyOffersScreen,
        onOpenFollowers: () =>
            _openFollowersList(restaurantName: _profileInfo.name),
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
                      menuItems: _menuItemsForDisplay,
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
    final analytics = _restaurantAnalytics;
    final completedOrdersToday =
        analytics?.metricValue('order_volume').round() ??
        _restaurantOrders.where((order) => order.isCompleted).length;
    final ordersInProgress = _restaurantOrders
        .where((order) => order.isActive)
        .length;
    final revenueToday =
        analytics?.metricValue('total_revenue') ??
        _restaurantOrders.fold<double>(
          0,
          (total, order) => total + (order.total ?? 0),
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
                      isRefreshing: _isRefreshingMenu || _isRefreshingDashboard,
                      ordersCompletedToday: completedOrdersToday,
                      revenueToday: revenueToday,
                      ordersInProgress: ordersInProgress,
                      selectedVideoName: _selectedPostVideo?.name,
                      selectedVideoSizeBytes: _selectedPostVideo?.size,
                      isPickingVideo: _isPickingPostVideo,
                      isCreatingPost: _isCreatingPost,
                      onSelectVideo: _pickPostVideo,
                      onClearVideo: _clearSelectedPostVideo,
                      onRefresh: () async {
                        await Future.wait<void>([
                          _refreshRestaurantMenu(force: true),
                          _refreshDashboardData(),
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
    final videoPath = selectedVideo.path?.trim() ?? '';
    if (videoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This platform did not provide a video file path.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final session = await _resolveSession();
    if (session == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to upload videos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isCreatingPost = true);
    try {
      final title = composerResult.caption.trim().isEmpty
          ? selectedVideo.name
          : composerResult.caption.trim();
      final created = await _ownerApiService.createVideo(
        session: session,
        videoPath: videoPath,
        title: title,
        description: composerResult.hashtags,
        status: 'published',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedVideos.insert(
          0,
          _UploadedRestaurantVideo(
            backendId: created.id,
            name: created.title,
            sizeBytes: selectedVideo.size,
            uploadedAt: created.createdAt ?? DateTime.now(),
            caption: created.description,
            hashtags: created.status,
            moderationLabel: created.moderationLabel,
            moderationReason: created.moderationReason,
            videoFilePath: created.playbackUrl.isEmpty
                ? videoPath
                : created.playbackUrl,
          ),
        );
        _selectedPostVideo = null;
        _selectedProfileTabIndex = 0;
        _isCreatingPost = false;
      });
      unawaited(_refreshRestaurantVideos());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video uploaded. Moderation status: ${created.moderationLabel}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreatingPost = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create the post: $error'),
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

  int _computeOrdersCompletedToday(List<RestaurantMenuItem> items) {
    final backendSignal = items
        .map((item) => item.ordersCount ?? 0)
        .fold<int>(0, (total, value) => total + value);
    if (backendSignal <= 0) {
      return 28;
    }
    return (backendSignal * 0.08).round().clamp(8, 320).toInt();
  }

  // ignore: unused_element
  int _computeOrdersInProgress(int completedToday) {
    return (completedToday * 0.34).round().clamp(3, 120).toInt();
  }

  double _computeRevenueToday({
    required int completedToday,
    required double? averagePrice,
  }) {
    final estimatedTicketSize = averagePrice ?? 12.5;
    return completedToday * estimatedTicketSize;
  }
}

class _FeedVideoPostData {
  const _FeedVideoPostData({
    required this.videoUrl,
    required this.postId,
    this.thumbnailUrl,
  });

  factory _FeedVideoPostData.fromFeedItem(CustomerVideoFeedItem item) {
    return _FeedVideoPostData(
      videoUrl: item.playbackUrl,
      postId: item.id,
      thumbnailUrl: item.thumbnailUrl,
    );
  }

  factory _FeedVideoPostData.fromOwnerVideo(RestaurantVideoItem item) {
    final postId = item.id.trim();
    return _FeedVideoPostData(
      videoUrl: item.playbackUrl,
      postId: postId.isEmpty
          ? 'restaurant-owner-video-${item.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}'
          : postId,
      thumbnailUrl: item.thumbnailUrl,
    );
  }

  final String videoUrl;
  final String postId;
  final String? thumbnailUrl;
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

class _RestaurantFeedStatusOverlay extends StatelessWidget {
  const _RestaurantFeedStatusOverlay({
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
                const CircularProgressIndicator(color: Color(0xFFFF7E4D))
              else ...[
                const Icon(
                  Icons.video_library_outlined,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
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
                    selected: true,
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
        if (post.audioLabel.trim().isNotEmpty) ...[
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
    required this.onReport,
  });

  final _ResponsiveMetrics metrics;
  final DemoFeedPost post;
  final VoidCallback onOpenRestaurant;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;
  final VoidCallback onReport;

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
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.flag_outlined,
            value: 'Report',
            metrics: metrics,
            onTap: onReport,
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
  final _controller = TextEditingController();
  final bool _isSending = false;

  late List<DemoComment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = const <DemoComment>[];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Commenting from restaurant accounts is not available yet.',
          ),
        ),
      );
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
                                          PopupMenuButton<String>(
                                            tooltip: 'More actions',
                                            onSelected: (value) {
                                              if (value == 'report') {
                                                showReportSheet(
                                                  context,
                                                  itemType:
                                                      ReportItemType.comment,
                                                  itemId: comment.id,
                                                  itemTitle: comment.authorName,
                                                );
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem<String>(
                                                value: 'report',
                                                child: Text('Report comment'),
                                              ),
                                            ],
                                            icon: const Icon(
                                              Icons.more_vert_rounded,
                                              size: 18,
                                              color: Color(0xFF9E8A7E),
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
