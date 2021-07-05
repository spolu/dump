import 'package:flutter/material.dart';

class Meta {
  const Meta({required this.streams});
  final List<String> streams;
}

class Entry extends StatefulWidget {
  Entry({
    required this.title,
    required this.meta,
    required this.body,
  }) : super(key: ObjectKey(title));

  final String title;
  final Meta meta;
  final String body;

  @override
  _EntryState createState() => _EntryState();
}

class _EntryState extends State<Entry> {
  final _body_controller = TextEditingController();

  @override
  void dispose() {
    _body_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        Text(widget.title),
        Text(widget.meta.streams.join(' ')),
        Container(
          child: TextField(
            controller: _body_controller,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 2,
            maxLines: null,
          ),
        )
      ]),
    );
  }
}
