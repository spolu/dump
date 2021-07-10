import 'package:app/models.dart';
import 'package:flutter/material.dart';
import 'package:app/fixed_split.dart';
import 'dart:developer';
import 'package:app/menu.dart';
import 'package:app/journal.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
        colorScheme: ColorScheme.light(
          background: Color.fromRGBO(247, 246, 243, 1.0),
          onBackground: Color.fromRGBO(25, 23, 17, 0.7),
        ),
        dividerColor: Color.fromRGBO(247, 246, 243, 1.0),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
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
  SearchQueryModel _searchQuery = SearchQueryModel('{Inbox}');
  StreamsModel _streams = StreamsModel();

  @override
  void initState() {
    super.initState();
    _futureStreamList = StreamList.fetch();
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
