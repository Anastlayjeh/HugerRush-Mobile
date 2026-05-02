import 'package:flutter/material.dart';

import '../models/demo_app_models.dart';
import '../services/demo_app_repository.dart';
import '../services/restaurant_menu_api_service.dart';

Future<void> showShareFallbackDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Share'),
        content: Text('$title\n\n$body'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> showRestaurantProfilePopup(
  BuildContext context, {
  required String restaurantName,
  required String handle,
  required double rating,
  required String caption,
  int initialTabIndex = 0,
  String? cuisineSummary,
  String? phoneLabel,
  String? locationLabel,
  String? followersCountLabel,
  VoidCallback? onOpenFollowers,
  String? profileImageUrl,
  List<RestaurantMenuItem>? menuItems,
  List<RestaurantProfileVideoPreview>? uploadedVideos,
  List<RestaurantProfileReviewPreview>? reviews,
  bool allowAddToCart = false,
  ValueChanged<RestaurantMenuItem>? onAddToCart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF6F2ED),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    clipBehavior: Clip.none,
    builder: (context) {
      return _RestaurantProfilePopup(
        restaurantName: restaurantName,
        handle: handle,
        rating: rating,
        caption: caption,
        initialTabIndex: initialTabIndex,
        cuisineSummary: cuisineSummary,
        phoneLabel: phoneLabel,
        locationLabel: locationLabel,
        followersCountLabel: followersCountLabel,
        onOpenFollowers: onOpenFollowers,
        profileImageUrl: profileImageUrl,
        menuItems: menuItems,
        uploadedVideos: uploadedVideos,
        reviews: reviews,
        allowAddToCart: allowAddToCart,
        onAddToCart: onAddToCart,
      );
    },
  );
}

Future<void> showRestaurantMenuItemDetailsPopup(
  BuildContext context, {
  required RestaurantMenuItem item,
  bool allowAddToCart = false,
  ValueChanged<RestaurantMenuItem>? onAddToCart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF6F2ED),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    clipBehavior: Clip.none,
    builder: (context) {
      return _RestaurantMenuItemDetailsSheet(
        item: item,
        allowAddToCart: allowAddToCart,
        onAddToCart: onAddToCart,
      );
    },
  );
}

class _RestaurantMenuItemDetailsSheet extends StatelessWidget {
  const _RestaurantMenuItemDetailsSheet({
    required this.item,
    required this.allowAddToCart,
    this.onAddToCart,
  });

  final RestaurantMenuItem item;
  final bool allowAddToCart;
  final ValueChanged<RestaurantMenuItem>? onAddToCart;

