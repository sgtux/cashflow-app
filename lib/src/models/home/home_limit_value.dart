import 'package:flutter/material.dart';

class HomeLimitValue {
  final String description;
  final num limit;
  final num spent;
  final num percent;
  final Color color;

  HomeLimitValue(
      {required this.description,
      required this.limit,
      required this.spent,
      required this.percent,
      required this.color});

  factory HomeLimitValue.fromMap(Map<String, dynamic> map) {
    var percent = map['spent'] / map['limit'];
    Color color;
    if (percent < .65) {
      color = Colors.green;
    } else if (percent < .80) {
      color = Colors.yellow;
    } else if (percent < .95) {
      color = Colors.red;
    } else {
      color = Colors.red.shade900;
    }
    return HomeLimitValue(
        description: map['description'],
        limit: map['limit'],
        spent: map['spent'],
        percent: percent,
        color: color);
  }
}
