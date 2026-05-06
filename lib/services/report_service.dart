import 'dart:async';

import 'moderation_support_models.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'auth_session_service.dart';
import 'authenticated_api_client.dart';

class ReportSubmission {
  const ReportSubmission({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.reason,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final ReportItemType itemType;
  final String itemId;
  final ReportReason reason;
  final String description;
  final DateTime createdAt;
}

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  final List<ReportSubmission> _submissions = <ReportSubmission>[];
  final AuthSessionService _sessionService = AuthSessionService();

  List<ReportSubmission> get submissions => List<ReportSubmission>.from(
    _submissions,
  );

  Future<ReportSubmission> submitReport({
    required ReportItemType itemType,
    required String itemId,
    required ReportReason reason,
    String description = '',
  }) async {
    final cleanedItemId = itemId.trim();
    if (cleanedItemId.isEmpty) {
      throw const ReportServiceException('Missing item reference for report.');
    }

    final session = await _sessionService.readSession();
    if (session == null || session.token.trim().isEmpty) {
      throw const ReportServiceException('Please log in again.');
    }

    final subject = '${itemType.label}: ${reason.label}';
    final message = <String>[
      'Reported item: $cleanedItemId',
      if (description.trim().isNotEmpty) description.trim(),
    ].join('\n\n');
    final body = <String, dynamic>{
      'subject': subject,
      'message': message,
      if (itemType == ReportItemType.restaurantProfile &&
          int.tryParse(cleanedItemId) != null)
        'restaurant_id': cleanedItemId,
      if (itemType == ReportItemType.order && int.tryParse(cleanedItemId) != null)
        'order_id': cleanedItemId,
    };

    final apiClient = AuthenticatedApiClient(
      authApiService: AuthApiService(),
      authSessionService: _sessionService,
    );
    final response = await apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/reports',
      body: body,
    );
    final payload = ApiClient.decodeMap(response.response.body);
    if (response.response.statusCode < 200 ||
        response.response.statusCode >= 300) {
      throw ReportServiceException(
        ApiClient.errorMessageForStatus(
          response.response.statusCode,
          payload,
          fallback: 'Could not submit report.',
        ),
      );
    }
    final data = payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final submission = ReportSubmission(
      id: (data['id'] as Object?)?.toString() ??
          'report-${DateTime.now().microsecondsSinceEpoch}',
      itemType: itemType,
      itemId: cleanedItemId,
      reason: reason,
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _submissions.insert(0, submission);

    return submission;
  }
}

class ReportServiceException implements Exception {
  const ReportServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
