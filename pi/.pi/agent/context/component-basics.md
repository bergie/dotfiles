# NoFlo Component Basics

*Components* are the elementary building blocks of NoFlo programs. They are added to a graph via a *node*, and connected to each other via *edges*. When a graph is turned into a running program (a *network*), the components corresponding to each graph node gets instantiated, and their ports connected based on edges defined in the graph.

## Component metadata

Components are identified by their name, which derives from the package name and their filename. Component stored into `components/Bar.js` in package named `foo` would be known as `foo/Bar`. Component names should be verbs not nouns, so `DoSomething` instead of `SomethingDoer`.

In addition to name, components can have an `icon` and a textual `description`. These are used to give context to how the component works. Icon should match a Font Awesome icon name (without any `fa-` or `fas-` prefix).

## Port Declarations

Components define their interface using `inPorts` and `outPorts`. Every port must declare a specific data type (e.g., `string`, `boolean`, `object`, `int`, or `all`) to enforce boundaries. Marking ports as `required` tells which ports must at least be connected for the component to work.

* *Firing inports* trigger the component to execute when they receive data.
* *Control ports* are used for passing configuration values to the component and are non-firing. Configuration values are typically received once at startup via IIPs, not as part of the data stream. Reading from control port doesn't "consume" the packet. Control ports may provide a `default` value.
* *Addressable ports (ArrayPorts)* are configured by setting `addressable: true` in the port definition. This allows a single port to accept multiple distinct connections. When processing data, the component can read from or send data to specific connection indexes (addresses). Typical use case is a routing component that decides to which sub-flow a particular packet should be sent.

## Information Packets (IPs) and Streams

Components may interact with the rest of the program only through packets. An Information Packet (IP) is not just raw data; it contains a type:

* `data`: Standard data payloads.
* `openBracket` and `closeBracket`: Used to group a sequence of related IPs together.

In NoFlo, a "stream" refers specifically to a sequence of packets bounded by these brackets. More complex *firing patterns* like only activating when a suitable set of packets is available in a set of different inports are possible using the `hasData` and `hasStream` methods to check whether ports contain the needed data.

## Component Lifecycle and Process API

When component is instantiated, it is inert and doesn't do anything. Components fire (and their `process` function is called) when they receive packets on *firing inports*. If a component reads packets (using `getData` or `getStream`) from the firing inports, this causes it to activate.

The `process` function receives an `input` and an `output` object representing the execution context:

* The `input` object is used to check for and retrieve incoming packets.
* The `output` object provides an isolated context to send packets downstream and handle automatic bracket forwarding.

When component is activated, it may `send` data packets to its outports. When it is ready with whatever operations the received packets triggered, it should deactivate by calling `done()` on the output context. For simple cases where activation causes a single packet to be sent, there is the `sendDone` shortcut, which is the same as calling `send` and `done`.

A typical way to start a NoFlo network (running program) is to define and send some *Initial Information Packets* (IIPs) to various components to start the data flow. IIPs are also often used for configuration. The NoFlo network is considered finished and will terminate when all components have deactivated and there are no in-flight packets.

Automatic bracket forwarding is enabled by components declaring their forwarding rules in the constructor (e.g., `forwardBrackets: { in: ['out', 'error'] }`). In most cases brackets _should be_ forwarded through the main inports and outports.

### Component example

```javascript
const noflo = require('noflo');

exports.getComponent = () => {
  const c = new noflo.Component();
  c.description = 'A standard component example';
  c.inPorts.add('in', { datatype: 'string' });
  c.outPorts.add('out', { datatype: 'string' });
  c.outPorts.add('error', { datatype: 'object' });

  c.process((input, output) => {
    if (!input.hasData('in')) return;
    const data = input.getData('in');

    // Process and send
    output.sendDone({ out: data.toUpperCase() });
  });

  return c;
};
```

Note: components with multiple inports can check presence of data on them with a single call:

