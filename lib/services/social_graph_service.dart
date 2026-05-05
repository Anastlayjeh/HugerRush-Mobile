import 'dart:async';

import 'moderation_support_models.dart';

class _FriendshipRecord {
  const _FriendshipRecord({
    required this.status,
    required this.updatedAt,
  });

  final FriendshipStatus status;
  final DateTime updatedAt;

  _FriendshipRecord copyWith({
    FriendshipStatus? status,
    DateTime? updatedAt,
  }) {
    return _FriendshipRecord(
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SocialGraphService {
  SocialGraphService._();

  static final SocialGraphService instance = SocialGraphService._();

  static const Duration _mockAutoAcceptDelay = Duration(seconds: 3);

  final Map<String, Set<String>> _followingByViewer = <String, Set<String>>{};
  final Map<String, _FriendshipRecord> _friendshipByPair =
      <String, _FriendshipRecord>{};

  String _normalizeId(String value) {
    final cleaned = value.trim().toLowerCase();
    return cleaned.isEmpty ? 'unknown' : cleaned;
  }

  String _pairKey(String first, String second) {
    final normalizedFirst = _normalizeId(first);
    final normalizedSecond = _normalizeId(second);
    if (normalizedFirst.compareTo(normalizedSecond) <= 0) {
      return '$normalizedFirst::$normalizedSecond';
    }
    return '$normalizedSecond::$normalizedFirst';
  }

  FriendshipStatus getFriendshipStatus({
    required String viewerId,
    required String targetId,
  }) {
    final key = _pairKey(viewerId, targetId);
    final record = _friendshipByPair[key];
    if (record == null) {
      return FriendshipStatus.none;
    }

    if (record.status == FriendshipStatus.requestSent) {
      final elapsed = DateTime.now().difference(record.updatedAt);
      if (elapsed >= _mockAutoAcceptDelay) {
        _friendshipByPair[key] = record.copyWith(
          status: FriendshipStatus.friends,
          updatedAt: DateTime.now(),
        );
        return FriendshipStatus.friends;
      }
    }
    return record.status;
  }

  Future<FriendshipStatus> sendFriendRequest({
    required String viewerId,
    required String targetId,
  }) async {
    final key = _pairKey(viewerId, targetId);
    _friendshipByPair[key] = _FriendshipRecord(
      status: FriendshipStatus.requestSent,
      updatedAt: DateTime.now(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 240));

    // TODO(api): Replace mock state with backend friend-request endpoint.
    return FriendshipStatus.requestSent;
  }

  Future<FriendshipStatus> refreshFriendshipStatus({
    required String viewerId,
    required String targetId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return getFriendshipStatus(viewerId: viewerId, targetId: targetId);
  }

  Future<FriendshipStatus> removeFriend({
    required String viewerId,
    required String targetId,
  }) async {
    final key = _pairKey(viewerId, targetId);
    _friendshipByPair.remove(key);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // TODO(api): Replace mock state with backend remove-friend endpoint.
    return FriendshipStatus.none;
  }

  bool isFollowingCustomer({
    required String viewerId,
    required String targetId,
  }) {
    final viewerKey = _normalizeId(viewerId);
    final targetKey = _normalizeId(targetId);
    final followed = _followingByViewer[viewerKey];
    return followed != null && followed.contains(targetKey);
  }

  Future<bool> toggleFollowCustomer({
    required String viewerId,
    required String targetId,
  }) async {
    final viewerKey = _normalizeId(viewerId);
    final targetKey = _normalizeId(targetId);
    final followed =
        _followingByViewer.putIfAbsent(viewerKey, () => <String>{});
    final isFollowing = followed.contains(targetKey);
    if (isFollowing) {
      followed.remove(targetKey);
    } else {
      followed.add(targetKey);
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));

    // TODO(api): Replace mock state with backend follow/unfollow endpoint.
    return !isFollowing;
  }
}
