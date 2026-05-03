import 'package:flutter/material.dart';

import '../services/admin_api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.authToken,
    required this.adminName,
    this.onLogout,
  });

  final String authToken;
  final String adminName;
  final Future<void> Function()? onLogout;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _apiService = AdminApiService();
  AdminDashboardSnapshot? _snapshot;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await _apiService.fetchDashboard(
        token: widget.authToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } on AdminApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _logout() async {
    final onLogout = widget.onLogout;
    if (onLogout != null) {
      await onLogout();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EFE5),
        surfaceTintColor: Colors.transparent,
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _AdminErrorState(message: _errorMessage!, onRetry: _loadDashboard)
          : snapshot == null
          ? _AdminErrorState(
              message: 'No dashboard data returned.',
              onRetry: _loadDashboard,
            )
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              color: const Color(0xFFFF7E4D),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Welcome, ${widget.adminName}',
                    style: const TextStyle(
                      color: Color(0xFF231A16),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Live data from the hunger_rush admin APIs.',
                    style: TextStyle(
                      color: Color(0xFF7D6C60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: snapshot.stats.entries
                        .map(
                          (entry) => _AdminStatCard(
                            label: _label(entry.key),
                            value: entry.value.toString(),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 22),
                  _AdminListSection(
                    title: 'Recent Orders',
                    emptyLabel: 'No recent orders yet.',
                    items: snapshot.recentOrders,
                    titleFor: (item) => 'Order #${item['id'] ?? ''}',
                    subtitleFor: (item) =>
                        '${item['status'] ?? 'pending'} - ${item['total'] ?? ''}',
                  ),
                  const SizedBox(height: 18),
                  _AdminListSection(
                    title: 'Recent Reports',
                    emptyLabel: 'No reports submitted yet.',
                    items: snapshot.recentReports,
                    titleFor: (item) => item['subject']?.toString() ?? 'Report',
                    subtitleFor: (item) =>
                        '${item['status'] ?? 'open'} - ${item['created_at'] ?? ''}',
                  ),
                ],
              ),
            ),
    );
  }

  String _label(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCFA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAD9CB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFF7E4D),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5D4C41),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminListSection extends StatelessWidget {
  const _AdminListSection({
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.titleFor,
    required this.subtitleFor,
  });

  final String title;
  final String emptyLabel;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic> item) titleFor;
  final String Function(Map<String, dynamic> item) subtitleFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF231A16),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(
                color: Color(0xFF7D6C60),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...items
                .take(5)
                .map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(titleFor(item)),
                    subtitle: Text(subtitleFor(item)),
                  ),
                ),
        ],
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFFF7E4D),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
