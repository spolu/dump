import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/srv_bindings.dart' as srv;

final s = Platform.isMacOS
    ? srv.NativeLibrary(DynamicLibrary.open('libsrv.dylib'))
    : srv.NativeLibrary(DynamicLibrary.executable());

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

  static bool inboxInMeta(String meta) {
    RegExp r = new RegExp(
      r"\{[^\{\}]+}",
      caseSensitive: false,
      multiLine: false,
    );
    bool inbox = false;
    r.allMatches(meta).map((match) => match.group(0)).forEach((m) {
      if (m != null) {
        if (m.substring(1, m.length - 1) == "Inbox") {
          inbox = true;
        }
      }
    });
    return inbox;
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
      'created': created,
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

class JournalState extends ChangeNotifier {
  JournalState(String query) {
    this._query = query;
    this._streams = [];
    this._user = null;
    this.updateStreams();
    this._auth.userChanges().listen((u) {
      this._user = u;
      notifyListeners();
    });
  }

  late String _query;
  late List<Stream> _streams;
  late User? _user;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool authenticated() {
    return _user != null;
  }

  Future<void> signOut() async {
    print(this._user);
    await _auth.signOut();
  }

  void querySelectStream(Stream stream) {
    if (stream.id == "all") {
      updateQuery("");
    } else {
      updateQuery("{" + stream.name + "}");
    }
  }

  void queryToggleStream(Stream stream) {
    if (_query.contains("{" + stream.name + "}")) {
      _query = _query.replaceAll("{" + stream.name + "}", "");
    } else {
      _query += " {" + stream.name + "}";
    }
    _query = _query.replaceAll("  ", " ");
    _query = _query.trim();
    notifyListeners();
  }

  void queryRemoveStream(Stream stream) {
    _query = _query.replaceAll("{" + stream.name + "}", "");
    _query = _query.replaceAll("  ", " ");
    _query = _query.trim();
    notifyListeners();
  }

  bool queryContainsStream(Stream stream) {
    return _query.contains("{" + stream.name + "}");
  }

  void updateQuery(String query) {
    this._query = query;
    notifyListeners();
  }

  String query() {
    return this._query;
  }

  List<Stream> streams() {
    return _streams;
  }

  Stream? _streamFromName(String name) {
    for (var s in _streams) {
      if (s.name == name) {
        return s;
      }
    }
    return null;
  }

  List<Stream> streamsFromMetaOrQuery(String metaOrQuery) {
    RegExp r = new RegExp(
      r"\{[^\{\}]+}",
      caseSensitive: false,
      multiLine: false,
    );
    List<Stream> streams = [];
    r.allMatches(metaOrQuery).map((match) => match.group(0)).forEach((m) {
      if (m != null) {
        var s = _streamFromName(m.substring(1, m.length - 1));
        if (s != null) {
          streams.add(s);
        }
      }
    });
    return streams;
  }

  void updateStreams() {
    // Update the streams on the network and call notifyListeners().
    StreamList.fetch().then((ss) {
      _streams = ss.streams;
      notifyListeners();
    });
  }
}
