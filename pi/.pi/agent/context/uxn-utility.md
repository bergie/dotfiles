# Utility Spec, Uxn profile (consolidated, v0.1 draft)

Context document for LLMs writing personal utilities whose UI is a Uxn/Varvara ROM and whose logic, networking and storage are NoFlo 2.x graphs. This file is the complete spec for this profile; load it, together with the Uxn/Varvara App Guidelines, before writing any code for a utility, so the conversation with the person is about the *problem* the utility solves, not about how to build it.

A utility is one app in one repository: a **bundle** made of a Uxn ROM (the UI), NoFlo graphs (logic, networking, persistence) and JSON Schemas (the contract between them). The ROM and the host graph exchange small text files in a Maildir-style directory (§7.6). The same bundle runs on the LilyGo T-Deck Max (graphs on MicroFlo), on desktop and mobile (graphs on NoFlo, ROM in a native Varvara emulator) and in a browser (NoFlo plus a JS or WASM Uxn VM). A bundle is data: installing or updating it needs no reflash and no build on the target. It is deployed in one of three tiers depending on what it must reach (§8).

This profile replaces the web UI of the original Utility Spec (Web Components PWA, client graph, browser-facing `host-link`). Everything on the host side (NoFlo layer, adapters, tiers, Reticulum identity, Dacar access, FBP profile) carries over, adapted where noted. Not yet specified: module conventions (Signal K, maps and charts, realtime data) and ROM-side widgets shared between utilities.

Related context documents, to load alongside this one:

- `uxn-app-guidelines.md`: Uxn/Varvara App Guidelines: Small Screens, Keyboard-First (A30). **Authoritative for everything inside the ROM**: layout tiers from 320x240 upward, keyboard-first input, themes and visual style, metadata and manifest, redraw rules, the plain-text storage rules (its §7.2) that §7.6 builds on, and its testing checklist. This spec does not repeat those rules. Where the two overlap, the guidelines win for the ROM and this spec wins for the host side and the boundary between them.
- `factotum-spec.md`: Varvara Factotum & Multi-Principal Capability Specification (A35). The reference for people *implementing* a Factotum host. It is not needed to write a ROM: the usage side, the part a ROM author needs, is complete in §7.14.
- `~/.pi/agent/context/component-basics.md` (NoFlo 2.x patterns), `~/.pi/agent/context/package-installation.md` (first-party package distribution), `~/.pi/agent/context/signalk-visuals.md` (Signal K UI rules; only its time, staleness and status-text rules apply here, see §7.2).

The decisions log at the end (§12–§13) records which rules were decided, which were assumed for v0.1, and what is still open. Do not re-open decisions listed there; assumption tags `(A#)` are listed in §13: follow them and mention in your report which you relied on. A1 to A18 come from the original spec, some amended; A19 and up belong to this profile.

## 1 Normative language

- **MUST / MUST NOT**: hard constraint. Never override. If the task seems to require breaking one, say so and stop.
- **DEFAULT**: do this unless there is a concrete reason not to. If you deviate, state the reason in one line in the README under "Deviations".
- **ASSUMPTION `(A#)`**: a v0.1 placeholder the maintainer has not confirmed (listed in §13). Follow it, and mention in your report that you relied on it.

## 2 When the spec is silent

Choose the most conservative option that is consistent with the stack, the tier and the aesthetic. Prefer fewer dependencies, fewer features, native platform APIs. State the assumption in one line in the README under "Assumptions". Do not ask the person about technical choices the spec could have answered; ask only about the problem.

## 3 Interaction workflow

Follow this order. Keep the person's attention on the problem.

1. **Restate the problem** in two or three sentences, in the person's terms.
2. **Inventory I/O**: what must the utility read, write, and talk to? Files, local devices, public APIs, Reticulum peers, Signal K data. List them. Then list what the person must see and do on a 320x240 screen with a keyboard.
3. **Pick the tier** from the I/O inventory (§8). State it in one line: "Tier 2, because it needs the ledger files on disk." Do not ask for confirmation unless two tiers genuinely fit. Prefer the lowest tier: push to a companion only what the device cannot do itself.
4. **Ask at most three questions**, all about the problem (inputs, outputs, edge cases). If the answer can be assumed safely, assume and state it.
5. **Design before code.** Write down, in the README or a design note:
   - the host graph as a list of nodes with named, typed ports, all drawn from the platform component set (§7.3);
   - the exported ports of the host graph with JSON Schemas and, for each, its mailbox, direction and kind (event, state, request), as a table (§7.6);
   - the ROM's screens, the key map of each, and which view port each screen draws from;
   - adapters needed and which host environments supply them;
   - the Factotum capabilities the ROM needs (protocols, roles, scopes), as the `needs` line of its signed manifest (§7.14).
6. **Build in this order**: schemas, host components (pure logic first, and only if the platform set cannot express them), graphs, adapters, mailbox fixtures and conformance tests, ROM mailbox library, ROM screens, wiring, tests.
7. **Run the acceptance checklist** (§15) and report any item you could not satisfy.
8. **Report briefly**: what was built, the tier and why, assumptions relied on, deviations, platform requests, and anything the person must do by hand (vendoring, claim code, creating the data directory, etc.).

## 4 Glossary

- **Utility**: one app, one repository. Ships as a bundle.
- **Bundle**: the installable unit: ROM (`.tal` source and assembled `.rom`), graph JSON, schemas, README. Pure data: it installs without a reflash or a build on the target.
- **ROM**: the Uxn/Varvara program that is the UI: screen, keyboard, UI state. No business logic.
- **Host graph**: NoFlo graph that owns I/O and logic: files, storage, network, Reticulum, long-running work, formatting, authoritative data. Runs on MicroFlo (T-Deck) or NoFlo (desktop, mobile, browser).
- **Host environment**: where a host graph runs. *Device*: MicroFlo on the T-Deck Max. *Desktop/mobile*: NoFlo on Node or Termux. *Browser*: NoFlo plus a JS or WASM Uxn VM.
- **Companion**: a second host graph on a machine with reach the device lacks (internet, local files, Signal K), linked to the device host graph over Reticulum (§7.13).
- **Tier**: deployment shape (1 self-contained, 2 companion or local OS reach, 3 Signal K).
- **Platform component set**: the small audited set of NoFlo components, implemented at least twice (NoFlo and MicroFlo), from which all graphs are assembled.
- **Adapter**: component(s) that wrap an external effect behind a fixed port contract. The only host-environment-specific layer.
- **Exported port**: an inport or outport of the host graph that the ROM may use. Each maps to exactly one mailbox.
- **Exchange root / mailbox**: the exchange root is the ROM's working directory. A mailbox is a directory in it holding one port's messages as text files (§7.6).
- **View port / command port**: a retained outport carrying a snapshot the ROM draws, and an inport the ROM sends commands to.
- **Runner library**: shared host-side material (platform components, mailbox adapter, standard ports, Reticulum host, claim gate, grant store, emulator launchers, browser shell) installed via npm and vendored. Name, exact list and versioning are still open (§13 O1).
- **Port contract**: the name, direction, JSON Schema, and semantics of a port.
- **Factotum**: the host service, served to the ROM as a synthetic `factotum/` directory over the File device, that performs signing, verification, sealing and capability checks so the ROM holds no keys (§7.14).
- **Provenance record**: the user, device, ROM hash and author that the host establishes when it loads a ROM. It decides what the ROM may reach, through mailboxes and through Factotum (§7.14).

## 5 Hard constraints at a glance

These are repeated from the sections below so they are never missed.

1. **Build:** the only build steps are vendoring and assembling the ROM with the vendored assembler. No bundler, transpiler, minifier or generator that must run before the bundle works. Source and assembled ROM are both committed.
2. **Dependencies are vendored** under `vendor/` with a manifest. No CDN. No runtime `npm install`. No runtime code fetching.
3. **The UI is a Uxn ROM written in Uxntal; logic is NoFlo 2.x graphs.** No web UI, no other UI toolkit.
4. **JSDoc types** with `// @ts-check` in every host-side `.js` file.
5. **The ROM contains no business logic**: presentation, input and UI state only. It redraws only what changed (Uxn App Guidelines).
6. **The ROM boundary is text files in mailboxes** (§7.6). All data crossing it, in either direction, is untrusted and validated.
7. **Fixed platform component set.** Graphs use only the audited set. No dynamic component loading.
8. **No mode flags** on components or in the ROM. If a flag changes which things happen, split the component. The ROM's layout tier follows the screen size, never a setting.
9. **All external effects go through adapters.** Logic components never touch files, network, storage or Reticulum directly. The ROM's only effects are the screen, input and the File device inside its exchange root.
10. **Portable ROM only:** standard Varvara devices at the pinned version; no reserved devices, no process spawning, no absolute paths, no path built from data.
11. **Small screen first:** 320x240 is the floor, keyboard-first, mouse optional. Extra space on larger screens shows more data, not different features (Uxn App Guidelines).
12. **Time displays** are local ship/device time with no zone specifier, or UTC with a `Z` suffix. Dates are `YYYY-MM-DD`.
13. **Secrets** (keys, claim codes, tokens) are never logged, never written into mailboxes or the exchange root, and never placed in persistent URLs. The one exception: a one-time claim code the person types into the ROM travels in a single command message that the host deletes on read (§10.5).
14. **No keys and no cryptography in the ROM.** Signing, verification, sealing and capability checks go through Factotum (§7.14), gated by the ROM's provenance.

## 6 Stack and repository

### 6.1 Stack

| Concern | Choice | Rule |
|---|---|---|
| UI | Uxn/Varvara ROM in Uxntal, one ROM per utility | MUST. Follow the Uxn App Guidelines. No web UI, no other UI toolkit. |
| Business logic, I/O, networking | NoFlo 2.x graphs (MicroFlo on the T-Deck) built from the platform component set | MUST. The ROM holds presentation and input handling only. |
| ROM to host | Maildir-style mailboxes: plain text records in the ROM's working directory | MUST. See §7.6. |
| Types | JSON Schemas for every port; JSDoc checked by `tsc --noEmit` for host-side JS | MUST. See §6.4. |
| Build | Assemble the ROM; vendor dependencies | MUST. See §6.3. No other build step. |
| Dependencies | Vendored, minimal | MUST. See §6.6. |
| Targets | Varvara 80K hosts at 320x240 and up, keyboard-first; MicroFlo on the T-Deck Max; Node LTS and evergreen browsers for NoFlo hosts | See §6.2, §9. |

### 6.2 Platform baseline (A20, A11)

- **ROM:** target the current Varvara spec (80K) and declare the version in metadata field `56`. Use only the standard devices. MUST NOT use the reserved devices or any host-specific feature: a ROM that depends on them does not run on other hosts. Test on at least two hosts (for example a native emulator and the device or a JS VM). Factotum (§7.14) is reached through the standard File device, so it is not a host-specific feature, but a host may not provide it: the ROM MUST degrade.
- **Primary device:** the T-Deck Max, 320x240 with a hardware keyboard. Desktop and larger screens are secondary and show more data. Mouse and touch are optional enhancements; never require them.
- **Host side:** Node LTS for NoFlo hosts. For the browser host shell (part of the runner library), use a platform feature only if it is **Baseline**; anything else is a progressive enhancement with a working fallback.

