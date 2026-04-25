import 'package:flutter/material.dart';

import '../services/restaurant_menu_api_service.dart';
import '../services/restaurant_profile_api_service.dart';

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
  static const int _profileTabIndex = 4;

  int _selectedTopTab = 1;
  int _selectedBottomIndex = 0;
  final _profileApiService = RestaurantProfileApiService();
  final _menuApiService = RestaurantMenuApiService();

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

  String get _restaurantHandle => _profileInfo.handle;

  bool get _isProfileTabSelected => _selectedBottomIndex == _profileTabIndex;
  bool get _isMenuTabSelected => _selectedBottomIndex == _menuTabIndex;

  void _onBottomNavSelected(int index) {
    setState(() => _selectedBottomIndex = index);
    if (index == _menuTabIndex) {
      _refreshRestaurantMenu();
    }
  }

  void _openMenuSection() {
    _onBottomNavSelected(_menuTabIndex);
    _refreshRestaurantMenu(force: true);
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

  @override
  Widget build(BuildContext context) {
    if (_isProfileTabSelected) {
      return _buildProfileScaffold();
    }
    if (_isMenuTabSelected) {
      return _buildMenuScaffold();
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
                        selectedTab: _selectedTopTab,
                        onTabSelected: (index) {
                          setState(() => _selectedTopTab = index);
                        },
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
                                  restaurantName: _restaurantHandle,
                                  metrics: metrics,
                                ),
                              ),
                              SizedBox(width: metrics.railGap),
                              _ActionRail(metrics: metrics),
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
                    child: _ProfileSection(
                      metrics: metrics,
                      profileInfo: _profileInfo,
                      isSyncingProfile: _isRefreshingProfile,
                      profileSyncError: _profileSyncError,
                      onRetryProfileSync: _refreshRestaurantProfile,
                      onManageFullMenu: _openMenuSection,
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
            final availableCount = _restaurantMenuItems
                .where((item) => item.isAvailable)
                .length;
            final popularCount = _restaurantMenuItems
                .where((item) => item.isPopular)
                .length;
            final averagePrice = _computeAveragePrice(_restaurantMenuItems);

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
                    totalItems: _restaurantMenuItems.length,
                    availableItems: availableCount,
                    popularItems: popularCount,
                    averagePrice: averagePrice,
                  ),
                  SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                  Expanded(
                    child: _MenuSection(
                      metrics: metrics,
                      items: _restaurantMenuItems,
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

  double? _computeAveragePrice(List<RestaurantMenuItem> items) {
    final prices = items.map((item) => item.price).whereType<double>().toList();
    if (prices.isEmpty) {
      return null;
    }
    final sum = prices.fold<double>(0, (value, item) => value + item);
    return sum / prices.length;
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.metrics,
    required this.profileInfo,
    required this.isSyncingProfile,
    required this.profileSyncError,
    required this.onRetryProfileSync,
    required this.onManageFullMenu,
  });

  final _ResponsiveMetrics metrics;
  final _RestaurantProfileInfo profileInfo;
  final bool isSyncingProfile;
  final String? profileSyncError;
  final VoidCallback onRetryProfileSync;
  final VoidCallback onManageFullMenu;

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

  static const List<_OwnerMenuItemData> _menuItems = [
    _OwnerMenuItemData(
      title: 'Margherita Special',
      description: 'Fresh basil, mozzarella, tomato sauce, olive oil drizzle.',
      price: '\$11.00',
      imageUrl:
          'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=800&q=80',
      tags: [
        _OwnerMenuTagData(
          label: 'VEG',
          backgroundColor: Color(0xFFE1F5E8),
          textColor: Color(0xFF2E9B57),
        ),
        _OwnerMenuTagData(
          label: 'Best Seller',
          backgroundColor: Color(0xFFEFEDEB),
          textColor: Color(0xFF7A6C61),
        ),
      ],
    ),
    _OwnerMenuItemData(
      title: 'Crispy Wings (6pcs)',
      description: 'Golden fried wings served with spicy dipping sauce.',
      price: '\$9.50',
      imageUrl:
          'https://images.unsplash.com/photo-1562967916-eb82221dfb92?auto=format&fit=crop&w=800&q=80',
      tags: [
        _OwnerMenuTagData(
          label: 'SPICY',
          backgroundColor: Color(0xFFFDE4E2),
          textColor: Color(0xFFC6463E),
        ),
      ],
    ),
    _OwnerMenuItemData(
      title: 'Creamy Carbonara',
      description: 'Spaghetti tossed in creamy parmesan sauce and herbs.',
      price: '\$13.25',
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?auto=format&fit=crop&w=800&q=80',
      tags: [
        _OwnerMenuTagData(
          label: 'Popular',
          backgroundColor: Color(0xFFE8EFF7),
          textColor: Color(0xFF43739C),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sectionGap = _clampDouble(24 * metrics.scale, 16, 24);
    final sectionTitleSize = _clampDouble(36 * metrics.scale, 24, 36);
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);
    final popularCardHeight = _clampDouble(246 * metrics.scale, 200, 246);
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
          ),
          SizedBox(height: sectionGap),
          _ProfileSectionTabs(metrics: metrics, selectedIndex: 1),
          SizedBox(height: sectionGap),
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
          Text(
            'Full Menu',
            style: TextStyle(
              color: const Color(0xFF1F1B19),
              fontSize: sectionTitleSize * 0.53,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 7, 10)),
          ...List.generate(_menuItems.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _menuItems.length - 1 ? 0 : itemGap,
              ),
              child: _OwnerMenuItemCard(
                metrics: metrics,
                item: _menuItems[index],
              ),
            );
          }),
          SizedBox(height: _clampDouble(18 * metrics.scale, 12, 18)),
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
                'Manage Full Menu',
                style: TextStyle(
                  fontSize: _clampDouble(22 * metrics.scale, 16, 22) * 0.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
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
        borderRadius: BorderRadius.circular(_clampDouble(24 * metrics.scale, 18, 24)),
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
        borderRadius: BorderRadius.circular(_clampDouble(18 * metrics.scale, 14, 18)),
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
                    separatorBuilder: (_, _) =>
                        SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
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
        borderRadius: BorderRadius.circular(_clampDouble(22 * metrics.scale, 18, 22)),
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
                        label: '${item.rating!.toStringAsFixed(1)}★',
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
              hasError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
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
  });

  final _ResponsiveMetrics metrics;
  final _RestaurantProfileInfo profileInfo;

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
                        _ProfileTopOverlayButton(
                          metrics: metrics,
                          icon: Icons.arrow_back_rounded,
                        ),
                        const Spacer(),
                        _ProfileTopOverlayButton(
                          metrics: metrics,
                          icon: Icons.search_rounded,
                        ),
                        SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                        _ProfileTopOverlayButton(
                          metrics: metrics,
                          icon: Icons.more_horiz_rounded,
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
                  Row(
                    children: [
                      Expanded(
                        child: _OwnerActionButton(
                          metrics: metrics,
                          label: 'Edit Profile',
                          outlined: true,
                        ),
                      ),
                      SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
                      Expanded(
                        child: _OwnerActionButton(
                          metrics: metrics,
                          label: 'Manage Menu',
                          outlined: false,
                        ),
                      ),
                    ],
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
  const _ProfileTopOverlayButton({required this.metrics, required this.icon});

  final _ResponsiveMetrics metrics;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final size = _clampDouble(44 * metrics.scale, 36, 44);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x34FFFFFF),
        border: Border.all(color: const Color(0x43FFFFFF)),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: _clampDouble(24 * metrics.scale, 18, 24),
      ),
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

