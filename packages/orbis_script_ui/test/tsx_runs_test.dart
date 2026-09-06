import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbis_script/orbis_script.dart';
import 'package:orbis_script_ui/orbis_script_ui.dart';

import 'panel_tsx.g.dart';

/// A real `.tsx` file, through the real TypeScript compiler, in the real
/// engine, out as real widgets.
///
/// [panelFromTsx] is the compiled output of `example/panel.tsx` — components,
/// props, JSX with the automatic runtime, and no import of any factory. Every
/// other test writes JavaScript by hand, which proves the engine and nothing
/// about whether anybody could actually write this in TypeScript.
void main() {
  group('a TypeScript interface', () {
    late ScriptHost host;

    setUp(() {
      host = ScriptHost();
      host.eval(UiRuntime.source, fileName: 'orbis/ui.js');
      host.eval(
        ScriptModule.around(panelFromTsx),
        fileName: 'example/panel.tsx',
      );
    });

    tearDown(() => host.dispose());

    test('runs, and describes what it was written to describe', () {
      final panel = UiNode.decode(host.eval('__orbis_ui.render()'));

      expect(panel.type, 'column');
      expect(panel.classes, contains('bg-slate-800'));

      // A heading, two readings, and a row of two buttons.
      expect(panel.children, hasLength(4));
      expect(panel.children.first.text, 'Scene');

      // Components nested inside components, each just a function that was
      // called: <Reading label="Objects" value={...} />.
      final objects = panel.children[1];
      expect(objects.type, 'row');
      expect(objects.children.first.text, 'Objects');
      expect(objects.children[1].text, '0');

      expect(panel.children[2].children.first.text, 'Renderer');
      expect(panel.children[2].children[1].text, 'Filament');
    });

    test('found its factory without any file importing one', () {
      // The automatic runtime. `"jsx": "react-jsx"` with `jsxImportSource`
      // pointed at this library, so a .tsx file is only its own interface.
      expect(panelFromTsx, contains('require("orbis/jsx-runtime")'));
      // Not React's factory, and nothing from node_modules: the tags compile
      // straight to this library's own.
      expect(panelFromTsx, isNot(contains('createElement')));
    });

    test('everything it asks for is in the vocabulary', () {
      final builder = UiBuilder();
      final panel = UiNode.decode(host.eval('__orbis_ui.render()'));
      expect(builder.unknownIn(panel), isEmpty);
    });

    test('pressing a button written in TypeScript changes what it describes',
        () {
      final panel = UiNode.decode(host.eval('__orbis_ui.render()'));
      final buttons = panel.children[3];

      final spawn = buttons.children.first;
      expect(spawn.text, 'Spawn');

      final handler = spawn.handlerFor('onPressed')!;
      host.eval('__orbis_ui.dispatch(${jsonEncode(handler)})');
      host.eval('__orbis_ui.dispatch(${jsonEncode(handler)})');

      final after = UiNode.decode(host.eval('__orbis_ui.render()'));
      expect(after.children[1].children[1].text, '2');
    });

    test('a module it was never given is refused by name', () {
      // Single files run without a bundler because the library registers
      // itself. Anything larger is a bundler's job, and saying so beats a
      // reference error somewhere inside the compiled output.
      expect(
        () => host.eval('require("react")'),
        throwsA(
          isA<ScriptError>().having(
            (error) => error.message,
            'message',
            allOf(contains('react'), contains('bundled')),
          ),
        ),
      );
    });

    testWidgets('and it lays out', (tester) async {
      final panel = UiNode.decode(host.eval('__orbis_ui.render()'));

      // Given a width rather than taking one. A widget test measures text
      // with a font whose every glyph is a square of the font size, so a panel
      // that fits comfortably in a real one can overflow here by a few pixels
      // and fail on something that would never happen.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 420, child: UiBuilder().build(panel)),
          ),
        ),
      );

      expect(find.text('Scene'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
      expect(find.text('Filament'), findsOneWidget);
      expect(find.text('Spawn'), findsOneWidget);
    });
  });
}
