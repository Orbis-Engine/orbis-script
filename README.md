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

## Interfaces

`orbis_script_ui` is how a script draws. TypeScript describes a tree and Dart
builds the real Flutter widgets for it — no reconciler, no retained tree, and
no second layout engine underneath. What is borrowed is the *styling*
vocabulary, because that is the part a web developer already knows:

```ts
import { column, row, text, button, mount } from "@orbis/ui";

let score = 0;

mount(() =>
  column({ class: "p-4 gap-3 bg-slate-900/0 items-start" },
    text(`Score ${score}`, { class: "text-2xl font-semibold text-slate-100" }),
    row({ class: "gap-2 items-center" },
      button("Again", {
        class: "px-3 py-2 rounded-md bg-ember-500 text-white",
        onPressed: () => { score = 0; },
      }),
      text("or press R", { class: "text-sm text-slate-400", style: "opacity: 0.8" }),
    ),
  ),
);
```

Both notations resolve to the same style, and CSS is laid over the class list
rather than replacing it. `p-4` is four steps of the theme's spacing scale;
`p-[13]` is thirteen pixels, for the one measurement in a design that does not
sit on the grid. A class nobody knows is ignored rather than fatal — an
interface that refuses to draw because a word was misspelt is worse than one
that draws without the rounded corner — and `unknownIn` lists what was ignored
for anybody who wants to be told.

What it deliberately is not is a second component set. The elements are the
ones a layout needs — `box`, `row`, `column`, `stack`, `text`, `button`,
`field`, `image`, `spacer` — and they resolve to Flutter's own widgets, laid
out by Flutter and drawn by Impeller.

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

MIT, © 2026 Chris Beckett. Bundles quickjs-ng, also MIT and under its own copyright —
see [LICENSE](LICENSE).
