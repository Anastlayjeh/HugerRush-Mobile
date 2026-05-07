import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/services/customer_restaurant_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('media URLs are resolved against the site origin', () {
    expect(
      ApiConfig.resolveMediaUrl('/storage/videos/clip.mp4'),
      'https://hungerrush.site/storage/videos/clip.mp4',
    );
    expect(
      ApiConfig.resolveMediaUrl('/v1/customer/videos/12/playback'),
      'https://hungerrush.site/api/v1/customer/videos/12/playback',
    );
    expect(
      ApiConfig.resolveMediaUrl('http://hungerrush.site/storage/clip.mp4'),
      'https://hungerrush.site/storage/clip.mp4',
    );
  });

  test('restaurant video exposes fallback playback URLs', () {
    final item = CustomerRestaurantVideoItem.fromJson(<String, dynamic>{
      'id': 9,
      'title': 'Kebab',
      'stream_hls_url': '/storage/hls/kebab.m3u8',
      'media_url': '/storage/videos/kebab.mp4',
      'stream_ready': true,
    });

    expect(item.resolvedPlaybackUrl, endsWith('/storage/hls/kebab.m3u8'));
    expect(
      item.playbackUrls,
      containsAll(<String>[
        'https://hungerrush.site/storage/hls/kebab.m3u8',
        'https://hungerrush.site/storage/videos/kebab.mp4',
      ]),
    );
  });

  test('restaurant video prefers direct media while stream is not ready', () {
    final item = CustomerRestaurantVideoItem.fromJson(<String, dynamic>{
      'id': 10,
      'title': 'Shawarma',
      'stream_hls_url': '/storage/hls/shawarma.m3u8',
      'media_url': '/storage/videos/shawarma.mp4',
      'stream_ready': false,
    });

    expect(item.resolvedPlaybackUrl, endsWith('/storage/videos/shawarma.mp4'));
    expect(item.playbackUrls.last, endsWith('/storage/hls/shawarma.m3u8'));
  });
}
