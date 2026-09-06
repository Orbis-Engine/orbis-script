// The automatic JSX runtime.
//
// With this, a `.tsx` file needs no import at all — the compiler inserts the
// call itself. That is what `"jsx": "react-jsx"` means, and it is what anybody
// who has written TypeScript in the last few years expects.
//
// The older arrangement still works and is what `js/tsconfig.json` uses for
// the runtime's own sources: `"jsx": "react"` with `"jsxFactory": "h"`, where
// every file imports `h` for itself.

import { element, type Child, type Node, type Props } from "./ui";

export type { Node, Child, Props };
export { Fragment } from "./ui";

/** One element with one child, or none. */
export function jsx(
  tag: string | ((props: Props) => Node),
  props: Props & { children?: Child },
  key?: string,
): Node {
  return jsxs(
    tag,
    { ...props, children: props.children === undefined ? [] : [props.children] },
    key,
  );
}

/** One element with several children. */
export function jsxs(
  tag: string | ((props: Props) => Node),
  props: Props & { children?: Child[] },
  key?: string,
): Node {
  const { children = [], ...rest } = props;
  const given: Props = key === undefined ? rest : { ...rest, key };

  // A tag that is a function is a component, and calling it is all that
  // rendering one means.
  if (typeof tag === "function") return tag({ ...given, children });
  return element(tag, given, ...children);
}

/** What the compiler calls in a development build. Same thing. */
export const jsxDEV = jsxs;
