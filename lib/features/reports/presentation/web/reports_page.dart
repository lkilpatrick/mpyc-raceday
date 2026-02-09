import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, 1, 1),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text('Reports',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  '${DateFormat.yMMMd().format(_dateRange.start)} – ${DateFormat.yMMMd().format(_dateRange.end)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Season Summary'),
            Tab(text: 'Crew Rotation'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Fleet Participation'),
            Tab(text: 'Weather'),
            Tab(text: 'Checklist Compliance'),
            Tab(text: 'Incidents'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SeasonSummaryTab(dateRange: _dateRange),
              _CrewRotationTab(dateRange: _dateRange),
              _MaintenanceReportTab(dateRange: _dateRange),
              _FleetParticipationTab(dateRange: _dateRange),
              _WeatherSummaryTab(dateRange: _dateRange),
              _ChecklistComplianceTab(dateRange: _dateRange),
              _IncidentSummaryTab(dateRange: _dateRange),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }
}

// ═══════════════════════════════════════════════════════
// Tab 1 — Season Summary
// ═══════════════════════════════════════════════════════

class _SeasonSummaryTab extends StatelessWidget {
  const _SeasonSummaryTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final startTs = Timestamp.fromDate(dateRange.start);
    final endTs = Timestamp.fromDate(dateRange.end);

