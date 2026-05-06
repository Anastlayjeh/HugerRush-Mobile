import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/auth_session.dart';
import '../models/customer_video_feed_models.dart';
import '../models/demo_app_models.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_service.dart';
import '../services/authenticated_api_client.dart';
import '../services/conversation_api_service.dart';
import '../services/customer_video_feed_api_service.dart';
import '../services/demo_app_repository.dart';
import '../services/moderation_support_models.dart';
import '../services/order_api_service.dart';
import '../services/post_share_service.dart';
import '../services/push_notification_service.dart';
import '../services/restaurant_menu_api_service.dart';
import '../services/restaurant_owner_api_service.dart';
import '../services/restaurant_profile_api_service.dart';
import 'app_support_screens.dart';
import 'login_screen.dart';

part 'restaurant/restaurant_feed_screen.dart';
part 'restaurant/restaurant_dashboard_screen.dart';
part 'restaurant/restaurant_messages_screen.dart';
part 'restaurant/restaurant_menu_screen.dart';
part 'restaurant/restaurant_profile_screen.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

String _formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) {
    return 'Now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h';
  }
  return '${difference.inDays}d';
}

String _feedCreatorLabel(String restaurantName) {
  final label = restaurantName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .join(' ');
  return (label.isEmpty ? 'HR' : label).toUpperCase();
}

String _feedHandleFromName(String value) {
  final cleaned = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '',
  );
  return cleaned.isEmpty ? 'restaurant' : cleaned;
}

String _feedTagFromName(String value) {
  final cleaned = _feedHandleFromName(value);
  return cleaned == 'restaurant' ? '#food' : '#$cleaned';
}
