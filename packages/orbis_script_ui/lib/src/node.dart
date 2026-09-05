import 'dart:convert';

/// One element of an interface, as script describes it.
///
/// A description rather than a widget: script says what it wants and Dart
/// builds it. That is one crossing per change instead of a stream of
/// per-property operations, and it means the widget tree is real Flutter —
/// laid out by Flutter, hit-tested by Flutter, and drawn by Impeller — rather
/// than a second tree pretending to be one.
class UiNode {
  const UiNode({
    required this.type,
    this.classes = '',
    this.css = '',
    this.text,
    this.props = const {},
    this.children = const [],
    this.key,
  });

  /// What to build: `column`, `row`, `stack`, `box`, `text`, `button`,
  /// `image`, `spacer`, `field`, or anything a host has registered.
  final String type;

  /// A utility class list, applied first.
  final String classes;

  /// CSS declarations, applied over the classes.
  final String css;

  /// The words, for the elements that have any.
  final String? text;

  /// Everything else the element needs: an image's source, a field's
  /// placeholder, the name of a callback.
  final Map<String, Object?> props;

  final List<UiNode> children;

  /// What this element is, across rebuilds. Flutter uses it to keep state on
  /// the right widget when a list is reordered.
  final String? key;

  /// Reads a description sent as JSON.
  ///
  /// Forgiving on purpose. Script is written by hand and reloaded on save, so
  /// a half-finished tree arriving mid-edit is the normal case rather than the
  /// exception — an element with no type becomes an empty box rather than an
  /// exception thrown into a frame.
  factory UiNode.fromJson(Object? value) {
    if (value is String) return UiNode(type: 'text', text: value);
    if (value is! Map) return const UiNode(type: 'box');

    final map = value.cast<String, Object?>();
    final children = map['children'];

    return UiNode(
      type: map['type'] is String ? map['type']! as String : 'box',
      classes: map['class'] is String
          ? map['class']! as String
          : (map['className'] is String ? map['className']! as String : ''),
      css: map['style'] is String ? map['style']! as String : '',
      text: map['text'] is String ? map['text']! as String : null,
      props: map['props'] is Map
          ? (map['props']! as Map).cast<String, Object?>()
          : const {},
      key: map['key'] is String ? map['key']! as String : null,
      children: children is List
          ? [for (final child in children) UiNode.fromJson(child)]
          : const [],
    );
  }

  /// Reads a whole description from the text script returned.
  static UiNode decode(String source) {
    final Object? parsed;
    try {
      parsed = jsonDecode(source);
    } on FormatException catch (error) {
      return UiNode(
        type: 'text',
        text: 'The interface could not be read: ${error.message}',
      );
    }
    return UiNode.fromJson(parsed);
  }

  Map<String, Object?> toJson() => {
    'type': type,
    if (classes.isNotEmpty) 'class': classes,
    if (css.isNotEmpty) 'style': css,
    if (text != null) 'text': text,
    if (props.isNotEmpty) 'props': props,
    if (key != null) 'key': key,
    if (children.isNotEmpty)
      'children': [for (final child in children) child.toJson()],
  };

  /// The name of the callback for an event, if script gave one.
  ///
  /// Callbacks cross as names rather than as functions: a function cannot be
  /// serialised, and a name is what the host calls back with when the button
  /// is pressed.
  String? handlerFor(String event) {
    final value = props[event];
    return value is String && value.isNotEmpty ? value : null;
  }
}
