part of '../user_home_screen.dart';

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

  Future<void> _toggleFollow(DemoFeedPost post) async {
    await _repository.toggleFollow(post.id);
    if (!mounted) {
      return;
    }
    _refreshFollowedRestaurants();
  }

  Future<void> _confirmAndUnfollow(DemoFeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unfollow restaurant'),
          content: Text('Unfollow ${post.restaurantName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E4D),
              ),
              child: const Text('Unfollow'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final previous = List<DemoFeedPost>.from(_followedRestaurants);
    setState(() {
      _followedRestaurants.removeWhere((item) => item.id == post.id);
    });
    try {
      await _toggleFollow(post);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Unfollowed ${post.restaurantName}.')),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _followedRestaurants = previous;
      });
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not unfollow right now. Please try again.'),
          ),
        );
    }
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
                            onUnfollow: () => _confirmAndUnfollow(post),
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
  const _FollowingRestaurantTile({
    required this.post,
    required this.onTap,
    required this.onUnfollow,
  });

  final DemoFeedPost post;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

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
              OutlinedButton(
                onPressed: onUnfollow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7E4D),
                  side: const BorderSide(color: Color(0xFFFFD3BF)),
                  minimumSize: const Size(82, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Unfollow',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
    this.userEmail,
    this.userAvatarUrl,
    this.userAvatarBytes,
  });

  final String userName;
  final VoidCallback onEditProfile;
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
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
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
            builder: (_) => const _CustomerHelpSupportScreen(),
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
  const _CustomerHelpSupportScreen();

  @override
  State<_CustomerHelpSupportScreen> createState() =>
      _CustomerHelpSupportScreenState();
}

class _CustomerHelpSupportScreenState
    extends State<_CustomerHelpSupportScreen> {
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
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  bool _isValidName(String value) {
    return RegExp(r"^[A-Za-z][A-Za-z\s'.-]{1,49}$").hasMatch(value.trim());
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 15;
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
    if (data.fullName.isEmpty ||
        data.email.isEmpty ||
        data.phone.isEmpty ||
        data.country.isEmpty ||
        data.city.isEmpty ||
        data.streetAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: Color(0xFFB7372B),
        ),
      );
      return;
    }
    if (!_isValidName(data.fullName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid name using letters, spaces, apostrophes, or dashes.',
          ),
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
    if (!_isValidPhone(data.phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number.'),
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'.-]")),
                  LengthLimitingTextInputFormatter(50),
                ],
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'-]")),
                        LengthLimitingTextInputFormatter(40),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CustomerEditProfileField(
                      label: 'City',
                      hint: 'Beirut',
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'-]")),
                        LengthLimitingTextInputFormatter(40),
                      ],
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
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
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
            textCapitalization: textCapitalization,
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