class _OwnerActionButton extends StatelessWidget {
  const _OwnerActionButton({
    required this.metrics,
    required this.label,
    required this.outlined,
  });

  final _ResponsiveMetrics metrics;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _clampDouble(50 * metrics.scale, 42, 50),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: outlined
              ? const Color(0xFFFF7E4D)
              : const Color(0xFFFFFFFF),
          backgroundColor: outlined
              ? const Color(0xFFF7F3EE)
              : const Color(0xFFFF7E4D),
          side: BorderSide(
            color: outlined ? const Color(0xFFFF7E4D) : const Color(0xFFFF7E4D),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: _clampDouble(16 * metrics.scale, 12, 16),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionTabs extends StatelessWidget {
  const _ProfileSectionTabs({
    required this.metrics,
    required this.selectedIndex,
  });

  final _ResponsiveMetrics metrics;
  final int selectedIndex;

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
                    child: Positioned.fill(
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7E4D),
                  backgroundColor: const Color(0xFFF0E8DF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Edit +',
                  style: TextStyle(
                    fontSize: _clampDouble(14 * metrics.scale, 10, 14),
                    fontWeight: FontWeight.w700,
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

class _OwnerMenuItemCard extends StatelessWidget {
  const _OwnerMenuItemCard({required this.metrics, required this.item});

  final _ResponsiveMetrics metrics;
  final _OwnerMenuItemData item;

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = _clampDouble(92 * metrics.scale, 74, 92);
    return Container(
      padding: EdgeInsets.all(_clampDouble(12 * metrics.scale, 10, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1ED),
        borderRadius: BorderRadius.circular(24),
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
                        colors: [Color(0xFFE5D8CA), Color(0xFFD8C7B5)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFF7A6556),
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: _clampDouble(12 * metrics.scale, 9, 12)),
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
                          fontSize:
                              _clampDouble(31 * metrics.scale, 22, 31) * 0.56,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                    ),
                    SizedBox(width: _clampDouble(10 * metrics.scale, 7, 10)),
                    Text(
                      item.price,
                      style: TextStyle(
                        color: const Color(0xFFFF7E4D),
                        fontSize:
                            _clampDouble(30 * metrics.scale, 22, 30) * 0.56,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF8C7D71),
                    fontSize: _clampDouble(14 * metrics.scale, 10, 14),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: _clampDouble(10 * metrics.scale, 7, 10)),
                Wrap(
                  spacing: _clampDouble(7 * metrics.scale, 5, 7),
                  runSpacing: _clampDouble(6 * metrics.scale, 4, 6),
                  children: item.tags
                      .map((tag) => _MenuTagPill(metrics: metrics, tag: tag))
                      .toList(),
                ),
              ],
            ),
          ),
          SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
          Container(
            width: _clampDouble(38 * metrics.scale, 30, 38),
            height: _clampDouble(38 * metrics.scale, 30, 38),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE9E5E1),
            ),
            child: Icon(
              Icons.edit_outlined,
              color: const Color(0xFFFF7E4D),
              size: _clampDouble(20 * metrics.scale, 14, 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTagPill extends StatelessWidget {
  const _MenuTagPill({required this.metrics, required this.tag});

  final _ResponsiveMetrics metrics;
  final _OwnerMenuTagData tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(10 * metrics.scale, 7, 10),
        vertical: _clampDouble(4 * metrics.scale, 3, 4),
      ),
      decoration: BoxDecoration(
        color: tag.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          color: tag.textColor,
          fontSize: _clampDouble(12 * metrics.scale, 8, 12),
          fontWeight: FontWeight.w700,
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

class _OwnerMenuItemData {
  const _OwnerMenuItemData({
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.tags,
  });

  final String title;
  final String description;
  final String price;
  final String imageUrl;
  final List<_OwnerMenuTagData> tags;
}

class _OwnerMenuTagData {
  const _OwnerMenuTagData({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}

class _RestaurantProfileInfo {
  const _RestaurantProfileInfo({
    required this.name,
    required this.handle,
    required this.cuisineSummary,
    required this.ratingLabel,
    required this.phoneLabel,
    required this.locationLabel,
    required this.coverImageUrl,
  });

  static const String _defaultCoverImage =
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1400&q=80';

  final String name;
  final String handle;
  final String cuisineSummary;
  final String ratingLabel;
  final String phoneLabel;
  final String locationLabel;
  final String coverImageUrl;

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
      _firstString(allMaps, const ['handle', 'username', 'slug', 'restaurant_slug']) ??
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
    final street = _firstString(allMaps, const ['street', 'address', 'location']);

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
      coverImageUrl: coverImageUrl,
    );
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
  double get bottomPadding => _clampDouble(height * 0.009, 8, 12);
  double get sideGap => _clampDouble(16 * scale, 8, 16);
  double get gapAfterTop => _clampDouble(12 * scale, 6, 12);
  double get sectionGapSmall => _clampDouble(20 * scale, 10, 18);
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
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _ResponsiveMetrics metrics;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.search_rounded, metrics: metrics),
        SizedBox(width: metrics.sideGap),
        Expanded(
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
        SizedBox(width: metrics.sideGap),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          metrics: metrics,
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
  const _RoundIconButton({required this.icon, required this.metrics});

  final IconData icon;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.topControlButtonSize,
      height: metrics.topControlButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x38FFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Icon(icon, color: Colors.white, size: metrics.topControlIconSize),
    );
  }
}

class _FeedDetails extends StatelessWidget {
  const _FeedDetails({required this.restaurantName, required this.metrics});

  final String restaurantName;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                      text: restaurantName,
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
                    '4.8',
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
        SizedBox(height: _clampDouble(8 * metrics.scale, 4, 8)),
        Text(
          'Feeling hungry? Pizza night is here with our Pepperoni Feast!',
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
          '#pizza #yum #foodie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFFF7E4D),
            fontSize: metrics.tagsFontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(12 * metrics.scale, 6, 14)),
        Row(
          children: [
            Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: _clampDouble(metrics.audioFontSize + 4, 14, 20),
            ),
            SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
            Flexible(
              child: Text(
                'Original Audio - Bella Italia Promo',
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
      ],
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({required this.metrics});

  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.railWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CreatorAvatar(metrics: metrics),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.favorite_rounded,
            value: '4.2k',
            iconColor: const Color(0xFFFF7E4D),
            metrics: metrics,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            value: '156',
            metrics: metrics,
          ),
          SizedBox(height: metrics.railItemGap),
          _ActionButton(
            icon: Icons.share_outlined,
            value: 'Share',
            metrics: metrics,
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.metrics});

  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            width: metrics.creatorPlusSize,
            height: metrics.creatorPlusSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF7E4D),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: metrics.creatorPlusSize * 0.62,
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
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String value;
  final _ResponsiveMetrics metrics;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: metrics.actionBubbleSize,
          height: metrics.actionBubbleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x36FFFFFF),
            border: Border.all(color: const Color(0x2BFFFFFF)),
          ),
          child: Icon(icon, color: iconColor, size: metrics.actionIconSize),
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