```javascript
if (!input.hasData("porta", "portb")) { return; }
```

### Async/Await Trap

Do not declare the top-level `process()`, `relay()`, or `handle()` functions as `async`. NoFlo intercepts returned Promises and treats their resolution as an implicit `sendDone()`. Mixing an async signature with explicit `output.sendDone()` calls will cause lifecycle errors. If you must use async/await, wrap the logic inside a self-executing async function or a separate helper method, and do not return its Promise to the top-level NoFlo API.

### Addressable Ports

Regular NoFlo ports can have multiple edges connected to them. For inports, packets arriving via any of these edges is treated equal. Outports similarly send the packet via all of the connected edges.

ArrayPorts are read from and write to only a specific edge at a time. The edge connected to the port is identified by an _index_, so for example IIP `'foo' -> IN[3] Bar` would be sent to index `3` of the `in` port of node `Bar`.

With addressable inports, you check for packet availability with `hasData(['portname', index])` and read a packet with `getData(['portname', index])`. Note that `getData` consumes the packet from the port.
The port method `attached()` provides a list of indexes that are connected:

```javascript
const indexesWithData = input
  .attached("in")
  .filter((idx) => input.hasData(["in", idx]));
```

Sending a packet to a particular index happens by setting the `index` in packet options:

```javascript
output.sendDone({
  out: new noflo.IP("data", msg, {
    index: 1,
  })
});
```

### Scoped packets

NoFlo supports isolating data flows using _packet scopes_. A component receiving packets with a scope will not see packets from another scope in the same processing run, effectively treating each scope as a parallel virtual instance of the network. A typical use case would be isolating the data flow related to each received HTTP request or message:

```javascript
server.on("request", (req, res) => {
  output.send({
    // Create isolated flow for each HTTP request
    out: new noflo.IP("data", {
      req,
      res,
    }, {
      scope: uuid(),
    }),
  });
});
```

Any packets sent during a scoped execution of the processing function will inherit the scope. Downstream components generally don't need to do anything about the scope, it will propagate automatically when receiving a scoped packet.

Components needing to mix unscoped data together with scoped data can do so by setting `scoped: false` on the inports where scopes are to be ignored. Setting `scoped: false` on an outport strips scope from sent packets.

### Generator Components

While most components act on a single input to produce an output and deactivate, some components need to output multiple packets over time (such as polling services, stream readers, network servers, or event listeners). These are known as Generator Components. Generators manage their own lifecycle and state over longer periods. For advanced implementations involving streams, generators, and asynchronous iterations, refer to the official NoFlo Process API documentation. `noflo-core/RunInterval` is a good example of a generator.

## Boundaries & Statelessness

**Triggering**: Components may not act on their own. They only trigger on packets received in their firing inports, and may only do operations once they have activated.

**Statelessness:** Components must be designed to be as stateless as possible. Do not store intermediate processing state in component instance variables, as this will cause race conditions in asynchronous graphs. Rely entirely on the incoming packets and bracket boundaries to provide the processing context.

**Side effects**: In addition to sending and receiving packets, components may of course have side effects like making or serving network requests, writing to the filesystem, etc. These side effects should be clearly marked in the component description.

**Errors**: Regular NoFlo components send any processing errors to an `error` outport. *NoFlo Assembly* components work with a message object where they add the errors to an array.

## NoFlo Assembly

NoFlo Assembly is preferred for typical data processing pipelines, as it keeps error handling and graph structure more straightforward. NoFlo Assembly components typically only have an `in` and an `out` port, apart from potential configuration *control ports*.

### Component Inheritance

NoFlo Assembly components must import from `noflo-assembly` instead of `noflo`:

```javascript
const { Component } = require('noflo-assembly');

class MyComponent extends Component {
  // ...
}

// Required export pattern for NoFlo to load the component
exports.getComponent = () => new MyComponent();
```

