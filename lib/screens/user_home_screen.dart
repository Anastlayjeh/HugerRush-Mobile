import 'package:flutter/material.dart';

import 'login_screen.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

String _profileEmailFromHandle(String handle) {
  final cleaned = handle.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  return '${cleaned.isEmpty ? 'foodie' : cleaned}@hungerrush.app';
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
  const UserHomeScreen({super.key, required this.userName});

  final String userName;

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
    final showProfile = _selectedBottomIndex == 4;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: showProfile || showDiscover || showOrders
          ? const Color(0xFFF8EFE5)
          : const Color(0xFF0A2230),
      endDrawer: _UserProfileMenuDrawer(userName: widget.userName),
      body: showProfile
          ? _ProfileTabBody(
              userName: widget.userName,
              userHandle: _userHandle,
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
          : _FeedTabBody(
              userHandle: _userHandle,
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

class _FeedTabBody extends StatelessWidget {
  const _FeedTabBody({
    required this.userHandle,
    required this.selectedTopTab,
    required this.selectedBottomIndex,
    required this.onTopTabSelected,
    required this.onBottomNavSelected,
  });

  final String userHandle;
  final int selectedTopTab;
  final int selectedBottomIndex;
  final ValueChanged<int> onTopTabSelected;
  final ValueChanged<int> onBottomNavSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _FeedBackground()),
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
                      selectedTab: selectedTopTab,
                      onTabSelected: onTopTabSelected,
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
                                userHandle: userHandle,
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
                    _OrderNowBar(metrics: metrics),
                    SizedBox(height: metrics.sectionGapSmall),
                    _BottomNavBar(
                      metrics: metrics,
                      selectedIndex: selectedBottomIndex,
                      onSelected: onBottomNavSelected,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiscoverTabBody extends StatelessWidget {
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
      subtitle: 'Italian comfort and signature pasta',
      deliveryLabel: '12 min',
      ratingLabel: '4.9',
      badge: 'Free delivery',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Ember Slice',
      subtitle: 'Stone-baked pizza and burrata bites',
      deliveryLabel: '18 min',
      ratingLabel: '4.8',
      badge: 'Top rated',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Cedar Bowl',
      subtitle: 'Fresh wraps, bowls, and grill plates',
      deliveryLabel: '14 min',
      ratingLabel: '4.7',
      badge: 'New menu',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
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
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;

    return Stack(
      children: [
        const Positioned.fill(child: _DiscoverBackground()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = _ResponsiveMetrics.from(constraints);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.horizontalPadding,
                  _clampDouble(metrics.topPadding + 6, 12, 20),
                  metrics.horizontalPadding,
                  metrics.bottomPadding,
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
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: _clampDouble(18 * metrics.scale, 14, 18)),
                    Row(
                      children: [
                        Expanded(child: _DiscoverSearchBar(metrics: metrics)),
                        SizedBox(
                          width: _clampDouble(12 * metrics.scale, 10, 12),
                        ),
                        _ProfileIconButton(
                          icon: Icons.place_outlined,
                          metrics: metrics,
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: _clampDouble(20 * metrics.scale, 16, 20)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DiscoverFeatureCard(metrics: metrics),
                            SizedBox(
                              height: _clampDouble(24 * metrics.scale, 18, 24),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Browse Cuisines',
                              actionLabel: 'View Map',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
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
                                itemCount: _categories.length,
                                separatorBuilder: (context, index) => SizedBox(
                                  width: _clampDouble(
                                    12 * metrics.scale,
                                    8,
                                    12,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  return _DiscoverCuisineChip(
                                    data: _categories[index],
                                    metrics: metrics,
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              height: _clampDouble(26 * metrics.scale, 20, 26),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Popular Near You',
                              actionLabel: 'See All',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            SizedBox(
                              height: _clampDouble(
                                320 * metrics.scale,
                                286,
                                320,
                              ),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _popularSpots.length,
                                separatorBuilder: (context, index) => SizedBox(
                                  width: _clampDouble(
                                    14 * metrics.scale,
                                    10,
                                    14,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  return _DiscoverSpotCard(
                                    data: _popularSpots[index],
                                    metrics: metrics,
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              height: _clampDouble(26 * metrics.scale, 20, 26),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Quick Cravings',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            _ProfilePanel(
                              child: Column(
                                children: List.generate(_quickCravings.length, (
                                  index,
                                ) {
                                  final item = _quickCravings[index];
                                  return Column(
                                    children: [
                                      _DiscoverDealTile(
                                        data: item,
                                        metrics: metrics,
                                      ),
                                      if (index != _quickCravings.length - 1)
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFF0E2D3),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            SizedBox(
                              height: _clampDouble(12 * metrics.scale, 8, 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox.shrink(),
                    _BottomNavBar(
                      metrics: metrics,
                      selectedIndex: selectedBottomIndex,
                      onSelected: onBottomNavSelected,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;

    return Stack(
      children: [
        const Positioned.fill(child: _OrdersBackground()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = _ResponsiveMetrics.from(constraints);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.horizontalPadding,
                  _clampDouble(metrics.topPadding + 6, 12, 20),
                  metrics.horizontalPadding,
                  metrics.bottomPadding,
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
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: _clampDouble(20 * metrics.scale, 16, 20)),
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
                              height: _clampDouble(26 * metrics.scale, 20, 26),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Live Order',
                              actionLabel: 'Need Help?',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            _ActiveOrderCard(
                              metrics: metrics,
                              currentStatus: _activeStatus,
                            ),
                            SizedBox(
                              height: _clampDouble(26 * metrics.scale, 20, 26),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Recent Orders',
                              actionLabel: 'View All',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
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
                              height: _clampDouble(26 * metrics.scale, 20, 26),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Reorder Tonight',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
                            ),
                            _OrdersRewardCard(metrics: metrics),
                            SizedBox(
                              height: _clampDouble(12 * metrics.scale, 8, 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox.shrink(),
                    _BottomNavBar(
                      metrics: metrics,
                      selectedIndex: selectedBottomIndex,
                      onSelected: onBottomNavSelected,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final steps = _buildOrderTimeline(currentStatus);
    final actionLabel = currentStatus == _OrderStatus.onTheWay
        ? 'Track rider'
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
  });

  final String label;
  final bool filled;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({
    required this.userName,
    required this.userHandle,
    required this.selectedBottomIndex,
    required this.onOpenMenu,
    required this.onBottomNavSelected,
  });

  final String userName;
  final String userHandle;
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
    return Stack(
      children: [
        const Positioned.fill(child: _ProfileBackground()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = _ResponsiveMetrics.from(constraints);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.horizontalPadding,
                  _clampDouble(metrics.topPadding + 6, 12, 20),
                  metrics.horizontalPadding,
                  metrics.bottomPadding,
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
                    SizedBox(height: _clampDouble(22 * metrics.scale, 16, 22)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileHeroCard(
                              userName: userName,
                              userHandle: userHandle,
                              metrics: metrics,
                            ),
                            SizedBox(
                              height: _clampDouble(18 * metrics.scale, 14, 18),
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
                              height: _clampDouble(28 * metrics.scale, 20, 28),
                            ),
                            const _ProfileSectionHeader(
                              title: 'Recent Orders',
                              actionLabel: 'View All',
                            ),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
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
                                separatorBuilder: (context, index) => SizedBox(
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
                              height: _clampDouble(28 * metrics.scale, 20, 28),
                            ),
                            const _ProfileSectionHeader(title: 'Saved Places'),
                            SizedBox(
                              height: _clampDouble(14 * metrics.scale, 10, 14),
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
                    const SizedBox.shrink(),
                    _BottomNavBar(
                      metrics: metrics,
                      selectedIndex: selectedBottomIndex,
                      onSelected: onBottomNavSelected,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
  const _DiscoverSearchBar({required this.metrics});

  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(
            Icons.mic_none_rounded,
            color: const Color(0xFFB9A596),
            size: _clampDouble(22 * metrics.scale, 18, 22),
          ),
        ],
      ),
    );
  }
}

class _DiscoverFeatureCard extends StatelessWidget {
  const _DiscoverFeatureCard({required this.metrics});

  static const _featureImage =
      'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80';

  final _ResponsiveMetrics metrics;

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
        Container(
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
  const _DiscoverCuisineChip({required this.data, required this.metrics});

  final _DiscoverCategoryData data;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _DiscoverSpotCard extends StatelessWidget {
  const _DiscoverSpotCard({required this.data, required this.metrics});

  final _DiscoverSpotData data;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _clampDouble(metrics.width * 0.72, 244, 284);
    final imageHeight = _clampDouble(
      (metrics.compact ? 110 : 128) * metrics.scale,
      metrics.compact ? 96 : 112,
      metrics.compact ? 110 : 128,
    );
    return Container(
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
                child: Container(
                  width: _clampDouble(34 * metrics.scale, 30, 34),
                  height: _clampDouble(34 * metrics.scale, 30, 34),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF9F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: const Color(0xFF8D7464),
                    size: _clampDouble(20 * metrics.scale, 16, 20),
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
                  Container(
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
                        fontSize: _clampDouble(12.5 * metrics.scale, 10, 12.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverDealTile extends StatelessWidget {
  const _DiscoverDealTile({required this.data, required this.metrics});

  final _DiscoverDealData data;
  final _ResponsiveMetrics metrics;

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

    return LayoutBuilder(
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
                    SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
                    Align(alignment: Alignment.centerRight, child: meta),
                  ],
                )
              : Row(
                  children: [
                    iconTile,
                    SizedBox(width: _clampDouble(14 * metrics.scale, 10, 14)),
                    Expanded(child: details),
                    SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
                    meta,
                  ],
                ),
        );
      },
    );
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
        final pizzaDiameter = _clampDouble(width * 1.74, width * 1.35, 780);
        final verticalShift = _clampDouble(height * 0.2, 108, 190);

        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF58CAD8),
                      Color(0xFF2199AA),
                      Color(0xFF0E4E68),
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

  double get topControlButtonSize => _clampDouble(54 * scale, 44, 54);
  double get topControlIconSize => _clampDouble(27 * scale, 21, 27);
  double get topTabFontSize => _clampDouble(17 * scale, 13, 17);
  double get topTabIndicatorWidth => _clampDouble(52 * scale, 40, 52);
  double get topTabIndicatorHeight => _clampDouble(5 * scale, 3, 5);

  double get handleFontSize => _clampDouble(32 * scale, 18, 32);
  double get handleAtFontSize => _clampDouble(18 * scale, 12, 18);
  double get captionFontSize => _clampDouble(17 * scale, 12.5, 17);
  double get tagsFontSize => _clampDouble(17 * scale, 12.5, 17);
  double get audioFontSize => _clampDouble(13 * scale, 10, 13);
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

  double get navHeight => _clampDouble(96 * scale, 72, 96);
  double get navRadius => _clampDouble(32 * scale, 22, 32);
  double get navIconSize => _clampDouble(30 * scale, 21, 30);
  double get navLabelSize => _clampDouble(12.5 * scale, 9, 12.5);
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
  const _FeedDetails({required this.userHandle, required this.metrics});

  final String userHandle;
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
                      text: userHandle,
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
          'Feeling hungry? Our new Pepperoni Feast is here. Cheesy and absolutely delicious.',
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

class _OrderNowBar extends StatelessWidget {
  const _OrderNowBar({required this.metrics});

  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final showMoreButton = constraints.maxWidth >= 340;

        return Container(
          height: metrics.ctaHeight,
          padding: EdgeInsets.symmetric(
            horizontal: _clampDouble(12 * metrics.scale, 8, 12),
            vertical: _clampDouble(8 * metrics.scale, 5, 8),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A5B),
            borderRadius: BorderRadius.circular(metrics.ctaRadius),
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
                width: _clampDouble(42 * metrics.scale, 30, 42),
                height: _clampDouble(42 * metrics.scale, 30, 42),
                decoration: const BoxDecoration(
                  color: Color(0x2EFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: metrics.ctaIconSize,
                ),
              ),
              SizedBox(width: _clampDouble(12 * metrics.scale, 6, 12)),
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
                            ? _clampDouble(metrics.ctaMainSize - 4, 16, 24)
                            : metrics.ctaMainSize,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(3 * metrics.scale, 1, 3)),
                    Text(
                      'DELIVERY IN 25M',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xF2FFFFFF),
                        fontSize: metrics.ctaSubSize,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _clampDouble(6 * metrics.scale, 2, 6)),
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
                            horizontal: _clampDouble(8 * metrics.scale, 4, 8),
                            vertical: _clampDouble(6 * metrics.scale, 4, 6),
                          ),
                          color: const Color(0x58FFFFFF),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _clampDouble(14 * metrics.scale, 8, 14),
                            vertical: _clampDouble(8 * metrics.scale, 4, 8),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1DFFFFFF),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0x49FFFFFF)),
                          ),
                          child: Text(
                            '\$14.99',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact
                                  ? _clampDouble(
                                      metrics.ctaPriceSize - 3,
                                      14,
                                      20,
                                    )
                                  : metrics.ctaPriceSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (showMoreButton) ...[
                          SizedBox(
                            width: _clampDouble(8 * metrics.scale, 4, 8),
                          ),
                          Container(
                            width: _clampDouble(34 * metrics.scale, 24, 34),
                            height: _clampDouble(34 * metrics.scale, 24, 34),
                            decoration: const BoxDecoration(
                              color: Color(0x1DFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                              size: _clampDouble(22 * metrics.scale, 14, 22),
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
  const _UserProfileMenuDrawer({required this.userName});

  final String userName;

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
                          child: Icon(
                            Icons.person_rounded,
                            color: const Color(0xFF8B5C41),
                            size: _clampDouble(28 * metrics.scale, 22, 28),
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
                                'Profile shortcuts and account tools',
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
                            builder: (_) =>  LoginScreen(),
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
    required this.metrics,
  });

  final String userName;
  final String userHandle;
  final _ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final avatarSize = _clampDouble(76 * metrics.scale, 60, 76);
    final displayName = userName.trim().isEmpty
        ? 'Hungry Explorer'
        : userName.trim();

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
                child: Icon(
                  Icons.person_rounded,
                  color: const Color(0xFF8B5C41),
                  size: avatarSize * 0.56,
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
                  _profileEmailFromHandle(userHandle),
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
                    'Rush Gold Member',
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
  const _ProfileSectionHeader({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

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
          Text(
            actionLabel!,
            style: const TextStyle(
              color: Color(0xFFFF7E4D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
    required this.subtitle,
    required this.deliveryLabel,
    required this.ratingLabel,
    required this.badge,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String deliveryLabel;
  final String ratingLabel;
  final String badge;
  final String imageUrl;
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
  });

  final _ResponsiveMetrics metrics;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.explore_rounded, label: 'Discover'),
      (icon: Icons.shopping_bag_rounded, label: 'Orders'),
      (icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      height: metrics.navHeight,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.compact ? 6 : 10,
        vertical: metrics.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
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
