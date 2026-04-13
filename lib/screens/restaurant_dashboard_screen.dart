import 'package:flutter/material.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key, required this.restaurantName});

  final String restaurantName;

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  static const _pageColor = Color(0xFFF1DFC4);
  bool _isOnline = true;
  int _selectedBottomIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Good Morning,\n${widget.restaurantName}!',
                      style: const TextStyle(
                        color: Color(0xFF381F13),
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: _isOnline,
                        onChanged: (value) {
                          setState(() => _isOnline = value);
                        },
                        activeTrackColor: const Color(0xFFFF7F4A),
                        inactiveTrackColor: const Color(0xFFDBC7AB),
                        thumbColor: WidgetStateProperty.all(
                          const Color(0xFFFDF5EA),
                        ),
                      ),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Color(0xFF553A2A),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: _MetricCard(
                      title: "Today's\nOrders",
                      value: '12',
                      icon: Icons.lock_outline,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      title: 'Pending',
                      value: '3',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      title: 'Revenue',
                      value: '\$450',
                      icon: Icons.attach_money_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _RevenueChartCard(),
              const SizedBox(height: 22),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Color(0xFF412819),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.videocam_rounded,
                      label: 'Add New\nVideo',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Edit\nMenu',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.campaign_rounded,
                      label: 'Active\nPromos',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: _pageColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomNavItem(
                  icon: Icons.smart_display_rounded,
                  label: 'Feed',
                  selected: _selectedBottomIndex == 0,
                  onTap: () => setState(() => _selectedBottomIndex = 0),
                ),
                _BottomNavItem(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Orders',
                  selected: _selectedBottomIndex == 1,
                  onTap: () => setState(() => _selectedBottomIndex = 1),
                ),
                _BottomNavItem(
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  selected: _selectedBottomIndex == 2,
                  onTap: () => setState(() => _selectedBottomIndex = 2),
                ),
                _BottomNavItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Menu',
                  selected: _selectedBottomIndex == 3,
                  onTap: () => setState(() => _selectedBottomIndex = 3),
                ),
                _BottomNavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  selected: _selectedBottomIndex == 4,
                  onTap: () => setState(() => _selectedBottomIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF655649),
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE1784C),
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8D7A8),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: const Color(0xFFE07645), size: 23),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard();

  @override
  Widget build(BuildContext context) {
    const values = [120.0, 300.0, 220.0, 520.0, 410.0, 610.0, 740.0];
    const yAxisLabels = ['800', '600', '400', '200', '0'];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: yAxisLabels
                        .map(
                          (label) => Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF897A6B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _RevenueChartPainter(values: values, maxY: 800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sun', style: _axisLabelStyle),
                Text('Mon', style: _axisLabelStyle),
                Text('Tue', style: _axisLabelStyle),
                Text('Wed', style: _axisLabelStyle),
                Text('Thu', style: _axisLabelStyle),
                Text('Fri', style: _axisLabelStyle),
                Text('Sat', style: _axisLabelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _axisLabelStyle = TextStyle(
  color: Color(0xFF857667),
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter({required this.values, required this.maxY});

  final List<double> values;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E4DC)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final ratio = (values[i].clamp(0, maxY)) / maxY;
      final y = size.height - (size.height * ratio);
      points.add(Offset(stepX * i, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.quadraticBezierTo(controlX, previous.dy, current.dx, current.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x77E56C49), Color(0x00E56C49)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFE16D49)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    if (maxY != oldDelegate.maxY ||
        values.length != oldDelegate.values.length) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i] != oldDelegate.values[i]) {
        return true;
      }
    }
    return false;
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8D7A8),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: const Color(0xFFE07645), size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A3429),
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFEC8052) : const Color(0xFF8E8981);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
