import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course_config.dart';
import '../../data/models/mark.dart';
import '../../data/models/mark_distance.dart';
import '../courses_providers.dart';
import '../widgets/course_map_diagram.dart';

class CourseConfigurationPage extends ConsumerStatefulWidget {
  const CourseConfigurationPage({super.key});

  @override
  ConsumerState<CourseConfigurationPage> createState() =>
      _CourseConfigurationPageState();
}

class _CourseConfigurationPageState
    extends ConsumerState<CourseConfigurationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
              Text('Course Configuration',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _seedCourses,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Seed Courses'),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Courses'),
            Tab(text: 'By Wind Direction'),
            Tab(text: 'Marks & Distances'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AllCoursesTab(
                searchQuery: _searchQuery,
                onSearchChanged: (q) => setState(() => _searchQuery = q),
              ),
              const _ByWindTab(),
              const _MarksTab(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _seedCourses() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seed Course Data?'),
        content: const Text(
            'This will populate Firestore with all 57 MPYC courses, marks, and distance data. Existing data will be overwritten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Seed')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final jsonStr = await DefaultAssetBundle.of(context)
          .loadString('assets/courses_seed.json');
      await ref.read(coursesRepositoryProvider).seedFromJson(jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course data seeded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seed error: $e')),
        );
      }
    }
  }
}