  String _priceLabel(double? value) {
    if (value == null) {
      return '--';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    void addToCart() {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      if (onAddToCart != null) {
        onAddToCart!(item);
        return;
      }
      if (messenger == null) {
        return;
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('${item.title} added to cart')),
      );
    }

    return ColoredBox(
      color: const Color(0xFFF6F2ED),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Details',
                            style: TextStyle(
                              color: Color(0xFF1F1B19),
                              fontSize: 30 * 0.56,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Read this menu item information.',
                            style: TextStyle(
                              color: Color(0xFF778295),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8492A6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF4C3A2), Color(0xFFEAA178)],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7DDD3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Item Name',
                              style: TextStyle(
                                color: Color(0xFF5A6A82),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Color(0xFF1F1B19),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              color: Color(0xFF5A6A82),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _priceLabel(item.price),
                            style: const TextStyle(
                              color: Color(0xFFF0682B),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7DDD3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Color(0xFF5A6A82),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Color(0xFF2F241B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MenuInfoChip(label: item.category),
                    _MenuInfoChip(
                      label: item.isAvailable ? 'Available' : 'Unavailable',
                    ),
                    if (item.isPopular) const _MenuInfoChip(label: 'Popular'),
                    if (item.rating != null)
                      _MenuInfoChip(
                        label: 'Rating ${item.rating!.toStringAsFixed(1)}',
                      ),
                    if (item.ordersCount != null)
                      _MenuInfoChip(label: '${item.ordersCount} orders'),
                  ],
                ),
                const SizedBox(height: 16),
                if (allowAddToCart)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5F6E82),
                            side: const BorderSide(color: Color(0xFFD5DEE9)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: addToCart,
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7E4D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          label: const Text(
                            'Add to cart',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7E4D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
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

class RestaurantProfileVideoPreview {
  const RestaurantProfileVideoPreview({
    required this.title,
    required this.meta,
  });

  final String title;
  final String meta;
}

class RestaurantProfileReviewPreview {
  const RestaurantProfileReviewPreview({
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

class _RestaurantProfilePopup extends StatelessWidget {
  const _RestaurantProfilePopup({
    required this.restaurantName,
    required this.handle,
    required this.rating,
    required this.caption,
    this.initialTabIndex = 0,
    this.cuisineSummary,
    this.phoneLabel,
    this.locationLabel,
    this.followersCountLabel,
    this.onOpenFollowers,
    this.profileImageUrl,
    this.menuItems,
    this.uploadedVideos,
    this.reviews,
    this.allowAddToCart = false,
    this.onAddToCart,
  });

  final String restaurantName;
  final String handle;
  final double rating;
  final String caption;
  final int initialTabIndex;
  final String? cuisineSummary;
  final String? phoneLabel;
  final String? locationLabel;
  final String? followersCountLabel;
  final VoidCallback? onOpenFollowers;
  final String? profileImageUrl;
  final List<RestaurantMenuItem>? menuItems;
  final List<RestaurantProfileVideoPreview>? uploadedVideos;
  final List<RestaurantProfileReviewPreview>? reviews;
  final bool allowAddToCart;
  final ValueChanged<RestaurantMenuItem>? onAddToCart;

  static const String _defaultProfileImage =
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80';
  static const List<RestaurantProfileVideoPreview> _fallbackVideos = [
    RestaurantProfileVideoPreview(
      title: 'Lunch Rush Kitchen Clip',
      meta: '21 MB • 2h ago',
    ),
    RestaurantProfileVideoPreview(
      title: 'Pizza Oven Timelapse',
      meta: '17 MB • 5h ago',
    ),
    RestaurantProfileVideoPreview(
      title: 'Plating Special Combo',
      meta: '12 MB • Yesterday',
    ),
  ];
  static const List<RestaurantProfileReviewPreview> _fallbackReviews = [
    RestaurantProfileReviewPreview(
      customerName: 'Lina M.',
      rating: 4.8,
      comment:
          'Pizza arrived hot and fresh. Crust was perfect and delivery was very quick.',
      timeLabel: '2h ago',
      orderLabel: '#4731',
    ),
    RestaurantProfileReviewPreview(
      customerName: 'Rami A.',
      rating: 4.6,
      comment:
          'Great flavor and portion size. Please keep the same quality for the fries.',
      timeLabel: '5h ago',
      orderLabel: '#4728',
    ),
    RestaurantProfileReviewPreview(
      customerName: 'Maya K.',
      rating: 5.0,
      comment:
          'Excellent as always. Packaging was clean and food arrived on time.',
      timeLabel: 'Yesterday',
      orderLabel: '#4722',
    ),
  ];
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

  String get _normalizedHandle {
    final cleaned = handle.trim();
    if (cleaned.isEmpty) {
      return '@restaurant';
    }
    return cleaned.startsWith('@') ? cleaned : '@$cleaned';
  }

  String get _initials {
    final parts = restaurantName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'R';
    }
    if (parts.length == 1) {
      final single = parts.first;
      return single.length >= 2
          ? single.substring(0, 2).toUpperCase()
          : single.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<RestaurantMenuItem> get _resolvedMenuItems {
    if (menuItems == null || menuItems!.isEmpty) {
      return _fallbackMenuItems;
    }
    return menuItems!;
  }

  List<RestaurantProfileVideoPreview> get _resolvedVideos {
    if (uploadedVideos == null) {
      return _fallbackVideos;
    }
    return uploadedVideos!;
  }

  List<RestaurantProfileReviewPreview> get _resolvedReviews {
    if (reviews == null || reviews!.isEmpty) {
      return _fallbackReviews;
    }
    return reviews!;
  }

  List<RestaurantMenuItem> get _popularChoices {
    final items = _resolvedMenuItems;
    final markedPopular = items.where((item) => item.isPopular).toList();
    if (markedPopular.isNotEmpty) {
      markedPopular.sort(
        (a, b) => (b.ordersCount ?? 0).compareTo(a.ordersCount ?? 0),
      );
      return markedPopular.take(3).toList();
    }
    final sorted = List<RestaurantMenuItem>.from(items)
      ..sort((a, b) {
        final byOrders = (b.ordersCount ?? 0).compareTo(a.ordersCount ?? 0);
        if (byOrders != 0) {
          return byOrders;
        }
        final byRating = (b.rating ?? 0).compareTo(a.rating ?? 0);
        if (byRating != 0) {
          return byRating;
        }
        return a.title.compareTo(b.title);
      });
    return sorted.take(3).toList();
  }

  String _priceLabel(double? value) {
    if (value == null) {
      return '--';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedInitialTabIndex = initialTabIndex.clamp(0, 2).toInt();
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    final viewportSize = MediaQuery.sizeOf(context);
    final tabPanelHeight = (viewportSize.height * 0.42)
        .clamp(320.0, 460.0)
        .toDouble();
    final popularChoices = _popularChoices;
    final videos = _resolvedVideos;
    final menuList = _resolvedMenuItems;
    final reviewsList = _resolvedReviews;
    return ColoredBox(
      color: const Color(0xFFF6F2ED),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PopupRestaurantHero(
                  restaurantName: restaurantName,
                  handle: _normalizedHandle,
                  cuisineSummary: cuisineSummary ?? 'Restaurant Partner',
                  ratingLabel: rating > 0 ? rating.toStringAsFixed(1) : null,
                  phoneLabel: phoneLabel ?? 'Phone unavailable',
                  locationLabel: locationLabel ?? 'Location unavailable',
                  followersCountLabel: followersCountLabel ?? '0',
                  onOpenFollowers: onOpenFollowers,
                  coverImageUrl: profileImageUrl ?? _defaultProfileImage,
                  initials: _initials,
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: DefaultTabController(
                    length: 3,
                    initialIndex: resolvedInitialTabIndex,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TabBar(
                          indicatorColor: const Color(0xFFFF7E4D),
                          indicatorWeight: 3,
                          labelColor: const Color(0xFFFF7E4D),
                          unselectedLabelColor: const Color(0xFF6D7485),
                          labelStyle: const TextStyle(
                            fontSize: 22 * 0.56,
                            fontWeight: FontWeight.w800,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 22 * 0.56,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Videos'),
                            Tab(text: 'Menu'),
                            Tab(text: 'Reviews'),
                          ],
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFD9D2CB),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: tabPanelHeight,
                          child: TabBarView(
                            children: [
                              videos.isEmpty
                                  ? const _PopupEmptyState(
                                      icon: Icons.video_library_rounded,
                                      title: 'No Videos Yet',
                                      message:
                                          'Upload videos from Dashboard > Create Post and they will appear here.',
                                    )
                                  : _RestaurantProfileVideoGrid(videos: videos),
                              _RestaurantProfileTabPanel(
                                children: [
                                  const _TabSubSectionTitle('Popular Choices'),
                                  ...popularChoices.map(
                                    (item) => _RestaurantProfileMenuTile(
                                      item: item,
                                      priceLabel: _priceLabel(item.price),
                                      showPopularBadge: true,
                                      allowAddToCart: allowAddToCart,
                                      onAddToCart: onAddToCart,
                                    ),
                                  ),
                                  const _TabSubSectionTitle('Full Menu'),
                                  ...menuList.map(
                                    (item) => _RestaurantProfileMenuTile(
                                      item: item,
                                      priceLabel: _priceLabel(item.price),
                                      showPopularBadge: false,
                                      allowAddToCart: allowAddToCart,
                                      onAddToCart: onAddToCart,
                                    ),
                                  ),
                                ],
                              ),
                              reviewsList.isEmpty
                                  ? const _PopupEmptyState(
                                      icon: Icons.reviews_rounded,
                                      title: 'No Reviews Yet',
                                      message:
                                          'Customer reviews will appear here once orders are completed.',
                                    )
                                  : _RestaurantProfileTabPanel(
                                      children: reviewsList
                                          .map(
                                            (review) =>
                                                _RestaurantProfileReviewTile(
                                                  review: review,
                                                ),
                                          )
                                          .toList(),
                                    ),
                            ],
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
      ),
    );
  }
}

class _PopupRestaurantHero extends StatelessWidget {
  const _PopupRestaurantHero({
    required this.restaurantName,
    required this.handle,
    required this.cuisineSummary,
    required this.ratingLabel,
    required this.phoneLabel,
    required this.locationLabel,
    required this.followersCountLabel,
    this.onOpenFollowers,
    required this.coverImageUrl,
    required this.initials,
  });

  final String restaurantName;
  final String handle;
  final String cuisineSummary;
  final String? ratingLabel;
  final String phoneLabel;
  final String locationLabel;
  final String followersCountLabel;
  final VoidCallback? onOpenFollowers;
  final String coverImageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const coverHeight = 220.0;
    const cardHeight = 286.0;
    const cardTop = coverHeight - 40;
    const avatarSize = 92.0;
    const totalHeight = cardTop + cardHeight;
    const avatarTop = cardTop - (avatarSize / 2);
    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              width: double.infinity,
              height: coverHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    coverImageUrl,
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
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        _PopupTopOverlayButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
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
              padding: const EdgeInsets.fromLTRB(
                16,
                (avatarSize / 2) + 12,
                16,
                16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0EC),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE6DBD0)),
              ),
              child: Column(
                children: [
                  Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F1B19),
                      fontSize: 42 * 0.58,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cuisineSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8F7F73),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _PopupHeroMetaItem(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF5B826),
                        label: ratingLabel == null
                            ? 'No ratings yet'
                            : ratingLabel!,
                      ),
                      _PopupHeroMetaItem(
                        icon: Icons.call_rounded,
                        iconColor: const Color(0xFFFF7E4D),
                        label: phoneLabel,
                      ),
                      _PopupHeroMetaItem(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF23A455),
                        label: locationLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5D9CE)),
                    ),
                    child: Center(
                      child: _PopupProfileConnectionMetric(
                        value: followersCountLabel,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26 * 0.55,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xE0FFFFFF),
                        fontSize: 11 * 0.7,
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

class _PopupTopOverlayButton extends StatelessWidget {
  const _PopupTopOverlayButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFFFFF),
            border: Border.all(color: const Color(0xFF121212)),
          ),
          child: Icon(icon, color: const Color(0xFF121212), size: 24),
        ),
      ),
    );
  }
}

class _PopupHeroMetaItem extends StatelessWidget {
  const _PopupHeroMetaItem({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2D241F),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PopupProfileConnectionMetric extends StatelessWidget {
  const _PopupProfileConnectionMetric({
    required this.value,
    required this.label,
    this.onTap,
  });

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
          style: const TextStyle(
            color: Color(0xFF201A16),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7C6E61),
            fontSize: 12,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: content,
        ),
      ),
    );
  }
}

