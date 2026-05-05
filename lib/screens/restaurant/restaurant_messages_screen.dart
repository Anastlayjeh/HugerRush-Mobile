part of '../restaurant_feed_screen.dart';

class _MessagesSection extends StatefulWidget {
  const _MessagesSection({required this.metrics, required this.restaurantName});

  final _ResponsiveMetrics metrics;
  final String restaurantName;

  @override
  State<_MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<_MessagesSection> {
  final _repository = DemoAppRepository.instance;

  List<DemoConversationThread> _threads = const <DemoConversationThread>[];
  MessageFilterType _selectedFilter = MessageFilterType.all;
  String? _selectedCustomerName;
  bool _needsReplyOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final threads = await _repository.getThreads();
    if (!mounted) {
      return;
    }
    setState(() {
      _threads = threads;
      _isLoading = false;
    });
  }

  List<DemoConversationThread> get _visibleThreads {
    Iterable<DemoConversationThread> items = _threads;
    switch (_selectedFilter) {
      case MessageFilterType.all:
        break;
      case MessageFilterType.unread:
        items = items.where((thread) => thread.unreadCount > 0);
        break;
      case MessageFilterType.orders:
        items = items.where((thread) => thread.type == MessageThreadType.order);
        break;
      case MessageFilterType.offers:
        items = items.where((thread) => thread.type == MessageThreadType.offer);
        break;
    }
    if (_needsReplyOnly) {
      items = items.where((thread) => thread.needsReply);
    }
    if (_selectedCustomerName != null) {
      items = items.where(
        (thread) => thread.customerName == _selectedCustomerName,
      );
    }
    return items.toList();
  }

  void _selectFilter(MessageFilterType filter) {
    setState(() => _selectedFilter = filter);
  }

  void _toggleNeedsReplyOnly() {
    setState(() => _needsReplyOnly = !_needsReplyOnly);
  }

  void _selectCustomer(String? customerName) {
    setState(() {
      _selectedCustomerName = _selectedCustomerName == customerName
          ? null
          : customerName;
    });
  }

