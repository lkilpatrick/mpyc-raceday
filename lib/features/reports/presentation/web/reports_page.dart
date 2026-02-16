import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, 1, 1),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
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
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Season Summary'),
            Tab(text: 'Volunteer Stats'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Fleet Participation'),
            Tab(text: 'Conditions'),
            Tab(text: 'Checklist Compliance'),
            Tab(text: 'Incidents'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SeasonSummaryTab(dateRange: _dateRange),
              _VolunteerStatsTab(dateRange: _dateRange),
              _MaintenanceReportTab(dateRange: _dateRange),
              _FleetParticipationTab(dateRange: _dateRange),
              _ConditionsAnalysisTab(dateRange: _dateRange),
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

  Future<void> _exportCsv() async {
    final tabNames = [
      'Season Summary', 'Volunteer Stats', 'Maintenance',
      'Fleet Participation', 'Conditions', 'Checklist Compliance', 'Incidents',
    ];
    final tabName = tabNames[_currentTabIndex];
    final fs = FirebaseFirestore.instance;
    final startTs = Timestamp.fromDate(_dateRange.start);
    final endTs = Timestamp.fromDate(_dateRange.end);
    final buf = StringBuffer();

    try {
      switch (_currentTabIndex) {
        case 0: // Season Summary
          final events = await fs.collection('race_events')
              .where('date', isGreaterThanOrEqualTo: startTs)
              .where('date', isLessThanOrEqualTo: endTs)
              .get();
          buf.writeln('Event Name,Date,Status');
          for (final d in events.docs) {
            final data = d.data();
            buf.writeln('"${data['name'] ?? ''}","${data['date'] != null ? DateFormat.yMMMd().format((data['date'] as Timestamp).toDate()) : ''}","${data['status'] ?? ''}"');
          }
        case 1: // Volunteer Stats
          final docs = await fs.collection('crew_assignments').get();
          buf.writeln('Volunteer Name,Duty Count');
          final countByMember = <String, int>{};
          for (final doc in docs.docs) {
            final name = (doc.data())['memberName'] as String? ?? 'Unknown';
            countByMember[name] = (countByMember[name] ?? 0) + 1;
          }
          final sorted = countByMember.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          for (final e in sorted) {
            buf.writeln('"${e.key}",${e.value}');
          }
        case 2: // Maintenance
          final docs = await fs.collection('maintenance_requests').get();
          buf.writeln('Title,Category,Status,Priority');
          for (final d in docs.docs) {
            final data = d.data();
            buf.writeln('"${data['title'] ?? ''}","${data['category'] ?? ''}","${data['status'] ?? ''}","${data['priority'] ?? ''}"');
          }
        case 3: // Fleet Participation
          final docs = await fs.collection('boats')
              .where('isActive', isEqualTo: true).get();
          buf.writeln('Boat Name,Sail Number,Class,Race Count');
          for (final d in docs.docs) {
            final data = d.data();
            buf.writeln('"${data['boatName'] ?? ''}","${data['sailNumber'] ?? ''}","${data['boatClass'] ?? ''}",${data['raceCount'] ?? 0}');
          }
        case 4: // Conditions
          final docs = await fs.collection('race_events')
              .where('date', isGreaterThanOrEqualTo: startTs)
              .where('date', isLessThanOrEqualTo: endTs)
              .get();
          buf.writeln('Event,Date,Wind (kts),Fleet Size');
          for (final d in docs.docs) {
            final data = d.data();
            final ws = data['weatherSnapshot'] as Map<String, dynamic>?;
            buf.writeln('"${data['name'] ?? ''}","${data['date'] != null ? DateFormat.yMMMd().format((data['date'] as Timestamp).toDate()) : ''}",${ws?['windSpeedKts'] ?? ''},${data['checkinCount'] ?? ''}');
          }
        case 5: // Checklist Compliance
          final docs = await fs.collection('checklist_completions').get();
          buf.writeln('Checklist,Status,Completed At');
          for (final d in docs.docs) {
            final data = d.data();
            buf.writeln('"${data['checklistName'] ?? ''}","${data['status'] ?? ''}","${data['completedAt'] != null ? DateFormat.yMMMd().format((data['completedAt'] as Timestamp).toDate()) : ''}"');
          }
        case 6: // Incidents
          final docs = await fs.collection('incidents').get();
          buf.writeln('Description,Status,Reporter,Rules Alleged,Boats');
          for (final d in docs.docs) {
            final data = d.data();
            final rules = (data['rulesAlleged'] as List?)?.join('; ') ?? '';
            final boats = (data['involvedBoats'] as List?)
                ?.map((b) => '${(b as Map)['sailNumber'] ?? ''}')
                .join('; ') ?? '';
            buf.writeln('"${(data['description'] ?? '').toString().replaceAll('"', '""')}","${data['status'] ?? ''}","${data['reportedBy'] ?? ''}","$rules","$boats"');
          }
      }

      final csv = buf.toString();
      final uri = Uri.dataFromString(csv, mimeType: 'text/csv', encoding: utf8);
      launchUrl(uri);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$tabName CSV exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
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
        fs.collection('checklist_completions').get(),
        fs.collection('maintenance_requests').get(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snap.data![0].docs;
        final checkins = snap.data![1].docs;
        final incidents = snap.data![2].docs;
        final checklists = snap.data![3].docs;
        final maintenance = snap.data![4].docs;

        final eventCount = events.length;
        final avgFleet = eventCount > 0
            ? (checkins.length / eventCount).toStringAsFixed(1)
            : '0';

        // Fleet size per event for chart
        final fleetByEvent = <String, int>{};
        for (final c in checkins) {
          final d = c.data();
          final eid = d['eventId'] ?? '';
          fleetByEvent[eid] = (fleetByEvent[eid] ?? 0) + 1;
        }

        // Incident status breakdown
        final incidentByStatus = <String, int>{};
        for (final i in incidents) {
          final d = i.data();
          final s = d['status'] ?? 'reported';
          incidentByStatus[s] = (incidentByStatus[s] ?? 0) + 1;
        }

        // Checklist completion status
        int checklistComplete = 0, checklistPending = 0;
        for (final c in checklists) {
          final d = c.data();
          if (d['status'] == 'completed') {
            checklistComplete++;
          } else {
            checklistPending++;
          }
        }

        // Maintenance open vs resolved
        int maintOpen = 0, maintResolved = 0;
        for (final m in maintenance) {
          final d = m.data();
          final s = d['status'] ?? '';
          if (s == 'resolved' || s == 'closed') {
            maintResolved++;
          } else {
            maintOpen++;
          }
        }

        final statusColors = <String, Color>{
          'reported': Colors.orange,
          'protestFiled': Colors.red,
          'hearingScheduled': Colors.purple,
          'hearingComplete': Colors.blue,
          'resolved': Colors.green,
          'withdrawn': Colors.grey,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top metrics
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard('Events', '$eventCount', Icons.event, Colors.blue),
                  _MetricCard('Total Check-Ins', '${checkins.length}', Icons.how_to_reg, Colors.teal),
                  _MetricCard('Avg Fleet Size', avgFleet, Icons.sailing, Colors.indigo),
                  _MetricCard('Incidents', '${incidents.length}', Icons.report, Colors.orange),
                  _MetricCard('Maintenance', '${maintenance.length}', Icons.build, Colors.brown),
                  _MetricCard('Checklists', '${checklists.length}', Icons.checklist, Colors.green),
                ],
              ),
              const SizedBox(height: 20),

              // Row of charts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fleet Size per Event (Engagement)
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sailing, size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text('Engagement — Fleet Size per Event',
                                    style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: fleetByEvent.isEmpty
                                  ? const Center(child: Text('No data'))
                                  : BarChart(
                                      BarChartData(
                                        barGroups: fleetByEvent.entries
                                            .toList().asMap().entries
                                            .map((e) => BarChartGroupData(
                                                  x: e.key,
                                                  barRods: [
                                                    BarChartRodData(
                                                      toY: e.value.value.toDouble(),
                                                      color: Colors.blue,
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
                                        gridData: const FlGridData(show: true),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Incident Status Donut (Competition)
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.report, size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text('Competition — Incidents',
                                    style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: incidentByStatus.isEmpty
                                  ? const Center(child: Text('No incidents'))
                                  : PieChart(
                                      PieChartData(
                                        sections: incidentByStatus.entries
                                            .map((e) => PieChartSectionData(
                                                  value: e.value.toDouble(),
                                                  title: '${e.key}\n${e.value}',
                                                  color: statusColors[e.key] ?? Colors.grey,
                                                  titleStyle: const TextStyle(
                                                      fontSize: 9, color: Colors.white),
                                                  radius: 70,
                                                ))
                                            .toList(),
                                        sectionsSpace: 2,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Operations — Checklists + Maintenance
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.checklist, size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Text('Operations',
                                    style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    if (checklistComplete > 0)
                                      PieChartSectionData(
                                        value: checklistComplete.toDouble(),
                                        title: 'Done\n$checklistComplete',
                                        color: Colors.green,
                                        titleStyle: const TextStyle(fontSize: 9, color: Colors.white),
                                        radius: 70,
                                      ),
                                    if (checklistPending > 0)
                                      PieChartSectionData(
                                        value: checklistPending.toDouble(),
                                        title: 'Pending\n$checklistPending',
                                        color: Colors.orange,
                                        titleStyle: const TextStyle(fontSize: 9, color: Colors.white),
                                        radius: 70,
                                      ),
                                    if (maintOpen > 0)
                                      PieChartSectionData(
                                        value: maintOpen.toDouble(),
                                        title: 'Maint Open\n$maintOpen',
                                        color: Colors.red.shade300,
                                        titleStyle: const TextStyle(fontSize: 9, color: Colors.white),
                                        radius: 70,
                                      ),
                                    if (maintResolved > 0)
                                      PieChartSectionData(
                                        value: maintResolved.toDouble(),
                                        title: 'Maint Done\n$maintResolved',
                                        color: Colors.teal,
                                        titleStyle: const TextStyle(fontSize: 9, color: Colors.white),
                                        radius: 70,
                                      ),
                                  ],
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 2 — Volunteer Stats
// ═══════════════════════════════════════════════════════

class _VolunteerStatsTab extends StatelessWidget {
  const _VolunteerStatsTab({required this.dateRange});
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
            _MetricTile('Volunteers', '${sorted.length}'),
            _MetricTile('Avg Duties/Volunteer', avg.toStringAsFixed(1)),
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
          chartTitle: 'Duties per Volunteer (Top 15)',
          table: DataTable(
            columns: const [
              DataColumn(label: Text('Volunteer')),
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
// Tab 5 — Conditions Analysis
// ═══════════════════════════════════════════════════════

class _ConditionsAnalysisTab extends StatelessWidget {
  const _ConditionsAnalysisTab({required this.dateRange});
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    final startTs = Timestamp.fromDate(dateRange.start);
    final endTs = Timestamp.fromDate(dateRange.end);

    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('race_events')
            .where('date', isGreaterThanOrEqualTo: startTs)
            .where('date', isLessThanOrEqualTo: endTs)
            .get(),
        FirebaseFirestore.instance
            .collection('boat_checkins')
            .where('checkedInAt', isGreaterThanOrEqualTo: startTs)
            .where('checkedInAt', isLessThanOrEqualTo: endTs)
            .get(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snap.data![0].docs;
        final checkins = snap.data![1].docs;

        // Build fleet size per event
        final fleetByEvent = <String, int>{};
        for (final c in checkins) {
          final d = c.data();
          final eid = d['eventId'] ?? '';
          fleetByEvent[eid] = (fleetByEvent[eid] ?? 0) + 1;
        }

        // Build event data with weather snapshots
        final eventRows = <_ConditionRow>[];
        for (final e in events) {
          final d = e.data();
          final ws = d['weatherSnapshot'] as Map<String, dynamic>?;
          final wind = (ws?['windSpeedKts'] as num?)?.toDouble();
          final fleet = fleetByEvent[e.id] ?? 0;
          final name = d['name'] ?? '';
          final date = (d['date'] as Timestamp?)?.toDate();
          eventRows.add(_ConditionRow(
            name: name,
            date: date,
            windKts: wind,
            fleetSize: fleet,
          ));
        }

        // Scatter data: wind vs fleet size
        final scatterSpots = eventRows
            .where((r) => r.windKts != null && r.fleetSize > 0)
            .map((r) => FlSpot(r.windKts!, r.fleetSize.toDouble()))
            .toList();

        final avgFleet = eventRows.isNotEmpty
            ? eventRows.map((r) => r.fleetSize).reduce((a, b) => a + b) /
                eventRows.length
            : 0.0;
        final withWind = eventRows.where((r) => r.windKts != null).toList();
        final avgWind = withWind.isNotEmpty
            ? withWind.map((r) => r.windKts!).reduce((a, b) => a + b) /
                withWind.length
            : 0.0;
        final maxWind = withWind.isNotEmpty
            ? withWind.map((r) => r.windKts!).reduce((a, b) => a > b ? a : b)
            : 0.0;

        return _ReportLayout(
          metrics: [
            _MetricTile('Race Days', '${events.length}'),
            _MetricTile('Avg Fleet', avgFleet.toStringAsFixed(1)),
            _MetricTile('Avg Wind', '${avgWind.toStringAsFixed(1)} kts'),
            _MetricTile('Max Wind', '${maxWind.toStringAsFixed(0)} kts'),
          ],
          chart: SizedBox(
            height: 250,
            child: scatterSpots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.air, size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        const Text(
                          'No wind data recorded yet.\n'
                          'Weather snapshots are captured when incidents are reported\n'
                          'or when race events include weather data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ScatterChart(
                    ScatterChartData(
                      scatterSpots: scatterSpots
                          .map((s) => ScatterSpot(s.x, s.y,
                              dotPainter: FlDotCirclePainter(
                                radius: 6,
                                color: Colors.blue.withValues(alpha: 0.7),
                                strokeColor: Colors.blue,
                                strokeWidth: 1,
                              )))
                          .toList(),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          axisNameWidget: Text('Fleet Size',
                              style: TextStyle(fontSize: 10)),
                          sideTitles: SideTitles(
                              showTitles: true, reservedSize: 30),
                        ),
                        bottomTitles: const AxisTitles(
                          axisNameWidget: Text('Wind Speed (kts)',
                              style: TextStyle(fontSize: 10)),
                          sideTitles: SideTitles(
                              showTitles: true, reservedSize: 30),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
          ),
          chartTitle: 'Wind Speed vs Fleet Size — Do high-wind days reduce turnout?',
          table: DataTable(
            columns: const [
              DataColumn(label: Text('Event')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Wind (kts)')),
              DataColumn(label: Text('Fleet Size')),
            ],
            rows: eventRows
                .map((r) => DataRow(cells: [
                      DataCell(Text(r.name)),
                      DataCell(Text(r.date != null
                          ? DateFormat.yMMMd().format(r.date!)
                          : '—')),
                      DataCell(Text(r.windKts?.toStringAsFixed(1) ?? '—')),
                      DataCell(Text('${r.fleetSize}')),
                    ]))
                .toList(),
          ),
        );
      },
    );
  }
}

class _ConditionRow {
  const _ConditionRow({
    required this.name,
    this.date,
    this.windKts,
    required this.fleetSize,
  });
  final String name;
  final DateTime? date;
  final double? windKts;
  final int fleetSize;
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
        // Keep docs grouped by rule for drill-down
        final docsByRule = <String, List<QueryDocumentSnapshot>>{};

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final status = d['status'] as String? ?? '';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          if (status == 'protestFiled' ||
              status == 'hearingScheduled' ||
              status == 'hearingComplete') {
            protests++;
          }
          if (status == 'resolved') {
            resolved++;
          }

          final rules = List<String>.from(d['rulesAlleged'] ?? []);
          for (final r in rules) {
            final ruleNum = r.split(' – ').first;
            rulesCited[ruleNum] = (rulesCited[ruleNum] ?? 0) + 1;
            docsByRule.putIfAbsent(ruleNum, () => []).add(doc);
          }
        }

        final sortedRules = rulesCited.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top10 = sortedRules.take(10).toList();

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
                      barTouchData: BarTouchData(
                        touchCallback: (event, response) {
                          if (event.isInterestedForInteractions &&
                              response?.spot != null) {
                            final idx = response!.spot!.touchedBarGroupIndex;
                            if (idx >= 0 && idx < top10.length) {
                              final rule = top10[idx].key;
                              final matching = docsByRule[rule] ?? [];
                              _showDrillDown(context, 'Rule $rule', matching);
                            }
                          }
                        },
                      ),
                      barGroups: top10.asMap().entries
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
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= top10.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(top10[i].key,
                                  style: const TextStyle(fontSize: 9));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          chartTitle: 'Most Cited Rules (tap bar for details)',
          table: DataTable(
            columns: const [
              DataColumn(label: Text('Rule')),
              DataColumn(label: Text('Times Cited')),
            ],
            rows: sortedRules
                .map((e) => DataRow(
                      cells: [
                        DataCell(Text(e.key)),
                        DataCell(Text('${e.value}')),
                      ],
                      onSelectChanged: (_) {
                        final matching = docsByRule[e.key] ?? [];
                        _showDrillDown(context, 'Rule ${e.key}', matching);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  static void _showDrillDown(
      BuildContext context, String title, List<QueryDocumentSnapshot> docs) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$title — ${docs.length} incident${docs.length == 1 ? '' : 's'}'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: docs.isEmpty
              ? const Center(child: Text('No matching incidents'))
              : ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final desc = d['description'] as String? ?? '';
                    final status = d['status'] as String? ?? '';
                    final reporter = d['reportedBy'] as String? ?? '';
                    final boats = (d['involvedBoats'] as List?)
                            ?.map((b) =>
                                '${(b as Map)['sailNumber'] ?? ''} ${(b)['boatName'] ?? ''}')
                            .join(', ') ??
                        '';
                    return Card(
                      child: ListTile(
                        title: Text(desc,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            'Status: $status · Reporter: $reporter\nBoats: $boats',
                            style: const TextStyle(fontSize: 11)),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
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
