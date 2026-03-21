import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

enum _TrainingStatus { planned, ongoing, completed }

class _TrainingSessionItem {
  const _TrainingSessionItem({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.focus,
    required this.location,
    required this.assignedPlayers,
    required this.status,
    this.notes = '',
  });

  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay startTime;
  final int durationMinutes;
  final String focus;
  final String location;
  final int assignedPlayers;
  final _TrainingStatus status;
  final String notes;

  _TrainingSessionItem copyWith({
    String? id,
    String? title,
    DateTime? date,
    TimeOfDay? startTime,
    int? durationMinutes,
    String? focus,
    String? location,
    int? assignedPlayers,
    _TrainingStatus? status,
    String? notes,
  }) {
    return _TrainingSessionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      focus: focus ?? this.focus,
      location: location ?? this.location,
      assignedPlayers: assignedPlayers ?? this.assignedPlayers,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

DateTime _sessionStartDateTime(_TrainingSessionItem session) {
  return DateTime(
    session.date.year,
    session.date.month,
    session.date.day,
    session.startTime.hour,
    session.startTime.minute,
  );
}

DateTime _sessionEndDateTime(_TrainingSessionItem session) {
  return _sessionStartDateTime(
    session,
  ).add(Duration(minutes: session.durationMinutes));
}

_TrainingStatus _effectiveStatus(_TrainingSessionItem session) {
  final now = DateTime.now();
  final start = _sessionStartDateTime(session);
  final end = _sessionEndDateTime(session);

  if (!now.isBefore(end)) {
    return _TrainingStatus.completed;
  }
  if (!now.isBefore(start)) {
    return _TrainingStatus.ongoing;
  }
  return _TrainingStatus.planned;
}

const String _trainingMetaMarker = '\n\n[FTM_META]\n';

String _serializeDescription(_TrainingSessionItem session) {
  final payload = <String, dynamic>{
    'focus': session.focus,
    'location': session.location,
    'assigned_players': session.assignedPlayers,
    'duration_minutes': session.durationMinutes,
    'status': _statusKey(session.status),
    'notes': session.notes.trim(),
  };
  return '${session.notes.trim()}$_trainingMetaMarker${jsonEncode(payload)}';
}

({String notes, Map<String, dynamic> meta}) _deserializeDescription(
  String description,
) {
  final markerIndex = description.indexOf(_trainingMetaMarker);
  if (markerIndex == -1) {
    return (notes: description.trim(), meta: <String, dynamic>{});
  }

  final notes = description.substring(0, markerIndex).trim();
  final metaRaw = description.substring(
    markerIndex + _trainingMetaMarker.length,
  );

  try {
    final decoded = jsonDecode(metaRaw);
    if (decoded is Map<String, dynamic>) {
      return (notes: notes, meta: decoded);
    }
  } catch (_) {}

  return (notes: notes, meta: <String, dynamic>{});
}

String _statusKey(_TrainingStatus status) {
  switch (status) {
    case _TrainingStatus.planned:
      return 'planned';
    case _TrainingStatus.ongoing:
      return 'ongoing';
    case _TrainingStatus.completed:
      return 'completed';
  }
}

_TrainingStatus _statusFromKey(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'ongoing':
      return _TrainingStatus.ongoing;
    case 'completed':
      return _TrainingStatus.completed;
    default:
      return _TrainingStatus.planned;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.showButton,
    required this.isSaving,
    required this.onCreatePressed,
  });

