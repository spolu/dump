import 'package:app/models.dart';
import 'package:flutter/material.dart';
import 'package:app/fixed_split.dart';
import 'package:app/menu.dart';
import 'package:app/journal.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:developer';
import 'dart:io';

void main() {
  // print env variable HOME
  var home = Platform.environment['HOME'];
  if (home != null) {
    log(home);
  }
  runApp(DumpApp());
}

class DumpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dump',
      theme: ThemeData(
        // brightness: Brightness.light,
        // primaryColor: Colors.teal,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          background: Color.fromRGBO(247, 246, 243, 1.0),
          onBackground: Color.fromRGBO(25, 23, 17, 0.7),
        ),
        dividerColor: Color.fromRGBO(247, 246, 243, 1.0),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: DumpTop(),
    );
  }
}

class DumpTop extends StatefulWidget {
  @override
  _DumpTopState createState() => _DumpTopState();
}

class _DumpTopState extends State<DumpTop> {
  SearchQueryModel _searchQuery = SearchQueryModel('{Inbox}');
  StreamsModel _streams = StreamsModel();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => _searchQuery),
        ChangeNotifierProvider(create: (context) => _streams),
      ],
      child: Scaffold(
        body: FixedSplit(
          axis: Axis.horizontal,
          initialChildrenSizes: const [200.0, -1],
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
            Consumer<StreamsModel>(
              builder: (context, streams, child) => Menu(
                streams: streams.streams(),
              ),
            ),
            Journal(),
          ],
        ),
      ),
    );
  }
}
