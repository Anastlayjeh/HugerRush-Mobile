import 'dart:async';

import 'moderation_support_models.dart';

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

    await Future<void>.delayed(const Duration(milliseconds: 500));

    final submission = ReportSubmission(
      id: 'report-${DateTime.now().microsecondsSinceEpoch}',
      itemType: itemType,
      itemId: cleanedItemId,
      reason: reason,
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _submissions.insert(0, submission);

    // TODO(api): Replace this mock insertion with a backend moderation endpoint.
    return submission;
  }
}

class ReportServiceException implements Exception {
  const ReportServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