class _AllCoursesTab extends ConsumerWidget {
  const _AllCoursesTab({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (courses) {
        var filtered = courses;
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = courses
              .where((c) =>
                  c.courseNumber.toLowerCase().contains(q) ||
                  c.courseName.toLowerCase().contains(q) ||
                  c.windDirectionBand.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Mark Sequence')),
                      DataColumn(label: Text('Dist (nm)')),
                      DataColumn(label: Text('Wind Band')),
                      DataColumn(label: Text('Finish At')),
                      DataColumn(label: Text('x2/x3')),
                      DataColumn(label: Text('Inflatable')),
                    ],
                    rows: filtered.map((c) {
                      return DataRow(cells: [
                        DataCell(Text(c.courseNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold))),
                        DataCell(
                          SizedBox(
                            width: 280,
                            child: Text(c.markSequenceDisplay,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        DataCell(Text(c.distanceNm.toStringAsFixed(1))),
                        DataCell(_bandChip(c.windDirectionBand)),
                        DataCell(Text(c.finishLocation == 'mark_x'
                            ? 'Mark X'
                            : 'CB')),
                        DataCell(
                            c.canMultiply
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.green)
                                : const SizedBox.shrink()),
                        DataCell(c.requiresInflatable
                            ? Text(c.inflatableType ?? 'Yes',
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 12))
                            : const SizedBox.shrink()),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bandChip(String band) {
    final (label, color) = switch (band) {
      'S_SW' => ('S/SW', Colors.red),
      'W' => ('W', Colors.orange),
      'NW' => ('NW', Colors.blue),
      'N' => ('N', Colors.purple),
      'N_EXT' => ('N+', Colors.purple),
      'INFLATABLE' => ('Infl.', Colors.teal),
      'LONG' => ('Long', Colors.brown),
      _ => (band, Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.15),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ByWindTab extends ConsumerWidget {
  const _ByWindTab();

  static const _windBands = [
    ('S_SW', 'S/SW (200-260°)', Colors.red),
    ('W', 'W (260-295°)', Colors.orange),
    ('NW', 'NW (295-320°)', Colors.blue),
    ('N', 'N (320-020°)', Colors.purple),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (courses) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wind quadrants
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _windBands.map((wb) {
                  final (band, label, color) = wb;
                  final bandCourses = courses
                      .where((c) =>
                          c.windDirectionBand == band ||
                          (band == 'N' && c.windDirectionBand == 'N_EXT'))
                      .toList()
                    ..sort((a, b) =>
                        a.distanceNm.compareTo(b.distanceNm));

                  return SizedBox(
                    width: 340,
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            color: color.withValues(alpha: 0.1),
                            child: Text(label,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color)),
                          ),
                          ...bandCourses.map((c) => ListTile(
                                dense: true,
                                title: Text(
                                  '#${c.courseNumber} — ${c.distanceNm} nm',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  c.markSequenceDisplay,
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: c.requiresInflatable
                                    ? const Icon(Icons.warning_amber,
                                        size: 16, color: Colors.orange)
                                    : null,
                              )),
                          if (bandCourses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No courses',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Inflatable and Long sections
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            color: Colors.teal.withValues(alpha: 0.1),
                            child: const Text('Inflatable Courses (A-E)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal)),
                          ),
                          ...courses
                              .where(
                                  (c) => c.windDirectionBand == 'INFLATABLE')
                              .map((c) => ListTile(
                                    dense: true,
                                    title: Text(
                                        '#${c.courseNumber} — ${c.markSequenceDisplay}'),
                                    subtitle: Text(
                                        'Requires: ${c.inflatableType ?? "inflatables"}'),
                                  )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            color: Colors.brown.withValues(alpha: 0.1),
                            child: const Text('Long Races (49-52)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown)),
                          ),
                          ...courses
                              .where((c) => c.windDirectionBand == 'LONG')
                              .map((c) => ListTile(
                                    dense: true,
                                    title: Text(
                                        '#${c.courseNumber} — ${c.distanceNm} nm'),
                                    subtitle:
                                        Text(c.markSequenceDisplay),
                                  )),
                        ],
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

class _MarksTab extends ConsumerWidget {
  const _MarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(marksProvider);
    final distancesAsync = ref.watch(markDistancesProvider);

    return Row(
      children: [
        // Marks list
        SizedBox(
          width: 280,
          child: Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(),
            child: marksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (marks) {
                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Marks',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...marks.map((m) => ListTile(
                          dense: true,
                          leading: Icon(
                            m.type == 'inflatable'
                                ? Icons.circle
                                : Icons.location_on,
                            color: m.type == 'inflatable'
                                ? Colors.orange
                                : Colors.blue,
                            size: 18,
                          ),
                          title: Text(m.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.type,
                                  style: const TextStyle(fontSize: 11)),
                              if (m.latitude != null)
                                Text(
                                  '${m.latitude!.toStringAsFixed(4)}°N, ${m.longitude!.toStringAsFixed(4)}°W',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              if (m.description != null)
                                Text(m.description!,
                                    style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          ),
        ),

        // Distance/heading table
        Expanded(
          child: distancesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (distances) {
              // Build matrix
              final markIds = <String>{};
              for (final d in distances) {
                markIds.add(d.fromMarkId);
                markIds.add(d.toMarkId);
              }
              final sortedIds = markIds.toList()..sort();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distance / Heading Chart',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        defaultColumnWidth: const FixedColumnWidth(90),
                        children: [
                          // Header row
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(6),
                                child: Text('FROM \\ TO',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10)),
                              ),
                              ...sortedIds.map((id) => Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(id,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10)),
                                  )),
                            ],
                          ),
                          // Data rows
                          ...sortedIds.map((fromId) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(fromId,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10)),
                                ),
                                ...sortedIds.map((toId) {
                                  if (fromId == toId) {
                                    return Container(
                                      padding: const EdgeInsets.all(6),
                                      color: Colors.grey.shade200,
                                      child: const Text('—',
                                          style: TextStyle(fontSize: 10)),
                                    );
                                  }
                                  final dist = distances
                                      .where((d) =>
                                          d.fromMarkId == fromId &&
                                          d.toMarkId == toId)
                                      .firstOrNull;
                                  return Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: dist != null
                                        ? Text(
                                            '${dist.distanceNm.toStringAsFixed(2)}\n${dist.headingMagnetic.toStringAsFixed(0)}°',
                                            style:
                                                const TextStyle(fontSize: 10),
                                          )
                                        : const Text('—',
                                            style: TextStyle(fontSize: 10)),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
