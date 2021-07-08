import 'package:flutter/material.dart';
import 'package:app/model.dart';

class StreamItem extends StatelessWidget {
  // constructor that accepts a stream and a callback when the stream is selected
  /*, this.onTap*/
  StreamItem({required this.stream, required this.onTap})
      : super(key: ObjectKey(stream.id));

  final Stream stream;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    var iconType = Icons.label;
    if (stream.id == "inbox") {
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
        child: Card(
          elevation: 0,
          color: Colors.transparent,
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
                Text(stream.name,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onBackground,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Menu extends StatelessWidget {
  Menu(
      {required this.loading,
      required this.streams,
      required this.onStreamSelection})
      : super();

  final bool loading;
  final List<Stream> streams;
  final Function(Stream) onStreamSelection;

  @override
  Widget build(BuildContext context) {
    final streams = List<StreamItem>.from(this.streams.map((Stream stream) {
      return StreamItem(
          stream: stream,
          onTap: () {
            this.onStreamSelection(stream);
          });
    }));
    return Container(
        decoration: new BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: loading
            ? new Center(
                child: new CircularProgressIndicator(),
              )
            : ListView(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                children: streams));
  }
}
