enum MessageFilterType { all, unread, orders, offers }

enum MessageThreadType { order, offer }

class DemoFeedPost {
  const DemoFeedPost({
    required this.id,
    required this.restaurantName,
    required this.restaurantHandle,
    required this.followersCount,
    required this.caption,
    required this.tags,
    required this.audioLabel,
    required this.rating,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isFollowing,
  });

  final String id;
  final String restaurantName;
  final String restaurantHandle;
  final int followersCount;
  final String caption;
  final String tags;
  final String audioLabel;
  final double rating;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFollowing;

  DemoFeedPost copyWith({
    String? id,
    String? restaurantName,
    String? restaurantHandle,
    int? followersCount,
    String? caption,
    String? tags,
    String? audioLabel,
    double? rating,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isFollowing,
  }) {
    return DemoFeedPost(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantHandle: restaurantHandle ?? this.restaurantHandle,
      followersCount: followersCount ?? this.followersCount,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      audioLabel: audioLabel ?? this.audioLabel,
      rating: rating ?? this.rating,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class DemoComment {
  const DemoComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.isRestaurantReply,
  });

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final bool isRestaurantReply;
}

class DemoNotificationItem {
  const DemoNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool isRead;

  DemoNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? timeLabel,
    bool? isRead,
  }) {
    return DemoNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      isRead: isRead ?? this.isRead,
    );
  }
}

class DemoOrder {
  const DemoOrder({
    required this.id,
    required this.customerName,
    required this.itemSummary,
    required this.etaLabel,
    required this.statusLabel,
    required this.channelLabel,
    required this.highlighted,
    required this.totalLabel,
    required this.completed,
  });

  final String id;
  final String customerName;
  final String itemSummary;
  final String etaLabel;
  final String statusLabel;
  final String channelLabel;
  final bool highlighted;
  final String totalLabel;
  final bool completed;
}

class DemoUploadedPost {
  const DemoUploadedPost({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  final String id;
  final String fileName;
  final int fileSizeBytes;
  final DateTime createdAt;
}

class DemoConversationMessage {
  const DemoConversationMessage({
    required this.id,
    required this.senderName,
    required this.body,
    required this.sentAt,
    required this.fromRestaurant,
  });

  final String id;
  final String senderName;
  final String body;
  final DateTime sentAt;
  final bool fromRestaurant;
}

class DemoConversationThread {
  const DemoConversationThread({
    required this.id,
    required this.customerName,
    required this.lastMessage,
    required this.timeLabel,
    required this.orderLabel,
    required this.channelLabel,
    required this.unreadCount,
    required this.priority,
    required this.needsReply,
    required this.online,
    required this.type,
    required this.messages,
  });

  final String id;
  final String customerName;
  final String lastMessage;
  final String timeLabel;
  final String orderLabel;
  final String channelLabel;
  final int unreadCount;
  final bool priority;
  final bool needsReply;
  final bool online;
  final MessageThreadType type;
  final List<DemoConversationMessage> messages;

  DemoConversationThread copyWith({
    String? id,
    String? customerName,
    String? lastMessage,
    String? timeLabel,
    String? orderLabel,
    String? channelLabel,
    int? unreadCount,
    bool? priority,
    bool? needsReply,
    bool? online,
    MessageThreadType? type,
    List<DemoConversationMessage>? messages,
  }) {
    return DemoConversationThread(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      lastMessage: lastMessage ?? this.lastMessage,
      timeLabel: timeLabel ?? this.timeLabel,
      orderLabel: orderLabel ?? this.orderLabel,
      channelLabel: channelLabel ?? this.channelLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      priority: priority ?? this.priority,
      needsReply: needsReply ?? this.needsReply,
      online: online ?? this.online,
      type: type ?? this.type,
      messages: messages ?? this.messages,
    );
  }
}

class DemoSearchResult {
  const DemoSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String categoryLabel;
}
