import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// QuickJS and the shim compile into one library the Dart host opens over FFI.
///
/// Four sources are the whole engine — quickjs-ng consolidated the rest — so
/// they are listed rather than discovered, which keeps an accidental addition
/// to the submodule out of the build.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final root = input.packageRoot;
    final qjs = root.resolve('native/quickjs-ng/');
    final shim = root.resolve('native/shim/');

    final builder = CBuilder.library(
      name: 'orbis_script',
      assetName: 'orbis_script',
      sources: [
        shim.resolve('orbis_script.c').toFilePath(),
        qjs.resolve('quickjs.c').toFilePath(),
        qjs.resolve('dtoa.c').toFilePath(),
        qjs.resolve('libregexp.c').toFilePath(),
        qjs.resolve('libunicode.c').toFilePath(),
      ],
      includes: [qjs.toFilePath(), shim.toFilePath()],
      // quickjs-ng's own build sets this for every target; without it the
      // sources fall back to a reduced libc surface and fail to compile.
      defines: {'_GNU_SOURCE': '1'},
      language: Language.c,
    );

    await builder.run(input: input, output: output, logger: null);
  });
}
