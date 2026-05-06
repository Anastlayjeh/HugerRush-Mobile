import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/auth_session.dart';
import '../models/demo_app_models.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_service.dart';
import '../services/authenticated_api_client.dart';
import '../services/conversation_api_service.dart';
import '../services/customer_restaurant_api_service.dart';
import '../services/demo_app_repository.dart';
import '../services/moderation_support_models.dart';
import '../services/notification_api_service.dart';
import '../services/order_api_service.dart';
import '../services/order_support_service.dart';
import '../services/post_share_service.dart';
import '../services/report_service.dart';
import '../services/restaurant_menu_api_service.dart';
import '../services/social_graph_service.dart';

final Set<String> _customerSavedRestaurantKeys = <String>{};

String _customerRestaurantSaveKey({
  required String restaurantName,
  required String handle,
}) {
  final cleanedHandle = handle.trim().toLowerCase();
  if (cleanedHandle.isNotEmpty) {
    return cleanedHandle.startsWith('@')
        ? cleanedHandle.substring(1)
        : cleanedHandle;
  }
  final cleanedName = restaurantName.trim().toLowerCase();
  return cleanedName.isEmpty ? 'restaurant' : cleanedName;
}

bool _isCustomerRestaurantSaved({
  required String restaurantName,
  required String handle,
}) {
  return _customerSavedRestaurantKeys.contains(
    _customerRestaurantSaveKey(restaurantName: restaurantName, handle: handle),
  );
}

bool isCustomerRestaurantSaved({
  required String restaurantName,
  required String handle,
}) {
  return _isCustomerRestaurantSaved(
    restaurantName: restaurantName,
    handle: handle,
  );
}

void _setCustomerRestaurantSaved({
  required String restaurantName,
  required String handle,
  required bool isSaved,
}) {
  final key = _customerRestaurantSaveKey(
    restaurantName: restaurantName,
    handle: handle,
  );
  if (isSaved) {
    _customerSavedRestaurantKeys.add(key);
  } else {
    _customerSavedRestaurantKeys.remove(key);
  }
}

void setCustomerRestaurantSaved({
  required String restaurantName,
  required String handle,
  required bool isSaved,
}) {
  _setCustomerRestaurantSaved(
    restaurantName: restaurantName,
    handle: handle,
    isSaved: isSaved,
  );
}

