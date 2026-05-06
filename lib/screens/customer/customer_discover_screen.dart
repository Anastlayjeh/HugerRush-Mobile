part of '../user_home_screen.dart';

class _DiscoverTabBody extends StatefulWidget {
  const _DiscoverTabBody({
    required this.userName,
    required this.authSession,
    required this.onSessionUpdated,
    required this.onSessionExpired,
    required this.favoriteSpotTitles,
    required this.onSetSpotFavorite,
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
  final AuthSession? authSession;
  final Future<void> Function(AuthSession session)? onSessionUpdated;
  final Future<void> Function()? onSessionExpired;
  final Set<String> favoriteSpotTitles;
  final void Function(_DiscoverSpotData spot, bool isFavorite)
  onSetSpotFavorite;
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
      handle: 'thegoldenspoon',
      categoryTitle: 'Pizza',
      subtitle: 'Italian comfort and signature pasta',
      deliveryLabel: '12 min',
      ratingLabel: '4.9',
      priceTier: 2,
      badge: 'Free delivery',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Ember Slice',
      handle: 'emberslice',
      categoryTitle: 'Burgers',
      subtitle: 'Stone-baked pizza and burrata bites',
      deliveryLabel: '18 min',
      ratingLabel: '4.8',
      priceTier: 2,
      badge: 'Top rated',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Cedar Bowl',
      handle: 'cedarbowl',
      categoryTitle: 'Sushi',
      subtitle: 'Fresh wraps, bowls, and grill plates',
      deliveryLabel: '14 min',
      ratingLabel: '4.7',
      priceTier: 1,
      badge: 'New menu',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
    ),
    _DiscoverSpotData(
      title: 'Sweet Dock',
      handle: 'sweetdock',
      categoryTitle: 'Desserts',
      subtitle: 'Gelato cups, cookies, and warm brownies',
      deliveryLabel: '16 min',
      ratingLabel: '4.8',
      priceTier: 1,
      badge: 'Chef pick',
      imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80',
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
  State<_DiscoverTabBody> createState() => _DiscoverTabBodyState();
}

class _DiscoverTabBodyState extends State<_DiscoverTabBody> {
  final _authSessionService = AuthSessionService();
  late final CustomerRestaurantApiService _restaurantApiService;
  AuthSession? _session;
  List<_DiscoverSpotData> _restaurantSpots = const <_DiscoverSpotData>[];
  final Map<String, List<RestaurantMenuItem>> _menuItemsByRestaurantId =
      <String, List<RestaurantMenuItem>>{};
  final Set<String> _pendingFavoriteRestaurantIds = <String>{};
  bool _isLoadingRestaurants = true;
  String? _restaurantError;
  Set<String> _activeCuisineFilters = <String>{};
  double _minimumRatingFilter = 0;
  int? _maximumDeliveryMinutesFilter;
  int? _maximumPriceTierFilter;

  List<_DiscoverSpotData> get _filteredPopularSpots {
    return _restaurantSpots
        .where((spot) {
          if (_activeCuisineFilters.isNotEmpty &&
              !_activeCuisineFilters.contains(spot.categoryTitle)) {
            return false;
          }
          if (spot.ratingValue < _minimumRatingFilter) {
            return false;
          }
          if (_maximumDeliveryMinutesFilter != null &&
              spot.deliveryMinutes > _maximumDeliveryMinutesFilter!) {
            return false;
          }
          if (_maximumPriceTierFilter != null &&
              spot.priceTier > _maximumPriceTierFilter!) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<_DiscoverSpotData> _spotsForCuisine(String cuisineTitle) {
    final matches = _restaurantSpots
        .where((spot) => spot.categoryTitle == cuisineTitle)
        .toList(growable: false);
    return matches.isEmpty ? _restaurantSpots : matches;
  }

  @override
  void initState() {
    super.initState();
    _session = widget.authSession;
    _restaurantApiService = CustomerRestaurantApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionUpdated: widget.onSessionUpdated,
        onSessionExpired: widget.onSessionExpired,
      ),
    );
    unawaited(_loadRestaurants());
  }

  @override
  void didUpdateWidget(covariant _DiscoverTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authSession?.token != widget.authSession?.token) {
      _session = widget.authSession;
      unawaited(_loadRestaurants());
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
    }
    return restored;
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoadingRestaurants = true;
      _restaurantError = null;
    });

    final session = await _resolveSession();
    if (session == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingRestaurants = false;
        _restaurantSpots = const <_DiscoverSpotData>[];
        _restaurantError = 'Please log in again to load restaurants.';
      });
      return;
    }

    try {
      final page = await _restaurantApiService.fetchRestaurants(
        session: session,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantSpots = page.restaurants
            .where(_isVisibleRestaurant)
            .map(_spotFromRestaurant)
            .toList(growable: false);
        _isLoadingRestaurants = false;
        _restaurantError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingRestaurants = false;
        _restaurantSpots = const <_DiscoverSpotData>[];
        _restaurantError = 'Unable to load restaurants. Please try again.';
      });
    }
  }

  bool _isVisibleRestaurant(CustomerRestaurantItem restaurant) {
    final status = restaurant.status.trim().toLowerCase();
    if (status.isEmpty) {
      return true;
    }
    return const <String>{
      'active',
      'approved',
      'open',
      'published',
      'enabled',
      'online',
    }.contains(status);
  }

  _DiscoverSpotData _spotFromRestaurant(CustomerRestaurantItem restaurant) {
    final category = restaurant.categoryLabel.trim();
    final description = restaurant.description.trim();
    final rating = restaurant.averageRating;
    return _DiscoverSpotData(
      id: restaurant.id,
      title: restaurant.name,
      handle: restaurant.id.isNotEmpty
          ? 'restaurant-${restaurant.id}'
          : restaurant.name.replaceAll(RegExp(r'\s+'), '').toLowerCase(),
      categoryTitle: category.isEmpty ? 'Restaurants' : category,
      subtitle: description.isNotEmpty
          ? description
          : (restaurant.address.isNotEmpty
                ? restaurant.address
                : 'Live restaurant on HungerRush'),
      deliveryLabel: '30 min',
      ratingLabel: rating == null ? '0.0' : rating.toStringAsFixed(1),
      priceTier: 2,
      badge: restaurant.menuItemsCount > 0
          ? '${restaurant.menuItemsCount} items'
          : 'Open',
      imageUrl: restaurant.profilePhotoUrl,
    );
  }

  Future<void> _openDiscoverSearch(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SearchScreen(allowFriendActions: true),
      ),
    );
  }

  Future<void> _openDiscoverFilters(BuildContext context) async {
    final result = await showModalBottomSheet<_DiscoverFiltersState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFEFCFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        var selectedCuisines = Set<String>.from(_activeCuisineFilters);
        var minimumRating = _minimumRatingFilter;
        int? maximumDeliveryMinutes = _maximumDeliveryMinutesFilter;
        int? maximumPriceTier = _maximumPriceTierFilter;
        return StatefulBuilder(
          builder: (context, setModalState) {
            String ratingLabelFor(double value) {
              if (value == 0) {
                return 'Any';
              }
              return '${value.toStringAsFixed(1)}+';
            }

            String deliveryLabelFor(int? value) {
              if (value == null) {
                return 'Any';
              }
              return '<= ${value}m';
            }

            String priceLabelFor(int? value) {
              if (value == null) {
                return 'Any';
              }
              if (value == 1) {
                return '\$';
              }
              return 'LL';
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8C6B8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Discover Filters',
                      style: TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Cuisines',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _DiscoverTabBody._categories
                          .map((category) {
                            final isSelected = selectedCuisines.contains(
                              category.title,
                            );
                            return FilterChip(
                              label: Text(category.title),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedCuisines.add(category.title);
                                  } else {
                                    selectedCuisines.remove(category.title);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFFFFE2D0),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Minimum rating',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final chips = <Widget>[];
                        for (final value in const <double>[0, 4.5, 4.8]) {
                          final isSelected = minimumRating == value;
                          chips.add(
                            ChoiceChip(
                              label: Text(ratingLabelFor(value)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => minimumRating = value),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(spacing: 8, runSpacing: 8, children: chips);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Delivery time',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final chips = <Widget>[];
                        for (final value in const <int?>[null, 15, 20]) {
                          final isSelected = maximumDeliveryMinutes == value;
                          chips.add(
                            ChoiceChip(
                              label: Text(deliveryLabelFor(value)),
                              selected: isSelected,
                              onSelected: (_) => setModalState(
                                () => maximumDeliveryMinutes = value,
                              ),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(spacing: 8, runSpacing: 8, children: chips);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Price',
                      style: TextStyle(
                        color: Color(0xFF5D4C41),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final chips = <Widget>[];
                        for (final value in const <int?>[null, 1, 2]) {
                          final isSelected = maximumPriceTier == value;
                          chips.add(
                            ChoiceChip(
                              label: Text(priceLabelFor(value)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => maximumPriceTier = value),
                              selectedColor: const Color(0xFFFFE2D0),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFF7E4D)
                                    : const Color(0xFF725F53),
                                fontWeight: FontWeight.w700,
                              ),
                              side: const BorderSide(color: Color(0xFFEAD9CB)),
                              backgroundColor: const Color(0xFFFFF8F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                        return Wrap(spacing: 8, runSpacing: 8, children: chips);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                sheetContext,
                              ).pop(const _DiscoverFiltersState());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7A6558),
                              side: const BorderSide(color: Color(0xFFE2D0C1)),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                _DiscoverFiltersState(
                                  selectedCuisineTitles: selectedCuisines,
                                  minimumRating: minimumRating,
                                  maximumDeliveryMinutes:
                                      maximumDeliveryMinutes,
                                  maximumPriceTier: maximumPriceTier,
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
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _activeCuisineFilters = Set<String>.from(result.selectedCuisineTitles);
      _minimumRatingFilter = result.minimumRating;
      _maximumDeliveryMinutesFilter = result.maximumDeliveryMinutes;
      _maximumPriceTierFilter = result.maximumPriceTier;
    });
  }

  Future<void> _openCuisineDetails(
    BuildContext context,
    _DiscoverCategoryData category,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DiscoverCuisineDetailsScreen(
          category: category,
          spots: _spotsForCuisine(category.title),
        ),
      ),
    );
  }

  Future<void> _openPopularSpot(
    BuildContext context,
    _DiscoverSpotData spot,
  ) async {
    await _openDiscoverRestaurantProfile(context, spot);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openPopularSpotMenu(
    BuildContext context,
    _DiscoverSpotData spot,
  ) async {
    final menuItems = await _discoverMenuItemsForSpot(spot);
    if (!mounted || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DiscoverRestaurantMenuScreen(
          spot: spot,
          items: menuItems,
          onItemTap: (item) =>
              _openDiscoverMenuItemDetails(context, spot, item),
        ),
      ),
    );
  }

  Future<List<RestaurantMenuItem>> _discoverMenuItemsForSpot(
    _DiscoverSpotData spot,
  ) async {
    final restaurantId = spot.id.trim();
    if (restaurantId.isNotEmpty) {
      final cached = _menuItemsByRestaurantId[restaurantId];
      if (cached != null) {
        return cached;
      }
      final session = await _resolveSession();
      if (session == null) {
        _showDiscoverSnackBar('Please log in again to load this menu.');
        return const <RestaurantMenuItem>[];
      }
      try {
        final menuItems = await _restaurantApiService.fetchRestaurantMenu(
          session: session,
          restaurantId: restaurantId,
        );
        _menuItemsByRestaurantId[restaurantId] = menuItems;
        return menuItems;
      } catch (_) {
        _showDiscoverSnackBar('Unable to load restaurant menu. Try again.');
        return const <RestaurantMenuItem>[];
      }
    }

    final category = spot.categoryTitle.trim().toLowerCase();
    switch (category) {
      case 'pizza':
        return _discoverPizzaMenuItems;
      case 'burgers':
        return _discoverBurgerMenuItems;
      case 'sushi':
        return _discoverSushiMenuItems;
      case 'desserts':
        return _discoverDessertMenuItems;
      default:
        return _discoverPizzaMenuItems;
    }
  }

  void _showDiscoverSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDiscoverMenuItemDetails(
    BuildContext context,
    _DiscoverSpotData spot,
    RestaurantMenuItem item,
  ) async {
    await showRestaurantMenuItemDetailsPopup(
      context,
      item: item,
      allowAddToCart: true,
      onAddToCart: (selectedItem) {
        final cartItem = _CartLineItemData(
          title: selectedItem.title,
          subtitle: '${spot.title} - ${selectedItem.category}',
          imageUrl: selectedItem.imageUrl,
          price: selectedItem.price ?? 0,
          quantity: 1,
          restaurantName: spot.title,
          restaurantId: spot.id,
          menuItemId: selectedItem.id,
        );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _OrdersCartScreen(
              initialItems: [cartItem],
              restaurantName: spot.title,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPopularSpotList(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _DiscoverPopularSpotsScreen(spots: _filteredPopularSpots),
      ),
    );
  }

  bool _isSpotSaved(_DiscoverSpotData spot) {
    final savedFromDiscoverHeart = widget.favoriteSpotTitles.contains(
      spot.title.trim(),
    );
    final savedFromProfileHeart = isCustomerRestaurantSaved(
      restaurantName: spot.title,
      handle: spot.handle,
    );
    return savedFromDiscoverHeart || savedFromProfileHeart;
  }

  Future<void> _toggleSpotFavorite(_DiscoverSpotData spot) async {
    final restaurantId = spot.id.trim();
    if (restaurantId.isNotEmpty &&
        !_pendingFavoriteRestaurantIds.add(restaurantId)) {
      return;
    }
    final nextSaved = !_isSpotSaved(spot);
    widget.onSetSpotFavorite(spot, nextSaved);
    if (restaurantId.isEmpty) {
      return;
    }
    try {
      final session = await _resolveSession();
      if (session == null) {
        throw const AuthApiException('Please log in again.');
      }
      if (nextSaved) {
        await _restaurantApiService.followRestaurant(
          session: session,
          restaurantId: restaurantId,
        );
      } else {
        await _restaurantApiService.unfollowRestaurant(
          session: session,
          restaurantId: restaurantId,
        );
      }
    } catch (error) {
      debugPrint('Discover restaurant follow failed: $error');
      if (mounted) {
        widget.onSetSpotFavorite(spot, !nextSaved);
        _showDiscoverSnackBar('Could not update follow status. Try again.');
      }
    } finally {
      if (restaurantId.isNotEmpty) {
        _pendingFavoriteRestaurantIds.remove(restaurantId);
      }
    }
  }

  void _openQuickCravingDetails(BuildContext context, _DiscoverDealData deal) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DiscoverDealDetailsSheet(
        data: deal,
        onAddToCart: (selectedDeal) =>
            _openQuickCravingCart(sheetContext, selectedDeal),
      ),
    );
  }

  void _openQuickCravingCart(
    BuildContext sheetContext,
    _DiscoverDealData deal,
  ) {
    final item = _CartLineItemData(
      title: deal.title,
      subtitle: 'Quick Cravings • ${deal.subtitle}',
      imageUrl: _quickCravingImageUrl(deal.title),
      price: _quickCravingPriceValue(deal.priceLabel),
      quantity: 1,
      restaurantName: 'Quick Cravings',
    );
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OrdersCartScreen(
            initialItems: [item],
            restaurantName: 'Quick Cravings',
          ),
        ),
      );
    });
  }

  double _quickCravingPriceValue(String priceLabel) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(priceLabel);
    if (match == null) {
      return 0;
    }
    return double.tryParse(match.group(1) ?? '') ?? 0;
  }

  String _quickCravingImageUrl(String title) {
    switch (title) {
      case 'Lunch Box Express':
        return 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80';
      case 'Sushi Night Combo':
        return 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=80';
      case 'Dessert Drop':
        return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80';
      default:
        return 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80';
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;
    final popularSpots = _filteredPopularSpots;

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
        return Stack(
          children: [
            const Positioned.fill(child: _DiscoverBackground()),
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
                            onTap: () => _openDiscoverFilters(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(18 * metrics.scale, 14, 18),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _DiscoverSearchBar(
                              metrics: metrics,
                              onTapSearch: () => _openDiscoverSearch(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _clampDouble(20 * metrics.scale, 16, 20),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _ProfileSectionHeader(
                                title: 'Browse Cuisines',
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
                                  126 * metrics.scale,
                                  112,
                                  126,
                                ),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount:
                                      _DiscoverTabBody._categories.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        width: _clampDouble(
                                          12 * metrics.scale,
                                          8,
                                          12,
                                        ),
                                      ),
                                  itemBuilder: (context, index) {
                                    final category =
                                        _DiscoverTabBody._categories[index];
                                    return _DiscoverCuisineChip(
                                      data: category,
                                      metrics: metrics,
                                      onTap: () => _openCuisineDetails(
                                        context,
                                        category,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              _ProfileSectionHeader(
                                title: 'Popular Restaurants',
                                actionLabel: 'See All',
                                onActionTap: () =>
                                    _openPopularSpotList(context),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              if (_isLoadingRestaurants)
                                _ProfilePanel(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      _clampDouble(18 * metrics.scale, 14, 18),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFFF7E4D),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_restaurantError != null)
                                _ProfilePanel(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      _clampDouble(18 * metrics.scale, 14, 18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _restaurantError!,
                                          style: const TextStyle(
                                            color: Color(0xFF7D6C60),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: _loadRestaurants,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (popularSpots.isEmpty)
                                _ProfilePanel(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      _clampDouble(18 * metrics.scale, 14, 18),
                                    ),
                                    child: const Text(
                                      'No restaurants available yet.',
                                      style: TextStyle(
                                        color: Color(0xFF7D6C60),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: _clampDouble(
                                    320 * metrics.scale,
                                    286,
                                    320,
                                  ),
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: popularSpots.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                          width: _clampDouble(
                                            14 * metrics.scale,
                                            10,
                                            14,
                                          ),
                                        ),
                                    itemBuilder: (context, index) {
                                      final spot = popularSpots[index];
                                      return _DiscoverSpotCard(
                                        data: spot,
                                        metrics: metrics,
                                        isFavorite: _isSpotSaved(spot),
                                        onTap: () =>
                                            _openPopularSpot(context, spot),
                                        onViewMenuTap: () =>
                                            _openPopularSpotMenu(context, spot),
                                        onFavoriteTap: () => unawaited(
                                          _toggleSpotFavorite(spot),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              const _ProfileSectionHeader(
                                title: 'Quick Cravings',
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              _ProfilePanel(
                                child: Column(
                                  children: List.generate(
                                    _DiscoverTabBody._quickCravings.length,
                                    (index) {
                                      final item = _DiscoverTabBody
                                          ._quickCravings[index];
                                      return Column(
                                        children: [
                                          _DiscoverDealTile(
                                            data: item,
                                            metrics: metrics,
                                            onTap: () =>
                                                _openQuickCravingDetails(
                                                  context,
                                                  item,
                                                ),
                                          ),
                                          if (index !=
                                              _DiscoverTabBody
                                                      ._quickCravings
                                                      .length -
                                                  1)
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFF0E2D3),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: _clampDouble(12 * metrics.scale, 8, 12),
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
          ],
        );
      },
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

class _DiscoverSearchBar extends StatelessWidget {
  const _DiscoverSearchBar({required this.metrics, required this.onTapSearch});

  final _ResponsiveMetrics metrics;
  final VoidCallback onTapSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapSearch,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
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
                  'Search users or restaurants',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF9D8A7D),
                    fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                    fontWeight: FontWeight.w600,
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

class _DiscoverCuisineChip extends StatelessWidget {
  const _DiscoverCuisineChip({
    required this.data,
    required this.metrics,
    required this.onTap,
  });

  final _DiscoverCategoryData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
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
        ),
      ),
    );
  }
}

class _DiscoverSpotCard extends StatelessWidget {
  const _DiscoverSpotCard({
    required this.data,
    required this.metrics,
    required this.isFavorite,
    required this.onTap,
    required this.onViewMenuTap,
    required this.onFavoriteTap,
  });

  final _DiscoverSpotData data;
  final _ResponsiveMetrics metrics;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onViewMenuTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _clampDouble(metrics.width * 0.72, 244, 284);
    final imageHeight = _clampDouble(
      (metrics.compact ? 110 : 128) * metrics.scale,
      metrics.compact ? 96 : 112,
      metrics.compact ? 110 : 128,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
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
                    child: Material(
                      color: const Color(0xFFFDF9F6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onFavoriteTap,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: _clampDouble(34 * metrics.scale, 30, 34),
                          height: _clampDouble(34 * metrics.scale, 30, 34),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? const Color(0xFFFF7E4D)
                                : const Color(0xFF8D7464),
                            size: _clampDouble(20 * metrics.scale, 16, 20),
                          ),
                        ),
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
                              horizontal: _clampDouble(
                                12 * metrics.scale,
                                9,
                                12,
                              ),
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
                                fontSize: _clampDouble(
                                  12 * metrics.scale,
                                  10,
                                  12,
                                ),
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
                          SizedBox(
                            width: _clampDouble(4 * metrics.scale, 2, 4),
                          ),
                          Text(
                            data.ratingLabel,
                            style: TextStyle(
                              color: const Color(0xFF5A4A40),
                              fontSize: _clampDouble(
                                14 * metrics.scale,
                                11,
                                14,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onViewMenuTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: _clampDouble(
                                13 * metrics.scale,
                                10,
                                13,
                              ),
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
                                fontSize: _clampDouble(
                                  12.5 * metrics.scale,
                                  10,
                                  12.5,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
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
    );
  }
}

class _DiscoverDealTile extends StatelessWidget {
  const _DiscoverDealTile({
    required this.data,
    required this.metrics,
    required this.onTap,
  });

  final _DiscoverDealData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
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
                        SizedBox(
                          height: _clampDouble(12 * metrics.scale, 8, 12),
                        ),
                        Align(alignment: Alignment.centerRight, child: meta),
                      ],
                    )
                  : Row(
                      children: [
                        iconTile,
                        SizedBox(
                          width: _clampDouble(14 * metrics.scale, 10, 14),
                        ),
                        Expanded(child: details),
                        SizedBox(
                          width: _clampDouble(10 * metrics.scale, 8, 10),
                        ),
                        meta,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _openDiscoverRestaurantProfile(
  BuildContext context,
  _DiscoverSpotData spot, {
  int initialTabIndex = 0,
}) {
  final reviewPreviews = _buildDemoRestaurantReviews(
    restaurantName: spot.title,
    rating: spot.ratingValue,
  );
  return showRestaurantProfilePopup(
    context,
    restaurantName: spot.title,
    handle: spot.handle,
    rating: spot.ratingValue,
    caption: spot.subtitle,
    initialTabIndex: initialTabIndex,
    followersCountLabel:
        '${_formatCompactCount(8400 + (spot.deliveryMinutes * 28))} followers',
    allowAddToCart: true,
    showFollowButton: true,
    showSaveButton: true,
    reviews: reviewPreviews,
    onOpenReviews: () {
      openRestaurantReviewsPage(
        context,
        restaurantName: spot.title,
        rating: spot.ratingValue,
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

class _DiscoverCuisineDetailsScreen extends StatelessWidget {
  const _DiscoverCuisineDetailsScreen({
    required this.category,
    required this.spots,
  });

  final _DiscoverCategoryData category;
  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    return _DiscoverSpotsCatalogScreen(
      title: category.title,
      subtitle: category.subtitle,
      spots: spots,
    );
  }
}

class _DiscoverPopularSpotsScreen extends StatelessWidget {
  const _DiscoverPopularSpotsScreen({required this.spots});

  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    return _DiscoverSpotsCatalogScreen(
      title: 'Popular Restaurants',
      subtitle: 'Top picks around your area',
      spots: spots,
    );
  }
}

class _DiscoverSpotsCatalogScreen extends StatelessWidget {
  const _DiscoverSpotsCatalogScreen({
    required this.title,
    required this.subtitle,
    required this.spots,
  });

  final String title;
  final String subtitle;
  final List<_DiscoverSpotData> spots;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7C6A5F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: spots.isEmpty
                    ? const Center(
                        child: Text(
                          'No restaurants available yet.',
                          style: TextStyle(
                            color: Color(0xFF7D6C60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: spots.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _DiscoverSpotPreviewTile(spot: spots[index]);
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

class _DiscoverSpotPreviewTile extends StatelessWidget {
  const _DiscoverSpotPreviewTile({required this.spot});

  final _DiscoverSpotData spot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEFCFA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openDiscoverRestaurantProfile(context, spot),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  spot.imageUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFFFE6D3),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFFFF7E4D),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFFFF7E4D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          spot.deliveryLabel,
                          style: const TextStyle(
                            color: Color(0xFFFF7E4D),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF5B63F),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          spot.ratingLabel,
                          style: const TextStyle(
                            color: Color(0xFF6B594D),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E8A7E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverRestaurantMenuScreen extends StatefulWidget {
  const _DiscoverRestaurantMenuScreen({
    required this.spot,
    required this.items,
    required this.onItemTap,
  });

  final _DiscoverSpotData spot;
  final List<RestaurantMenuItem> items;
  final ValueChanged<RestaurantMenuItem> onItemTap;

  @override
  State<_DiscoverRestaurantMenuScreen> createState() =>
      _DiscoverRestaurantMenuScreenState();
}

class _DiscoverRestaurantMenuScreenState
    extends State<_DiscoverRestaurantMenuScreen> {
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

  List<RestaurantMenuItem> get _filteredItems {
    if (_selectedCategory == _allCategory) {
      return widget.items;
    }
    final normalized = _selectedCategory.toLowerCase();
    return widget.items
        .where((item) => item.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  String _formatUsd(double? value) {
    if (value == null) {
      return '--';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  double _averagePrice(List<RestaurantMenuItem> menuItems) {
    if (menuItems.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    for (final item in menuItems) {
      sum += item.price ?? 0;
    }
    return sum / menuItems.length;
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final metrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    final categories = _categories;
    final filteredItems = _filteredItems;
    final availableCount = filteredItems
        .where((item) => item.isAvailable)
        .length;
    final popularCount = filteredItems.where((item) => item.isPopular).length;
    final averagePrice = _averagePrice(filteredItems);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.spot.title} Menu',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF4D6BF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7E4D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Section',
                            style: TextStyle(
                              color: const Color(0xFF2C231D),
                              fontSize: _clampDouble(
                                16 * metrics.scale,
                                13,
                                16,
                              ),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.spot.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF7E6D62),
                              fontSize: _clampDouble(
                                12.5 * metrics.scale,
                                10.5,
                                12.5,
                              ),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Items',
                      value: '${filteredItems.length}',
                      icon: Icons.format_list_bulleted_rounded,
                      iconColor: const Color(0xFFFF7E4D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Available',
                      value: '$availableCount',
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF2E9B57),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Popular',
                      value: '$popularCount',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF0A523),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DiscoverMenuStatCard(
                      label: 'Avg',
                      value: _formatUsd(averagePrice),
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF4B7AA3),
                    ),
                  ),
                ],
              ),
              if (categories.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                          fontSize: 12,
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
              ],
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No menu items found.',
                          style: TextStyle(
                            color: Color(0xFF7D6C60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _DiscoverMenuItemCard(
                            item: item,
                            priceLabel: _formatUsd(item.price),
                            onTap: () => widget.onItemTap(item),
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

class _DiscoverMenuStatCard extends StatelessWidget {
  const _DiscoverMenuStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DACD)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1F1B19),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8D7E73),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverMenuItemCard extends StatelessWidget {
  const _DiscoverMenuItemCard({
    required this.item,
    required this.priceLabel,
    required this.onTap,
  });

  final RestaurantMenuItem item;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9DACD)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD6B4), Color(0xFFFF9C6C)],
                          ),
                        ),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                            style: const TextStyle(
                              color: Color(0xFF1F1B19),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFFF7E4D),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C7D71),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _DiscoverMenuBadge(
                          label: item.category,
                          backgroundColor: const Color(0xFFEFE8E1),
                          textColor: const Color(0xFF786658),
                        ),
                        _DiscoverMenuBadge(
                          label: item.isAvailable ? 'Available' : 'Paused',
                          backgroundColor: item.isAvailable
                              ? const Color(0xFFE1F5E8)
                              : const Color(0xFFFDE4E2),
                          textColor: item.isAvailable
                              ? const Color(0xFF2E9B57)
                              : const Color(0xFFC6463E),
                        ),
                        if (item.isPopular)
                          const _DiscoverMenuBadge(
                            label: 'Popular',
                            backgroundColor: Color(0xFFE8EFF7),
                            textColor: Color(0xFF43739C),
                          ),
                        if (item.rating != null)
                          _DiscoverMenuBadge(
                            label: '${item.rating!.toStringAsFixed(1)}*',
                            backgroundColor: const Color(0xFFFFF1CC),
                            textColor: const Color(0xFFB07800),
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

class _DiscoverMenuBadge extends StatelessWidget {
  const _DiscoverMenuBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DiscoverDealDetailsSheet extends StatelessWidget {
  const _DiscoverDealDetailsSheet({required this.data, this.onAddToCart});

  final _DiscoverDealData data;
  final ValueChanged<_DiscoverDealData>? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEFCFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8C6B8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: data.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(data.icon, color: data.accentColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.subtitle,
                style: const TextStyle(
                  color: Color(0xFF7F6D61),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    data.priceLabel,
                    style: const TextStyle(
                      color: Color(0xFF231A16),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: data.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.promoLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (onAddToCart != null) {
                      onAddToCart!(data);
                      return;
                    }
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger
                      ?..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text('${data.title} added to cart')),
                      );
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text(
                    'Add To Cart',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
    this.id = '',
    required this.title,
    required this.handle,
    required this.categoryTitle,
    required this.subtitle,
    required this.deliveryLabel,
    required this.ratingLabel,
    required this.priceTier,
    required this.badge,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String handle;
  final String categoryTitle;
  final String subtitle;
  final String deliveryLabel;
  final String ratingLabel;
  final int priceTier;
  final String badge;
  final String imageUrl;

  int get deliveryMinutes =>
      int.tryParse(deliveryLabel.split(' ').first.trim()) ?? 999;

  double get ratingValue => double.tryParse(ratingLabel.trim()) ?? 0;
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

const List<RestaurantMenuItem> _discoverPizzaMenuItems = [
  RestaurantMenuItem(
    id: 'pizza-margherita',
    title: 'Margherita Fire',
    description: 'Fresh mozzarella, basil leaves, tomato sauce, and olive oil.',
    price: 10.80,
    imageUrl:
        'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=900&q=80',
    category: 'Pizza',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 180,
  ),
  RestaurantMenuItem(
    id: 'pizza-pepperoni',
    title: 'Pepperoni Feast',
    description: 'Loaded pepperoni slices, melted mozzarella, and oregano.',
    price: 12.40,
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
    category: 'Pizza',
    isAvailable: true,
    isPopular: true,
    rating: 4.9,
    ordersCount: 216,
  ),
  RestaurantMenuItem(
    id: 'pizza-truffle',
    title: 'Truffle Burrata',
    description: 'Burrata cream, mushrooms, truffle oil, and parmesan flakes.',
    price: 14.60,
    imageUrl:
        'https://images.unsplash.com/photo-1593504049359-74330189a345?auto=format&fit=crop&w=900&q=80',
    category: 'Signature',
    isAvailable: true,
    isPopular: false,
    rating: 4.7,
    ordersCount: 94,
  ),
  RestaurantMenuItem(
    id: 'pizza-garlic-knots',
    title: 'Garlic Knots',
    description: 'Six golden knots brushed with butter, parsley, and parmesan.',
    price: 4.90,
    imageUrl:
        'https://images.unsplash.com/photo-1619531038896-dc1a44a84f95?auto=format&fit=crop&w=900&q=80',
    category: 'Starters',
    isAvailable: true,
    isPopular: false,
    rating: 4.6,
    ordersCount: 102,
  ),
];

const List<RestaurantMenuItem> _discoverBurgerMenuItems = [
  RestaurantMenuItem(
    id: 'burger-angus',
    title: 'Double Angus Stack',
    description: 'Two smashed patties, cheddar, pickles, and signature sauce.',
    price: 13.20,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
    category: 'Burgers',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 228,
  ),
  RestaurantMenuItem(
    id: 'burger-classic',
    title: 'Classic Smash',
    description: 'Smash beef patty, lettuce, tomato, onion, and burger sauce.',
    price: 9.90,
    imageUrl:
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
    category: 'Burgers',
    isAvailable: true,
    isPopular: true,
    rating: 4.7,
    ordersCount: 172,
  ),
  RestaurantMenuItem(
    id: 'burger-cajun-fries',
    title: 'Cajun Fries',
    description: 'Seasoned crispy fries with smoky paprika and sea salt.',
    price: 4.30,
    imageUrl:
        'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=900&q=80',
    category: 'Sides',
    isAvailable: true,
    isPopular: false,
    rating: 4.5,
    ordersCount: 132,
  ),
  RestaurantMenuItem(
    id: 'burger-milkshake',
    title: 'Vanilla Milkshake',
    description: 'Creamy vanilla shake topped with whipped cream.',
    price: 3.80,
    imageUrl:
        'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=900&q=80',
    category: 'Drinks',
    isAvailable: true,
    isPopular: false,
    rating: 4.4,
    ordersCount: 88,
  ),
];

const List<RestaurantMenuItem> _discoverSushiMenuItems = [
  RestaurantMenuItem(
    id: 'sushi-salmon-roll',
    title: 'Salmon Crunch Roll',
    description: 'Salmon, avocado, cucumber, crispy flakes, and teriyaki.',
    price: 11.70,
    imageUrl:
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=80',
    category: 'Sushi',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 166,
  ),
  RestaurantMenuItem(
    id: 'sushi-dragon-roll',
    title: 'Dragon Roll',
    description: 'Shrimp tempura, avocado, eel sauce, and sesame.',
    price: 13.90,
    imageUrl:
        'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?auto=format&fit=crop&w=900&q=80',
    category: 'Sushi',
    isAvailable: true,
    isPopular: true,
    rating: 4.9,
    ordersCount: 145,
  ),
  RestaurantMenuItem(
    id: 'sushi-poke-bowl',
    title: 'Tuna Poke Bowl',
    description: 'Marinated tuna, rice, mango, edamame, and spicy mayo.',
    price: 12.50,
    imageUrl:
        'https://images.unsplash.com/photo-1604908554027-6e8f3f2b54f8?auto=format&fit=crop&w=900&q=80',
    category: 'Bowls',
    isAvailable: true,
    isPopular: false,
    rating: 4.6,
    ordersCount: 104,
  ),
  RestaurantMenuItem(
    id: 'sushi-miso-soup',
    title: 'Miso Soup',
    description: 'Warm miso broth with tofu cubes, seaweed, and scallions.',
    price: 3.20,
    imageUrl:
        'https://images.unsplash.com/photo-1623341214825-9f4f963727da?auto=format&fit=crop&w=900&q=80',
    category: 'Sides',
    isAvailable: true,
    isPopular: false,
    rating: 4.5,
    ordersCount: 93,
  ),
];

const List<RestaurantMenuItem> _discoverDessertMenuItems = [
  RestaurantMenuItem(
    id: 'dessert-lava-cake',
    title: 'Chocolate Lava Cake',
    description: 'Warm molten center cake with vanilla cream.',
    price: 7.10,
    imageUrl:
        'https://images.unsplash.com/photo-1621303837174-89787a7d4729?auto=format&fit=crop&w=900&q=80',
    category: 'Desserts',
    isAvailable: true,
    isPopular: true,
    rating: 4.9,
    ordersCount: 194,
  ),
  RestaurantMenuItem(
    id: 'dessert-gelato',
    title: 'Pistachio Gelato',
    description: 'Small-batch gelato topped with crushed pistachio.',
    price: 5.40,
    imageUrl:
        'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=900&q=80',
    category: 'Desserts',
    isAvailable: true,
    isPopular: true,
    rating: 4.8,
    ordersCount: 152,
  ),
  RestaurantMenuItem(
    id: 'dessert-cheesecake',
    title: 'Berry Cheesecake',
    description: 'Creamy cheesecake with mixed berry compote.',
    price: 6.70,
    imageUrl:
        'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=900&q=80',
    category: 'Desserts',
    isAvailable: true,
    isPopular: false,
    rating: 4.7,
    ordersCount: 98,
  ),
  RestaurantMenuItem(
    id: 'dessert-cookies',
    title: 'Chocolate Chip Cookies',
    description: 'Three soft-baked cookies with dark chocolate chunks.',
    price: 4.20,
    imageUrl:
        'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&w=900&q=80',
    category: 'Bakery',
    isAvailable: true,
    isPopular: false,
    rating: 4.5,
    ordersCount: 86,
  ),
];

class _DiscoverFiltersState {
  const _DiscoverFiltersState({
    this.selectedCuisineTitles = const <String>{},
    this.minimumRating = 0,
    this.maximumDeliveryMinutes,
    this.maximumPriceTier,
  });

  final Set<String> selectedCuisineTitles;
  final double minimumRating;
  final int? maximumDeliveryMinutes;
  final int? maximumPriceTier;
}
