part of '../restaurant_feed_screen.dart';

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