Future<bool> showReportSheet(
  BuildContext context, {
  required ReportItemType itemType,
  required String itemId,
  String? itemTitle,
  List<ReportReason> reasons = ReportReason.values,
}) async {
  final cleanItemId = itemId.trim();
  if (cleanItemId.isEmpty) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Unable to report this item right now.')),
      );
    return false;
  }

  final descriptionController = TextEditingController();
  var selectedReason = reasons.first;
  var isSubmitting = false;
  var submitted = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFBF7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          Future<void> submit() async {
            if (isSubmitting) {
              return;
            }
            setSheetState(() => isSubmitting = true);
            try {
              await ReportService.instance.submitReport(
                itemType: itemType,
                itemId: cleanItemId,
                reason: selectedReason,
                description: descriptionController.text,
              );
              submitted = true;
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            } on ReportServiceException catch (error) {
              if (!sheetContext.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.maybeOf(sheetContext);
              messenger
                ?..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(error.message)));
              setSheetState(() => isSubmitting = false);
            } catch (_) {
              if (!sheetContext.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.maybeOf(sheetContext);
              messenger
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'We could not submit your report. Please try again.',
                    ),
                  ),
                );
              setSheetState(() => isSubmitting = false);
            }
          }

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report',
                    style: TextStyle(
                      color: Color(0xFF231A16),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    itemTitle?.trim().isNotEmpty == true
                        ? 'You are reporting: ${itemTitle!.trim()}'
                        : 'You are reporting a ${itemType.label.toLowerCase()}.',
                    style: const TextStyle(
                      color: Color(0xFF7D6C60),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEADBCB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ReportReason>(
                        value: selectedReason,
                        isExpanded: true,
                        items: reasons
                            .map((reason) {
                              return DropdownMenuItem<ReportReason>(
                                value: reason,
                                child: Text(
                                  reason.label,
                                  style: const TextStyle(
                                    color: Color(0xFF2F241B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setSheetState(() => selectedReason = value);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Optional details',
                      filled: true,
                      fillColor: const Color(0xFFFEFCFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7B675A),
                            side: const BorderSide(color: Color(0xFFE3D2C4)),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: isSubmitting ? null : submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7E4D),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit',
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

  descriptionController.dispose();
  if (submitted && context.mounted) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Thanks. Your report has been submitted.'),
        ),
      );
  }
  return submitted;
}

Future<bool> showOrderIssueSheet(
  BuildContext context, {
  required String orderId,
  String? restaurantName,
}) async {
  final cleanOrderId = orderId.trim();
  if (cleanOrderId.isEmpty) {
    return false;
  }
  final detailsController = TextEditingController();
  var selectedReason = OrderIssueReason.missingItem;
  var isSubmitting = false;
  var submitted = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFBF7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

          Future<void> submit() async {
            if (isSubmitting) {
              return;
            }
            setSheetState(() => isSubmitting = true);
            try {
              await OrderSupportService.instance.submitOrderIssue(
                orderId: cleanOrderId,
                reason: selectedReason,
                description: detailsController.text,
              );
              submitted = true;
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            } on OrderSupportServiceException catch (error) {
              if (!sheetContext.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.maybeOf(sheetContext);
              messenger
                ?..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(error.message)));
              setSheetState(() => isSubmitting = false);
            } catch (_) {
              if (!sheetContext.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.maybeOf(sheetContext);
              messenger
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'We could not submit your issue right now. Please try again.',
                    ),
                  ),
                );
              setSheetState(() => isSubmitting = false);
            }
          }

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Help',
                    style: TextStyle(
                      color: Color(0xFF231A16),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    restaurantName?.trim().isNotEmpty == true
                        ? 'Order #$cleanOrderId - ${restaurantName!.trim()}'
                        : 'Order #$cleanOrderId',
                    style: const TextStyle(
                      color: Color(0xFF7D6C60),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEADBCB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OrderIssueReason>(
                        value: selectedReason,
                        isExpanded: true,
                        items: OrderIssueReason.values
                            .map((reason) {
                              return DropdownMenuItem<OrderIssueReason>(
                                value: reason,
                                child: Text(
                                  reason.label,
                                  style: const TextStyle(
                                    color: Color(0xFF2F241B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setSheetState(() => selectedReason = value);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened',
                      filled: true,
                      fillColor: const Color(0xFFFEFCFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7B675A),
                            side: const BorderSide(color: Color(0xFFE3D2C4)),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: isSubmitting ? null : submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7E4D),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit',
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

  detailsController.dispose();
  if (submitted && context.mounted) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Support request submitted successfully.'),
        ),
      );
  }
  return submitted;
}

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

Future<void> openRestaurantReviewsPage(
  BuildContext context, {
  required String restaurantName,
  required double rating,
  List<RestaurantProfileReviewPreview> reviews =
      const <RestaurantProfileReviewPreview>[],
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _RestaurantReviewsPage(
        restaurantName: restaurantName,
        rating: rating,
        reviews: reviews,
      ),
    ),
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
  bool showFollowButton = false,
  bool showSaveButton = false,
  bool initiallyFollowing = false,
  VoidCallback? onToggleFollow,
  bool initiallySaved = false,
  ValueChanged<bool>? onToggleSave,
  VoidCallback? onOpenReviews,
  bool showMenuCategoryFilter = false,
  bool enableReportButton = true,
}) {
  final resolvedInitiallySaved =
      showSaveButton &&
      (initiallySaved ||
          _isCustomerRestaurantSaved(
            restaurantName: restaurantName,
            handle: handle,
          ));

  void handleToggleSave(bool isSaved) {
    _setCustomerRestaurantSaved(
      restaurantName: restaurantName,
      handle: handle,
      isSaved: isSaved,
    );
    onToggleSave?.call(isSaved);
  }

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
        showFollowButton: showFollowButton,
        showSaveButton: showSaveButton,
        initiallyFollowing: initiallyFollowing,
        onToggleFollow: onToggleFollow,
        initiallySaved: resolvedInitiallySaved,
        onToggleSave: handleToggleSave,
        onOpenReviews: onOpenReviews,
        showMenuCategoryFilter: showMenuCategoryFilter,
        showReportButton: enableReportButton,
        onReport: () {
          showReportSheet(
            context,
            itemType: ReportItemType.restaurantProfile,
            itemId: handle.trim().isEmpty ? restaurantName : handle,
            itemTitle: restaurantName,
          );
        },
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

typedef RestaurantVideoManageCallback = Future<void> Function(int index);

Future<void> openRestaurantProfileVideoFeed(
  BuildContext context, {
  required String restaurantName,
  required List<RestaurantProfileVideoPreview> videos,
  int initialIndex = 0,
  RestaurantVideoManageCallback? onManageVideo,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _RestaurantProfileVideoFeedScreen(
        restaurantName: restaurantName,
        videos: videos,
        initialIndex: initialIndex,
        onManageVideo: onManageVideo,
      ),
    ),
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
    Future<void> reportItem() async {
      await showReportSheet(
        context,
        itemType: ReportItemType.menuItem,
        itemId: item.id,
        itemTitle: item.title,
      );
    }

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: reportItem,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7E4D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    label: const Text(
                      'Report item',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
    this.showFollowButton = false,
    this.showSaveButton = false,
    this.initiallyFollowing = false,
    this.onToggleFollow,
    this.initiallySaved = false,
    this.onToggleSave,
    this.onOpenReviews,
    this.showMenuCategoryFilter = false,
    this.showReportButton = true,
    this.onReport,
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
  final bool showFollowButton;
  final bool showSaveButton;
  final bool initiallyFollowing;
  final VoidCallback? onToggleFollow;
  final bool initiallySaved;
  final ValueChanged<bool>? onToggleSave;
  final VoidCallback? onOpenReviews;
  final bool showMenuCategoryFilter;
  final bool showReportButton;
  final VoidCallback? onReport;

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
                  showFollowButton: showFollowButton,
                  showSaveButton: showSaveButton,
                  initiallyFollowing: initiallyFollowing,
                  onToggleFollow: onToggleFollow,
                  initiallySaved: initiallySaved,
                  onToggleSave: onToggleSave,
                  onOpenReviews: onOpenReviews,
                  showReportButton: showReportButton,
                  onReport: onReport,
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
                                  : _RestaurantProfileVideoGrid(
                                      restaurantName: restaurantName,
                                      videos: videos,
                                    ),
                              _RestaurantProfileMenuTabPanel(
                                restaurantName: restaurantName,
                                popularChoices: popularChoices,
                                menuList: menuList,
                                allowAddToCart: allowAddToCart,
                                onAddToCart: onAddToCart,
                                showCategoryFilter: showMenuCategoryFilter,
                              ),
                              _RestaurantProfileReviewsTabPanel(
                                reviews: reviewsList,
                                onOpenReviews: onOpenReviews,
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

class _PopupRestaurantHero extends StatefulWidget {
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
    this.showFollowButton = false,
    this.showSaveButton = false,
    this.initiallyFollowing = false,
    this.onToggleFollow,
    this.initiallySaved = false,
    this.onToggleSave,
    this.onOpenReviews,
    this.showReportButton = true,
    this.onReport,
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
  final bool showFollowButton;
  final bool showSaveButton;
  final bool initiallyFollowing;
  final VoidCallback? onToggleFollow;
  final bool initiallySaved;
  final ValueChanged<bool>? onToggleSave;
  final VoidCallback? onOpenReviews;
  final bool showReportButton;
  final VoidCallback? onReport;

  @override
  State<_PopupRestaurantHero> createState() => _PopupRestaurantHeroState();
}

class _PopupRestaurantHeroState extends State<_PopupRestaurantHero> {
  late bool _isFollowing;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initiallyFollowing;
    _isSaved = widget.initiallySaved;
  }

  @override
  void didUpdateWidget(covariant _PopupRestaurantHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyFollowing != widget.initiallyFollowing) {
      _isFollowing = widget.initiallyFollowing;
    }
    if (oldWidget.initiallySaved != widget.initiallySaved) {
      _isSaved = widget.initiallySaved;
    }
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    widget.onToggleFollow?.call();
  }

  void _toggleSaved() {
    final nextSaved = !_isSaved;
    setState(() => _isSaved = nextSaved);
    widget.onToggleSave?.call(nextSaved);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            nextSaved
                ? 'Saved to your places'
                : 'Removed from your saved places',
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    const coverHeight = 220.0;
    final cardHeight = widget.showFollowButton ? 336.0 : 286.0;
    const cardTop = coverHeight - 40;
    const avatarSize = 92.0;
    final totalHeight = cardTop + cardHeight;
    const avatarTop = cardTop - (avatarSize / 2);
    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: SizedBox(
              width: double.infinity,
              height: coverHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.coverImageUrl,
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
                        if (widget.showReportButton)
                          PopupMenuButton<String>(
                            tooltip: 'More actions',
                            color: const Color(0xFFFFFBF7),
                            onSelected: (value) {
                              if (value == 'report') {
                                widget.onReport?.call();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_outlined,
                                      color: Color(0xFFFF7E4D),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Report'),
                                  ],
                                ),
                              ),
                            ],
                            child: const _PopupTopOverlayButton(
                              icon: Icons.more_horiz_rounded,
                            ),
                          ),
                        if (widget.showReportButton) const SizedBox(width: 8),
                        if (widget.showSaveButton)
                          _PopupTopOverlayButton(
                            icon: _isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            onTap: _toggleSaved,
                            iconColor: _isSaved
                                ? const Color(0xFFFF7E4D)
                                : const Color(0xFF121212),
                            backgroundColor: _isSaved
                                ? const Color(0xFFFFF7F2)
                                : const Color(0xFFFFFFFF),
                            borderColor: _isSaved
                                ? const Color(0xFFFFC9B2)
                                : const Color(0xFF121212),
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
                    widget.restaurantName,
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
                    widget.cuisineSummary,
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
                        label: widget.ratingLabel == null
                            ? 'No ratings yet'
                            : widget.ratingLabel!,
                        onTap: widget.onOpenReviews,
                      ),
                      _PopupHeroMetaItem(
                        icon: Icons.call_rounded,
                        iconColor: const Color(0xFFFF7E4D),
                        label: widget.phoneLabel,
                      ),
                      _PopupHeroMetaItem(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF23A455),
                        label: widget.locationLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5D9CE)),
                    ),
                    child: Center(
                      child: _PopupProfileConnectionMetric(
                        value: widget.followersCountLabel,
                        label: 'Followers',
                        onTap: widget.onOpenFollowers,
                      ),
                    ),
                  ),
                  if (widget.showFollowButton) ...[
                    const SizedBox(height: 10),
                    _PopupFollowButton(
                      isFollowing: _isFollowing,
                      onTap: _toggleFollow,
                    ),
                  ],
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
                      widget.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26 * 0.55,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.handle,
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

class _PopupFollowButton extends StatelessWidget {
  const _PopupFollowButton({required this.isFollowing, this.onTap});

  final bool isFollowing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 112,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isFollowing
                  ? const Color(0xFFFFF4EC)
                  : const Color(0xFFFF7E4D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFollowing
                    ? const Color(0xFFE5D9CE)
                    : const Color(0xFFFF7E4D),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFollowing ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: isFollowing ? const Color(0xFFB66541) : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowing ? const Color(0xFFB66541) : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
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

class _PopupTopOverlayButton extends StatelessWidget {
  const _PopupTopOverlayButton({
    required this.icon,
    this.onTap,
    this.iconColor = const Color(0xFF121212),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFF121212),
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

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
            color: backgroundColor,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: iconColor, size: 24),
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
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
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
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      ),
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
              primary: false,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: children.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => children[index],
            ),
    );
  }
}

class _RestaurantProfileMenuTabPanel extends StatefulWidget {
  const _RestaurantProfileMenuTabPanel({
    required this.restaurantName,
    required this.popularChoices,
    required this.menuList,
    required this.allowAddToCart,
    required this.onAddToCart,
    this.showCategoryFilter = true,
  });

  final String restaurantName;
  final List<RestaurantMenuItem> popularChoices;
  final List<RestaurantMenuItem> menuList;
  final bool allowAddToCart;
  final ValueChanged<RestaurantMenuItem>? onAddToCart;
  final bool showCategoryFilter;

  @override
  State<_RestaurantProfileMenuTabPanel> createState() =>
      _RestaurantProfileMenuTabPanelState();
}

class _RestaurantProfileMenuTabPanelState
    extends State<_RestaurantProfileMenuTabPanel> {
  static const String _allCategory = 'All';
  String _selectedCategory = _allCategory;

  List<String> get _categories {
    final categories = <String>{};
    for (final item in <RestaurantMenuItem>[
      ...widget.popularChoices,
      ...widget.menuList,
    ]) {
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
  void didUpdateWidget(covariant _RestaurantProfileMenuTabPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _allCategory;
    }
  }

  List<RestaurantMenuItem> _filterItems(List<RestaurantMenuItem> source) {
    if (!widget.showCategoryFilter) {
      return source;
    }
    if (_selectedCategory == _allCategory) {
      return source;
    }
    final normalizedCategory = _selectedCategory.toLowerCase();
    return source
        .where(
          (item) => item.category.trim().toLowerCase() == normalizedCategory,
        )
        .toList(growable: false);
  }

  String _priceLabel(double? value) {
    if (value == null) {
      return '--';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final filteredPopular = _filterItems(widget.popularChoices);
    final filteredMenu = _filterItems(widget.menuList);

    final menuChildren = <Widget>[];
    Widget? fullMenuActionTile;
    menuChildren.add(const _TabSubSectionTitle('Popular Choices'));
    if (filteredPopular.isEmpty) {
      menuChildren.add(
        _MenuCategoryEmptyNote(
          message: widget.showCategoryFilter
              ? 'No popular items in "$_selectedCategory".'
              : 'No popular items yet.',
        ),
      );
    } else {
      menuChildren.addAll(
        filteredPopular.map(
          (item) => _RestaurantProfileMenuTile(
            item: item,
            priceLabel: _priceLabel(item.price),
            showPopularBadge: true,
            allowAddToCart: widget.allowAddToCart,
            onAddToCart: widget.onAddToCart,
          ),
        ),
      );
    }

    if (widget.allowAddToCart) {
      fullMenuActionTile = _RestaurantProfileFullMenuActionTile(
        restaurantName: widget.restaurantName,
        menuItems: widget.menuList,
        allowAddToCart: widget.allowAddToCart,
        onAddToCart: widget.onAddToCart,
      );
    } else {
      menuChildren.add(const _TabSubSectionTitle('Full Menu'));
      if (filteredMenu.isEmpty) {
        menuChildren.add(
          _MenuCategoryEmptyNote(
            message: widget.showCategoryFilter
                ? 'No full-menu items in "$_selectedCategory".'
                : 'No full-menu items yet.',
          ),
        );
      } else {
        menuChildren.addAll(
          filteredMenu.map(
            (item) => _RestaurantProfileMenuTile(
              item: item,
              priceLabel: _priceLabel(item.price),
              showPopularBadge: false,
              allowAddToCart: widget.allowAddToCart,
              onAddToCart: widget.onAddToCart,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4D8CA)),
      ),
      child: Column(
        children: [
          if (widget.showCategoryFilter && categories.length > 1) ...[
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
            const SizedBox(height: 8),
          ],
          Expanded(
            child: ListView.separated(
              primary: false,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: menuChildren.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => menuChildren[index],
            ),
          ),
          if (fullMenuActionTile != null) ...[
            const SizedBox(height: 8),
            fullMenuActionTile,
          ],
        ],
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

class _MenuCategoryEmptyNote extends StatelessWidget {
  const _MenuCategoryEmptyNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0DFC8)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF8A7768),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RestaurantProfileVideoGrid extends StatelessWidget {
  const _RestaurantProfileVideoGrid({
    required this.restaurantName,
    required this.videos,
  });

  final String restaurantName;
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
          final video = videos[index];
          return _RestaurantProfileVideoGridTile(
            video: video,
            onTap: () {
              openRestaurantProfileVideoFeed(
                context,
                restaurantName: restaurantName,
                videos: videos,
                initialIndex: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _RestaurantProfileVideoGridTile extends StatelessWidget {
  const _RestaurantProfileVideoGridTile({
    required this.video,
    required this.onTap,
  });

  final RestaurantProfileVideoPreview video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
        ),
      ),
    );
  }
}

class _RestaurantProfileVideoDemoScreen extends StatefulWidget {
  const _RestaurantProfileVideoDemoScreen({
    required this.restaurantName,
    required this.video,
    required this.videoAssetPath,
  });

  final String restaurantName;
  final RestaurantProfileVideoPreview video;
  final String videoAssetPath;

  @override
  State<_RestaurantProfileVideoDemoScreen> createState() =>
      _RestaurantProfileVideoDemoScreenState();
}

class _RestaurantProfileVideoDemoScreenState
    extends State<_RestaurantProfileVideoDemoScreen> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final assetPath = widget.videoAssetPath.trim();
    if (assetPath.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() => _hasError = true);
      return;
    }
    final controller = VideoPlayerController.asset(assetPath);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        return;
      }
      setState(() => _isReady = true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_isReady) {
      return;
    }
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isPlaying = controller?.value.isPlaying ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EFE5),
        elevation: 0,
        title: const Text(
          'Video Demo',
          style: TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF231A16)),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF151515),
                  child: AspectRatio(
                    aspectRatio: _isReady && controller != null
                        ? controller.value.aspectRatio
                        : 9 / 16,
                    child: _hasError
                        ? const Center(
                            child: Text(
                              'Demo video unavailable',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : !_isReady || controller == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF7E4D),
                            ),
                          )
                        : VideoPlayer(controller),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _hasError ? null : _togglePlayback,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(isPlaying ? 'Pause' : 'Play'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E4D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Demo clip',
                    style: const TextStyle(
                      color: Color(0xFF8A786B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.video.title,
                style: const TextStyle(
                  color: Color(0xFF231A16),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.restaurantName} • ${widget.video.meta}',
                style: const TextStyle(
                  color: Color(0xFF7E6D62),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is a demo player. Connect uploaded video URLs here later for live restaurant clips.',
                style: TextStyle(
                  color: Color(0xFF6D5D53),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantProfileVideoFeedScreen extends StatefulWidget {
  const _RestaurantProfileVideoFeedScreen({
    required this.restaurantName,
    required this.videos,
    required this.initialIndex,
    this.onManageVideo,
  });

  final String restaurantName;
  final List<RestaurantProfileVideoPreview> videos;
  final int initialIndex;
  final RestaurantVideoManageCallback? onManageVideo;

  @override
  State<_RestaurantProfileVideoFeedScreen> createState() =>
      _RestaurantProfileVideoFeedScreenState();
}

class _RestaurantProfileVideoFeedScreenState
    extends State<_RestaurantProfileVideoFeedScreen> {
  static const List<String> _demoVideoAssets = [
    'assets/videos/home_video_1.mp4',
    'assets/videos/home_video_2.mp4',
  ];
  final DemoAppRepository _repository = DemoAppRepository.instance;

  late final PageController _pageController;
  late final List<VideoPlayerController> _controllers;
  late final List<bool> _isReadyByIndex;
  late final List<bool> _hasErrorByIndex;
  late final List<bool> _isFollowingByIndex;
  late final List<int> _likesByIndex;
  late final List<int> _commentsByIndex;
  late int _currentIndex;
  final Set<int> _likedIndices = <int>{};
  final Map<int, Offset> _lastDoubleTapOffsetsByIndex = <int, Offset>{};
  final List<_RestaurantVideoLikeBurstData> _activeLikeBursts =
      <_RestaurantVideoLikeBurstData>[];
  int _nextLikeBurstId = 1;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.videos.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, maxIndex);
    _pageController = PageController(initialPage: _currentIndex);
    _controllers = List<VideoPlayerController>.generate(widget.videos.length, (
      index,
    ) {
      return VideoPlayerController.asset(_assetForIndex(index));
    });
    _isReadyByIndex = List<bool>.filled(widget.videos.length, false);
    _hasErrorByIndex = List<bool>.filled(widget.videos.length, false);
    _isFollowingByIndex = List<bool>.generate(
      widget.videos.length,
      (index) => index == 0,
    );
    _likesByIndex = List<int>.generate(widget.videos.length, (index) {
      return 1200 + (index * 170);
    });
    _commentsByIndex = List<int>.generate(widget.videos.length, (index) {
      return _repository.getComments(_postIdForVideoIndex(index)).length;
    });

    for (var index = 0; index < _controllers.length; index++) {
      _initializeController(index);
    }
  }

  String _assetForIndex(int index) {
    if (_demoVideoAssets.isEmpty) {
      return '';
    }
    return _demoVideoAssets[index % _demoVideoAssets.length];
  }

  Future<void> _initializeController(int index) async {
    final controller = _controllers[index];
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        return;
      }
      _isReadyByIndex[index] = true;
      _hasErrorByIndex[index] = false;
      if (index == _currentIndex) {
        await controller.play();
      } else {
        await controller.pause();
      }
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      _hasErrorByIndex[index] = true;
      _isReadyByIndex[index] = false;
      setState(() {});
    }
  }

  Future<void> _onPageChanged(int index) async {
    _currentIndex = index;
    for (var i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      if (!_isReadyByIndex[i]) {
        continue;
      }
      if (i == index) {
        await controller.play();
      } else {
        await controller.pause();
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toggleFollowForVideo(int index) {
    setState(() {
      _isFollowingByIndex[index] = !_isFollowingByIndex[index];
    });
  }

  void _toggleLikeForVideo(int index) {
    setState(() {
      if (_likedIndices.contains(index)) {
        _likedIndices.remove(index);
        _likesByIndex[index] = (_likesByIndex[index] - 1).clamp(0, 9999999);
      } else {
        _likedIndices.add(index);
        _likesByIndex[index] += 1;
      }
    });
  }

  String _postIdForVideoIndex(int index) {
    return index.isEven ? 'for-you' : 'following';
  }

  void _rememberDoubleTapPosition(int index, TapDownDetails details) {
    _lastDoubleTapOffsetsByIndex[index] = details.localPosition;
  }

  List<_RestaurantVideoLikeBurstData> _likeBurstsForVideoIndex(int index) {
    return _activeLikeBursts
        .where((item) => item.videoIndex == index)
        .toList(growable: false);
  }

  void _spawnLikeBurst({
    required int videoIndex,
    required Offset tapPosition,
    required Size surfaceSize,
  }) {
    final maxWidth = surfaceSize.width <= 0 ? 390.0 : surfaceSize.width;
    final maxHeight = surfaceSize.height <= 0 ? 700.0 : surfaceSize.height;
    final clampedX = maxWidth <= 96
        ? maxWidth / 2
        : tapPosition.dx.clamp(48.0, maxWidth - 48.0).toDouble();
    final clampedY = maxHeight <= 180
        ? maxHeight / 2
        : tapPosition.dy.clamp(90.0, maxHeight - 90.0).toDouble();
    final burst = _RestaurantVideoLikeBurstData(
      id: _nextLikeBurstId++,
      videoIndex: videoIndex,
      tapPosition: Offset(clampedX, clampedY),
    );
    setState(() => _activeLikeBursts.add(burst));
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _activeLikeBursts.removeWhere((item) => item.id == burst.id);
      });
    });
  }

  void _handleVideoDoubleTapLike(int index, Size surfaceSize) {
    final tapPosition =
        _lastDoubleTapOffsetsByIndex[index] ??
        Offset(surfaceSize.width / 2, surfaceSize.height * 0.55);
    _spawnLikeBurst(
      videoIndex: index,
      tapPosition: tapPosition,
      surfaceSize: surfaceSize,
    );
    if (_likedIndices.contains(index)) {
      return;
    }
    setState(() {
      _likedIndices.add(index);
      _likesByIndex[index] += 1;
    });
  }

  Future<void> _openCommentsForVideo(int index) async {
    final postId = _postIdForVideoIndex(index);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestaurantVideoCommentsBottomSheet(
        postId: postId,
        postTitle: widget.restaurantName,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _commentsByIndex[index] = _repository.getComments(postId).length;
    });
  }

  Future<void> _shareVideo(int index) async {
    final video = widget.videos[index];
    final result = await PostShareService.instance.sharePost(
      postId: _postIdForVideoIndex(index),
      title: widget.restaurantName,
      caption: video.title,
      creatorHandle: widget.restaurantName,
    );
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    if (!result.success) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Unable to share this video right now. Please try again.',
          ),
        ),
      );
      return;
    }
    if (result.copiedToClipboard) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard.')),
      );
    }
  }

  Future<void> _openManageVideo() async {
    final onManageVideo = widget.onManageVideo;
    if (onManageVideo == null) {
      return;
    }
    await onManageVideo(_currentIndex);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String _compactCount(int value) {
    if (value >= 1000000) {
      final valueInMillions = value / 1000000;
      final label = valueInMillions % 1 == 0
          ? valueInMillions.toStringAsFixed(0)
          : valueInMillions.toStringAsFixed(1);
      return '${label}M';
    }
    if (value >= 1000) {
      final valueInThousands = value / 1000;
      final label = valueInThousands % 1 == 0
          ? valueInThousands.toStringAsFixed(0)
          : valueInThousands.toStringAsFixed(1);
      return '${label}K';
    }
    return '$value';
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'HR';
    }
    if (parts.length == 1) {
      final value = parts.first;
      if (value.length >= 2) {
        return value.substring(0, 2).toUpperCase();
      }
      return value.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.videos;
    if (videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No videos available',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final video = videos[index];
          final controller = _controllers[index];
          final isReady = _isReadyByIndex[index];
          final hasError = _hasErrorByIndex[index];
          final isFollowing = _isFollowingByIndex[index];
          final isLiked = _likedIndices.contains(index);
          final likes = _likesByIndex[index];
          final comments = _commentsByIndex[index];
          final itemSize = MediaQuery.sizeOf(context);
          final likeBursts = _likeBurstsForVideoIndex(index);

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTapDown: (details) =>
                _rememberDoubleTapPosition(index, details),
            onDoubleTap: () => _handleVideoDoubleTapLike(index, itemSize),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _RestaurantVideoBackground(
                  controller: controller,
                  isReady: isReady,
                  hasError: hasError,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x26000000),
                        Color(0x1A000000),
                        Color(0xAA000000),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _VideoOverlayIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Home Style Demo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.onManageVideo != null)
                              _VideoOverlayIconButton(
                                icon: Icons.edit_rounded,
                                onTap: _openManageVideo,
                              )
                            else
                              const SizedBox(width: 42),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '@${widget.restaurantName.toLowerCase().replaceAll(' ', '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    video.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '#hungryrush #${widget.restaurantName.toLowerCase().replaceAll(' ', '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFF7E4D),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    video.meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xD9FFFFFF),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 74,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _RestaurantVideoFollowAvatar(
                                    initials: _initialsFromName(
                                      widget.restaurantName,
                                    ),
                                    isFollowing: isFollowing,
                                    onToggleFollow: () =>
                                        _toggleFollowForVideo(index),
                                  ),
                                  const SizedBox(height: 12),
                                  _VideoRailAction(
                                    icon: Icons.favorite_rounded,
                                    label: _compactCount(likes),
                                    onTap: () => _toggleLikeForVideo(index),
                                    iconColor: isLiked
                                        ? const Color(0xFFFF7E4D)
                                        : Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  _VideoRailAction(
                                    icon: Icons.mode_comment_outlined,
                                    label: _compactCount(comments),
                                    onTap: () => _openCommentsForVideo(index),
                                  ),
                                  const SizedBox(height: 12),
                                  _VideoRailAction(
                                    icon: Icons.share_outlined,
                                    label: 'Share',
                                    onTap: () => _shareVideo(index),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (likeBursts.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          for (final burst in likeBursts)
                            _RestaurantVideoLikeBurst(
                              key: ValueKey<int>(burst.id),
                              tapPosition: burst.tapPosition,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantVideoLikeBurstData {
  const _RestaurantVideoLikeBurstData({
    required this.id,
    required this.videoIndex,
    required this.tapPosition,
  });

  final int id;
  final int videoIndex;
  final Offset tapPosition;
}

class _RestaurantVideoLikeBurst extends StatelessWidget {
  const _RestaurantVideoLikeBurst({super.key, required this.tapPosition});

  final Offset tapPosition;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: tapPosition.dx - 52,
      top: tapPosition.dy - 72,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          final fade = progress < 0.72
              ? 1.0
              : (1 - (progress - 0.72) / 0.28).clamp(0.0, 1.0);
          final rise = 30 * progress;
          final pop = progress < 0.2
              ? 0.6 + progress * 2.1
              : 1.0 + (1 - progress) * 0.1;
          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, -rise),
              child: Transform.scale(
                scale: pop,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFAA72), Color(0xFFFF6D4F)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFDF2E8),
                      width: 2.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40A84329),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantVideoBackground extends StatelessWidget {
  const _RestaurantVideoBackground({
    required this.controller,
    required this.isReady,
    required this.hasError,
  });

  final VideoPlayerController controller;
  final bool isReady;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Demo video unavailable',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    if (!isReady) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7E4D)),
        ),
      );
    }

    final aspectRatio = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : (9 / 16);

    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1080,
            height: 1080 / aspectRatio,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoOverlayIconButton extends StatelessWidget {
  const _VideoOverlayIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0x3DFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _RestaurantVideoFollowAvatar extends StatelessWidget {
  const _RestaurantVideoFollowAvatar({
    required this.initials,
    required this.isFollowing,
    required this.onToggleFollow,
  });

  final String initials;
  final bool isFollowing;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
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
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleFollow,
              customBorder: const CircleBorder(),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7E4D),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  isFollowing ? Icons.check_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoRailAction extends StatelessWidget {
  const _VideoRailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x38FFFFFF),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0x3AFFFFFF)),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantVideoCommentsBottomSheet extends StatefulWidget {
  const _RestaurantVideoCommentsBottomSheet({
    required this.postId,
    required this.postTitle,
  });

  final String postId;
  final String postTitle;

  @override
  State<_RestaurantVideoCommentsBottomSheet> createState() =>
      _RestaurantVideoCommentsBottomSheetState();
}