class _PopupEmptyState extends StatelessWidget {
  const _PopupEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEFE8),
            ),
            child: Icon(icon, color: const Color(0xFFFF7E4D), size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2A231E),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8D7E73),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantProfileTabPanel extends StatelessWidget {
  const _RestaurantProfileTabPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4D8CA)),
      ),
      child: children.isEmpty
          ? const Center(
              child: Text(
                'No data yet',
                style: TextStyle(
                  color: Color(0xFF8F7E71),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: children.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => children[index],
            ),
    );
  }
}

class _TabSubSectionTitle extends StatelessWidget {
  const _TabSubSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF856D58),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RestaurantProfileVideoGrid extends StatelessWidget {
  const _RestaurantProfileVideoGrid({required this.videos});

  final List<RestaurantProfileVideoPreview> videos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4D8CA)),
      ),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: videos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          return _RestaurantProfileVideoGridTile(video: videos[index]);
        },
      ),
    );
  }
}

class _RestaurantProfileVideoGridTile extends StatelessWidget {
  const _RestaurantProfileVideoGridTile({required this.video});

  final RestaurantProfileVideoPreview video;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DCCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFE1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFFF68B1F),
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2F241B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            video.meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8F7E71),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantProfileMenuTile extends StatelessWidget {
  const _RestaurantProfileMenuTile({
    required this.item,
    required this.priceLabel,
    required this.showPopularBadge,
    required this.allowAddToCart,
    required this.onAddToCart,
  });

  final RestaurantMenuItem item;
  final String priceLabel;
  final bool showPopularBadge;
  final bool allowAddToCart;
  final ValueChanged<RestaurantMenuItem>? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showRestaurantMenuItemDetailsPopup(
          context,
          item: item,
          allowAddToCart: allowAddToCart,
          onAddToCart: onAddToCart,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6DCCF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.imageUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFFFFEFE1),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Color(0xFFF68B1F),
                      ),
                    );
                  },
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
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2F241B),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFF0682B),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8F7E71),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MenuInfoChip(label: item.category),
                        if (showPopularBadge && item.isPopular)
                          const _MenuInfoChip(label: 'Popular'),
                        _MenuInfoChip(
                          label: item.isAvailable ? 'Available' : 'Unavailable',
                        ),
                      ],
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

