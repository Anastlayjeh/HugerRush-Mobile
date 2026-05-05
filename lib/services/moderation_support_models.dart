enum ReportItemType {
  feedPost,
  restaurantProfile,
  customerProfile,
  menuItem,
  comment,
  review,
  conversation,
  order,
}

enum ReportReason {
  harmfulOrOffensiveContent,
  falseOrMisleadingFoodClaim,
  spam,
  harassment,
  nonFoodContent,
  inappropriateImageOrVideo,
  other,
}

enum OrderIssueReason {
  missingItem,
  lateDelivery,
  wrongOrder,
  paymentIssue,
  foodQualityIssue,
  other,
}

enum FriendshipStatus {
  none,
  requestSent,
  friends,
}

extension ReportItemTypeLabel on ReportItemType {
  String get label {
    switch (this) {
      case ReportItemType.feedPost:
        return 'Feed Post/Video';
      case ReportItemType.restaurantProfile:
        return 'Restaurant Profile';
      case ReportItemType.customerProfile:
        return 'Customer Profile';
      case ReportItemType.menuItem:
        return 'Menu Item';
      case ReportItemType.comment:
        return 'Comment';
      case ReportItemType.review:
        return 'Review';
      case ReportItemType.conversation:
        return 'Conversation';
      case ReportItemType.order:
        return 'Order';
    }
  }
}

extension ReportReasonLabel on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.harmfulOrOffensiveContent:
        return 'Harmful or offensive content';
      case ReportReason.falseOrMisleadingFoodClaim:
        return 'False or misleading food claim';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.nonFoodContent:
        return 'Non-food content';
      case ReportReason.inappropriateImageOrVideo:
        return 'Inappropriate image/video';
      case ReportReason.other:
        return 'Other';
    }
  }
}

extension OrderIssueReasonLabel on OrderIssueReason {
  String get label {
    switch (this) {
      case OrderIssueReason.missingItem:
        return 'Missing item';
      case OrderIssueReason.lateDelivery:
        return 'Late delivery';
      case OrderIssueReason.wrongOrder:
        return 'Wrong order';
      case OrderIssueReason.paymentIssue:
        return 'Payment issue';
      case OrderIssueReason.foodQualityIssue:
        return 'Food quality issue';
      case OrderIssueReason.other:
        return 'Other';
    }
  }
}

extension FriendshipStatusLabel on FriendshipStatus {
  String get label {
    switch (this) {
      case FriendshipStatus.none:
        return 'Not friends';
      case FriendshipStatus.requestSent:
        return 'Request Sent';
      case FriendshipStatus.friends:
        return 'Friends';
    }
  }
}
