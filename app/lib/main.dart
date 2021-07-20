import 'package:app/models.dart';
import 'package:flutter/material.dart';
import 'package:app/menu.dart';
import 'package:app/journal.dart';
import 'package:app/login.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  runApp(DumpApp());
}

class DumpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => JournalState('{Inbox}')),
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

    return Consumer<JournalState>(
        builder: (context, state, child) => state.authenticated()
            ? (isHandset ? _buildHandset(context) : _buildNormal(context))
            : Scaffold(
                body: Login(),
              ));
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
                builder: (context) => Consumer<JournalState>(
                  builder: (context, state, child) => Scaffold(
                    body: Menu(
                      streams: state.streams(),
                    ),
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
            child: Consumer<JournalState>(
              builder: (context, state, child) => Menu(
                streams: state.streams(),
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
