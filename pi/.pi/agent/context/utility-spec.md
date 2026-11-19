# Utility Spec (consolidated, v0.1 draft)

Context document for LLMs writing personal utility PWAs. This file is the complete spec; load it before writing any code for a utility, so the conversation with the person is about the *problem* the utility solves, not about how to build it.

A utility is one app in one repository: a static PWA whose UI is Web Components and whose business logic is NoFlo 2.x graphs, deployed in one of three tiers depending on what it must reach. Not yet specified: a design system (tokens, typography, controls, motion, accessibility) and module conventions (Signal K, maps and charts, realtime data, console).

Related context documents, to load alongside this one when relevant: `~/.pi/agent/context/component-basics.md` (NoFlo 2.x patterns), `~/.pi/agent/context/signalk-visuals.md` (Signal K UI rules), `~/.pi/agent/context/package-installation.md` (first-party package distribution).

The decisions log at the end (§12–§13) records which rules were decided, which were assumed for v0.1, and what is still open. Do not re-open decisions listed there; assumption tags `(A#)` are listed in §13 — follow them and mention in your report which you relied on.

## 1 Normative language

- **MUST / MUST NOT**: hard constraint. Never override. If the task seems to require breaking one, say so and stop.
- **DEFAULT**: do this unless there is a concrete reason not to. If you deviate, state the reason in one line in the README under "Deviations".
- **ASSUMPTION `(A#)`**: a v0.1 placeholder the maintainer has not confirmed (listed in §13). Follow it, and mention in your report that you relied on it.

## 2 When the spec is silent

Choose the most conservative option that is consistent with the stack, the tier and the aesthetic. Prefer fewer dependencies, fewer features, native platform APIs. State the assumption in one line in the README under "Assumptions". Do not ask the person about technical choices the spec could have answered; ask only about the problem.

## 3 Interaction workflow

Follow this order. Keep the person's attention on the problem.

1. **Restate the problem** in two or three sentences, in the person's terms.
2. **Inventory I/O**: what must the utility read, write, and talk to? Files, local devices, public APIs, Reticulum peers, Signal K data. List them.
3. **Pick the tier** from the I/O inventory (§8). State it in one line: "Tier 2, because it needs the ledger files on disk." Do not ask for confirmation unless two tiers genuinely fit.
4. **Ask at most three questions**, all about the problem (inputs, outputs, edge cases). If the answer can be assumed safely, assume and state it.
5. **Design before code.** Write down, in the README or a design note:
   - client graph and host graph as lists of nodes with named, typed ports;
   - exported ports of the host graph (with JSON Schemas);
   - UI components and the view-models they observe;
   - adapters needed and which tier supplies them.
6. **Build in this order**: schemas, components (pure logic first), graphs, adapters, UI components, wiring, tests.
7. **Run the acceptance checklist** (§15) and report any item you could not satisfy.
8. **Report briefly**: what was built, the tier and why, assumptions relied on, deviations, and anything the person must do by hand (vendoring, claim code, etc.).

## 4 Glossary

- **Utility**: one app, one repository.
- **Tier**: deployment shape (1 static, 2 local CLI host, 3 Signal K plugin).
- **Client graph**: NoFlo graph running in the browser. Owns UI state and view-models. Identical across tiers 1 and 2.
- **Host graph**: NoFlo graph that owns I/O and anything touching files, network, Reticulum, or storage. In tier 1 it runs in the browser, in-process. In tier 2 it runs in the CLI process. In tier 3 it is replaced by Signal K itself (plus an optional plugin backend).
- **Adapter**: component(s) that wrap an external effect behind a fixed port contract. The only tier-specific layer.
- **Exported port**: an inport or outport of the host graph that the client graph may use.
- **Runner library**: shared NoFlo components (HTTP serving, Reticulum host, claim gate, grant store, platform openers) installed via npm and vendored. Name, exact component list and versioning are still open (§13 O1).
- **Port contract**: the name, direction, JSON Schema, and semantics of a port.

## 5 Hard constraints at a glance

These are repeated from the sections below so they are never missed.

1. **No build step.** No bundler, transpiler, minifier or preprocessor. Source is what ships.
2. **Dependencies are vendored** under `vendor/` with a manifest. No CDN. No runtime `npm install`. No runtime code fetching.
3. **Web Components for UI**, NoFlo 2.x for logic. No React, Vue, or CSS frameworks.
4. **JSDoc types** with `// @ts-check` in every `.js` file.
5. **UI components contain no business logic** and never re-render whole subtrees on data change; they update specific nodes.
6. **No `innerHTML` (or equivalents) with data.** Inbound data is untrusted and validated against a schema.
7. **Fixed component registry.** No dynamic component loading in utilities.
8. **No mode flags** on components. If a flag changes which things happen, split the component.
9. **All external effects go through adapters.** Logic components never touch the DOM, storage, files, network or Reticulum directly.
10. **Relative URLs only**, so the utility works under any base path.
11. **Mobile first**: single column, 48x48 px minimum touch targets; extra space on larger screens shows more data, not different features.
12. **Time displays** are local ship/device time with no zone specifier, or UTC with a `Z` suffix. Dates are `YYYY-MM-DD`.
13. **Secrets** (keys, claim codes, tokens) are never logged, never placed in URLs that persist, and never stored in `localStorage`.

## 6 Stack and repository

### 6.1 Stack

| Concern | Choice | Rule |
|---|---|---|
| UI | Web Components (`HTMLElement` subclasses, native `customElements`) | MUST. No UI frameworks, no CSS frameworks. |
| Business logic | NoFlo 2.x graphs and components | MUST. Logic lives in components, not in UI code. |
| Modules | Native ES Modules | MUST. No CommonJS, no bundling. |
| Types | JSDoc annotations checked by `tsc --noEmit` | MUST. See §6.4. |
| Build | None | MUST. See §6.3. |
| Dependencies | Vendored, minimal | MUST. See §6.6. |
| Targets | Evergreen browsers; Node LTS for tier 2 and 3 hosts | See §6.2, §9. |

### 6.2 Browser baseline (A11)

Target current evergreen browsers (Chrome/Edge, Firefox, Safari on macOS and iOS). Use a platform feature only if it is **Baseline** (newly or widely available). Anything that is not Baseline MUST be a progressive enhancement with a working fallback. Features such as `<dialog>`, container queries, `:has()`, CSS nesting and `color-mix()` qualify once they are Baseline; check the status before relying on a newer feature.

The phone is the primary device. Never rely on hover, on a wide viewport, or on a keyboard being present.

### 6.3 No build step

MUST NOT use: bundlers (Webpack, Vite, Rollup, esbuild), transpilers (Babel, the TypeScript compiler for emit), minifiers, CSS preprocessors, template compilers, or code generators that must run before the app works. What is in the repo is what ships.

Allowed, because nothing they produce ships:

- `tsc --noEmit` as a type check (dev dependency only, run via `npm run check`).
- `node --test` for tests.
- `scripts/vendor.mjs`, the vendoring script (§6.6). This is the only build step.