class _MenuInfoChip extends StatelessWidget {
  const _MenuInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF856D58),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RestaurantProfileReviewTile extends StatelessWidget {
  const _RestaurantProfileReviewTile({required this.review});

  final RestaurantProfileReviewPreview review;

  String get _initial {
    final cleaned = review.customerName.trim();
    if (cleaned.isEmpty) {
      return '?';
    }
    return cleaned[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DCCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFFEFE1),
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: Color(0xFF7F4A20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.customerName,
                  style: const TextStyle(
                    color: Color(0xFF2F241B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1CC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFB07800),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFFB07800),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            review.comment,
            style: const TextStyle(
              color: Color(0xFF58493C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${review.orderLabel} • ${review.timeLabel}',
            style: const TextStyle(
              color: Color(0xFF9A8B7E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repository = DemoAppRepository.instance;
  late final TextEditingController _controller;

  List<DemoSearchResult> _results = const <DemoSearchResult>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_handleQueryChanged);
    if (widget.initialQuery.trim().isNotEmpty) {
      _runSearch(widget.initialQuery);
    }
  }

  void _handleQueryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await _repository.search(query);
    if (!mounted) {
      return;
    }
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              decoration: InputDecoration(
                hintText: 'Search promos, orders, or messages',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () {
                          _controller.clear();
                          setState(() => _results = const <DemoSearchResult>[]);
                        },
                  icon: const Icon(Icons.close_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No results yet. Try a restaurant, customer, or order ID.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: const Color(0xFFF3F0EC),
                      title: Text(result.title),
                      subtitle: Text(result.subtitle),
                      trailing: Text(
                        result.categoryLabel,
                        style: const TextStyle(
                          color: Color(0xFFFF7E4D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = DemoAppRepository.instance;
  List<DemoNotificationItem> _items = const <DemoNotificationItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repository.getNotifications();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    setState(() => _isLoading = true);
    final items = await _repository.markAllNotificationsRead();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _isLoading || _items.isEmpty ? null : _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  tileColor: item.isRead
                      ? const Color(0xFFF3F0EC)
                      : const Color(0xFFFFEFE8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: item.isRead
                          ? const Color(0xFFE5DACF)
                          : const Color(0xFFFFD6C8),
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.body),
                  trailing: Text(item.timeLabel),
                );
              },
            ),
    );
  }
}

class RestaurantDetailsScreen extends StatelessWidget {
  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantName,
    required this.handle,
    required this.rating,
    required this.caption,
  });

  final String restaurantName;
  final String handle;
  final double rating;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(restaurantName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@$handle', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Rating ${rating.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Color(0xFFFF7E4D),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(caption),
          ],
        ),
      ),
    );
  }
}

