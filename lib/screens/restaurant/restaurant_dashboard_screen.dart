part of '../restaurant_feed_screen.dart';

class _CreatePostComposerResult {
  const _CreatePostComposerResult({
    required this.caption,
    required this.hashtags,
  });

  final String caption;
  final String hashtags;
}

class _CreatePostComposerScreen extends StatefulWidget {
  const _CreatePostComposerScreen({required this.selectedVideoName});

  final String selectedVideoName;

  @override
  State<_CreatePostComposerScreen> createState() =>
      _CreatePostComposerScreenState();
}

class _CreatePostComposerScreenState extends State<_CreatePostComposerScreen> {
  late final TextEditingController _captionController;
  late final TextEditingController _hashtagsController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _hashtagsController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  String _normalizeHashtags(String rawValue) {
    final normalized = <String>[];
    final seen = <String>{};
    final parts = rawValue.split(RegExp(r'[\s,]+'));
    for (final part in parts) {
      final cleaned = part.trim().replaceAll(RegExp(r'[^A-Za-z0-9_#]'), '');
      if (cleaned.isEmpty) {
        continue;
      }
      final withoutPrefix = cleaned.replaceAll('#', '');
      if (withoutPrefix.isEmpty) {
        continue;
      }
      final tag = '#$withoutPrefix';
      final key = tag.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      normalized.add(tag);
    }
    return normalized.join(' ');
  }

  void _submit() {
    final caption = _captionController.text.trim();
    final hashtags = _normalizeHashtags(_hashtagsController.text);
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a caption.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (hashtags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one hashtag.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(_CreatePostComposerResult(caption: caption, hashtags: hashtags));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EFE8),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1B19),
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedVideoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8D7E73),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Caption',
                    style: TextStyle(
                      color: Color(0xFF1F1B19),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a short caption for your post...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7E4D),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hashtags',
                    style: TextStyle(
                      color: Color(0xFF1F1B19),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hashtagsController,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '#pizza #burger #fresh',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6D9CD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7E4D),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7E4D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.metrics,
    required this.restaurantName,
    required this.isRefreshing,
    required this.ordersCompletedToday,
    required this.revenueToday,
    required this.ordersInProgress,
    required this.selectedVideoName,
    required this.selectedVideoSizeBytes,
    required this.isPickingVideo,
    required this.isCreatingPost,
    required this.onSelectVideo,
    required this.onClearVideo,
    required this.onRefresh,
    required this.onCreatePost,
    required this.onOpenCompletedOrders,
    required this.onOpenRevenueAnalytics,
    required this.onOpenActiveOrders,
    required this.onOpenOrderManagement,
    required this.onOpenOrderDetails,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final bool isRefreshing;
  final int ordersCompletedToday;
  final double revenueToday;
  final int ordersInProgress;
  final String? selectedVideoName;
  final int? selectedVideoSizeBytes;
  final bool isPickingVideo;
  final bool isCreatingPost;
  final Future<void> Function() onSelectVideo;
  final VoidCallback onClearVideo;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreatePost;
  final Future<void> Function() onOpenCompletedOrders;
  final Future<void> Function() onOpenRevenueAnalytics;
  final Future<void> Function() onOpenActiveOrders;
  final Future<void> Function() onOpenOrderManagement;
  final Future<void> Function(String orderId) onOpenOrderDetails;

  @override
  Widget build(BuildContext context) {
    final sectionGap = _clampDouble(12 * metrics.scale, 8, 12);

    return RefreshIndicator(
      color: const Color(0xFFFF7E4D),
      onRefresh: onRefresh,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _DashboardHeaderCard(
            metrics: metrics,
            restaurantName: restaurantName,
            isRefreshing: isRefreshing,
            onRefresh: onRefresh,
          ),
          SizedBox(height: sectionGap),
          _DashboardStatsPanel(
            metrics: metrics,
            ordersCompletedToday: ordersCompletedToday,
            revenueToday: revenueToday,
            ordersInProgress: ordersInProgress,
            onOpenCompletedOrders: onOpenCompletedOrders,
            onOpenRevenueAnalytics: onOpenRevenueAnalytics,
            onOpenActiveOrders: onOpenActiveOrders,
          ),
          SizedBox(height: sectionGap),
          _CreatePostPanel(
            metrics: metrics,
            selectedVideoName: selectedVideoName,
            selectedVideoSizeBytes: selectedVideoSizeBytes,
            isPickingVideo: isPickingVideo,
            isCreatingPost: isCreatingPost,
            onSelectVideo: onSelectVideo,
            onClearVideo: onClearVideo,
            onCreatePost: onCreatePost,
          ),
          SizedBox(height: sectionGap),
          _DashboardLiveOrdersPanel(
            metrics: metrics,
            ordersInProgress: ordersInProgress,
            onOpenOrderManagement: onOpenOrderManagement,
            onOpenOrderDetails: onOpenOrderDetails,
          ),
          SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
        ],
      ),
    );
  }
}

