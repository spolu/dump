import 'package:flutter/material.dart';
import 'package:app/model.dart';

class StreamItem extends StatelessWidget {
  // constructor that accepts a stream and a callback when the stream is selected
  /*, this.onTap*/
  StreamItem({required this.stream}) : super(key: ObjectKey(stream.id));

  final Stream stream;

  @override
  Widget build(BuildContext context) {
    var iconType = Icons.label;
    if (stream.id == "inbox") {
      iconType = Icons.inbox;
    }
    if (stream.id == "all") {
      iconType = Icons.article;
    }
    return Card(
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
              color: Color.fromRGBO(25, 23, 17, 0.7),
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
                  color: Color.fromRGBO(25, 23, 17, 0.7),
                )),
          ],
        ),
      ),
    );
  }
}

class StreamList extends StatelessWidget {
  StreamList({required this.loading, required this.streams}) : super();

  final bool loading;
  final List<Stream> streams;

  @override
  Widget build(BuildContext context) {
    final streams = List<StreamItem>.from(this.streams.map((Stream stream) {
      return StreamItem(stream: stream);
    }));
    return Container(
        decoration: new BoxDecoration(
          color: Color.fromRGBO(223, 223, 217, 1.0),
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
