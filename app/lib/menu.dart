import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models.dart';
import 'dart:developer';

class StreamItem extends StatelessWidget {
  // constructor that accepts a stream and a callback when the stream is selected
  /*, this.onTap*/
  StreamItem(
      {required this.stream,
      required this.searchQuery,
      required this.onTap,
      required this.onDoubleTap})
      : super(key: ObjectKey(stream.id));

  final Stream stream;
  final Function onTap;
  final Function onDoubleTap;
  final SearchQueryModel searchQuery;

  @override
  Widget build(BuildContext context) {
    var iconType = Icons.label;
    if (stream.id == "0-inbox") {
      iconType = Icons.inbox;
    }
    if (stream.id == "all") {
      iconType = Icons.article;
    }

    var bgColor = Colors.transparent;
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
          color: searchQuery.containsStream(stream)
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
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onBackground,
                      )),
                ),
                SizedBox(width: 10.0),
                GestureDetector(
                  onTap: () {
                    stream.delete().then((s) {
                      Provider.of<StreamsModel>(context, listen: false)
                          .update();
                    });
                  },
                  child: Icon(
                    Icons.delete,
                    color: Colors.grey[200],
                    size: 13.0,
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
    final streams = List<Widget>.from(this.streams.map((Stream stream) {
      return Consumer<SearchQueryModel>(
          builder: (context, searchQuery, child) => StreamItem(
              stream: stream,
              searchQuery: searchQuery,
              onTap: () {
                // Provider.of<SearchQueryModel>(context, listen: false)
                //     .streamToggle(stream);
                searchQuery.streamToggle(stream);
              },
              onDoubleTap: () {
                // Provider.of<SearchQueryModel>(context, listen: false)
                //     .streamSelect(stream);
                searchQuery.streamSelect(stream);
              }));
    }));
    return Container(
      decoration: new BoxDecoration(
        color: Theme.of(context).colorScheme.background,
      ),
      child: Column(children: [
        Expanded(
            child: ListView(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                children: streams)),
      ]),
    );
  }
}