### 6.4 Types with JSDoc

- Every `.js` file under `src/`, `scripts/`, `bin/` and `test/` starts with `// @ts-check`.
- `jsconfig.json` (or `tsconfig.json`) sets `checkJs: true`, `strict: true`, `noEmit: true`, `module`/`moduleResolution` for native ESM, `allowJs: true`.
- Shared types are `@typedef`s in `src/types.js`. Import types with `/** @typedef {import('./types.js').Reading} Reading */`.
- Every exported function has `@param` and `@returns`. Every component port payload has a matching `@typedef`.
- `any` is allowed only at the boundary with a vendored library lacking types; wrap it immediately in a typed function. Prefer `unknown` plus validation.
- JSON Schemas in `schemas/` are the source of truth for port payloads (D12). A port declares its schema as the id `<utility-id>/<schema-name>` (NoFlo 2.x `ns/name` form) and the schema body lives in `schemas/<schema-name>.json`; no cross-file `$ref` in v1, so a schema's closure is the single file. Keep each schema and its typedef side by side in review. A test MUST validate sample payloads against each schema.
- Validation of inbound data: use the schema/guard facilities of the NoFlo runtime where available; otherwise a small hand-written validator for the subset actually used (type, enum, min/max, required). Do not add a general-purpose validator dependency without a justification line in `vendor/vendor.json`.

### 6.5 Repository layout

One repository per utility.

```
my-utility/
├── README.md              # problem, tier and why, how to run, Assumptions, Deviations
├── AGENTS.md              # tells LLM agents to follow the pinned spec version
├── SPEC_VERSION           # e.g. "0.1"
├── LICENSE                # EUPL-1.2 (A8)
├── package.json           # "type": "module"; scripts; tier 2 "bin"; tier 3 signalk keys
├── jsconfig.json
├── index.html             # relative URLs only
├── manifest.webmanifest
├── sw.js                  # tier 1 only
├── icons/                 # single source icon plus required sizes
├── styles/
│   ├── tokens.css         # colour, spacing, motion tokens
│   ├── base.css           # reset, typography
│   └── components.css     # styles for tac-* elements
├── src/
│   ├── main.js            # boot: mode, router, graphs, mount
│   ├── types.js           # shared @typedefs
│   ├── lib/               # format.js, router.js, mode.js, small helpers
│   ├── ui/                # one file per Web Component: tac-*.js
│   ├── components/        # NoFlo components; index.js is the fixed registry
│   └── adapters/
│       └── <name>/        # one directory per adapter, per tier implementation
├── graphs/
│   ├── client.json        # client graph (A3)
│   └── host.json          # host graph
├── schemas/               # JSON Schemas for exported ports and adapter contracts
├── test/                  # node:test tests for components, graphs, lib
├── scripts/
│   └── vendor.mjs         # the only build step
├── vendor/
│   ├── vendor.json        # manifest of every vendored package
│   └── <package>/...      # vendored sources, unmodified
└── bin/
    └── <utility>.mjs      # tier 2 only: CLI entry
```

Conventions:

- File names are kebab-case. Custom elements and CSS classes use the prefix `tac-` (A2), for example `<tac-card>`, `.tac-card`.
- NoFlo components are namespaced by the utility id: `<utility-id>/<ComponentName>`.
- Graphs are JSON in `graphs/`, loaded at runtime (A3). The registry `src/components/index.js` imports every component explicitly (D11); it is the only place components are registered.
- `package.json` scripts: `vendor`, `check` (`tsc --noEmit`), `test` (`node --test`), and for tier 2 `start`. Nothing else.
- Dev dependencies are limited to the type checker. They are never vendored or shipped.
- `AGENTS.md` contains: the pinned spec version, the instruction "follow the Utility Spec at that version; its rules override your defaults", and the location of the spec.

### 6.6 Vendoring

Vendoring is the only build step, run only when adding or updating a dependency.

First-party packages — `@reticulum/*` (reticulum-js), `dacar`, NoFlo, `rfed`, and the meri-imperiumi `signalk-*` plugins — are canonically distributed as cryptographically signed rngit releases over the Reticulum mesh, with centralized registries (npm) as mirrors; refer to `~/.pi/agent/context/package-installation.md` when documenting install steps or vendoring sources for them.

- `scripts/vendor.mjs` uses only Node built-ins. It fetches a pinned package (for example via `npm pack` into a temp directory), copies the needed files into `vendor/<name>/`, and updates `vendor/vendor.json`.
- Every vendored package has a manifest entry: `name`, exact `version`, `license` (SPDX id), `source` URL, `sha256` of the vendored files, and a one-line `justification` explaining why a dependency is needed at all. First-party packages (`@reticulum/*`, `dacar`, NoFlo) additionally record the rngit `release` (`rns://<origin>/<group>/<repo>` and tag) and the release `signer` identity hash; the vendoring script fetches and verifies the signed release (`rngit release fetch ... <signer>`, re-checkable offline with `rngit release verify`) before copying files. Where a signature could not be machine-verified, the entry instead records in a `verified` line what was checked by hand and by whom.
- Versions are pinned exactly. No ranges, no `latest`.
- Vendored files are committed and **never edited in place**. Local fixes live as patch files in `vendor/patches/` and are applied by the vendoring script.
- Licences MUST be EUPL-1.2-compatible. If unsure, do not add the dependency; say so.
- No CDN references, no runtime `import()` of remote URLs, no runtime package installs.
- The NoFlo 2.x runtime and the runner library (D8) are vendored like any other package, under `vendor/`.
- Before adding any dependency, check whether a native platform API or ten lines of code does the job. The default answer is no dependency.

A published tier 2 package ships its `vendor/` directory in the tarball; it has no install-time dependencies.

### 6.7 Licensing (A8)

- DEFAULT licence is EUPL-1.2. Every source file carries `// SPDX-License-Identifier: EUPL-1.2` (use the comment syntax of the file type).
- `LICENSE` contains the licence text. `README.md` names it.
- Vendored code keeps its own licence and is listed in `vendor/vendor.json`.
- Utilities that are never released may still follow this; deviations go in the README.

### 6.8 README and AGENTS requirements

`README.md` MUST contain: the problem in two or three sentences; the tier and the reason; how to run it (and, for tier 2 and 3, how to start the host and pair a device); an "Assumptions" section; a "Deviations" section; and how to update vendored dependencies.

## 7 Architecture

### 7.1 Overview

```
 ┌──────────────── browser ────────────────┐         ┌───────── host ──────────┐
 │  UI components (tac-*)                  │         │  host graph             │
 │     ▲ view-models    │ commands         │         │   logic components      │
 │     │                ▼                  │   FBP   │   adapters ─────────────┼─▶ files, network,
 │  client graph ── host-link (remote ─────┼── over ─┼─▶ exported ports        │   Reticulum, storage
 │                  subgraph proxy)        │   RNS   │                         │
 └─────────────────────────────────────────┘         └─────────────────────────┘
```

