import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/demo_app_models.dart';
import '../services/demo_app_repository.dart';
import 'login_screen.dart';
import '../services/restaurant_menu_api_service.dart';
import '../services/restaurant_profile_api_service.dart';
import 'app_support_screens.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

class RestaurantFeedScreen extends StatefulWidget {
  const RestaurantFeedScreen({
    super.key,
    required this.restaurantName,
    this.authToken,
    this.initialUserData,
  });

  final String restaurantName;
  final String? authToken;
  final Map<String, dynamic>? initialUserData;

  @override
  State<RestaurantFeedScreen> createState() => _RestaurantFeedScreenState();
}

class _RestaurantFeedScreenState extends State<RestaurantFeedScreen> {
  static const int _menuTabIndex = 1;
  static const int _dashboardTabIndex = 2;
  static const int _messagesTabIndex = 3;
  static const int _profileTabIndex = 4;
  static const int _profileMenuTabIndex = 1;
  static const List<RestaurantMenuItem> _fallbackMenuItems = [
    RestaurantMenuItem(
      id: 'margherita-special',
      title: 'Margherita Special',
      description:
          'Fresh basil, mozzarella, tomato sauce, and olive oil drizzle.',
      price: 11.00,
      imageUrl:
          'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=900&q=80',
      category: 'Pizza',
      isAvailable: true,
      isPopular: true,
      rating: 4.8,
      ordersCount: 148,
    ),
    RestaurantMenuItem(
      id: 'crispy-wings',
      title: 'Crispy Wings (6pcs)',
      description: 'Golden fried wings served with spicy dipping sauce.',
      price: 9.50,
      imageUrl:
          'https://images.unsplash.com/photo-1562967916-eb82221dfb92?auto=format&fit=crop&w=900&q=80',
      category: 'Starters',
      isAvailable: true,
      isPopular: false,
      rating: 4.6,
      ordersCount: 96,
    ),
    RestaurantMenuItem(
      id: 'creamy-carbonara',
      title: 'Creamy Carbonara',
      description: 'Spaghetti tossed in creamy parmesan sauce and herbs.',
      price: 13.25,
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?auto=format&fit=crop&w=900&q=80',
      category: 'Pasta',
      isAvailable: true,
      isPopular: true,
      rating: 4.9,
      ordersCount: 121,
    ),
    RestaurantMenuItem(
      id: 'smoked-bbq-burger',
      title: 'Smoked BBQ Burger',
      description: 'Beef patty, cheddar, caramelized onions, and BBQ sauce.',
      price: 12.75,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      category: 'Burgers',
      isAvailable: true,
      isPopular: true,
      rating: 4.7,
      ordersCount: 134,
    ),
    RestaurantMenuItem(
      id: 'garden-caesar-salad',
      title: 'Garden Caesar Salad',
      description:
          'Romaine lettuce, parmesan flakes, croutons, and Caesar dressing.',
      price: 8.40,
      imageUrl:
          'https://images.unsplash.com/photo-1546793665-c74683f339c1?auto=format&fit=crop&w=900&q=80',
      category: 'Salads',
      isAvailable: true,
      isPopular: false,
      rating: 4.4,
      ordersCount: 58,
    ),
    RestaurantMenuItem(
      id: 'double-chocolate-brownie',
      title: 'Double Chocolate Brownie',
      description:
          'Warm brownie served with chocolate sauce and vanilla cream.',
      price: 6.80,
      imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=900&q=80',
      category: 'Desserts',
      isAvailable: true,
      isPopular: false,
      rating: 4.8,
      ordersCount: 73,
    ),
  ];

  final _profileScaffoldKey = GlobalKey<ScaffoldState>();
  final _demoRepository = DemoAppRepository.instance;
  int _selectedBottomIndex = 0;
  int _selectedProfileTabIndex = _profileMenuTabIndex;
  final _profileApiService = RestaurantProfileApiService();
  final _menuApiService = RestaurantMenuApiService();
  PlatformFile? _selectedPostVideo;
  bool _isPickingPostVideo = false;
  bool _isCreatingPost = false;
  final List<_UploadedRestaurantVideo> _uploadedVideos =
      <_UploadedRestaurantVideo>[];
  late DemoFeedPost _vendorFeedPost;

