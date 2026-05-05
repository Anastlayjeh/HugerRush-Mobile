import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/demo_app_models.dart';
import '../services/demo_app_repository.dart';
import '../services/moderation_support_models.dart';
import '../services/post_share_service.dart';
import 'login_screen.dart';
import '../services/restaurant_menu_api_service.dart';
import '../services/restaurant_profile_api_service.dart';
import 'app_support_screens.dart';

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

