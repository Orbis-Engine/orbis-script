/// TypeScript's way into an interface.
///
/// The model and the widgets are `orbis_ui`, which is engine: a canvas laid
/// out by hand in the editor and a tree described in TypeScript are the same
/// document, and this package is one of the two ways to author it. What is
/// here is the part that is actually about script — running it, watching it,
/// and putting what it returned on screen.
///
/// The original description, which is still what the whole layer is for:
///
/// An interface described in TypeScript and built in Flutter.
///
/// One widget vocabulary rather than two. A script describes a tree — boxes,
/// rows, text, buttons — with a utility class list or a block of CSS on each
/// element, and this builds the real Flutter widgets for it. There is no
/// reconciler and no retained tree in between: the description arrives whole,
/// the widgets are built from it, and Flutter lays out, hit-tests and draws
/// exactly as it does for everything else in the application.
///
/// The styling is where the borrowed vocabulary is. `p-4 flex-1 items-center
/// bg-slate-800 rounded-lg` means what somebody who has written a web page
/// expects it to mean, and `padding: 8px 12px; border-radius: 6px` means the
/// same thing in the other notation. Both resolve to Flutter's own layout, so
/// the familiar words are a way in rather than a second box model to keep
/// aligned forever.
library;

export 'package:orbis_ui/orbis_ui.dart';

export 'src/runtime.g.dart' show UiRuntime;
export 'src/runner.dart' show ScriptedUiView, UiScriptRunner;