  late _RestaurantProfileInfo _profileInfo;
  bool _isRefreshingProfile = false;
  String? _profileSyncError;
  List<RestaurantMenuItem> _restaurantMenuItems = const [];
  bool _isRefreshingMenu = false;
  bool _hasLoadedMenu = false;
  String? _menuSyncError;

  @override
  void initState() {
    super.initState();
    _vendorFeedPost = _demoRepository.getFeedPost(
      following: true,
      vendorView: true,
    );
    _profileInfo = _RestaurantProfileInfo.fromData(
      primary: widget.initialUserData,
      fallbackName: widget.restaurantName,
    );
    _refreshRestaurantProfile();
  }

  @override
  void dispose() {
    _profileApiService.dispose();
    _menuApiService.dispose();
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
  List<RestaurantMenuItem> get _menuItemsForDisplay =>
      _restaurantMenuItems.isEmpty ? _fallbackMenuItems : _restaurantMenuItems;

  void _syncVendorFeedPost() {
    _vendorFeedPost = _demoRepository.getFeedPost(
      following: true,
      vendorView: true,
    );
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

  Future<void> _openRestaurantDetails() async {
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
        .getComments(_vendorFeedPost.id)
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

    await showRestaurantProfilePopup(
      context,
      restaurantName: _vendorFeedPost.restaurantName,
      handle: _vendorFeedPost.restaurantHandle,
      rating: _vendorFeedPost.rating,
      caption: _vendorFeedPost.caption,
      cuisineSummary: _profileInfo.cuisineSummary,
      phoneLabel: _profileInfo.phoneLabel,
      locationLabel: _profileInfo.locationLabel,
      followersCountLabel: _profileInfo.followersCountLabel,
      profileImageUrl: _profileInfo.coverImageUrl,
      menuItems: _menuItemsForDisplay,
      uploadedVideos: videoPreviews,
      reviews: reviewPreviews,
    );
  }

  Future<void> _toggleVendorFollow() async {
    final updated = await _demoRepository.toggleFollow(_vendorFeedPost.id);
    if (!mounted) {
      return;
    }
    setState(() => _vendorFeedPost = updated);
  }

  Future<void> _toggleVendorLike() async {
    final updated = await _demoRepository.toggleLike(_vendorFeedPost.id);
    if (!mounted) {
      return;
    }
    setState(() => _vendorFeedPost = updated);
  }

  Future<void> _openVendorComments() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommentsScreen(
          postId: _vendorFeedPost.id,
          postTitle: _vendorFeedPost.restaurantName,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(_syncVendorFeedPost);
  }

  Future<void> _shareVendorPromo() async {
    await showShareFallbackDialog(
      context,
      title: _vendorFeedPost.restaurantName,
      body: _vendorFeedPost.caption,
    );
  }

  Future<void> _openVendorPromoDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PromoDetailsScreen(
          title: _vendorFeedPost.restaurantName,
          caption: _vendorFeedPost.caption,
          audioLabel: _vendorFeedPost.audioLabel,
        ),
      ),
    );
  }

  Future<void> _openCompletedOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderListScreen(
          title: 'Completed Orders',
          orders: _demoRepository.getOrders(completed: true),
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
        builder: (_) => OrderListScreen(
          title: 'Orders In Progress',
          orders: _demoRepository.getOrders(completed: false),
        ),
      ),
    );
  }

  Future<void> _openOrderManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrderManagementScreen(orders: _demoRepository.getOrders()),
      ),
    );
  }

  Future<void> _openOrderDetails(String orderId) async {
    final order = _demoRepository.findOrder(orderId);
    if (order == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  void _onBottomNavSelected(int index) {
    setState(() => _selectedBottomIndex = index);
    if (index == _menuTabIndex || index == _dashboardTabIndex) {
      _refreshRestaurantMenu();
    }
  }

  void _openMenuSection() {
    _onBottomNavSelected(_menuTabIndex);
    _refreshRestaurantMenu(force: true);
  }

  void _onProfileTabSelected(int index) {
    setState(() => _selectedProfileTabIndex = index);
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

  void _openProfileSettingsDrawer() {
    _profileScaffoldKey.currentState?.openEndDrawer();
  }

  void _logoutToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
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
        _restaurantMenuItems = _fallbackMenuItems;
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
        _restaurantMenuItems = items.isEmpty ? _fallbackMenuItems : items;
        _hasLoadedMenu = true;
        _isRefreshingMenu = false;
        _menuSyncError = items.isEmpty
            ? 'No backend menu items were returned, so sample dishes are shown.'
            : null;
      });
    } on RestaurantMenuApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantMenuItems = _fallbackMenuItems;
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
      body: Stack(
        children: [
          const Positioned.fill(child: _FeedBackground()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x0D000000),
                    const Color(0x7A000000),
                    const Color(0xCF00131A),
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _ResponsiveMetrics.from(constraints);
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    metrics.topPadding,
                    metrics.horizontalPadding,
                    metrics.bottomPadding,
                  ),
                  child: Column(
                    children: [
                      _TopControls(
                        metrics: metrics,
                        onOpenSearch: _openSearch,
                        onOpenNotifications: _openNotifications,
                        onOpenFeedInfo: _openVendorPromoDetails,
                      ),
                      SizedBox(height: metrics.gapAfterTop),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _FeedDetails(
                                  post: _vendorFeedPost,
                                  metrics: metrics,
                                  onOpenRestaurant: _openRestaurantDetails,
                                  onOpenAudio: _openVendorPromoDetails,
                                ),
                              ),
                              SizedBox(width: metrics.railGap),
                              _ActionRail(
                                metrics: metrics,
                                post: _vendorFeedPost,
                                onOpenRestaurant: _openRestaurantDetails,
                                onToggleFollow: _toggleVendorFollow,
                                onToggleLike: _toggleVendorLike,
                                onOpenComments: _openVendorComments,
                                onShare: _shareVendorPromo,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.sectionGapSmall),
                      _BottomNavBar(
                        metrics: metrics,
                        selectedIndex: _selectedBottomIndex,
                        onSelected: _onBottomNavSelected,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScaffold() {
    return Scaffold(
      key: _profileScaffoldKey,
      backgroundColor: const Color(0xFFF8EFE8),
      endDrawer: _ProfileSettingsDrawer(
        onEditProfile: _openEditProfile,
        onLogout: _logoutToLogin,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ResponsiveMetrics.from(constraints);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                metrics.topPadding,
                metrics.horizontalPadding,
                metrics.bottomPadding,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _ProfileSection(
                      metrics: metrics,
                      profileInfo: _profileInfo,
                      isSyncingProfile: _isRefreshingProfile,
                      profileSyncError: _profileSyncError,
                      onRetryProfileSync: _refreshRestaurantProfile,
                      onManageFullMenu: _openMenuSection,
                      onOpenSettings: _openProfileSettingsDrawer,
                      selectedTabIndex: _selectedProfileTabIndex,
                      onTabSelected: _onProfileTabSelected,
                      uploadedVideos: _uploadedVideos,
                    ),
                  ),
                  SizedBox(height: metrics.sectionGapSmall),
                  _BottomNavBar(
                    metrics: metrics,
                    selectedIndex: _selectedBottomIndex,
                    onSelected: _onBottomNavSelected,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ResponsiveMetrics.from(constraints);
            final menuItems = _menuItemsForDisplay;
            final availableCount = menuItems
                .where((item) => item.isAvailable)
                .length;
            final popularCount = menuItems
                .where((item) => item.isPopular)
                .length;
            final averagePrice = _computeAveragePrice(menuItems);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                metrics.topPadding,
                metrics.horizontalPadding,
                metrics.bottomPadding,
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
                  SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                  _MenuStatsRow(
                    metrics: metrics,
                    totalItems: menuItems.length,
                    availableItems: availableCount,
                    popularItems: popularCount,
                    averagePrice: averagePrice,
                  ),
                  SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                  Expanded(
                    child: _MenuSection(
                      metrics: metrics,
                      items: menuItems,
                      isLoading: _isRefreshingMenu,
                      errorMessage: _menuSyncError,
                      onRetry: () => _refreshRestaurantMenu(force: true),
                    ),
                  ),
                  SizedBox(height: metrics.sectionGapSmall),
                  _BottomNavBar(
                    metrics: metrics,
                    selectedIndex: _selectedBottomIndex,
                    onSelected: _onBottomNavSelected,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardScaffold() {
    final completedOrdersToday = _computeOrdersCompletedToday(
      _restaurantMenuItems,
    );
    final ordersInProgress = _computeOrdersInProgress(completedOrdersToday);
    final revenueToday = _computeRevenueToday(
      completedToday: completedOrdersToday,
      averagePrice: _computeAveragePrice(_restaurantMenuItems),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ResponsiveMetrics.from(constraints);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                metrics.topPadding,
                metrics.horizontalPadding,
                metrics.bottomPadding,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _DashboardSection(
                      metrics: metrics,
                      restaurantName: _restaurantName,
                      isRefreshing: _isRefreshingMenu,
                      ordersCompletedToday: completedOrdersToday,
                      revenueToday: revenueToday,
                      ordersInProgress: ordersInProgress,
                      selectedVideoName: _selectedPostVideo?.name,
                      selectedVideoSizeBytes: _selectedPostVideo?.size,
                      isPickingVideo: _isPickingPostVideo,
                      isCreatingPost: _isCreatingPost,
                      onSelectVideo: _pickPostVideo,
                      onClearVideo: _clearSelectedPostVideo,
                      onRefresh: () => _refreshRestaurantMenu(force: true),
                      onCreatePost: _createVideoPost,
                      onOpenCompletedOrders: _openCompletedOrders,
                      onOpenRevenueAnalytics: _openRevenueAnalytics,
                      onOpenActiveOrders: _openActiveOrders,
                      onOpenOrderManagement: _openOrderManagement,
                      onOpenOrderDetails: _openOrderDetails,
                    ),
                  ),
                  SizedBox(height: metrics.sectionGapSmall),
                  _BottomNavBar(
                    metrics: metrics,
                    selectedIndex: _selectedBottomIndex,
                    onSelected: _onBottomNavSelected,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ResponsiveMetrics.from(constraints);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                metrics.topPadding,
                metrics.horizontalPadding,
                metrics.bottomPadding,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _MessagesSection(
                      metrics: metrics,
                      restaurantName: _restaurantName,
                    ),
                  ),
                  SizedBox(height: metrics.sectionGapSmall),
                  _BottomNavBar(
                    metrics: metrics,
                    selectedIndex: _selectedBottomIndex,
                    onSelected: _onBottomNavSelected,
                  ),
                ],
              ),
            );
          },
        ),
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
    setState(() => _isCreatingPost = true);
    try {
      final created = await _demoRepository.createPost(
        fileName: selectedVideo.name,
        fileSizeBytes: selectedVideo.size,
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

  int _computeOrdersCompletedToday(List<RestaurantMenuItem> items) {
    final backendSignal = items
        .map((item) => item.ordersCount ?? 0)
        .fold<int>(0, (total, value) => total + value);
    if (backendSignal <= 0) {
      return 28;
    }
    return (backendSignal * 0.08).round().clamp(8, 320).toInt();
  }

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

class _FeedBackground extends StatelessWidget {
  const _FeedBackground();

  static const _pizzaImage =
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pizzaDiameter = _clampDouble(width * 1.72, width * 1.35, 760);
        final verticalShift = _clampDouble(height * 0.20, 110, 190);

        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
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
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, verticalShift),
                child: ClipOval(
                  child: SizedBox(
                    width: pizzaDiameter,
                    height: pizzaDiameter,
                    child: Image.network(
                      _pizzaImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFFF1C76A),
                                Color(0xFFD1642E),
                                Color(0xFF863A1E),
                              ],
                            ),
                          ),
                        );
                      },
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

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.metrics,
    required this.restaurantName,
    required this.isRefreshing,
    required this.ordersCompletedToday,
    required this.revenueToday,
    required this.ordersInProgress,
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
  final int ordersCompletedToday;
  final double revenueToday;
  final int ordersInProgress;
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
    required this.onOpenOrderManagement,
    required this.onOpenOrderDetails,
  });

  final _ResponsiveMetrics metrics;
  final int ordersInProgress;
  final Future<void> Function() onOpenOrderManagement;
  final Future<void> Function(String orderId) onOpenOrderDetails;

  static const List<_DashboardLiveOrderData> _sampleOrders = [
    _DashboardLiveOrderData(
      orderId: '#4735',
      customerName: 'Lina M.',
      itemSummary: '2x Pepperoni Feast, 1x Cola',
      etaLabel: 'ETA 14m',
      statusLabel: 'Cooking',
      highlighted: true,
    ),
    _DashboardLiveOrderData(
      orderId: '#4733',
      customerName: 'Rami A.',
      itemSummary: '1x Chicken Wrap, 1x Fries',
      etaLabel: 'ETA 8m',
      statusLabel: 'Packing',
      highlighted: false,
    ),
    _DashboardLiveOrderData(
      orderId: '#4730',
      customerName: 'Jad F.',
      itemSummary: '1x Family Box, 2x Garlic Dip',
      etaLabel: 'ETA 22m',
      statusLabel: 'Queued',
      highlighted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cardRadius = _clampDouble(22 * metrics.scale, 16, 22);
    final listGap = _clampDouble(8 * metrics.scale, 6, 8);
    final displayCount = _sampleOrders
        .take(ordersInProgress.clamp(1, _sampleOrders.length))
        .toList();

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
          ...List.generate(displayCount.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == displayCount.length - 1 ? 0 : listGap,
              ),
              child: _DashboardLiveOrderRow(
                metrics: metrics,
                data: displayCount[index],
                onTap: () => onOpenOrderDetails(displayCount[index].orderId),
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
  const _MessagesSection({required this.metrics, required this.restaurantName});

  final _ResponsiveMetrics metrics;
  final String restaurantName;

  @override
  State<_MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<_MessagesSection> {
  final _repository = DemoAppRepository.instance;

  List<DemoConversationThread> _threads = const <DemoConversationThread>[];
  MessageFilterType _selectedFilter = MessageFilterType.all;
  String? _selectedCustomerName;
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
  });

  final String name;
  final int sizeBytes;
  final DateTime uploadedAt;
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.metrics,
    required this.profileInfo,
    required this.isSyncingProfile,
    required this.profileSyncError,
    required this.onRetryProfileSync,
    required this.onManageFullMenu,
    required this.onOpenSettings,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.uploadedVideos,
  });

  final _ResponsiveMetrics metrics;
  final _RestaurantProfileInfo profileInfo;
  final bool isSyncingProfile;
  final String? profileSyncError;
  final VoidCallback onRetryProfileSync;
  final VoidCallback onManageFullMenu;
  final VoidCallback onOpenSettings;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final List<_UploadedRestaurantVideo> uploadedVideos;

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
            return _PopularMenuCard(
              metrics: metrics,
              item: _popularItems[index],
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
  });

  final _ResponsiveMetrics metrics;
  final _UploadedRestaurantVideo video;
  final int index;

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
    return Container(
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
          SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(12 * metrics.scale, 10, 12),
              vertical: _clampDouble(9 * metrics.scale, 7, 9),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.storage_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(18 * metrics.scale, 14, 18),
                ),
                SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                Expanded(
                  child: Text(
                    'Menu data is synced from your SQL-backed backend API.',
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

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.metrics,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final _ResponsiveMetrics metrics;
  final List<RestaurantMenuItem> items;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;

    if (isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7E4D)),
      );
    }

    return Column(
      children: [
        if (hasError) ...[
          _MenuSyncBanner(
            metrics: metrics,
            message: errorMessage!.trim(),
            onRetry: onRetry,
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
        ],
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF7E4D),
            onRefresh: onRetry,
            child: items.isEmpty
                ? _EmptyMenuState(metrics: metrics)
                : ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(
                      height: _clampDouble(10 * metrics.scale, 8, 10),
                    ),
                    itemBuilder: (context, index) {
                      return _ManagedMenuItemCard(
                        metrics: metrics,
                        item: items[index],
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
  const _EmptyMenuState({required this.metrics});

  final _ResponsiveMetrics metrics;

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
          'No menu items found',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF2A231E),
            fontSize: _clampDouble(20 * metrics.scale, 15, 20),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
        Text(
          'Add dishes from your backend and pull to refresh.',
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
  const _ManagedMenuItemCard({required this.metrics, required this.item});

  final _ResponsiveMetrics metrics;
  final RestaurantMenuItem item;

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = _clampDouble(90 * metrics.scale, 72, 90);
    return Container(
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
                          fontSize: _clampDouble(18 * metrics.scale, 14, 18),
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
    required this.onOpenSettings,
  });

  final _ResponsiveMetrics metrics;
  final _RestaurantProfileInfo profileInfo;
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _initials(profileInfo.name),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            _clampDouble(26 * metrics.scale, 18, 26) * 0.55,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: _clampDouble(2 * metrics.scale, 1, 2)),
                    Text(
                      '@${profileInfo.handle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xE0FFFFFF),
                        fontSize: _clampDouble(11 * metrics.scale, 8, 11) * 0.7,
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
    required this.onEditProfile,
    required this.onLogout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Navigation',
                style: TextStyle(
                  color: Color(0xFF1F1B19),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFFF7E4D),
                ),
                title: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Color(0xFF2E2521),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onEditProfile();
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFB7372B),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFF2E2521),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  });

  final String restaurantName;
  final String cuisineType;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String street;
  final String postalCode;

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
        _normalized(postalCode) == _normalized(other.postalCode);
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
  });

  final _ResponsiveMetrics metrics;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
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
  const _PopularMenuCard({required this.metrics, required this.item});

  final _ResponsiveMetrics metrics;
  final _PopularMenuItemData item;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _clampDouble(198 * metrics.scale, 156, 198);
    return SizedBox(
      width: cardWidth,
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
                                colors: [Color(0xFFF3C1A8), Color(0xFFEFB18E)],
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
}

