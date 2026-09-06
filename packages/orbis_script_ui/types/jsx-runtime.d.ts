import { type Child, type Node, type Props } from "./ui";
export type { Node, Child, Props };
export { Fragment } from "./ui";
/** One element with one child, or none. */
export declare function jsx(tag: string | ((props: Props) => Node), props: Props & {
    children?: Child;
}, key?: string): Node;
/** One element with several children. */
export declare function jsxs(tag: string | ((props: Props) => Node), props: Props & {
    children?: Child[];
}, key?: string): Node;
/** What the compiler calls in a development build. Same thing. */
export declare const jsxDEV: typeof jsxs;