- **Tier 1:** the host graph runs in the same page. `host-link` is in-process but keeps the same port contract.
- **Tier 2:** the host graph runs in the CLI process; `host-link` speaks FBP Protocol 2 over Reticulum (§10).
- **Tier 3:** there is no remote host graph. Signal K is the host; the client graph uses Signal K adapters (§7.5). An optional plugin backend runs inside the plugin process.

The split is the point: UI and client graph are the same across tiers 1 and 2, and adapters are the only tier-specific code.

### 7.2 UI layer: Web Components

MUST:

- Components are `HTMLElement` subclasses registered with a `tac-` tag (A2).
- **Light DOM by default** (A10), so shared stylesheets in `styles/` apply. Shadow DOM only for genuine encapsulation needs, and then it adopts the shared stylesheets.
- **Attributes are configuration** (strings), **properties carry data**, **events go up**. Events are `CustomEvent`s named `tac-<thing>`, with `bubbles: true`, a typed `detail`.
- `connectedCallback` builds the DOM once (clone a `<template>` or use `createElement`) and **caches element references**. Later updates change only `textContent` or specific attributes/properties on those references. Never re-render a subtree on data change.
- `disconnectedCallback` removes listeners, timers and subscriptions. A component that is removed MUST leave nothing running.
- No business logic, no `fetch`, no storage, no Reticulum, no timers for data. A component renders a view-model and emits commands.
- Lists reuse child elements by key (a small helper in `src/lib/`), rather than rebuilding.

The UI talks to the client graph through two things in `src/lib/bridge.js`:

- `bridge.view(name)` returns a **ViewModel**: an `EventTarget` with a current `value` and a `change` event. Components receive a view-model by property and observe it.
- `bridge.send(inport, payload)` sends a command packet into a client-graph inport.

Both are typed per utility; the names are the client graph's exported ports.

Several UI rules here (granular updates, hash routing, `minRate` throttling, backoff reconnects, time formats, day/night colour tokens, the tactical sci-fi aesthetic, 48 px touch targets, the terminal console pattern) are carried over from the Signal K UI specification; refer to `~/.pi/agent/context/signalk-visuals.md` for their full statement.

### 7.3 NoFlo layer

For NoFlo 2.x component mechanics — port declarations, control and addressable ports, information packets and streams — refer to `~/.pi/agent/context/component-basics.md`. Note that utilities use the fixed-registry pattern (§6.5), not the loader-based discovery described there.

Components:

- **Fixed registry** (D11): `src/components/index.js` imports every component explicitly. No dynamic discovery, installation or loading.
- **One responsibility per component.** Port names are plain nouns or verbs.
- **No mode flags** (D8). If a flag changes which things happen, split the component. Port configuration carries *values* (a path, an interval, a threshold), never behaviour switches.
- **Every port has a JSON Schema** in `schemas/` (D12). Port payloads MUST be wire-safe: MsgPack is the wire encoding (§14), so payloads are limited to what both JSON and MsgPack represent, plus byte strings (`Uint8Array`) — no functions, DOM nodes, `undefined`, `Date`, `Map`, `BigInt`, `NaN` or `Infinity`. This keeps tiers interchangeable.
- Logic components are **pure** where possible: no DOM, no storage, no files, no network, no direct adapter imports. They get effects only through wired adapter ports.
- Each component file begins with a header comment listing its ports and what they mean.

Errors (D11):

- Any component that can fail has an `error` outport carrying the shared shape in `schemas/error.json`: `{ code, message, source, detail? }`. Every `error` outport MUST be wired to something (an error sink, a view-model, or the console).
- Where partial results are meaningful, use the assembly style instead: a message object `{ data, errors: [] }` that accumulates errors as it flows. DEFAULT: `error` outport for adapters and I/O; assembly style for processing pipelines.
- Never throw to the runtime for expected failures. Never swallow errors. Flowtrace `ERROR` events are debug telemetry, not the application's error path.

Graphs:

- Graph structure is the unit of adaptation (D8): to change *what the utility does*, change the graph; to change *a value*, change a setting.
- Initial packets carry fixed values. User-editable values come from the `storage` adapter as packets. Secrets never appear in graph JSON.
- Keep graphs small: a soft cap of about 15 nodes per graph. Beyond that, extract a subgraph with documented ports.
- Lifecycle: NoFlo 2.x has no start or shutdown packets. A network starts when the host application starts it; fixed values enter as initial information packets (IIPs), and control ports redeliver standing configuration at each network start. A long-running utility network stays running because its boundary sources — the adapters — hold their transmissions open. To stop it, the host ends those transmissions (end-of-transmission) and calls `network.stop()` (wired to SIGINT/SIGTERM in tier 2). Closedown is cascading: a network ends when every boundary input is at end-of-transmission and the network is quiescent. Components release resources in `tearDown` handlers, called at shutdown; a shutdown that hangs is a component bug (see the has-first activation rules in `component-basics.md`).

### 7.4 Client graph and host graph

| | Client graph | Host graph |
|---|---|---|
| Runs | browser | browser (tier 1), CLI process (tier 2) |
| Owns | view-models, UI commands, connection status, UI preferences | files, storage, network, Reticulum, long-running work, authoritative data |
| Talks to | UI via `bridge`; host via `host-link` | adapters; clients via exported ports |
| Tier 3 | Signal K adapters in the browser | replaced by Signal K (+ optional plugin backend) |

Rule of thumb: if it must survive closing the browser, or touches the outside world, it belongs in the host graph. If it exists only to show something, it belongs in the client graph.

### 7.5 Adapters

An **adapter** wraps an external effect behind a fixed port contract. v0.1 names the standard set; their schemas are not yet defined (O2).

| Adapter | Purpose | Implementations |
|---|---|---|
| `storage` | key-value and blob persistence | IndexedDB (tier 1); files in the data dir (tier 2); SK plugin config and resources (tier 3) |
| `files` | read/write/list in a configured root | tier 2 only |
| `clock` | now, ticks | system clock; controllable double |
| `reticulum` | announce, links, packets, resources | reticulum-js in browser (tier 1); server-side (tier 2) |
| `host-link` | remote-subgraph transport | in-process (tier 1); FBP over Reticulum (tier 2) |
| `signalk` | delta subscription, REST, meta | tier 3 only |

Rules:

- Adapters live in `src/adapters/<name>/`, one implementation per tier.
- Choosing an implementation is a graph-assembly decision (which node is in the graph), never a runtime flag.
- Every adapter has a test double in `test/doubles/`.
- `files` MUST confine access to its configured root: normalise paths, reject `..`, and refuse symlinks that leave the root.
- Adapters validate everything inbound against the port schema before it enters a graph.

### 7.6 `host-link`: the client/host boundary (tiers 1 and 2)

The host graph's **exported ports** are its component signature: in and out ports with JSON Schema references. The client graph contains a `host` node whose ports mirror them; the client graph neither knows nor cares whether it is in-process or remote.

