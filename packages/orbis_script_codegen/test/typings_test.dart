import 'package:orbis_script_codegen/orbis_script_codegen.dart';
import 'package:test/test.dart';

String manifest(String components, {int version = 1, String package = 'game'}) =>
    '{"formatVersion": $version, "package": "$package", '
    '"components": [$components]}';

const velocity = '''
  {"name":"Velocity","class":"Velocity","kind":"float32","arity":3,
   "fields":["x","y","z"],"replicated":true,"ownerWritable":true,
   "source":"lib/components.dart"}
''';

const networkId = '''
  {"name":"NetworkId","class":"NetworkId","kind":"int64","arity":1,
   "fields":["value"],"replicated":false,"source":"lib/components.dart"}
''';

List<ManifestComponent> parse(String json) =>
    const ManifestReader().parse(json, 'test.json');

void main() {
  group('reading a manifest', () {
    test('reads a component', () {
      final component = parse(manifest(velocity)).single;
      expect(component.name, 'Velocity');
      expect(component.kind, 'float32');
      expect(component.arity, 3);
      expect(component.fields, ['x', 'y', 'z']);
      expect(component.replicated, isTrue);
      expect(component.ownerWritable, isTrue);
      expect(component.package, 'game');
    });

    test('a missing ownerWritable reads as false', () {
      expect(parse(manifest(networkId)).single.ownerWritable, isFalse);
    });

    test('a newer format version is refused rather than guessed at', () {
      expect(
        () => parse(manifest(velocity, version: 2)),
        throwsA(isA<ManifestError>().having((e) => e.message, 'message',
            contains('this build reads 1'))),
      );
    });

    test('malformed JSON is refused with the parser\'s complaint', () {
      expect(() => parse('{not json'), throwsA(isA<ManifestError>()));
    });

    test('a top-level array is refused', () {
      expect(() => parse('[]'), throwsA(isA<ManifestError>()));
    });
  });

  group('emitting typings', () {
    String emit(String json) =>
        const TypeScriptEmitter().emit(parse(json));

    test('an interface per component, with its fields', () {
      final output = emit(manifest('$velocity, $networkId'));
      expect(output, contains('export interface Velocity {'));
      expect(output, contains('  x: number;'));
      expect(output, contains('  z: number;'));
    });

    test('an int64 component is bigint, not number', () {
      final output = emit(manifest(networkId));
      expect(output, contains('export interface NetworkId {\n  value: bigint;'));
      expect(output, contains('NetworkId: BigInt64Array;'));
    });

    test('entity handles are branded so a number cannot stand in', () {
      final output = emit(manifest(velocity));
      expect(output, contains('export type Entity = bigint & {'));
      expect(output, contains('readonly __orbisEntity: unique symbol;'));
    });

    test('arity is a constant per component, not a literal to remember', () {
      final output = emit(manifest('$velocity, $networkId'));
      expect(output, contains('readonly Velocity: 3;'));
      expect(output, contains('readonly NetworkId: 1;'));
    });

    test('replication shows up as a union of names', () {
      final output = emit(manifest('$velocity, $networkId'));
      expect(output,
          contains("replicatedComponents: readonly 'Velocity'[]"));
      expect(output,
          contains("ownerWritableComponents: readonly 'Velocity'[]"));
    });

    test('two replicated components are bracketed before the array', () {
      const health = '''
        {"name":"Health","class":"Health","kind":"int32","arity":2,
         "fields":["current","max"],"replicated":true,
         "source":"lib/components.dart"}
      ''';
      final output = emit(manifest('$velocity, $health'));
      expect(output,
          contains("replicatedComponents: readonly ('Health' | 'Velocity')[]"),
          reason: "without the brackets this parses as a union of 'Health' "
              'and an array of Velocity — a different type, and a valid one, '
              'so only a type checker catches it');
    });

    test('nothing replicated gives never, which refuses a name', () {
      final output = emit(manifest(networkId));
      expect(output, contains('replicatedComponents: readonly never[]'));
    });

    test('the doc comment says where a component came from', () {
      final output = emit(manifest(velocity));
      expect(output, contains('from game'));
      expect(output, contains('writable by the client that owns the entity'));
    });

    test('a local component says so, rather than saying nothing', () {
      expect(emit(manifest(networkId)),
          contains('Local to whichever machine it is on'));
    });

    test('a workspace with no components still emits a usable surface', () {
      final output = emit(manifest(''));
      expect(output, contains('export interface Components {'));
      expect(output, contains('export declare const world'));
      expect(output, contains('readonly never[]'));
    });

    test('the world doc steers systems towards queries', () {
      final output = emit(manifest(velocity));
      expect(output, contains('crosses once per tick'),
          reason: 'a type that permits per-entity access is read as an '
              'invitation unless the documentation says otherwise');
    });
  });
}
