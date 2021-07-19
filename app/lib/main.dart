import 'package:app/models.dart';
import 'package:flutter/material.dart';
import 'package:app/menu.dart';
import 'package:app/journal.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(DumpApp());
}

class DumpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => SearchQueryModel('{Inbox}')),
        ChangeNotifierProvider(create: (context) => StreamsModel()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}

class DumpTop extends StatefulWidget {
  @override
  _DumpTopState createState() => _DumpTopState();
}

class _DumpTopState extends State<DumpTop> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isHandset = MediaQuery.of(context).size.width < 600;
    return isHandset ? _buildHandset(context) : _buildNormal(context);
  }

  Widget _buildHandset(BuildContext context) {
    return Scaffold(
        body: Flex(
      children: [
        SizedBox(
          height: 20.0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        Expanded(
          child: Journal(onMenu: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Consumer<StreamsModel>(
                  builder: (context, streams, child) => Menu(
                    streams: streams.streams(),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    ));
  }

  Widget _buildNormal(BuildContext context) {
    return Scaffold(
      body: Flex(
        children: [
          SizedBox(
            width: 250,
            child: Consumer<StreamsModel>(
              builder: (context, streams, child) => Menu(
                streams: streams.streams(),
              ),
            ),
          ),
          Expanded(child: Journal(onMenu: () {})),
        ],
        direction: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.stretch,
      ),
    );
  }
}