The `host` node is a hand-written component in `src/components/host.js`, declared in the fixed registry, with its ports taken from the host graph's exported-port schemas (§6.4). A test compares the component's signature hash against the host graph's — the protocol computes `sig_hash` for component signatures — so signature drift fails the test instead of surfacing at runtime.

- **State vs event ports (A12).** A *state* port is retained: the host replays the latest value to a client on subscribe and on reconnect. An *event* port is not replayed. The marker is an additive optional port field, `retain` (see P3 in §13).
- **Requests.** A request packet carries an `id`; the answer arrives on a `response` outport echoing it. Clients filter by `id`. Over a mesh, answers may take minutes: the UI shows a pending state and never blocks.
- **Connection status.** The `host` node has a `status` outport describing the connectivity layer reached (§10.8). The UI MUST show it.
- **Delivery.** At-most-once, host authoritative. After a reconnect the client takes a fresh snapshot from retained ports; it does not try to replay what it missed. User actions that must survive a reload go through a persisted outbox with states `queued, sent, delivered, failed`.
- **Multiple clients.** One shared host graph. Outports broadcast to all connected clients; each new client gets its own snapshot.
- **Large payloads** travel by reference (Reticulum Resource), not inline (P5 in §13).
- **Pending protocol work.** The behaviours above rely on additions to FBP Protocol 2 (P1 to P4 in §13). Keep all of this behind the `host-link` adapter so protocol changes do not ripple into utilities.

### 7.7 State and persistence

- The host graph is authoritative. The client holds view-models and nothing else that matters.
- UI preferences (mode, motion setting, last tab, unsent drafts) go in `localStorage` with keys prefixed `<utility-id>:`, every read and write inside `try/catch`, and the UI correct when storage is empty. **Secrets never go in `localStorage`.**
- Persisted data carries `{ "format": "<utility-id>", "version": n }`. Migrations are components in the host graph.
- Every utility MUST offer **export and import** of its data as JSON. Import validates against the schema and previews changes before applying; it never silently overwrites.
- Tier 1 hosts SHOULD request persistent storage (`navigator.storage.persist()`) and tell the person when the browser declines.

### 7.8 Routing

- Single-page, native `hashchange` routing: `#/`, `#/settings`, `#/log`, and so on. Routes are declared in one table in `src/lib/router.js`.
- Default route is `#/`. An unknown route falls back to the default and shows a brief notice.
- On every navigation: update `document.title`, and move focus to the view's main heading (`tabindex="-1"`).
- The hash holds the route and simple path parameters only. No secrets. A fragment that begins with `claim=` is consumed by pairing and stripped before routing (§10.5).
- No page or route transitions.

### 7.9 Data formatting (A15)

- All formatting lives in `src/lib/format.js`. Components never format inline.
- **Units** are not hardcoded in components. They come from the value's schema (and, in tier 3, from Signal K `meta`). Scale SI-derived units with ISO prefixes for readability (1200 W becomes 1.2 kW; 15000 Wh becomes 15 kWh). Exempt from prefix scaling: angles, percentages, time and dates, temperatures, counts, and display units such as knots or nautical miles.
- **Precision:** DEFAULT three significant digits unless the schema says otherwise. **Missing, null or stale values display `--`.** Telemetry numbers use `.` as the decimal separator with no grouping. Parse user-entered numbers in JavaScript, accepting both `.` and `,`.
- **Time (MUST):** show either local time with no zone specifier (`14:30`) or UTC with a `Z` suffix (`04:30Z`). Never `LST`, `GMT+2` or similar. 24-hour clock. Dates are `YYYY-MM-DD`; combined forms are `2026-11-10 14:30` (local) and `2026-11-10T04:30Z` (UTC).
- **Source of local time:** the device clock, unless the utility is configured with a fixed offset. In tier 3, use `environment.time.timezoneOffset` when present (encoded as `(-)hhmm`, for example `200` or `-930`; verify against the current Signal K schema before relying on it).
- **Timestamps from remote peers are claims, not truth.** Show them as such and fall back to receive time when absent or implausible.
- **Staleness:** a value older than its schema-declared maximum age is shown dimmed with an age cue in text, never by colour alone.

### 7.10 Security basics (all tiers)

- MUST NOT use `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval` or `new Function` with data. Use `textContent`, `createElement`, template cloning and `setAttribute` on known attributes.
- URLs derived from data are validated with `new URL()` and restricted to expected schemes (normally `https:`).
- **All inbound data is untrusted**: network responses, files, Reticulum packets and announces, Signal K deltas, user imports. Validate against the port schema at the adapter boundary, cap sizes, and reject or quarantine failures.
- No dynamic `import()` with data-derived specifiers.
- **Default CSP (A17)**, as a `<meta http-equiv="Content-Security-Policy">` in `index.html`: `default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'none'; form-action 'none'`, plus a `connect-src` limited to `'self'` and the origins declared in the README (gateways, public APIs). Set styles through classes and CSS variables or CSSOM, not style attributes.
- Secrets (identity keys, claim codes, tokens) are never logged, never stored in `localStorage`, never placed in persistent URLs. See §10.10.

### 7.11 Testing

- `node --test`. No network in tests; inject the clock.
- **Component tests** use the test utilities of the vendored NoFlo runtime.
- **Graph tests** load the graph JSON, substitute adapters with doubles from `test/doubles/`, send packets and assert outputs.
- **Schema tests** validate sample payloads against every port schema.
- UI components need no automated DOM test dependency; verify by hand against the checklist (§15). Anything beyond that is optional and kept out of the repo's dependencies.

### 7.12 States every view must handle

Every view defines **loading, empty, error, offline and stale** states. Connection status is always visible. Nothing blocks behind a spinner for mesh-length latency; show a pending state and let the person keep working.

## 8 Tier selection

The UI is always a static PWA. A **tier** answers one question: what does the utility need to reach, and therefore what host does it need?

| Tier | Needs | Shell | Example |
|---|---|---|---|
| 1 | Reticulum peers and/or public APIs only; local storage on the device | Static hosting (GH Pages or similar). The host graph runs in the browser. | rngit document editor/manager |
| 2 | Local files, local network devices, OS access | npm package with a CLI runner that starts a localhost host and opens the UI | Monthly accounting statement updater (ledger-cli files on disk) |
| 3 | Signal K data, resources or plugin lifecycle | Signal K plugin (webapp plus optional backend) | Passage weather briefing (GRIBs, routes, other SK resources) |

Selection:

1. List what the utility must read, write and talk to (§3, step 2).
2. **The most demanding need wins:** any Signal K need means tier 3; otherwise any local files or devices means tier 2; otherwise tier 1.
3. State the tier and the reason in one line. Do not ask the person unless two tiers genuinely fit.

Edge cases:

- Needs only local persistence on one device: tier 1 (IndexedDB), no host.
- Needs Signal K *and* local files: tier 3; the plugin backend does the file access on the Signal K host.
- Needs local network devices that Signal K already exposes: tier 3, through Signal K.
- Cross-device sync with no server: tier 1 over Reticulum.

