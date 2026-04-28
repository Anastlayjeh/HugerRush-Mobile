import '../models/demo_app_models.dart';

class DemoAppRepository {
  DemoAppRepository._();

  static final DemoAppRepository instance = DemoAppRepository._();

  final Map<String, DemoFeedPost> _feedPosts = <String, DemoFeedPost>{
    'for-you': const DemoFeedPost(
      id: 'for-you',
      restaurantName: 'Bella Italia',
      restaurantHandle: 'bellaitalia',
      caption:
          'Feeling hungry? Our new Pepperoni Feast is here. Cheesy and absolutely delicious.',
      tags: '#pizza #yum #foodie',
      audioLabel: 'Original Audio - Bella Italia Promo',
      rating: 4.8,
      likeCount: 4200,
      commentCount: 156,
      isLiked: false,
      isFollowing: false,
    ),
    'following': const DemoFeedPost(
      id: 'following',
      restaurantName: 'Bella Italia',
      restaurantHandle: 'bellaitalia',
      caption:
          'Fresh from the oven: kitchen updates, lunch offers, and a warm batch of garlic knots.',
      tags: '#following #offers #fresh',
      audioLabel: 'Original Audio - Lunch Rush Kitchen Clip',
      rating: 4.8,
      likeCount: 3180,
      commentCount: 92,
      isLiked: true,
      isFollowing: true,
    ),
    'vendor-feed': const DemoFeedPost(
      id: 'vendor-feed',
      restaurantName: 'Bella Italia',
      restaurantHandle: 'bellaitalia',
      caption: 'Pizza night is here with our Pepperoni Feast.',
      tags: '#pizza #yum #foodie',
      audioLabel: 'Original Audio - Bella Italia Promo',
      rating: 4.8,
      likeCount: 4200,
      commentCount: 156,
      isLiked: false,
      isFollowing: true,
    ),
  };

  final Map<String, List<DemoComment>> _commentsByPost = <String, List<DemoComment>>{
    'for-you': <DemoComment>[
      DemoComment(
        id: 'c1',
        authorName: 'Lina M.',
        body: 'The crust looks amazing.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        isRestaurantReply: false,
      ),
      DemoComment(
        id: 'c2',
        authorName: 'Bella Italia',
        body: 'Fresh from the oven. Come hungry.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        isRestaurantReply: true,
      ),
    ],
    'following': <DemoComment>[
      DemoComment(
        id: 'c3',
        authorName: 'Rami A.',
        body: 'Saving this for dinner.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
        isRestaurantReply: false,
      ),
    ],
    'vendor-feed': <DemoComment>[
      DemoComment(
        id: 'c4',
        authorName: 'Maya K.',
        body: 'Looks perfect.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 11)),
        isRestaurantReply: false,
      ),
    ],
  };

  List<DemoNotificationItem> _notifications = <DemoNotificationItem>[
    const DemoNotificationItem(
      id: 'n1',
      title: 'New order assigned',
      body: 'Order #4735 just moved into the live queue.',
      timeLabel: 'Now',
      isRead: false,
    ),
    const DemoNotificationItem(
      id: 'n2',
      title: 'Customer replied',
      body: 'Sara N. sent a pickup update request.',
      timeLabel: '3m ago',
      isRead: false,
    ),
    const DemoNotificationItem(
      id: 'n3',
      title: 'Promo performing well',
      body: 'Pepperoni Feast promo gained 42 new likes.',
      timeLabel: '28m ago',
      isRead: true,
    ),
  ];

  final List<DemoOrder> _orders = <DemoOrder>[
    const DemoOrder(
      id: '#4735',
      customerName: 'Lina M.',
      itemSummary: '2x Pepperoni Feast, 1x Cola',
      etaLabel: 'ETA 14m',
      statusLabel: 'Cooking',
      channelLabel: 'Delivery',
      highlighted: true,
      totalLabel: '\$33.98',
      completed: false,
    ),
    const DemoOrder(
      id: '#4733',
      customerName: 'Rami A.',
      itemSummary: '1x Chicken Wrap, 1x Fries',
      etaLabel: 'ETA 8m',
      statusLabel: 'Packing',
      channelLabel: 'Pickup',
      highlighted: false,
      totalLabel: '\$18.25',
      completed: false,
    ),
    const DemoOrder(
      id: '#4730',
      customerName: 'Jad F.',
      itemSummary: '1x Family Box, 2x Garlic Dip',
      etaLabel: 'ETA 22m',
      statusLabel: 'Queued',
      channelLabel: 'Delivery',
      highlighted: false,
      totalLabel: '\$27.10',
      completed: false,
    ),
    const DemoOrder(
      id: '#4728',
      customerName: 'Youssef A.',
      itemSummary: '1x Pepperoni Feast, 1x Tiramisu',
      etaLabel: 'Completed',
      statusLabel: 'Delivered',
      channelLabel: 'Delivery',
      highlighted: false,
      totalLabel: '\$21.90',
      completed: true,
    ),
    const DemoOrder(
      id: '#4722',
      customerName: 'Maya K.',
      itemSummary: '2x Pasta Combo, 2x Water',
      etaLabel: 'Completed',
      statusLabel: 'Delivered',
      channelLabel: 'Pickup',
      highlighted: false,
      totalLabel: '\$29.40',
      completed: true,
    ),
  ];

