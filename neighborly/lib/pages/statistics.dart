import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Helped Requests & Neighborhood Rank
          Row(
            children: [
              _statCard(
                iconData: Icons.flash_on_outlined,
                label: '55',
                subLabel: 'Helped\nRequests',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9C64), Color(0xFFFF9C64)],
                ),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 16),
              _statCard(
                iconData: Icons.leaderboard_outlined,
                label: '#2',
                subLabel: 'Leaderboard\nRank',
                gradient: const LinearGradient(
                  colors: [Color(0xFFB084F4), Color(0xFFB084F4)],
                ),
                iconColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard(
                iconData: Icons.check_circle_outlined,
                label: '83%',
                subLabel: 'Help Response\nSuccess',
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8F46C), Color(0xFFB8F46C)],
                ),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 16),
              _statCard(
                iconData: Icons.location_on_outlined,
                label: '2 km',
                subLabel: 'Help Range\nRadius',
                gradient: const LinearGradient(
                  colors: [Color(0xFF94D4FA), Color(0xFF94D4FA)],
                ),
                iconColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Strongest Topics (all in one card)
          // Most Frequent Help Types (all in one card)
          const Text(
            'MOST REQUESTED HELP TYPES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5B7E),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _strongestTopicsCard(context),
          const SizedBox(height: 28),
          // Least Contributed Areas (single card)
          const Text(
            'CONTRIBUTIONS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5B7E),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _contributionsCard(),
          /* _topicCard(
            context: context,
            iconPath: null,
            iconData: Icons.traffic,
            label: 'Traffic Updates',
            percent: 0.95,
            percentLabel: '95%',
            color: Colors.green,
          ), */
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String subLabel,
    required IconData iconData,
    required Gradient gradient, // <-- keep for compatibility, but ignore
    Color iconColor = Colors.white,
  }) {
    // Map each stat card to its solid color
    Color cardColor = Colors.white;
    if (label == '55') {
      cardColor = const Color(0xFFFF9C64); // Helped Requests
    } else if (label == '#2') {
      cardColor = const Color(0xFFB084F4); // Leaderboard
    } else if (label == '83%') {
      cardColor = const Color(0xFFB8F46C); // Help Response Success
    } else if (label == '2 km') {
      cardColor = const Color(0xFF94D4FA); // Help Range Radius
    }

    return Expanded(
      child: Container(
        height: 135,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                subLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Icon and value row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 28, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _strongestTopicsCard(BuildContext context) {
    // 7 random icons and values
    final helpTypes = [
      {'icon': Icons.shopping_cart, 'active': 20.0},
      {'icon': Icons.directions_car, 'active': 28.0},
      {'icon': Icons.pets, 'active': 15.0},
      {'icon': Icons.local_hospital, 'active': 10.0},
      {'icon': Icons.home_repair_service, 'active': 25.0},
      {'icon': Icons.school, 'active': 18.0},
      {'icon': Icons.restaurant, 'active': 22.0},
    ];

    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SizedBox(
          width: double.infinity,
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: 30,
              minY: 0,
              barGroups: List.generate(helpTypes.length, (index) {
                final type = helpTypes[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: type['active'] as double,
                      width: 32,
                      color: const Color(0xFF2FEA9B),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ],
                );
              }),
              groupsSpace: 8, // closer bars
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: 10,
                    getTitlesWidget: (value, meta) {
                      if (value % 10 == 0 && value >= 0 && value <= 30) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= helpTypes.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Icon(
                          helpTypes[idx]['icon'] as IconData,
                          size: 20,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              gridData: FlGridData(
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _verticalBarWithLabel({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int value,
    required int max,
    required Color color,
  }) {
    double barHeight = 180;
    double fillHeight = (value / max) * barHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Faded background bar
            Container(
              width: 22,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                ),
              ),
            ),
            // Filled bar
            Container(
              width: 22,
              height: fillHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _topicChartRow({
    required BuildContext context,
    required String label,
    required int activeRequests, // Active requests
    required int inactiveRequests, // Inactive requests
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Column(
      children: [
        Icon(
          Icons.bar_chart,
          size: 32,
          color: activeColor,
        ), // Icon for each section
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // Stacked Bar Chart
        SizedBox(
          height: 50, // Adjust the height for the bar
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      fromY: 0, // Start from 0 (X-axis starts here)
                      toY:
                          activeRequests
                              .toDouble(), // Set height of the active bar
                      width: 30, // Bar width
                      color: activeColor, // Color for the active bar
                    ),
                    BarChartRodData(
                      fromY:
                          activeRequests
                              .toDouble(), // Start where active bar ends
                      toY:
                          (activeRequests + inactiveRequests)
                              .toDouble(), // Set height of inactive bar
                      width: 30, // Bar width
                      color: inactiveColor, // Color for the inactive bar
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _contributionsCard() {
    final List<_ContributionData> chartData = [
      _ContributionData('Groceries', 30, const Color(0xFF4285F4)),
      _ContributionData('Transport', 8, const Color(0xFF2FEA9B)),
      _ContributionData('Medical', 10, const Color(0xFFFFB300)),
      _ContributionData('Other', 7, const Color(0xFFFFE082)),
    ];

    // Sort the chartData in ascending order based on the value
    chartData.sort((a, b) => a.value.compareTo(b.value));

    final int total = chartData.fold(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
      ),
      child: Column(
        children: [
          // Radial Chart Section
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: SfCircularChart(
                  margin: EdgeInsets.zero,
                  legend: Legend(isVisible: false),
                  series: <CircularSeries>[
                    RadialBarSeries<_ContributionData, String>(
                      dataSource: chartData,
                      xValueMapper: (_ContributionData data, _) => data.label,
                      yValueMapper: (_ContributionData data, _) => data.value,
                      pointColorMapper:
                          (_ContributionData data, _) => data.color,
                      maximumValue: total.toDouble(),
                      radius: '100%',
                      innerRadius: '30%',
                      gap: '12%',
                      cornerStyle: CornerStyle.bothCurve,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: false,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: Color(0xFF5B5B7E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between chart and labels
          // Label Section
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center labels horizontally
            children:
                chartData.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 3,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5B5B7E),
                          ),
                        ),
                        Text(
                          '${item.value}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ContributionData {
  final String label;
  final int value;
  final Color color;
  _ContributionData(this.label, this.value, this.color);
}

// Custom painter for the ring segments

Widget _topicCard({
  required BuildContext context,
  String? iconPath,
  IconData? iconData,
  required String label,
  required double percent,
  required String percentLabel,
  required Color color,
  required int currentRequests,
  required int totalRequests,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
    ),
    child: Row(
      children: [
        iconPath != null
            ? Image.asset(iconPath, width: 32, height: 32, fit: BoxFit.cover)
            : Icon(iconData, size: 32, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Gradient progress bar
              // Gradient progress bar for Traffic Updates
              SizedBox(
                height: 200, // Adjust height as needed
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            fromY: 0, // start of the bar
                            toY:
                                currentRequests
                                    .toDouble(), // height of the active requests bar
                            width: 20,
                            color: color, // Color for the current requests bar
                          ),
                          BarChartRodData(
                            fromY:
                                currentRequests
                                    .toDouble(), // Start where the active bar ends
                            toY:
                                totalRequests
                                    .toDouble(), // End at totalRequests
                            width: 20,
                            color:
                                Colors
                                    .grey
                                    .shade300, // Color for the remaining part of the bar
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percentLabel ',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