Because only adapters differ between tiers, a utility can move up a tier later without rewriting its logic or UI. Design for that: never leak tier-specific details into components or views.

## 9 Deployment tiers

### 9.1 Tier 1: static PWA

**Hosting and paths**

- Served over HTTPS from static hosting. Project sites live under a sub-path (`/repo/`), so every URL MUST be relative. Register the service worker with a relative URL (`./sw.js`); the manifest uses `"start_url": "./"` and `"scope": "./"`.
- Because this is a secure context, the full PWA toolkit is available: service worker, installability, WebCrypto.

**Manifest and icons**

- `manifest.webmanifest` with `display: standalone`, name, short name, and icons from the single source icon. `theme_color` is the constant `--bg-base` value (`#080a0c`); there is no per-mode variant.
- One source icon file; other sizes are derivatives kept under `icons/`. The favicon is the same asset, referenced relatively.

**Service worker (DEFAULT; strategy details O6)**

- The page MUST work without it. It is an enhancement for offline use.
- `sw.js` holds a `CACHE_VERSION` and a hand-maintained `PRECACHE` list of every shipped file. A test asserts that every shipped file is listed, so the list cannot drift (no build step to generate it).
- Cache-first for the precached app shell; never cache Reticulum traffic or API responses unless the utility's design says so.
- Update flow: a new worker installs in the background; the UI shows an "update available" indicator and reloads only when the person accepts.
- The UI shows an "installed and cached" indicator, because a first load on a boat with no internet only works if the PWA was installed beforehand.

**Storage and identity**

- Host graph in the page; `storage` adapter is IndexedDB. Request persistent storage; browsers (Safari especially) may evict site data otherwise.
- The Reticulum identity lives in the browser, with the mandatory backup flow (§10.2).

**Network rules**

- Public APIs: only CORS-enabled ones. Do not invent a proxy. Declare every origin in the README and in the CSP `connect-src`.
- **No embedded secrets.** API keys are supplied by the person at runtime and stored via the `storage` adapter, never committed and never in graph JSON.
- Reticulum: the browser is a **leaf node only**, connecting through WebSocket interfaces. An HTTPS page needs `wss://` for non-loopback gateways (mixed-content rules).
- Do not connect to public hubs by default; interfaces are opt-in (§10.7).

### 9.2 Tier 2: npm package with a localhost host

**Shape**

- An npm package with a `bin` entry. Running it starts the host graph, serves the static UI files (the same files tier 1 would host), binds to loopback, and opens the browser.
- **Tier 2 means the UI runs on the same machine as the host.** Localhost is a secure context, so the browser can use WebCrypto and speak FBP over Reticulum to the host.
- Remote access works the way any client does: the same UI deployed statically, connecting to the host over Reticulum. Tier 2 UI files MUST therefore also work when served statically (the host destination is configured or pasted instead of assumed same-origin).
- **Known limitation:** reaching a tier 2 host from a phone over a LAN needs a `wss` endpoint in front of it. That is out of scope for v1; a TLS-terminating proxy such as Caddy is a later extension.

**CLI behaviour (names: A14)**

| Item | Rule |
|---|---|
| Binding | `127.0.0.1` only. Never `0.0.0.0` or a LAN hostname. |
| URL opened | `http://localhost:PORT/` explicitly, so the page stays a secure context. |
| Port (A18) | A fixed default per utility; if busy, the next free port. Always print the URL. |
| `--port` | Override the port. |
| `--data-dir` | Override the data directory (default `~/.<utility-id>/`). |
| `--no-open` | Do not launch a browser. |
| `--print-claim` | Print a fresh owner-claim URL when no owner exists. |
| `invite` | Issue a one-time code for an additional device (§10.5). |
| `--reset-owner` | Revoke owner grants and reopen the claim window. |

- **Opening the browser** is a swappable component per platform (`xdg-open`, `open`, `start`, `termux-open-url`). This is an example of graph-level adaptation (D8): the runtime graph swaps one node.
- On first start with no owner, the CLI prints the claim URL and opens it.
- **Origin and Host checks.** The host's WebSocket interface MUST accept only its own origin (plus explicitly configured UI origins) and only expected `Host` values, to stop other web pages and DNS rebinding.
- **Loopback is not authentication.** Other apps on the same device can connect to localhost ports. Authorization is by Reticulum identity (§10.4).

**Portability profile (tested targets: Linux, macOS, Termux on Android; iSH best effort; Windows untested; A7)**

- Node built-ins only; no native addons (Termux uses Bionic, where native modules often fail to build). Target the current Node LTS.
- Assume the OS may kill the host at any time. Write state atomically (write then rename); make startup idempotent; persist the Reticulum identity and the Dacar clock so a restart keeps the same address and monotonic timestamps.
- **Idle must be cheap.** No polling and no timers when nothing is happening.
- Handle `SIGINT` and `SIGTERM` by running the graph's shutdown sequence.
- **Secrets storage** (identity key, Dacar store) MUST be in a filesystem that honours modes: directory `0700`, files `0600`. On Termux that means the app-private home, never shared storage. User data paths (for example the ledger directory) stay freely configurable.
- Document user setup steps that the CLI cannot do: on Termux a wake lock, battery optimisation exemption, and Termux:Boot for autostart.
- Clock sanity: a host without a reliable clock (for example a Raspberry Pi with no RTC) must not issue Dacar operations with a wildly wrong time; see §10.4.

### 9.3 Tier 3: Signal K plugin

**Principles**

- **Talk to the host through its native protocol** (D9): Signal K deltas over its WebSocket stream and REST. No FBP remoting, no browser-side Reticulum identity, no Dacar between the browser and Signal K.
- **Signal K is the integration bus.** Anything a utility produces that other parties may want is published as Signal K data, not through a private protocol:
  - vessel data as paths with `meta` (units, display rules), via deltas;
  - routes, waypoints and other collections through the Resources API;
  - alerts through notifications;
  - anything else through documented REST routes under the plugin's own prefix.
- **Authentication is Signal K's own** (login and token handling). Handle `401`s gracefully, and degrade sensibly when security is turned off. No custom auth.

**Shape**

- An npm package published as a Signal K plugin and/or webapp (package keywords `signalk-node-server-plugin` and/or `signalk-webapp`, with a `signalk` block in `package.json` including `appIcon` and `displayName`). The server serves the package's static directory under the package's own path, so keep every URL relative and verify the layout against the current Signal K documentation.
- The same repo conventions apply (§6), with the UI root in the directory Signal K serves (typically `public/`) instead of the repo root.
- The single `appIcon` is the source of truth for the favicon; do not duplicate it under another name for the webapp.
- Theme colour, favicon and the rest of branding follow the design system; until it is written, `~/.pi/agent/context/signalk-visuals.md` is the closest reference (appIcon as favicon, `theme-color` `#080a0c`).

**Webapp only, by default**

