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

export 'src/builder.dart' show UiBuilder, UiEvent;
export 'src/css.dart' show UiCss;
export 'src/node.dart' show UiNode;
export 'src/runtime.g.dart' show UiRuntime;
export 'src/runner.dart' show ScriptedUiView, UiScriptRunner;
export 'src/style.dart' show UiStyle;
export 'src/surface.dart' show ScriptedSurface;
export 'src/theme.dart' show UiTheme;
export 'src/utilities.dart' show UiUtilities, parseColour;
