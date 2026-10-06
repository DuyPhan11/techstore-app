import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/admin_dashboard_model.dart';
import '../utils/currency_format.dart';

enum RevenueChartType { bar, line }

class RevenueChart extends StatefulWidget {
  final List<RevenueTimePointModel> dataPoints;
  final double height;

  const RevenueChart({
    super.key,
    required this.dataPoints,
    this.height = 200,
  });

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  RevenueChartType _chartType = RevenueChartType.bar;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        child: const Text(
          'Chưa có dữ liệu doanh thu trong khoảng thời gian này',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    final maxRevenue = widget.dataPoints.map((e) => e.revenue).reduce(max);
    final totalRevenue = widget.dataPoints.fold(0.0, (sum, e) => sum + e.revenue);
    final avgRevenue = widget.dataPoints.isNotEmpty ? totalRevenue / widget.dataPoints.length : 0.0;

    RevenueTimePointModel? selectedPoint;
    if (_selectedIndex != null && _selectedIndex! >= 0 && _selectedIndex! < widget.dataPoints.length) {
      selectedPoint = widget.dataPoints[_selectedIndex!];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls & Stats Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Stats pills
            Row(
              children: [
                _buildStatBadge(
                  label: 'Cao nhất',
                  value: _formatCompactAmount(maxRevenue),
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'TB/ngày',
                  value: _formatCompactAmount(avgRevenue),
                  color: const Color(0xFF0EA5E9),
                ),
              ],
            ),

            // Toggle Bar vs Line
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildTypeTab(
                    icon: Icons.bar_chart_rounded,
                    type: RevenueChartType.bar,
                  ),
                  _buildTypeTab(
                    icon: Icons.show_chart_rounded,
                    type: RevenueChartType.line,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Selected Tooltip Info Banner
        if (selectedPoint != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateLabel(selectedPoint.date),
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${selectedPoint.orderCount} đơn • ',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      CurrencyHelper.format(selectedPoint.revenue),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Interactive Canvas Chart
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = constraints.maxWidth;
            return GestureDetector(
              onTapUp: (details) {
                final localX = details.localPosition.dx;
                final count = widget.dataPoints.length;
                if (count == 0) return;
                final step = chartWidth / count;
                final index = (localX / step).floor().clamp(0, count - 1);
                setState(() {
                  _selectedIndex = (_selectedIndex == index) ? null : index;
                });
              },
              child: CustomPaint(
                size: Size(chartWidth, widget.height),
                painter: _RevenueCanvasPainter(
                  dataPoints: widget.dataPoints,
                  maxRevenue: maxRevenue > 0 ? maxRevenue : 1.0,
                  chartType: _chartType,
                  selectedIndex: _selectedIndex,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 6),
        // Helper hint
        const Center(
          child: Text(
            'Chạm vào cột/điểm trên biểu đồ để xem chi tiết theo ngày',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTypeTab({required IconData icon, required RevenueChartType type}) {
    final isSelected = _chartType == type;
    return InkWell(
      onTap: () => setState(() => _chartType = type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  String _formatCompactAmount(double val) {
    if (val >= 1000000000) {
      return '${(val / 1000000000).toStringAsFixed(1)}B';
    } else if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K';
    }
    return val.toStringAsFixed(0);
  }

  String _formatDateLabel(String yyyyMmDd) {
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return yyyyMmDd;
  }
}

class _RevenueCanvasPainter extends CustomPainter {
  final List<RevenueTimePointModel> dataPoints;
  final double maxRevenue;
  final RevenueChartType chartType;
  final int? selectedIndex;

  _RevenueCanvasPainter({
    required this.dataPoints,
    required this.maxRevenue,
    required this.chartType,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double bottomPadding = 22.0;
    final double chartHeight = size.height - bottomPadding;
    final double width = size.width;
    final int count = dataPoints.length;

    if (count == 0) return;

    // 1. Draw horizontal grid lines (0%, 33%, 66%, 100%)
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 3; i++) {
      final y = chartHeight - (chartHeight * (i / 3.0));
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final double step = width / count;

    if (chartType == RevenueChartType.bar) {
      // 2. Bar Chart
      final double barWidth = (step * 0.65).clamp(3.0, 24.0);

      for (int i = 0; i < count; i++) {
        final point = dataPoints[i];
        final ratio = (point.revenue / maxRevenue).clamp(0.0, 1.0);
        final barHeight = max(chartHeight * ratio, 2.0); // minimum 2px so zero revenue still shows base

        final x = (i * step) + (step / 2.0);
        final y = chartHeight - barHeight;

        final isSelected = selectedIndex == i;

        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - (barWidth / 2.0), y, barWidth, barHeight),
          const Radius.circular(4),
        );

        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSelected
                ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
                : (point.revenue > 0
                    ? [const Color(0xFF6366F1), const Color(0xFF4338CA)]
                    : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]),
          ).createShader(Rect.fromLTWH(x - (barWidth / 2.0), y, barWidth, barHeight));

        canvas.drawRRect(barRect, barPaint);

        if (isSelected) {
          // Highlight border
          final highlightPaint = Paint()
            ..color = const Color(0xFF38BDF8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(barRect, highlightPaint);
        }
      }
    } else {
      // 3. Line / Area Chart
      final path = Path();
      final fillPath = Path();

      final points = <Offset>[];
      for (int i = 0; i < count; i++) {
        final point = dataPoints[i];
        final ratio = (point.revenue / maxRevenue).clamp(0.0, 1.0);
        final x = (i * step) + (step / 2.0);
        final y = chartHeight - (chartHeight * ratio);
        points.add(Offset(x, y));
      }

      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        fillPath.moveTo(points.first.dx, chartHeight);
        fillPath.lineTo(points.first.dx, points.first.dy);

        for (int i = 0; i < points.length - 1; i++) {
          final p0 = points[i];
          final p1 = points[i + 1];
          final controlX = (p0.dx + p1.dx) / 2.0;
          path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
          fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        }

        fillPath.lineTo(points.last.dx, chartHeight);
        fillPath.close();

        // Area Gradient Fill
        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.35),
              const Color(0xFF6366F1).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, width, chartHeight));
        canvas.drawPath(fillPath, fillPaint);

        // Stroke Line
        final strokePaint = Paint()
          ..color = const Color(0xFF4F46E5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, strokePaint);

        // Draw points
        for (int i = 0; i < points.length; i++) {
          final pt = points[i];
          final isSelected = selectedIndex == i;

          if (isSelected) {
            // Vertical guide line
            final guidePaint = Paint()
              ..color = const Color(0xFF38BDF8)
              ..strokeWidth = 1.2
              ..style = PaintingStyle.stroke;
            canvas.drawLine(Offset(pt.dx, 0), Offset(pt.dx, chartHeight), guidePaint);

            // Outer ring
            canvas.drawCircle(pt, 6, Paint()..color = const Color(0xFF38BDF8));
            canvas.drawCircle(pt, 3, Paint()..color = Colors.white);
          } else if (count <= 14 || dataPoints[i].revenue > 0) {
            canvas.drawCircle(pt, 3.5, Paint()..color = const Color(0xFF4F46E5));
            canvas.drawCircle(pt, 1.8, Paint()..color = Colors.white);
          }
        }
      }
    }

    // 4. Date labels on bottom X-axis
    final textStyle = const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    int labelStep = max((count / 5).ceil(), 1);
    for (int i = 0; i < count; i += labelStep) {
      final point = dataPoints[i];
      final parts = point.date.split('-');
      final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : point.date;

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final x = ((i * step) + (step / 2.0)) - (textPainter.width / 2.0);
      textPainter.paint(canvas, Offset(x.clamp(0.0, width - textPainter.width), chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueCanvasPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.chartType != chartType ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxRevenue != maxRevenue;
  }
}

// ============================================================================
// DONUT / PIE REVENUE PROPORTION CHART
// ============================================================================

class DonutProportionChart extends StatelessWidget {
  final List<CategoryRevenueModel> categories;
  final double totalRevenue;

  static const List<Color> palette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];

  const DonutProportionChart({
    super.key,
    required this.categories,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty || totalRevenue <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: const Text(
          'Chưa có dữ liệu tỷ trọng doanh thu trong kỳ này',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        // Top Donut Visual
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _DonutChartPainter(
                      categories: categories,
                      totalRevenue: totalRevenue,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TỶ TRỌNG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${categories.length} DM',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Stacked 100% Segmented Proportion Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: categories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final color = palette[idx % palette.length];
                final flex = max((cat.percentage * 10).round(), 1);

                return Expanded(
                  flex: flex,
                  child: Container(
                    color: color,
                    margin: const EdgeInsets.only(right: 1.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Category Detail Breakdown List
        Column(
          children: categories.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final color = palette[idx % palette.length];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Color bullet
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Category Name
                  Expanded(
                    child: Text(
                      cat.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),

                  // Percentage Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${cat.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Revenue Amount
                  Text(
                    CurrencyHelper.format(cat.revenue),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryRevenueModel> categories;
  final double totalRevenue;

  _DonutChartPainter({
    required this.categories,
    required this.totalRevenue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalRevenue <= 0 || categories.isEmpty) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final radius = (size.width / 2.0) - 10;
    final strokeWidth = 20.0;

    double startAngle = -pi / 2.0; // Start at 12 o'clock

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final sweepAngle = (cat.revenue / totalRevenue) * (2 * pi);

      if (sweepAngle <= 0) continue;

      final color = DonutProportionChart.palette[i % DonutProportionChart.palette.length];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      // Small 0.03 rad gap between segments
      final gap = categories.length > 1 ? 0.03 : 0.0;
      final actualSweep = max(sweepAngle - gap, 0.01);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gap / 2.0),
        actualSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.totalRevenue != totalRevenue;
  }
}