  Future<void> _openConversation(
    DemoConversationThread thread, {
    bool openComposer = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          threadId: thread.id,
          restaurantName: widget.restaurantName,
          openComposerOnStart: openComposer,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadThreads();
  }

  @override
  Widget build(BuildContext context) {
    final unreadThreads = _threads.where((item) => item.unreadCount > 0).length;
    final needsReplyThreads = _threads.where((item) => item.needsReply).length;
    final priorityThreads = _threads.where((item) => item.priority).toList();
    final visibleThreads = _visibleThreads;

    return RefreshIndicator(
      color: const Color(0xFFFF7E4D),
      onRefresh: _loadThreads,
      child: _isLoading
          ? ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                _MessagesHeaderCard(
                  metrics: widget.metrics,
                  restaurantName: widget.restaurantName,
                  unreadThreads: unreadThreads,
                  needsReplyThreads: needsReplyThreads,
                  needsReplySelected: _needsReplyOnly,
                  onSelectUnread: () => _selectFilter(MessageFilterType.unread),
                  onToggleNeedsReply: _toggleNeedsReplyOnly,
                ),
                SizedBox(
                  height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                ),
                _MessagesFilterRow(
                  metrics: widget.metrics,
                  selectedFilter: _selectedFilter,
                  onSelected: _selectFilter,
                ),
                if (priorityThreads.isNotEmpty) ...[
                  SizedBox(
                    height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                  ),
                  _PriorityInboxRow(
                    metrics: widget.metrics,
                    items: priorityThreads,
                    selectedCustomerName: _selectedCustomerName,
                    onSelectedCustomer: _selectCustomer,
                  ),
                ],
                SizedBox(
                  height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                ),
                if (visibleThreads.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1ED),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4D8CD)),
                    ),
                    child: const Text(
                      'No conversations match the current filters.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...List.generate(visibleThreads.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleThreads.length - 1
                            ? _clampDouble(6 * widget.metrics.scale, 4, 6)
                            : _clampDouble(10 * widget.metrics.scale, 8, 10),
                      ),
                      child: _MessageThreadCard(
                        metrics: widget.metrics,
                        thread: visibleThreads[index],
                        onOpenThread: () =>
                            _openConversation(visibleThreads[index]),
                        onReply: () => _openConversation(
                          visibleThreads[index],
                          openComposer: true,
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _MessagesHeaderCard extends StatelessWidget {
  const _MessagesHeaderCard({
    required this.metrics,
    required this.restaurantName,
    required this.unreadThreads,
    required this.needsReplyThreads,
    required this.needsReplySelected,
    required this.onSelectUnread,
    required this.onToggleNeedsReply,
  });

  final _ResponsiveMetrics metrics;
  final String restaurantName;
  final int unreadThreads;
  final int needsReplyThreads;
  final bool needsReplySelected;
  final VoidCallback onSelectUnread;
  final VoidCallback onToggleNeedsReply;

  @override
  Widget build(BuildContext context) {
    final titleSize = _clampDouble(32 * metrics.scale, 22, 32) * 0.56;
    final subtitleSize = _clampDouble(15 * metrics.scale, 11, 15);
    final labelSize = _clampDouble(12 * metrics.scale, 9, 12);
    final valueSize = _clampDouble(20 * metrics.scale, 14, 20);

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
                      'Messages',
                      style: TextStyle(
                        color: const Color(0xFF1F1B19),
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                    Text(
                      'Stay on top of customer replies for $restaurantName',
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
                width: _clampDouble(42 * metrics.scale, 36, 42),
                height: _clampDouble(42 * metrics.scale, 36, 42),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD9CC)),
                ),
                child: Icon(
                  Icons.mark_chat_unread_rounded,
                  color: const Color(0xFFFF7E4D),
                  size: _clampDouble(22 * metrics.scale, 18, 22),
                ),
              ),
            ],
          ),
          SizedBox(height: _clampDouble(12 * metrics.scale, 8, 12)),
          Row(
            children: [
              Expanded(
                child: _MessageHeaderStat(
                  metrics: metrics,
                  icon: Icons.mark_chat_unread_rounded,
                  iconColor: const Color(0xFFFF7E4D),
                  iconBackground: const Color(0xFFFFEFE8),
                  label: 'Unread',
                  value: '$unreadThreads threads',
                  labelSize: labelSize,
                  valueSize: valueSize,
                  onTap: onSelectUnread,
                ),
              ),
              SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
              Expanded(
                child: _MessageHeaderStat(
                  metrics: metrics,
                  icon: Icons.reply_rounded,
                  iconColor: const Color(0xFF2E9B57),
                  iconBackground: const Color(0xFFE1F5E8),
                  label: 'Needs Reply',
                  value: '$needsReplyThreads now',
                  labelSize: labelSize,
                  valueSize: valueSize,
                  onTap: onToggleNeedsReply,
                  selected: needsReplySelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageHeaderStat extends StatelessWidget {
  const _MessageHeaderStat({
    required this.metrics,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueSize,
    required this.onTap,
    this.selected = false,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final double labelSize;
  final double valueSize;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(10 * metrics.scale, 8, 10),
          vertical: _clampDouble(9 * metrics.scale, 7, 9),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : const Color(0xFFF8EFE8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFD7C8) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: _clampDouble(32 * metrics.scale, 26, 32),
              height: _clampDouble(32 * metrics.scale, 26, 32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackground,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: _clampDouble(17 * metrics.scale, 13, 17),
              ),
            ),
            SizedBox(width: _clampDouble(8 * metrics.scale, 6, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8D7E73),
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: _clampDouble(2 * metrics.scale, 1, 2)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF2A231E),
                      fontSize: valueSize * 0.72,
                      fontWeight: FontWeight.w800,
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

class _MessagesFilterRow extends StatelessWidget {
  const _MessagesFilterRow({
    required this.metrics,
    required this.selectedFilter,
    required this.onSelected,
  });

  final _ResponsiveMetrics metrics;
  final MessageFilterType selectedFilter;
  final ValueChanged<MessageFilterType> onSelected;

  static const _filters = [
    (icon: Icons.all_inbox_rounded, label: 'All', type: MessageFilterType.all),
    (
      icon: Icons.mark_chat_unread_rounded,
      label: 'Unread',
      type: MessageFilterType.unread,
    ),
    (
      icon: Icons.receipt_long_rounded,
      label: 'Orders',
      type: MessageFilterType.orders,
    ),
    (
      icon: Icons.local_offer_outlined,
      label: 'Offers',
      type: MessageFilterType.offers,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final item = _filters[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == _filters.length - 1
                  ? 0
                  : _clampDouble(8 * metrics.scale, 6, 8),
            ),
            child: _MessageFilterChip(
              metrics: metrics,
              icon: item.icon,
              label: item.label,
              selected: selectedFilter == item.type,
              onTap: () => onSelected(item.type),
            ),
          );
        }),
      ),
    );
  }
}

class _MessageFilterChip extends StatelessWidget {
  const _MessageFilterChip({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFF7E4D) : const Color(0xFF89786D);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(12 * metrics.scale, 10, 12),
          vertical: _clampDouble(8 * metrics.scale, 6, 8),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : const Color(0xFFF3ECE5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFFFD7C8) : const Color(0xFFE2D5CA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: _clampDouble(17 * metrics.scale, 14, 17),
            ),
            SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityInboxRow extends StatelessWidget {
  const _PriorityInboxRow({
    required this.metrics,
    required this.items,
    required this.selectedCustomerName,
    required this.onSelectedCustomer,
  });

  final _ResponsiveMetrics metrics;
  final List<DemoConversationThread> items;
  final String? selectedCustomerName;
  final ValueChanged<String?> onSelectedCustomer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Inbox',
          style: TextStyle(
            color: const Color(0xFF1F1B19),
            fontSize: _clampDouble(21 * metrics.scale, 15, 21),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: _clampDouble(8 * metrics.scale, 6, 8)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1
                      ? 0
                      : _clampDouble(8 * metrics.scale, 6, 8),
                ),
                child: _PriorityThreadChip(
                  metrics: metrics,
                  item: item,
                  selected: selectedCustomerName == item.customerName,
                  onTap: () => onSelectedCustomer(item.customerName),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PriorityThreadChip extends StatelessWidget {
  const _PriorityThreadChip({
    required this.metrics,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final DemoConversationThread item;
  final bool selected;
  final VoidCallback onTap;

  static String _initials(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'HR';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _clampDouble(10 * metrics.scale, 8, 10),
          vertical: _clampDouble(8 * metrics.scale, 6, 8),
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE8) : const Color(0xFFF3F0EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFD7C8) : const Color(0xFFE3D7CC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _clampDouble(30 * metrics.scale, 24, 30),
                  height: _clampDouble(30 * metrics.scale, 24, 30),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFE2D6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(item.customerName),
                    style: TextStyle(
                      color: const Color(0xFF9A3F1F),
                      fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (item.online)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: _clampDouble(10 * metrics.scale, 8, 10),
                      height: _clampDouble(10 * metrics.scale, 8, 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF24A75A),
                        border: Border.all(
                          color: const Color(0xFFF3F0EC),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: _clampDouble(7 * metrics.scale, 5, 7)),
            Text(
              item.customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF2A231E),
                fontSize: _clampDouble(12 * metrics.scale, 10, 12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageThreadCard extends StatelessWidget {
  const _MessageThreadCard({
    required this.metrics,
    required this.thread,
    required this.onOpenThread,
    required this.onReply,
  });

  final _ResponsiveMetrics metrics;
  final DemoConversationThread thread;
  final VoidCallback onOpenThread;
  final VoidCallback onReply;

  static String _initials(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'HR';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;
    final highlightColor = thread.priority
        ? const Color(0xFFFFE1D4)
        : const Color(0xFFE4D8CD);

    return InkWell(
      onTap: onOpenThread,
      borderRadius: BorderRadius.circular(
        _clampDouble(20 * metrics.scale, 16, 20),
      ),
      child: Container(
        padding: EdgeInsets.all(_clampDouble(12 * metrics.scale, 10, 12)),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1ED),
          borderRadius: BorderRadius.circular(
            _clampDouble(20 * metrics.scale, 16, 20),
          ),
          border: Border.all(color: highlightColor),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: _clampDouble(44 * metrics.scale, 36, 44),
                      height: _clampDouble(44 * metrics.scale, 36, 44),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE2D6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(thread.customerName),
                        style: TextStyle(
                          color: const Color(0xFF9A3F1F),
                          fontSize: _clampDouble(16 * metrics.scale, 13, 16),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (thread.online)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: _clampDouble(12 * metrics.scale, 10, 12),
                          height: _clampDouble(12 * metrics.scale, 10, 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF24A75A),
                            border: Border.all(
                              color: const Color(0xFFF4F1ED),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: _clampDouble(10 * metrics.scale, 8, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1F1B19),
                                fontSize: _clampDouble(
                                  18 * metrics.scale,
                                  14,
                                  18,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _clampDouble(6 * metrics.scale, 4, 6),
                          ),
                          Text(
                            thread.timeLabel,
                            style: TextStyle(
                              color: const Color(0xFF8C7D71),
                              fontSize: _clampDouble(12 * metrics.scale, 9, 12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasUnread) ...[
                            SizedBox(
                              width: _clampDouble(6 * metrics.scale, 4, 6),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _clampDouble(
                                  7 * metrics.scale,
                                  5,
                                  7,
                                ),
                                vertical: _clampDouble(3 * metrics.scale, 2, 3),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7E4D),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${thread.unreadCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _clampDouble(
                                    10 * metrics.scale,
                                    8,
                                    10,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: _clampDouble(4 * metrics.scale, 3, 4)),
                      Text(
                        thread.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF8A7B6F),
                          fontSize: _clampDouble(13 * metrics.scale, 10, 13),
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: _clampDouble(9 * metrics.scale, 7, 9)),
            Row(
              children: [
                _MessageMetaPill(
                  metrics: metrics,
                  icon: Icons.receipt_long_rounded,
                  label: thread.orderLabel,
                ),
                SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                _MessageMetaPill(
                  metrics: metrics,
                  icon: Icons.local_shipping_outlined,
                  label: thread.channelLabel,
                ),
                if (thread.priority) ...[
                  SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                  _MessageMetaPill(
                    metrics: metrics,
                    icon: Icons.priority_high_rounded,
                    label: 'Priority',
                    highlighted: true,
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7E4D),
                    minimumSize: Size(
                      _clampDouble(84 * metrics.scale, 70, 84),
                      _clampDouble(34 * metrics.scale, 30, 34),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: _clampDouble(10 * metrics.scale, 8, 10),
                    ),
                    backgroundColor: const Color(0xFFFFEFE8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.reply_rounded,
                    size: _clampDouble(16 * metrics.scale, 13, 16),
                  ),
                  label: Text(
                    'Reply',
                    style: TextStyle(
                      fontSize: _clampDouble(12 * metrics.scale, 10, 12),
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

class _MessageMetaPill extends StatelessWidget {
  const _MessageMetaPill({
    required this.metrics,
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final _ResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? const Color(0xFFC1502B)
        : const Color(0xFF7D6C60);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _clampDouble(7 * metrics.scale, 5, 7),
        vertical: _clampDouble(4 * metrics.scale, 3, 4),
      ),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFE8DD) : const Color(0xFFEDE5DE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: _clampDouble(13 * metrics.scale, 10, 13),
          ),
          SizedBox(width: _clampDouble(4 * metrics.scale, 3, 4)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: _clampDouble(11 * metrics.scale, 9, 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

