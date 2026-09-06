// What JSX is allowed to say.
//
// Without this, `<row class="p-4">` is an error under strict TypeScript: the
// compiler has no idea what a `row` is. Declaring the elements here is what
// makes a `.tsx` file check — and, more usefully, what makes an editor offer
// the element names and complain about a misspelt one before it is ever run.
//
// The props are deliberately loose past the ones every element shares. An
// element's own properties are the engine's business and change with it, and a
// type that lied about them would be worse than one that says little.

import type { Child, Handler } from "./ui";

declare global {
  namespace JSX {
    type Element = import("./ui").Node;

    interface ElementChildrenAttribute {
      children: Child[];
    }

    interface Common {
      /** A utility class list: `p-4 flex-1 items-center bg-slate-800`. */
      class?: string;
      /** CSS declarations, laid over the classes. */
      style?: string;
      /** What this element is across rebuilds, so state stays on it. */
      key?: string;
      children?: Child | Child[];
    }

    interface Pressable extends Common {
      onPressed?: Handler;
      onTap?: Handler;
    }

    interface IntrinsicElements {
      /** A container. Lays its children out in a column when it has several. */
      box: Pressable;
      row: Pressable;
      column: Pressable;
      /** Children on top of one another, placed by their own edges. */
      stack: Pressable;
      /** Words. Write them as the content: `<text>Hello</text>`. */
      text: Pressable;
      /** Something to press. */
      button: Pressable & { onPressed?: Handler };
      /** Somewhere to type. */
      field: Common & { placeholder?: string; onChanged?: Handler };
      /** A picture, by source. */
      image: Common & { src?: string };
      /** Whatever space is going. */
      spacer: Common;
    }
  }
}

export {};
