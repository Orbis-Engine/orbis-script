// An interface written the way anybody would write one.
//
// Components are functions from props to elements. There is no state hook and
// no lifecycle here on purpose: those exist in React to drive a reconciler,
// and the reconciler on the other side of this is Flutter's own. State lives
// wherever the script keeps it, and the whole interface is described again
// after every event — which is exactly what `build` does on every setState.

import { mount, type Child, type Handler } from "../js/ui";

interface RowProps {
  label: string;
  value: string;
  children?: Child[];
}

/** One line of a settings panel: a name on the left, a value on the right. */
function Reading({ label, value }: RowProps) {
  return (
    <row class="justify-between items-center py-1">
      <text class="text-slate-300">{label}</text>
      <text class="text-slate-100 font-semibold">{value}</text>
    </row>
  );
}

function Action({ label, onPressed }: { label: string; onPressed: Handler }) {
  return (
    // `flex-1` so the two share the row rather than each taking the width of
    // its own words — which overflows a narrow panel by a few pixels and, in
    // a debug build, paints stripes across it.
    <button class="flex-1 px-3 py-2 rounded bg-ember-500 text-slate-50
                   text-center"
            key={label} onPressed={onPressed}>
      {label}
    </button>
  );
}

let spawned = 0;

function Panel() {
  return (
    <column class="p-4 gap-2 bg-slate-800 rounded-lg">
      <text class="text-lg font-bold text-slate-100">Scene</text>
      <Reading label="Objects" value={String(spawned)} />
      <Reading label="Renderer" value="Filament" />
      <row class="gap-2 pt-2">
        <Action label="Spawn" onPressed={() => { spawned += 1; }} />
        <Action label="Clear" onPressed={() => { spawned = 0; }} />
      </row>
    </column>
  );
}

mount(() => <Panel />);