  final List<DemoUploadedPost> _uploadedPosts = <DemoUploadedPost>[];

  final List<DemoConversationThread> _threads = <DemoConversationThread>[
    DemoConversationThread(
      id: 't1',
      customerName: 'Sara N.',
      lastMessage:
          'Can I switch my side from fries to grilled veggies before pickup?',
      timeLabel: '2m',
      orderLabel: '#4731',
      channelLabel: 'Pickup',
      unreadCount: 2,
      priority: true,
      needsReply: true,
      online: true,
      type: MessageThreadType.order,
      messages: <DemoConversationMessage>[
        DemoConversationMessage(
          id: 'm1',
          senderName: 'Sara N.',
          body: 'Can I switch my side from fries to grilled veggies before pickup?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
          fromRestaurant: false,
        ),
      ],
    ),
    DemoConversationThread(
      id: 't2',
      customerName: 'Youssef A.',
      lastMessage: 'Thanks! The order arrived, but I am missing the drink.',
      timeLabel: '7m',
      orderLabel: '#4728',
      channelLabel: 'Delivery',
      unreadCount: 1,
      priority: true,
      needsReply: true,
      online: false,
      type: MessageThreadType.order,
      messages: <DemoConversationMessage>[
        DemoConversationMessage(
          id: 'm2',
          senderName: 'Youssef A.',
          body: 'Thanks! The order arrived, but I am missing the drink.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 7)),
          fromRestaurant: false,
        ),
      ],
    ),
    DemoConversationThread(
      id: 't3',
      customerName: 'Maya K.',
      lastMessage: 'Perfect as always. Please keep extra napkins next time.',
      timeLabel: '25m',
      orderLabel: '#4722',
      channelLabel: 'Delivery',
      unreadCount: 0,
      priority: false,
      needsReply: false,
      online: false,
      type: MessageThreadType.order,
      messages: <DemoConversationMessage>[
        DemoConversationMessage(
          id: 'm3',
          senderName: 'Maya K.',
          body: 'Perfect as always. Please keep extra napkins next time.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 25)),
          fromRestaurant: false,
        ),
      ],
    ),
    DemoConversationThread(
      id: 't4',
      customerName: 'Elie H.',
      lastMessage: 'Do you still have the family-size combo available tonight?',
      timeLabel: '41m',
      orderLabel: 'Offer',
      channelLabel: 'Delivery',
      unreadCount: 3,
      priority: false,
      needsReply: true,
      online: true,
      type: MessageThreadType.offer,
      messages: <DemoConversationMessage>[
        DemoConversationMessage(
          id: 'm4',
          senderName: 'Elie H.',
          body: 'Do you still have the family-size combo available tonight?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 41)),
          fromRestaurant: false,
        ),
      ],
    ),
    DemoConversationThread(
      id: 't5',
      customerName: 'Nour R.',
      lastMessage: 'Please ring the bell at the main entrance when you arrive.',
      timeLabel: '1h',
      orderLabel: '#4714',
      channelLabel: 'Delivery',
      unreadCount: 0,
      priority: false,
      needsReply: false,
      online: true,
      type: MessageThreadType.order,
      messages: <DemoConversationMessage>[
        DemoConversationMessage(
          id: 'm5',
          senderName: 'Nour R.',
          body: 'Please ring the bell at the main entrance when you arrive.',
          sentAt: DateTime.now().subtract(const Duration(hours: 1)),
          fromRestaurant: false,
        ),
      ],
    ),
    DemoConversationThread(
      id: 't6',
      customerName: 'Karim D.',
      lastMessage: 'Can I add one garlic dip to this order?',
      timeLabel: '1h',
      orderLabel: '#4713',
      channelLabel: 'Pickup',
      unreadCount: 1,
      priority: false,
      needsReply: true,
      online: false,
      type: MessageThreadType.order,
      messages: <DemoConversationMessage>[
        DemoConversationMessage(
          id: 'm6',
          senderName: 'Karim D.',
          body: 'Can I add one garlic dip to this order?',
          sentAt: DateTime.now().subtract(const Duration(hours: 1)),
          fromRestaurant: false,
        ),
      ],
    ),
  ];

  DemoFeedPost getFeedPost({required bool following, bool vendorView = false}) {
    if (vendorView) {
      return _feedPosts['vendor-feed']!;
    }
    return _feedPosts[following ? 'following' : 'for-you']!;
  }

  Future<DemoFeedPost> toggleFollow(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final post = _feedPosts[postId]!;
    final updated = post.copyWith(isFollowing: !post.isFollowing);
    _feedPosts[postId] = updated;
    return updated;
  }

  Future<DemoFeedPost> toggleLike(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final post = _feedPosts[postId]!;
    final nextLiked = !post.isLiked;
    final updated = post.copyWith(
      isLiked: nextLiked,
      likeCount: nextLiked ? post.likeCount + 1 : (post.likeCount - 1).clamp(0, 1 << 31),
    );
    _feedPosts[postId] = updated;
    return updated;
  }