    return FutureBuilder(
      future: Future.wait([
        fs.collection('race_events')
            .where('date', isGreaterThanOrEqualTo: startTs)
            .where('date', isLessThanOrEqualTo: endTs)
            .get(),
        fs.collection('boat_checkins')
            .where('checkedInAt', isGreaterThanOrEqualTo: startTs)
            .where('checkedInAt', isLessThanOrEqualTo: endTs)
            .get(),
        fs.collection('incidents')
            .where('reportedAt', isGreaterThanOrEqualTo: startTs)
            .where('reportedAt', isLessThanOrEqualTo: endTs)
            .get(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snap.data![0].docs;
        final checkins = snap.data![1].docs;
        final incidents = snap.data![2].docs;

        final eventCount = events.length;
        final avgFleet = eventCount > 0
            ? (checkins.length / eventCount).toStringAsFixed(1)
            : '0';

        // Fleet size per event for chart
        final fleetByEvent = <String, int>{};
        for (final c in checkins) {
          final d = c.data() as Map<String, dynamic>;
          final eid = d['eventId'] as String? ?? '';
          fleetByEvent[eid] = (fleetByEvent[eid] ?? 0) + 1;
        }

        return _ReportLayout(
          metrics: [
            _MetricTile('Events', '$eventCount'),
            _MetricTile('Total Check-Ins', '${checkins.length}'),
            _MetricTile('Avg Fleet Size', avgFleet),
            _MetricTile('Incidents', '${incidents.length}'),
          ],
          chart: SizedBox(
            height: 200,
            child: fleetByEvent.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
                    BarChartData(
                      barGroups: fleetByEvent.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.value.toDouble(),
                                    color: Colors.blue,
                                    width: 16,
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
          ),
          chartTitle: 'Fleet Size per Event',
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 2 — Crew Rotation
// ═══════════════════════════════════════════════════════

class _CrewRotationTab extends StatelessWidget {
  const _CrewRotationTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('crew_assignments')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final countByMember = <String, int>{};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final name = d['memberName'] as String? ?? 'Unknown';
          countByMember[name] = (countByMember[name] ?? 0) + 1;
        }
        final sorted = countByMember.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final avg = sorted.isNotEmpty
            ? sorted.map((e) => e.value).reduce((a, b) => a + b) / sorted.length
            : 0.0;

        return _ReportLayout(
          metrics: [
            _MetricTile('Total Assignments', '${docs.length}'),
            _MetricTile('Crew Members', '${sorted.length}'),
            _MetricTile('Avg Duties/Member', avg.toStringAsFixed(1)),
          ],
          chart: SizedBox(
            height: 200,
            child: sorted.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
                    BarChartData(
                      barGroups: sorted.take(15).toList().asMap().entries
                          .map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.value.toDouble(),
                                    color: Colors.purple,
                                    width: 14,
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          chartTitle: 'Duties per Crew Member (Top 15)',
          table: DataTable(
            columns: const [
              DataColumn(label: Text('Member')),
              DataColumn(label: Text('Duties')),
            ],
            rows: sorted
                .map((e) => DataRow(cells: [
                      DataCell(Text(e.key)),
                      DataCell(Text('${e.value}')),
                    ]))
                .toList(),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 3 — Maintenance Report
// ═══════════════════════════════════════════════════════

class _MaintenanceReportTab extends StatelessWidget {
  const _MaintenanceReportTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maintenance_requests')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int open = 0, resolved = 0;
        final byCategory = <String, int>{};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final status = d['status'] as String? ?? '';
          if (status == 'resolved' || status == 'closed') {
            resolved++;
          } else {
            open++;
          }
          final cat = d['category'] as String? ?? 'Other';
          byCategory[cat] = (byCategory[cat] ?? 0) + 1;
        }

        return _ReportLayout(
          metrics: [
            _MetricTile('Total Requests', '${docs.length}'),
            _MetricTile('Open', '$open'),
            _MetricTile('Resolved', '$resolved'),
          ],
          chart: SizedBox(
            height: 200,
            child: byCategory.isEmpty
                ? const Center(child: Text('No data'))
                : PieChart(
                    PieChartData(
                      sections: byCategory.entries.toList().asMap().entries
                          .map((e) {
                        final colors = [
                          Colors.blue, Colors.red, Colors.green,
                          Colors.orange, Colors.purple, Colors.teal,
                        ];
                        return PieChartSectionData(
                          value: e.value.value.toDouble(),
                          title: '${e.value.key}\n${e.value.value}',
                          color: colors[e.key % colors.length],
                          titleStyle: const TextStyle(
                              fontSize: 10, color: Colors.white),
                          radius: 80,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          chartTitle: 'Requests by Category',
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 4 — Fleet Participation
// ═══════════════════════════════════════════════════════

class _FleetParticipationTab extends StatelessWidget {
  const _FleetParticipationTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('boats')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final boats = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'name': '${data['boatName'] ?? ''} (${data['sailNumber'] ?? ''})',
            'count': data['raceCount'] as int? ?? 0,
          };
        }).toList()
          ..sort((a, b) =>
              (b['count'] as int).compareTo(a['count'] as int));

        return _ReportLayout(
          metrics: [
            _MetricTile('Active Boats', '${docs.length}'),
            _MetricTile(
                'Avg Races',
                docs.isNotEmpty
                    ? (boats.map((b) => b['count'] as int).reduce((a, b) => a + b) /
                            docs.length)
                        .toStringAsFixed(1)
                    : '0'),
          ],
          chart: SizedBox(
            height: 200,
            child: boats.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
                    BarChartData(
                      barGroups: boats.take(20).toList().asMap().entries
                          .map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: (e.value['count'] as int).toDouble(),
                                    color: Colors.teal,
                                    width: 12,
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          chartTitle: 'Races per Boat (Top 20)',
          table: DataTable(
            columns: const [
              DataColumn(label: Text('Boat')),
              DataColumn(label: Text('Races')),
            ],
            rows: boats
                .map((b) => DataRow(cells: [
                      DataCell(Text(b['name'] as String)),
                      DataCell(Text('${b['count']}')),
                    ]))
                .toList(),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 5 — Weather Summary
// ═══════════════════════════════════════════════════════

class _WeatherSummaryTab extends StatelessWidget {
  const _WeatherSummaryTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    final startTs = Timestamp.fromDate(dateRange.start);
    final endTs = Timestamp.fromDate(dateRange.end);

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('weather_entries')
          .where('timestamp', isGreaterThanOrEqualTo: startTs)
          .where('timestamp', isLessThanOrEqualTo: endTs)
          .orderBy('timestamp')
          .get(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No weather data for this period'));
        }

        double totalWind = 0, maxWind = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final w = (d['windSpeedKts'] as num?)?.toDouble() ?? 0;
          totalWind += w;
          if (w > maxWind) maxWind = w;
        }
        final avgWind = totalWind / docs.length;

        // Wind speed over time for chart
        final spots = docs.asMap().entries.map((e) {
          final d = e.value.data() as Map<String, dynamic>;
          return FlSpot(
              e.key.toDouble(), (d['windSpeedKts'] as num?)?.toDouble() ?? 0);
        }).toList();

        return _ReportLayout(
          metrics: [
            _MetricTile('Entries', '${docs.length}'),
            _MetricTile('Avg Wind', '${avgWind.toStringAsFixed(1)} kts'),
            _MetricTile('Max Wind', '${maxWind.toStringAsFixed(0)} kts'),
          ],
          chart: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
          chartTitle: 'Wind Speed Over Time',
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 6 — Checklist Compliance
// ═══════════════════════════════════════════════════════

class _ChecklistComplianceTab extends StatelessWidget {
  const _ChecklistComplianceTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('checklist_completions')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int completed = 0, partial = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final status = d['status'] as String? ?? '';
          if (status == 'completed') {
            completed++;
          } else {
            partial++;
          }
        }
        final rate = docs.isNotEmpty
            ? (completed / docs.length * 100).toStringAsFixed(0)
            : '0';

        return _ReportLayout(
          metrics: [
            _MetricTile('Total', '${docs.length}'),
            _MetricTile('Completed', '$completed'),
            _MetricTile('Partial', '$partial'),
            _MetricTile('Completion Rate', '$rate%'),
          ],
          chart: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: completed.toDouble(),
                    title: 'Done\n$completed',
                    color: Colors.green,
                    radius: 80,
                    titleStyle:
                        const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: partial.toDouble(),
                    title: 'Partial\n$partial',
                    color: Colors.orange,
                    radius: 80,
                    titleStyle:
                        const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
                sectionsSpace: 2,
              ),
            ),
          ),
          chartTitle: 'Completion Status',
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 7 — Incident Summary
// ═══════════════════════════════════════════════════════

class _IncidentSummaryTab extends StatelessWidget {
  const _IncidentSummaryTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int protests = 0, resolved = 0;
        final rulesCited = <String, int>{};
        final statusCounts = <String, int>{};

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final status = d['status'] as String? ?? '';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          if (status == 'protestFiled' ||
              status == 'hearingScheduled' ||
              status == 'hearingComplete') protests++;
          if (status == 'resolved') resolved++;

          final rules = List<String>.from(d['rulesAlleged'] ?? []);
          for (final r in rules) {
            final ruleNum = r.split(' – ').first;
            rulesCited[ruleNum] = (rulesCited[ruleNum] ?? 0) + 1;
          }
        }

        final sortedRules = rulesCited.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return _ReportLayout(
          metrics: [
            _MetricTile('Total Incidents', '${docs.length}'),
            _MetricTile('Protests Filed', '$protests'),
            _MetricTile('Resolved', '$resolved'),
          ],
          chart: SizedBox(
            height: 200,
            child: sortedRules.isEmpty
                ? const Center(child: Text('No rules cited'))
                : BarChart(
                    BarChartData(
                      barGroups: sortedRules.take(10).toList().asMap().entries
                          .map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.value.toDouble(),
                                    color: Colors.red,
                                    width: 16,
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          chartTitle: 'Most Cited Rules',
          table: DataTable(
            columns: const [
              DataColumn(label: Text('Rule')),
              DataColumn(label: Text('Times Cited')),
            ],
            rows: sortedRules
                .map((e) => DataRow(cells: [
                      DataCell(Text(e.key)),
                      DataCell(Text('${e.value}')),
                    ]))
                .toList(),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Shared report layout
// ═══════════════════════════════════════════════════════

class _ReportLayout extends StatelessWidget {
  const _ReportLayout({
    required this.metrics,
    required this.chart,
    required this.chartTitle,
    this.table,
  });

  final List<_MetricTile> metrics;
  final Widget chart;
  final String chartTitle;
  final Widget? table;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics.map((m) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(m.value,
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(m.label,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )).toList(),
          ),
          const SizedBox(height: 16),

          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chartTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  chart,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Table
          if (table != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: table!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile {
  const _MetricTile(this.label, this.value);
  final String label;
  final String value;
}
