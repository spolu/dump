import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:path/path.dart' as p;
import 'dart:ffi';
import 'dart:io';
import 'package:app/srv_bindings.dart' as srv;

import 'package:ffi/ffi.dart';

final s = srv.NativeLibrary(DynamicLibrary.open('libsrv.dylib'));

// String _getPath() {
//   // see https://github.com/dart-lang/ffigen/blob/master/example/c_json/main.dart#L48
//   final localPath = Directory.current.absolute.path;
//   var path = p.join(localPath, 'macos/libsrv.dylib');
//   return path;
// }

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

  List<String> streamNamesNotInQuery(String query) {
    RegExp r = new RegExp(
      r"\{[^\{\}]+}",
      caseSensitive: false,
      multiLine: false,
    );
    List<String> ss = [];
    r.allMatches(meta).map((match) => match.group(0)).forEach((m) {
      if (m != null) {
        if (!query.contains(m)) {
          ss.add(m.substring(1, m.length - 1));
        }
      }
    });
    return ss;
  }

  Future<Entry> update() async {
    final req = jsonEncode(<String, dynamic>{
      'id': id,
      'title': title == '' ? "(empty)" : title,
      'meta': meta,
      'body': body,
    });

    final ptr = s.update_entry_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    return Entry.fromJson(json.decode(data));
  }

  Future<Entry> delete() async {
    final req = jsonEncode(<String, dynamic>{
      'id': id,
      'title': title == '' ? "(empty)" : title,
      'meta': meta,
      'body': body,
    });

    final ptr = s.delete_entry_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    return Entry.fromJson(json.decode(data));
  }

  static Future<Entry> create(List<Stream> streams) async {
    final req = jsonEncode(<String, dynamic>{
      'title': '',
      'meta': streams.map((stream) => "{" + stream.name + "}").join(' '),
      'body': ''
    });

    final ptr = s.create_entry_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    return Entry.fromJson(json.decode(data));
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
    final req = jsonEncode(<String, dynamic>{
      'query': query,
      'offset': offset,
      'limit': limit,
    });

    final ptr = s.list_entries_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    final json = jsonDecode(data);
    return EntryList(
      entries: (json['entries'] as List)
          .map((entry) => Entry.fromJson(entry))
          .toList(),
      offset: json['offset'],
      total: json['total'],
    );
  }
}

class Stream {
  const Stream({required this.id, required this.name});
  final String id;
  final String name;

  factory Stream.fromJson(Map<String, dynamic> json) {
    return Stream(id: json['id'], name: json['name']);
  }

  Future<Stream> update() async {
    final req = jsonEncode(<String, dynamic>{
      'id': id,
      'name': name,
    });

    final ptr = s.update_stream_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    return Stream.fromJson(json.decode(data));
  }

  Future<Stream> delete() async {
    final req = jsonEncode(<String, dynamic>{
      'id': id,
      'name': name,
    });

    final ptr = s.delete_stream_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    return Stream.fromJson(json.decode(data));
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
    final req = jsonEncode(<String, dynamic>{
      'query': '',
      'offset': 0,
      'limit': 999,
    });

    final ptr = s.list_streams_ffi(req.toNativeUtf8().cast());
    final data = ptr.cast<Utf8>().toDartString();
    s.response_free_ffi(ptr);

    final json = jsonDecode(data);
    return StreamList(
      streams: (json['streams'] as List)
          .map((entry) => Stream.fromJson(entry))
          .toList(),
      total: json['total'],
    );
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

  void streamRemove(Stream stream) {
    _query = _query.replaceAll("{" + stream.name + "}", "");
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
    for (var s in _streams) {
      if (s.name == name) {
        return s;
      }
    }
    return null;
  }

  List<Stream> fromMetaOrQuery(String metaOrQuery) {
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
