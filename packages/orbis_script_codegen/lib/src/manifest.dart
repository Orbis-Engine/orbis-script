import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// One component, as a manifest describes it.
class ManifestComponent {
  const ManifestComponent({
    required this.name,
    required this.kind,
    required this.arity,
    required this.fields,
    required this.replicated,
    required this.ownerWritable,
    required this.package,
  });

  factory ManifestComponent.fromJson(
      Map<String, Object?> json, String package) {
    return ManifestComponent(
      name: json['name']! as String,
      kind: json['kind']! as String,
      arity: json['arity']! as int,
      fields: [
        for (final field in json['fields']! as List<Object?>) field! as String,
      ],
      replicated: json['replicated'] as bool? ?? false,
      ownerWritable: json['ownerWritable'] as bool? ?? false,
      package: package,
    );
  }

  final String name;
  final String kind;
  final int arity;
  final List<String> fields;
  final bool replicated;
  final bool ownerWritable;

  /// Which package declared it, for the doc comment — a script author looking
  /// at a name they do not recognise should be able to find where it came from.
  final String package;
}

/// Thrown when a manifest cannot be read as one.
class ManifestError implements Exception {
  const ManifestError(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'ManifestError($path): $message';
}

/// Finds and reads the manifests a workspace publishes.
///
/// Reads only JSON. That is the point of the manifest: a typings generator can
/// learn what every package in a workspace declares without building any of
/// them, and without this repository depending on the engine at all.
class ManifestReader {
  const ManifestReader({this.fileName = 'orbis_components.json'});

  final String fileName;

  /// Every manifest under [root], deepest paths last so the listing is stable.
  List<ManifestComponent> read(String root) {
    final directory = Directory(root);
    if (!directory.existsSync()) return const [];

    final manifests = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => p.basename(file.path) == fileName)
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final components = <ManifestComponent>[];
    final seen = <String, String>{};

    for (final file in manifests) {
      for (final component in parse(file.readAsStringSync(), file.path)) {
        final previous = seen[component.name];
        if (previous != null && previous != component.package) {
          throw ManifestError(
              file.path,
              'component "${component.name}" is declared by both $previous '
              'and ${component.package}. A name is what crosses the wire, so '
              'two packages cannot both own one');
        }
        seen[component.name] = component.package;
        components.add(component);
      }
    }

    components.sort((a, b) => a.name.compareTo(b.name));
    return components;
  }

  /// Parses one manifest's contents.
  List<ManifestComponent> parse(String contents, String path) {
    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error) {
      throw ManifestError(path, 'not valid JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw ManifestError(path, 'expected an object at the top level');
    }

    final version = decoded['formatVersion'];
    if (version != 1) {
      // Refused rather than guessed at: a manifest from a newer engine may
      // describe layouts this generator would silently get wrong.
      throw ManifestError(
          path, 'format version $version, but this build reads 1');
    }

    final package = decoded['package'] as String? ?? 'unknown';
    final components = decoded['components'] as List<Object?>? ?? const [];
    // Sorted here rather than only where several manifests are merged, so the
    // order does not depend on which entry point the caller used and the
    // emitted typings are reproducible.
    return [
      for (final component in components)
        ManifestComponent.fromJson(component! as Map<String, Object?>, package),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }
}
