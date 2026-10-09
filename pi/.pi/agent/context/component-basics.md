# NoFlo Component Basics (NoFlo 2.x)

Components are the elementary building blocks of NoFlo programs. They are added to a graph via a node, and connected to each other via edges. When a graph is turned into a running program (a network), the components corresponding to each graph node get instantiated, and their ports connected based on edges defined in the graph.

This reference describes NoFlo 2.x. Everything is plain ESM with zero build step, on Node.js >= 22. There is no 1.x compatibility path in new code — do not write CommonJS components.

## Packaging and discovery

NoFlo 2.x core does not discover anything. Applications supply a component registry; on Node.js the registry comes from `@noflo/loader-node` (`createNodeModulesRegistry(baseDir)`), which discovers components via fbp-manifest. Library authors don't instantiate the registry, but the library layout must satisfy what it scans:

- `components/` for component files, `graphs/` for graph files (`.fbp`, `.json`, registered as pre-parsed subgraph components), `spec/` for fbp-spec suites associated to components by file basename.
- Components are `.js` files (ESM via the package's `"type": "module"`). `.mjs` is NOT discovered. Components are imported eagerly at discovery, so component modules must be side-effect free at import time — no server starts, no file writes, no timers.
- The generated `fbp.json` manifest cache is an application concern; never commit it to a library.

## Component metadata

A component's name is its file basename, namespaced by the package's library identifier: the npm package name minus any `@scope/` prefix and minus a leading `noflo-`. So `components/Bar.js` in package `foo` is `foo/Bar`, in `@acme/widgets` it is `widgets/Bar`, and `@noflo/noflo` itself uses bare names like `Repeat`. Component names should be verbs not nouns, so `DoSomething` instead of `SomethingDoer`.

In addition to name, components can have an `icon` and a textual `description`. Icons match a Font Awesome icon name (without any `fa-` or `fas-` prefix); the library-level default comes from the `noflo.icon` key in `package.json`. Keep that key.

## Port Declarations

Components define their interface with `inPorts` and `outPorts`. Every port must declare a specific data type (e.g., `string`, `boolean`, `object`, `int`, or `all`) to enforce boundaries. Marking ports as `required` tells which ports must at least be connected for the component to work.

- Firing inports trigger the component to execute when they receive data.
- Control ports (`control: true`) are used for passing configuration values and are non-firing. Configuration values are typically received once at startup via IIPs, not as part of the data stream. Reading from a control port doesn't "consume" the packet: the port buffers the latest stream (brackets kept; a newer incoming stream discards the previously buffered one), and `getStream()` reads a grouped configuration stream. Marking a control port `required` does NOT make the component wait for it at runtime — order IIPs/data correctly or handle absence explicitly. Give control ports a `default` where a sensible one exists, but since IIP-vs-data delivery timing within one activation is not guaranteed, guard reads with `hasData` and keep a local fallback.
- Addressable ports (ArrayPorts, `addressable: true`) accept multiple distinct connections. When processing data, the component reads from or sends to specific connection indexes. Typical use case: a routing component deciding to which sub-flow a packet should be sent.

## Information Packets (IPs) and Streams

Components may interact with the rest of the program only through packets. An Information Packet (IP) is not just raw data; it contains a type:

- `data`: standard data payloads.
- `openBracket` and `closeBracket`: used to group a sequence of related IPs together.

In NoFlo, a "stream" refers specifically to a sequence of packets bounded by these brackets. More complex firing patterns — like only activating when a suitable set of packets is available across several inports — are expressed with the `hasData` and `hasStream` methods to check whether ports contain the needed data.

## Component Lifecycle and Process API

When a component is instantiated, it is inert and doesn't do anything. Components fire (their `process` function is called) when they receive packets on firing inports. If a component reads packets (using `getData` or `getStream`) from the firing inports, this causes it to activate.

The process contract is: check preconditions with `has`/`hasData`, then activate and start processing with `get`/`getData`. Reading from a port while an activation is still waiting for more data is a footgun — that pending activation will never re-invoke (load never drains, `shutdown()` hangs). So check everything with `has` first; only once the firing pattern is confirmed, get the values and process to completion. Note that on control ports `has()` reports whether a data IP is present in the buffered stream; buffered brackets alone don't satisfy it.

The `process` function receives an `input` and an `output` object representing the execution context:

- The `input` object is used to check for and retrieve incoming packets.
- The `output` object provides an isolated context to send packets downstream with automatic bracket forwarding.

When a component is activated, it may `send` data packets to its outports. When it is ready with whatever operations the received packets triggered, it should deactivate by calling `done()` on the output context. For the common case of sending a packet and finishing, there is the `sendDone` shortcut.

A typical way to start a NoFlo network is to define and send some Initial Information Packets (IIPs) to various components to start the data flow. IIPs are also often used for configuration. The network is considered finished and will terminate when all components have deactivated and there are no in-flight packets.

Automatic bracket forwarding is enabled by components declaring their forwarding rules in the constructor (e.g., `forwardBrackets: { in: ['out', 'error'] }`, the default). In most cases brackets should be forwarded through the main inports and outports.

The process function fires on data IPs only — brackets never trigger it. Don't handle bracket types manually to forward groupings; let `forwardBrackets` do it. With multiple data outports, declare `forwardBrackets` explicitly listing every port that should carry the grouping, and set it to `{}` for components where grouping is meaningless (generators, sinks). Note the key footgun: forwarded brackets attach to actual sends, not to ports — an outport listed in `forwardBrackets` that receives no send during an activation stays completely silent (on an error path only the `error` port gets the grouping; data outports receive nothing, not even empty groups).

### Component example

```javascript
import { Component } from "@noflo/noflo";

export function getComponent() {
  const c = new Component({
    description: "A standard component example",
    inPorts: {
      in: { datatype: "string" },
    },
    outPorts: {
      out: { datatype: "string" },
      error: { datatype: "object" },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("in")) return;
    const data = input.getData("in");

    // Process and send
    output.sendDone({ out: data.toUpperCase() });
  });

  return c;
}
```

Components with multiple inports can check presence of data on them with a single call:

```javascript
if (!input.hasData("porta", "portb")) { return; }
```

The canonical library export is the named `getComponent` function returning a component instance.

### Async/Await Trap

A Promise returned from the `process` function is interpreted by NoFlo as an implicit `output.sendDone(resolvedValue)` (a rejection becomes `done(err)`). Therefore:

- Never declare the top-level `process()`, `relay()`, or `processMessage()` functions as `async`.
- Pick one style per component and never mix them (mixing corrupts the activation lifecycle):
  - Promise-pure: do the async work and return the Promise, resolving with the output map; never call `send`/`done` inside. The `output` parameter can then be omitted from the callback signature.
  - Explicit: call `output.send`/`output.sendDone`/`output.done` yourself and return nothing.
- If you need an inner async helper, call it fire-and-forget with `.catch((err) => output.done(err))` and do not return its Promise to the top-level API.

### Backpressure

2.x edges apply consumer-paced backpressure via high-water marks. `output.send`/`sendDone` return Promises that resolve when the receiving edges admitted the packet(s). Fire-and-forget is safe for sending a single packet per activation, but fan-out loops (splitting one input into many outputs) must await admission inside an inner async function:

```javascript
c.process((input, output) => {
  if (!input.hasData("in")) return;
  const data = input.getData("in");
  const sendAll = async () => {
    for (const part of data.split("\n")) {
      await output.send({ out: part }); // respects the edge high-water mark
    }
    output.done();
  };
  sendAll().catch((err) => output.done(err));
});
```

Do not return the inner Promise from `process`. Awaiting `output.send` (without `done`) is also the correct way to pace output inside long-running generator bodies.

### Addressable Ports

Regular NoFlo ports can have multiple edges connected to them. For inports, packets arriving via any of these edges are treated equal. Outports similarly send the packet via all of the connected edges.

ArrayPorts are read from and written to only a specific edge at a time. The edge connected to the port is identified by an index, so for example the IIP `'foo' -> IN[3] Bar` is sent to index `3` of the `in` port of node `Bar`.

With addressable inports, you check for packet availability with `hasData(['portname', index])` and read a packet with `getData(['portname', index])`. Note that `getData` consumes the packet from the port. The port method `attached()` provides a list of indexes that are connected:

```javascript
const indexesWithData = input
  .attached("in")
  .filter((idx) => input.hasData(["in", idx]));
```

Sending a packet to a particular index happens by setting the `index` in packet options:

```javascript
import { IP } from "@noflo/noflo";

output.sendDone({
  out: new IP("data", msg, { index: 1 }),
});
```

### Scoped packets

NoFlo supports isolating data flows using packet scopes. A component receiving packets with a scope will not see packets from another scope in the same processing run, effectively treating each scope as a parallel virtual instance of the network. A typical use case is isolating the data flow related to each received HTTP request:

```javascript
import { IP } from "@noflo/noflo";

server.on("request", (req, res) => {
  output.send({
    // Create isolated flow for each HTTP request
    out: new IP("data", { req, res }, { scope: uuid() }),
  });
});
```

Any packets sent during a scoped execution of the processing function inherit the scope. Downstream components generally don't need to do anything about the scope, it propagates automatically when receiving a scoped packet.

Components needing to mix unscoped data together with scoped data can set `scoped: false` on the inports where scopes should be ignored. Setting `scoped: false` on an outport strips scope from sent packets.

### Generator Components

While most components act on a single input to produce an output and deactivate, some components need to output multiple packets over time (polling services, stream readers, network servers, event listeners). These are Generator Components. Generator rules:

- Held resources (sockets, intervals, contexts) may be stored on the instance or in the `getComponent` closure; key resource maps by scope when the generator is per-scope (one server per scoped flow).
- Keep the activation context open (do not call `done`) for as long as the resource lives; deactivate it when the resource is released.
- Register a `tearDown` (it may be async) that releases every held resource — it runs at network shutdown, and a network that cannot shut down cleanly is a bug. For `node:http` servers, close keep-alive connections (`closeAllConnections()`) or the close callback never fires.
- Emit from event handlers with `component.outPorts.<port>.sendIP(new IP("data", data, { scope }))` rather than through a stale `output` handle from a past activation.
- Pace ongoing output with `await output.send(...)` to respect edge backpressure.

## Boundaries & Statelessness

**Triggering**: Components may not act on their own. They only trigger on packets received in their firing inports, and may only do operations once they have activated.

**Statelessness**: Components must be designed to be as stateless as possible. Do not store intermediate processing state in component instance variables, as this will cause race conditions in asynchronous graphs. Rely entirely on the incoming packets and bracket boundaries to provide the processing context. The only exception is generator resources (see Generator Components).

**Empty is valid**: never falsy-guard inputs (`if (!data) return;`) — that leaves the activation unresolved and swallows empty strings, which are valid data. Send what you received.

**Side effects**: In addition to sending and receiving packets, components may of course have side effects like making or serving network requests, writing to the filesystem, etc. These side effects should be clearly marked in the component description.

**Errors**: Declare an `error` outport (`datatype: "object"`) on every component that can fail — without one, a processing error is thrown into the network instead of routed. Routing conventions: `output.error(err)` followed by `output.done()` when nothing was sent yet, `output.done(err)` after a partial send; `output.sendDone(err)` also routes an Error (or Error array) to the error port. Wrap fallible operations (`JSON.parse`, `new RegExp`) and route the caught error — do not let exceptions escape the process function except through the error port convention. NoFlo Assembly components work with a message object where errors are added to an array instead.

## NoFlo Assembly (@noflo/assembly)

NoFlo Assembly is preferred for typical data processing pipelines, as it keeps error handling and graph structure more straightforward. Assembly components typically only have an `in` and an `out` port, apart from potential configuration control ports.

Assembly lives in the `@noflo/assembly` package (in-tree at `packages/assembly` in the noflo monorepo). It declares `@noflo/noflo` as a peer dependency, ESM only. NoFlo Assembly components must import from `@noflo/assembly` instead of `@noflo/noflo`:

```javascript
import { Component } from "@noflo/assembly";

class MyComponent extends Component {
  // ...
}

// Required export pattern for NoFlo to load the component
export function getComponent() {
  return new MyComponent();
}
```

Use named classes (not anonymous functions) for better stack traces when errors occur.

### Assembly Message Structure

Assembly components work with a standardized message object:

```javascript
{
  errors: Error[],  // Required array for accumulating processing errors
  // ... other arbitrary data fields
}
```

All components in the pipeline can add errors to the `msg.errors` array, and downstream components check `failed(msg)` before processing.

### Relay-Type Components (simple `in` → `out`)

Components with only `in` and `out` ports use the `relay()` method pattern:

```javascript
import { Component } from "@noflo/assembly";

class BuildFrame extends Component {
  constructor() {
    super({
      description: 'Builds car frame',
      validates: { id: 'num' },
      // Port definition is not necessary
    });
  }

  relay(msg, output) {
    msg.chassis = {
      id: msg.id,
      frame: 'Steel Frame',
    };
    output.sendDone(msg);
  }
}

export function getComponent() {
  return new BuildFrame();
}
```

For relay components:

- Port definition is optional (`in` and `out` auto-created)
- Validation is applied automatically before `relay()` is called
- If validation fails, the message is forwarded with errors without calling `relay()`

### Multi-Route Components

Components with multiple input or output ports implement a `processMessage()` method instead:

```javascript
import { Component } from "@noflo/assembly";

class MountEngine extends Component {
  constructor() {
    super({
      description: 'Mounts 3rd party engine on chassis',
      inPorts: {
        in: {
          datatype: 'object',
          description: 'Assembly',
        },
        engine: {
          datatype: 'string',
          description: 'Engine name',
          control: true, // for simplicity of example graph
        },
      },
      validates: { chassis: 'obj' },
    });
  }

  processMessage(input, output) {
    if (!input.hasData('in', 'engine')) { return; }

    const msg = input.getData('in');
    const engine = input.getData('engine');

    // Message validation is explicit for multi-route components
    if (!this.validate(msg)) {
      output.sendDone(msg);
      return;
    }

    msg.chassis.engine = engine;
    output.sendDone(msg);
  }
}

export function getComponent() {
  return new MountEngine();
}
```

The Component constructor automatically wires `processMessage()` to the component's process function. (The 1.x name for this hook was `handle`, renamed because it collided with the 2.x `Component.handle` property where the engine stores the processing function.)

### Validation Rules

The `validates` property in the constructor defines validation rules for message fields. Rules can be specified as:

Array syntax (checks presence with the `'ok'` validator):

```javascript
validates: ['id', 'user.name', 'body.id']
```

Object syntax (specific validators):

```javascript
validates: {
  id: 'num',
  'user.name': 'str',
  'user.age': '>0',
  body: 'obj',
  text: 'ok',
}
```

Built-in validators:

| Validator | Description |
|-----------|-------------|
| `'ok'` | Value is truthy |
| `'def'` | Value is defined (not undefined) |
| `'set'` | Value is set (not undefined or null) |
| `'num'` | Value is a number |
| `'str'` | Value is a string |
| `'obj'` | Value is an object (non-null) |
| `'func'` | Value is a function |
| `'>0'` | Value is a positive number |

How validation works — the `validate(msg, rules)` method:

1. Checks if the message already contains errors (returns `false` if so)
2. Applies validators to the specified fields (dotted paths dig into nested objects)
3. Adds errors to the `msg.errors` array if validation fails
4. Returns `false` if validation fails, `true` otherwise

For relay components, validation is automatic. For multi-route components, call it explicitly:

```javascript
if (!this.validate(msg)) {
  output.sendDone(msg);
  return;
}
// Normal processing
```

Custom rules can be passed as the second argument:

```javascript
if (!this.validate(msg, { id: 'num', 'site.url': 'ok' })) {
  output.sendDone(msg);
  return;
}
// Normal processing
```

### Error Handling

NoFlo Assembly uses a centralized error handling pattern where errors accumulate in the message object:

```javascript
import { fail, failed } from "@noflo/assembly";

// Add errors to message
fail(msg, new Error('Something went wrong'));

// Add multiple errors
fail(msg, [err1, err2, err3]);

// Check if message has errors
if (failed(msg)) {
  // Forward failed message without processing
  output.sendDone(msg);
  return;
}
```

When an error occurs, add it to the message and send it to all outputs expecting that message type:

```javascript
if (err) {
  output.sendDone(fail(msg, err));
  return;
}

// Multiple outputs - send failed message to all
fail(msg, err);
output.sendDone({
  main: msg,
  aux: msg,
});
return;
```

### Sending to Multiple Outports

Use `output.sendDone()` with an object mapping port names to messages:

```javascript
output.sendDone({
  main: msg,
  aux: msg,
});
```

All specified ports receive their respective messages, and the component deactivates.

### Concurrency Helpers

For parallel processing pipelines, use `fork()` and `merge()` to handle message isolation:

```javascript
import { fork, merge } from "@noflo/assembly";

// Fork message for parallel branches
const m1 = fork(msg);
const m2 = fork(msg);

// Send to parallel branches
output.sendDone({
  branch1: m1,
  branch2: m2,
});
```

Fork options:

```javascript
// Exclude certain properties from being copied
const m1 = fork(msg, ['excludeMe']);

// Clone certain properties (deep copy) instead of reference
const m2 = fork(msg, [], ['cloneMe']);
```

Merge forks back together:

```javascript
const b = input.getData('b');
const c = input.getData('c');

// Merge - first parameter takes priority
const car = merge(c, b);
output.sendDone(car);
```

The merge function combines messages, with the first message's properties taking priority over the second.

See the `@noflo/assembly` package itself (`packages/assembly` in the noflo monorepo) for documentation and the car-assembly example project.

## Coding standards

NoFlo 2.x is ES Modules only: packages use `"type": "module"`, `import`/`export` syntax, and explicit `.js` extensions in relative imports. There is no build step — no Babel, Webpack, or CoffeeScript. Target Node.js >= 22.

- Use JSDoc annotations for TypeScript type definitions (`npm run types` runs `tsc --checkJs` in the monorepo packages).
- Format with Biome; monorepo packages declare no separate linter.
- Test components with fbp-spec suites in `spec/` executed by `@noflo/fbp-spec-runner`, plus `node:test` for what the runner cannot express. Testing footguns:
  - fbp-spec `inputs` post in map order and data on a firing port triggers the component immediately — list control ports before the firing port, or the component fires with configuration missing.
  - The runner asserts data IPs only, and fan-out expectations evaluate against the last packet received on the port — intermediate fan-out packets, error-port values, scopes, and bracket structure belong in `node:test`.
  - An error sent to an error port that is not in `expect` vanishes and the case times out instead of failing fast — always assert the error port on failure paths (`path: $.message` + `contains`).
  - When driving sockets directly in `node:test`, attach all waiters/collectors before sending any IPs — an activation's packets arrive as one synchronous burst and can complete inside the post that triggers it. Clean up generators in a `finally` with `await c.shutdown()`; a leaked server keeps the process alive.
- Resolve dependencies on a strict ladder: web platform standards first (`fetch`, `URL`, `crypto.randomUUID`, `structuredClone`, WebCrypto digests), then `node:` builtins for what standards don't cover, third-party packages last. Prefer native methods over lodash/underscore, `fetch` over request libraries, Promises APIs (`node:fs/promises`) over callback style.
- Component modules must be side-effect free at import time.

The full normative authoring rules and the complete pitfall quick reference live in the noflo monorepo at `documents/component-library-migration.md`; loading architecture is documented in `documents/component-loading.md`.
