import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/boat.dart';
import '../../data/models/boat_checkin.dart';
import '../boat_checkin_providers.dart';

class BoatCheckinScreen extends ConsumerStatefulWidget {
  const BoatCheckinScreen({super.key, required this.eventId, this.eventName});

  final String eventId;
  final String? eventName;

  @override
  ConsumerState<BoatCheckinScreen> createState() => _BoatCheckinScreenState();
}

class _BoatCheckinScreenState extends ConsumerState<BoatCheckinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkinsAsync = ref.watch(eventCheckinsProvider(widget.eventId));
    final closedAsync = ref.watch(checkinsClosedProvider(widget.eventId));
    final count = ref.watch(checkinCountProvider(widget.eventId));
    final isClosed = closedAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.eventName ?? 'Race Day Check-In',
                style: const TextStyle(fontSize: 16)),
            Text('$count boats checked in',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
        actions: [
          if (!isClosed)
            TextButton.icon(
              onPressed: _closeCheckins,
              icon: const Icon(Icons.lock, size: 18),
              label: const Text('Close'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Check-in count hero
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    const Text('boats\nchecked in',
                        style: TextStyle(fontSize: 12)),
                    if (isClosed) ...[
                      const SizedBox(width: 16),
                      const Chip(
                        label: Text('CLOSED',
                            style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Checked In'),
                  Tab(text: 'Fleet'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sail number or boat name...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Checked In tab
                _CheckedInTab(
                  eventId: widget.eventId,
                  searchQuery: _searchQuery,
                ),
                // Fleet tab
                _FleetTab(
                  eventId: widget.eventId,
                  searchQuery: _searchQuery,
                  isClosed: isClosed,
                  onCheckinTap: _showCheckinSheet,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isClosed
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCheckinSheet(null),
              icon: const Icon(Icons.add),
              label: const Text('Add New Boat'),
            ),
    );
  }

  void _showCheckinSheet(Boat? boat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _CheckinFormSheet(
          eventId: widget.eventId,
          boat: boat,
          ref: ref,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _closeCheckins() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close Check-In?'),
        content: const Text(
            'No more boats will be able to check in. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Close Check-In')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(boatCheckinRepositoryProvider)
        .closeCheckins(widget.eventId);
  }
}

class _CheckedInTab extends ConsumerWidget {
  const _CheckedInTab({required this.eventId, required this.searchQuery});

  final String eventId;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(eventCheckinsProvider(eventId));

    return checkinsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (checkins) {
        var filtered = checkins;
        if (searchQuery.isNotEmpty) {
          filtered = checkins
              .where((c) =>
                  c.sailNumber.toLowerCase().contains(searchQuery) ||
                  c.boatName.toLowerCase().contains(searchQuery) ||
                  c.skipperName.toLowerCase().contains(searchQuery))
              .toList();
        }

        if (filtered.isEmpty) {
          return const Center(child: Text('No boats checked in yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final c = filtered[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(c.sailNumber.length > 3
                      ? c.sailNumber.substring(c.sailNumber.length - 3)
                      : c.sailNumber,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                title: Row(
                  children: [
                    Text(c.boatName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('(${c.sailNumber})',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Text(c.skipperName),
                    const SizedBox(width: 8),
                    Text(DateFormat.Hm().format(c.checkedInAt),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.safetyEquipmentVerified)
                      const Icon(Icons.verified_user,
                          color: Colors.green, size: 20),
                    if (c.phrfRating != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Chip(
                          label: Text('${c.phrfRating}',
                              style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: Colors.red.shade300, size: 22),
                      tooltip: 'Remove check-in',
                      onPressed: () => _confirmRemove(context, ref, c),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, BoatCheckin checkin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Check-In?'),
        content: Text(
            'Remove ${checkin.boatName} (${checkin.sailNumber}) from check-in?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(boatCheckinRepositoryProvider)
          .removeCheckin(checkin.id);
      ref.invalidate(eventCheckinsProvider(eventId));
      ref.invalidate(boatsNotCheckedInProvider(eventId));
    }
  }
}

class _FleetTab extends ConsumerWidget {
  const _FleetTab({
    required this.eventId,
    required this.searchQuery,
    required this.isClosed,
    required this.onCheckinTap,
  });

  final String eventId;
  final String searchQuery;
  final bool isClosed;
  final void Function(Boat?) onCheckinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boatsAsync = ref.watch(boatsNotCheckedInProvider(eventId));

    return boatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (boats) {
        var filtered = boats;
        if (searchQuery.isNotEmpty) {
          filtered = boats
              .where((b) =>
                  b.sailNumber.toLowerCase().contains(searchQuery) ||
                  b.boatName.toLowerCase().contains(searchQuery) ||
                  b.ownerName.toLowerCase().contains(searchQuery))
              .toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sailing, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(searchQuery.isNotEmpty
                    ? 'No matching boats'
                    : 'All known boats are checked in!'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final b = filtered[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Text(b.sailNumber.length > 3
                      ? b.sailNumber.substring(b.sailNumber.length - 3)
                      : b.sailNumber,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                title: Text('${b.boatName} (${b.sailNumber})'),
                subtitle: Text('${b.ownerName} • ${b.boatClass}'),
                trailing: isClosed
                    ? const Icon(Icons.lock, color: Colors.grey, size: 18)
                    : FilledButton(
                        onPressed: () => onCheckinTap(b),
                        child: const Text('Check In'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CheckinFormSheet extends StatefulWidget {
  const _CheckinFormSheet({
    required this.eventId,
    required this.boat,
    required this.ref,
    required this.scrollController,
  });

  final String eventId;
  final Boat? boat;
  final WidgetRef ref;
  final ScrollController scrollController;

  @override
  State<_CheckinFormSheet> createState() => _CheckinFormSheetState();
}

class _CheckinFormSheetState extends State<_CheckinFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sailCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skipperCtrl;
  late final TextEditingController _classCtrl;
  late final TextEditingController _crewCountCtrl;
  late final TextEditingController _phrfCtrl;
  bool _safetyVerified = false;

  List<Boat> _fleet = [];
  Boat? _selectedFleetBoat;
  bool _isNewBoat = false;

  @override
  void initState() {
    super.initState();
    _sailCtrl = TextEditingController(text: widget.boat?.sailNumber ?? '');
    _nameCtrl = TextEditingController(text: widget.boat?.boatName ?? '');
    _skipperCtrl = TextEditingController(text: widget.boat?.ownerName ?? '');
    _classCtrl = TextEditingController(text: widget.boat?.boatClass ?? '');
    _crewCountCtrl = TextEditingController(text: '1');
    _phrfCtrl = TextEditingController(
        text: widget.boat?.phrfRating?.toString() ?? '');

    if (widget.boat != null) {
      _selectedFleetBoat = widget.boat;
    }
    _loadFleet();
  }

  Future<void> _loadFleet() async {
    final fleet = widget.ref.read(fleetProvider).value ?? [];
    if (mounted) {
      setState(() => _fleet = fleet);
    }
  }

  void _selectFleetBoat(Boat? boat) {
    if (boat == null) {
      setState(() {
        _isNewBoat = true;
        _selectedFleetBoat = null;
        _sailCtrl.text = '';
        _nameCtrl.text = '';
        _skipperCtrl.text = '';
        _classCtrl.text = '';
        _phrfCtrl.text = '';
      });
    } else {
      setState(() {
        _isNewBoat = false;
        _selectedFleetBoat = boat;
        _sailCtrl.text = boat.sailNumber;
        _nameCtrl.text = boat.boatName;
        _skipperCtrl.text = boat.ownerName;
        _classCtrl.text = boat.boatClass;
        _phrfCtrl.text = boat.phrfRating?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _sailCtrl.dispose();
    _nameCtrl.dispose();
    _skipperCtrl.dispose();
    _classCtrl.dispose();
    _crewCountCtrl.dispose();
    _phrfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Check In Boat',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // Fleet dropdown — select from existing boats or add new
          if (widget.boat == null) ...[
            DropdownButtonFormField<String>(
              value: _selectedFleetBoat?.id,
              decoration: const InputDecoration(
                labelText: 'Select from Fleet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sailing),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '__new__',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Add New Boat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                ..._fleet.map((b) => DropdownMenuItem<String>(
                      value: b.id,
                      child: Text(
                        '${b.sailNumber} — ${b.boatName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (val) {
                if (val == '__new__') {
                  _selectFleetBoat(null);
                } else if (val != null) {
                  final boat = _fleet.firstWhere((b) => b.id == val);
                  _selectFleetBoat(boat);
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _sailCtrl,
            decoration: const InputDecoration(
              labelText: 'Sail Number *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Boat Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _skipperCtrl,
            decoration: const InputDecoration(
              labelText: 'Skipper *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _classCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _crewCountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Crew #',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _phrfCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'PHRF Rating (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          CheckboxListTile(
            value: _safetyVerified,
            onChanged: (v) => setState(() => _safetyVerified = v ?? false),
            title: const Text('Safety Equipment Verified'),
            subtitle: const Text(
                'PFDs, throwable, horn/whistle, fire extinguisher'),
            controlAffinity: ListTileControlAffinity.leading,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('CHECK IN',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final boatId = _selectedFleetBoat?.id ?? '';

    final checkin = BoatCheckin(
      id: '',
      eventId: widget.eventId,
      boatId: boatId,
      sailNumber: _sailCtrl.text.trim(),
      boatName: _nameCtrl.text.trim(),
      skipperName: _skipperCtrl.text.trim(),
      boatClass: _classCtrl.text.trim(),
      checkedInAt: DateTime.now(),
      checkedInBy: 'PRO',
      crewCount: int.tryParse(_crewCountCtrl.text) ?? 1,
      safetyEquipmentVerified: _safetyVerified,
      phrfRating: int.tryParse(_phrfCtrl.text),
    );

    await widget.ref
        .read(boatCheckinRepositoryProvider)
        .checkInBoat(checkin);

    // If new boat (not from fleet), also save to fleet
    if (_isNewBoat || (widget.boat == null && _selectedFleetBoat == null)) {
      await widget.ref.read(boatCheckinRepositoryProvider).saveBoat(Boat(
            id: '',
            sailNumber: _sailCtrl.text.trim(),
            boatName: _nameCtrl.text.trim(),
            ownerName: _skipperCtrl.text.trim(),
            boatClass: _classCtrl.text.trim(),
            phrfRating: int.tryParse(_phrfCtrl.text),
          ));
    }

    // Invalidate the not-checked-in list
    widget.ref.invalidate(boatsNotCheckedInProvider(widget.eventId));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_nameCtrl.text.trim()} (${_sailCtrl.text.trim()}) checked in!')),
      );
    }
  }
}
