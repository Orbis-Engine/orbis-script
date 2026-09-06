/// Running a compiled TypeScript file in the engine.
///
/// TypeScript emits a file that expects to be a module: it assigns to
/// `exports`, and asks for what it imported through `require`. The engine has
/// neither — it evaluates a script, and there is nothing on the other side to
/// import from.
///
/// So a compiled file is wrapped before it is run. Each gets its own `exports`
/// and `module`, which is what stops two scripts writing over each other's
/// top-level names, and `require` reaches whatever the interface runtime
/// registered.
///
/// Anything asking for a module the engine was not given is a bundler's job.
/// That is not a shortcoming: it is how every engine of this shape works, and
/// a bundle is one file rather than a resolver at runtime.
class ScriptModule {
  const ScriptModule._();

  /// One compiled file, ready for the engine.
  ///
  /// Give it a [name] to keep what the file exported, so that the host can
  /// reach it afterwards: a script holding its state in a module is the
  /// ordinary case, and a game has to be able to write into that state.
  /// Without one the file is run for its effects and its exports are dropped.
  static String around(String compiled, {String? name}) {
    final body = '(function () {\n'
        'var module = { exports: {} };\n'
        'var exports = module.exports;\n'
        'var require = globalThis.require;\n'
        '$compiled\n'
        'return module.exports;\n'
        '})()';

    if (name == null) return '$body;';
    return 'globalThis.__orbis_modules[${_quoted(name)}] = $body;';
  }

  /// A JavaScript string literal. Names come from callers, and a caller with a
  /// quote in one should get a working script rather than a syntax error.
  static String _quoted(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
