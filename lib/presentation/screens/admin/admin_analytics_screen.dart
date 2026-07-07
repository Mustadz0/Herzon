import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        Supabase.instance.client.rpc('get_user_growth').catchError((_) => []),
        Supabase.instance.client.rpc('get_engagement_metrics').catchError((_) => null),
        Supabase.instance.client.from('posts').select('content_type').count(),
        Supabase.instance.client.from('reports').select('status').count(),
      ]);
      setState(() {
        _analytics = {
          'user_growth': results[0],
          'engagement': results[1],
          'post_types': results[2],
          'report_stats': results[3],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 16),
                      Text('Erreur: $_error', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadAnalytics, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Analytiques',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // User growth chart
                      _buildChartCard(
                        'Croissance des utilisateurs',
                        _buildUserGrowthChart(),
                      ),
                      const SizedBox(height: 16),
                      // Engagement metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Likes moyens',
                              (_analytics['engagement'] as Map<String, dynamic>?)?['avg_likes']?.toStringAsFixed(1) ?? '0',
                              Icons.favorite_outline,
                              const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Commentaires',
                              (_analytics['engagement'] as Map<String, dynamic>?)?['avg_comments']?.toStringAsFixed(1) ?? '0',
                              Icons.chat_bubble_outline,
                              const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Total réactions',
                              ((_analytics['engagement'] as Map<String, dynamic>?)?['total_reactions'] ?? 0).toString(),
                              Icons.favorite,
                              const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Total commentaires',
                              ((_analytics['engagement'] as Map<String, dynamic>?)?['total_comments'] ?? 0).toString(),
                              Icons.chat_bubble,
                              const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Post types pie chart
                      _buildChartCard(
                        'Types de posts',
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: 45,
                                  title: 'Texte',
                                  color: const Color(0xFF4F46E5),
                                  radius: 60,
                                  titleStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 30,
                                  title: 'Photo',
                                  color: const Color(0xFF7C3AED),
                                  radius: 60,
                                  titleStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 15,
                                  title: 'Vidéo',
                                  color: const Color(0xFF3B82F6),
                                  radius: 60,
                                  titleStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 10,
                                  title: 'Sondage',
                                  color: const Color(0xFFF59E0B),
                                  radius: 60,
                                  titleStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserGrowthChart() {
    final growthData = _analytics['user_growth'] as List<dynamic>? ?? [];
    if (growthData.isEmpty) {
      return const Center(child: Text('Aucune donnée de croissance disponible'));
    }

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < growthData.length; i++) {
      final item = growthData[i] as Map<String, dynamic>;
      spots.add(FlSpot(i.toDouble(), (item['new_users'] as num).toDouble()));
      final monthStr = item['month'] as String? ?? '';
      if (monthStr.length >= 7) {
        labels.add(monthStr.substring(5, 7));
      } else {
        labels.add('${i + 1}');
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFE2E8F0),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4F46E5),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF4F46E5),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4F46E5).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
