# orbis-script

The [Orbis](https://github.com/Orbis-Engine/orbis) scripting runtime. Game logic
in TypeScript, on QuickJS, calling the engine's C ABI directly.

Not a port. Orbis keeps its components in a C++ core behind a C ABI, and QuickJS
is C, so script talks to the engine without Dart in the path — TypeScript is a
peer of Dart here, not a guest inside it. Design owes a debt to
[OneJS](https://github.com/Singtaa/OneJS), which does the equivalent job for a
runtime shaped nothing like this one.

```sh
git submodule update --init --recursive
cd packages/orbis_script && dart test
```

## Status

**S0 done** — the VM runs. Evaluation, JavaScript stacks carried into Dart
exceptions, microtask pumping, and unhandled promise rejections surfaced rather
than dropped. S1 binds the engine's C ABI.

## Licence

MIT. Bundles quickjs-ng, also MIT.
