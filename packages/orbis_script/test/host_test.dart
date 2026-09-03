import 'package:orbis_script/orbis_script.dart';
import 'package:test/test.dart';

void main() {
  late ScriptHost host;

  setUp(() => host = ScriptHost());
  tearDown(() => host.dispose());

  test('reports the vendored engine version', () {
    expect(ScriptHost.engineVersion, matches(r'^\d+\.\d+\.\d+'));
  });

  test('evaluates an expression', () {
    expect(host.eval('1 + 1'), '2');
  });

  test('keeps state between evaluations', () {
    host.eval('globalThis.counter = 0;');
    host.eval('globalThis.counter += 7;');
    expect(host.eval('globalThis.counter'), '7');
  });

  test('surfaces a thrown error as a Dart exception with a JS stack', () {
    expect(
      () => host.eval('function boom() { throw new Error("kaboom"); }\nboom();',
          fileName: 'behaviour.js'),
      throwsA(
        isA<ScriptError>()
            .having((e) => e.message, 'message', contains('kaboom'))
            // The stack is the point: it must name the throwing function and
            // the file the caller passed, not just the message.
            .having((e) => e.message, 'stack', contains('boom'))
            .having((e) => e.message, 'file', contains('behaviour.js')),
      ),
    );
  });

  test('a syntax error is reported, not crashed on', () {
    expect(() => host.eval('function ('), throwsA(isA<ScriptError>()));
  });

  test('pumping runs queued microtasks', () {
    host.eval('globalThis.resolved = 0;'
        'Promise.resolve(41).then((v) => { globalThis.resolved = v + 1; });');

    expect(host.eval('globalThis.resolved'), '0',
        reason: 'microtasks must not run until the host pumps them');
    expect(host.pumpMicrotasks(), greaterThanOrEqualTo(1));
    expect(host.eval('globalThis.resolved'), '42');
  });

  test('pumping an empty queue is a no-op', () {
    expect(host.pumpMicrotasks(), 0);
  });

  test('a throwing microtask surfaces on pump', () {
    host.eval('Promise.resolve().then(() => { throw new Error("in a job"); });');
    expect(host.pumpMicrotasks, throwsA(isA<ScriptError>()));
  });

  test('use after dispose is refused rather than crashing', () {
    final other = ScriptHost()..dispose();
    expect(other.isDisposed, isTrue);
    expect(() => other.eval('1'), throwsA(isA<StateError>()));
    expect(other.dispose, returnsNormally);
  });
}
