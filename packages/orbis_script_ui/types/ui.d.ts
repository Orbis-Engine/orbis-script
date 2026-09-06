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
/** Builds one element. */
export declare function element(type: string, props?: Props, ...children: Child[]): Node;
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
export type Component<P = Props> = (props: P & {
    children?: Child[];
}) => Node;
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
export declare function h(tag: string | Component<any>, props: Props | null, ...children: Child[]): Node;
/**
 * `<>...</>` — several elements where one is expected.
 *
 * A column rather than a special kind of node, because the description has no
 * concept of a group and inventing one would mean the Dart side needing to
 * know about it. A fragment in a row is the one case where that shows; use a
 * row there instead.
 */
export declare function Fragment(props: {
    children?: Child[];
}): Node;
export declare const box: (props?: Props, ...children: Child[]) => Node;
export declare const row: (props?: Props, ...children: Child[]) => Node;
export declare const column: (props?: Props, ...children: Child[]) => Node;
export declare const stack: (props?: Props, ...children: Child[]) => Node;
export declare const image: (props?: Props, ...children: Child[]) => Node;
/** Words. The first argument is the words, because that is what it is. */
export declare function text(words: string, props?: Props): Node;
/** Something to press. */
export declare function button(label: string, props?: Props): Node;
/** Somewhere to type. */
export declare function field(value: string, props?: Props): Node;
/** Whatever space is going. */
export declare function spacer(): Node;
export declare function mount(root: () => Node): void;
/** Called by the host. Returns the whole interface as JSON. */
export declare function render(): string;
/** Called by the host when somebody presses something. */
export declare function dispatch(name: string, payload?: string): void;