class _RestaurantVideoCommentsBottomSheetState
    extends State<_RestaurantVideoCommentsBottomSheet> {
  final DemoAppRepository _repository = DemoAppRepository.instance;
  final TextEditingController _controller = TextEditingController();

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

  String _relative(DateTime value) {
    final difference = DateTime.now().difference(value);
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

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }
    FocusScope.of(context).unfocus();
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
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.56;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2C5BB),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_comments.length} comments',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF231A16),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF7A695E),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFECE1D7)),
              Expanded(
                child: _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet. Start the conversation.',
                          style: TextStyle(
                            color: Color(0xFF7E6D62),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        itemCount: _comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4EC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF0E2D5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFE4D1),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Color(0xFF9A5A3B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              comment.authorName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF231A16),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _relative(comment.createdAt),
                                            style: const TextStyle(
                                              color: Color(0xFF8A7A6F),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.body,
                                        style: const TextStyle(
                                          color: Color(0xFF5B4A41),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEADACC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEADACC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF9E70),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _isSending ? null : _sendComment,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7E4D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 22),
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

class _RestaurantProfileFullMenuActionTile extends StatelessWidget {
  const _RestaurantProfileFullMenuActionTile({
    required this.restaurantName,
    required this.menuItems,
    required this.allowAddToCart,
    required this.onAddToCart,
  });

  final String restaurantName;
  final List<RestaurantMenuItem> menuItems;
  final bool allowAddToCart;
  final ValueChanged<RestaurantMenuItem>? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _RestaurantFullMenuScreen(
                restaurantName: restaurantName,
                menuItems: menuItems,
                allowAddToCart: allowAddToCart,
                onAddToCart: onAddToCart,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD7C6)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFFFF7E4D),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'View Full Menu',
                  style: TextStyle(
                    color: Color(0xFF2F241B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9A7B67),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantFullMenuScreen extends StatefulWidget {
  const _RestaurantFullMenuScreen({
    required this.restaurantName,
    required this.menuItems,
    required this.allowAddToCart,
    required this.onAddToCart,
  });

  final String restaurantName;
  final List<RestaurantMenuItem> menuItems;
  final bool allowAddToCart;
  final ValueChanged<RestaurantMenuItem>? onAddToCart;

  @override
  State<_RestaurantFullMenuScreen> createState() =>
      _RestaurantFullMenuScreenState();
}

class _RestaurantFullMenuScreenState extends State<_RestaurantFullMenuScreen> {
  static const String _allCategory = 'All';
  String _selectedCategory = _allCategory;

  List<String> get _categories {
    final categories = <String>{};
    for (final item in widget.menuItems) {
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
      return widget.menuItems;
    }
    final normalized = _selectedCategory.toLowerCase();
    return widget.menuItems
        .where((item) => item.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  String _priceLabel(double? value) {
    if (value == null) {
      return '--';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  String _averagePriceLabel(List<RestaurantMenuItem> items) {
    if (items.isEmpty) {
      return '\$0.00';
    }
    var sum = 0.0;
    for (final item in items) {
      sum += item.price ?? 0;
    }
    return '\$${(sum / items.length).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final filteredItems = _filteredItems;
    final availableCount = filteredItems
        .where((item) => item.isAvailable)
        .length;
    final popularCount = filteredItems.where((item) => item.isPopular).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.restaurantName} Menu',
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
                child: const Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFFF7E4D),
                      size: 21,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap an item to view details and add it to cart.',
                        style: TextStyle(
                          color: Color(0xFF7D6C60),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RestaurantMenuStatCard(
                      label: 'Items',
                      value: '${filteredItems.length}',
                      icon: Icons.format_list_bulleted_rounded,
                      iconColor: const Color(0xFFFF7E4D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RestaurantMenuStatCard(
                      label: 'Available',
                      value: '$availableCount',
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF2E9B57),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RestaurantMenuStatCard(
                      label: 'Popular',
                      value: '$popularCount',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF0A523),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RestaurantMenuStatCard(
                      label: 'Avg',
                      value: _averagePriceLabel(filteredItems),
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _RestaurantProfileMenuTile(
                            item: item,
                            priceLabel: _priceLabel(item.price),
                            showPopularBadge: false,
                            allowAddToCart: widget.allowAddToCart,
                            onAddToCart: widget.onAddToCart,
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

class _RestaurantMenuStatCard extends StatelessWidget {
  const _RestaurantMenuStatCard({
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
    final hasComment = review.comment.trim().isNotEmpty;
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
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) {
                  if (value == 'report') {
                    showReportSheet(
                      context,
                      itemType: ReportItemType.review,
                      itemId: '${review.customerName}-${review.orderLabel}',
                      itemTitle: review.customerName,
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Text('Report review'),
                  ),
                ],
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF9A8B7E),
                ),
              ),
            ],
          ),
          if (hasComment) ...[
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
          ],
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

class _RestaurantProfileReviewsTabPanel extends StatelessWidget {
  const _RestaurantProfileReviewsTabPanel({
    required this.reviews,
    this.onOpenReviews,
  });

  final List<RestaurantProfileReviewPreview> reviews;
  final VoidCallback? onOpenReviews;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (onOpenReviews != null) {
      children.add(_RestaurantReviewPageActionTile(onTap: onOpenReviews!));
    }
    if (reviews.isEmpty) {
      children.add(
        const _MenuCategoryEmptyNote(
          message: 'No reviews yet for this restaurant.',
        ),
      );
    } else {
      children.addAll(
        reviews.map((review) => _RestaurantProfileReviewTile(review: review)),
      );
    }
    return _RestaurantProfileTabPanel(children: children);
  }
}

class _RestaurantReviewPageActionTile extends StatelessWidget {
  const _RestaurantReviewPageActionTile({required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD7C6)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.rate_review_rounded,
                color: Color(0xFFFF7E4D),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Open Reviews Page',
                  style: TextStyle(
                    color: Color(0xFF2F241B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9A7B67),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantReviewsPage extends StatefulWidget {
  const _RestaurantReviewsPage({
    required this.restaurantName,
    required this.rating,
    required this.reviews,
  });

  final String restaurantName;
  final double rating;
  final List<RestaurantProfileReviewPreview> reviews;

  @override
  State<_RestaurantReviewsPage> createState() => _RestaurantReviewsPageState();
}

class _RestaurantReviewsPageState extends State<_RestaurantReviewsPage> {
  late final TextEditingController _feedbackController;
  late List<RestaurantProfileReviewPreview> _reviews;
  double _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _reviews = List<RestaurantProfileReviewPreview>.from(widget.reviews);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) {
      return widget.rating;
    }
    final total = _reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    return total / _reviews.length;
  }

  bool get _canSubmitReview => _selectedRating > 0;

  void _submitReview() {
    final feedback = _feedbackController.text.trim();
    if (_selectedRating <= 0) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please select stars first.')),
        );
      return;
    }

    final newReview = RestaurantProfileReviewPreview(
      customerName: 'You',
      rating: _selectedRating,
      comment: feedback,
      timeLabel: 'Now',
      orderLabel: '#NEW',
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _reviews = <RestaurantProfileReviewPreview>[newReview, ..._reviews];
      _selectedRating = 0;
      _feedbackController.clear();
    });

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Thanks for your review.')));
  }

  @override
  Widget build(BuildContext context) {
    final reviewCount = _reviews.length;
    final average = _averageRating;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F2ED),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.restaurantName} Reviews',
          style: const TextStyle(
            color: Color(0xFF221B17),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5DACF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF1CC),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFB07800),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          average.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF2B211B),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reviewCount == 1
                              ? '1 customer review'
                              : '$reviewCount customer reviews',
                          style: const TextStyle(
                            color: Color(0xFF8A796C),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5DACF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave a Review',
                    style: TextStyle(
                      color: Color(0xFF2B211B),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      final isSelected = _selectedRating >= starNumber;
                      return IconButton(
                        onPressed: () {
                          setState(
                            () => _selectedRating = starNumber.toDouble(),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        splashRadius: 20,
                        icon: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isSelected
                              ? const Color(0xFFF5B63F)
                              : const Color(0xFFC5B8AB),
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Share your feedback (optional)',
                      filled: true,
                      fillColor: const Color(0xFFFEFCFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEADBCB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFF9E70)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canSubmitReview ? _submitReview : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7E4D),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review_rounded),
                      label: const Text(
                        'Submit Review',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_reviews.isEmpty)
              const _PopupEmptyState(
                icon: Icons.rate_review_rounded,
                title: 'No Reviews Yet',
                message:
                    'Customers have not left feedback for this restaurant yet.',
              )
            else
              ..._reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RestaurantProfileReviewTile(review: review),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.includeCustomers = true,
    this.returnSubmittedQuery = false,
    this.allowFriendActions = false,
  });

  final String initialQuery;
  final bool includeCustomers;
  final bool returnSubmittedQuery;
  final bool allowFriendActions;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repository = DemoAppRepository.instance;
  final _authSessionService = AuthSessionService();
  late final TextEditingController _controller;
  late final CustomerRestaurantApiService _restaurantApiService;
  int _activeSearchRequestId = 0;

  List<DemoSearchResult> _results = const <DemoSearchResult>[];
  final Map<String, bool> _restaurantFollowOverrides = <String, bool>{};
  bool _isLoading = false;

  String get _searchHintText {
    return widget.includeCustomers
        ? 'Search users or restaurants'
        : 'Search restaurants';
  }

  String get _searchPromptText {
    return widget.includeCustomers
        ? 'Start typing to search users or restaurants.'
        : 'Start typing to search restaurants.';
  }

  @override
  void initState() {
    super.initState();
    _restaurantApiService = CustomerRestaurantApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
      ),
    );
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_handleQueryChanged);
    if (widget.initialQuery.trim().isNotEmpty) {
      _runSearch(widget.initialQuery);
    }
  }

  void _handleQueryChanged() {
    _runSearch(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final cleanedQuery = query.trim();
    final requestId = ++_activeSearchRequestId;
    if (cleanedQuery.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const <DemoSearchResult>[];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    final customerResults = widget.includeCustomers
        ? (await _repository.search(cleanedQuery, includeCustomers: true))
              .where((item) => item.categoryLabel.toLowerCase() == 'customer')
              .toList(growable: false)
        : const <DemoSearchResult>[];
    final restaurantResults = await _searchLiveRestaurants(cleanedQuery);
    if (!mounted) {
      return;
    }
    if (requestId != _activeSearchRequestId) {
      return;
    }
    setState(() {
      _results = <DemoSearchResult>[...customerResults, ...restaurantResults];
      _isLoading = false;
    });
  }

  Future<List<DemoSearchResult>> _searchLiveRestaurants(String query) async {
    final session = await _authSessionService.readSession();
    if (session == null || session.token.trim().isEmpty) {
      return const <DemoSearchResult>[];
    }

    try {
      final page = await _restaurantApiService.fetchRestaurants(
        session: session,
        perPage: 30,
        query: query,
      );
      final filtered = page.restaurants
          .where((restaurant) => _restaurantMatchesQuery(restaurant, query))
          .toList(growable: false);
      final restaurants = filtered.isEmpty ? page.restaurants : filtered;
      return restaurants
          .map(_searchResultFromRestaurant)
          .toList(growable: false);
    } catch (error) {
      debugPrint('Live restaurant search failed: $error');
      return const <DemoSearchResult>[];
    }
  }

  bool _restaurantMatchesQuery(
    CustomerRestaurantItem restaurant,
    String query,
  ) {
    final cleanedQuery = _normalizeSearchQuery(query);
    if (cleanedQuery.isEmpty) {
      return true;
    }
    final haystack = _normalizeSearchQuery(
      '${restaurant.name} ${restaurant.description} ${restaurant.categoryLabel} ${restaurant.address}',
    );
    return haystack.contains(cleanedQuery);
  }

  String _normalizeSearchQuery(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  DemoSearchResult _searchResultFromRestaurant(
    CustomerRestaurantItem restaurant,
  ) {
    final description = restaurant.description.trim();
    final address = restaurant.address.trim();
    final subtitle = description.isNotEmpty
        ? description
        : (address.isNotEmpty ? address : restaurant.categoryLabel);
    final handle = restaurant.id.trim().isNotEmpty
        ? 'restaurant-${restaurant.id}'
        : restaurant.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (restaurant.isFollowing && restaurant.id.trim().isNotEmpty) {
      _restaurantFollowOverrides.putIfAbsent(restaurant.id.trim(), () => true);
    }
    return DemoSearchResult(
      id: 'restaurant-live-${restaurant.id}',
      restaurantId: restaurant.id,
      title: restaurant.name,
      subtitle: subtitle,
      categoryLabel: 'Restaurant',
      handle: handle,
      imageUrl: restaurant.profilePhotoUrl,
      rating: restaurant.averageRating,
      phoneLabel: restaurant.phone,
      locationLabel: restaurant.address,
      isFollowingRestaurant: restaurant.isFollowing,
    );
  }

  Future<void> _handleSubmittedSearch(String query) async {
    final cleanedQuery = query.trim();
    if (widget.returnSubmittedQuery) {
      if (cleanedQuery.isNotEmpty) {
        Navigator.of(context).pop(cleanedQuery);
      }
      return;
    }
    await _runSearch(cleanedQuery);
  }

  void _handleBackPressed() {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }
  }

  Future<void> _openRestaurantProfileFromResult(DemoSearchResult result) async {
    final restaurantId = result.restaurantId?.trim();
    if (restaurantId != null && restaurantId.isNotEmpty) {
      await _openLiveRestaurantProfileFromResult(result, restaurantId);
      return;
    }
    if (!result.id.startsWith('post-')) {
      return;
    }
    final postId = result.id.substring('post-'.length);
    final post = _repository.findFeedPost(postId);
    if (post == null || !mounted) {
      return;
    }
    await showRestaurantProfilePopup(
      context,
      restaurantName: post.restaurantName,
      handle: post.restaurantHandle,
      rating: post.rating,
      caption: post.caption,
      followersCountLabel: '${post.followersCount} followers',
    );
  }

  Future<void> _openLiveRestaurantProfileFromResult(
    DemoSearchResult result,
    String restaurantId,
  ) async {
    final session = await _authSessionService.readSession();
    List<RestaurantMenuItem> menuItems = const <RestaurantMenuItem>[];
    if (session != null && session.token.trim().isNotEmpty) {
      try {
        menuItems = await _restaurantApiService.fetchRestaurantMenu(
          session: session,
          restaurantId: restaurantId,
        );
      } catch (error) {
        debugPrint('Search restaurant menu load failed: $error');
      }
    }
    if (!mounted) {
      return;
    }
    await showRestaurantProfilePopup(
      context,
      restaurantName: result.title,
      handle: result.handle ?? 'restaurant-$restaurantId',
      rating: result.rating ?? 0,
      caption: result.subtitle,
      cuisineSummary: result.subtitle,
      phoneLabel: result.phoneLabel,
      locationLabel: result.locationLabel,
      profileImageUrl: result.imageUrl,
      menuItems: menuItems,
      showFollowButton: true,
      initiallyFollowing: _isRestaurantFollowing(result),
      onToggleFollow: () => unawaited(_toggleRestaurantFollow(result)),
      enableReportButton: false,
    );
  }

  bool _isRestaurantFollowing(DemoSearchResult result) {
    final restaurantId = result.restaurantId?.trim();
    if (restaurantId == null || restaurantId.isEmpty) {
      return result.isFollowingRestaurant;
    }
    return _restaurantFollowOverrides[restaurantId] ??
        result.isFollowingRestaurant;
  }

  Future<void> _toggleRestaurantFollow(DemoSearchResult result) async {
    final restaurantId = result.restaurantId?.trim();
    if (restaurantId == null || restaurantId.isEmpty) {
      return;
    }
    final session = await _authSessionService.readSession();
    if (session == null || session.token.trim().isEmpty) {
      _showSearchSnackBar('Please log in again to follow restaurants.');
      return;
    }
    final previous = _isRestaurantFollowing(result);
    final next = !previous;
    setState(() => _restaurantFollowOverrides[restaurantId] = next);
    try {
      if (next) {
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
      debugPrint('Search restaurant follow failed: $error');
      if (!mounted) {
        return;
      }
      setState(() => _restaurantFollowOverrides[restaurantId] = previous);
      _showSearchSnackBar('Could not update follow status. Try again.');
    }
  }

  void _showSearchSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCustomerProfileFromResult(DemoSearchResult result) async {
    if (!result.id.startsWith('thread-')) {
      return;
    }
    final threadId = result.id.substring('thread-'.length);
    final thread = _repository.findThread(threadId);
    if (thread == null || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CustomerPublicProfileScreen(
          profileId: 'customer-${thread.id}',
          displayName: thread.customerName,
          subtitle: thread.lastMessage,
          allowFriendActions: widget.allowFriendActions,
        ),
      ),
    );
  }

  List<DemoSearchResult> get _restaurantResults {
    return _results
        .where((item) => item.categoryLabel.toLowerCase() == 'restaurant')
        .toList(growable: false);
  }

  List<DemoSearchResult> get _customerResults {
    return _results
        .where((item) => item.categoryLabel.toLowerCase() == 'customer')
        .toList(growable: false);
  }

  Widget _buildResultsSection({
    required String title,
    required List<DemoSearchResult> items,
    required VoidCallback Function(DemoSearchResult result)? onTapBuilder,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6D5B4F),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          return Column(
            children: [
              ListTile(
                onTap: onTapBuilder == null ? null : onTapBuilder(result),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: const Color(0xFFF3F0EC),
                title: Text(result.title),
                subtitle: Text(result.subtitle),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB59885),
                ),
              ),
              if (index != items.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _handleBackPressed,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSubmittedSearch,
              decoration: InputDecoration(
                hintText: _searchHintText,
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
            if (_controller.text.trim().isEmpty)
              Expanded(
                child: Center(
                  child: Text(_searchPromptText, textAlign: TextAlign.center),
                ),
              )
            else
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 360),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4DDD6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _results.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No users or restaurants found.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            _buildResultsSection(
                              title: 'Users',
                              items: _customerResults,
                              onTapBuilder: (result) =>
                                  () => _openCustomerProfileFromResult(result),
                            ),
                            _buildResultsSection(
                              title: 'Restaurants',
                              items: _restaurantResults,
                              onTapBuilder: (result) =>
                                  () =>
                                      _openRestaurantProfileFromResult(result),
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

class _CustomerPublicProfileScreen extends StatefulWidget {
  const _CustomerPublicProfileScreen({
    required this.profileId,
    required this.displayName,
    required this.subtitle,
    required this.allowFriendActions,
  });

  final String profileId;
  final String displayName;
  final String subtitle;
  final bool allowFriendActions;

  @override
  State<_CustomerPublicProfileScreen> createState() =>
      _CustomerPublicProfileScreenState();
}

class _CustomerPublicProfileScreenState
    extends State<_CustomerPublicProfileScreen> {
  static const String _viewerId = 'viewer-customer';
  final _socialGraphService = SocialGraphService.instance;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  bool _isFollowing = false;
  bool _isUpdatingFollow = false;
  bool _isUpdatingFriend = false;

  @override
  void initState() {
    super.initState();
    _syncState();
  }

  String get _targetId => widget.profileId.trim().toLowerCase();

  String get _handle {
    final cleaned = widget.displayName.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    return cleaned.isEmpty ? '@customer' : '@$cleaned';
  }

  String get _initials {
    final words = widget.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return 'CU';
    }
    if (words.length == 1) {
      final value = words.first.toUpperCase();
      return value.length >= 2 ? value.substring(0, 2) : value;
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Future<void> _syncState() async {
    final follow = _socialGraphService.isFollowingCustomer(
      viewerId: _viewerId,
      targetId: _targetId,
    );
    final friend = await _socialGraphService.refreshFriendshipStatus(
      viewerId: _viewerId,
      targetId: _targetId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isFollowing = follow;
      _friendshipStatus = friend;
    });
    if (_friendshipStatus == FriendshipStatus.requestSent) {
      _pollFriendRequest();
    }
  }

  Future<void> _pollFriendRequest() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted || _friendshipStatus != FriendshipStatus.requestSent) {
      return;
    }
    final status = await _socialGraphService.refreshFriendshipStatus(
      viewerId: _viewerId,
      targetId: _targetId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _friendshipStatus = status);
  }

  Future<void> _toggleFollow() async {
    if (_isUpdatingFollow) {
      return;
    }
    setState(() => _isUpdatingFollow = true);
    try {
      final nextState = await _socialGraphService.toggleFollowCustomer(
        viewerId: _viewerId,
        targetId: _targetId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isFollowing = nextState);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nextState ? 'Now following user.' : 'Unfollowed user.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFollow = false);
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_isUpdatingFriend || _friendshipStatus != FriendshipStatus.none) {
      return;
    }
    setState(() => _isUpdatingFriend = true);
    try {
      final next = await _socialGraphService.sendFriendRequest(
        viewerId: _viewerId,
        targetId: _targetId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _friendshipStatus = next);
      _pollFriendRequest();
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Friend request sent.')));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFriend = false);
      }
    }
  }

  Future<void> _removeFriend() async {
    if (_isUpdatingFriend || _friendshipStatus != FriendshipStatus.friends) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove friend'),
          content: Text('Remove ${widget.displayName} from your friends list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E4D),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isUpdatingFriend = true);
    try {
      final next = await _socialGraphService.removeFriend(
        viewerId: _viewerId,
        targetId: _targetId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _friendshipStatus = next);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Friend removed.')));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFriend = false);
      }
    }
  }

  Future<void> _reportProfile() async {
    await showReportSheet(
      context,
      itemType: ReportItemType.customerProfile,
      itemId: _targetId,
      itemTitle: widget.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFriendActions = widget.allowFriendActions;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: const Text('User Profile'),
        actions: [
          IconButton(
            onPressed: _reportProfile,
            tooltip: 'Report profile',
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFECDDCF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD8B6), Color(0xFFFFAE79)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Color(0xFF6A3D24),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.displayName,
                            style: const TextStyle(
                              color: Color(0xFF231A16),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _handle,
                            style: const TextStyle(
                              color: Color(0xFF88786D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7D6C60),
                              fontSize: 13,
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
              const SizedBox(height: 14),
              if (!showFriendActions)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF2D8C5)),
                  ),
                  child: const Text(
                    'This profile is shown in preview mode.',
                    style: TextStyle(
                      color: Color(0xFF6A574B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUpdatingFollow ? null : _toggleFollow,
                        icon: Icon(
                          _isFollowing
                              ? Icons.check_rounded
                              : Icons.person_add_alt_rounded,
                        ),
                        label: Text(_isFollowing ? 'Following' : 'Follow'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7E4D),
                          side: const BorderSide(color: Color(0xFFFFC9B2)),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _friendshipStatus == FriendshipStatus.none
                          ? FilledButton(
                              onPressed: _isUpdatingFriend
                                  ? null
                                  : _sendFriendRequest,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7E4D),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Add Friend'),
                            )
                          : _friendshipStatus == FriendshipStatus.requestSent
                          ? FilledButton(
                              onPressed: null,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB793),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Request Sent'),
                            )
                          : OutlinedButton(
                              onPressed: _isUpdatingFriend
                                  ? null
                                  : _removeFriend,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2F8A7E),
                                side: const BorderSide(
                                  color: Color(0xFFCBE6E1),
                                ),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Remove Friend'),
                            ),
                    ),
                  ],
                ),
            ],
          ),
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
  final _authSessionService = AuthSessionService();
  late final NotificationApiService _notificationApiService;

  AuthSession? _session;
  List<AppNotification> _items = const <AppNotification>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _notificationApiService = NotificationApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
        onSessionUpdated: (session) async => _session = session,
      ),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _resolveSession();
      if (session == null) {
        _setLoadError('Please log in again to view notifications.');
        return;
      }

      final items = await _notificationApiService.fetchNotifications(
        session: session,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
        _items = items;
        _isLoading = false;
      });
    } on AuthSessionExpiredException {
      await _authSessionService.clearSession();
      _setLoadError('Please log in again to view notifications.');
    } on AuthApiException catch (error, stackTrace) {
      _debugNotificationError(error, stackTrace);
      _setLoadError('We could not load your notifications. Please try again.');
    } catch (error, stackTrace) {
      _debugNotificationError(error, stackTrace);
      _setLoadError('We could not load your notifications. Please try again.');
    }
  }

  Future<AuthSession?> _resolveSession() async {
    final cached = _session;
    if (cached != null && cached.token.trim().isNotEmpty) {
      return cached;
    }
    final session = await _authSessionService.readSession();
    _session = session;
    return session;
  }

  void _setLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    final session = await _resolveSession();
    if (session == null) {
      _showFriendlySnackBar('Please log in again to update notifications.');
      return;
    }

    final previousItems = _items;
    setState(
      () => _items = _items
          .map((item) => item.copyWith(isRead: true, readAt: DateTime.now()))
          .toList(growable: false),
    );

    try {
      await _notificationApiService.markAllAsRead(session: session);
    } catch (error, stackTrace) {
      _debugNotificationError(error, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _items = previousItems);
      _showFriendlySnackBar(
        'Could not update notifications. Please try again.',
      );
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.isRead || item.id.trim().isEmpty) {
      return;
    }
    final session = await _resolveSession();
    if (session == null) {
      _showFriendlySnackBar('Please log in again to update notifications.');
      return;
    }

    final previousItems = _items;
    final readItem = item.copyWith(isRead: true, readAt: DateTime.now());
    setState(() => _replaceNotification(readItem));

    try {
      final updated = await _notificationApiService.markAsRead(
        session: session,
        notificationId: item.id,
      );
      if (updated != null && mounted) {
        setState(() => _replaceNotification(updated));
      }
    } catch (error, stackTrace) {
      _debugNotificationError(error, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _items = previousItems);
      _showFriendlySnackBar('Could not update notification. Please try again.');
    }
  }

  void _replaceNotification(AppNotification updated) {
    _items = _items
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
  }

  void _showFriendlySnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _debugNotificationError(Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('Notifications error: $error');
    debugPrint('$stackTrace');
  }

  String _notificationTimeLabel(AppNotification item) {
    final createdAt = item.createdAt;
    if (createdAt == null) {
      return 'Recently';
    }
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
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
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : _items.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  onTap: item.isRead ? null : () => _markRead(item),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.body.isNotEmpty) Text(item.body),
                      const SizedBox(height: 6),
                      Text(
                        _notificationTimeLabel(item),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7A6A5E),
                        ),
                      ),
                    ],
                  ),
                  trailing: item.isRead
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF7A6A5E),
                        )
                      : IconButton(
                          tooltip: 'Mark as read',
                          onPressed: () => _markRead(item),
                          icon: const Icon(Icons.mark_email_read_rounded),
                        ),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(comment.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'More actions',
                        onSelected: (value) {
                          if (value == 'report') {
                            showReportSheet(
                              context,
                              itemType: ReportItemType.comment,
                              itemId: comment.id,
                              itemTitle: comment.authorName,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Text('Report comment'),
                          ),
                        ],
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF9E8A7E),
                        ),
                      ),
                    ],
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

