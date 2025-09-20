// widgets/custom_progress_indicator.dart
import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Color valueColor;
  final double height;

  const CustomProgressIndicator({
    Key? key,
    required this.value,
    this.backgroundColor = Colors.grey,
    this.valueColor = Colors.blue,
    this.height = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressValue = value.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: (progressValue * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: valueColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            flex: 100 - (progressValue * 100).round(),
            child: Container(),
          ),
        ],
      ),
    );
  }
}