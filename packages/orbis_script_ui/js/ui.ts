// Describing an interface from TypeScript.
//
// The tree is a plain object and nothing here builds a widget: script says
// what it wants and the engine's Dart side builds the real Flutter widgets
// for it. That is why there is no reconciler in this file — no diffing, no
// retained tree, no lifecycle. A description is cheap to make and cheap to
// send, and Flutter is already extremely good at rebuilding from one.
//
// Styling is a class list, CSS, or both. The class names are the ones anybody
// who has written a web page already knows; what they resolve to is Flutter's
// own layout rather than a second box model.

/** One element of an interface. */
export interface Node {
  type: string;
  class?: string;
  style?: string;
  text?: string;
  key?: string;
  props?: Record<string, unknown>;
  children?: Node[];
}

/**
 * What can be a child: an element, some words, nothing, or more of them.
 *
 * Arrays are in here because `{items.map(...)}` is how anybody writes a list,
 * and it produces one. The runtime has always flattened them; the type simply
 * did not say so, which made the ordinary way of writing a list an error.
 */
export type Child =
  | Node
  | string
  | number
  | null
  | undefined
  | false
  | Child[];

/** Something that happens when an element is used. */
export type Handler = (payload?: string) => void;

export interface Props {
  /** A utility class list: `p-4 flex-1 items-center bg-slate-800`. */
  class?: string;
  /** CSS declarations, laid over the classes: `padding: 8px; color: #fff`. */
  style?: string;
  /** What this element is across rebuilds, so state stays on it. */
  key?: string;

  onPressed?: Handler;
  onTap?: Handler;
  onChanged?: Handler;

  [other: string]: unknown;
}

const handlers = new Map<string, Handler>();
let counted = 0;

/**
 * A callback, as a name the host can send back.
 *
 * A function cannot cross to Dart, so what crosses is a name and what stays
 * here is the function. Named once and reused for the life of the callback,
 * because a new name on every render would leak one per frame.
 */
function nameFor(handler: Handler, key: string | undefined, event: string): string {
  const name = key ? `${key}:${event}` : `h${++counted}`;
  handlers.set(name, handler);
  return name;
}

/// The elements whose content is words rather than other elements.
const WORDED = new Set(["text", "button", "field"]);

/** Builds one element. */
export function element(type: string, props: Props = {}, ...children: Child[]): Node {
  const { class: classes, style, key, ...rest } = props;
  const passed: Record<string, unknown> = {};

  for (const [name, value] of Object.entries(rest)) {
    passed[name] =
      typeof value === "function"
        ? nameFor(value as Handler, key, name)
        : value;
  }

  // Flattened by hand rather than by `flat`, because a child may be an array
  // of arrays — `{rows.map(row => row.map(...))}` is an ordinary thing to
  // write — and the depth is not known in advance.
  const flattened: Node[] = [];

  const take = (child: Child): void => {
    if (child === null || child === undefined || child === false) return;
    if (Array.isArray(child)) {
      for (const each of child) take(each);
      return;
    }
    flattened.push(
      typeof child === "object" ? child : { type: "text", text: String(child) },
    );
  };

  for (const child of children) take(child);

  const node: Node = { type };
  if (classes) node.class = classes;
  if (style) node.style = style;
  if (key) node.key = key;
  if (Object.keys(passed).length > 0) node.props = passed;

  // Some elements carry words rather than children, and in JSX the words are
  // written where children go: `<text>Hello</text>`. Folded here rather than
  // asked of whoever writes it, because the alternative is a text element
  // containing a text element containing the words, which draws nothing.
  if (WORDED.has(type) && flattened.length > 0 &&
      flattened.every((child) => child.type === "text" && child.children === undefined)) {
    node.text = flattened.map((child) => child.text ?? "").join("");
    return node;
  }

  if (flattened.length > 0) node.children = flattened;
  return node;
}

/**
 * What a component is here: a function from props to an element.
 *
 * Deliberately not a class, and deliberately without state, effects or a
 * lifecycle. Those exist in React to drive a reconciler, and there is no
 * reconciler on this side — the description crosses to Dart and Flutter does
 * the reconciling, which it is already extremely good at. Adding a second one
 * here would mean two trees disagreeing about what is on screen.
 *
 * State lives wherever the script keeps it, and the interface is described
 * again after every event. That is the same thing `build` does on every
 * setState, and it costs about as much.
 */
export type Component<P = Props> = (props: P & { children?: Child[] }) => Node;

/**
 * The function JSX compiles to.
 *
 * `<row class="p-4">{...}</row>` becomes `h("row", { class: "p-4" }, ...)`,
 * and `<Panel title="x" />` becomes `h(Panel, { title: "x" })`. Set
 * `"jsxFactory": "h"` and `"jsxFragmentFactory": "Fragment"` in tsconfig, or
 * `"jsx": "react"` with `"jsxFactory": "h"`.
 *
 * A tag that is a string is an element the engine knows how to draw; a tag
 * that is a function is a component, and calling it is all that "rendering"
 * one means.
 */
export function h(
  tag: string | Component<any>,
  props: Props | null,
  ...children: Child[]
): Node {
  const given = props ?? {};
  if (typeof tag === "function") {
    return tag({ ...given, children });
  }
  return element(tag, given, ...children);
}

/**
 * `<>...</>` — several elements where one is expected.
 *
 * A column rather than a special kind of node, because the description has no
 * concept of a group and inventing one would mean the Dart side needing to
 * know about it. A fragment in a row is the one case where that shows; use a
 * row there instead.
 */
export function Fragment(props: { children?: Child[] }): Node {
  return element("column", {}, ...(props.children ?? []));
}

const of = (type: string) =>
  (props: Props = {}, ...children: Child[]): Node =>
    element(type, props, ...children);

export const box = of("box");
export const row = of("row");
export const column = of("column");
export const stack = of("stack");
export const image = of("image");

/** Words. The first argument is the words, because that is what it is. */
export function text(words: string, props: Props = {}): Node {
  return { ...element("text", props), text: words };
}

/** Something to press. */
export function button(label: string, props: Props = {}): Node {
  return { ...element("button", props), text: label };
}

/** Somewhere to type. */
export function field(value: string, props: Props = {}): Node {
  return { ...element("field", props), text: value };
}

/** Whatever space is going. */
export function spacer(): Node {
  return { type: "spacer" };
}

/**
 * What the host calls to draw the interface.
 *
 * A project sets this to whatever draws its own interface, and the host asks
 * for it after every event.
 */
let describe: () => Node = () => ({ type: "box" });

export function mount(root: () => Node): void {
  describe = root;
}

/** Called by the host. Returns the whole interface as JSON. */
export function render(): string {
  return JSON.stringify(describe());
}

/** Called by the host when somebody presses something. */
export function dispatch(name: string, payload?: string): void {
  const handler = handlers.get(name);
  if (handler) handler(payload);
}

// The host looks for this on the global object rather than importing it,
// because a bundle is evaluated as a script and there is nothing to import
// from on the other side.
(globalThis as Record<string, unknown>).__orbis_ui = {
  render,
  dispatch,
  mount,
};

// So that a bundle compiled with `"jsx": "react"` finds its factory without
// every file importing it.
(globalThis as Record<string, unknown>).h = h;
(globalThis as Record<string, unknown>).Fragment = Fragment;