- The default is a webapp-only utility whose client graph runs entirely in the browser against Signal K, using `signalk` adapters: delta subscription (with `minRate`, exponential-backoff reconnect and staleness), and a REST client for resources, history and `meta`. A utility with several data sources simply wires several adapter nodes.
- Add a **plugin backend** only when something must run without a browser open: logging, long computations, mesh synchronisation, acting as a resource provider. The backend runs inside the plugin process, is not remoted, and publishes its outputs back into Signal K. If it needs Reticulum, it uses the shared Reticulum connection plugin (O3) and the browser never touches Reticulum in tier 3.

**Consequence:** tier 3 client graphs are not portable to tiers 1 and 2, because the data model is Signal K's. That is expected; these utilities exist because of Signal K data. Reusable across tiers: UI components, pure-logic components, the design system.

### 9.4 What is the same everywhere

| | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| UI components, design system, formatting | same | same | same |
| Pure-logic components | same | same | same |
| Client graph | shared with tier 2 | shared with tier 1 | Signal K-specific |
| Host | in-process graph | CLI-hosted graph | Signal K (+ optional backend) |
| Client/host link | in-process | FBP over Reticulum | deltas + REST |
| Identity | in browser | on host; browser has its own client identity | Signal K auth |
| Persistence | IndexedDB | data dir on host | SK config and resources |
| Offline | service worker | not applicable (data on host) | not applicable |

## 10 Identity, access and Reticulum

Load this part when the utility uses Reticulum (tiers 1 and 2; tier 3 backends reach Reticulum through the shared connection plugin instead, §9.3).

Use Reticulum's own terms in code and UI: **identity, destination, aspect, announce, path, link, interface**. Do not invent friendlier synonyms.

### 10.1 Identity model

- A Reticulum identity is an X25519 + Ed25519 keypair. Its destination/identity hash is 16 bytes. Display hashes as lowercase hex in monospace with a copy button, always in full.
- **One identity per app install** (DEFAULT). Destinations already differ per app through aspects, but sharing one identity across apps lets an observer link them. Sharing is opt-in.
- **Announce deliberately.** Never announce on page load. Hosts announce at start and on a long, jittered interval; clients announce only on explicit action. Intervals are configurable within conservative bounds. Airtime is a shared, scarce resource.

### 10.2 Browser identity (tier 1; client identity in tier 2)

- **Generate locally** with a CSPRNG on first run, before any host contact. Never generate a browser identity server-side. Show the hash immediately.
- **Store in IndexedDB**, with extractable key material so backup is possible. Request persistent storage. **Never use `localStorage`** for key material.
- **Backup is mandatory.** Browsers can evict site data, and Reticulum has no recovery or revocation, so a lost identity is a lost address.
  - Prompt at creation (dismissible but visible) and show a persistent `NOT BACKED UP` indicator until done.
  - **Encrypted export** (A6): passphrase, PBKDF2-HMAC-SHA-256 with at least 600,000 iterations and a random 16-byte salt, AES-GCM with a random 96-bit nonce, all through WebCrypto. The file records format, version and KDF parameters.
  - **Raw export and import** in the reference 64-byte private key layout (X25519 ‖ Ed25519), so keys round-trip with the reference tools. Importers also accept the legacy 128-byte layout. Raw export is a file download behind a warning; never display the key as text by default.
  - Mark the backup done only after a verification step (a test decrypt or a re-entered passphrase).
- **Loss or compromise:** there is no rotation. The only recovery is a new identity, re-pairing, and telling contacts out of band. The UI says this plainly.

### 10.3 Host identity (tier 2)

- Generated at first start and stored in the **secrets directory** with modes `0700` (directory) and `0600` (files), in the reference-compatible format. On Termux this is the app-private home, never shared storage (§9.2).
- The host's destination hash is its address and is the **Dacar root trust anchor**.
- Backup is a copy of the secrets directory; the README documents how.
- Shell access to the host is the ultimate authority: it can reopen the claim window or reset ownership (§10.5).

### 10.4 Access control with Dacar (D13)

The host is the **sole issuer** of grants by default. The browser never signs Dacar operations and never sees the privacy salt.

- **Model:** a grant is a tuple of object, relation, grantee and issuer, signed by the issuer. The host's identity is the only root trust anchor.
- **Objects and relations.** Objects are `<utility-id>:<exported-port>`, with the wildcard `<utility-id>:*`. Relations are `read` (subscribe to an outport), `write` (send to an inport) and `admin` (reserved; authority to manage grants).
- **Owner** = `admin` on `<utility-id>:*` (the wildcard is required because `admin` does not cascade to child namespaces by default). The owner client asks the host to grant or revoke; the host checks that the sender holds `admin`, then signs the operation itself. Only the host's key therefore needs to be recallable by verifiers.
- **Privacy salt:** `init` generates a random 32-byte salt. Never use the zero default (it is fail-open). The salt stays on the host.
- **One grant per device.** A grantee is a single identity. Label devices through the Dacar `aliases` mechanism, and list "who has access" from the host's plaintext ledger of locally issued grants.
- **Revocation and loss.** Revoke a lost device and grant the new identity. With a single authoritative host, local evaluation is authoritative; the strict consistency challenge only matters once several nodes hold copies of the policy.
- **Clock.** Persist the host's hybrid logical clock so timestamps never go backwards. Dacar rejects operations too far in the future or past the horizon, so a host with a bad clock must refuse to issue operations and warn (relevant for Pi-class hosts without an RTC).

Roles (O4, pending P1 in §13):

| Role | Grants issued by the host | Target capability bits | Notes |
|---|---|---|---|
| owner | `admin` on `<utility-id>:*` | port I/O, component read, introspection | Can manage grants through host commands. |
| member | `read`/`write` on named ports | port I/O | Default for invited devices. |
| viewer | `read` | outport subscribe | Read-only. |
| dev | none; enabled by an explicit CLI flag, loopback only | graph read/edit, telemetry, lifecycle, component read | **Never** `COMPONENT_WRITE` in production. |

Production hosts MUST NOT grant `GRAPH_EDIT`, `COMPONENT_WRITE`, `LIFECYCLE_CTRL` or `ADMIN` to client identities. Today `LIFECYCLE_CTRL` gates packet input; that conflation is P1 in §13.

### 10.5 Pairing, version 1 (A4, A5)

Authority for the first pairing comes from shell access to the host. All v1 codes are issued by the host CLI.

Owner claim (first run):

1. The PWA generates its identity on first load, shows the hash, and starts the backup flow.
2. The host starts with no owner. The CLI prints and opens a **claim URL**: `http://localhost:PORT/#claim=<code>&host=<destination-hash>`. The code travels in the URL fragment, so it is never sent in an HTTP request or written to a server log.
3. The PWA reads the fragment, strips it with `history.replaceState`, and **pins the host's destination hash**. A destination hash is derived from the host's public key, so pinning it authenticates the host to the client and rules out a rogue host. The router ignores fragments beginning `claim=`.
4. The PWA opens a link to the host and calls `identify()`. The code is then sent *inside the encrypted link*, bound to the identified identity.
5. The host verifies the code, issues the owner grant, closes the claim window, and re-sends its capability advertisement with the new mask (P4 in §13).
6. The CLI prints the identity hash that claimed ownership. The person compares it with the hash the PWA shows. This is the cheap check that nobody got there first.

