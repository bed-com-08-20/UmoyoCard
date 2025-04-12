import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsPredictionsScreen extends StatelessWidget {
  const InsightsPredictionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Predictions'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHealthCard(
            title: '🩸 Blood Pressure',
            chart: _buildLineChart(),
            prediction: 'Moderate risk of hypertension',
            tip: 'Reduce salt intake and monitor daily',
          ),
          const SizedBox(height: 16),
          _buildHealthCard(
            title: '🍬 Blood Sugar',
            chart: _buildAreaChart(),
            prediction: 'Likely sugar spike in next 3 days',
            tip: 'Balance meals with protein and fiber',
          ),
          const SizedBox(height: 16),
          _buildHealthCard(
            title: '⚖️ Weight',
            chart: _buildBarChart(),
            prediction: 'Stable weight — good progress!',
            tip: 'Maintain diet and light exercise',
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard({
    required String title,
    required Widget chart,
    required String prediction,
    required String tip,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 150, child: chart),
            const SizedBox(height: 12),
            Text('Prediction: $prediction',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Tip: $tip'),
          ],
        ),
      ),
    );
  }

  // Placeholder line chart (e.g. for BP)
  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 120),
              FlSpot(1, 125),
              FlSpot(2, 130),
              FlSpot(3, 128),
              FlSpot(4, 135),
            ],
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // Placeholder area chart (for sugar)
  Widget _buildAreaChart() {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 90),
              FlSpot(1, 110),
              FlSpot(2, 100),
              FlSpot(3, 115),
              FlSpot(4, 105),
            ],
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green,
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // Placeholder bar chart (for weight)
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: [
          BarChartGroupData(
              x: 0, barRods: [BarChartRodData(toY: 60, color: Colors.green)]),
          BarChartGroupData(
              x: 1, barRods: [BarChartRodData(toY: 61, color: Colors.green)]),
          BarChartGroupData(
              x: 2, barRods: [BarChartRodData(toY: 62, color: Colors.green)]),
          BarChartGroupData(
              x: 3, barRods: [BarChartRodData(toY: 61.5, color: Colors.green)]),
          BarChartGroupData(
              x: 4, barRods: [BarChartRodData(toY: 62, color: Colors.green)]),
        ],
      ),
    );
  }
}
