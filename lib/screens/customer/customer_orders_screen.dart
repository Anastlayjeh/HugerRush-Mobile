part of '../user_home_screen.dart';

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
      reorderItems: [
        _CartLineItemData(
          title: 'Angus Burger Combo',
          subtitle: 'Burger Station - No onions',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
          price: 12.50,
          quantity: 1,
          restaurantName: 'Burger Station',
        ),
        _CartLineItemData(
          title: 'Cajun Fries',
          subtitle: 'Large - Extra crispy',
          imageUrl:
              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=900&q=80',
          price: 4.80,
          quantity: 1,
          restaurantName: 'Burger Station',
        ),
      ],
    ),
    _PastOrderEntryData(
      title: 'Napoli Fire',
      summary: '1 item - Pepperoni feast with extra mozzarella',
      dateLabel: 'Yesterday, 7:18 PM',
      totalLabel: '\$18.90',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
      reorderItems: [
        _CartLineItemData(
          title: 'Pepperoni Feast',
          subtitle: 'Napoli Fire - Extra mozzarella',
          imageUrl:
              'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
          price: 14.00,
          quantity: 1,
          restaurantName: 'Napoli Fire',
        ),
      ],
    ),
    _PastOrderEntryData(
      title: 'Bean & Brew',
      summary: '3 items - iced latte, brownie, and turkey sandwich',
      dateLabel: 'Apr 25, 9:06 AM',
      totalLabel: '\$16.40',
      status: _OrderStatus.rejected,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      reorderItems: [
        _CartLineItemData(
          title: 'Iced Latte',
          subtitle: 'Bean & Brew - Medium',
          imageUrl:
              'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
          price: 4.20,
          quantity: 1,
          restaurantName: 'Bean & Brew',
        ),
        _CartLineItemData(
          title: 'Brownie',
          subtitle: 'Chocolate',
          imageUrl:
              'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=900&q=80',
          price: 3.10,
          quantity: 1,
          restaurantName: 'Bean & Brew',
        ),
        _CartLineItemData(
          title: 'Turkey Sandwich',
          subtitle: 'Whole wheat',
          imageUrl:
              'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=900&q=80',
          price: 5.50,
          quantity: 1,
          restaurantName: 'Bean & Brew',
        ),
      ],
    ),
  ];

  static const List<_OrderReceiptData> _orderReceipts = [
    _OrderReceiptData(
      orderId: 'HR-2048',
      restaurantName: 'Burger Station',
      summary: '2 items - Angus burger and Cajun fries',
      placedAtLabel: 'Today, 12:24 PM',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      paymentMethodLabel: 'Paid online',
      deliveryFee: 2.75,
      serviceFee: 1.25,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: [
        _OrderReceiptLineItemData(
          title: 'Angus Burger Combo',
          subtitle: 'No onions',
          quantity: 1,
          unitPrice: 12.50,
        ),
        _OrderReceiptLineItemData(
          title: 'Cajun Fries',
          subtitle: 'Large, extra crispy',
          quantity: 1,
          unitPrice: 4.80,
        ),
        _OrderReceiptLineItemData(
          title: 'Cola',
          subtitle: 'Regular',
          quantity: 2,
          unitPrice: 1.60,
        ),
      ],
    ),
    _OrderReceiptData(
      orderId: 'HR-2047',
      restaurantName: 'Napoli Fire',
      summary: '1 item - Pepperoni feast with extra mozzarella',
      placedAtLabel: 'Yesterday, 7:18 PM',
      status: _OrderStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
      paymentMethodLabel: 'On delivery',
      deliveryFee: 2.25,
      serviceFee: 1.15,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: [
        _OrderReceiptLineItemData(
          title: 'Pepperoni Feast',
          subtitle: 'Extra mozzarella',
          quantity: 1,
          unitPrice: 14.00,
        ),
        _OrderReceiptLineItemData(
          title: 'Garlic Bread',
          subtitle: '4 pieces',
          quantity: 1,
          unitPrice: 1.50,
        ),
      ],
    ),
    _OrderReceiptData(
      orderId: 'HR-2046',
      restaurantName: 'Bean & Brew',
      summary: '3 items - iced latte, brownie, and turkey sandwich',
      placedAtLabel: 'Apr 25, 9:06 AM',
      status: _OrderStatus.rejected,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      paymentMethodLabel: 'Refunded',
      deliveryFee: 2.30,
      serviceFee: 1.30,
      discountPercent: 0,
      loyaltyPointsUsed: 0,
      loyaltyDiscountUsd: 0,
      items: [
        _OrderReceiptLineItemData(
          title: 'Iced Latte',
          subtitle: 'Medium',
          quantity: 1,
          unitPrice: 4.20,
        ),
        _OrderReceiptLineItemData(
          title: 'Brownie',
          subtitle: 'Chocolate',
          quantity: 1,
          unitPrice: 3.10,
        ),
        _OrderReceiptLineItemData(
          title: 'Turkey Sandwich',
          subtitle: 'Whole wheat',
          quantity: 1,
          unitPrice: 5.50,
        ),
      ],
    ),
  ];

  static const List<_RestaurantCartData> _ordersMenuCarts = [
    _RestaurantCartData(
      restaurantName: 'Burger Station',
      items: [
        _CartLineItemData(
          title: 'Angus Burger Combo',
          subtitle: 'No onions',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
          price: 12.50,
          quantity: 1,
          restaurantName: 'Burger Station',
        ),
        _CartLineItemData(
          title: 'Cajun Fries',
          subtitle: 'Large • Extra crispy',
          imageUrl:
              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=900&q=80',
          price: 4.80,
          quantity: 1,
          restaurantName: 'Burger Station',
        ),
      ],
    ),
    _RestaurantCartData(
      restaurantName: 'Napoli Fire',
      items: [
        _CartLineItemData(
          title: 'Pepperoni Feast',
          subtitle: 'Extra mozzarella',
          imageUrl:
              'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
          price: 14.00,
          quantity: 1,
          restaurantName: 'Napoli Fire',
        ),
      ],
    ),
    _RestaurantCartData(
      restaurantName: 'Bean & Brew',
      items: [
        _CartLineItemData(
          title: 'Iced Latte',
          subtitle: 'Medium',
          imageUrl:
              'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
          price: 5.25,
          quantity: 2,
          restaurantName: 'Bean & Brew',
        ),
      ],
    ),
  ];

  void _openOrderHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _OrdersReceiptsScreen(receipts: _orderReceipts),
      ),
    );
  }

  void _openCart(
    BuildContext context, {
    List<_CartLineItemData>? initialItems,
    String? restaurantName,
  }) {
    if (initialItems == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OrdersCartListScreen(carts: _ordersMenuCarts),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrdersCartScreen(
          initialItems: initialItems,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  void _reorderPastOrder(BuildContext context, _PastOrderEntryData order) {
    _openCart(
      context,
      initialItems: order.reorderItems,
      restaurantName: order.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;

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
            const Positioned.fill(child: _OrdersBackground()),
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
                            onTap: () => _openOrderHistory(context),
                          ),
                          SizedBox(
                            width: _clampDouble(10 * metrics.scale, 8, 10),
                          ),
                          _ProfileIconButton(
                            icon: Icons.shopping_cart_checkout_rounded,
                            metrics: metrics,
                            onTap: () => _openCart(context),
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
                              _OrdersHeroCard(
                                metrics: metrics,
                                metricsData: _heroMetrics,
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
                                ),
                              ),
                              _ProfileSectionHeader(
                                title: 'Live Order',
                                actionLabel: 'Need Help?',
                                onActionTap: () {
                                  showOrderIssueSheet(
                                    context,
                                    orderId: 'HR-2048',
                                    restaurantName: 'Burger Station',
                                  );
                                },
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  14 * metrics.scale,
                                  10,
                                  14,
                                ),
                              ),
                              _ActiveOrderCard(
                                metrics: metrics,
                                currentStatus: _activeStatus,
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
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
                                      onReorder: () => _reorderPastOrder(
                                        context,
                                        _pastOrders[index],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(
                                height: _clampDouble(
                                  26 * metrics.scale,
                                  20,
                                  26,
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

class _OrdersReceiptsScreen extends StatelessWidget {
  const _OrdersReceiptsScreen({required this.receipts});

  final List<_OrderReceiptData> receipts;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final metrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Order Receipts',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: receipts.isEmpty
            ? const Center(
                child: Text(
                  'No receipts available yet.',
                  style: TextStyle(
                    color: Color(0xFF7D6C60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: receipts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final receipt = receipts[index];
                  return _OrderReceiptListTile(
                    receipt: receipt,
                    metrics: metrics,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _OrderReceiptDetailsScreen(receipt: receipt),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _OrderReceiptListTile extends StatelessWidget {
  const _OrderReceiptListTile({
    required this.receipt,
    required this.metrics,
    required this.onTap,
  });

  final _OrderReceiptData receipt;
  final _ResponsiveMetrics metrics;
  final VoidCallback onTap;

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final imageSize = _clampDouble(76 * metrics.scale, 64, 76);
    return _ProfilePanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 12, 14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FoodThumb(imageUrl: receipt.imageUrl, size: imageSize),
                SizedBox(width: _clampDouble(12 * metrics.scale, 10, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF231A16),
                          fontSize: _clampDouble(17 * metrics.scale, 14, 17),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: _clampDouble(4 * metrics.scale, 2, 4)),
                      Text(
                        '${receipt.orderId} - ${receipt.summary}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7E6D62),
                          fontSize: _clampDouble(
                            12.8 * metrics.scale,
                            11,
                            12.8,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
                      Wrap(
                        spacing: _clampDouble(8 * metrics.scale, 6, 8),
                        runSpacing: _clampDouble(8 * metrics.scale, 6, 8),
                        children: [
                          _OrdersInfoChip(
                            label: receipt.placedAtLabel,
                            icon: Icons.schedule_rounded,
                            metrics: metrics,
                          ),
                          _OrderStatusPill(
                            status: receipt.status,
                            metrics: metrics,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatUsd(receipt.totalUsd),
                      style: TextStyle(
                        color: const Color(0xFF231A16),
                        fontSize: _clampDouble(17 * metrics.scale, 14, 17),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFFB19D8F),
                      size: _clampDouble(24 * metrics.scale, 20, 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderReceiptDetailsScreen extends StatelessWidget {
  const _OrderReceiptDetailsScreen({required this.receipt});

  static const double _usdToLbpRate = 89500;

  final _OrderReceiptData receipt;

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatLbp(double usdValue) {
    final lbpValue = (usdValue * _usdToLbpRate).round();
    final withCommas = lbpValue.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas LBP';
  }

  List<_OrderTimelineStepData> _buildStages() {
    if (receipt.status == _OrderStatus.canceled ||
        receipt.status == _OrderStatus.rejected) {
      final steps = List<_OrderTimelineStepData>.generate(
        _orderStatusFlow.length,
        (index) {
          final stepStatus = _orderStatusFlow[index];
          return _OrderTimelineStepData(
            status: stepStatus,
            title: _orderStatusLabel(stepStatus),
            subtitle: _orderStatusDescription(stepStatus),
            icon: _orderStatusIcon(stepStatus),
            isComplete: index == 0,
            isCurrent: false,
          );
        },
      );
      steps.add(
        _OrderTimelineStepData(
          status: receipt.status,
          title: _orderStatusLabel(receipt.status),
          subtitle: _orderStatusDescription(receipt.status),
          icon: _orderStatusIcon(receipt.status),
          isComplete: false,
          isCurrent: true,
        ),
      );
      return steps;
    }

    final rawIndex = _orderStatusFlow.indexOf(receipt.status);
    final currentIndex = rawIndex.clamp(0, _orderStatusFlow.length - 1).toInt();
    return List<_OrderTimelineStepData>.generate(_orderStatusFlow.length, (
      index,
    ) {
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

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final metrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    final stages = _buildStages();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Receipt #${receipt.orderId}',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FoodThumb(
                      imageUrl: receipt.imageUrl,
                      size: _clampDouble(82 * metrics.scale, 70, 82),
                    ),
                    SizedBox(width: _clampDouble(12 * metrics.scale, 10, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF231A16),
                              fontSize: _clampDouble(
                                19 * metrics.scale,
                                16,
                                19,
                              ),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(
                            height: _clampDouble(4 * metrics.scale, 2, 4),
                          ),
                          Text(
                            receipt.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF7D6C60),
                              fontSize: _clampDouble(
                                13.5 * metrics.scale,
                                11,
                                13.5,
                              ),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(
                            height: _clampDouble(10 * metrics.scale, 8, 10),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _OrdersInfoChip(
                                label: receipt.placedAtLabel,
                                icon: Icons.schedule_rounded,
                                metrics: metrics,
                              ),
                              _OrdersInfoChip(
                                label: receipt.paymentMethodLabel,
                                icon: Icons.payments_rounded,
                                metrics: metrics,
                              ),
                              _OrderStatusPill(
                                status: receipt.status,
                                metrics: metrics,
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
            const SizedBox(height: 12),
            _CheckoutSectionCard(
              title: 'Order Stages',
              child: Column(
                children: List.generate(stages.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == stages.length - 1 ? 0 : 10,
                    ),
                    child: _OrderTimelineRow(
                      data: stages[index],
                      metrics: metrics,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _CheckoutSectionCard(
              title: 'Items Ordered (${receipt.totalItems})',
              child: Column(
                children: List.generate(receipt.items.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == receipt.items.length - 1 ? 0 : 8,
                    ),
                    child: _OrderReceiptItemTile(item: receipt.items[index]),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _CheckoutSectionCard(
              title: 'Receipt Details',
              child: Column(
                children: [
                  _OrdersPriceRow(
                    label: 'Subtotal',
                    value: _formatUsd(receipt.subtotalUsd),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Delivery fee',
                    value: _formatUsd(receipt.deliveryFee),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Service fee',
                    value: _formatUsd(receipt.serviceFee),
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Discount (%)',
                    value: '${receipt.discountPercent.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Loyalty points used',
                    value: '${receipt.loyaltyPointsUsed} pts',
                  ),
                  if (receipt.loyaltyDiscountUsd > 0) ...[
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Loyalty discount',
                      value: '-${_formatUsd(receipt.loyaltyDiscountUsd)}',
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEADBCB)),
                  const SizedBox(height: 10),
                  _OrdersPriceRow(
                    label: 'Total (USD)',
                    value: _formatUsd(receipt.totalUsd),
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Total (LBP)',
                    value: _formatLbp(receipt.totalUsd),
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _OrdersPriceRow(
                    label: 'Payment',
                    value: receipt.paymentMethodLabel,
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

class _OrderReceiptItemTile extends StatelessWidget {
  const _OrderReceiptItemTile({required this.item});

  final _OrderReceiptLineItemData item;

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E2D4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D6C60),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x${item.quantity}',
            style: const TextStyle(
              color: Color(0xFF7D6C60),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _formatUsd(item.totalPrice),
            style: const TextStyle(
              color: Color(0xFFFF7E4D),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersCartListScreen extends StatelessWidget {
  const _OrdersCartListScreen({required this.carts});

  final List<_RestaurantCartData> carts;

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Your Carts',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: carts.isEmpty
              ? const Center(
                  child: Text(
                    'No carts yet. Add items from a restaurant first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7D6C60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF2D8C4)),
                      ),
                      child: const Text(
                        'Checkout supports one restaurant at a time.',
                        style: TextStyle(
                          color: Color(0xFF9B5B38),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: carts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cart = carts[index];
                          return _OrdersCartListTile(
                            restaurantName: cart.restaurantName,
                            totalItems: cart.totalItems,
                            subtotalLabel: _formatMoney(cart.subtotal),
                            coverImageUrl: cart.coverImageUrl,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _OrdersCartScreen(
                                    initialItems: cart.items,
                                    restaurantName: cart.restaurantName,
                                  ),
                                ),
                              );
                            },
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

class _OrdersCartListTile extends StatelessWidget {
  const _OrdersCartListTile({
    required this.restaurantName,
    required this.totalItems,
    required this.subtotalLabel,
    required this.coverImageUrl,
    required this.onTap,
  });

  final String restaurantName;
  final int totalItems;
  final String subtotalLabel;
  final String coverImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0DCCB)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  coverImageUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: const Color(0xFFFFE9D7),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFFFF7E4D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalItems item${totalItems == 1 ? '' : 's'} • $subtotalLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E8A7E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersCartScreen extends StatefulWidget {
  const _OrdersCartScreen({required this.initialItems, this.restaurantName});

  final List<_CartLineItemData> initialItems;
  final String? restaurantName;

  @override
  State<_OrdersCartScreen> createState() => _OrdersCartScreenState();
}

class _OrdersCartScreenState extends State<_OrdersCartScreen> {
  static const double _deliveryFee = 2.75;
  static const double _serviceFee = 1.35;

  late List<_CartLineItemData> _items;
  late String _restaurantName;

  @override
  void initState() {
    super.initState();
    final explicitRestaurant = widget.restaurantName?.trim() ?? '';
    final fallbackRestaurant = _firstRestaurantNameFromItems(
      widget.initialItems,
    );
    _restaurantName = explicitRestaurant.isNotEmpty
        ? explicitRestaurant
        : fallbackRestaurant;
    final targetRestaurant = _restaurantName.isEmpty
        ? fallbackRestaurant
        : _restaurantName;
    final normalizedTarget = _normalizeRestaurantKey(targetRestaurant);
    final removedRestaurants = <String>{};
    var removedCount = 0;

    _items = widget.initialItems
        .where((item) {
          if (normalizedTarget.isEmpty) {
            return true;
          }
          final resolvedRestaurant = _resolvedCartItemRestaurantName(item);
          if (resolvedRestaurant.isEmpty) {
            return true;
          }
          final matches =
              _normalizeRestaurantKey(resolvedRestaurant) == normalizedTarget;
          if (!matches) {
            removedCount += 1;
            removedRestaurants.add(resolvedRestaurant);
          }
          return matches;
        })
        .map(
          (item) => item.copyWith(
            title: item.title,
            subtitle: item.subtitle,
            imageUrl: item.imageUrl,
            price: item.price,
            quantity: item.quantity,
            restaurantName: item.restaurantName.trim().isEmpty
                ? _restaurantName
                : item.restaurantName,
          ),
        )
        .toList();
    if (removedCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final removedLabel = removedRestaurants.join(', ');
        final removedSource = removedLabel.isEmpty
            ? 'another restaurant'
            : removedLabel;
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'You can order from one restaurant only. Removed $removedCount item${removedCount == 1 ? '' : 's'} from $removedSource.',
              ),
            ),
          );
      });
    }
  }

  int get _totalItems =>
      _items.fold<int>(0, (total, item) => total + item.quantity);

  double get _subtotal => _items.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );

  double get _total => _subtotal + _deliveryFee + _serviceFee;

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  void _increaseQuantity(int index) {
    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(quantity: item.quantity + 1);
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      final item = _items[index];
      if (item.quantity <= 1) {
        _items.removeAt(index);
        return;
      }
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) {
      return;
    }
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _OrdersCheckoutScreen(
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          serviceFee: _serviceFee,
          totalItems: _totalItems,
        ),
      ),
    );
    if (!mounted || placed != true) {
      return;
    }
    final placedTotal = _total;
    final placedItems = _totalItems;
    setState(() => _items.clear());
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Order placed for ${_formatMoney(placedTotal)} ($placedItems items)',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${_restaurantName.isEmpty ? 'Cart' : '$_restaurantName Cart'} ($_totalItems)',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF1E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Color(0xFFFF7E4D),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          color: Color(0xFF231A16),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add menu items to continue to checkout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7D6C60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7E4D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to orders',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _OrdersCartItemTile(
                            item: item,
                            onIncrease: () => _increaseQuantity(index),
                            onDecrease: () => _decreaseQuantity(index),
                            onRemove: () => _removeItem(index),
                            priceLabel: _formatMoney(
                              item.price * item.quantity,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0DCCB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12A7633A),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _OrdersPriceRow(
                            label: 'Subtotal',
                            value: _formatMoney(_subtotal),
                          ),
                          const SizedBox(height: 8),
                          _OrdersPriceRow(
                            label: 'Delivery fee',
                            value: _formatMoney(_deliveryFee),
                          ),
                          const SizedBox(height: 8),
                          _OrdersPriceRow(
                            label: 'Service fee',
                            value: _formatMoney(_serviceFee),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFEADBCB)),
                          const SizedBox(height: 10),
                          _OrdersPriceRow(
                            label: 'Total',
                            value: _formatMoney(_total),
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _checkout,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7E4D),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_rounded),
                        label: Text(
                          'Checkout ${_formatMoney(_total)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
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

class _OrdersCartItemTile extends StatelessWidget {
  const _OrdersCartItemTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.priceLabel,
  });

  final _CartLineItemData item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCCB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 74,
              height: 74,
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
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D6C60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Color(0xFFFF7E4D),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _OrdersQtyButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Color(0xFF231A16),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _OrdersQtyButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB66541),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text(
                      'Remove',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

class _OrdersQtyButton extends StatelessWidget {
  const _OrdersQtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF2DCCB)),
          ),
          child: Icon(icon, color: const Color(0xFF9D5F3E), size: 18),
        ),
      ),
    );
  }
}

class _OrdersPriceRow extends StatelessWidget {
  const _OrdersPriceRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFF231A16) : const Color(0xFF7D6C60);
    final weight = highlight ? FontWeight.w900 : FontWeight.w700;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: weight, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: weight, fontSize: 14),
        ),
      ],
    );
  }
}

enum _CheckoutPaymentMethod { onDelivery, visa, whishMoney }

enum _CheckoutChangeRequest { noNeed, usd50, usd100 }

enum _CheckoutDeliveryMode { now, scheduled }

class _CheckoutScheduledSlot {
  const _CheckoutScheduledSlot({
    required this.dayLabel,
    required this.timeRange,
  });

  final String dayLabel;
  final String timeRange;
}

class _CheckoutDeliverySelection {
  const _CheckoutDeliverySelection({
    required this.mode,
    required this.slotIndex,
  });

  final _CheckoutDeliveryMode mode;
  final int slotIndex;
}

class _CheckoutLocationData {
  const _CheckoutLocationData({
    required this.city,
    required this.street,
    required this.building,
    this.floor = '',
    this.apartment = '',
    this.landmark = '',
  });

  final String city;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String landmark;

  bool get hasRequiredFields =>
      city.trim().isNotEmpty &&
      street.trim().isNotEmpty &&
      building.trim().isNotEmpty;

  bool get hasAnyField =>
      city.trim().isNotEmpty ||
      street.trim().isNotEmpty ||
      building.trim().isNotEmpty ||
      floor.trim().isNotEmpty ||
      apartment.trim().isNotEmpty ||
      landmark.trim().isNotEmpty;
}

class _OrdersCheckoutScreen extends StatefulWidget {
  const _OrdersCheckoutScreen({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalItems,
  });

  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final int totalItems;

  @override
  State<_OrdersCheckoutScreen> createState() => _OrdersCheckoutScreenState();
}

class _OrdersCheckoutScreenState extends State<_OrdersCheckoutScreen> {
  static const double _usdToLbpRate = 89500;
  static const double _loyaltyDiscountRate = 0.10;
  static const int _loyaltyPointsPerUsdDiscount = 100;
  static const List<_CheckoutScheduledSlot> _deliverySlots = [
    _CheckoutScheduledSlot(dayLabel: 'Today', timeRange: '08:00 AM - 08:15 AM'),
    _CheckoutScheduledSlot(
      dayLabel: 'Tomorrow',
      timeRange: '08:15 AM - 08:30 AM',
    ),
    _CheckoutScheduledSlot(
      dayLabel: 'Monday, May 04',
      timeRange: '08:30 AM - 08:45 AM',
    ),
  ];

  _CheckoutDeliveryMode _deliveryMode = _CheckoutDeliveryMode.now;
  int _scheduledSlotIndex = 1;
  _CheckoutLocationData _location = const _CheckoutLocationData(
    city: '',
    street: '',
    building: '',
  );
  _CheckoutPaymentMethod _paymentMethod = _CheckoutPaymentMethod.onDelivery;
  _CheckoutChangeRequest _changeRequest = _CheckoutChangeRequest.noNeed;
  bool _useLoyalty = false;
  bool _saveChangeInWallet = false;

  double get _baseTotalUsd =>
      widget.subtotal + widget.deliveryFee + widget.serviceFee;

  double get _discountPercent => _useLoyalty ? (_loyaltyDiscountRate * 100) : 0;

  double get _loyaltyDiscountUsd =>
      _useLoyalty ? (_baseTotalUsd * _loyaltyDiscountRate) : 0;

  int get _loyaltyPointsUsed =>
      (_loyaltyDiscountUsd * _loyaltyPointsPerUsdDiscount).round();

  double get _totalUsd =>
      (_baseTotalUsd - _loyaltyDiscountUsd).clamp(0, double.infinity);

  int get _earnedPoints => (_totalUsd * 8).round();

  bool get _cashPayment => _paymentMethod == _CheckoutPaymentMethod.onDelivery;

  _CheckoutScheduledSlot get _selectedScheduledSlot {
    final maxIndex = _deliverySlots.length - 1;
    final safeIndex = _scheduledSlotIndex.clamp(0, maxIndex).toInt();
    return _deliverySlots[safeIndex];
  }

  String _formatUsd(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatLbp(double usdValue) {
    final lbpValue = (usdValue * _usdToLbpRate).round();
    final withCommas = lbpValue.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas LBP';
  }

  String _paymentMethodLabel(_CheckoutPaymentMethod method) {
    switch (method) {
      case _CheckoutPaymentMethod.onDelivery:
        return 'On Delivery';
      case _CheckoutPaymentMethod.visa:
        return 'Visa';
      case _CheckoutPaymentMethod.whishMoney:
        return 'Whish Money';
    }
  }

  String _changeRequestLabel(_CheckoutChangeRequest request) {
    switch (request) {
      case _CheckoutChangeRequest.noNeed:
        return 'No need';
      case _CheckoutChangeRequest.usd50:
        return '\$50.00';
      case _CheckoutChangeRequest.usd100:
        return '\$100.00';
    }
  }

  String get _deliveryPrimaryLabel {
    if (_deliveryMode == _CheckoutDeliveryMode.now) {
      return 'Now';
    }
    return 'Schedule for later';
  }

  String get _deliverySecondaryLabel {
    if (_deliveryMode == _CheckoutDeliveryMode.now) {
      return 'Deliver immediately';
    }
    final slot = _selectedScheduledSlot;
    return '${slot.dayLabel} • ${slot.timeRange}';
  }

  String get _locationPrimaryLabel {
    if (_location.hasRequiredFields) {
      return '${_location.city}, ${_location.street}';
    }
    return 'Add delivery location';
  }

  String get _locationSecondaryLabel {
    if (!_location.hasAnyField) {
      return 'City, street, building';
    }
    final segments = <String>[
      if (_location.building.trim().isNotEmpty) 'Bldg ${_location.building}',
      if (_location.floor.trim().isNotEmpty) 'Floor ${_location.floor}',
      if (_location.apartment.trim().isNotEmpty) 'Apt ${_location.apartment}',
      if (_location.landmark.trim().isNotEmpty) _location.landmark,
    ];
    return segments.isEmpty ? 'City, street, building' : segments.join(', ');
  }

  void _selectPayment(_CheckoutPaymentMethod method) {
    setState(() {
      _paymentMethod = method;
      if (method != _CheckoutPaymentMethod.onDelivery) {
        _changeRequest = _CheckoutChangeRequest.noNeed;
        _saveChangeInWallet = false;
      }
    });
  }

  void _placeOrder() {
    if (!_location.hasRequiredFields) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please set your city, street, and building before placing the order.',
            ),
          ),
        );
      _openLocationEditor();
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _openDeliveryTimeSelector() async {
    final selection = await showModalBottomSheet<_CheckoutDeliverySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F2ED),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.none,
      builder: (context) => _CheckoutDeliveryTimeSheet(
        initialMode: _deliveryMode,
        initialSlotIndex: _scheduledSlotIndex,
        slots: _deliverySlots,
      ),
    );
    if (!mounted || selection == null) {
      return;
    }
    setState(() {
      _deliveryMode = selection.mode;
      final maxIndex = _deliverySlots.length - 1;
      _scheduledSlotIndex = selection.slotIndex.clamp(0, maxIndex).toInt();
    });
  }

  Future<void> _openLocationEditor() async {
    final location = await showModalBottomSheet<_CheckoutLocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F2ED),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.none,
      builder: (context) => _CheckoutLocationSheet(initialValue: _location),
    );
    if (!mounted || location == null) {
      return;
    }
    setState(() => _location = location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckoutSectionCard(
                title: 'Delivery Time',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openDeliveryTimeSelector,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFCFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8D8C8)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF1E7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _deliveryMode == _CheckoutDeliveryMode.now
                                      ? Icons.access_time_rounded
                                      : Icons.calendar_month_rounded,
                                  color: const Color(0xFFFF7E4D),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _deliveryPrimaryLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF2D251F),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _deliverySecondaryLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF8D7D71),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFB19D8F),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Default is now. Tap to schedule for later.',
                      style: TextStyle(
                        color: Color(0xFF8D7D71),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Location',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF1E7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF7E4D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationPrimaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF2D251F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _locationSecondaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8D7D71),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _openLocationEditor,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7E4D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Change',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set your city, street, and building details for delivery.',
                      style: TextStyle(
                        color: Color(0xFF8D7D71),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Payment Method',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _CheckoutPaymentMethod.values.map((method) {
                    final selected = _paymentMethod == method;
                    return ChoiceChip(
                      label: Text(_paymentMethodLabel(method)),
                      selected: selected,
                      onSelected: (value) {
                        if (!value) {
                          return;
                        }
                        _selectPayment(method);
                      },
                      selectedColor: const Color(0xFFFFE4D2),
                      side: const BorderSide(color: Color(0xFFEFD9C8)),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFFB65D37)
                            : const Color(0xFF7D6C60),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: const Color(0xFFFEFCFA),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Request Change',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _CheckoutChangeRequest.values.map((request) {
                        final selected = _changeRequest == request;
                        return ChoiceChip(
                          label: Text(_changeRequestLabel(request)),
                          selected: selected,
                          onSelected: !_cashPayment
                              ? null
                              : (value) {
                                  if (!value) {
                                    return;
                                  }
                                  setState(() => _changeRequest = request);
                                },
                          selectedColor: const Color(0xFFFFE4D2),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFFB65D37)
                                : const Color(0xFF7D6C60),
                            fontWeight: FontWeight.w700,
                          ),
                          side: const BorderSide(color: Color(0xFFEFD9C8)),
                          backgroundColor: const Color(0xFFFEFCFA),
                        );
                      }).toList(),
                    ),
                    if (!_cashPayment) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Change request is available for cash on delivery only.',
                        style: TextStyle(
                          color: Color(0xFF8D7D71),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Use Loyalty?',
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('No'),
                      selected: !_useLoyalty,
                      onSelected: (_) => setState(() => _useLoyalty = false),
                      selectedColor: const Color(0xFFFFE4D2),
                      side: const BorderSide(color: Color(0xFFEFD9C8)),
                      labelStyle: TextStyle(
                        color: !_useLoyalty
                            ? const Color(0xFFB65D37)
                            : const Color(0xFF7D6C60),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: const Color(0xFFFEFCFA),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Yes'),
                      selected: _useLoyalty,
                      onSelected: (_) => setState(() => _useLoyalty = true),
                      selectedColor: const Color(0xFFFFE4D2),
                      side: const BorderSide(color: Color(0xFFEFD9C8)),
                      labelStyle: TextStyle(
                        color: _useLoyalty
                            ? const Color(0xFFB65D37)
                            : const Color(0xFF7D6C60),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: const Color(0xFFFEFCFA),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Wallet',
                child: SwitchListTile.adaptive(
                  value: _saveChangeInWallet,
                  onChanged: _cashPayment
                      ? (value) => setState(() => _saveChangeInWallet = value)
                      : null,
                  activeThumbColor: const Color(0xFFFF7E4D),
                  activeTrackColor: const Color(0xFFFFD4BB),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Save change in my wallet',
                    style: TextStyle(
                      color: Color(0xFF2D251F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Turn on to save your returned cash as wallet credit.',
                    style: TextStyle(
                      color: Color(0xFF8D7D71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _CheckoutSectionCard(
                title: 'Receipt Details',
                child: Column(
                  children: [
                    _OrdersPriceRow(
                      label: 'Subtotal',
                      value: _formatUsd(widget.subtotal),
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Delivery fee',
                      value: _formatUsd(widget.deliveryFee),
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Service fee',
                      value: _formatUsd(widget.serviceFee),
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Loyalty points used',
                      value: '$_loyaltyPointsUsed pts',
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Discount (%)',
                      value: '${_discountPercent.toStringAsFixed(0)}%',
                    ),
                    if (_loyaltyDiscountUsd > 0) ...[
                      const SizedBox(height: 8),
                      _OrdersPriceRow(
                        label: 'Loyalty discount',
                        value: '-${_formatUsd(_loyaltyDiscountUsd)}',
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFEADBCB)),
                    const SizedBox(height: 10),
                    _OrdersPriceRow(
                      label: 'Total (USD)',
                      value: _formatUsd(_totalUsd),
                      highlight: true,
                    ),
                    const SizedBox(height: 8),
                    _OrdersPriceRow(
                      label: 'Total (LBP)',
                      value: _formatLbp(_totalUsd),
                      highlight: true,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF6E5E53),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const TextSpan(text: 'You earned '),
                            TextSpan(
                              text: '$_earnedPoints',
                              style: const TextStyle(
                                color: Color(0xFFFF7E4D),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(text: ' points'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _placeOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    'Place Order (${widget.totalItems} items)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

class _CheckoutLocationSheet extends StatefulWidget {
  const _CheckoutLocationSheet({required this.initialValue});

  final _CheckoutLocationData initialValue;

  @override
  State<_CheckoutLocationSheet> createState() => _CheckoutLocationSheetState();
}

class _CheckoutLocationSheetState extends State<_CheckoutLocationSheet> {
  late final TextEditingController _cityController;
  late final TextEditingController _streetController;
  late final TextEditingController _buildingController;
  late final TextEditingController _floorController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _landmarkController;
  bool _showRequiredError = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialValue.city);
    _streetController = TextEditingController(text: widget.initialValue.street);
    _buildingController = TextEditingController(
      text: widget.initialValue.building,
    );
    _floorController = TextEditingController(text: widget.initialValue.floor);
    _apartmentController = TextEditingController(
      text: widget.initialValue.apartment,
    );
    _landmarkController = TextEditingController(
      text: widget.initialValue.landmark,
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFEFCFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8D8C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8D8C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB893)),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF7D6C60),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB3A295),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _save() {
    final city = _cityController.text.trim();
    final street = _streetController.text.trim();
    final building = _buildingController.text.trim();
    if (city.isEmpty || street.isEmpty || building.isEmpty) {
      setState(() => _showRequiredError = true);
      return;
    }
    Navigator.of(context).pop(
      _CheckoutLocationData(
        city: city,
        street: street,
        building: building,
        floor: _floorController.text.trim(),
        apartment: _apartmentController.text.trim(),
        landmark: _landmarkController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ColoredBox(
      color: const Color(0xFFF6F2ED),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D5D1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delivery location',
                  style: TextStyle(
                    color: Color(0xFF1F1B19),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(label: 'City *', hint: 'Beirut'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _streetController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    label: 'Street *',
                    hint: 'Hamra Main Street',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _buildingController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    label: 'Building *',
                    hint: 'Building name or number',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _floorController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(label: 'Floor', hint: '3'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _apartmentController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          label: 'Apartment',
                          hint: 'A12',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _landmarkController,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDecoration(
                    label: 'Landmark',
                    hint: 'Near the pharmacy',
                  ),
                ),
                if (_showRequiredError) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Please fill city, street, and building.',
                    style: TextStyle(
                      color: Color(0xFFB7372B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E4D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save location',
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

class _CheckoutDeliveryTimeSheet extends StatefulWidget {
  const _CheckoutDeliveryTimeSheet({
    required this.initialMode,
    required this.initialSlotIndex,
    required this.slots,
  });

  final _CheckoutDeliveryMode initialMode;
  final int initialSlotIndex;
  final List<_CheckoutScheduledSlot> slots;

  @override
  State<_CheckoutDeliveryTimeSheet> createState() =>
      _CheckoutDeliveryTimeSheetState();
}

class _CheckoutDeliveryTimeSheetState
    extends State<_CheckoutDeliveryTimeSheet> {
  late _CheckoutDeliveryMode _mode;
  late int _slotIndex;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final maxIndex = widget.slots.length - 1;
    _slotIndex = widget.initialSlotIndex.clamp(0, maxIndex).toInt();
  }

  void _confirm() {
    Navigator.of(
      context,
    ).pop(_CheckoutDeliverySelection(mode: _mode, slotIndex: _slotIndex));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ColoredBox(
      color: const Color(0xFFF6F2ED),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D5D1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delivery time',
                  style: TextStyle(
                    color: Color(0xFF1F1B19),
                    fontSize: 34 * 0.56,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _CheckoutDeliveryModeTile(
                  title: 'Now',
                  icon: Icons.access_time_rounded,
                  selected: _mode == _CheckoutDeliveryMode.now,
                  onTap: () =>
                      setState(() => _mode = _CheckoutDeliveryMode.now),
                ),
                const SizedBox(height: 10),
                _CheckoutDeliveryModeTile(
                  title: 'Schedule For Later',
                  icon: Icons.calendar_month_rounded,
                  selected: _mode == _CheckoutDeliveryMode.scheduled,
                  onTap: () =>
                      setState(() => _mode = _CheckoutDeliveryMode.scheduled),
                ),
                if (_mode == _CheckoutDeliveryMode.scheduled) ...[
                  const SizedBox(height: 14),
                  ...List<Widget>.generate(widget.slots.length, (index) {
                    final slot = widget.slots[index];
                    final selected = index == _slotIndex;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.slots.length - 1 ? 0 : 8,
                      ),
                      child: _CheckoutScheduleSlotTile(
                        dayLabel: slot.dayLabel,
                        timeRange: slot.timeRange,
                        selected: selected,
                        onTap: () => setState(() => _slotIndex = index),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E4D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirm delivery time',
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

class _CheckoutDeliveryModeTile extends StatelessWidget {
  const _CheckoutDeliveryModeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEFE4) : const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFC5A8)
                  : const Color(0xFFE8D8C8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFFFF7E4D)
                    : const Color(0xFF8D7D71),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF2D251F),
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFFF7E4D)
                    : const Color(0xFFB7A89B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutScheduleSlotTile extends StatelessWidget {
  const _CheckoutScheduleSlotTile({
    required this.dayLabel,
    required this.timeRange,
    required this.selected,
    required this.onTap,
  });

  final String dayLabel;
  final String timeRange;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFF1F1B19)
        : const Color(0xFF9A8C82);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2ECE6) : const Color(0xFFFEFCFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE8D8C8)
                  : const Color(0xFFF0E6DC),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                timeRange,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSectionCard extends StatelessWidget {
  const _CheckoutSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF231A16),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
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
  const _OrdersHeroCard({required this.metrics, required this.metricsData});

  final _ResponsiveMetrics metrics;
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
          return Wrap(
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

  void _openOrderTracking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrderTrackingScreen(
          orderId: 'HR-2048',
          restaurantName: 'Burger Station',
          itemSummary: 'Double smash burger combo with Cajun fries',
          status: currentStatus,
          etaLabel: '8 min',
          totalLabel: '\$24.50',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildOrderTimeline(currentStatus);
    final actionLabel = currentStatus == _OrderStatus.onTheWay
        ? 'Track order'
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
                  onTap: () => _openOrderTracking(context),
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
  const _PastOrderCard({
    required this.data,
    required this.metrics,
    this.onReorder,
  });

  final _PastOrderEntryData data;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final imageSize = _clampDouble(82 * metrics.scale, 68, 82);
    return _ProfilePanel(
      child: Padding(
        padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageToDetailsGap = _clampDouble(14 * metrics.scale, 10, 14);
            final detailsToActionsGap = _clampDouble(
              12 * metrics.scale,
              10,
              12,
            );
            final minDetailsWidth = _clampDouble(172 * metrics.scale, 156, 184);
            final minActionsWidth = _clampDouble(106 * metrics.scale, 98, 112);
            final minWidthForSideBySide =
                imageSize +
                imageToDetailsGap +
                minDetailsWidth +
                detailsToActionsGap +
                minActionsWidth;
            final compact = constraints.maxWidth < minWidthForSideBySide;
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
                  onTap: onReorder,
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
                SizedBox(width: imageToDetailsGap),
                Expanded(child: details),
                SizedBox(width: detailsToActionsGap),
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
    this.onTap,
  });

  final String label;
  final bool filled;
  final _ResponsiveMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
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
        ),
      ),
    );
  }
}

class _OrderTrackingScreen extends StatelessWidget {
  const _OrderTrackingScreen({
    required this.orderId,
    required this.restaurantName,
    required this.itemSummary,
    required this.status,
    required this.etaLabel,
    required this.totalLabel,
  });

  final String orderId;
  final String restaurantName;
  final String itemSummary;
  final _OrderStatus status;
  final String etaLabel;
  final String totalLabel;

  int _currentStepIndexForStatus() {
    switch (status) {
      case _OrderStatus.pending:
        return 0;
      case _OrderStatus.accepted:
        return 1;
      case _OrderStatus.preparing:
        return 2;
      case _OrderStatus.ready:
        return 3;
      case _OrderStatus.onTheWay:
        return 4;
      case _OrderStatus.delivered:
        return 5;
      case _OrderStatus.canceled:
      case _OrderStatus.rejected:
        return 1;
    }
  }

  String _formatClockTime(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final meridiem = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $meridiem';
  }

  String _normalizedName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _openRestaurantDirectMessage(BuildContext context) async {
    final repository = DemoAppRepository.instance;
    final threads = await repository.getThreads();
    if (!context.mounted) {
      return;
    }
    if (threads.isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No messages available yet for this restaurant.'),
          ),
        );
      return;
    }

    final targetName = _normalizedName(restaurantName);
    DemoConversationThread? matchedThread;

    for (final thread in threads) {
      final mappedName =
          _customerRestaurantNamesByThreadId[thread.id] ?? thread.customerName;
      if (_normalizedName(mappedName) == targetName) {
        matchedThread = thread;
        break;
      }
    }

    if (matchedThread == null) {
      for (final thread in threads) {
        final mappedName =
            _customerRestaurantNamesByThreadId[thread.id] ??
            thread.customerName;
        final normalizedMapped = _normalizedName(mappedName);
        if (normalizedMapped.contains(targetName) ||
            targetName.contains(normalizedMapped)) {
          matchedThread = thread;
          break;
        }
      }
    }

    if (matchedThread == null) {
      final fallbackOrderThread = threads.firstWhere(
        (thread) => thread.type == MessageThreadType.order,
        orElse: () => threads.first,
      );
      matchedThread = fallbackOrderThread;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          threadId: matchedThread!.id,
          restaurantName: 'You',
          openComposerOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final placedAt = now.subtract(const Duration(minutes: 26));
    final viewport = MediaQuery.sizeOf(context);
    final trackingMetrics = _ResponsiveMetrics.from(
      BoxConstraints(maxWidth: viewport.width, maxHeight: viewport.height),
    );
    final checkpoints = <_OrderTrackingStep>[
      _OrderTrackingStep(
        label: 'Order placed',
        subtitle: 'Payment confirmed and ticket sent to the restaurant.',
        time: placedAt,
        icon: Icons.shopping_bag_rounded,
      ),
      _OrderTrackingStep(
        label: 'Restaurant accepted',
        subtitle: 'The kitchen accepted your order and queued it.',
        time: placedAt.add(const Duration(minutes: 3)),
        icon: Icons.receipt_long_rounded,
      ),
      _OrderTrackingStep(
        label: 'Preparing',
        subtitle: 'Your meal is being cooked fresh.',
        time: placedAt.add(const Duration(minutes: 12)),
        icon: Icons.restaurant_rounded,
      ),
      _OrderTrackingStep(
        label: 'Packed and ready',
        subtitle: 'Order packed and assigned to a rider.',
        time: placedAt.add(const Duration(minutes: 17)),
        icon: Icons.inventory_2_rounded,
      ),
      _OrderTrackingStep(
        label: 'On the way',
        subtitle: 'Rider is heading to your location.',
        time: placedAt.add(const Duration(minutes: 20)),
        icon: Icons.delivery_dining_rounded,
      ),
      _OrderTrackingStep(
        label: 'Delivered',
        subtitle: 'Enjoy your meal!',
        time: placedAt.add(const Duration(minutes: 29)),
        icon: Icons.check_circle_rounded,
      ),
    ];
    final currentStepIndex = _currentStepIndexForStatus();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Track Order #$orderId',
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
          children: [
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemSummary,
                      style: const TextStyle(
                        color: Color(0xFF7D6C60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OrdersInfoChip(
                          label: 'ETA $etaLabel',
                          icon: Icons.timer_outlined,
                          metrics: trackingMetrics,
                        ),
                        _OrdersInfoChip(
                          label: totalLabel,
                          icon: Icons.payments_rounded,
                          metrics: trackingMetrics,
                        ),
                        _OrdersInfoChip(
                          label: 'Status ${_orderStatusLabel(status)}',
                          icon: _orderStatusIcon(status),
                          metrics: trackingMetrics,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (currentStepIndex + 1) / checkpoints.length,
                      minHeight: 9,
                      color: _orderStatusAccentColor(status),
                      backgroundColor: const Color(0xFFF2E4D7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: List.generate(checkpoints.length, (index) {
                    final step = checkpoints[index];
                    final isComplete = index <= currentStepIndex;
                    final isCurrent = index == currentStepIndex;
                    final previousTime = index == 0
                        ? null
                        : checkpoints[index - 1].time;
                    final durationLabel = previousTime == null
                        ? 'Start'
                        : '${step.time.difference(previousTime).inMinutes} min';
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == checkpoints.length - 1 ? 0 : 10,
                      ),
                      child: _OrderTrackingTimelineTile(
                        step: step,
                        isComplete: isComplete,
                        isCurrent: isCurrent,
                        timeLabel: _formatClockTime(step.time),
                        durationLabel: durationLabel,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ProfilePanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Helpful Actions',
                      style: TextStyle(
                        color: Color(0xFF231A16),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OrdersActionPill(
                          label: 'Contact restaurant',
                          filled: false,
                          metrics: trackingMetrics,
                          onTap: () => _openRestaurantDirectMessage(context),
                        ),
                        _OrdersActionPill(
                          label: 'Support chat',
                          filled: true,
                          metrics: trackingMetrics,
                          onTap: () {
                            showOrderIssueSheet(
                              context,
                              orderId: orderId,
                              restaurantName: restaurantName,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTrackingStep {
  const _OrderTrackingStep({
    required this.label,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final DateTime time;
  final IconData icon;
}

class _OrderTrackingTimelineTile extends StatelessWidget {
  const _OrderTrackingTimelineTile({
    required this.step,
    required this.isComplete,
    required this.isCurrent,
    required this.timeLabel,
    required this.durationLabel,
  });

  final _OrderTrackingStep step;
  final bool isComplete;
  final bool isCurrent;
  final String timeLabel;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCurrent
        ? const Color(0xFFFF7E4D)
        : isComplete
        ? const Color(0xFF2F8A7E)
        : const Color(0xFFD9CABC);
    final panelColor = isCurrent
        ? const Color(0xFFFFF2E8)
        : isComplete
        ? const Color(0xFFF1F8F5)
        : const Color(0xFFF8F1EA);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: const TextStyle(
                    color: Color(0xFF231A16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A695E),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrackingMetaPill(
                      icon: Icons.schedule_rounded,
                      label: timeLabel,
                    ),
                    _TrackingMetaPill(
                      icon: Icons.timelapse_rounded,
                      label: durationLabel,
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

class _TrackingMetaPill extends StatelessWidget {
  const _TrackingMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1E2D3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8A7060)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5D4C42),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
    required this.reorderItems,
  });

  final String title;
  final String summary;
  final String dateLabel;
  final String totalLabel;
  final _OrderStatus status;
  final String imageUrl;
  final List<_CartLineItemData> reorderItems;
}

class _OrderReceiptData {
  const _OrderReceiptData({
    required this.orderId,
    required this.restaurantName,
    required this.summary,
    required this.placedAtLabel,
    required this.status,
    required this.imageUrl,
    required this.paymentMethodLabel,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discountPercent,
    required this.loyaltyPointsUsed,
    required this.loyaltyDiscountUsd,
    required this.items,
  });

  final String orderId;
  final String restaurantName;
  final String summary;
  final String placedAtLabel;
  final _OrderStatus status;
  final String imageUrl;
  final String paymentMethodLabel;
  final double deliveryFee;
  final double serviceFee;
  final double discountPercent;
  final int loyaltyPointsUsed;
  final double loyaltyDiscountUsd;
  final List<_OrderReceiptLineItemData> items;

  int get totalItems =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  double get subtotalUsd =>
      items.fold<double>(0, (total, item) => total + item.totalPrice);

  double get _baseTotalUsd => subtotalUsd + deliveryFee + serviceFee;

  double get _percentDiscountUsd => _baseTotalUsd * (discountPercent / 100);

  double get totalDiscountUsd => _percentDiscountUsd + loyaltyDiscountUsd;

  double get totalUsd =>
      (_baseTotalUsd - totalDiscountUsd).clamp(0, double.infinity);
}

class _OrderReceiptLineItemData {
  const _OrderReceiptLineItemData({
    required this.title,
    this.subtitle = '',
    required this.quantity,
    required this.unitPrice,
  });

  final String title;
  final String subtitle;
  final int quantity;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;
}

class _CartLineItemData {
  const _CartLineItemData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.restaurantName = '',
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final double price;
  final int quantity;
  final String restaurantName;

  _CartLineItemData copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    double? price,
    int? quantity,
    String? restaurantName,
  }) {
    return _CartLineItemData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }
}

class _RestaurantCartData {
  const _RestaurantCartData({
    required this.restaurantName,
    required this.items,
  });

  final String restaurantName;
  final List<_CartLineItemData> items;

  int get totalItems =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  double get subtotal => items.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );

  String get coverImageUrl => items.isEmpty
      ? 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80'
      : items.first.imageUrl;
}

String _normalizeRestaurantKey(String value) {
  return value.trim().toLowerCase();
}

String _firstRestaurantNameFromItems(List<_CartLineItemData> items) {
  for (final item in items) {
    final name = _resolvedCartItemRestaurantName(item);
    if (name.isNotEmpty) {
      return name;
    }
  }
  return '';
}

String _resolvedCartItemRestaurantName(_CartLineItemData item) {
  final direct = item.restaurantName.trim();
  if (direct.isNotEmpty) {
    return direct;
  }
  final subtitle = item.subtitle.trim();
  if (subtitle.isEmpty) {
    return '';
  }
  const separators = ['•', '-', '–', '—', '|', '/'];
  for (final separator in separators) {
    final index = subtitle.indexOf(separator);
    if (index > 0) {
      return subtitle.substring(0, index).trim();
    }
  }
  return '';
}

