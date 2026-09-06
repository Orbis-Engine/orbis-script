import 'package:flutter/material.dart';
import 'package:orbis_ui/orbis_ui.dart';



/// Whatever can run a line of script and hand back what it returned.
///
/// An interface rather than the scripting host itself, so this package builds
/// and tests without a native toolchain, a submodule or a virtual machine —
/// and so the same widget can be driven by a file being watched, a network
/// message or a test, none of which are QuickJS.
abstract interface class UiScriptRunner {
  /// Evaluates [source] and returns its result as text.
  ///
  /// Throws whatever the runtime throws. The view catches it and shows it,
  /// because an interface that vanishes when a script has a typo in it is an
  /// interface nobody can debug.
  String evaluate(String source);
}

/// An interface a script describes, drawn and kept up to date.
///
/// The loop is deliberately plain: ask the script what the interface looks
/// like, build it, and when somebody presses something tell the script and ask
/// again. One crossing per change rather than a stream of per-property
/// operations, and no tree kept on both sides to fall out of step.
class ScriptedUiView extends StatefulWidget {
  const ScriptedUiView({
    super.key,
    required this.runner,
    this.render = 'globalThis.__orbis_ui.render()',
    this.dispatch = '__orbis_ui.dispatch',
    this.theme = const UiTheme(),
    this.fontFamily,
    this.onError,
  });

  final UiScriptRunner runner;

  /// What to evaluate to get the interface.
  final String render;

  /// The function to call when something is pressed.
  final String dispatch;

  final UiTheme theme;
  final String? fontFamily;

  /// Told when the script fails, so a host can log it or put it in a console.
  final ValueChanged<Object>? onError;

  @override
  State<ScriptedUiView> createState() => _ScriptedUiViewState();
}

class _ScriptedUiViewState extends State<ScriptedUiView> {
  UiNode _description = const UiNode(type: 'box');
  String? _failure;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(ScriptedUiView old) {
    super.didUpdateWidget(old);
    if (old.runner != widget.runner || old.render != widget.render) _ask();
  }

  /// Asks the script what the interface looks like now.
  void _ask() {
    try {
      final described = widget.runner.evaluate(widget.render);
      setState(() {
        _description = UiNode.decode(described);
        _failure = null;
      });
    } on Object catch (error) {
      // Shown rather than thrown. A script is edited while it is running, and
      // the half of the second where it does not compile should not take the
      // application with it.
      widget.onError?.call(error);
      setState(() => _failure = '$error');
    }
  }

  void _send(String handler, Object? payload) {
    final argument = payload == null
        ? ''
        : ', ${_quote(payload.toString())}';
    try {
      widget.runner.evaluate(
        '${widget.dispatch}(${_quote(handler)}$argument)',
      );
    } on Object catch (error) {
      widget.onError?.call(error);
      setState(() => _failure = '$error');
      return;
    }
    // Whatever the handler did, the interface may look different now.
    _ask();
  }

  static String _quote(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return UiSurface(
        theme: widget.theme,
        fontFamily: widget.fontFamily,
        description: UiNode(
          type: 'box',
          classes: 'p-4 bg-slate-900 rounded-md border border-rose-500',
          children: [
            UiNode(
              type: 'text',
              classes: 'text-sm text-rose-300',
              text: failure,
            ),
          ],
        ),
      );
    }

    return UiSurface(
      description: _description,
      theme: widget.theme,
      fontFamily: widget.fontFamily,
      onEvent: _send,
    );
  }
}