Additional devices: `invite` on the CLI issues a one-time code with a role (default `member`), delivered the same way as a claim URL. Each device claims its own grant. UI-initiated invites and request/approve flows are deferred (O7); the intended design is an access request with a short fingerprint derived from both identity hashes, compared on both screens.

Code properties (MUST):

- At least 80 bits of entropy, shown in Crockford base32 in groups of four.
- Single use, short TTL (10 minutes by default), invalidated after five failed attempts.
- The host stores only a hash of the code and compares in constant time.
- Never logged, never embedded in served HTML, never exposed through any HTTP route. The only delivery paths are the opened URL fragment and the terminal.

Recovery: `--reset-owner` revokes owner grants and reopens the claim window. Shell access to the host is always sufficient to regain control; losing a browser profile must not lock the person out.

Tier 1: there is no host to claim. A tier 1 client is a client of someone else's host: it shows its identity hash (copy), the host's admin issues the grant, and the client pins the host's destination hash.

### 10.6 Host discovery (A13)

- Hosts announce under the stable `fbp.runtime` aspect. The announce app data is `[protocol_version, destination_hash, node_name]` (well under the 128-byte limit), serialized as defined in the FBP Protocol 2 AsyncAPI document (§14). `node_name` is the **utility id**; a client rejects an incompatible version from the first byte.
- Clients show announces they hear as a list. **Pinned hosts come first.** Unpinned hosts are labelled `UNVERIFIED`. Never auto-connect to an unpinned host.
- After link establishment with a verified identity, the host sends its capability advertisement. Treat it as the in-link truth over any cached announce.

### 10.7 Interfaces and configuration

- **Browser interfaces** are WebSocket interfaces, as a list of entries with name, URL, enabled flag and live status, stored as JSON and exportable. For a tier 2 UI served by its own host the default list contains one same-origin entry (relative URL). A static UI has none until the person adds one.
- **No public hubs or third-party gateways by default.** Connecting to one is an explicit opt-in, with a note about privacy and airtime.
- An HTTPS page needs `wss://` for non-loopback gateways (mixed-content rules).
- **Server side** follows the standard Reticulum configuration conventions and prefers attaching to an existing shared instance rather than opening its own interfaces. Show the equivalent `rnsd` config snippet in the UI where the person must configure a gateway.
- Each interface entry states what it implies: leaf or transport, trusted local link or radio, and rough bandwidth class.

### 10.8 Connectivity status

"Socket open" tells the person almost nothing. Show the highest layer reached, always with a text cue as well as colour, mapped onto the theme classes:

| Layer reached | Label | Theme |
|---|---|---|
| No transport | `[ OFFLINE ]` | `theme-offline` |
| Gateway connected, nothing heard | `[ GATEWAY ]` | `theme-orange` |
| Host announce heard (show age and hops) | `[ HEARD ]` | `theme-teal` |
| Path known | `[ PATH ]` | `theme-teal` |
| Link established, identified, capability advertisement received | `[ LINK ]` | `theme-green` |
| Rejected, incompatible protocol version, or permission denied | `[ DENIED ]` | `theme-red` |

- Distinguish "no path yet" from "peer unreachable", and show **last-heard age** per peer (the staleness equivalent for mesh peers).
- Interpret the limitation code in the capability advertisement: permission denied shows the pairing prompt; hardware constrained, link saturated and concurrency lock each get a plain-language message.
- Log connection events in the terminal pseudo-console (design pass), with `[ OK ]`/`[ WARN ]`/`[ FAIL ]` status brackets.

### 10.9 Behaviour on a slow, lossy mesh

- **Assume minutes, not milliseconds.** No blocking spinners, no request/response assumptions. Show message states `queued, sent, delivered, failed` and persist the outbox across reloads.
- No polling. Updates are event-driven.
- **Size awareness:** show payload size before sending, warn above a single packet, and use links or resources for bulk transfers, with byte-level progress (P5 in §13).
- Timestamps from peers are claims; see §7.9.

### 10.10 Security rules

- Announce app data and every inbound payload are **untrusted**: validate length and shape against the schema, and never place them in `innerHTML`.
- **Verify peers out of band.** Show the full hash, and support local contact names (trust on first use is the realistic model).
- **Never log keys or claim codes.** Redact them in the console and in any exported diagnostics.
- **Origin and Host checks** on a localhost-bound host, and identity-based authorization as the actual gate (§9.2).
- Dev-profile capabilities exist only for an explicitly enabled dev identity on loopback.

## 11 FBP Protocol 2 utility profile (stub, A9)

Utilities use a small subset of FBP Protocol 2 over Reticulum:

- **Used:** the announce, the `0x02` capability advertisement, `0x47` packet send and the `0x49`/`0x4A` stream commands into exported inports, `0x48` status, `0x17` rejections, and read-only component signatures and schemas (`0x20` to `0x24`, `0x28`, `0x29`) to learn exported ports and their schemas.
- **Not used and refused for client identities in production:** graph CRDT sync and edits, component write and install, run control, breakpoints and process control, telemetry subscription.

The gaps below must be closed in the protocol for this profile to work as written (P1 to P6 in §13). Until they are: implement the `host-link` adapter against the target behaviour described in §7.6, keep every protocol detail behind the adapter, and report in the README under Assumptions that the utility relies on pending FBP Protocol 2 changes.

## 12 Decided (D1–D15)

| # | Decision |
|---|---|
| D1 | Utilities are PWAs. Phone is the primary UI; desktop/tablet is secondary and uses extra space to show more data. Target evergreen browsers. |
| D2 | One repository per utility. |
| D3 | No build step. Dependencies are vendored into the repo; vendoring is the only accepted build step, run only when adding or updating a dependency. As light on dependencies as possible. |
| D4 | UI is Web Components. Business logic is NoFlo 2.x. Code is ES Modules with JSDoc type annotations. |
| D5 | Deployment tier follows from what the utility must talk to: (1) Reticulum or public APIs only: static hosting (GH Pages or similar); (2) local network or files: npm package with a CLI runner that starts a server and opens the UI; (3) Signal K access: SK plugin. |
| D6 | Tier choice should be obvious from the problem. Worked examples: rngit document editor/manager = tier 1; monthly ledger-cli statement updater = tier 2; passage weather briefing = tier 3. |
| D7 | Every utility has a **client graph** (browser) and a **host graph** (adapters and I/O). |
| D8 | Prefer graph-level adaptation over configuration options. Structure goes in the graph; values go in settings. The runner is a library of shared NoFlo components shipped via npm, assembled by an LLM into a graph for each project, and vendored into the repo. |
| D9 | Tiers 1 and 2: client and host talk FBP Protocol 2 over Reticulum (the host graph appears to the client graph as a remote subgraph). Tier 3: Signal K deltas and REST; no FBP remoting. |
| D10 | Tier 2 hosts own identity and network operations server-side, bind to localhost (a secure context), and may run on the phone itself (Termux, iSH). A LAN-hosted variant with a TLS proxy such as Caddy is a possible later extension. |
| D11 | Fixed component list (no dynamic component discovery) for utilities. Errors travel on an error outport or, where applicable, accumulate in the message object (noflo-assembly style). |
| D12 | Port contracts are JSON Schemas (NoFlo 2.x ports can ship them). |
| D13 | Dacar: the host is the sole issuer of grants by default. |
| D14 | Carried over from the Signal K UI spec: vanilla components, granular DOM updates, hash routing, `minRate`-style throttling, backoff reconnects, time format rules, day/night colour tokens, tactical sci-fi aesthetic, 48 px touch targets, terminal console pattern. |
| D15 | Requested coverage: animation/motion rules; Reticulum best practices (identity generation, configuration, backup; interface configs and defaults; connectivity status). |