### 6.3 Build: assemble and vendor only

MUST NOT use: bundlers, transpilers, minifiers, template compilers, or code generators that must run before the bundle works. What is in the repo is what ships.

Allowed, because nothing they produce runs on the target except the ROM itself:

- `npm run rom` runs `scripts/assemble.mjs`, which assembles `rom/main.tal` (and the files it includes) into `rom/<utility-id>.rom` and `rom/<utility-id>.rom.sym` with the vendored assembler. Assembly is deterministic.
- `tsc --noEmit` as a type check (dev dependency only, run via `npm run check`).
- `node --test` for tests.
- `scripts/vendor.mjs`, the vendoring script (§6.6).

The `.tal` source and the assembled `.rom` are both committed (A21). The `.rom` is what installs, so the target needs no toolchain. A test re-assembles the source and fails if the committed `.rom` differs; this is the counterpart of the web profile's service-worker precache drift test.

### 6.4 Types and schemas

- Every host-side `.js` file under `src/`, `scripts/`, `bin/` and `test/` starts with `// @ts-check`. Most utilities have little host-side JS, because graphs are assembled from the platform set.
- `jsconfig.json` (or `tsconfig.json`) sets `checkJs: true`, `strict: true`, `noEmit: true`, `module`/`moduleResolution` for native ESM, `allowJs: true`.
- Shared types are `@typedef`s in `src/types.js`. Every exported function has `@param` and `@returns`. `any` is allowed only at the boundary with a vendored library lacking types; prefer `unknown` plus validation.
- JSON Schemas in `schemas/` are the source of truth for port payloads (D12). A port declares its schema as the id `<utility-id>/<schema-name>` (NoFlo 2.x `ns/name` form) and the schema body lives in `schemas/<schema-name>.json`; no cross-file `$ref` in v1, so a schema's closure is the single file. A test MUST validate sample payloads against each schema.
- **ROM-facing schemas** use the restricted subset in §7.6 (A28). The ROM's own checks are hand-written in Uxntal and mirror that subset; the host validates everything the ROM writes against the full schema.
- Validation of inbound data on the host: use the schema/guard facilities of the NoFlo runtime where available; otherwise a small hand-written validator for the subset actually used (type, enum, min/max, required). Do not add a general-purpose validator dependency without a justification line in `vendor/vendor.json`.

### 6.5 Repository layout

One repository per utility.

```
my-utility/
├── README.md              # problem, tier and why, how to run, mailbox table, key map,
│                          # Assumptions, Deviations, Platform requests
├── AGENTS.md              # tells LLM agents to follow the pinned spec and the Uxn guidelines
├── SPEC_VERSION           # e.g. "uxn-0.1"
├── LICENSE                # EUPL-1.2 (A8)
├── package.json           # "type": "module"; scripts; tier 2 "bin"; tier 3 signalk keys
├── jsconfig.json
├── rom/
│   ├── main.tal           # reset vector (metadata first), vectors, screen table
│   ├── screens/           # one file per screen: <screen>.tal
│   ├── lib/               # mailbox.tal, text.tal, layout.tal, small helpers
│   ├── <utility-id>.rom   # assembled from rom/*.tal; committed
│   └── <utility-id>.rom.sym
├── graphs/
│   ├── host.json          # host graph, runs beside the ROM
│   └── companion.json     # tier 2 and 3 only: the companion's graph
├── schemas/               # JSON Schemas for exported ports and adapter contracts
├── src/                   # host-side JS, only when needed
│   ├── adapters/<n>/      # one directory per adapter, per host environment
│   ├── components/        # utility-specific components (a Deviation, A19) and index.js
│   └── lib/
├── test/                  # node:test: graphs, schemas, mailbox conformance, ROM build check
│   ├── doubles/
│   └── fixtures/mailboxes/    # sample message files, valid and invalid
├── scripts/
│   ├── vendor.mjs         # vendoring
│   └── assemble.mjs       # assembles the ROM with the vendored assembler
├── vendor/
│   ├── vendor.json        # manifest of every vendored package
│   └── <package>/...      # vendored sources, unmodified
└── bin/
    └── <utility>.mjs      # tier 2 only: CLI entry
```

There is no `index.html`, manifest, service worker or stylesheet in a utility: the browser host shell belongs to the runner library.

Conventions:

- File names are kebab-case. Port, mailbox and screen names are kebab-case. Uxntal labels are scoped by screen (`@home/draw`).
- Utility-specific NoFlo components (a Deviation) are namespaced by the utility id: `<utility-id>/<ComponentName>`.
- Graphs are JSON in `graphs/`, loaded at runtime (A3). The ROM and the graphs are data.
- `package.json` scripts: `vendor`, `rom`, `check` (`tsc --noEmit`), `test` (`node --test`), and for tier 2 `start`. Nothing else.
- Dev dependencies are limited to the type checker and the Uxn command-line emulator that runs the assembler. They are never vendored or shipped.
- `AGENTS.md` contains: the pinned spec version, the instruction "follow the Utility Spec (Uxn profile) at that version and the Uxn App Guidelines; their rules override your defaults", and the location of both documents.

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

Additions for this profile:

- **The assembler is a dev tool.** Drifblim is vendored as `vendor/drifblim/drifblim.rom` (with its manifest entry) and run by a Uxn command-line emulator, which is an installed dev dependency like the type checker. Neither is shipped.
- **Shared Uxntal libraries** (theme loading, manifest, the mailbox reader and writer from the runner library) are vendored as unmodified `.tal` source under `vendor/<name>/` and included from `rom/`. Each has a manifest entry like any package.
- **The platform is not vendored.** MicroFlo and the in-firmware Varvara VM are the platform. The README names the platform component-set version the graphs were written against.

### 6.7 Licensing (A8)

- DEFAULT licence is EUPL-1.2. Every source file carries `SPDX-License-Identifier: EUPL-1.2` in the comment syntax of its type (`//` for JS, `( ... )` for Uxntal, `<!-- -->` for Markdown where useful).
- `LICENSE` contains the licence text. `README.md` names it.
- Vendored code keeps its own licence and is listed in `vendor/vendor.json`.
- Utilities that are never released may still follow this; deviations go in the README.

### 6.8 README and AGENTS requirements

`README.md` MUST contain:

- the problem in two or three sentences;
- the tier and the reason;
- how to run it (and, for tier 2 and 3, how to start the host and pair a device);
- the **mailbox table**: every exported port with its mailbox, direction, kind and schema id;
- the **key map** of every screen;
- the `needs` line (Factotum protocols, roles and scopes) of the signed manifest, if the ROM uses Factotum;
- an "Assumptions" section, a "Deviations" section, and a "Platform requests" section (components the platform set lacks);
- the platform component-set version the graphs were written against;
- how to update vendored dependencies.

## 7 Architecture

### 7.1 Overview

```
 ┌──────────── Varvara VM ───────────┐          ┌─────────── host ────────────┐
 │  ROM (Uxntal)                     │  files   │  host graph (NoFlo/MicroFlo) │
 │   screen, keyboard, UI state      │  in the  │   platform components        │
 │   reads inbox/, writes outbox/ ───┼─ exchange┼─▶ mailbox adapter            │
 │                                   │  root    │   other adapters ────────────┼─▶ storage, files,
 └───────────────────────────────────┘          │   host-link ─────────────────┼─▶ network, Reticulum,
                                                └──────────────────────────────┘   companion graph
```

- **Device:** the ROM runs in the VM inside the T-Deck firmware; the host graph runs on MicroFlo beside it.
- **Desktop and mobile:** the host graph runs on NoFlo (Node, Termux); the runner starts a native Varvara emulator on the ROM with the exchange root as its working directory.
- **Browser:** the host graph runs on NoFlo in the page beside a JS or WASM Uxn VM. The VM's File device and the `mailbox` adapter share one virtual filesystem.
- **Tiers 2 and 3:** a second host, the companion, is reached through `host-link` (§7.13). The ROM never talks to it directly.

The split is the point: the ROM and the graphs are the same across host environments, and adapters are the only environment-specific code.

### 7.2 UI layer: the ROM

MUST:

- Follow the Uxn App Guidelines: layout derived from `Screen/width` and `Screen/height` with 320x240 as the floor, keyboard-complete input with the mouse optional, theme loading, metadata registered as the first instruction at reset, redraw only when something changed.
- Own presentation and UI state only: current screen, cursor and selection, scroll offset, focus, the text being typed, the names of messages already handled. Anything that must survive closing the ROM, or that the person would call data, belongs to the host graph.
- Talk to the host through mailboxes only (§7.6): read view ports and event ports, write command ports. The only other files it touches are `.theme`, `.snarf` (Guidelines §5, §7) and the synthetic `factotum/` directory (§7.14). Paths are fixed and relative.
- **Draw from the latest snapshot.** A view port carries everything the current screen needs, already formatted (§7.9). The ROM never formats numbers or times from raw data, and never sorts, filters or aggregates. When a list exceeds a screen, the ROM asks for a window by command (`offset`, `count`) and the host answers with a new snapshot.
- **Poll cheaply** (§7.6). No timers for data, no polling at frame rate.
- **Hold no keys and do no cryptography.** Ask Factotum (§7.14), handle its `ok`, `err` and `needconfirm` answers, and hide features whose capability is absent.
- **Show pending states.** After a command, show a pending state until the answer or the next snapshot arrives. Never block.
- Keep one `.tal` file per screen. Each file begins with a header comment listing the ports it reads and writes and the keys it handles.
- Use static buffers sized by the limits in §7.6. No unbounded copies; check bounds on every read.

What carries over from the web profile and how:

| Web profile rule | In this profile |
|---|---|
| Granular DOM updates, never re-render subtrees | Redraw only when changed, by region where it pays (Guidelines §6). |
| Hash routing | A screen table (§7.8). |
| `minRate` throttling | The host throttles view-port publication; the ROM draws the newest snapshot only. |
| Backoff reconnects | Host side, in the Reticulum and `host-link` adapters. |
| Time formats | Unchanged (§7.9). |
| Day/night colour tokens | Varvara themes (`.theme`), Guidelines §5. No mode flag. |
| Tactical sci-fi aesthetic | The visual style of Guidelines §5.1 (A1 amended). |
| 48 px touch targets | Not applicable: keyboard-first. Optional mouse controls follow the Guidelines. |
| Terminal console pattern | A `log` screen fed by the `console` port (§7.6). |
| Status labels with colour classes | Text labels from §10.8 with a non-colour cue; colour only as a secondary cue. |

### 7.3 NoFlo layer

For NoFlo 2.x component mechanics — port declarations, control and addressable ports, information packets and streams — refer to `~/.pi/agent/context/component-basics.md`. Note that utilities use a fixed component set (below), not the loader-based discovery described there.

Components:

