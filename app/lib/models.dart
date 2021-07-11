import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Entry {
  const Entry({
    required this.id,
    required this.created,
    required this.title,
    required this.meta,
    required this.body,
  });
  final String id;
  final int created;
  final String title;
  final String meta;
  final String body;

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
        id: json['id'],
        created: json['created'],
        meta: json['meta'],
        title: json['title'],
        body: json['body']);
  }

  Future<Entry> update() async {
    final response = await http.put(
      Uri.parse(
        'http://127.0.0.1:13371/entries/$id',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id': id,
        'title': title == '' ? "(empty)" : title,
        'meta': meta,
        'body': body,
      }),
    );

    if (response.statusCode == 200) {
      return Entry.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update entry');
    }
  }

  Future<Entry> delete() async {
    final response = await http.delete(
      Uri.parse(
        'http://127.0.0.1:13371/entries/$id',
      ),
    );

    if (response.statusCode == 200) {
      return this;
    } else {
      throw Exception('Failed to create entry');
    }
  }

  static Future<Entry> create(List<Stream> streams) async {
    final response = await http.post(
      Uri.parse(
        'http://127.0.0.1:13371/entries',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': '',
        'meta': streams.map((stream) => "{" + stream.name + "}").join(' '),
        'body': '',
      }),
    );

    if (response.statusCode == 200) {
      return Entry.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create entry');
    }
  }
}

class EntryList {
  const EntryList({
    required this.entries,
    required this.offset,
    required this.total,
  });

  final List<Entry> entries;
  final int offset;
  final int total;

  static Future<EntryList> fetch(int offset, int limit, String query) async {
    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:13371/entries?offset=$offset&limit=$limit&query=$query'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return EntryList(
        entries: (json['entries'] as List)
            .map((entry) => Entry.fromJson(entry))
            .toList(),
        offset: json['offset'],
        total: json['total'],
      );
    } else {
      throw Exception('Failed to load entries');
    }
  }
}

class Stream {
  const Stream({required this.id, required this.name});
  final String id;
  final String name;

  factory Stream.fromJson(Map<String, dynamic> json) {
    return Stream(id: json['id'], name: json['name']);
  }

  Future<Stream> delete() async {
    final response = await http.delete(
      Uri.parse(
        'http://127.0.0.1:13371/streams/$id',
      ),
    );

    if (response.statusCode == 200) {
      return this;
    } else {
      throw Exception('Failed to create entry');
    }
  }
}

class StreamList {
  const StreamList({
    required this.streams,
    required this.total,
  });

  final List<Stream> streams;
  final int total;

  static Future<StreamList> fetch() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:13371/streams'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return StreamList(
        streams: (json['streams'] as List)
            .map((entry) => Stream.fromJson(entry))
            .toList(),
        total: json['total'],
      );
    } else {
      throw Exception('Failed to load streams');
    }
  }
}

class SearchQueryModel extends ChangeNotifier {
  SearchQueryModel(String query) {
    this._query = query;
  }

  late String _query;

  void streamSelect(Stream stream) {
    if (stream.id == "all") {
      update("");
    } else {
      update("{" + stream.name + "}");
    }
  }

  void streamToggle(Stream stream) {
    if (_query.contains("{" + stream.name + "}")) {
      _query = _query.replaceAll("{" + stream.name + "}", "");
    } else {
      _query += " {" + stream.name + "}";
    }
    _query = _query.replaceAll("  ", " ");
    _query = _query.trim();
    notifyListeners();
  }

  bool containsStream(Stream stream) {
    return _query.contains("{" + stream.name + "}");
  }

  void update(String query) {
    this._query = query;
    notifyListeners();
  }

  String query() {
    return this._query;
  }
}

class StreamsModel extends ChangeNotifier {
  StreamsModel() {
    this._streams = [];
    this.update();
  }

  late List<Stream> _streams;

  List<Stream> streams() {
    return _streams;
  }

  Stream? _fromName(String name) {
    for (var i = 0; i < _streams.length; i++) {
      if (_streams[i].name == name) {
        return _streams[i];
      }
    }
    return null;
  }

  List<Stream> fromMetaOrQuery(String metaOrQuery) {
    log("fromMetaOrQuery: $metaOrQuery");
    RegExp r = new RegExp(
      r"\{[^\{\}]+}",
      caseSensitive: false,
      multiLine: false,
    );
    List<Stream> streams = [];
    r.allMatches(metaOrQuery).map((match) => match.group(0)).forEach((m) {
      if (m != null) {
        var s = _fromName(m.substring(1, m.length - 1));
        if (s != null) {
          streams.add(s);
        }
      }
    });
    return streams;
  }

  void update() {
    // Update the streams on the network and call notifyListeners().
    StreamList.fetch().then((ss) {
      _streams = ss.streams;
      notifyListeners();
    });
  }
}
