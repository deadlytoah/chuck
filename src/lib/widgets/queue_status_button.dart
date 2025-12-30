import 'package:flutter/cupertino.dart';

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
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: CupertinoColors.activeBlue,
        shape: BoxShape.circle,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
