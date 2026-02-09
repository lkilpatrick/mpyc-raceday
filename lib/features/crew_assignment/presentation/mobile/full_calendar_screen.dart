import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crew_assignment_providers.dart';

class FullCalendarScreen extends ConsumerStatefulWidget {
  const FullCalendarScreen({super.key});

  @override
  ConsumerState<FullCalendarScreen> createState() => _FullCalendarScreenState();
}

class _FullCalendarScreenState extends ConsumerState<FullCalendarScreen> {
  DateTime _focused = DateTime.now();
  String _series = 'All';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _series,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All series')),
                    DropdownMenuItem(
                      value: 'Spring Series',
                      child: Text('Spring Series'),
                    ),
                    DropdownMenuItem(
                      value: 'Summer Series',
                      child: Text('Summer Series'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _series = value ?? 'All'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (events) {
              final monthStart = DateTime(_focused.year, _focused.month, 1);
              final dayCount = DateUtils.getDaysInMonth(
                _focused.year,
                _focused.month,
              );
              final filtered = events.where((event) {
                if (_series == 'All') return true;
                return event.seriesName == _series;
              }).toList();

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      '${_focused.year}-${_focused.month.toString().padLeft(2, '0')}',
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        _focused = DateTime(
                          _focused.year,
                          _focused.month - 1,
                          1,
                        );
                      }),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() {
                        _focused = DateTime(
                          _focused.year,
                          _focused.month + 1,
                          1,
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      itemCount: dayCount,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.2,
                          ),
                      itemBuilder: (context, index) {
                        final day = monthStart.add(Duration(days: index));
                        final hasEvent = filtered.any(
                          (e) =>
                              e.date.year == day.year &&
                              e.date.month == day.month &&
                              e.date.day == day.day,
                        );

                        return InkWell(
                          onTap: () => _showDayEvents(context, day, filtered),
                          child: Card(
                            margin: const EdgeInsets.all(4),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${day.day}'),
                                  const Spacer(),
                                  if (hasEvent)
                                    const Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: Colors.blue,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDayEvents(
    BuildContext context,
    DateTime day,
    List<dynamic> events,
  ) {
    final dayEvents = events.where(
      (e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day,
    );

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Events on ${day.month}/${day.day}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...dayEvents.map(
            (e) => ListTile(title: Text(e.name), subtitle: Text(e.seriesName)),
          ),
          if (dayEvents.isEmpty) const Text('No events'),
        ],
      ),
    );
  }
}
