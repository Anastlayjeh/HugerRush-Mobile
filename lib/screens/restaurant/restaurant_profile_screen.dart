part of '../restaurant_feed_screen.dart';

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
                                          onReport: () {},
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

  static const List<_PopularMenuItemData> _popularItems = [
    _PopularMenuItemData(
      title: 'Pepperoni Feast',
      subtitle: 'Extra cheese, smoky beef, chili flakes',
      price: '\$14.99',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1000&q=80',
    ),
    _PopularMenuItemData(
      title: 'Classic Burger',
      subtitle: 'Beef patty, lettuce, cheddar, special sauce',
      price: '\$12.40',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1000&q=80',
    ),
    _PopularMenuItemData(
      title: 'Creamy Carbonara',
      subtitle: 'Fresh pasta, parmesan, black pepper',
      price: '\$13.25',
      imageUrl:
          'https://images.unsplash.com/photo-1612874742237-6526221588e3?auto=format&fit=crop&w=1000&q=80',
    ),
  ];

  static const List<_RestaurantReviewData> _sampleReviews = [
    _RestaurantReviewData(
      customerName: 'Lina M.',
      rating: 4.8,
      comment:
          'Pizza arrived hot and fresh. Crust was perfect and delivery was very quick.',
      timeLabel: '2h ago',
      orderLabel: '#4731',
    ),
    _RestaurantReviewData(
      customerName: 'Rami A.',
      rating: 4.6,
      comment:
          'Great flavor and portion size. Please keep the same quality for the fries.',
      timeLabel: '5h ago',
      orderLabel: '#4728',
    ),
    _RestaurantReviewData(
      customerName: 'Maya K.',
      rating: 5.0,
      comment:
          'Excellent as always. Packaging was clean and food arrived on time.',
      timeLabel: 'Yesterday',
      orderLabel: '#4722',
    ),
    _RestaurantReviewData(
      customerName: 'Karim D.',
      rating: 4.4,
      comment: 'Burger was tasty and juicy. I would love a bit more sauce.',
      timeLabel: 'Yesterday',
      orderLabel: '#4713',
    ),
  ];

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
    return [
      Text(
        'Popular Choices',
        style: TextStyle(
          color: const Color(0xFF1F1B19),
          fontSize: sectionTitleSize * 0.53,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: _clampDouble(10 * metrics.scale, 7, 10)),
      Text(
        'Best performing dishes this week',
        style: TextStyle(
          color: const Color(0xFF8E7E72),
          fontSize: subtitleSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
      SizedBox(
        height: popularCardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _popularItems.length,
          separatorBuilder: (_, index) => SizedBox(width: itemGap),
          itemBuilder: (context, index) {
            final popularItem = _popularItems[index];
            return _PopularMenuCard(
              metrics: metrics,
              item: popularItem,
              onTap: () => onOpenMenuItemDetails(
                popularItem.toRestaurantMenuItem(index),
              ),
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
    final avgRating =
        _sampleReviews.fold<double>(
          0,
          (total, review) => total + review.rating,
        ) /
        _sampleReviews.length;

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
      ...List.generate(_sampleReviews.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _sampleReviews.length - 1
                ? 0
                : _clampDouble(10 * metrics.scale, 8, 10),
          ),
          child: _ReviewCard(metrics: metrics, review: _sampleReviews[index]),
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
    required this.onLogout,
  });

  final String restaurantName;
  final String restaurantHandle;
  final String? profileImagePath;
  final VoidCallback onEditProfile;
  final VoidCallback onManageMenu;
  final VoidCallback onOpenFollowers;
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
              builder: (_) => const _RestaurantHelpSupportScreen(),
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
  const _RestaurantHelpSupportScreen();

  @override
  State<_RestaurantHelpSupportScreen> createState() =>
      _RestaurantHelpSupportScreenState();
}

class _RestaurantHelpSupportScreenState
    extends State<_RestaurantHelpSupportScreen> {
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
                    onPressed: () {
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

  bool _isValidRestaurantName(String value) {
    return RegExp(r"^[A-Za-z0-9][A-Za-z0-9\s'.&-]{1,79}$").hasMatch(
      value.trim(),
    );
  }

  bool _isValidLocationText(String value) {
    return RegExp(r"^[A-Za-z0-9][A-Za-z0-9\s'.,#/-]{1,79}$").hasMatch(
      value.trim(),
    );
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 15;
  }

  bool _isValidPostalCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 3 && digits.length <= 10;
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

    if (!_isValidRestaurantName(data.restaurantName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid restaurant name using letters, numbers, and basic punctuation.',
          ),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }

    if (!_isValidPhone(data.phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }

    if (!_isValidPostalCode(data.postalCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid postal code.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }

    if (!_isValidLocationText(data.country) ||
        !_isValidLocationText(data.city) ||
        !_isValidLocationText(data.street)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please use valid location text for country, city, and street.',
          ),
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[A-Za-z0-9\s'.&-]"),
                  ),
                  LengthLimitingTextInputFormatter(80),
                ],
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Cuisine Type',
                hint: 'Italian',
                controller: _cuisineTypeController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s&/-]")),
                  LengthLimitingTextInputFormatter(60),
                ],
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EditProfileField(
                      label: 'Country',
                      hint: 'Lebanon',
                      controller: _countryController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z\s'-]"),
                        ),
                        LengthLimitingTextInputFormatter(40),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EditProfileField(
                      label: 'City',
                      hint: 'Beirut',
                      controller: _cityController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z\s'-]"),
                        ),
                        LengthLimitingTextInputFormatter(40),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Street',
                hint: 'Hamra St, Bldg 42',
                controller: _streetController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(80),
                ],
              ),
              const SizedBox(height: 12),
              _EditProfileField(
                label: 'Postal Code',
                hint: '1103',
                keyboardType: TextInputType.number,
                controller: _postalCodeController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
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
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
            inputFormatters: inputFormatters,
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

