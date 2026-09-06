import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbis_script/orbis_script.dart';
import 'package:orbis_script_ui/orbis_script_ui.dart';

/// The whole chain, in one test.
///
/// Script runs in the real engine, describes an interface, and Flutter builds
/// real widgets from it. Every other test in this package starts from a
/// description that Dart wrote, which proves the builder and nothing about
/// where a description comes from — and where it comes from is the entire
/// point of the thing.
///
/// The script here is plain JavaScript rather than the TypeScript in `js/`,
/// because compiling that needs a TypeScript compiler and there is not one on
/// this machine. What it does is exactly what the compiled library does: build
/// the same plain objects and hand them over as JSON on `__orbis_ui`.
void main() {
  group('script drives the interface', () {
    late ScriptHost host;

    setUp(() => host = ScriptHost());
    tearDown(() => host.dispose());

    /// The part of `js/ui.ts` this test needs, as the JavaScript it compiles
    /// to: elements, components, and the same handler-by-name arrangement.
    const runtime = r'''
      var handlers = {};
      var counted = 0;

      function element(type, props, children) {
        props = props || {};
        var node = { type: type };
        var passed = {};
        for (var name in props) {
          if (name === 'class' || name === 'style' || name === 'key') continue;
          var value = props[name];
          if (typeof value === 'function') {
            var handle = props.key ? props.key + ':' + name : 'h' + (++counted);
            handlers[handle] = value;
            passed[name] = handle;
          } else {
            passed[name] = value;
          }
        }
        if (props.class) node.class = props.class;
        if (props.style) node.style = props.style;
        if (props.key) node.key = props.key;
        if (Object.keys(passed).length) node.props = passed;

        var flat = [];
        (children || []).forEach(function (child) {
          if (child === null || child === undefined || child === false) return;
          flat.push(
            typeof child === 'object' ? child : { type: 'text', text: String(child) }
          );
        });
        // Some elements carry words rather than children, and in JSX the
        // words are written where children go: <text>Hello</text>.
        var worded = type === 'text' || type === 'button' || type === 'field';
        if (worded && flat.length &&
            flat.every(function (c) { return c.type === 'text' && !c.children; })) {
          node.text = flat.map(function (c) { return c.text || ''; }).join('');
          return node;
        }

        if (flat.length) node.children = flat;
        return node;
      }

      // What JSX compiles to: a string tag is an element, a function tag is a
      // component, and calling it is all that rendering one means.
      function h(tag, props) {
        var children = Array.prototype.slice.call(arguments, 2);
        if (typeof tag === 'function') {
          var given = Object.assign({}, props || {});
          given.children = children;
          return tag(given);
        }
        return element(tag, props, children);
      }

      var describe = function () { return { type: 'box' }; };
      globalThis.__orbis_ui = {
        mount: function (root) { describe = root; },
        render: function () { return JSON.stringify(describe()); },
        dispatch: function (name, payload) {
          var handler = handlers[name];
          if (handler) handler(payload);
        },
      };
    ''';

    test('an interface written as components comes back as widgets', () async {
      // A component is a function from props to an element. No class, no
      // state, no lifecycle — those exist to drive a reconciler, and the
      // reconciler here is Flutter's.
      host.eval(runtime);
      host.eval(r'''
        var count = 0;

        function Counter(props) {
          return h('column', { class: 'p-4 gap-2 bg-slate-800 rounded-lg' },
            h('text', { class: 'text-lg font-bold text-slate-100' }, props.title),
            h('text', { class: 'text-slate-300' }, 'Pressed ' + count + ' times'),
            h('button', { class: 'px-3 py-2 bg-ember-500 rounded', key: 'more',
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
      expect(node.children.first.text, 'From TypeScript');
      expect(node.children[1].text, 'Pressed 0 times');

      // The callback crossed as a name, because a function cannot cross.
      expect(node.children[2].handlerFor('onPressed'), 'more:onPressed');
    });

    test('what the script says is styled by the same class names', () async {
      host.eval(runtime);
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
      // Nothing in it that the vocabulary does not know.
      expect(builder.unknownIn(node), isEmpty);
    });

    test('pressing something reaches the script, and the next render shows it',
        () async {
      host.eval(runtime);
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

    testWidgets('and it lays out as real Flutter widgets', (tester) async {
      host.eval(runtime);
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