  final bool showButton;
  final bool isSaving;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Training Sessions',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Plan and manage your team sessions',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final action = showButton
            ? ElevatedButton.icon(
                onPressed: isSaving ? null : onCreatePressed,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(isSaving ? 'Saving...' : 'Create Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ED6B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            : const SizedBox.shrink();

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (showButton) ...[
                const SizedBox(height: 14),
                action,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            action,
          ],
        );
      },
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.totalSessions,
    required this.upcomingSessions,
    required this.completedSessions,
  });

  final int totalSessions;
  final int upcomingSessions;
  final int completedSessions;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        label: 'Total Sessions',
        value: '$totalSessions',
        icon: Icons.calendar_month_rounded,
        accent: const Color(0xFF1ED6B0),
        background: const Color(0xFFE8F7F3),
      ),
      _SummaryCardData(
        label: 'Upcoming',
        value: '$upcomingSessions',
        icon: Icons.schedule_rounded,
        accent: const Color(0xFF2563EB),
        background: const Color(0xFFDBEAFE),
      ),
      _SummaryCardData(
        label: 'Completed',
        value: '$completedSessions',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF0F9D65),
        background: const Color(0xFFDCFCE7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        final isMedium = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: _SummaryCard(data: cards[i])),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        if (isMedium) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: _SummaryCard(data: card),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              _SummaryCard(data: cards[i]),
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accent),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _TrainingStatus? selectedFilter;
  final ValueChanged<_TrainingStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: 'All',
            selected: selectedFilter == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final status in _TrainingStatus.values) ...[
            _FilterChipButton(
              label: _statusLabel(status),
              selected: selectedFilter == status,
              onTap: () => onSelected(status),
            ),
            if (status != _TrainingStatus.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1ED6B0) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1ED6B0)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final _TrainingSessionItem session;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.calendar_today_outlined,
                          label: _formatDate(session.date),
                        ),
                        _InfoPill(
                          icon: Icons.schedule_outlined,
                          label:
                              '${_formatTime(session.startTime)} - ${session.durationMinutes} min',
                        ),
                        _InfoPill(
                          icon: Icons.sports_soccer_outlined,
                          label: session.focus,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: _effectiveStatus(session)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _MetaItem(
                icon: Icons.place_outlined,
                label: session.location,
              ),
              _MetaItem(
                icon: Icons.group_outlined,
                label: '${session.assignedPlayers} players assigned',
              ),
            ],
          ),
          if (session.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              session.notes.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View'),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _TrainingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              color: Color(0xFF1ED6B0),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sessions found for this view',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first training session to organize upcoming work for the squad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create First Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ED6B0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailsSheet extends StatelessWidget {
  const _SessionDetailsSheet({required this.session});

  final _TrainingSessionItem session;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Session overview and coaching notes',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: _effectiveStatus(session)),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DetailCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    value: _formatDate(session.date),
                  ),
                  _DetailCard(
                    icon: Icons.schedule_outlined,
                    title: 'Time',
                    value: _formatTime(session.startTime),
                  ),
                  _DetailCard(
                    icon: Icons.timer_outlined,
                    title: 'Duration',
                    value: '${session.durationMinutes} minutes',
                  ),
                  _DetailCard(
                    icon: Icons.sports_soccer_outlined,
                    title: 'Focus',
                    value: session.focus,
                  ),
                  _DetailCard(
                    icon: Icons.place_outlined,
                    title: 'Location',
                    value: session.location,
                  ),
                  _DetailCard(
                    icon: Icons.group_outlined,
                    title: 'Assigned Players',
                    value: '${session.assignedPlayers}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      session.notes.trim().isEmpty
                          ? 'No session notes were added yet.'
                          : session.notes.trim(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1ED6B0), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingSessionFormDialog extends StatefulWidget {
  const _TrainingSessionFormDialog({this.session});

  final _TrainingSessionItem? session;

  @override
  State<_TrainingSessionFormDialog> createState() =>
      _TrainingSessionFormDialogState();
}

class _TrainingSessionFormDialogState extends State<_TrainingSessionFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _locationController;
  late final TextEditingController _assignedPlayersController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedFocus;
  late _TrainingStatus _selectedStatus;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _titleController = TextEditingController(text: session?.title ?? '');
    _durationController = TextEditingController(
      text: session?.durationMinutes.toString() ?? '90',
    );
    _locationController = TextEditingController(text: session?.location ?? '');
    _assignedPlayersController = TextEditingController(
      text: session?.assignedPlayers.toString() ?? '20',
    );
    _notesController = TextEditingController(text: session?.notes ?? '');
    _selectedDate = session?.date ?? DateTime.now();
    _selectedTime =
        session?.startTime ?? const TimeOfDay(hour: 10, minute: 0);
    _selectedFocus = session?.focus ?? _TrainingPageState._focusOptions.first;
    _selectedStatus = session != null
        ? _effectiveStatus(session)
        : _TrainingStatus.planned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _assignedPlayersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;
    setState(() {
      _selectedTime = picked;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final session = _TrainingSessionItem(
      id: widget.session?.id ?? '',
      title: _titleController.text.trim(),
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      startTime: _selectedTime,
      durationMinutes: int.parse(_durationController.text.trim()),
      focus: _selectedFocus,
      location: _locationController.text.trim(),
      assignedPlayers: int.parse(_assignedPlayersController.text.trim()),
      status: _selectedStatus,
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Edit Session' : 'Create Session',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Build a clear plan for the squad and keep session details organized.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Defensive Transition Drill',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 520;
                      final dateButton = _PickerField(
                        label: 'Date',
                        value: _formatDate(_selectedDate),
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      );
                      final timeButton = _PickerField(
                        label: 'Time',
                        value: _formatTime(_selectedTime),
                        icon: Icons.schedule_outlined,
                        onTap: _pickTime,
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            dateButton,
                            const SizedBox(height: 12),
                            timeButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: dateButton),
                          const SizedBox(width: 12),
                          Expanded(child: timeButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 520;
                      final durationField = TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid duration';
                          }
                          return null;
                        },
                      );
                      final playersField = TextFormField(
                        controller: _assignedPlayersController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Players',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            durationField,
                            const SizedBox(height: 12),
                            playersField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: durationField),
                          const SizedBox(width: 12),
                          Expanded(child: playersField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFocus,
                    decoration: const InputDecoration(
                      labelText: 'Focus / Category',
                    ),
                    items: _TrainingPageState._focusOptions
                        .map(
                          (focus) => DropdownMenuItem<String>(
                            value: focus,
                            child: Text(focus),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedFocus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. Main Training Pitch',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_TrainingStatus>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _TrainingStatus.values
                        .map(
                          (status) => DropdownMenuItem<_TrainingStatus>(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText:
                          'Add key objectives, drill notes, or coaching reminders',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: Icon(
                            _isEditing ? Icons.save_outlined : Icons.add,
                          ),
                          label: Text(
                            _isEditing ? 'Save Changes' : 'Create Session',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1ED6B0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

String _statusLabel(_TrainingStatus status) {
  switch (status) {
    case _TrainingStatus.planned:
      return 'Planned';
    case _TrainingStatus.ongoing:
      return 'Ongoing';
    case _TrainingStatus.completed:
      return 'Completed';
  }
}

_StatusPalette _statusColors(_TrainingStatus status) {
  switch (status) {
    case _TrainingStatus.planned:
      return const _StatusPalette(
        background: Color(0xFFDBEAFE),
        foreground: Color(0xFF1D4ED8),
      );
    case _TrainingStatus.ongoing:
      return const _StatusPalette(
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFFB45309),
      );
    case _TrainingStatus.completed:
      return const _StatusPalette(
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
      );
  }
}

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

class _TrainingPageState extends State<TrainingPage> {
  static const List<String> _focusOptions = <String>[
    'Tactical',
    'Technical',
    'Fitness',
    'Attacking',
    'Defensive',
    'Recovery',
  ];

  final ApiClient _api = ApiClient.instance;

  final List<_TrainingSessionItem> _sessions = <_TrainingSessionItem>[
    _TrainingSessionItem(
      id: 'ts-1',
      title: 'Press Resistance Build-Up',
      date: DateTime(2026, 3, 22),
      startTime: const TimeOfDay(hour: 10, minute: 0),
      durationMinutes: 90,
      focus: 'Tactical',
      location: 'Main Training Pitch',
      assignedPlayers: 22,
      status: _TrainingStatus.planned,
      notes:
          'Focus on escaping the first line of pressure and finding the free midfielder in zone 14.',
    ),
    _TrainingSessionItem(
      id: 'ts-2',
      title: 'Final Third Combination Play',
      date: DateTime(2026, 3, 21),
      startTime: const TimeOfDay(hour: 15, minute: 30),
      durationMinutes: 75,
      focus: 'Attacking',
      location: 'Pitch 2',
      assignedPlayers: 18,
      status: _TrainingStatus.ongoing,
      notes:
          'Pattern work between wingers, fullbacks, and attacking midfielder with quick finishes.',
    ),
    _TrainingSessionItem(
      id: 'ts-3',
      title: 'Defensive Shape and Compactness',
      date: DateTime(2026, 3, 20),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      durationMinutes: 80,
      focus: 'Defensive',
      location: 'Indoor Analysis Room',
      assignedPlayers: 24,
      status: _TrainingStatus.completed,
      notes:
          'Back four distances, midfield line support, and rest-defense triggers were reviewed.',
    ),
    _TrainingSessionItem(
      id: 'ts-4',
      title: 'Explosive Speed and Recovery',
      date: DateTime(2026, 3, 24),
      startTime: const TimeOfDay(hour: 11, minute: 15),
      durationMinutes: 60,
      focus: 'Fitness',
      location: 'Performance Center',
      assignedPlayers: 16,
      status: _TrainingStatus.planned,
      notes:
          'Short acceleration blocks followed by individualized recovery protocols.',
    ),
  ];

  _TrainingStatus? _selectedFilter;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _teamId;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      final data = error.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
      return 'API error ${error.status}';
    }
    return error.toString();
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  _TrainingSessionItem _sessionFromApi(Map<String, dynamic> data) {
    final rawDate = (data['date'] as String? ?? '').trim();
    final parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    final description = (data['description'] as String? ?? '').trim();
    final parsedDescription = _deserializeDescription(description);
    final meta = parsedDescription.meta;

    return _TrainingSessionItem(
      id: '${data['id']}',
      title: (data['title'] as String? ?? 'Untitled Session').trim(),
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      startTime: TimeOfDay(
        hour: parsedDate.hour,
        minute: parsedDate.minute,
      ),
      durationMinutes: _toInt(meta['duration_minutes'], fallback: 90),
      focus: (meta['focus'] as String? ?? _focusOptions.first).trim(),
      location: (meta['location'] as String? ?? 'Training Ground').trim(),
      assignedPlayers: _toInt(meta['assigned_players'], fallback: 0),
      status: _statusFromKey(meta['status'] as String?),
      notes: parsedDescription.notes,
    );
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profileRes = await _api.get('/profile');
      final profileData = profileRes is Map<String, dynamic>
          ? profileRes['data']
          : null;
      final teamData = profileData is Map<String, dynamic>
          ? profileData['team']
          : null;
      final teamId = teamData is Map<String, dynamic> ? teamData['id'] : null;

      if (teamId == null) {
        throw Exception('No team found for the authenticated coach');
      }

      final sessionsRes = await _api.get('/training-sessions');
      final list = sessionsRes is Map<String, dynamic>
          ? (sessionsRes['data'] as List<dynamic>? ?? <dynamic>[])
          : sessionsRes is List
          ? sessionsRes
          : <dynamic>[];

      final sessions = list
          .whereType<Map<String, dynamic>>()
          .map(_sessionFromApi)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (!mounted) return;
      setState(() {
        _teamId = _toInt(teamId, fallback: 0);
        _sessions
          ..clear()
          ..addAll(sessions);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _saveSessionToBackend(
    _TrainingSessionItem session, {
    _TrainingSessionItem? existing,
  }) async {
    final payload = <String, dynamic>{
      'title': session.title,
      'description': _serializeDescription(session),
      'date': _sessionStartDateTime(session).toIso8601String(),
    };

    if (existing == null) {
      final teamId = _teamId;
      if (teamId == null || teamId <= 0) {
        throw Exception('No active team available for this coach');
      }
      payload['team_id'] = teamId;
    }

    final response = existing == null
        ? await _api.post('/training-sessions', payload)
        : await _api.put('/training-sessions/${existing.id}', payload);

    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid training session response');
    }

    final saved = _sessionFromApi(data);
    setState(() {
      if (existing == null) {
        _sessions.add(saved);
      } else {
        final index = _sessions.indexWhere((item) => item.id == existing.id);
        if (index >= 0) {
          _sessions[index] = saved;
        }
      }
      _sessions.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  List<_TrainingSessionItem> get _filteredSessions {
    final sessions = _selectedFilter == null
        ? List<_TrainingSessionItem>.from(_sessions)
        : _sessions
              .where((session) => _effectiveStatus(session) == _selectedFilter)
              .toList();
    sessions.sort((a, b) => a.date.compareTo(b.date));
    return sessions;
  }

  int get _totalSessions => _sessions.length;

  int get _upcomingSessions =>
      _sessions
          .where(
            (session) => _effectiveStatus(session) == _TrainingStatus.planned,
          )
          .length;

  int get _completedSessions =>
      _sessions
          .where(
            (session) =>
                _effectiveStatus(session) == _TrainingStatus.completed,
          )
          .length;

  Future<void> _openSessionForm({_TrainingSessionItem? existing}) async {
    final result = await showDialog<_TrainingSessionItem>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TrainingSessionFormDialog(session: existing),
    );

    if (result == null) return;

    setState(() => _saving = true);
    try {
      await _saveSessionToBackend(result, existing: existing);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Create failed: ${_errorMessage(error)}'
                : 'Update failed: ${_errorMessage(error)}',
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Training session created'
              : 'Training session updated',
        ),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  Future<void> _showSessionDetails(_TrainingSessionItem session) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionDetailsSheet(session: session),
    );
  }

  Future<void> _deleteSession(_TrainingSessionItem session) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete session'),
            content: Text('Delete "${session.title}" from your schedule?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      await _api.delete('/training-sessions/${session.id}');
      setState(() {
        _sessions.removeWhere((item) => item.id == session.id);
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${_errorMessage(error)}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Training session deleted'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredSessions = _filteredSessions;
    final isCompact = MediaQuery.sizeOf(context).width < 900;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: isCompact
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _openSessionForm,
              backgroundColor: const Color(0xFF1ED6B0),
              foregroundColor: Colors.white,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Saving...' : 'Create Session'),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                showButton: !isCompact,
                isSaving: _saving,
                onCreatePressed: _openSessionForm,
              ),
              const SizedBox(height: 16),
              _SummarySection(
                totalSessions: _totalSessions,
                upcomingSessions: _upcomingSessions,
                completedSessions: _completedSessions,
              ),
              const SizedBox(height: 16),
              _FilterSection(
                selectedFilter: _selectedFilter,
                onSelected: (status) {
                  setState(() {
                    _selectedFilter = status;
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F7F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_note_rounded,
                              color: Color(0xFF1ED6B0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session Schedule',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Keep your squad aligned with clear session planning and coaching priorities.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (filteredSessions.isEmpty)
                        _EmptyState(onCreatePressed: _openSessionForm)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSessions.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final session = filteredSessions[index];
                            return _SessionCard(
                              session: session,
                              onView: () => _showSessionDetails(session),
                              onEdit: () => _openSessionForm(existing: session),
                              onDelete: () => _deleteSession(session),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