enum RestaurantOrderFilter { all, active, completed }

class LiveRestaurantOrdersScreen extends StatefulWidget {
  const LiveRestaurantOrdersScreen({
    super.key,
    required this.title,
    this.filter = RestaurantOrderFilter.all,
  });

  final String title;
  final RestaurantOrderFilter filter;

  @override
  State<LiveRestaurantOrdersScreen> createState() =>
      _LiveRestaurantOrdersScreenState();
}

class _LiveRestaurantOrdersScreenState
    extends State<LiveRestaurantOrdersScreen> {
  late final AuthSessionService _sessionService;
  late final RestaurantOrderApiService _orderApiService;
  List<AppOrder> _orders = const <AppOrder>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sessionService = AuthSessionService();
    _orderApiService = RestaurantOrderApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _sessionService,
      ),
    );
    unawaited(_loadOrders());
  }

  List<AppOrder> get _filteredOrders {
    switch (widget.filter) {
      case RestaurantOrderFilter.active:
        return _orders.where((order) => order.isActive).toList(growable: false);
      case RestaurantOrderFilter.completed:
        return _orders
            .where((order) => order.isCompleted)
            .toList(growable: false);
      case RestaurantOrderFilter.all:
        return _orders;
    }
  }

  Future<void> _loadOrders({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final session = await _sessionService.readSession();
      if (session == null || session.token.trim().isEmpty) {
        throw const AuthApiException('Please log in again.');
      }
      final orders = await _orderApiService.fetchOrders(session: session);
      if (!mounted) {
        return;
      }
      setState(() {
        _orders = orders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint('Restaurant orders load failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load orders. Pull to refresh or try again.';
      });
    }
  }

  Future<void> _openOrder(AppOrder order) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LiveRestaurantOrderDetailScreen(
          orderId: order.id,
          initialOrder: order,
        ),
      ),
    );
    if (changed == true) {
      unawaited(_loadOrders(showSpinner: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => unawaited(_loadOrders()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadOrders(showSpinner: false),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 54,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () => unawaited(_loadOrders()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              )
            : orders.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 90),
                  Icon(
                    Icons.inbox_outlined,
                    size: 54,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No orders found.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    onTap: () => unawaited(_openOrder(order)),
                    tileColor: const Color(0xFFF3F0EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('${order.displayId} - ${order.customerName}'),
                    subtitle: Text(order.itemSummary),
                    trailing: _OrderStatusChip(label: order.statusLabel),
                  );
                },
              ),
      ),
    );
  }
}

