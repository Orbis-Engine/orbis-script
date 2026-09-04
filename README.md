# orbis-script

The [Orbis](https://github.com/Orbis-Engine/orbis) scripting runtime. Game logic
in TypeScript, on QuickJS, calling the engine's C ABI directly.

Orbis keeps its components in a C++ core behind a C ABI, and QuickJS is C, so
script talks to the engine without Dart in the path. TypeScript is a peer of
Dart here, not a guest inside it, and that shapes everything below: the shim is
C, the boundary is handles and buffers, and a system reads component columns
rather than asking about entities one at a time.

```sh
git submodule update --init --recursive
cd packages/orbis_script && dart test
```

```sh
./tool/check.sh          # both packages, plus the typings through tsc
```

## Status

**S0 done** — the VM runs. Evaluation, JavaScript stacks carried into Dart
exceptions, microtask pumping, and unhandled promise rejections surfaced rather
than dropped.

**S2 done** — `orbis_script_codegen` reads the component manifests an Orbis
workspace publishes and emits TypeScript typings for them. It reads JSON and
nothing else, so it learns what the engine declares without depending on the
engine at all — the two repositories share a contract, not a build.

**S1 next** — binding the engine's C ABI, so the typings describe something a
script can actually call.

## Licence

MIT. Bundles quickjs-ng, also MIT.
