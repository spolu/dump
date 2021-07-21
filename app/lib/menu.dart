import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:app/models.dart';
import 'package:hovering/hovering.dart';

import 'dart:math' as math;

class StreamDeleteDialog extends StatelessWidget {
  StreamDeleteDialog({
    required this.stream,
    required this.onConfirm,
  }) : super(key: ObjectKey(stream.id));

  final Stream stream;
  final Function onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetAnimationDuration: Duration(milliseconds: 0),
      insetAnimationCurve: Curves.linear,
      insetPadding: EdgeInsets.all(50.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: Container(
        width: 300,
        height: 150,
        child: Container(
            // decoration: new BoxDecoration(color: Colors.blue),
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text("Confirm stream deletion?",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 20.0),
                Text(
                    "The stream will be removed from all its entries (without deleting them).",
                    style: TextStyle(color: Colors.black38)),
                Expanded(child: Container()),
                Container(
                  decoration: new BoxDecoration(color: Colors.transparent),
                  padding: EdgeInsets.symmetric(horizontal: 0.0),
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Confirm",
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class StreamEdit extends StatefulWidget {
  StreamEdit({
    required this.stream,
    required this.onUpdate,
  }) : super(key: ObjectKey("stream_edit"));

  final Stream stream;
  final Function(Stream) onUpdate;

  @override
  _StreamEditState createState() => _StreamEditState();
}

class _StreamEditState extends State<StreamEdit> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.stream.name;
  }

  @override
  void dispose() {
    this.widget.onUpdate(Stream(
          id: this.widget.stream.id,
          meta: this.widget.stream.meta,
          name: _nameController.text,
        ));
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        elevation: 0,
        insetAnimationDuration: Duration(milliseconds: 0),
        insetAnimationCurve: Curves.linear,
        insetPadding: EdgeInsets.all(50.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Container(
          width: 300,
          height: 90,
          child: Column(
            children: <Widget>[
              Container(
                  // decoration: new BoxDecoration(color: Colors.blue),
                  padding: EdgeInsets.only(top: 20.0),
                  child: Row(children: [
                    SizedBox(
                      width: 20.0,
                    ),
                    Icon(
                      Icons.title,
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      size: 13.0,
                    ),
                    Expanded(
                      child: Container(
                        // decoration: new BoxDecoration(color: Colors.green),
                        child: TextField(
                          autofocus: true,
                          controller: _nameController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(
                                top: 10.0, bottom: 8.0, left: 7.0, right: 7.0),
                          ),
                          style: TextStyle(
                            height: 1.0,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                  ])),
              Expanded(child: Container()),
              Container(
                decoration: new BoxDecoration(color: Colors.transparent),
                padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

class StreamItem extends StatelessWidget {
  StreamItem(
      {required this.stream,
      required this.state,
      required this.onTap,
      required this.onDoubleTap})
      : super(key: ObjectKey(stream.id));

  final Stream stream;
  final Function onTap;
  final Function onDoubleTap;
  final JournalState state;

  @override
  Widget build(BuildContext context) {
    var iconType = Icons.label;
    if (stream.id == "0-inbox") {
      iconType = Icons.inbox;
    }
    if (stream.id == "all") {
      iconType = Icons.article;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          this.onTap();
        },
        onDoubleTap: () {
          this.onDoubleTap();
        },
        child: Card(
          elevation: 0,
          color: state.queryContainsStream(stream)
              ? Colors.grey[300]
              : Colors.transparent,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.all(0.0),
          child: Padding(
            padding: EdgeInsets.all(5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 10.0,
                ),
                Icon(
                  iconType,
                  color: Theme.of(context).colorScheme.onBackground,
                  size: 13.0,
                ),
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: Text(stream.name,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onBackground,
                      )),
                ),
                stream.name == "Inbox"
                    ? Container()
                    : GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (_context) {
                                var state = Provider.of<JournalState>(context,
                                    listen: false);
                                return StreamEdit(
                                    stream: stream,
                                    onUpdate: (Stream s) {
                                      s.update().then((value) {
                                        state.updateStreams();
                                      });
                                    });
                              });
                        },
                        child: HoverWidget(
                          child: Icon(
                            Icons.edit,
                            color: Colors.grey[200],
                            size: 13.0,
                          ),
                          hoverChild: Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 13.0,
                          ),
                          onHover: (event) {},
                        ),
                      ),
                SizedBox(width: 10.0),
                stream.name == "Inbox"
                    ? Container()
                    : GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (_context) {
                                var state = Provider.of<JournalState>(context,
                                    listen: false);
                                return StreamDeleteDialog(
                                    stream: stream,
                                    onConfirm: () {
                                      stream.delete().then((s) {
                                        state.updateStreams();
                                        state.queryRemoveStream(stream);
                                      });
                                    });
                              });
                        },
                        child: HoverWidget(
                          child: Icon(
                            Icons.delete,
                            color: Colors.grey[200],
                            size: 13.0,
                          ),
                          hoverChild: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 13.0,
                          ),
                          onHover: (event) {},
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Menu extends StatelessWidget {
  Menu({
    required this.streams,
  }) : super();

  final List<Stream> streams;

  @override
  Widget build(BuildContext context) {
    bool isHandset = MediaQuery.of(context).size.width < 600;
    return Container(
      decoration: new BoxDecoration(
        color: Theme.of(context).colorScheme.background,
      ),
      child: Column(
          children: isHandset
              ? _buildHandsetChildren(context)
              : _buildNormalChildren(context)),
    );
  }

  List<Widget> _buildNormalChildren(BuildContext context) {
    final streams = List<Widget>.from(this.streams.map((Stream stream) {
      return Consumer<JournalState>(
          builder: (context, state, child) => StreamItem(
              stream: stream,
              state: state,
              onTap: () {
                state.queryToggleStream(stream);
              },
              onDoubleTap: () {
                state.querySelectStream(stream);
              }));
    }));

    var state = Provider.of<JournalState>(context, listen: false);

    return [
      Expanded(
          child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
              children: streams)),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            state.signOut();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              "Sign Out",
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHandsetChildren(BuildContext context) {
    var children = _buildNormalChildren(context);
    children.insert(
      0,
      SizedBox(height: 44.0),
    );
    children.insert(
        1,
        Row(
          children: [
            Expanded(
              child: Container(),
            ),
            Container(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 1.0),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 20.0),
          ],
        ));
    return children;
  }
}
