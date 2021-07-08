import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class Entry {
  const Entry({
    required this.id,
    required this.title,
    required this.meta,
    required this.body,
  });
  final String id;
  final String title;
  final String meta;
  final String body;

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
        id: json['id'],
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
        'title': title,
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

  static Future<Entry> create() async {
    final response = await http.post(
      Uri.parse(
        'http://127.0.0.1:13371/entries',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': '',
        'meta': '',
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