class PromoDetailsScreen extends StatelessWidget {
  const PromoDetailsScreen({
    super.key,
    required this.title,
    required this.caption,
    required this.audioLabel,
  });

  final String title;
  final String caption;
  final String audioLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caption, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.music_note_rounded, color: Color(0xFFFF7E4D)),
                const SizedBox(width: 8),
                Expanded(child: Text(audioLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postTitle,
  });

  final String postId;
  final String postTitle;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
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
    return Scaffold(
      appBar: AppBar(title: Text('${widget.postTitle} Comments')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _comments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return ListTile(
                  tileColor: const Color(0xFFF3F0EC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(comment.authorName),
                  subtitle: Text(comment.body),
                  trailing: Text(
                    _formatTime(comment.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Add a comment',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _isSending ? null : _send,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send'),
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

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key, required this.title, required this.orders});

  final String title;
  final List<DemoOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            tileColor: const Color(0xFFF3F0EC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('${order.id} • ${order.customerName}'),
            subtitle: Text(order.itemSummary),
            trailing: Text(order.statusLabel),
          );
        },
      ),
    );
  }
}

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key, required this.orders});

  final List<DemoOrder> orders;

  @override
  Widget build(BuildContext context) {
    return OrderListScreen(title: 'Order Management', orders: orders);
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final DemoOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.customerName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(order.itemSummary),
            const SizedBox(height: 12),
            Text('Status: ${order.statusLabel}'),
            Text('ETA: ${order.etaLabel}'),
            Text('Channel: ${order.channelLabel}'),
            Text('Total: ${order.totalLabel}'),
          ],
        ),
      ),
    );
  }
}