class LiveRestaurantOrderDetailScreen extends StatefulWidget {
  const LiveRestaurantOrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  final String orderId;
  final AppOrder? initialOrder;

  @override
  State<LiveRestaurantOrderDetailScreen> createState() =>
      _LiveRestaurantOrderDetailScreenState();
}

class _LiveRestaurantOrderDetailScreenState
    extends State<LiveRestaurantOrderDetailScreen> {
  late final AuthSessionService _sessionService;
  late final RestaurantOrderApiService _orderApiService;
  AppOrder? _order;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _sessionService = AuthSessionService();
    _orderApiService = RestaurantOrderApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _sessionService,
      ),
    );
    if (_order == null) {
      unawaited(_loadOrder());
    }
  }

  Future<AuthSession> _readSession() async {
    final session = await _sessionService.readSession();
    if (session == null || session.token.trim().isEmpty) {
      throw const AuthApiException('Please log in again.');
    }
    return session;
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final order = await _orderApiService.fetchOrder(
        session: await _readSession(),
        orderId: widget.orderId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Restaurant order detail load failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load this order.';
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final order = _order;
    if (order == null || _isUpdating) {
      return;
    }
    setState(() => _isUpdating = true);
    try {
      await _orderApiService.updateStatus(
        session: await _readSession(),
        orderId: order.id,
        status: status,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('Restaurant order status update failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not update the order. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  List<_RestaurantOrderAction> _actionsFor(AppOrder order) {
    switch (order.status.trim().toLowerCase().replaceAll('-', '_')) {
      case 'pending':
        return const [
          _RestaurantOrderAction('Accept', 'accepted', true),
          _RestaurantOrderAction('Reject', 'rejected', false),
        ];
      case 'accepted':
        return const [
          _RestaurantOrderAction('Start Preparing', 'preparing', true),
          _RestaurantOrderAction('Reject', 'rejected', false),
        ];
      case 'preparing':
        return const [
          _RestaurantOrderAction('Mark Ready', 'ready_for_pickup', true),
        ];
      case 'ready':
      case 'ready_for_pickup':
        return const [_RestaurantOrderAction('Picked Up', 'picked_up', true)];
      case 'picked_up':
        return const [_RestaurantOrderAction('Send Out', 'on_the_way', true)];
      case 'on_the_way':
      case 'on the way':
        return const [
          _RestaurantOrderAction('Mark Delivered', 'delivered', true),
        ];
    }
    return const <_RestaurantOrderAction>[];
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: Text(order?.displayId ?? 'Order')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => unawaited(_loadOrder()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : order == null
          ? const Center(child: Text('Order not found.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    _OrderStatusChip(label: order.statusLabel),
                  ],
                ),
                const SizedBox(height: 14),
                _OrderInfoRow(label: 'Restaurant', value: order.restaurantName),
                _OrderInfoRow(label: 'Items', value: order.itemSummary),
                _OrderInfoRow(label: 'Channel', value: order.channelLabel),
                if (order.etaLabel.trim().isNotEmpty)
                  _OrderInfoRow(label: 'ETA', value: order.etaLabel),
                if (order.addressLabel.trim().isNotEmpty)
                  _OrderInfoRow(label: 'Address', value: order.addressLabel),
                _OrderInfoRow(label: 'Total', value: order.totalLabel),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Line items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(item.quantityLabel),
                      trailing: Text(item.totalLabel),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ..._actionsFor(order).map((action) {
                  final buttonChild = _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(action.label);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: action.primary
                        ? FilledButton(
                            onPressed: _isUpdating
                                ? null
                                : () => unawaited(_updateStatus(action.status)),
                            child: buttonChild,
                          )
                        : OutlinedButton(
                            onPressed: _isUpdating
                                ? null
                                : () => unawaited(_updateStatus(action.status)),
                            child: buttonChild,
                          ),
                  );
                }),
              ],
            ),
    );
  }
}