## 13 Assumptions, protocol gaps, open questions

Assumptions made for v0.1 (confirm or override):

| # | Assumption |
|---|---|
| A1 | Mode names stay `day` and `night`. A manual toggle persists the choice. Default when nothing sets it: `day`. A host-provided mode (e.g. SK) overrides. |
| A2 | Neutral namespace prefix `tac-` for custom elements and CSS classes. |
| A3 | Graphs are JSON files in `graphs/`, loaded at runtime. |
| A4 | v1 pairing uses one-time codes issued from the host CLI: first-run owner claim, plus `invite` for additional devices. UI-initiated invites and request/approve are deferred. |
| A5 | No QR codes in v1; pairing uses a copyable code or link. |
| A6 | Identity backup uses PBKDF2 + AES-GCM via WebCrypto, so nothing needs vendoring. |
| A7 | Termux is a tested target for tier 2; iSH is best effort. Node target is the current LTS. |
| A8 | Default licence is EUPL-1.2 with SPDX headers. |
| A9 | The FBP Protocol 2 utility profile appears as a stub that lists gaps P1 to P6. |
| A10 | Custom elements use light DOM by default. |
| A11 | Browser baseline: use only features that are Baseline (newly or widely available); anything else must be a progressive enhancement. |
| A12 | State-vs-event port marker is an additive optional port field (`retain`). |
| A13 | The announce `node_name` is the utility id. |
| A14 | CLI flag names: `--port`, `--data-dir`, `--no-open`, `invite`, `--reset-owner`, `--print-claim`. |
| A15 | "Local time" is the device clock unless a fixed offset is configured. Missing values display as `--`. |
| A16 | Each utility repo pins the spec version it follows in a `SPEC_VERSION` file. |
| A17 | A default Content-Security-Policy ships with every utility. |
| A18 | Tier 2 default port is fixed per utility, with fallback to the next free port. |

FBP Protocol 2 utility profile gaps (findings to feed upstream):

| # | Gap |
|---|---|
| P1 | `0x47` packet send and the stream commands require `LIFECYCLE_CTRL`, which also allows pause, step, breakpoints and disabling nodes. The 8-bit capability mask is fully allocated. Needs separate port I/O capabilities (`advertised_mask` or a wider field). |
| P2 | No first-class outbound packet channel for exported outports; flowtrace `DATA` events are the only visible route (buffered, runtime-chosen cadence, exposes all internal edges to `TELEMETRY_READ`). Needs per-outport subscription with prompt delivery and a retained last value. |
| P3 | `Port` has no state-vs-event marker. Needs an additive optional field (A12). |
| P4 | No pre-capability channel for claim and access-request commands; unclaimed identities get mask 0. The runtime should also re-send `0x02` when grants change. |
| P5 | No convention for large packet payloads as Reticulum Resource references. |
| P6 | Utility naming rides on `node_name` (128-byte app_data cap) or runtime metadata; fix a convention (A13). |

Dacar SPEC findings to feed upstream:

- §10.2 says "maximum 50 visited nodes, §7.2", but §7.2 states a maximum recursion depth of 10 hops.
- There is no enrollment procedure for grantees; §10.4/§10.5 here fill the gap and could become a companion profile.
- Optional key-carrying Delta form: a Delta could carry the issuer's 64-byte public key (self-verifying against the issuer hash) to remove the announce-store dependency on non-RFed transports.

Open questions:

| # | Question |
|---|---|
| O1 | Runner library: name, exact component list, versioning. Needed before the template repo. |
| O2 | Adapter port contracts (storage, files, clock, reticulum, host-link, signalk). Only named in v0.1; schemas not yet defined. |
| O3 | SK conventions: auth failure handling; how a plugin backend reaches the shared Reticulum connection plugin. |
| O4 | Relation-to-capability table for the utility profile. Depends on P1. |
| O5 | Large-payload convention (Reticulum Resource references). Depends on P5. |
| O6 | Service worker update flow and cache strategy. |
| O7 | UI-initiated invites and request/approve pairing. Deferred by A4. |
| O8 | Design system, motion, accessibility, alarm module, maps and charts. |
| O9 | Template repo skeleton and acceptance checklist beyond §15's. |
| O10 | Validate by building the three example utilities from the spec. After the template repo. |

## 14 External references

| Reference | Version | Used for |
|---|---|---|
| FBP Protocol 2 SPEC and AsyncAPI document | 2.0.0-alpha.1 | Announce app-data serialization (§10.6), capability advertisement, packet and stream commands, component signature hashing (`sig_hash`, §7.6), the utility profile (§11) |
| Dacar SPEC | 1.0 | Grants, relations, privacy salt, hybrid logical clock, store layout (§10.4, §10.5) |
| reticulum-js | pin the exact vendored version in `vendor/vendor.json` (§6.6) | Browser and server Reticulum: identities, links, packets, resources (§7.5) |

All three are first-party packages: canonically distributed as signed rngit releases, with registries as mirrors (see `~/.pi/agent/context/package-installation.md`).

## 15 Acceptance checklist

Before reporting done, verify each item and say which, if any, you could not verify.

- [ ] `npm run check` (type check) passes with no `any` outside vendored-library boundaries.
- [ ] `npm test` passes; every NoFlo component and graph has a test using adapter doubles.
- [ ] No file in `src/` imports from outside `src/`, `vendor/` or Node built-ins.
- [ ] `vendor/` has a manifest entry (name, version, SPDX licence, source, SHA-256) for every file group; all licences are EUPL-1.2-compatible.
- [ ] No `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval`, `new Function` with data.
- [ ] Every UI value that changes at runtime is updated through a cached element reference (`textContent` or a specific attribute).
- [ ] Every view has loading, empty, error and offline states.
- [ ] All interactive targets are at least 48x48 px on the phone layout.
- [ ] Every URL in HTML, CSS, JS and the manifest is relative.
- [ ] The README states the problem, the tier and why, how to run, assumptions and deviations.
- [ ] `SPEC_VERSION` is present and matches the spec used.
- [ ] No secret appears in logs, URLs, test fixtures or committed files.