class _DashboardHeaderCard extends StatelessWidget {
  const _DashboardHeaderCard({
    required this.metrics,
    required this.restaurantName,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final titleSize = _clampDouble(32 * metrics.scale, 22, 32) * 0.56;
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(16 * metrics.scale, 12, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(24 * metrics.scale, 18, 24),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                    Text(
                      'Today at $restaurantName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8F7F73),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD9CC)),
                ),
                child: IconButton(
                  onPressed: isRefreshing ? null : () => onRefresh(),
                  icon: isRefreshing
                      ? SizedBox(
                          width: _clampDouble(18 * metrics.scale, 14, 18),
                          height: _clampDouble(18 * metrics.scale, 14, 18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF7E4D),
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: const Color(0xFFFF7E4D),
                          size: _clampDouble(22 * metrics.scale, 18, 22),
                        ),
                  tooltip: 'Refresh dashboard',
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(12 * metrics.scale, 10, 12),
              vertical: _clampDouble(9 * metrics.scale, 7, 9),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(18 * metrics.scale, 14, 18),
                ),
                SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                Expanded(
                  child: Text(
                    'Track daily flow and publish updates for your followers.',
                    style: TextStyle(
                      color: const Color(0xFF7D6D61),
                      fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatsPanel extends StatelessWidget {
  const _DashboardStatsPanel({
    required this.metrics,
    required this.ordersCompletedToday,
    required this.revenueToday,
    required this.ordersInProgress,
    required this.onOpenCompletedOrders,
    required this.onOpenRevenueAnalytics,
    required this.onOpenActiveOrders,
  });

  final _ResponsiveMetrics metrics;
  final int ordersCompletedToday;
  final double revenueToday;
  final int ordersInProgress;
  final Future<void> Function() onOpenCompletedOrders;
  final Future<void> Function() onOpenRevenueAnalytics;
  final Future<void> Function() onOpenActiveOrders;

  @override
  Widget build(BuildContext context) {
    final itemGap = _clampDouble(8 * metrics.scale, 6, 8);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashboardStatCard(
                metrics: metrics,
                icon: Icons.task_alt_rounded,
                label: 'Orders Completed Today',
                value: '$ordersCompletedToday',
                iconColor: const Color(0xFF2E9B57),
                iconBackgroundColor: const Color(0xFFE1F5E8),
                onTap: onOpenCompletedOrders,
              ),
            ),
            SizedBox(width: itemGap),
            Expanded(
              child: _DashboardStatCard(
                metrics: metrics,
                icon: Icons.payments_rounded,
                label: 'Revenue Today',
                value: _formatUsd(revenueToday),
                iconColor: const Color(0xFFFF7E4D),
                iconBackgroundColor: const Color(0xFFFFEFE8),
                onTap: onOpenRevenueAnalytics,
              ),
            ),
          ],
        ),
        SizedBox(height: itemGap),
        _DashboardStatCard(
          metrics: metrics,
          icon: Icons.timelapse_rounded,
          label: 'Orders In Progress',
          value: '$ordersInProgress',
          iconColor: const Color(0xFF43739C),
          iconBackgroundColor: const Color(0xFFE8EFF7),
          onTap: onOpenActiveOrders,
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(
        _clampDouble(18 * metrics.scale, 14, 18),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(12 * metrics.scale, 10, 12),
          vertical: _clampDouble(10 * metrics.scale, 8, 10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0EC),
          borderRadius: BorderRadius.circular(
            _clampDouble(18 * metrics.scale, 14, 18),
          ),
          border: Border.all(color: const Color(0xFFE5DACF)),
        ),
        child: Row(
          children: [
            Container(
              width: _clampDouble(34 * metrics.scale, 28, 34),
              height: _clampDouble(34 * metrics.scale, 28, 34),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: _clampDouble(18 * metrics.scale, 14, 18),
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1F1B19),
                      fontSize: _clampDouble(18 * metrics.scale, 13, 18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8D7E73),
                      fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostPanel extends StatelessWidget {
  const _CreatePostPanel({
    required this.metrics,
    required this.selectedVideoName,
    required this.selectedVideoSizeBytes,
    required this.isPickingVideo,
    required this.isCreatingPost,
    required this.onSelectVideo,
    required this.onClearVideo,
    required this.onCreatePost,
  });

  final _ResponsiveMetrics metrics;
  final String? selectedVideoName;
  final int? selectedVideoSizeBytes;
  final bool isPickingVideo;
  final bool isCreatingPost;
  final Future<void> Function() onSelectVideo;
  final VoidCallback onClearVideo;
  final Future<void> Function() onCreatePost;

  @override
  Widget build(BuildContext context) {
    final hasSelectedVideo =
        selectedVideoName != null && selectedVideoName!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 11, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(
          _clampDouble(22 * metrics.scale, 16, 22),
        ),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: _clampDouble(34 * metrics.scale, 30, 34),
                height: _clampDouble(34 * metrics.scale, 30, 34),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEFE8),
                ),
                child: Icon(
                  Icons.video_call_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(20 * metrics.scale, 16, 20),
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Post',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Upload a short promo or kitchen update video.',
                      style: TextStyle(
                        color: const Color(0xFF8D7E73),
                        fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _clampDouble(12 * metrics.scale, 10, 12),
              vertical: _clampDouble(10 * metrics.scale, 8, 10),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0D4C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_file_rounded,
                      color: const Color(0xFFFF7E4D),
                      size: _clampDouble(18 * metrics.scale, 14, 18),
                    ),
                    SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
                    Expanded(
                      child: Text(
                        hasSelectedVideo
                            ? selectedVideoName!
                            : 'No video selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasSelectedVideo
                              ? const Color(0xFF2A231E)
                              : const Color(0xFF9B8C81),
                          fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasSelectedVideo)
                      IconButton(
                        onPressed: isPickingVideo ? null : onClearVideo,
                        icon: Icon(
                          Icons.close_rounded,
                          color: const Color(0xFF9B8C81),
                          size: _clampDouble(18 * metrics.scale, 14, 18),
                        ),
                        tooltip: 'Remove video',
                      ),
                  ],
                ),
                if (hasSelectedVideo && selectedVideoSizeBytes != null)
                  Padding(
                    padding: EdgeInsets.only(
                      left: _clampDouble(26 * metrics.scale, 20, 26),
                    ),
                    child: Text(
                      _formatFileSize(selectedVideoSizeBytes!),
                      style: TextStyle(
                        color: const Color(0xFF8D7E73),
                        fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPickingVideo ? null : () => onSelectVideo(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7E4D),
                    side: const BorderSide(color: Color(0xFFFFC8B4)),
                    padding: EdgeInsets.symmetric(
                      vertical: _clampDouble(12 * metrics.scale, 10, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isPickingVideo
                      ? SizedBox(
                          width: _clampDouble(16 * metrics.scale, 13, 16),
                          height: _clampDouble(16 * metrics.scale, 13, 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF7E4D),
                          ),
                        )
                      : Icon(
                          Icons.video_library_rounded,
                          size: _clampDouble(18 * metrics.scale, 14, 18),
                        ),
                  label: Text(
                    isPickingVideo ? 'Picking...' : 'Upload Video',
                    style: TextStyle(
                      fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      hasSelectedVideo && !isPickingVideo && !isCreatingPost
                      ? onCreatePost
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7E4D),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE8DBD1),
                    disabledForegroundColor: const Color(0xFFA69488),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      vertical: _clampDouble(12 * metrics.scale, 10, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isCreatingPost
                      ? SizedBox(
                          width: _clampDouble(16 * metrics.scale, 13, 16),
                          height: _clampDouble(16 * metrics.scale, 13, 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.cloud_upload_rounded,
                          size: _clampDouble(18 * metrics.scale, 14, 18),
                        ),
                  label: Text(
                    isCreatingPost ? 'Creating...' : 'Create Post',
                    style: TextStyle(
                      fontSize: _clampDouble(14 * metrics.scale, 11, 14),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardLiveOrdersPanel extends StatelessWidget {
  const _DashboardLiveOrdersPanel({
    required this.metrics,
    required this.ordersInProgress,
    required this.onOpenOrderManagement,
    required this.onOpenOrderDetails,
  });

  final _ResponsiveMetrics metrics;
  final int ordersInProgress;
  final Future<void> Function() onOpenOrderManagement;
  final Future<void> Function(String orderId) onOpenOrderDetails;

  static const List<_DashboardLiveOrderData> _sampleOrders = [
    _DashboardLiveOrderData(
      orderId: '#4735',
      customerName: 'Lina M.',
      itemSummary: '2x Pepperoni Feast, 1x Cola',
      etaLabel: 'ETA 14m',
      statusLabel: 'Cooking',
      highlighted: true,
    ),
    _DashboardLiveOrderData(
      orderId: '#4733',
      customerName: 'Rami A.',
      itemSummary: '1x Chicken Wrap, 1x Fries',
      etaLabel: 'ETA 8m',
      statusLabel: 'Packing',
      highlighted: false,
    ),
    _DashboardLiveOrderData(
      orderId: '#4730',
      customerName: 'Jad F.',
      itemSummary: '1x Family Box, 2x Garlic Dip',
      etaLabel: 'ETA 22m',
      statusLabel: 'Queued',
      highlighted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cardRadius = _clampDouble(22 * metrics.scale, 16, 22);
    final listGap = _clampDouble(8 * metrics.scale, 6, 8);
    final displayCount = _sampleOrders
        .take(ordersInProgress.clamp(1, _sampleOrders.length))
        .toList();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: _clampDouble(metrics.height * 0.24, 160, 230),
      ),
      padding: EdgeInsets.all(_clampDouble(14 * metrics.scale, 11, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: const Color(0xFFE5DACF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: _clampDouble(34 * metrics.scale, 30, 34),
                height: _clampDouble(34 * metrics.scale, 30, 34),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEFE8),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(20 * metrics.scale, 16, 20),
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Order Queue',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: _clampDouble(18 * metrics.scale, 14, 18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$ordersInProgress orders currently in progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF8D7E73),
                        fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _clampDouble(10 * metrics.scale, 8, 10),
                  vertical: _clampDouble(5 * metrics.scale, 4, 5),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: const Color(0xFF2E9B57),
                    fontSize: _clampDouble(10 * metrics.scale, 8, 10),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          ...List.generate(displayCount.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == displayCount.length - 1 ? 0 : listGap,
              ),
              child: _DashboardLiveOrderRow(
                metrics: metrics,
                data: displayCount[index],
                onTap: () => onOpenOrderDetails(displayCount[index].orderId),
              ),
            );
          }),
          SizedBox(height: _clampDouble(10 * metrics.scale, 8, 10)),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => onOpenOrderManagement(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7E4D),
                backgroundColor: const Color(0xFFFFEFE8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: _clampDouble(11 * metrics.scale, 9, 11),
                ),
              ),
              icon: Icon(
                Icons.receipt_long_rounded,
                size: _clampDouble(18 * metrics.scale, 14, 18),
              ),
              label: Text(
                'Open Order Management',
                style: TextStyle(
                  fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLiveOrderRow extends StatelessWidget {
  const _DashboardLiveOrderRow({
    required this.metrics,
    required this.data,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final _DashboardLiveOrderData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = data.highlighted
        ? const Color(0xFFB95533)
        : const Color(0xFF7D6C60);
    final statusBackground = data.highlighted
        ? const Color(0xFFFFE8DE)
        : const Color(0xFFEDE5DE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(10 * metrics.scale, 8, 10),
          vertical: _clampDouble(9 * metrics.scale, 7, 9),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EFE8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: data.highlighted
                ? const Color(0xFFFFD8C9)
                : const Color(0xFFE2D6CB),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data.orderId,
                        style: TextStyle(
                          color: const Color(0xFF1F1B19),
                          fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                      Flexible(
                        child: Text(
                          data.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF7E7064),
                            fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _clampDouble(3 * metrics.scale, 2, 3)),
                  Text(
                    data.itemSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8D7E73),
                      fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.etaLabel,
                  style: TextStyle(
                    color: const Color(0xFF2A231E),
                    fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _clampDouble(8 * metrics.scale, 6, 8),
                    vertical: _clampDouble(3 * metrics.scale, 2, 3),
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: _clampDouble(10 * metrics.scale, 8, 10),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLiveOrderData {
  const _DashboardLiveOrderData({
    required this.orderId,
    required this.customerName,
    required this.itemSummary,
    required this.etaLabel,
    required this.statusLabel,
    required this.highlighted,
  });

  final String orderId;
  final String customerName;
  final String itemSummary;
  final String etaLabel;
  final String statusLabel;
  final bool highlighted;
}

