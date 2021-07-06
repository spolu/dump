import 'package:flutter/material.dart';
import 'package:app/fixed_split.dart';
import 'package:app/model.dart';
import 'package:app/stream.dart';

void main() => runApp(LitApp());

class LitApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lit',
      theme: ThemeData(
        // brightness: Brightness.dark,
        primaryColor: Colors.teal,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
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
  late Future<List<Stream>> _futureStreams;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _futureStreams = Stream.fetchStreams();
  }

  void _handleStreamSelection(Stream stream) {
    setState(() {
      _searchText = "[[" + stream.name + "]]";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Lit'),
      //   elevation: 0,
      //   actions: [IconButton(icon: Icon(Icons.list), onPressed: _pushSaved)],
      // ),
      body: FixedSplit(
        axis: Axis.horizontal,
        initialChildrenSizes: const [300.0, -1],
        minSizes: [200.0, 200.0],
        splitters: [
          SizedBox(
            width: 1,
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Entry',
        child: Icon(Icons.add),
        onPressed: null,
      ),
    );
  }

  Widget _buildStreams() {
    return FutureBuilder<List<Stream>>(
        future: _futureStreams,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return StreamList(loading: false, streams: snapshot.data!);
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
          }
          return StreamList(loading: true, streams: []);
        });
  }

  Widget _buildEntries() {
    return Text('Entries');
  }
}

// class RandomWordsState extends State<RandomWords> {
//   final _suggestions = <WordPair>[];
//   final _saved = <WordPair>{};
//   final _biggerFont =
//       const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold);
// 
//   Widget _buildSaved() {
//     final tiles = _saved.map(
//       (WordPair pair) {
//         return ListTile(
//           title: Text(
//             pair.asPascalCase,
//             style: _biggerFont,
//           ),
//         );
//       },
//     );
//     final divided = tiles.isNotEmpty
//         ? ListTile.divideTiles(context: context, tiles: tiles).toList()
//         : <Widget>[];
//     return ListView(children: divided);
//   }
// 
//   void _pushSaved() {
//     Navigator.of(context).push(
//       PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Text('Saved Suggestions'),
//           ),
//           body: _buildSaved(),
//         );
//       }, transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return child;
//       }
//           // MaterialPageRoute<void>(
//           //   builder: (BuildContext context) {
//           //   },
//           // ),
//           ),
//     );
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Lit'),
//         elevation: 0,
//         actions: [IconButton(icon: Icon(Icons.list), onPressed: _pushSaved)],
//       ),
//       body: FixedSplit(
//         axis: Axis.horizontal,
//         initialChildrenSizes: const [300.0, -1],
//         minSizes: [200.0, 200.0],
//         splitters: [
//           SizedBox(
//             width: 2,
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).dividerColor,
//               ),
//             ),
//           ),
//         ],
//         children: [
//           _buildSaved(),
//           _buildSuggestions(),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         tooltip: 'New Entry',
//         child: Icon(Icons.add),
//         onPressed: null,
//       ),
//     );
//   }
// 
//   Widget _buildRow(WordPair pair) {
//     final alreadySaved = _saved.contains(pair);
//     return ListTile(
//       title: Text(
//         pair.asPascalCase,
//         style: _biggerFont,
//       ),
//       trailing: Icon(
//         alreadySaved ? Icons.favorite : Icons.favorite_border,
//         color: alreadySaved ? Colors.red : null,
//       ),
//       onTap: () {
//         setState(() {
//           if (alreadySaved) {
//             _saved.remove(pair);
//           } else {
//             _saved.add(pair);
//           }
//         });
//       },
//     );
//   }
// 
//   Widget _buildSuggestions() {
//     return ListView.builder(
//         padding: const EdgeInsets.all(5.0),
//         itemBuilder: (context, i) {
//           if (i.isOdd) return const Divider();
// 
//           final index = i ~/ 2;
//           if (index >= _suggestions.length) {
//             _suggestions.addAll(generateWordPairs().take(10));
//           }
//           return _buildRow(_suggestions[index]);
//         });
//   }
// }
