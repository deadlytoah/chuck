import 'package:flutter/material.dart';

class QueueStatusButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const QueueStatusButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: 'queueStatus',
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
