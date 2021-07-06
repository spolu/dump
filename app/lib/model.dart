import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Entry {
  const Entry({
    required this.id,
    required this.title,
    required this.body,
  });
  final String id;
  final String title;
  final String body;

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(id: json['id'], title: json['title'], body: json['body']);
  }

  static Future<List<Entry>> fetchEntries() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:13371/entries'),
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Entry>.from(l.map((model) => Entry.fromJson(model)));
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

  static Future<List<Stream>> fetchStreams() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:13371/streams'),
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Stream>.from(l.map((model) => Stream.fromJson(model)));
    } else {
      throw Exception('Failed to load streams');
    }
  }
}
