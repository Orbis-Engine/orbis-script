import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbis_script/orbis_script.dart';
import 'package:orbis_script_ui/orbis_script_ui.dart';

/// The whole chain, in one test.
///
/// The library's own TypeScript, compiled, running in the real engine,
/// describing an interface, coming out as real Flutter widgets — and a press
/// going back the other way with the next render showing it.
///
/// Every other test in this package starts from a description that Dart wrote,
/// which proves the builder and nothing at all about where a description comes
/// from. Where it comes from is the entire point of the thing.
///
/// Nothing here is a stand-in: [UiRuntime.source] is exactly what a game
/// loads, generated from `js/ui.ts` by `tool/embed_runtime.dart`.
void main() {
  group('script drives the interface', () {
    late ScriptHost host;

    setUp(() {
      host = ScriptHost();
      host.eval(UiRuntime.source, fileName: 'orbis/ui.js');
    });

    tearDown(() => host.dispose());

    test('the runtime is the compiled library, not a copy of it', () {
      // If this ever fails, the embedded runtime is stale: run
      // `npm run build:ui && dart run tool/embed_runtime.dart`.
      expect(UiRuntime.length, greaterThan(2000));
      expect(host.eval('typeof globalThis.h'), 'function');
      expect(host.eval('typeof globalThis.Fragment'), 'function');
      expect(host.eval('typeof __orbis_ui.render'), 'function');
    });

    test('an interface written as components comes back as widgets', () {
      // A component is a function from props to an element. No class, no
      // state, no lifecycle — those exist to drive a reconciler, and the
      // reconciler here is Flutter's.
      host.eval(r'''
        var count = 0;

        function Counter(props) {
          return h('column', { class: 'p-4 gap-2 bg-slate-800 rounded-lg' },
            h('text', { class: 'text-lg font-bold text-slate-100' }, props.title),
            h('text', { class: 'text-slate-300' }, 'Pressed ' + count + ' times'),
            h('button', { class: 'px-3 py-2 rounded', key: 'more',
                          onPressed: function () { count++; } }, 'One more')
          );
        }

        __orbis_ui.mount(function () {
          return h(Counter, { title: 'From TypeScript' });
        });
      ''');

      final node = UiNode.decode(host.eval('__orbis_ui.render()'));

      expect(node.type, 'column');
      expect(node.classes, contains('bg-slate-800'));
      expect(node.children, hasLength(3));

      // Words written where children go, folded onto the element that carries
      // them — which is what `<text>Hello</text>` has to mean.
      expect(node.children.first.text, 'From TypeScript');
      expect(node.children[1].text, 'Pressed 0 times');

      // The callback crossed as a name, because a function cannot cross.
      expect(node.children[2].handlerFor('onPressed'), 'more:onPressed');
    });

    test('a fragment stands in for several where one is expected', () {
      host.eval(r'''
        __orbis_ui.mount(function () {
          return h(Fragment, null, h('text', {}, 'One'), h('text', {}, 'Two'));
        });
      ''');

      final node = UiNode.decode(host.eval('__orbis_ui.render()'));
      expect(node.children.map((child) => child.text), ['One', 'Two']);
    });

    test('what the script says is styled by the same class names', () {
      host.eval(r'''
        __orbis_ui.mount(function () {
          return h('row', { class: 'p-4 gap-3 items-center' },
            h('text', { class: 'text-xl text-ember-400' }, 'Orbis'));
        });
      ''');

      final builder = UiBuilder();
      final node = UiNode.decode(host.eval('__orbis_ui.render()'));
      final style = builder.styleOf(node);

      expect(style.paddingLeft, 16);
      expect(style.gap, 12);
      expect(style.crossAxis, 'center');
      // Nothing in it the vocabulary does not know.
      expect(builder.unknownIn(node), isEmpty);
    });

    test('CSS written inline lands on the same style as the classes', () {
      host.eval(r'''
        __orbis_ui.mount(function () {
          return h('box', {
            class: 'p-2',
            style: 'background: #223344; border-radius: 6px',
          });
        });
      ''');

      final node = UiNode.decode(host.eval('__orbis_ui.render()'));
      final style = UiBuilder().styleOf(node);

      expect(style.paddingTop, 8);
      expect(style.radius, 6);
      expect(style.background, const Color(0xFF223344));
    });

    test('pressing something reaches the script, and the next render shows it',
        () {
      host.eval(r'''
        var count = 0;
        __orbis_ui.mount(function () {
          return h('button', { key: 'more', onPressed: function () { count++; } },
            'Pressed ' + count);
        });
      ''');

      final first = UiNode.decode(host.eval('__orbis_ui.render()'));
      expect(first.text, 'Pressed 0');

      final handler = first.handlerFor('onPressed')!;
      host.eval('__orbis_ui.dispatch(${jsonEncode(handler)})');

      final second = UiNode.decode(host.eval('__orbis_ui.render()'));
      expect(second.text, 'Pressed 1');
    });

    test('a script that throws surfaces as an error rather than a blank frame',
        () {
      expect(
        () => host.eval('__orbis_ui.mount(function () { throw new Error("no"); });'
            '__orbis_ui.render()'),
        throwsA(isA<ScriptError>()),
      );
    });

    testWidgets('and it lays out as real Flutter widgets', (tester) async {
      host.eval(r'''
        __orbis_ui.mount(function () {
          return h('column', { class: 'p-4 gap-2' },
            h('text', { class: 'text-lg' }, 'One'),
            h('text', {}, 'Two'));
        });
      ''');

      final node = UiNode.decode(host.eval('__orbis_ui.render()'));

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: UiBuilder().build(node))),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
    });
  });
}