class _RestaurantProfileInfo {
  const _RestaurantProfileInfo({
    required this.name,
    required this.handle,
    required this.cuisineSummary,
    required this.ratingLabel,
    required this.phoneLabel,
    required this.locationLabel,
    required this.followersCountLabel,
    required this.coverImageUrl,
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

  final String name;
  final String handle;
  final String cuisineSummary;
  final String ratingLabel;
  final String phoneLabel;
  final String locationLabel;
  final String followersCountLabel;
  final String coverImageUrl;
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

    return _RestaurantProfileInfo(
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

  double get navHeight => _clampDouble(96 * scale, 74, 96);
  double get navRadius => _clampDouble(30 * scale, 22, 30);
  double get navIconSize => _clampDouble(31 * scale, 22, 31);
  double get navLabelSize => _clampDouble(13 * scale, 9.5, 13);
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.metrics,
    required this.onOpenSearch,
    required this.onOpenNotifications,
    required this.onOpenFeedInfo,
  });

  final _ResponsiveMetrics metrics;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenFeedInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.search_rounded,
          metrics: metrics,
          onTap: onOpenSearch,
          tooltip: 'Search',
        ),
        SizedBox(width: metrics.sideGap),
        Expanded(
          child: Center(
            child: _TopTab(
              label: 'For You',
              selected: true,
              metrics: metrics,
              onTap: onOpenFeedInfo,
            ),
          ),
        ),
        SizedBox(width: metrics.sideGap),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          metrics: metrics,
          onTap: onOpenNotifications,
          tooltip: 'Notifications',
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
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '@',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: metrics.handleAtFontSize,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: post.restaurantHandle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: metrics.handleFontSize,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
            isFollowing: post.isFollowing,
            onOpenRestaurant: onOpenRestaurant,
            onToggleFollow: onToggleFollow,
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
    required this.isFollowing,
    required this.onOpenRestaurant,
    required this.onToggleFollow,
  });

  final _ResponsiveMetrics metrics;
  final bool isFollowing;
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
              'BELLA ITALIA',
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
                isFollowing ? Icons.check_rounded : Icons.add_rounded,
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.metrics,
    required this.selectedIndex,
    required this.onSelected,
  });

  final _ResponsiveMetrics metrics;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

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

    return Container(
      height: metrics.navHeight,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.compact ? 6 : 10,
        vertical: metrics.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EFE8),
        borderRadius: BorderRadius.circular(metrics.navRadius),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: metrics.navIconSize),
          SizedBox(height: _clampDouble(6 * metrics.scale, 2, 6)),
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
