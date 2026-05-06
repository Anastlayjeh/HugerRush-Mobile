part of '../user_home_screen.dart';

class _MessagesTabBody extends StatelessWidget {
  const _MessagesTabBody({
    required this.userName,
    required this.selectedBottomIndex,
    required this.onBottomNavSelected,
  });

  final String userName;
  final int selectedBottomIndex;
  final ValueChanged<int> onBottomNavSelected;

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final greetingName = trimmedName.isEmpty
        ? 'Explorer'
        : trimmedName.split(RegExp(r'\s+')).first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAreaPadding = MediaQuery.paddingOf(context);
        final safeHeight =
            constraints.maxHeight -
            safeAreaPadding.top -
            safeAreaPadding.bottom;
        final metrics = _ResponsiveMetrics.from(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight > 0 ? safeHeight : constraints.maxHeight,
          ),
        );
        final navBarBottomInset = safeAreaPadding.bottom;
        final navBarTotalHeight = metrics.navHeight + navBarBottomInset;
        return Stack(
          children: [
            Positioned.fill(
              bottom: navBarTotalHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    _clampDouble(metrics.topPadding + 6, 12, 20),
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Messages',
                        style: TextStyle(
                          color: const Color(0xFF231A16),
                          fontSize: _clampDouble(34 * metrics.scale, 26, 34),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      SizedBox(height: _clampDouble(6 * metrics.scale, 4, 6)),
                      Text(
                        'Track conversations and restaurant updates for $greetingName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7F6D61),
                          fontSize: _clampDouble(15 * metrics.scale, 12, 15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: _clampDouble(20 * metrics.scale, 16, 20),
                      ),
                      Expanded(
                        child: _CustomerMessagesSection(
                          metrics: metrics,
                          userName: userName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNavBar(
                metrics: metrics,
                selectedIndex: selectedBottomIndex,
                onSelected: onBottomNavSelected,
                fullWidth: true,
                bottomInset: navBarBottomInset,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerMessagesSection extends StatefulWidget {
  const _CustomerMessagesSection({
    required this.metrics,
    required this.userName,
  });

  final _ResponsiveMetrics metrics;
  final String userName;

  @override
  State<_CustomerMessagesSection> createState() =>
      _CustomerMessagesSectionState();
}

class _CustomerMessagesSectionState extends State<_CustomerMessagesSection> {
  final _authSessionService = AuthSessionService();
  late final ConversationApiService _conversationApiService;

  List<DemoConversationThread> _threads = const <DemoConversationThread>[];
  MessageFilterType _selectedFilter = MessageFilterType.all;
  String? _selectedThreadId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversationApiService = ConversationApiService(
      apiClient: AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
      ),
    );
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final session = await _authSessionService.readSession();
      if (session == null || session.token.trim().isEmpty) {
        throw const ConversationApiException(
          'Please log in again to load conversations.',
        );
      }
      final conversations = await _conversationApiService.fetchConversations(
        session: session,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _threads = conversations
            .map(_threadFromConversation)
            .toList(growable: false);
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _threads = const <DemoConversationThread>[];
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  String _counterpartyName(DemoConversationThread thread) {
    return thread.customerName;
  }

  DemoConversationThread _threadFromConversation(AppConversation conversation) {
    final latestAt =
        conversation.lastMessageAt ?? conversation.latestMessage?.createdAt;
    final isOrderThread = conversation.orderId.trim().isNotEmpty;
    return DemoConversationThread(
      id: conversation.id,
      customerName: conversation.restaurantName,
      lastMessage: conversation.previewText,
      timeLabel: latestAt == null ? 'Recent' : _formatRelativeTime(latestAt),
      orderLabel: isOrderThread ? '#${conversation.orderId}' : 'General',
      channelLabel: conversation.displaySubject,
      unreadCount: conversation.unreadCount,
      priority: conversation.unreadCount > 0,
      needsReply: conversation.unreadCount > 0,
      online: false,
      type: isOrderThread ? MessageThreadType.order : MessageThreadType.offer,
      messages: conversation.messages
          .map(
            (message) => DemoConversationMessage(
              id: message.id,
              senderName: message.senderName,
              body: message.body,
              sentAt: message.createdAt ?? DateTime.now(),
              fromRestaurant: message.fromRestaurant,
            ),
          )
          .toList(growable: false),
    );
  }

  String get _senderName {
    final cleaned = widget.userName.trim();
    if (cleaned.isEmpty) {
      return 'You';
    }
    return cleaned;
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
    if (_selectedThreadId != null) {
      items = items.where((thread) => thread.id == _selectedThreadId);
    }
    return items.toList();
  }

  void _selectFilter(MessageFilterType filter) {
    setState(() => _selectedFilter = filter);
  }

  void _selectThread(String threadId) {
    setState(() {
      _selectedThreadId = _selectedThreadId == threadId ? null : threadId;
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
          restaurantName: _senderName,
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
    final priorityThreads = _threads.where((item) => item.priority).toList();
    final visibleThreads = _visibleThreads;

    return RefreshIndicator(
      color: const Color(0xFFFF7E4D),
      onRefresh: _loadThreads,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 160),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7D3D34),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                _CustomerMessagesFilterRow(
                  metrics: widget.metrics,
                  selectedFilter: _selectedFilter,
                  onSelected: _selectFilter,
                ),
                if (priorityThreads.isNotEmpty) ...[
                  SizedBox(
                    height: _clampDouble(12 * widget.metrics.scale, 8, 12),
                  ),
                  _CustomerPriorityInboxRow(
                    metrics: widget.metrics,
                    items: priorityThreads,
                    selectedThreadId: _selectedThreadId,
                    counterpartyNameOf: _counterpartyName,
                    onSelectedThread: _selectThread,
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
                    final thread = visibleThreads[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleThreads.length - 1
                            ? _clampDouble(6 * widget.metrics.scale, 4, 6)
                            : _clampDouble(10 * widget.metrics.scale, 8, 10),
                      ),
                      child: _CustomerMessageThreadCard(
                        metrics: widget.metrics,
                        thread: thread,
                        counterpartyName: _counterpartyName(thread),
                        onOpenThread: () => _openConversation(thread),
                        onReply: () =>
                            _openConversation(thread, openComposer: true),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _CustomerMessagesFilterRow extends StatelessWidget {
  const _CustomerMessagesFilterRow({
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
            child: _CustomerMessageFilterChip(
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

class _CustomerMessageFilterChip extends StatelessWidget {
  const _CustomerMessageFilterChip({
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

class _CustomerPriorityInboxRow extends StatelessWidget {
  const _CustomerPriorityInboxRow({
    required this.metrics,
    required this.items,
    required this.selectedThreadId,
    required this.counterpartyNameOf,
    required this.onSelectedThread,
  });

  final _ResponsiveMetrics metrics;
  final List<DemoConversationThread> items;
  final String? selectedThreadId;
  final String Function(DemoConversationThread) counterpartyNameOf;
  final ValueChanged<String> onSelectedThread;

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
              final counterpartyName = counterpartyNameOf(item);
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1
                      ? 0
                      : _clampDouble(8 * metrics.scale, 6, 8),
                ),
                child: _CustomerPriorityThreadChip(
                  metrics: metrics,
                  counterpartyName: counterpartyName,
                  online: item.online,
                  selected: selectedThreadId == item.id,
                  onTap: () => onSelectedThread(item.id),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CustomerPriorityThreadChip extends StatelessWidget {
  const _CustomerPriorityThreadChip({
    required this.metrics,
    required this.counterpartyName,
    required this.online,
    required this.selected,
    required this.onTap,
  });

  final _ResponsiveMetrics metrics;
  final String counterpartyName;
  final bool online;
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
                    _initials(counterpartyName),
                    style: TextStyle(
                      color: const Color(0xFF9A3F1F),
                      fontSize: _clampDouble(11 * metrics.scale, 9, 11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (online)
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
              counterpartyName,
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

class _CustomerMessageThreadCard extends StatelessWidget {
  const _CustomerMessageThreadCard({
    required this.metrics,
    required this.thread,
    required this.counterpartyName,
    required this.onOpenThread,
    required this.onReply,
  });

  final _ResponsiveMetrics metrics;
  final DemoConversationThread thread;
  final String counterpartyName;
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
                        _initials(counterpartyName),
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
                              counterpartyName,
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
                _CustomerMessageMetaPill(
                  metrics: metrics,
                  icon: Icons.receipt_long_rounded,
                  label: thread.orderLabel,
                ),
                SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                _CustomerMessageMetaPill(
                  metrics: metrics,
                  icon: Icons.local_shipping_outlined,
                  label: thread.channelLabel,
                ),
                if (thread.priority) ...[
                  SizedBox(width: _clampDouble(6 * metrics.scale, 4, 6)),
                  _CustomerMessageMetaPill(
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

class _CustomerMessageMetaPill extends StatelessWidget {
  const _CustomerMessageMetaPill({
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
