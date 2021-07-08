import 'package:flutter/material.dart';
import 'package:app/fixed_split.dart';
import 'dart:developer';
import 'package:app/model.dart';
import 'package:app/stream.dart';
import 'package:app/entry.dart';
import 'package:app/shortcuts.dart';

void main() => runApp(LitApp());

class LitApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lit',
      theme: ThemeData(
        // brightness: Brightness.light,
        // primaryColor: Colors.teal,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        // fontFamily: 'Georgia',
        colorScheme: ColorScheme.light(
          background: Color.fromRGBO(247, 246, 243, 1.0),
          onBackground: Color.fromRGBO(25, 23, 17, 0.7),
        ),
        dividerColor: Color.fromRGBO(247, 246, 243, 1.0),
      ),
      home: LitTop(),
    );
  }
}

class LitTop extends StatefulWidget {
  @override
  _LitTopState createState() => _LitTopState();
}

class _LitTopState extends State<LitTop> {
  late Future<StreamList> _futureStreamList;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _futureStreamList = StreamList.fetch();
  }

  void _handleSearcTextUpdate(String searchText) {
    setState(() {
      _searchText = searchText;
      log("UDPATED STATE: searchText=" + _searchText);
    });
  }

  void _handleStreamSelection(Stream stream) {
    setState(() {
      if (stream.id == "all") {
        _searchText = "";
      } else {
        _searchText = "{" + stream.name + "}";
      }
      log("UDPATED STATE: searchText=" + _searchText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FixedSplit(
        axis: Axis.horizontal,
        initialChildrenSizes: const [300.0, -1],
        minSizes: [200.0, 200.0],
        splitters: [
          SizedBox(
            width: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ],
        children: [
          _buildStreams(),
          _buildEntries(),
        ],
      ),
    );
  }

  Widget _buildStreams() {
    return FutureBuilder<StreamList>(
        future: _futureStreamList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return StreamListView(
                  loading: false,
                  streams: snapshot.data!.streams,
                  onStreamSelection: _handleStreamSelection);
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold));
            }
          }
          return StreamListView(
              loading: true,
              streams: [],
              onStreamSelection: _handleStreamSelection);
        });
  }

  Widget _buildEntries() {
    return MainView(
        searchText: _searchText, onSearchTextUpdate: _handleSearcTextUpdate);
  }
}
