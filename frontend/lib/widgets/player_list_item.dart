import 'package:flutter/material.dart';

class PlayerListEntry {
  final String name;
  final int number;
  final Color statusColor;
  const PlayerListEntry({
    required this.name,
    required this.number,
    required this.statusColor,
  });
}

class PlayerListItem extends StatelessWidget {
  const PlayerListItem({
    super.key,
    required this.name,
    required this.number,
    required this.statusColor,
  });

  final String name;
  final int number;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE5E7EB),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Number $number',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
