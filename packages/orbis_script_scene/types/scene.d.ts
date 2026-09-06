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
/** Puts something in the world, or moves what is already there. */
export declare function spawn(thing: Thing): Thing;
/** Takes something out. Doing it twice is not an error. */
export declare function destroy(id: string): void;
/** Everything, in the order it was first put there. */
export declare function all(): Thing[];
/** How many things there are. */
export declare function count(): number;
/** Takes everything out. */
export declare function clear(): void;
export declare function onFrame(run: (seconds: number) => void): void;
