import 'package:flutter/material.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedTopTab = 1;
  int _selectedBottomIndex = 0;

  String get _userHandle {
    final cleaned = widget.userName.trim();
    if (cleaned.isEmpty) {
      return 'FoodExplorer';
    }
    return cleaned.replaceAll(RegExp(r'\s+'), '');
  }

  @override
  Widget build(BuildContext context) {
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
                                  userHandle: _userHandle,
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
                        selectedIndex: _selectedBottomIndex,
                        onSelected: (index) {
                          setState(() => _selectedBottomIndex = index);
                        },
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
  double get railWidth => _clampDouble(78 * scale, 60, 78);
  double get railItemGap => _clampDouble(14 * scale, 8, 14);

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

  double get creatorSize => _clampDouble(68 * scale, 52, 68);
  double get creatorPlusSize => _clampDouble(28 * scale, 20, 28);
  double get actionBubbleSize => _clampDouble(62 * scale, 46, 62);
  double get actionIconSize => _clampDouble(34 * scale, 24, 34);
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
