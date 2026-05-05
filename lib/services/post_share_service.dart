import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class PostShareResult {
  const PostShareResult({
    required this.success,
    this.copiedToClipboard = false,
    this.errorMessage,
    this.link = '',
  });

  final bool success;
  final bool copiedToClipboard;
  final String? errorMessage;
  final String link;
}

class PostShareService {
  PostShareService._();

  static final PostShareService instance = PostShareService._();

  String buildShareLink({
    required String postId,
    String creatorHandle = '',
  }) {
    final cleanedPostId = postId.trim().isEmpty ? 'post' : postId.trim();
    final normalizedHandle = creatorHandle
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // TODO(api): Replace this placeholder link with backend-generated share links.
    if (normalizedHandle.isEmpty) {
      return 'https://hungerrush.app/post/$cleanedPostId';
    }
    return 'https://hungerrush.app/post/$cleanedPostId?by=$normalizedHandle';
  }

  Future<PostShareResult> sharePost({
    required String postId,
    required String title,
    required String caption,
    String creatorHandle = '',
  }) async {
    final link = buildShareLink(postId: postId, creatorHandle: creatorHandle);
    final cleanedTitle = title.trim().isEmpty ? 'HungerRush' : title.trim();
    final cleanedCaption = caption.trim();
    final text = cleanedCaption.isEmpty
        ? '$cleanedTitle\n$link'
        : '$cleanedTitle\n$cleanedCaption\n$link';

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: cleanedTitle),
      );
      return PostShareResult(success: true, link: link);
    } catch (_) {
      if (!kIsWeb) {
        return PostShareResult(
          success: false,
          link: link,
          errorMessage:
              'Unable to open the share options right now. Please try again.',
        );
      }
      try {
        await Clipboard.setData(ClipboardData(text: link));
        return PostShareResult(success: true, copiedToClipboard: true, link: link);
      } catch (_) {
        return PostShareResult(
          success: false,
          link: link,
          errorMessage: 'Unable to share or copy the link on this device.',
        );
      }
    }
  }
}
