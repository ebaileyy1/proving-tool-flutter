import 'package:flutter/material.dart';

class ActiveFiltersBanner extends StatelessWidget {
  final String? statusFilter;
  final String? typeFilter;
  final VoidCallback onClear;

  const ActiveFiltersBanner({
    super.key,
    required this.statusFilter,
    required this.typeFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (statusFilter == null && typeFilter == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Text(
            'Showing: ${[?statusFilter, ?typeFilter].join(' + ')} trials',
            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}
