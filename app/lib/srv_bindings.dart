// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

class NativeLibrary {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void response_free_ffi(
    ffi.Pointer<ffi.Int8> response,
  ) {
    return _response_free_ffi(
      response,
    );
  }

  late final _response_free_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_response_free_ffi>>('response_free_ffi');
  late final _dart_response_free_ffi _response_free_ffi =
      _response_free_ffi_ptr.asFunction<_dart_response_free_ffi>();

  ffi.Pointer<ffi.Int8> list_entries_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _list_entries_ffi(
      request,
    );
  }

  late final _list_entries_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_list_entries_ffi>>('list_entries_ffi');
  late final _dart_list_entries_ffi _list_entries_ffi =
      _list_entries_ffi_ptr.asFunction<_dart_list_entries_ffi>();

  ffi.Pointer<ffi.Int8> create_entry_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _create_entry_ffi(
      request,
    );
  }

  late final _create_entry_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_create_entry_ffi>>('create_entry_ffi');
  late final _dart_create_entry_ffi _create_entry_ffi =
      _create_entry_ffi_ptr.asFunction<_dart_create_entry_ffi>();

  ffi.Pointer<ffi.Int8> update_entry_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _update_entry_ffi(
      request,
    );
  }

  late final _update_entry_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_update_entry_ffi>>('update_entry_ffi');
  late final _dart_update_entry_ffi _update_entry_ffi =
      _update_entry_ffi_ptr.asFunction<_dart_update_entry_ffi>();

  ffi.Pointer<ffi.Int8> delete_entry_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _delete_entry_ffi(
      request,
    );
  }

  late final _delete_entry_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_delete_entry_ffi>>('delete_entry_ffi');
  late final _dart_delete_entry_ffi _delete_entry_ffi =
      _delete_entry_ffi_ptr.asFunction<_dart_delete_entry_ffi>();

  ffi.Pointer<ffi.Int8> list_streams_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _list_streams_ffi(
      request,
    );
  }

  late final _list_streams_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_list_streams_ffi>>('list_streams_ffi');
  late final _dart_list_streams_ffi _list_streams_ffi =
      _list_streams_ffi_ptr.asFunction<_dart_list_streams_ffi>();

  ffi.Pointer<ffi.Int8> delete_stream_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _delete_stream_ffi(
      request,
    );
  }

  late final _delete_stream_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_delete_stream_ffi>>('delete_stream_ffi');
  late final _dart_delete_stream_ffi _delete_stream_ffi =
      _delete_stream_ffi_ptr.asFunction<_dart_delete_stream_ffi>();

  ffi.Pointer<ffi.Int8> update_stream_ffi(
    ffi.Pointer<ffi.Int8> request,
  ) {
    return _update_stream_ffi(
      request,
    );
  }

  late final _update_stream_ffi_ptr =
      _lookup<ffi.NativeFunction<_c_update_stream_ffi>>('update_stream_ffi');
  late final _dart_update_stream_ffi _update_stream_ffi =
      _update_stream_ffi_ptr.asFunction<_dart_update_stream_ffi>();
}

typedef _c_response_free_ffi = ffi.Void Function(
  ffi.Pointer<ffi.Int8> response,
);

typedef _dart_response_free_ffi = void Function(
  ffi.Pointer<ffi.Int8> response,
);

typedef _c_list_entries_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_list_entries_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _c_create_entry_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_create_entry_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _c_update_entry_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_update_entry_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _c_delete_entry_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_delete_entry_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _c_list_streams_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_list_streams_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _c_delete_stream_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_delete_stream_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _c_update_stream_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);

typedef _dart_update_stream_ffi = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<ffi.Int8> request,
);
