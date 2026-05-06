import 'dart:async';

import 'moderation_support_models.dart';

class OrderIssueSubmission {
  const OrderIssueSubmission({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final OrderIssueReason reason;
  final String description;
  final DateTime createdAt;
}

class OrderSupportService {
  OrderSupportService._();

  static final OrderSupportService instance = OrderSupportService._();

  final List<OrderIssueSubmission> _submissions = <OrderIssueSubmission>[];

  List<OrderIssueSubmission> get submissions => List<OrderIssueSubmission>.from(
    _submissions,
  );

  Future<OrderIssueSubmission> submitOrderIssue({
    required String orderId,
    required OrderIssueReason reason,
    String description = '',
  }) async {
    final cleanedOrderId = orderId.trim();
    if (cleanedOrderId.isEmpty) {
      throw const OrderSupportServiceException('Order ID is required.');
    }

    await Future<void>.delayed(const Duration(milliseconds: 550));

    final submission = OrderIssueSubmission(
      id: 'issue-${DateTime.now().microsecondsSinceEpoch}',
      orderId: cleanedOrderId,
      reason: reason,
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _submissions.insert(0, submission);

    // TODO(api): Replace this mock insertion with an order-support backend endpoint.
    return submission;
  }
}

class OrderSupportServiceException implements Exception {
  const OrderSupportServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
