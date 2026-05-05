import 'dart:async';

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

    await Future<void>.delayed(const Duration(milliseconds: 520));

    final request = SupportRequest(
      id: 'support-${DateTime.now().microsecondsSinceEpoch}',
      audience: audience,
      topic: cleanedTopic,
      details: cleanedDetails,
      createdAt: DateTime.now(),
    );
    _requests.insert(0, request);

    // TODO(api): Replace this mock insertion with backend support ticket endpoint.
    return request;
  }
}

class SupportRequestException implements Exception {
  const SupportRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
