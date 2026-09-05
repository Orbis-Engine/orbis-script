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

/** What can be a child: an element, some words, or nothing. */
export type Child = Node | string | number | null | undefined | false;

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

  const flattened: Node[] = [];
  for (const child of children.flat(8) as Child[]) {
    if (child === null || child === undefined || child === false) continue;
    flattened.push(
      typeof child === "object" ? child : { type: "text", text: String(child) },
    );
  }

  const node: Node = { type };
  if (classes) node.class = classes;
  if (style) node.style = style;
  if (key) node.key = key;
  if (Object.keys(passed).length > 0) node.props = passed;
  if (flattened.length > 0) node.children = flattened;
  return node;
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
