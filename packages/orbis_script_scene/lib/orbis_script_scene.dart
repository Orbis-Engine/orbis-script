/// Game objects described from TypeScript.
///
/// Script says what is in the world and where; what a renderer makes of that
/// is the renderer's business. Nothing in this package draws anything, and
/// nothing in it knows what a renderer is — which is what lets the same script
/// run in the editor, in a game, and on a front end with no Flutter in it.
library;

export 'src/runtime.g.dart' show SceneRuntime;
export 'src/thing.dart' show ScriptedThing;