**Important:** Use named classes (not anonymous functions) for better stack traces when errors occur.

### Assembly Message Structure

Assembly components work with a standardized message object:

```javascript
{
  errors: Error[],  // Required array for accumulating processing errors
  // ... other arbitrary data fields
}
```

All components in the pipeline can add errors to `msg.errors` array, and downstream components check `failed(msg)` before processing.

### Relay-Type Components (Simple `in` → `out`)

Components with only `in` and `out` ports can use the simplified `relay()` method pattern:

```javascript
const { Component } = require('noflo-assembly');

class BuildFrame extends Component {
  constructor() {
    super({
      description: 'Builds car frame',
      validates: { id: 'num' },
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

exports.getComponent = () => new BuildFrame();
```

For relay components:
- Port definition is optional (`in` and `out` auto-created)
- Validation is applied automatically before `relay()` is called
- If validation fails, the message is forwarded with errors without calling `relay()`

### Multi-Route Components

Components with multiple input or output ports should use the `handle()` method instead of `process()`:

```javascript
const { Component, merge, fail } = require('noflo-assembly');

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
          control: true,
        },
      },
      validates: { chassis: 'obj' },
    });
  }

  handle(input, output) {
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

exports.getComponent = () => new MountEngine();
```

Note: The Component constructor automatically wires `handle()` to the component's process function.

### Validation Rules

The `validates` property in the constructor defines validation rules for message fields. Rules can be specified as:

**Array syntax** (checks presence with `'ok'` validator):
```javascript
validates: ['id', 'user.name', 'body.id']
```

**Object syntax** (specific validators):
```javascript
validates: {
  id: 'num',
  'user.name': 'str',
  'user.age': '>0',
  body: 'obj',
  text: 'ok',
}
```

**Built-in validators:**
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

**How validation works:**
The `validate(msg, rules)` method:
1. Checks if the message already contains errors (returns `false` if so)
2. Applies validators to the specified fields
3. Adds errors to `msg.errors` array if validation fails
4. Returns `false` if validation fails, `true` otherwise

For relay components, validation is automatic. For multi-route components, call explicitly:

```javascript
if (!this.validate(msg)) {
  output.sendDone(msg);
  return;
}
// Normal processing
```

Custom validation rules can be passed as second argument:

```javascript
if (!this.validate(msg1, { id: 'num', 'site.url': 'ok' })) {
  output.sendDone(msg1);
  return;
}
// Normal processing
```

### Error Handling

NoFlo Assembly uses a centralized error handling pattern where errors accumulate in the message object:

```javascript
const { fail, failed } = require('noflo-assembly');

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

When an error occurs, add it to the message and send to all outputs expecting that message type:

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
  aux: msg
});
```

All specified ports receive their respective messages, and the component deactivates.

### Concurrency Helpers

For parallel processing pipelines, use `fork()` and `merge()` to handle message isolation:

```javascript
const { fork, merge } = require('noflo-assembly');

// Fork message for parallel branches
const m1 = fork(msg);
const m2 = fork(msg);

// Send to parallel branches
output.sendDone({
  branch1: m1,
  branch2: m2,
});
```

**Fork options:**
```javascript
// Exclude certain properties from being copied
const m1 = fork(msg, ['excludeMe']);

// Clone certain properties (deep copy) instead of reference
const m2 = fork(msg, [], ['cloneMe']);
```

**Merge forks back together:**
```javascript
const b = input.getData('b');
const c = input.getData('c');

// Merge - first parameter takes priority
const car = merge(c, b);

// If both have same key, c's value is preserved
output.sendDone(car);
```

The merge function combines messages, with the first message's properties taking priority over the second.

See noflo-assembly documentation and examples in the package itself for more details.

## Coding standards

With NoFlo 1.x we use CommonJS. Eventually this will change to ES Modules, but not yet.

It is a good idea to utilize JsDocs for TypeScript type definitions.
