import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_stats_provider.dart';
import '../../widgets/admin/admin_stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text('Erreur: $e', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(adminStatsProvider.notifier).loadStats(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.read(adminStatsProvider.notifier).loadStats(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tableau de bord',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              // Stat cards grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  AdminStatCard(
                    title: 'Utilisateurs',
                    value: stats.totalUsers.toString(),
                    icon: Icons.people_outline,
                    color: const Color(0xFF4F46E5),
                  ),
                  AdminStatCard(
                    title: 'Posts',
                    value: stats.totalPosts.toString(),
                    icon: Icons.article_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                  AdminStatCard(
                    title: 'Signalements',
                    value: stats.pendingReports.toString(),
                    icon: Icons.flag_outlined,
                    color: const Color(0xFFEF4444),
                    subtitle: stats.pendingReports > 0 ? 'En attente' : null,
                  ),
                  AdminStatCard(
                    title: 'Actifs aujourd\'hui',
                    value: stats.activeUsersToday.toString(),
                    icon: Icons.trending_up,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Posts last 7 days chart
              Container(
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
                      'Posts des 7 derniers jours',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: stats.postsLast7Days.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune donnée',
                                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _getMaxY(stats.postsLast7Days),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => const Color(0xFF1E293B),
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${rod.toY.toInt()} posts',
                                        GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                                        final index = value.toInt();
                                        if (index >= 0 && index < days.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              days[index],
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
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
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: _getMaxY(stats.postsLast7Days) / 4,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: const Color(0xFFE2E8F0),
                                    strokeWidth: 1,
                                  ),
                                ),
                                barGroups: _buildBarGroups(stats.postsLast7Days),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Top zones
              if (stats.topZones.isNotEmpty) ...[
                Container(
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
                        'Zones les plus actives',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...stats.topZones.take(5).map((zone) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4F46E5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    zone['name'] ?? 'Zone inconnue',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${zone['post_count'] ?? 0} posts',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10;
    final max = data.fold<int>(0, (prev, e) {
      final count = (e['count'] ?? 0) as int;
      return count > prev ? count : prev;
    });
    return (max + 5).toDouble();
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> data) {
    return List.generate(7, (index) {
      final dayData = index < data.length ? data[index] : null;
      final count = dayData?['count'] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: const Color(0xFF4F46E5),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(data),
              color: const Color(0xFFF1F5F9),
            ),
          ),
        ],
      );
    });
  }
}
