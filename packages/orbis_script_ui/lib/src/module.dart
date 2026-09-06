/// Running a compiled TypeScript file in the engine.
///
/// TypeScript emits a file that expects to be a module: it assigns to
/// `exports`, and asks for what it imported through `require`. The engine has
/// neither — it evaluates a script, and there is nothing on the other side to
/// import from.
///
/// So a compiled file is wrapped before it is run. Each gets its own `exports`
/// and `module`, which is what stops two scripts writing over each other's
/// top-level names, and `require` reaches the library the interface runtime
/// registered.
///
/// Anything asking for a module the engine was not given is a bundler's job.
/// That is not a shortcoming: it is how every engine of this shape works, and
/// a bundle is one file rather than a resolver at runtime.
class ScriptModule {
  const ScriptModule._();

  /// One compiled file, ready for the engine.
  ///
  /// [name] appears in a stack trace, so it is worth being the path somebody
  /// would recognise.
  static String around(String compiled) => '(function () {\n'
      'var module = { exports: {} };\n'
      'var exports = module.exports;\n'
      'var require = globalThis.require;\n'
      '$compiled\n'
      'return module.exports;\n'
      '})();';
}
