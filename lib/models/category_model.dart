// models/category_model.dart
import 'package:flutter/material.dart'; // Add this import

class Category {
  final int? id;
  final String name;
  final int color;

  Category({
    this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: (map['color'] as int?) ?? Colors.blue.value,
    );
  }
}