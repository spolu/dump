import 'package:flutter/material.dart';
import 'package:app/model.dart';

class EntryItem extends StatefulWidget {
  EntryItem({
    required this.entry,
  }) : super(key: ObjectKey(entry.id));

  final Entry entry;

  @override
  _EntryItemState createState() => _EntryItemState();
}

class _EntryItemState extends State<EntryItem> {
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
        Text(widget.entry.title),
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
