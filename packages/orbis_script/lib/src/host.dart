import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.dart' as native;

/// A value thrown by script, carrying the JavaScript stack with it.
///
/// The stack matters more than usual here: by the time a mod or a designer's
/// behaviour throws, the Dart stack says only that the host pumped a queue.
class ScriptError implements Exception {
  ScriptError(this.message);

  /// The thrown value coerced to string, followed by its JavaScript stack.
  final String message;

  @override
  String toString() => 'ScriptError: $message';
}

/// One QuickJS runtime and its context.
///
/// A host owns native memory, so it must be disposed. Nothing else in the
/// package holds one implicitly — the editor keeps one per play session, and a
/// shipped game keeps one for the life of the process.
class ScriptHost {
  ScriptHost() : _handle = native.orbisScriptNew() {
    if (_handle == nullptr) {
      throw StateError('Could not create a QuickJS runtime.');
    }
  }

  Pointer<native.OrbisScriptHostStruct> _handle;

  bool get isDisposed => _handle == nullptr;

  /// The vendored QuickJS version, for diagnostics and bug reports.
  static String get engineVersion =>
      native.orbisScriptEngineVersion().cast<Utf8>().toDartString();

  /// Evaluates [source] as a global script and returns its result as a string.
  ///
  /// [fileName] is what appears in stack traces, so it is worth passing the
  /// real path once a watcher is loading files.
  ///
  /// Throws [ScriptError] if the script throws.
  String eval(String source, {String fileName = '<eval>'}) {
    _checkAlive();
    return using((arena) {
      final out = arena<Pointer<Char>>();
      final threw = native.orbisScriptEval(
            _handle,
            source.toNativeUtf8(allocator: arena).cast<Char>(),
            fileName.toNativeUtf8(allocator: arena).cast<Char>(),
            out,
          ) !=
          0;
      return _consume(out.value, isError: threw);
    });
  }

  /// Runs queued microtasks until the queue is empty, returning how many ran.
  ///
  /// QuickJS does not drive its own job queue, so resolved promises sit there
  /// until something pumps them. The frame loop will call this; until then a
  /// caller does, which is why it is public rather than internal.
  ///
  /// Throws [ScriptError] if a job throws. Jobs queued before the failure have
  /// already run.
  int pumpMicrotasks() {
    _checkAlive();
    return using((arena) {
      final error = arena<Pointer<Char>>();
      final ran = native.orbisScriptPump(_handle, error);
      if (ran < 0) _consume(error.value, isError: true);
      return ran;
    });
  }

  /// Frees the context and runtime. Idempotent.
  void dispose() {
    if (_handle == nullptr) return;
    native.orbisScriptFree(_handle);
    _handle = nullptr;
  }

  void _checkAlive() {
    if (_handle == nullptr) {
      throw StateError('This ScriptHost has been disposed.');
    }
  }

  /// Takes ownership of a string the shim allocated, freeing it either way.
  String _consume(Pointer<Char> pointer, {required bool isError}) {
    if (pointer == nullptr) {
      if (isError) throw ScriptError('unknown JavaScript error');
      return '';
    }
    final value = pointer.cast<Utf8>().toDartString();
    native.orbisScriptStringFree(pointer);
    if (isError) throw ScriptError(value);
    return value;
  }
}
