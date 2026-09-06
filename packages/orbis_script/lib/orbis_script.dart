/// The Orbis scripting runtime.
///
/// Runs JavaScript and TypeScript on QuickJS. The engine bindings this exists
/// to serve arrive in S1; for now this is the host, its lifetime, and the
/// error path that carries a JavaScript stack back into Dart.
library;

export 'src/host.dart' show ScriptError, ScriptHost;
export 'src/module.dart' show ScriptModule;
