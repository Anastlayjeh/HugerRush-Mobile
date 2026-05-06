import 'package:flutter_application_1/models/customer_video_feed_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CustomerVideoFeedItem prefers HLS playback URLs', () {
    final item = CustomerVideoFeedItem.fromJson(<String, dynamic>{
      'id': 12,
      'title': 'Smash Burger',
      'media_url': 'https://example.com/video.mp4',
      'playback_url': 'https://example.com/video.m3u8',
      'stream_ready': true,
      'status': 'published',
      'moderation_status': 'approved',
    });

    expect(item.playbackUrl, 'https://example.com/video.m3u8');
    expect(item.isApprovedForFeed, isTrue);
  });

  test('CustomerVideoFeedItem rejects draft or unapproved videos', () {
    final item = CustomerVideoFeedItem.fromJson(<String, dynamic>{
      'id': 13,
      'title': 'Draft clip',
      'stream_hls_url': 'https://example.com/draft.m3u8',
      'stream_ready': true,
      'status': 'draft',
      'moderation_status': 'approved',
    });

    expect(item.isApprovedForFeed, isFalse);
  });
}
