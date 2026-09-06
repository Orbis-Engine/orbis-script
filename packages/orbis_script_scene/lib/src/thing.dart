import 'dart:convert';

import 'package:vector_math/vector_math_64.dart';

/// One thing in the world, as script describes it.
///
/// A description rather than an object the script holds a handle to. Script
/// says what is in the world and the engine works out what changed, the same
/// way the interface works — which means there is no state on the wire to fall
/// out of step, and a script that is reloaded mid-frame cannot leave the world
/// half-built.
///
/// Nothing here knows what a renderer is. A thing has a place, a size, a turn
/// and a colour; turning that into a particular renderer's idea of an object
/// is whoever is drawing.
class ScriptedThing {
  const ScriptedThing({
    required this.id,
    required this.position,
    this.turn = 0,
    required this.scale,
    this.colour = 0xB0B6BE,
    this.mesh,
  });

  /// What this is, across frames. The renderer keeps what it built against it.
  final String id;

  /// Metres, in the world's own axes.
  final Vector3 position;

  /// Degrees about the upright axis. Most things only ever turn that way, and
  /// a script that needs more can say so in its own terms and send a mesh.
  final double turn;

  final Vector3 scale;

  /// `0xRRGGBB`, as somebody writes a colour. Converting it to whatever a
  /// renderer wants is the renderer's business.
  final int colour;

  /// A model to draw instead of the built-in cube.
  final String? mesh;

  /// Everything in the world, from what script sent.
  ///
  /// Forgiving on purpose. Script is written by hand and reloaded on save, so
  /// a half-finished thing arriving mid-edit is the ordinary case rather than
  /// the exception — a thing with no place goes to the origin rather than
  /// throwing an exception into a frame.
  static List<ScriptedThing> decodeAll(String source) {
    final Object? parsed;
    try {
      parsed = jsonDecode(source);
    } on FormatException {
      return const [];
    }
    if (parsed is! List) return const [];

    final things = <ScriptedThing>[];
    for (final entry in parsed) {
      if (entry is! Map) continue;
      final map = entry.cast<String, Object?>();
      final id = map['id'];
      if (id is! String || id.isEmpty) continue;
      things.add(ScriptedThing.fromJson(id, map));
    }
    return things;
  }

  factory ScriptedThing.fromJson(String id, Map<String, Object?> map) {
    return ScriptedThing(
      id: id,
      position: _triple(map['at'], 0),
      turn: _number(map['turn'], 0),
      scale: _size(map['size']),
      colour: _colour(map['colour']),
      mesh: map['mesh'] is String && (map['mesh']! as String).isNotEmpty
          ? map['mesh']! as String
          : null,
    );
  }

  static double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : fallback;

  static Vector3 _triple(Object? value, double fallback) {
    if (value is! List || value.length < 3) {
      return Vector3.all(fallback);
    }
    return Vector3(
      _number(value[0], fallback),
      _number(value[1], fallback),
      _number(value[2], fallback),
    );
  }

  /// One number for all three, or one each, or a metre.
  static Vector3 _size(Object? value) {
    if (value is num) return Vector3.all(value.toDouble());
    if (value is List && value.length >= 3) return _triple(value, 1);
    return Vector3.all(1);
  }

  /// `#RRGGBB`, or `#RGB`, or nothing.
  static int _colour(Object? value) {
    if (value is num) return value.toInt() & 0xFFFFFF;
    if (value is! String) return 0xB0B6BE;

    final digits = value.startsWith('#') ? value.substring(1) : value;
    final expanded = switch (digits.length) {
      3 => '${digits[0]}${digits[0]}${digits[1]}${digits[1]}'
          '${digits[2]}${digits[2]}',
      6 => digits,
      // Written with an alpha it does not have. The colour is the last six.
      8 => digits.substring(0, 6),
      _ => null,
    };
    if (expanded == null) return 0xB0B6BE;
    return int.tryParse(expanded, radix: 16) ?? 0xB0B6BE;
  }

  @override
  String toString() => 'ScriptedThing($id at $position)';
}
