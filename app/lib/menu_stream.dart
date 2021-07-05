import 'package:flutter/material.dart';

class MenuStream extends StatelessWidget {
  MenuStream({
    required this.id,
    required this.name,
  }) : super(key: ObjectKey(id));

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(name),
    );
  }
}