- **Platform component set** (D11, D19, A19): graphs are assembled only from the audited platform component set, implemented at least twice (NoFlo and MicroFlo) and shipped with the runner library (O1). No dynamic discovery, installation or loading. Adding a component is a platform release, and on the T-Deck a reflash, so add one only when a graph cannot express the need, and write the request under "Platform requests" in the README. A utility-specific component is a Deviation: it lives in `src/components/` with an explicit registry `src/components/index.js`, and it restricts the bundle to NoFlo hosts.
- **One responsibility per component.** Port names are plain nouns or verbs.
- **No mode flags** (D8). If a flag changes which things happen, split the component. Port configuration carries *values* (a path, an interval, a threshold), never behaviour switches.
- **Every port has a JSON Schema** in `schemas/` (D12). Port payloads MUST be wire-safe: MsgPack is the wire encoding (§14), so payloads are limited to what both JSON and MsgPack represent, plus byte strings (`Uint8Array`) — no functions, DOM nodes, `undefined`, `Date`, `Map`, `BigInt`, `NaN` or `Infinity`. This keeps hosts interchangeable. Ports that cross the ROM boundary are restricted further (§7.6, A28).
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
- Lifecycle: NoFlo 2.x has no start or shutdown packets. A network starts when the host application starts it; fixed values enter as initial information packets (IIPs), and control ports redeliver standing configuration at each network start. A long-running utility network stays running because its boundary sources — the adapters — hold their transmissions open. To stop it, the host ends those transmissions (end-of-transmission) and calls `network.stop()` (wired to SIGINT/SIGTERM in tier 2). Closedown is cascading: a network ends when every boundary input is at end-of-transmission and the network is quiescent. Components release resources in `tearDown` handlers, called at shutdown; a shutdown that hangs is a component bug (see the has-first activation rules in `component-basics.md`). On the T-Deck the network starts at boot and runs until power-off; `tearDown` handlers are best effort there.

### 7.4 ROM and host graph

| | ROM | Host graph |
|---|---|---|
| Runs | in the Varvara VM, on every host environment | on MicroFlo (device) or NoFlo (desktop, mobile, browser) |
| Owns | screen, keyboard, UI state, drawing | data, files, storage, network, Reticulum, long-running work, formatting, all business logic |
| Talks to | the host graph, through mailboxes only | adapters; the ROM through the `mailbox` adapter; other hosts through `host-link` |
| Tier 3 | unchanged | the companion is a Signal K plugin backend; the device host graph reaches it through `host-link` |

Rule of thumb: if it must survive closing the ROM, or touches the outside world, it belongs in the host graph. If it exists only to show something or to capture a keystroke, it belongs in the ROM.

### 7.5 Adapters

An **adapter** wraps an external effect behind a fixed port contract. v0.1 names the standard set; their schemas are not yet defined (O2).

| Adapter | Purpose | Implementations |
|---|---|---|
| `mailbox` | the exchange root: deliver to `inbox/`, consume from `outbox/` (§7.6) | Node `fs` (desktop, mobile); the firmware filesystem (device); the shared virtual filesystem (browser) |
| `factotum` | serves the synthetic `factotum/` directory; keys never leave it (§7.14) | Node with the host keystore; device with NVS or a secure element; WebCrypto in a browser |
| `storage` | key-value and blob persistence | IndexedDB (browser); files in the data dir (desktop, mobile); the device filesystem (device); SK plugin config and resources (tier 3 companion) |
| `files` | read/write/list in a configured root | desktop, mobile, companion |
| `clock` | now, ticks | system clock; controllable double |
| `reticulum` | announce, links, packets, resources | reticulum-js in the browser; server-side on desktop, mobile and companion; the device's native stack |
| `host-link` | remote-subgraph transport between hosts | FBP over Reticulum (§7.13) |
| `signalk` | delta subscription, REST, meta | tier 3 companion only |

Rules:

- Adapters live in `src/adapters/<n>/` (or in the runner library), one implementation per host environment.
- Choosing an implementation is a graph-assembly decision (which node is in the graph), never a runtime flag.
- Every adapter has a test double in `test/doubles/`.
- `files` MUST confine access to its configured root: normalise paths, reject `..`, and refuse symlinks that leave the root.
- Adapters validate everything inbound against the port schema before it enters a graph. The `mailbox` adapter treats the ROM as untrusted (§7.10).

### 7.6 The ROM boundary: Maildir-style mailboxes (D18)

The ROM and the host graph never share memory or sockets. They exchange small text files in the **exchange root**, which is the ROM's working directory. This is Maildir in spirit: a directory per mailbox, one file per message, delivery by writing a complete file, consumption by deleting it. It builds on the storage rules of the Uxn App Guidelines (§7.2 there). It needs only the Varvara File device, it survives either side restarting, writers never conflict (one writer per mailbox), and the same layout works on the T-Deck, a desktop and a browser VM.

**Layout** (A22):

```
<exchange-root>/        the ROM's working directory; the File device cannot reach outside it
├── inbox/<port>/       host to ROM: one mailbox per exported outport
├── outbox/<port>/      ROM to host: one mailbox per exported inport
├── blobs/              large payloads sent by reference
├── factotum/           synthetic, served by the host: cryptographic sessions (§7.14)
├── .theme              Varvara theme (Guidelines §5)
└── .snarf              clipboard (Guidelines §7)
```

- The **host creates every directory** at install and at start-up, from the exported ports. The ROM never creates directories: Varvara has no create-directory operation, and the spec is silent on creating one by writing (O13).
- One mailbox per exported port, named after the port. **One writer and one reader per mailbox:** the host writes `inbox/*` and reads `outbox/*`; the ROM does the opposite. One ROM per exchange root (A29); two UIs over the same data get two exchange roots provisioned by the host.
- The exchange root is mode `0700` where the platform has modes. It never contains secrets (§5.13).
- On the device, the exchange root SHOULD sit on volatile storage so frequent snapshots do not wear flash; durable data goes through the `storage` adapter (A26, O14).

**Message file.** A message is one file named `<seq>.msg`, where `<seq>` is the writer's counter as eight decimal digits (`00000042.msg`). The content is UTF-8 text in the record shape of the Guidelines: header lines, a blank line, a body, and a terminator.

```
id: 00000042
schema: sailing-log/entry-list
in-reply-to: 00000007

count: 2
title: Anchorage at Kawau
entry: 2026-11-25	14:30	Anchored
entry: 2026-11-25	18:05	Wind NW 15 kn
note: A longer value is folded onto
 continuation lines that start with one space.
--end--
```

