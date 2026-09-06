import 'package:orbis_script/orbis_script.dart';
import 'package:orbis_script_scene/orbis_script_scene.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

/// Script putting things in the world, in the real engine.
///
/// The JavaScript here is what `scene.ts` compiles to, loaded from
/// [SceneRuntime.source] — not a stand-in for it.
void main() {
  group('spawning from script', () {
    late ScriptHost host;

    setUp(() {
      host = ScriptHost();
      host.eval(SceneRuntime.source, fileName: 'orbis/scene.js');
    });

    tearDown(() => host.dispose());

    List<ScriptedThing> world() =>
        ScriptedThing.decodeAll(host.eval('__orbis_scene.describe()'));

    test('what a script spawns is what comes out', () {
      host.eval(r'''
        var scene = require("scene");
        scene.spawn({ id: "crate", at: [1, 0.5, -3], size: 0.5,
                      colour: "#D9634F", turn: 45 });
      ''');

      final things = world();
      expect(things, hasLength(1));

      final crate = things.single;
      expect(crate.id, 'crate');
      expect(crate.position.x, 1);
      expect(crate.position.z, -3);
      expect(crate.turn, 45);
      expect(crate.scale.x, 0.5);
      expect(crate.colour, 0xD9634F);
    });

    test('a size can be one number or three', () {
      host.eval(r'''
        var scene = require("scene");
        scene.spawn({ id: "even", at: [0, 0, 0], size: 2 });
        scene.spawn({ id: "tall", at: [0, 0, 0], size: [1, 4, 1] });
      ''');

      final things = {for (final thing in world()) thing.id: thing};
      expect(things['even']!.scale, vectorOf(2));
      expect(things['tall']!.scale.y, 4);
      expect(things['tall']!.scale.x, 1);
    });

    test('spawning the same name again moves it rather than doubling it', () {
      // A description says everything, so saying it twice cannot leave two.
      host.eval(r'''
        var scene = require("scene");
        scene.spawn({ id: "one", at: [0, 0, 0] });
        scene.spawn({ id: "one", at: [5, 0, 0] });
      ''');

      expect(world(), hasLength(1));
      expect(world().single.position.x, 5);
    });

    test('what is destroyed is gone, and destroying it twice is not an error',
        () {
      host.eval(r'''
        var scene = require("scene");
        scene.spawn({ id: "gone", at: [0, 0, 0] });
        scene.destroy("gone");
        scene.destroy("gone");
      ''');
      expect(world(), isEmpty);
    });

    test('a frame runs the script step and then says what is there', () {
      // How a game loop looks from here: the host asks for a frame, the script
      // moves what it likes, and what comes back is the whole world.
      host.eval(r'''
        var scene = require("scene");
        scene.spawn({ id: "walker", at: [0, 0, 0] });
        scene.onFrame(function (seconds) {
          scene.spawn({ id: "walker", at: [seconds * 2, 0, 0] });
        });
      ''');

      final first =
          ScriptedThing.decodeAll(host.eval('__orbis_scene.frame(1.5)'));
      expect(first.single.position.x, 3);

      final second =
          ScriptedThing.decodeAll(host.eval('__orbis_scene.frame(4)'));
      expect(second.single.position.x, 8);
    });

    test('a thousand things is one message, not a thousand', () {
      host.eval(r'''
        var scene = require("scene");
        for (var i = 0; i < 1000; i++) {
          scene.spawn({ id: "t" + i, at: [i % 40, 0, Math.floor(i / 40)] });
        }
      ''');
      expect(world(), hasLength(1000));
      expect(host.eval('String(require("scene").count())'), '1000');
    });

    test('half a thing still arrives somewhere rather than throwing', () {
      // Script is written by hand and reloaded on save, so something
      // half-finished arriving mid-edit is the ordinary case. It goes to the
      // origin at a metre across, which is visible and obviously wrong —
      // better than an exception thrown into a frame.
      host.eval(r'''
        var scene = require("scene");
        scene.spawn({ id: "vague" });
      ''');

      final vague = world().single;
      expect(vague.position, vectorOf(0));
      expect(vague.scale, vectorOf(1));
    });

    test('anything that is not a list of things is nothing', () {
      expect(ScriptedThing.decodeAll('not json at all'), isEmpty);
      expect(ScriptedThing.decodeAll('{"id":"x"}'), isEmpty);
      expect(ScriptedThing.decodeAll('[1, 2, 3]'), isEmpty);
      // A thing with no name cannot be kept track of, so it is not kept.
      expect(ScriptedThing.decodeAll('[{"at":[0,0,0]}]'), isEmpty);
    });
  });
}

/// Reads better than three closeTo lines.
Matcher vectorOf(double value) => predicate(
      (Object? got) =>
          got is Vector3 &&
          (got.x - value).abs() < 1e-9 &&
          (got.y - value).abs() < 1e-9 &&
          (got.z - value).abs() < 1e-9,
      'a vector of $value',
    );