class RevenueAnalyticsScreen extends StatelessWidget {
  const RevenueAnalyticsScreen({
    super.key,
    required this.revenueLabel,
    required this.completedOrders,
  });

  final String revenueLabel;
  final int completedOrders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              revenueLabel,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('Estimated from $completedOrders completed orders today.'),
          ],
        ),
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.threadId,
    required this.restaurantName,
    this.openComposerOnStart = false,
  });

  final String threadId;
  final String restaurantName;
  final bool openComposerOnStart;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _repository = DemoAppRepository.instance;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  DemoConversationThread? _thread;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    final thread = _repository.findThread(widget.threadId);
    if (thread == null) {
      return;
    }
    await _repository.markThreadRead(widget.threadId);
    if (!mounted) {
      return;
    }
    setState(() => _thread = _repository.findThread(widget.threadId));
    if (widget.openComposerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thread == null) {
      return;
    }
    setState(() => _isSending = true);
    final updated = await _repository.sendReply(
      threadId: _thread!.id,
      restaurantName: widget.restaurantName,
      text: text,
    );
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() {
      _thread = updated;
      _isSending = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reply sent')));
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    return Scaffold(
      appBar: AppBar(title: Text(thread?.customerName ?? 'Conversation')),
      body: thread == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: thread.messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final message = thread.messages[index];
                      final align = message.fromRestaurant
                          ? Alignment.centerRight
                          : Alignment.centerLeft;
                      final color = message.fromRestaurant
                          ? const Color(0xFFFFEFE8)
                          : const Color(0xFFF3F0EC);
                      return Align(
                        alignment: align,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(message.body),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Write a reply',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _isSending ? null : _send,
                          child: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send'),
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

class SimplePlaceholderScreen extends StatelessWidget {
  const SimplePlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
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
