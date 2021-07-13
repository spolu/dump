import 'package:app/models.dart';
import 'package:flutter/material.dart';
import 'package:app/fixed_split.dart';
import 'package:app/menu.dart';
import 'package:app/journal.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:ffi';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'dart:developer';

import 'package:app/srv_bindings.dart' as srv;

final s = srv.NativeLibrary(DynamicLibrary.open(_getPath()));

String _getPath() {
  final localPath = Directory.current.absolute.path;
  var path = p.join(localPath, 'macos/libsrv.dylib');
  return path;
}

class ListOptions {
  const ListOptions({
    required this.query,
    required this.offset,
    required this.limit,
  });
  final String query;
  final int offset;
  final int limit;
}

void main() {
  final req = jsonEncode(<String, dynamic>{
    'query': '{Inbox}',
    'offset': 0,
    'limit': 10,
  });

  final tt = s.list_entries_ffi(req.toNativeUtf8().cast());
  final ss = tt.cast<Utf8>().toDartString();
  log('TT: $tt');
  log('SS: $ss');
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
