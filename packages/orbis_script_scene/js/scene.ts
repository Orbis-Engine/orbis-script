// Putting things in the world from TypeScript.
//
// The same arrangement as the interface: script says what it wants and the
// engine builds it. What crosses is a description of everything in the world,
// not a stream of commands — a message that says everything cannot go stale,
// and there is no state on the wire to fall out of step.
//
// Nothing here knows what a renderer is. A thing has a place, a size, a turn
// and a colour, and turning that into a particular renderer's idea of an
// object is the host's business.

/** Something in the world. */
export interface Thing {
  /** What it is, across frames. Reused rather than rebuilt when it moves. */
  id: string;

  /** Metres, in the world's own axes. */
  at: [number, number, number];

  /** Degrees about the upright axis. Most things only ever turn that way. */
  turn?: number;

  /** Metres. One number for all three, or one each. */
  size?: number | [number, number, number];

  /** `#RRGGBB`, the way a colour is written. */
  colour?: string;

  /** A model to draw instead of the built-in cube. */
  mesh?: string;
}

const world = new Map<string, Thing>();

/** Puts something in the world, or moves what is already there. */
export function spawn(thing: Thing): Thing {
  world.set(thing.id, thing);
  return thing;
}

/** Takes something out. Doing it twice is not an error. */
export function destroy(id: string): void {
  world.delete(id);
}

/** Everything, in the order it was first put there. */
export function all(): Thing[] {
  return Array.from(world.values());
}

/** How many things there are. */
export function count(): number {
  return world.size;
}

/** Takes everything out. */
export function clear(): void {
  world.clear();
}

/** Something to run before each description: the game's own step. */
let step: ((seconds: number) => void) | null = null;

export function onFrame(run: (seconds: number) => void): void {
  step = run;
}

// The host looks for this on the global object rather than importing it,
// because a bundle is evaluated as a script and there is nothing to import
// from on the other side.
(globalThis as Record<string, unknown>).__orbis_scene = {
  /** Runs the game's own step, then describes the world. */
  frame(seconds: number): string {
    if (step) step(seconds);
    return JSON.stringify(all());
  },

  /** Describes the world without running anything. */
  describe(): string {
    return JSON.stringify(all());
  },
};
