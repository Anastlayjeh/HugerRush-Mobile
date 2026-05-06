import 'dart:async';

import 'auth_api_service.dart';
import 'auth_session_service.dart';
import 'authenticated_api_client.dart';
import 'api_client.dart';

enum SupportAudience {
  customer,
  restaurant,
}

class SupportRequest {
  const SupportRequest({
    required this.id,
    required this.audience,
    required this.topic,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final SupportAudience audience;
  final String topic;
  final String details;
  final DateTime createdAt;
}

class SupportRequestService {
  SupportRequestService._();

  static final SupportRequestService instance = SupportRequestService._();

  final List<SupportRequest> _requests = <SupportRequest>[];
  final AuthSessionService _sessionService = AuthSessionService();

  List<SupportRequest> get requests => List<SupportRequest>.from(_requests);

  Future<SupportRequest> submitRequest({
    required SupportAudience audience,
    required String topic,
    required String details,
  }) async {
    final cleanedTopic = topic.trim();
    final cleanedDetails = details.trim();
    if (cleanedTopic.isEmpty || cleanedDetails.isEmpty) {
      throw const SupportRequestException('Topic and details are required.');
    }

    final session = await _sessionService.readSession();
    if (session == null || session.token.trim().isEmpty) {
      throw const SupportRequestException('Please log in again.');
    }

    final apiClient = AuthenticatedApiClient(
      authApiService: AuthApiService(),
      authSessionService: _sessionService,
    );
    final response = await apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/support-requests',
      body: <String, dynamic>{
        'channel': audience == SupportAudience.restaurant
            ? 'restaurant_app'
            : 'customer_app',
        'subject': cleanedTopic,
        'message': cleanedDetails,
      },
    );
    final payload = ApiClient.decodeMap(response.response.body);
    if (response.response.statusCode < 200 ||
        response.response.statusCode >= 300) {
      throw SupportRequestException(
        ApiClient.errorMessageForStatus(
          response.response.statusCode,
          payload,
          fallback: 'Could not submit support request.',
        ),
      );
    }

    final data = payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final request = SupportRequest(
      id: (data['id'] as Object?)?.toString() ??
          'support-${DateTime.now().microsecondsSinceEpoch}',
      audience: audience,
      topic: cleanedTopic,
      details: cleanedDetails,
      createdAt: DateTime.now(),
    );
    _requests.insert(0, request);

    return request;
  }
}

class SupportRequestException implements Exception {
  const SupportRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