class _RestaurantOrderAction {
  const _RestaurantOrderAction(this.label, this.status, this.primary);

  final String label;
  final String status;
  final bool primary;
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB65D37),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7D6C60),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF231A16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
  final _authSessionService = AuthSessionService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final ConversationApiService _conversationApiService;

  DemoConversationThread? _thread;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversationApiService = ConversationApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
      ),
    );
    _loadThread();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    try {
      final session = await _authSessionService.readSession();
      if (session == null || session.token.trim().isEmpty) {
        throw const ConversationApiException(
          'Please log in again to load this conversation.',
        );
      }
      final conversation = await _conversationApiService.fetchConversation(
        session: session,
        conversationId: widget.threadId,
      );
      await _conversationApiService.markRead(
        session: session,
        conversationId: widget.threadId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = _threadFromConversation(conversation);
        _error = null;
      });
      if (widget.openComposerOnStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    }
  }

  DemoConversationThread _threadFromConversation(
    AppConversation conversation, {
    List<DemoConversationMessage>? messages,
  }) {
    final latestAt =
        conversation.lastMessageAt ?? conversation.latestMessage?.createdAt;
    final isOrderThread = conversation.orderId.trim().isNotEmpty;
    return DemoConversationThread(
      id: conversation.id,
      customerName: conversation.restaurantName,
      lastMessage: conversation.previewText,
      timeLabel: latestAt == null ? 'Recent' : _formatTime(latestAt),
      orderLabel: isOrderThread ? '#${conversation.orderId}' : 'General',
      channelLabel: conversation.displaySubject,
      unreadCount: 0,
      priority: false,
      needsReply: false,
      online: false,
      type: isOrderThread ? MessageThreadType.order : MessageThreadType.offer,
      messages:
          messages ??
          conversation.messages
              .map(
                (message) => DemoConversationMessage(
                  id: message.id,
                  senderName: message.senderName,
                  body: message.body,
                  sentAt: message.createdAt ?? DateTime.now(),
                  fromRestaurant: message.fromRestaurant,
                ),
              )
              .toList(growable: false),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thread == null) {
      return;
    }
    setState(() => _isSending = true);
    try {
      final session = await _authSessionService.readSession();
      if (session == null || session.token.trim().isEmpty) {
        throw const ConversationApiException(
          'Please log in again to send messages.',
        );
      }
      final created = await _conversationApiService.sendMessage(
        session: session,
        conversationId: _thread!.id,
        body: text,
      );
      if (!mounted) {
        return;
      }
      final current = _thread!;
      _controller.clear();
      setState(() {
        _thread = current.copyWith(
          messages: <DemoConversationMessage>[
            ...current.messages,
            DemoConversationMessage(
              id: created.id,
              senderName: created.senderName,
              body: created.body,
              sentAt: created.createdAt ?? DateTime.now(),
              fromRestaurant: created.fromRestaurant,
            ),
          ],
          lastMessage: created.body,
          timeLabel: 'Now',
        );
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply sent')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _reportConversation() async {
    await showReportSheet(
      context,
      itemType: ReportItemType.conversation,
      itemId: widget.threadId,
      itemTitle: _thread?.customerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    return Scaffold(
      appBar: AppBar(
        title: Text(thread?.customerName ?? 'Conversation'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Conversation actions',
            onSelected: (value) {
              if (value == 'report') {
                _reportConversation();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Color(0xFFFF7E4D)),
                    SizedBox(width: 8),
                    Text('Report conversation'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7D3D34),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : thread == null
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