- **Headers:** `id` (equals `<seq>`), `schema` (the port's schema id), optional `in-reply-to` (a request id) and optional `ref` (a blob name). Unknown headers are ignored.
- **Body:** `key: value` lines. Keys match `[a-z][a-z0-9-]*`. A value is one line; longer text folds onto continuation lines that begin with a single space. A repeated key is an ordered list. A row of columns is one value with columns separated by a tab; the schema description names the columns.
- **Terminator:** the final line is `--end--`. A message without it is incomplete. No key can equal it, and folded lines start with a space, so it cannot occur inside a body.
- **ROM-facing payload subset (A28):** a flat object whose values are strings, integers, booleans, lists of those, or tables of columns. No nesting, no floats, no null (omit the key). Display values arrive already formatted (§7.9). Text is printable ASCII by default (O11). The host validates ROM-written messages against the full schema; the ROM checks the subset by hand.

**Writing.**

- Compose the whole record in memory and write it in one pass to a new file. Never rewrite or append to an existing message; to change state, send a new message.
- Counters strictly increase per mailbox. At start, a writer seeds its counter with the highest name present in its mailbox plus one, or one if the mailbox is empty.
- Host-side writers SHOULD deliver as real Maildir does: write into a `tmp/` directory beside the mailboxes, then rename into place, so a reader never sees a partial file (A25). The ROM cannot rename (Varvara has no rename), so ROM-side writers rely on the terminator. Readers always check the terminator, whoever wrote the file.
- A move is a copy then a delete: write the complete record under its new name, then delete the old one. A crash in between leaves a duplicate, never a loss, so readers tolerate duplicates.

**Reading.**

- List the mailbox directory. Varvara returns one line per entry (four characters of details, a tab, the name; directories end with `/`) in unspecified order, so the reader picks the smallest name itself. Keep only names matching `[0-9]{8}\.msg`.
- Read the file into a bounded buffer. Skip it if it lacks the terminator (leave it in place and retry on the next poll). Delete it, and report it on the `console` port, if it is complete but oversized or invalid.
- After handling a valid message, delete the file. Deletion is consumption.
- The host sweeps orphans: at start it removes incomplete files it wrote itself, and it removes incomplete ROM-written files older than ten seconds.

**Port kinds.**

| Kind | Direction | Mailbox behaviour |
|---|---|---|
| Event | either | Handled in order and deleted. Not replayed. |
| State (retained) | host to ROM | The reader takes the highest-numbered complete message as the current value, deletes all older ones, and leaves the newest in place, so a restarted ROM starts from the last state (A12). The marker is the port's `retain` field (P3). |
| Request and response | ROM to host, then host to ROM | The request carries an `id`; the answer arrives on a response port with `in-reply-to` echoing it. Answers may take minutes over a mesh: the ROM shows a pending state and never blocks. |

**Standard ports** (A27). Every host graph exports these through a runner-library subgraph; the ROM uses what it needs.

| Port | Kind | Purpose |
|---|---|---|
| `status` | state, host to ROM | Connectivity layer reached (§10.8), last-heard ages, host health. The ROM MUST show it. |
| `console` | event, host to ROM | Log lines for the `log` screen. |
| `prefs` / `prefs-set` | state / command | UI preferences, held by the host (§7.7). |
| `outbox-state` | state, host to ROM | States of persisted commands: `queued`, `sent`, `delivered`, `failed`, each with an optional `reason` such as `waiting: batch 3 of 10` (§10.11). |
| `export` / `import` | command with response | Export and import of the utility's data (§7.7). |

**Polling and wake-up** (A24). Varvara has no file-change event, so the ROM polls its inbox mailboxes: at most once per second while a screen is visible (count frames in the screen vector), immediately after it sends a command, and after a key press. It does not poll while it has nothing to show. A host MAY write a wake byte to the Console input to prompt an immediate poll; ROMs MUST accept it and MUST NOT depend on it (O12). The host's `mailbox` adapter uses change notification where its platform has it (for example `fs.watch`, or a hook in the firmware), and otherwise polls only while a ROM is running.

**Delivery.** At-most-once, host authoritative. Messages the ROM did not consume stay on disk and are handled when it next runs, unless the host expires them. A restarted ROM takes its snapshot from the state mailboxes; it does not try to replay what it missed. User actions that must survive a restart persist as command files in `outbox/` until the host consumes them, and the host reports their progress on `outbox-state`.

**Limits** (A23). A message is at most 2048 bytes; a mailbox holds at most 32 pending messages. When an event mailbox is full, the host drops the oldest unconsumed event and counts it. When the host is not consuming and the ROM's outbox is full, the ROM stops sending and shows an offline state.

**Large payloads.** The writer first writes the payload as a complete file in `blobs/`, then sends a message with a `ref` header naming it. The reader deletes the blob after use. Readers read blobs in chunks. Over the mesh, the payload travels as a Reticulum Resource (P5) and arrives in `blobs/` on the receiving host.

### 7.7 State and persistence

- The host graph is authoritative. The ROM holds screen state and nothing else that matters.
- **UI preferences** (theme choice, last screen, unsent drafts) go to the host with `prefs-set` and come back on the retained `prefs` port (A27). The ROM works with defaults when no `prefs` message exists and keeps no preference files of its own.
- Persisted data carries `{ "format": "<utility-id>", "version": n }`. Migrations are components in the host graph.
- Every utility MUST offer **export and import** of its data as JSON through the `export` and `import` ports. Export writes its file to a configured location *outside the exchange root*. For import, the person places a file in the host's import location; the host validates it against the schema and publishes a **preview** on a view port; the ROM shows it and applies only after the person confirms. Import never silently overwrites.
- Browser hosts SHOULD request persistent storage (`navigator.storage.persist()`) and report on `status` when the browser declines. Device hosts batch writes to flash.

### 7.8 Screens and navigation

- Screens are declared in one table in `rom/main.tal`. The default screen is `home`. An unknown screen falls back to the default and shows a brief notice.
- Navigation is a stack with one documented back key. Every screen draws a title line; focus starts on the first control.
- A screen's parameters are simple values only. No secrets.
- No transitions.
- Pairing is a screen, not a route (§10.5).

### 7.9 Data formatting (A15)

- **All formatting happens in the host graph**, in formatting components (on NoFlo hosts a shared `format` library). The ROM never formats: view ports carry display strings, already scaled, rounded and in the right time format, and the ROM draws them. Where the ROM needs a number for its own logic (a cursor index, a count) it is a 16-bit integer.
- **Units** are not hardcoded in components. They come from the value's schema (and, in tier 3, from Signal K `meta`). Scale SI-derived units with ISO prefixes for readability (1200 W becomes 1.2 kW; 15000 Wh becomes 15 kWh). Exempt from prefix scaling: angles, percentages, time and dates, temperatures, counts, and display units such as knots or nautical miles.
- **Precision:** DEFAULT three significant digits unless the schema says otherwise. **Missing, null or stale values display `--`.** Telemetry numbers use `.` as the decimal separator with no grouping. Parse user-entered numbers in the host graph, accepting both `.` and `,`; the ROM sends the text as typed.
- **Time (MUST):** show either local time with no zone specifier (`14:30`) or UTC with a `Z` suffix (`04:30Z`). Never `LST`, `GMT+2` or similar. 24-hour clock. Dates are `YYYY-MM-DD`; combined forms are `2026-11-10 14:30` (local) and `2026-11-10T04:30Z` (UTC).
- **Source of local time:** the device clock, unless the utility is configured with a fixed offset. In tier 3, use `environment.time.timezoneOffset` when present (encoded as `(-)hhmm`, for example `200` or `-930`; verify against the current Signal K schema before relying on it).
- **Timestamps from remote peers are claims, not truth.** Show them as such and fall back to receive time when absent or implausible.
- **Staleness:** a value older than its schema-declared maximum age is marked by the host: the view port carries the display string plus an age cue in text (for example `12 min`), and the ROM may also flag it with a glyph or dimming. Never by colour alone, and always legible in two tones.
- **Characters (O11):** DEFAULT printable ASCII. The host replaces anything the ROM's font cannot draw.

### 7.10 Security basics (all tiers)

- **The ROM is untrusted code** (A33). The `mailbox` adapter validates every ROM-written message against the port schema, caps its size, rate-limits per port, and rejects or quarantines failures. A ROM only ever sees the mailboxes its grants cover (§10.4).
- **Authority is an intersection** of the user's policy, the author's signed manifest and the device context (§7.14). The same provenance record decides which mailboxes are provisioned and which Factotum capabilities are served.
- **The ROM treats every inbound message as untrusted.** It checks the terminator, the size cap and the record shape, bounds every value before it copies, indexes or draws it, and never uses a value as an address, an offset, a file name or a jump target. File names come only from fixed prefixes plus names matching `[0-9]{8}\.msg`.
- The ROM MUST NOT use reserved devices, host-specific features or process spawning (§5.10).
- **All inbound data on the host is untrusted**: network responses, files, Reticulum packets and announces, Signal K deltas, user imports. Validate against the port schema at the adapter boundary, cap sizes, reject or quarantine failures.
- Host-side JS MUST NOT use `eval`, `new Function` or dynamic `import()` with data-derived specifiers. URLs derived from data are validated with `new URL()` and restricted to expected schemes (normally `https:`).
- The ROM can read everything in its exchange root, so the host places only what the grants allow, and never secrets (§5.13).
- **Browser host shell:** the runner library sets a default Content-Security-Policy (A17); the origins a utility needs are declared in its README and added to `connect-src`.
- Secrets (identity keys, claim codes, tokens) are never logged and never persist in URLs. See §10.10.

### 7.11 Testing

- `node --test`. No network in tests; inject the clock.
- **Component tests** use the test utilities of the vendored NoFlo runtime.
- **Graph tests** load the graph JSON, substitute adapters with doubles from `test/doubles/`, send packets and assert outputs.
- **Schema tests** validate sample payloads against every port schema.
- **Mailbox conformance tests** run the `mailbox` adapter against `test/fixtures/mailboxes/`, in both directions: complete, truncated (no terminator), oversized, out-of-order and duplicate messages, invalid records, state ports keeping only the newest message, and counter seeding after a restart.
- **ROM build test:** re-assemble and compare with the committed `.rom` (§6.3).
- **ROM parsing tests** (SHOULD): the mailbox reader in `rom/lib/` is exercised by a small Uxntal test ROM, run under the Uxn command-line emulator against fixture directories.
- Screens are verified by hand against the testing checklist of the Uxn App Guidelines and §15. Anything beyond that is optional and kept out of the repo's dependencies.

### 7.12 States every view must handle

Every view defines **loading, empty, error, offline and stale** states. Connection status is always visible. Nothing blocks behind a spinner for mesh-length latency; show a pending state and let the person keep working.

### 7.13 `host-link`: the host-to-host boundary (tiers 2 and 3)

A device host graph reaches a companion through `host-link` (A31). The companion graph's **exported ports** are its component signature: in and out ports with JSON Schema references. The device host graph contains a `companion` node whose ports mirror them, so the rest of the graph neither knows nor cares whether the companion is on the same machine or across a mesh.

The `companion` node is a hand-written component in the runner library, with its ports taken from the companion graph's exported-port schemas (§6.4). A test compares its signature hash against the companion graph's (the protocol computes `sig_hash` for component signatures), so signature drift fails the test instead of surfacing at runtime.

- **State vs event ports (A12).** A *state* port is retained: the companion replays the latest value on subscribe and on reconnect. An *event* port is not replayed. The marker is an additive optional port field, `retain` (P3 in §13).
- **Requests.** A request packet carries an `id`; the answer arrives on a `response` outport echoing it. Over a mesh, answers may take minutes: the device graph publishes a pending state to the ROM and never blocks.
- **Connection status.** The `companion` node has a `status` outport describing the connectivity layer reached (§10.8). The host graph forwards it to the standard `status` port, and the ROM MUST show it.
- **Delivery.** At-most-once, companion authoritative. After a reconnect the device takes a fresh snapshot from retained ports. User actions that must survive a restart go through a persisted outbox with states `queued, sent, delivered, failed`, published on `outbox-state`.
- **Multiple peers.** One shared companion graph. Outports broadcast to all connected peers; each new peer gets its own snapshot.
- **Large payloads** travel by reference (Reticulum Resource), not inline (P5), and land in the device's `blobs/` for the ROM (§7.6).
- **Pending protocol work.** The behaviours above rely on additions to FBP Protocol 2 (P1 to P4 in §13). Keep all of this behind the `host-link` adapter so protocol changes do not ripple into utilities.

### 7.14 Cryptographic operations: Factotum (D20)

A ROM holds no key material and implements no cryptography. When it needs a signature, a verification, a sealed or unsealed message, or a capability check, it asks the host through **Factotum**: a synthetic filesystem served over the standard File device, in the style of Plan 9's factotum. The ROM never reaches Reticulum, so it cannot sign or encrypt for it itself; Factotum is how it takes part in the mesh without that.

This section is the complete usage reference for ROM authors. `factotum-spec.md` (A35) is the reference for people implementing a Factotum host and is not needed to write a ROM.

**Division of labour.**

| Need | Mechanism |
|---|---|
| Application data, commands, snapshots | Mailboxes (§7.6) |
| Signing, verifying, sealing, unsealing, capability attenuation and verification | Factotum |
| Network credentials (API keys, passwords, tokens) | Neither: they stay in host adapters (§10.10) |

**Mount point and discovery (A36).** The tree appears as `factotum/` inside the exchange root, and the ROM uses relative paths only. (The implementer's spec calls it `/sys/factotum`; Varvara confines the File device to the working directory, so that absolute path is not usable from a ROM.) The files are synthetic: the host serves them and nothing is written to disk. The ROM uses only standard File operations.

```
factotum/
├── ctl          read-only: the capabilities visible to this ROM, one ndb line each
├── clone        read-only: allocates a session and returns its id
├── 00/          a session
│   ├── ctl      write commands, read status
│   └── data     raw binary input and output
└── 01/ ...
```

Reading `factotum/ctl` returns zero or more lines such as:

```
proto=ed25519 role=sign user=<alias> scope=<scope>
proto=lxmf-paper role=seal user=<alias>
proto=dacar role=cap scope=<scope> expires=<unix-time>
```

An empty read means the ROM has no cryptographic capabilities. A failed read of `clone` or `ctl`, or a missing `factotum/` directory, means the host does not provide Factotum (O19). In both cases the ROM MUST hide or disable the features that need it. Gate a feature by scanning the listing for the bytes `proto=<proto> role=<role>`; take the `user` alias from the listing instead of hardcoding it.

**Sessions.** One operation uses one session. Every file is opened by writing its path to `File/name`, and `File/length` is set before each read or write.

1. **Allocate.** Read `factotum/clone`. It returns three bytes: two lowercase hex digits and a newline (`00\n`). If no slot is free it returns `err busy\n` (or zero bytes). A host may allow as few as four concurrent sessions per ROM.
2. **Start.** Write one line to `factotum/<id>/ctl`: `start proto=<p> role=<r> [key=value ...]\n`. Other commands: `reset\n` clears the buffers but keeps the negotiated parameters; `close\n` zeroizes the session and frees the slot.
3. **Check.** Read `factotum/<id>/ctl`. The first byte of the status tells the outcome (next table).
4. **Move data.** Write the input bytes to `factotum/<id>/data` with one or more writes. **Reading `data` finishes the operation** and returns the raw binary result. A read that returns zero bytes (`File/success` is `0000`) is end of data. Without an explicit result, a zero-length read also means the operation is finished or failed: read `ctl` to find out which.
5. **Check again.** Read `ctl` for the final status, then write `close\n`. The host reclaims all of a ROM's sessions when it ends or resets, but a ROM MUST NOT rely on that.

**Status lines.** Every status line ends with a newline and starts with a fixed byte, so the ROM branches on byte 0.

| Byte 0 | Meaning | Example |
|---|---|---|
| `o` (`0x6f`) | Ready or succeeded; optional `key=value` metadata follows | `ok` or `ok src=4d12... sig=valid` |
| `e` (`0x65`) | Failed or denied; a reason code follows | `err cap-denied` |
| `n` (`0x6e`) | Blocked, waiting for the person to confirm or unlock on the device | `needconfirm` |

Reason codes and what the ROM does with each:

| Answer | Meaning | ROM action |
|---|---|---|
| `needconfirm` | The person must approve in the host's privileged shell | Show a pending state ("confirm on the device"), poll `ctl` at the §7.6 rate, let the person cancel with `close`. Never draw a confirmation prompt of its own. |
| `err cap-denied` | Outside the ROM's effective authority | Mark the feature unavailable and say which capability is missing. Do not retry. |
| `err user-denied` | The person refused | Say so. No automatic retry. |
| `err bad-sig`, `err decrypt-failed` | The input is invalid or tampered with | Treat the data as untrusted and say so. Never treat it as valid. |
| `err unknown-dest` | Sealing target not known to the host | Tell the person the destination is unknown. |
| `err busy` (on `clone`) | No free session | Close sessions the ROM still holds, then retry later. |
| `err bad-proto`, `err bad-param`, `err bad-length`, `err state` | A bug in the ROM | Report on the `console` port and show a generic error. |

**Protocols.** Values in `<>` are filled in by the ROM; `[ ]` is optional. A ROM uses only the protocols it declares in its manifest (below).

*`ed25519`: signatures.*

| Role | `start` attributes | `data` in | `data` out | `ctl` after |
|---|---|---|---|---|
| `sign` | `proto=ed25519 role=sign user=<alias> [scope=<s>] [mode=digest\|stream] [cap=<token>]` | `mode=stream`: any number of bytes over one or more writes. `mode=digest`: exactly 32 bytes (a SHA-256 digest). | 64 bytes: the signature | `ok` or `err <reason>` |
| `verify` | `proto=ed25519 role=verify pub=<64-hex> [mode=digest\|stream]` | the 64-byte signature, then the digest (32 bytes) or the message bytes | none | `ok`, or `err bad-sig` |

Use `mode=stream` unless the ROM already holds a digest: the host hashes internally, so the ROM needs no SHA-256. Write stream data in chunks of at most 4096 bytes. The signing convention (a digest signed as the message) is not plain Ed25519 over the message, so signatures are only verifiable by Factotum-compatible verifiers until O21 is settled.

*`dacar`: capabilities.*

| Role | `start` attributes | `data` in | `data` out | `ctl` after |
|---|---|---|---|---|
| `attenuate` | `proto=dacar role=attenuate [cap=<parent>] [scope=<sub>] [expires=<unix>] [audience=<dest-hex>]` | optional extra caveat lines (ndb) | the narrower token, raw binary; read until zero bytes | `ok`, or `err cap-denied` |
| `verify` | `proto=dacar role=verify [scope=<required>]` | a raw binary token | none | `ok issuer=<hex> subject=<hex> scope=<s>`, or `err <reason>` |

A ROM may narrow its own authority with `attenuate` (for example, scope a signature to one record set) and can never widen it.

*`lxmf-paper`: sealed paper messages.*

| Role | `start` attributes | `data` in | `data` out | `ctl` after |
|---|---|---|---|---|
| `seal` | `proto=lxmf-paper role=seal dest=<32-hex> user=<alias> [format=uri\|raw]` | the canonical LXMF payload bytes | `lxm://...` ASCII (default) or the raw packet | `ok dest=<32-hex>`, or `err unknown-dest` |
| `unseal` | `proto=lxmf-paper role=unseal user=<alias>` | an `lxm://...` URI (whitespace trimmed) or raw packet bytes, auto-detected | the decrypted payload bytes | `ok src=<32-hex> sig=valid`, or `sig=unknown`, or `err bad-sig` / `err decrypt-failed` |

The canonical payload is a timestamp plus a MsgPack structure, which is heavy to build in Uxntal. A ROM that wants to send a message normally issues a command to the host graph and lets the graph compose and seal it. Use `seal` directly only when the ROM already holds the payload. Treat `sig=unknown` as unverified and label it that way (as `UNVERIFIED`, §10.6).

`kosync` exists in the implementer's spec and is not used in this profile: network credentials stay in host adapters, and the ROM never builds authenticated requests.

**Declaring what the ROM needs.** A signed release carries a manifest in ndb syntax. The `needs` line lists the most the ROM may ever ask for, as space-separated `proto:role` entries, each with an optional `?scope=`:

```
rom_sha256=<64 hex>
app=sailing-log
version=0.1.0
author=<64-hex Ed25519 public key>
needs=ed25519:sign?scope=sailing-log ed25519:verify
sig=<128-hex signature>
```

An LLM writing a utility produces the `needs` line, keeps it minimal, and records it in the README. The release tooling computes `rom_sha256` and `sig`. A ROM that asks for anything outside `needs` gets `err cap-denied`. (The manifest should cover the graphs and schemas too: O18.)

**Uxntal pattern.** A reusable routine in `rom/lib/factotum.tal`. Only the `start` line and the data steps change between protocols. This one signs 32 bytes with `mode=digest`. It has not been assembled or run; test it on a host before relying on it.

```
|a0 @File &vector $2 &success $2 &stat $2 &delete $1 &append $1 &name $2 &length $2 &read $2 &write $2

( Sign the 32 bytes at fx-digest. Returns 1 when fx-sig holds a signature, else 0. )
@fx-sign ( -- ok )
	( 1. allocate a session: two hex digits and a newline )
	;fx-clone .File/name DEO2
	#0003 .File/length DEO2
	;fx-sid .File/read DEO2
	.File/success DEI2 #0003 NEQ2 ,&fail JCN
	( 2. copy the two id digits into the ctl and data paths, after "factotum/" )
	;fx-sid LDA2 ;fx-ctl #0009 ADD2 STA2
	;fx-sid LDA2 ;fx-data #0009 ADD2 STA2
	( 3. start, then check status byte 0 is 'o' )
	;fx-ctl .File/name DEO2
	;fx-start/end ;fx-start SUB2 .File/length DEO2
	;fx-start .File/write DEO2
	#0040 .File/length DEO2
	;fx-status .File/read DEO2
	;fx-status LDA #6f NEQ ,&fail-close JCN
	( 4. digest in, signature out, on the same open data file )
	;fx-data .File/name DEO2
	#0020 .File/length DEO2
	;fx-digest .File/write DEO2
	#0040 .File/length DEO2
	;fx-sig .File/read DEO2
	.File/success DEI2 #0040 NEQ2 ,&fail-close JCN
	( 5. read the final status )
	;fx-ctl .File/name DEO2
	#0040 .File/length DEO2
	;fx-status .File/read DEO2
	;fx-status LDA #6f NEQ ,&fail-close JCN
	;fx-close-session JSR2
	#01 JMP2r
	&fail-close ;fx-close-session JSR2
	&fail #00 JMP2r

@fx-close-session ( -- )
	;fx-ctl .File/name DEO2
	;fx-close/end ;fx-close SUB2 .File/length DEO2
	;fx-close .File/write DEO2
	JMP2r

@fx-clone "factotum/clone $1
@fx-ctl "factotum/00/ctl $1
@fx-data "factotum/00/data $1
@fx-start "start 20 "proto=ed25519 20 "role=sign 20 "user=me 20 "mode=digest 0a &end
@fx-close "close 0a &end
@fx-sid $4
@fx-status $40
@fx-digest $20
@fx-sig $40
```

The sample hardcodes `user=me` for brevity; real ROMs take the alias from the `factotum/ctl` listing. The `needconfirm` case shows up as a status byte of `n` at step 3: a real ROM returns a "pending" result there, keeps the session open, and polls `ctl` again later instead of closing.

**ROM rules.**

- Close every session you open. Hold at most two at once (DEFAULT), and never keep one open across screens.
- Never block the UI for longer than one operation. A stream larger than a few kilobytes is the host graph's job, not the ROM's.
- Put results that travel on to a mailbox into a message field as a hex string, or into a blob (§7.6) when large. Sealed `lxm://` output is already ASCII.
- Treat everything read back (statuses, `src`, `issuer`, tokens) as untrusted text: check lengths before copying.
- Never log or display anything the ROM did not need. Keys never appear in Factotum's namespace, and the ROM stores no secrets of its own (§5.13).
- Features that depend on Factotum degrade visibly: hidden or disabled with a one-line reason, never a silent failure.

**Provenance and authority (A37), for the record.** The ROM cannot see or change this; it matters because it explains the answers above. When the launcher loads a ROM, the host builds a provenance record: the user's identity, the device's identity, the SHA-256 of the ROM, and the author's public key if the release is signed. The ROM's effective authority is the intersection of the user's policy, the author's `needs` and the device context; a ROM may narrow it and never widen it. An unsigned ROM is pinned to its hash and declares no needs, so every capability it requests needs confirmation or is denied. The prompt is drawn by the privileged shell (the launcher), never by the ROM, so a ROM cannot fake one. The same record decides which mailboxes the `mailbox` adapter provisions (§10.4): one record, two doors, files for data and Factotum for cryptography.

**Host rules (for implementers).** Details are in `factotum-spec.md`. No key material is ever visible in the ROM's namespace. Session ids are validated against `[0-9a-f]`. Buffers and ephemeral keys are zeroized on close, reset and ROM termination, and sessions are reclaimed when the ROM ends. On the device, hosts cap concurrent sessions (at least four) and the streaming buffer (at least 4096 bytes). Host-side graph components use the host's own crypto service under the same policy; Factotum is the ROM-facing face of it.

## 8 Tier selection

The UI is always a Uxn ROM. A **tier** answers one question: what does the utility need to reach, and therefore what host does it need?

| Tier | Needs | Shell | Example |
|---|---|---|---|
| 1 | Reticulum peers and local storage on the device. A browser host may also reach CORS-enabled public APIs. | The bundle on any host environment; the host graph runs beside the ROM; no companion. | rngit document editor/manager |
| 2 | Local files outside the exchange root, local network devices, internet services, OS access | A host graph on a machine with that reach, shipped as an npm package with a CLI runner. When the UI is on another device, this host is the **companion**, and the device keeps a thin host graph linked to it over Reticulum. | Monthly accounting statement updater (ledger-cli files on disk) |
| 3 | Signal K data, resources or plugin lifecycle | A Signal K plugin backend acting as the companion | Passage weather briefing (GRIBs, routes, other SK resources) |

Selection:

1. List what the utility must read, write and talk to (§3, step 2).
2. **The most demanding need wins:** any Signal K need means tier 3; otherwise any local files, devices or non-Reticulum network that the chosen host cannot reach itself means tier 2; otherwise tier 1.
3. **Prefer the lowest tier.** As much as possible works directly on the device; use a companion only for what needs reach the device lacks or heavy transformation of data.
4. State the tier and the reason in one line. Do not ask the person unless two tiers genuinely fit.

Edge cases:

- Needs only local persistence on one device: tier 1, no companion.
- Needs the internet from the T-Deck: tier 2; the companion fetches and converts, the device receives the result over Reticulum.
- On a desktop host, files and internet are reachable directly: the single host graph serves both the ROM and the local needs, so there is no separate companion.
- Needs Signal K *and* local files: tier 3; the plugin backend does the file access on the Signal K host.
- Cross-device sync with no server: tier 1 over Reticulum.

Because only adapters differ between host environments, a utility can move up a tier later without rewriting its ROM or its pure logic. Design for that: never leak tier-specific details into the ROM or its screens.

## 9 Deployment tiers

### 9.1 Tier 1: self-contained bundle

**Distribution and install (A33)**

- A bundle is data: the assembled ROM, the graph JSON and the schemas. Install means copying it into the host's app directory. Updating a bundle needs no reflash and no toolchain on the target.
- DEFAULT distribution: a signed rngit release over the Reticulum mesh, with registries as mirrors. The release signer is the identity that grants are keyed to (§10.4).

**Host environments**

- **Device (T-Deck Max):** the host graph runs on MicroFlo; Reticulum is the only network layer on board. Radios are live only when needed, except LoRa listening (A34), and queued sends are batched (§10.11). Idle must be cheap: no polling and no timers when nothing is happening. The Reticulum identity and the Dacar clock persist across restarts.
- **Desktop and mobile:** NoFlo on Node or Termux, with the portability profile of §9.2.
- **Browser:** NoFlo in the page beside a JS or WASM Uxn VM. The page is a shell provided by the runner library: service worker, install prompt, update flow, CSP and storage requests are its concern, not the utility's (O6). The VM's File device is backed by a virtual filesystem that the `mailbox` adapter also uses; `storage` is IndexedDB. Request persistent storage; browsers (Safari especially) may evict site data otherwise.

**Network rules (browser host)**

- Public APIs: only CORS-enabled ones. Do not invent a proxy. Declare every origin in the README and in the CSP `connect-src`.
- **No embedded secrets.** API keys are supplied by the person at runtime and stored via the `storage` adapter, never committed and never in graph JSON.
- Reticulum: the browser is a **leaf node only**, connecting through WebSocket interfaces. An HTTPS page needs `wss://` for non-loopback gateways (mixed-content rules).
- Do not connect to public hubs by default; interfaces are opt-in (§10.7).

### 9.2 Tier 2: npm package with a CLI runner

**Shape**

- An npm package with a `bin` entry. Running it starts the host graph, creates the exchange root in the data directory, and starts a native Varvara emulator on the ROM with the exchange root as its working directory.
- **Companion mode:** run headless (`--no-ui`). The companion serves its exported ports to device hosts over Reticulum through `host-link` (§7.13).
- Remote access works the way any peer does: another device's host graph connects to the companion over Reticulum. The tier 2 host graph therefore MUST NOT assume a ROM is attached.
- **Known limitation:** a browser UI reaching a tier 2 host over a LAN needs a `wss` endpoint in front of it. Out of scope for v1; a TLS-terminating proxy such as Caddy is a later extension.

**CLI behaviour (names: A14, amended)**

| Item | Rule |
|---|---|
| `--data-dir` | Override the data directory (default `~/.<utility-id>/`). The exchange root is `<data-dir>/exchange/`. |
| `--no-ui` | Do not launch an emulator (companion mode). |
| `--emulator` | Override the emulator command. |
| `--print-claim` | Print a fresh claim string when no owner exists. |
| `invite` | Issue a one-time code for an additional device (§10.5). |
| `--reset-owner` | Revoke owner grants and reopen the claim window. |

- **Launching the emulator** is a swappable component per platform (`uxn11`, `uxnemu`, and so on). This is an example of graph-level adaptation (D8): the runtime graph swaps one node.
- On first start with no owner, the CLI prints the claim string (§10.5).
- A browser shell, if one is served, accepts only its own origin (plus explicitly configured UI origins) and only expected `Host` values, to stop other web pages and DNS rebinding.
- **Loopback and file permissions are not authentication.** Other apps on the same machine can read an exchange root that is not private. Authorization between hosts is by Reticulum identity (§10.4); the exchange root is `0700`.

**Portability profile (tested targets: Linux, macOS, Termux on Android; iSH best effort; Windows untested; A7)**

- Node built-ins only; no native addons (Termux uses Bionic, where native modules often fail to build). Target the current Node LTS.
- Assume the OS may kill the host at any time. Write state atomically (write then rename); make startup idempotent; persist the Reticulum identity and the Dacar clock so a restart keeps the same address and monotonic timestamps.
- **Idle must be cheap.** No polling and no timers when nothing is happening; with no ROM open, the host does not watch the mailboxes.
- Handle `SIGINT` and `SIGTERM` by running the graph's shutdown sequence.
- **Secrets storage** (identity key, Dacar store) MUST be in a filesystem that honours modes: directory `0700`, files `0600`. On Termux that means the app-private home, never shared storage. User data paths (for example the ledger directory) stay freely configurable.
- Document user setup steps that the CLI cannot do: on Termux a wake lock, battery optimisation exemption, and Termux:Boot for autostart.
- Clock sanity: a host without a reliable clock (for example a Raspberry Pi with no RTC) must not issue Dacar operations with a wildly wrong time; see §10.4.

### 9.3 Tier 3: Signal K plugin backend

**Principles**

- **Signal K is the host for Signal K data** (D9). The plugin backend, running inside the Signal K server process, talks to Signal K natively: deltas over its WebSocket stream and REST. The ROM never talks to Signal K, and neither does a device. No browser-side Reticulum identity and no Dacar between a ROM and Signal K.
- The backend acts as the **companion**. The device host graph reaches it through `host-link` over Reticulum, using the shared Reticulum connection plugin (O3). All Signal K specifics live in the backend; the device sees ordinary exported ports (A32).
- **Signal K is the integration bus.** Anything a utility produces that other parties may want is published as Signal K data, not through a private protocol:
  - vessel data as paths with `meta` (units, display rules), via deltas;
  - routes, waypoints and other collections through the Resources API;
  - alerts through notifications;
  - anything else through documented REST routes under the plugin's own prefix.
- **Authentication is Signal K's own** (login and token handling) for anything that reaches Signal K. Handle `401`s gracefully and degrade sensibly when security is turned off. Access from a device is by Reticulum identity and Dacar grants (§10.4).

**Shape**

- An npm package published as a Signal K plugin (package keyword `signalk-node-server-plugin`, with a `signalk` block in `package.json` including `appIcon` and `displayName`). Verify the layout against the current Signal K documentation. The bundle's ROM and graphs ship in the package as data.
- The same repo conventions apply (§6). The backend runs inside the plugin process, is not remoted, and publishes its outputs back into Signal K.
- A webapp is optional and outside this profile.

**Consequence:** tier 3 companion graphs are not portable to tiers 1 and 2, because the data model is Signal K's. That is expected; these utilities exist because of Signal K data. Reusable across tiers: the ROM, its screens, pure-logic components and the schemas of ROM-facing ports.

### 9.4 What is the same everywhere

| | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| ROM, screens, formatting rules | same | same | same |
| ROM boundary | mailbox | mailbox | mailbox |
| Pure-logic components | same | same | same |
| Host graph | beside the ROM | beside the ROM, or the companion | the device host graph; the companion is the Signal K backend |
| Host-to-host link | none, or peers over Reticulum | `host-link` over Reticulum | `host-link` over Reticulum |
| Identity | on the host | on the host | host identity; Signal K auth for Signal K |
| Persistence | device filesystem, data dir or IndexedDB | data dir on the host | SK config and resources on the companion |
| Offline | works (data is local) | works for local data; companion data when reachable | works for local data; SK data when the companion is reachable |

## 10 Identity, access and Reticulum

Load this part when the utility uses Reticulum. In this profile Reticulum is a **host** concern: the ROM never touches it (D17). Hosts use it to reach each other: a device, a companion, other devices. A tier 3 backend reaches Reticulum through the shared connection plugin instead (§9.3).

Use Reticulum's own terms in code and UI: **identity, destination, aspect, announce, path, link, interface**. Do not invent friendlier synonyms.

### 10.1 Identity model

- A Reticulum identity is an X25519 + Ed25519 keypair. Its destination/identity hash is 16 bytes. Display hashes as lowercase hex in monospace with a copy action (to `.snarf`), always in full.
- **One identity per app install** (DEFAULT). Destinations already differ per app through aspects, but sharing one identity across apps lets an observer link them. Sharing is opt-in.
- **Announce deliberately.** Never announce merely because a ROM or page opened. Hosts announce at start and on a long, jittered interval; clients announce only on explicit action. Intervals are configurable within conservative bounds. Airtime is a shared, scarce resource.

### 10.2 Browser-hosted identity (browser host environment)

Applies only when the host graph runs in a browser. The person reaches it through the ROM's `identity` screen (§10.3); the cryptography stays in the host.

- **Generate locally** with a CSPRNG on first run, before any host contact. Never generate a browser identity server-side. Show the hash immediately.
- **Store in IndexedDB**, with extractable key material so backup is possible. Request persistent storage. **Never use `localStorage`** for key material.
- **Backup is mandatory.** Browsers can evict site data, and Reticulum has no recovery or revocation, so a lost identity is a lost address.
  - Prompt at creation (dismissible but visible) and show a persistent `NOT BACKED UP` indicator until done.
  - **Encrypted export** (A6): passphrase, PBKDF2-HMAC-SHA-256 with at least 600,000 iterations and a random 16-byte salt, AES-GCM with a random 96-bit nonce, all through WebCrypto. The file records format, version and KDF parameters.
  - **Raw export and import** in the reference 64-byte private key layout (X25519 ‖ Ed25519), so keys round-trip with the reference tools. Importers also accept the legacy 128-byte layout. Raw export is a file download behind a warning; never display the key as text by default.
  - Mark the backup done only after a verification step (a test decrypt or a re-entered passphrase).
- **Loss or compromise:** there is no rotation. The only recovery is a new identity, re-pairing, and telling contacts out of band. The UI says this plainly.

### 10.3 Host identity (all host environments)

- Generated at first start and stored in the **secrets directory** with modes `0700` (directory) and `0600` (files), in the reference-compatible format. On Termux this is the app-private home, never shared storage (§9.2). On the device, the secret lives in device storage that is not the exchange root (O15).
- The host's destination hash is its address and is the **Dacar root trust anchor**.
- **The ROM is the identity UI.** An `identity` screen shows the full hash (it fits 40 columns), the `NOT BACKED UP` indicator, and the backup actions. The host publishes an `identity` view port and accepts `identity-backup` commands (encrypted export, raw export, verification). The host does the cryptography; the key never enters the exchange root. Encrypted exports follow §10.2; a raw export goes to a location outside the exchange root that the screen names.
- Backup is a copy of the secrets directory; the README documents how.
- Shell access to the host is the ultimate authority: it can reopen the claim window or reset ownership (§10.5).

### 10.4 Access control with Dacar (D13)

The host is the **sole issuer** of grants by default. A ROM never signs Dacar operations and never sees the privacy salt, and neither does a browser-hosted shell.

- **Model:** a grant is a tuple of object, relation, grantee and issuer, signed by the issuer. The host's identity is the only root trust anchor.
- **Objects and relations.** Objects are `<utility-id>:<exported-port>`, with the wildcard `<utility-id>:*`. Relations are `read` (subscribe to an outport), `write` (send to an inport) and `admin` (reserved; authority to manage grants).
- **Owner** = `admin` on `<utility-id>:*` (the wildcard is required because `admin` does not cascade to child namespaces by default). The owner (a peer host, or the person through the host CLI) asks the host to grant or revoke; the host checks that the sender holds `admin`, then signs the operation itself. Only the host's key therefore needs to be recallable by verifiers.
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

Production hosts MUST NOT grant `GRAPH_EDIT`, `COMPONENT_WRITE`, `LIFECYCLE_CTRL` or `ADMIN` to peer identities. Today `LIFECYCLE_CTRL` gates packet input; that conflation is P1 in §13.

**The local ROM** is not a Reticulum peer and holds no grant of its own. Its authority comes from its provenance record (§7.14, A33, A37): the host exposes only the mailboxes for the ports its bundle declares, and only those the owner has allowed, and it serves only the Factotum protocols and scopes in the intersection of user policy, the signed manifest's `needs` and the device context. The `mailbox` adapter provisions `inbox/<port>` for `read` grants and `outbox/<port>` for `write` grants. The grantee for a signed ROM is its author, the identity that signed the release: you trust an author, not an app. An unsigned ROM is pinned to its hash and gets nothing without confirmation. A ROM sees nothing outside its exchange root (Varvara confines the File device) and nothing inside it that the grants do not cover.

### 10.5 Pairing, version 1 (A4, A5)

Pairing grants a peer host access to a host's exported ports, typically a device to a companion. Authority for the first pairing comes from shell access to the host. All v1 codes are issued by the host CLI. The person carries the code to the device and types it on its keyboard.

Owner claim (first run):

1. The device host has generated its identity (§10.3); the ROM's `identity` screen shows the hash and starts the backup flow.
2. The companion starts with no owner. Its CLI prints a **claim string**: the code and the companion's destination hash, for example `claim=<code> host=<destination-hash>`. No URL and no QR code (A5).
3. The person enters both on the ROM's pairing screen. The ROM sends them as one `pair` command (the one place a secret passes through a mailbox, §5.13); the host deletes the message on read. The device host **pins** the destination hash. A destination hash is derived from the host's public key, so pinning it authenticates the companion to the device and rules out a rogue host.
4. The device host opens a link to the companion and calls `identify()`. The code is then sent *inside the encrypted link*, bound to the identified identity.
5. The companion verifies the code, issues the owner grant, closes the claim window, and re-sends its capability advertisement with the new mask (P4 in §13).
6. The companion CLI prints the identity hash that claimed ownership. The person compares it with the hash the device shows. This is the cheap check that nobody got there first.

Additional devices: `invite` on the CLI issues a one-time code with a role (default `member`), entered the same way. Each device claims its own grant. UI-initiated invites and request/approve flows are deferred (O7); the intended design is an access request with a short fingerprint derived from both identity hashes, compared on both screens. A short fingerprint would also avoid typing a full destination hash (O16).

Code properties (MUST):

- At least 80 bits of entropy, shown in Crockford base32 in groups of four, case-insensitive on entry.
- Single use, short TTL (10 minutes by default), invalidated after five failed attempts.
- The host stores only a hash of the code and compares in constant time.
- Never logged, never embedded in served pages, never exposed through any HTTP route. The only delivery paths are the terminal and the person's typing.

Recovery: `--reset-owner` revokes owner grants and reopens the claim window. Shell access to the host is always sufficient to regain control; losing a device must not lock the person out.

Tier 1 with no companion: there is nothing to pair.

### 10.6 Host discovery (A13)

- Hosts announce under the stable `fbp.runtime` aspect. The announce app data is `[protocol_version, destination_hash, node_name]` (well under the 128-byte limit), serialized as defined in the FBP Protocol 2 AsyncAPI document (§14). `node_name` is the **utility id**; a host rejects an incompatible version from the first byte.
- The device host publishes the announces it hears on a `peers` view port, and the ROM shows them as a list. **Pinned hosts come first.** Unpinned hosts are labelled `UNVERIFIED`. Never auto-connect to an unpinned host.
- After link establishment with a verified identity, the companion sends its capability advertisement. Treat it as the in-link truth over any cached announce.

### 10.7 Interfaces and configuration

- **Interface entries** (name, type or URL, enabled flag, live status) are held by the host as exportable text and edited through the ROM's `interfaces` screen, over view and command ports. A browser host's entries are WebSocket interfaces; a tier 2 host serving its own browser shell has one same-origin entry by default.
- **No public hubs or third-party gateways by default.** Connecting to one is an explicit opt-in, with a note about privacy and airtime.
- **Radios are live only when needed**, except LoRa listening (A34). A utility that turns a radio on says so on its screen.
- An HTTPS page needs `wss://` for non-loopback gateways (mixed-content rules).
- **Server side** follows the standard Reticulum configuration conventions and prefers attaching to an existing shared instance rather than opening its own interfaces. Show the equivalent `rnsd` config snippet on a screen where the person must configure a gateway.
- Each interface entry states what it implies: leaf or transport, trusted local link or radio, and rough bandwidth class.

### 10.8 Connectivity status

"Socket open" tells the person almost nothing. The host computes the highest layer reached and publishes it on the standard `status` port. The ROM always shows it as a text label, with a cue that is not colour alone (a glyph or inversion; colour is secondary, Guidelines §5).

| Layer reached | Label |
|---|---|
| No transport | `[ OFFLINE ]` |
| Gateway connected, nothing heard | `[ GATEWAY ]` |
| Host announce heard (show age and hops) | `[ HEARD ]` |
| Path known | `[ PATH ]` |
| Link established, identified, capability advertisement received | `[ LINK ]` |
| Rejected, incompatible protocol version, or permission denied | `[ DENIED ]` |

- Distinguish "no path yet" from "peer unreachable", and show **last-heard age** per peer (the staleness equivalent for mesh peers).
- Interpret the limitation code in the capability advertisement: permission denied shows the pairing prompt; hardware constrained, link saturated and concurrency lock each get a plain-language message.
- Log connection events on the `log` screen, with `[ OK ]`/`[ WARN ]`/`[ FAIL ]` status brackets.

### 10.9 Behaviour on a slow, lossy mesh

- **Assume minutes, not milliseconds.** No blocking spinners, no request/response assumptions. Show message states `queued, sent, delivered, failed` and persist the outbox across reloads.
- No network polling. Updates are event-driven. The only polling is the ROM's cheap local mailbox poll (§7.6).
- **Size awareness:** show payload size before sending, warn above a single packet, and use links or resources for bulk transfers, with byte-level progress (P5 in §13).
- Timestamps from peers are claims; see §7.9.

### 10.10 Security rules

- Announce app data and every inbound payload are **untrusted**: validate length and shape against the schema, and never let data reach anything that interprets it.
- **Verify peers out of band.** Show the full hash, and support local contact names (trust on first use is the realistic model).
- **Never log keys or claim codes.** Redact them in the console and in any exported diagnostics.
- **Origin and Host checks** on any served browser shell, and identity-based authorization as the actual gate (§9.2).
- A ROM never holds a Reticulum or Dacar key (§10.4).
- Dev-profile capabilities exist only for an explicitly enabled dev identity on loopback.
- Cryptographic operations asked for by a ROM go through Factotum (§7.14) and its policy, never through a mailbox command.

### 10.11 Send policy and radio duty cycle (A38)

Radios cost power and airtime. The host, not the ROM, decides when queued work goes out, so a device can keep a radio off until there is enough to send. This section fixes only the hooks. The spool itself (format, flush policy, forwarding between hosts) belongs in a separate host-networking document (O23).

- **Spool.** Outbound items queue on the host in **durable storage**, not in the volatile exchange root (A26). The spool is a platform component whose thresholds are graph values, not mode flags: minimum queued bytes, maximum age of the oldest item, link availability, and an explicit `send-now` command from the ROM.
- **Radio power.** The `reticulum` adapter exposes a power-control capability (radio on, off, listen-only) that the spool drives. Listening policy follows A34.
- **Visibility.** `outbox-state` carries an optional `reason` for items that are waiting (for example `waiting: batch 3 of 10`, `waiting: no link`). The ROM shows it and offers "send now".
- **Provenance travels.** When Factotum signs or attenuates a Dacar token for a remote host, it embeds the provenance chain (user, device, author, ROM hash) in the caveats (Factotum spec §2.3), so the remote host can authorize by provenance.
- Keep the spool a thin layer over Reticulum's own store-and-forward (LXMF propagation) rather than a second transport.

## 11 FBP Protocol 2 utility profile (stub, A9)

Hosts use a small subset of FBP Protocol 2 over Reticulum to reach each other (`host-link`, §7.13). The ROM does not speak FBP; it speaks only the mailbox protocol of §7.6.

- **Used:** the announce, the `0x02` capability advertisement, `0x47` packet send and the `0x49`/`0x4A` stream commands into exported inports, `0x48` status, `0x17` rejections, and read-only component signatures and schemas (`0x20` to `0x24`, `0x28`, `0x29`) to learn exported ports and their schemas.
- **Not used and refused for peer identities in production:** graph CRDT sync and edits, component write and install, run control, breakpoints and process control, telemetry subscription.

The gaps below must be closed in the protocol for this profile to work as written (P1 to P6 in §13). Until they are: implement the `host-link` adapter against the target behaviour described in §7.13, keep every protocol detail behind the adapter, and report in the README under Assumptions that the utility relies on pending FBP Protocol 2 changes.

## 12 Decided (D1–D20)

Amended by this profile: D1 (primary device), D3 (assembling the ROM is an accepted build step), D4 (UI), D5 (the shell of each tier), D7 (no client graph), D9 (the ROM link), D10 (hosts), D11 (platform component set), D14 (aesthetic, touch targets, routing and console patterns; time formats, staleness and status text carry over). Where they conflict, D16 to D20 win.

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
| D16 | The UI is a Uxn/Varvara ROM written in Uxntal, following the Uxn/Varvara App Guidelines. A utility has no web UI. |
| D17 | Logic, I/O, networking and persistence live in NoFlo 2.x host graphs (MicroFlo on the T-Deck Max). The ROM holds presentation and UI state only. There is no client graph, and the ROM never touches Reticulum. |
| D18 | The ROM and the host graph exchange plain-text messages in Maildir-style mailboxes in the ROM's working directory (§7.6), following the storage rules of the Uxn App Guidelines. FBP over Reticulum is used between hosts only. |
| D19 | One bundle (ROM, graphs, schemas) runs unchanged on the T-Deck Max (MicroFlo), desktop and mobile (NoFlo plus a native emulator) and in a browser (NoFlo plus a JS or WASM VM). Graphs use one small audited platform component set, implemented at least twice. |
| D20 | Cryptographic operations for ROMs go through a Factotum-style synthetic File interface (§7.14), gated by the ROM's provenance and Dacar capabilities. A ROM holds no keys and implements no cryptography. |

## 13 Assumptions, protocol gaps, open questions

Assumptions made for v0.1 (confirm or override). A1 to A18 come from the original spec; amended or superseded ones say so. A19 and up are new in this profile.

| # | Assumption |
|---|---|
| A1 | *Superseded.* There are no mode flags and no `day`/`night` mode names: colours come from the Varvara `.theme` file (Guidelines §5), and a host-provided mode (e.g. SK) may be applied by the host replacing `.theme`. The visual style is the Guidelines' §5.1. |
| A2 | *Superseded.* No custom elements, so no `tac-` prefix. |
| A3 | Graphs are JSON files in `graphs/`, loaded at runtime. The ROM is data too. |
| A4 | *Amended.* v1 pairing uses one-time codes issued from the host CLI and typed on the device: first-run owner claim, plus `invite` for additional devices. UI-initiated invites and request/approve are deferred. |
| A5 | No QR codes in v1; pairing uses a typed code and destination hash. |
| A6 | *Amended.* Identity backup uses PBKDF2 + AES-GCM: WebCrypto in a browser host, Node crypto on NoFlo hosts. The device implementation is open (O15). |
| A7 | Termux is a tested target for tier 2; iSH is best effort. Node target is the current LTS. |
| A8 | Default licence is EUPL-1.2 with SPDX headers. |
| A9 | The FBP Protocol 2 utility profile appears as a stub that lists gaps P1 to P6. |
| A10 | *Superseded.* No Web Components. |
| A11 | Browser baseline applies to the browser host shell only: use only features that are Baseline; anything else must be a progressive enhancement. |
| A12 | State-vs-event port marker is an additive optional port field (`retain`). |
| A13 | The announce `node_name` is the utility id. |
| A14 | *Amended.* CLI flag names: `--data-dir`, `--no-ui`, `--emulator`, `invite`, `--reset-owner`, `--print-claim`. |
| A15 | "Local time" is the device clock unless a fixed offset is configured. Missing values display as `--`. |
| A16 | Each utility repo pins the spec version it follows in a `SPEC_VERSION` file, here `uxn-0.1`. |
| A17 | *Amended.* A default Content-Security-Policy ships with the browser host shell, from the runner library. |
| A18 | *Superseded.* No localhost port for the UI. |
| A19 | Graphs use only the platform component set. A utility-specific component is a recorded Deviation, lives in `src/components/` with an explicit registry, and restricts the bundle to NoFlo hosts. |
| A20 | ROMs target Varvara 80K and declare it in metadata field `56`. |
| A21 | Drifblim is the assembler. The `.tal` source and the assembled `.rom` are both committed, and a test checks that they match. |
| A22 | The exchange root is the ROM's working directory, with `inbox/<port>/`, `outbox/<port>/` and `blobs/`. Messages are `NNNNNNNN.msg` files. |
| A23 | Limits: a message is at most 2048 bytes, a mailbox holds at most 32 pending messages. |
| A24 | The ROM polls its inbox mailboxes at most once per second while a screen is visible, and immediately after a send or key press. A Console wake byte is optional. |
| A25 | Host-side writers deliver with write-to-`tmp/`-then-rename. ROM-side writers rely on the terminator. Readers always check the terminator. |
| A26 | On the T-Deck the exchange root lives on volatile storage; durable data goes through the `storage` adapter. |
| A27 | Every host graph exports the standard ports `status`, `console`, `prefs`, `prefs-set`, `outbox-state`, `export` and `import`. UI preferences live on the host, not in ROM files. |
| A28 | ROM-facing payloads are flat: strings, integers, booleans, lists (repeated keys) and tables (repeated keys with tab-separated columns). Display values arrive pre-formatted. Text is printable ASCII by default. |
| A29 | One ROM per exchange root. |
| A30 | The Uxn App Guidelines are loaded alongside this spec as `uxn-app-guidelines.md`. |
| A31 | The old `host-link` semantics (retained state ports, request ids, at-most-once delivery, blobs by reference) apply between hosts. |
| A32 | Tier 3 is a Signal K plugin backend acting as the companion; the ROM and the device never talk to Signal K. |
| A33 | *Amended by §7.14.* ROM authors are untrusted. Bundles are distributed as signed rngit releases. A ROM's authority is the intersection of user policy, the signed manifest's `needs` and the device context; the grantee for a signed ROM is the release signer, and an unsigned ROM is pinned to its hash and needs confirmation. |
| A34 | On the device, radios are live only when needed, except LoRa listening. |
| A35 | The Factotum spec (`factotum-spec.md`) is the implementer's reference. The usage side for ROM authors lives in §7.14, so ROM work does not need it loaded. |
| A36 | Factotum appears as `factotum/` inside the exchange root, not at `/sys/factotum`. A ROM tolerates its absence. |
| A37 | One provenance record (user, device, ROM hash, author) and the intersection rule decide both mailbox exposure and Factotum capabilities. The confirmation prompt is drawn by the privileged shell. |
| A38 | The spool hooks of §10.11 are in scope; the spool format and flush policy are not. |

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
| O1 | Runner library: name, exact component list, versioning. Now also covers the mailbox adapter, standard ports, emulator launchers and the browser shell. Needed before the template repo. |
| O2 | Adapter port contracts (mailbox, storage, files, clock, reticulum, host-link, signalk). Only named in v0.1; schemas not yet defined. |
| O3 | SK conventions: auth failure handling; how a plugin backend reaches the shared Reticulum connection plugin; how a device gets Signal K data through the companion (A32). |
| O4 | Relation-to-capability table for the utility profile, including what a local ROM's grants expose. Depends on P1. |
| O5 | Large-payload convention (Reticulum Resource references). Depends on P5. |
| O6 | Update flow and cache strategy of the browser host shell. |
| O7 | UI-initiated invites and request/approve pairing. Deferred by A4. |
| O8 | Shared ROM widgets and tiles, alarm module, maps and charts on a 320x240 screen. (The design system itself is the Uxn App Guidelines.) |
| O9 | Template repo skeleton and acceptance checklist beyond §15's. |
| O10 | Validate by building the three example utilities from the spec, as ROM plus graphs. After the template repo. |
| O11 | Characters and fonts: printable ASCII only, or UTF-8 with a font. How the host sanitizes display strings. |
| O12 | A standard way for a host to prompt an immediate poll (a Console byte, or something else), and whether 1 s is the right default poll rate on the device. |
| O13 | Whether a ROM can create directories at run time (Guidelines §9). Until then, the host creates them. |
| O14 | Flash wear and the volatile exchange root on the T-Deck: what survives power loss, and how the host restores mailboxes at boot. |
| O15 | Device identity storage and backup: where the secret lives on the T-Deck, the cost of the key derivation on its CPU, and where a raw export goes (never the exchange root). |
| O16 | Pairing on a keyboard device: typing a 32-character destination hash, or deriving a short fingerprint to compare instead. |
| O17 | Schema conventions for ROM-facing ports: declaring table columns, size caps and `retain`; whether the JSON-to-text mapping is generated or hand-written. |
| O18 | Bundle format: what a bundle manifest declares (ports, files read and written, networks used), how it is signed, and how grants reach the `mailbox` adapter. The Factotum manifest covers only `rom_sha256`, but a bundle also carries graphs that run with host authority, so the signature must cover them too. |
| O19 | Who serves `factotum/` on each host (firmware VM, native emulator launcher, browser VM), and whether a mailbox-based fallback is needed for hosts that cannot serve synthetic files. |
| O20 | Whether `policy.ndb` or the Dacar grants are the source of truth for a ROM's authority, and how the two stay consistent. |
| O21 | The Ed25519 signing convention in Factotum. It signs a SHA-256 digest as the message, so its signatures differ from plain Ed25519 over the message, which is what RNS and LXMF verify. Define it explicitly and add domain separation (scope in the signed bytes, or per-scope keys). |
| O22 | `kosync` returns the MD5 auth token in `ctl`, which contradicts zero secret exposure. Drop it for ROMs, or return only a per-request proof. Here the host's HTTP adapter holds the credential. |
| O23 | A host-networking document: spool format, flush policy, the radio power capability, and UUCP/NNCP-style forwarding between hosts. |
| O24 | Per-operation Dacar relations (`sign`, `decrypt`) and key aliases scoped per utility; the documented relations are `read`, `write` and `admin`. |

## 14 External references

| Reference | Version | Used for |
|---|---|---|
| Varvara specification (wiki.xxiivv.com/site/varvara.html) and application support standards (libraries.html) | 80K | The File device, Screen, Controller, metadata, themes, manifest and clipboard conventions (§6.2, §7.6) |
| Uxn/Varvara App Guidelines | pinned alongside this spec (A30) | Everything inside the ROM |
| Varvara Factotum & Multi-Principal Capability Specification | 1.0.0-draft (A35) | Cryptographic operations for ROMs, provenance and policy (§7.14) |
| Drifblim (Uxntal assembler) | pin the exact vendored version in `vendor/vendor.json` | Assembling the ROM (§6.3) |
| MicroFlo | pinned by the platform component set | Running host graphs on the T-Deck Max |
| FBP Protocol 2 SPEC and AsyncAPI document | 2.0.0-alpha.1 | Announce app-data serialization (§10.6), capability advertisement, packet and stream commands, component signature hashing (`sig_hash`, §7.13), the utility profile (§11) |
| Dacar SPEC | 1.0 | Grants, relations, privacy salt, hybrid logical clock, store layout (§10.4, §10.5) |
| reticulum-js | pin the exact vendored version in `vendor/vendor.json` (§6.6) | Browser and server Reticulum: identities, links, packets, resources (§7.5) |

The FBP, Dacar and reticulum-js entries are first-party packages: canonically distributed as signed rngit releases, with registries as mirrors (see `~/.pi/agent/context/package-installation.md`).

## 15 Acceptance checklist

Before reporting done, verify each item and say which, if any, you could not verify.

- [ ] `npm run check` (type check) passes with no `any` outside vendored-library boundaries.
- [ ] `npm test` passes; every graph has a test using adapter doubles, and the mailbox conformance tests pass in both directions.
- [ ] `rom/<utility-id>.rom` is exactly what the vendored assembler produces from `rom/*.tal`, and the `.rom.sym` file is present.
- [ ] The ROM's metadata is present (name, description, Varvara version field `56`) and registered as the first instruction at reset.
- [ ] The ROM uses only standard Varvara devices, no process spawning, and only fixed relative paths inside its exchange root.
- [ ] The ROM holds no key material and has no cryptographic code: signing, sealing and capability checks go through Factotum under the relative `factotum/` path, and the ROM handles `err`, `needconfirm` and the absence of Factotum, and closes every session it opens.
- [ ] The ROM passes the testing checklist of the Uxn App Guidelines: 320x240 and a larger size, keyboard only, no mouse, monochrome, with and without a `.theme` file.
- [ ] Every value the ROM shows comes from the latest snapshot; the ROM redraws only when something changed and polls no faster than §7.6 allows.
- [ ] Every view has loading, empty, error, offline and stale states, and connection status is always visible.
- [ ] Every exported port has a JSON Schema, a mailbox, and a row in the README's mailbox table; ROM-facing schemas stay within the restricted subset.
- [ ] The host validates every ROM-written message; the ROM bounds-checks and validates every inbound message.
- [ ] The graphs use only the platform component set (or the Deviation is recorded), with no mode flags and a test for each graph.
- [ ] `vendor/` has a manifest entry (name, version, SPDX licence, source, SHA-256) for every file group; all licences are EUPL-1.2-compatible.
- [ ] The README states the problem, the tier and why, how to run, the mailbox table, the key map, assumptions, deviations and platform requests.
- [ ] `SPEC_VERSION` is present and matches the spec used.
- [ ] No secret appears in logs, mailboxes, URLs, test fixtures or committed files.
