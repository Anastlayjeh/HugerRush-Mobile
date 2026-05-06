import 'dart:async';

import 'moderation_support_models.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'auth_session_service.dart';
import 'authenticated_api_client.dart';

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
  final AuthSessionService _sessionService = AuthSessionService();

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

    final session = await _sessionService.readSession();
    if (session == null || session.token.trim().isEmpty) {
      throw const OrderSupportServiceException('Please log in again.');
    }

    final apiClient = AuthenticatedApiClient(
      authApiService: AuthApiService(),
      authSessionService: _sessionService,
    );
    final response = await apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/reports',
      body: <String, dynamic>{
        if (int.tryParse(cleanedOrderId.replaceFirst('#', '')) != null)
          'order_id': cleanedOrderId.replaceFirst('#', ''),
        'subject': 'Order issue: ${reason.label}',
        'message': description.trim().isEmpty
            ? 'Issue reported for order $cleanedOrderId.'
            : description.trim(),
      },
    );
    final payload = ApiClient.decodeMap(response.response.body);
    if (response.response.statusCode < 200 ||
        response.response.statusCode >= 300) {
      throw OrderSupportServiceException(
        ApiClient.errorMessageForStatus(
          response.response.statusCode,
          payload,
          fallback: 'Could not submit order issue.',
        ),
      );
    }
    final data = payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final submission = OrderIssueSubmission(
      id: (data['id'] as Object?)?.toString() ??
          'issue-${DateTime.now().microsecondsSinceEpoch}',
      orderId: cleanedOrderId,
      reason: reason,
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _submissions.insert(0, submission);

    return submission;
  }
}

class OrderSupportServiceException implements Exception {
  const OrderSupportServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