  List<DemoComment> getComments(String postId) {
    return List<DemoComment>.from(_commentsByPost[postId] ?? const <DemoComment>[]);
  }

  Future<List<DemoComment>> addComment({
    required String postId,
    required String authorName,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return getComments(postId);
    }
    final items = List<DemoComment>.from(_commentsByPost[postId] ?? const <DemoComment>[]);
    items.add(
      DemoComment(
        id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
        authorName: authorName,
        body: cleaned,
        createdAt: DateTime.now(),
        isRestaurantReply: false,
      ),
    );
    _commentsByPost[postId] = items;
    final post = _feedPosts[postId];
    if (post != null) {
      _feedPosts[postId] = post.copyWith(commentCount: items.length);
    }
    return List<DemoComment>.from(items);
  }

  Future<List<DemoNotificationItem>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<DemoNotificationItem>.from(_notifications);
  }

  Future<List<DemoNotificationItem>> markAllNotificationsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _notifications = _notifications
        .map((item) => item.copyWith(isRead: true))
        .toList();
    return List<DemoNotificationItem>.from(_notifications);
  }

  Future<List<DemoSearchResult>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final cleaned = query.trim().toLowerCase();
    if (cleaned.isEmpty) {
      return const <DemoSearchResult>[];
    }
    final results = <DemoSearchResult>[];
    for (final post in _feedPosts.values) {
      final haystack = '${post.restaurantName} ${post.caption} ${post.tags}'.toLowerCase();
      if (haystack.contains(cleaned)) {
        results.add(
          DemoSearchResult(
            id: 'post-${post.id}',
            title: post.restaurantName,
            subtitle: post.caption,
            categoryLabel: 'Promo',
          ),
        );
      }
    }
    for (final order in _orders) {
      final haystack = '${order.id} ${order.customerName} ${order.itemSummary}'.toLowerCase();
      if (haystack.contains(cleaned)) {
        results.add(
          DemoSearchResult(
            id: 'order-${order.id}',
            title: order.id,
            subtitle: '${order.customerName} • ${order.itemSummary}',
            categoryLabel: 'Order',
          ),
        );
      }
    }
    for (final thread in _threads) {
      final haystack =
          '${thread.customerName} ${thread.lastMessage} ${thread.orderLabel}'.toLowerCase();
      if (haystack.contains(cleaned)) {
        results.add(
          DemoSearchResult(
            id: 'thread-${thread.id}',
            title: thread.customerName,
            subtitle: thread.lastMessage,
            categoryLabel: 'Message',
          ),
        );
      }
    }
    return results;
  }

  List<DemoOrder> getOrders({
    bool? completed,
  }) {
    if (completed == null) {
      return List<DemoOrder>.from(_orders);
    }
    return _orders.where((item) => item.completed == completed).toList();
  }

  DemoOrder? findOrder(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) {
        return order;
      }
    }
    return null;
  }

  List<DemoUploadedPost> getUploadedPosts() {
    final posts = List<DemoUploadedPost>.from(_uploadedPosts);
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<DemoUploadedPost> createPost({
    required String fileName,
    required int fileSizeBytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final post = DemoUploadedPost(
      id: 'upload-${DateTime.now().microsecondsSinceEpoch}',
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      createdAt: DateTime.now(),
    );
    _uploadedPosts.insert(0, post);
    _notifications = <DemoNotificationItem>[
      const DemoNotificationItem(
        id: 'new-post',
        title: 'New post published',
        body: 'Your latest kitchen update is now live on the feed.',
        timeLabel: 'Just now',
        isRead: false,
      ),
      ..._notifications,
    ];
    return post;
  }

  Future<List<DemoConversationThread>> getThreads() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<DemoConversationThread>.from(_threads);
  }

  List<String> getCustomerNames() {
    final names = _threads.map((thread) => thread.customerName).toSet().toList();
    names.sort();
    return names;
  }

  DemoConversationThread? findThread(String threadId) {
    for (final thread in _threads) {
      if (thread.id == threadId) {
        return thread;
      }
    }
    return null;
  }

  Future<DemoConversationThread> markThreadRead(String threadId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) {
      throw StateError('Thread not found');
    }
    final updated = _threads[index].copyWith(unreadCount: 0);
    _threads[index] = updated;
    return updated;
  }

  Future<DemoConversationThread> sendReply({
    required String threadId,
    required String restaurantName,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      throw StateError('Reply is empty');
    }
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) {
      throw StateError('Thread not found');
    }
    final existing = _threads[index];
    final messages = List<DemoConversationMessage>.from(existing.messages)
      ..add(
        DemoConversationMessage(
          id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
          senderName: restaurantName,
          body: cleaned,
          sentAt: DateTime.now(),
          fromRestaurant: true,
        ),
      );
    final updated = existing.copyWith(
      lastMessage: cleaned,
      timeLabel: 'Now',
      unreadCount: 0,
      needsReply: false,
      messages: messages,
    );
    _threads[index] = updated;
    return updated;
  }
}
