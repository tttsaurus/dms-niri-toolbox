# Dynamic Island Event Bridge Specs

This document describes the event and content architecture used by the Dynamic Island subsystem in `dms-niri-toolbox`.

```text
external event producers
    │
    ▼
IslandEventBridge
    │ eventReceived(event)
    ▼
IslandController
    ├── mode
    └── currentEvent
    │
    ▼
IslandContentRegistry
    │
    ▼
Loader
    │
    ▼
actual Content.qml
    ├── requestedWidth
    └── requestedHeight
    │
    ▼
IslandPresenter
    ├── validates requested dimensions
    ├── applies compact / peek / expanded policy
    └── produces targetWidth / targetHeight
    │
    ▼
DynamicIsland
    ├── geometry animation
    └── ShaderEffect / visual shell
    │
    ▼
IslandWindow
    ├── Wayland layer-shell surface
    ├── input mask
    └── DankBar positioning
```

> Note:<br>
> `IslandDaemon` is the composition root and the only daemon entrypoint specified in the `plugin.json`
> ```json
> "components": {
>   "widget": "./Toolbox.qml",
>   "daemon": "./island/IslandDaemon.qml"
> },
> ```

## Canonical Island Event

All producers should eventually produce the same logical event object:

```js
{
    type: "debugPeek",
    presentation: "peek",
    ttl: 1800,
    payload: {
        message: "hello",
        width: 280
    }
}
```

### `type`

Semantic content/event type. It is resolved by `IslandContentRegistry.qml`.

Examples:

```text
debugPeek
debugExpanded
volume
media
notification
battery
workspace
download
```

Backend code must not send QML paths. Use semantic types instead.

### `presentation`

Valid values:

```text
compact
peek
expanded
```

Current geometry semantics:

| Mode | Width | Height |
|---|---|---|
| `compact` | configured compact width | DankBar height |
| `peek` | _**content-requested** width_ | DankBar height |
| `expanded` | _**content-requested** width_ | _**content-requested height**_ |

If omitted, the controller defaults to `peek`. Unknown values fall back to `peek`.

`type` and `presentation` are intentionally independent.

### `ttl`

Optional lifetime in milliseconds.

```js
ttl: 1800
```

A positive finite TTL starts the controller timer. When it expires, the controller calls `clear()` and returns to compact mode. A newly pushed event cancels the previous TTL timer.

Not having a `ttl` means no expiry.

### `payload`

Arbitrary content-specific data. The bridge and controller do not interpret payload fields.

Feel free to use and interpret the `payload` inside the actual content QML implementations.

For example, you can put the requested `width`/`height` inside the `payload` of an event, and the whole event will be injected to the content QML implementations.

## `IslandEventBridge`

The bridge is the boundary between external producers and Island state.

Public output:

```qml
signal eventReceived(var event)
signal clearRequested()
```

The daemon wires these signals into the controller:

```qml
onEventReceived: event => islandController.push(event)
onClearRequested: islandController.clear()
```

The bridge does not own the controller.

### Direct ingress

The bridge exposes:

```qml
function accept(event) {
    if (event)
        root.eventReceived(event)
}
```

Use this for QML or future backend adapters.

### PluginService global-var ingress

The bridge watches:

```text
pluginId = toolbox
global var = islandEvent
```

The global var may contain either a direct event:

```js
{
    type: "debugPeek",
    presentation: "peek"
}
```

or an envelope:

```js
{
    token: "producer-specific-event-id",
    event: {
        type: "debugPeek",
        presentation: "peek"
    }
}
```

### `token`

`PluginService.getGlobalVar()` is retained state, not a true event queue.

`token` gives an event instance identity so the bridge can distinguish if it received a duplicate event.

The bridge remembers the most recently consumed token and ignores duplicates.

`token` is optional. It is mainly useful for the retained global-var transport. Direct function calls, signals, and IPC calls already have event semantics and do not need it.

## Permanent Bash Debug Channel

The bridge owns a permanent `IpcHandler` target:

```text
toolboxIslandDebug
```

This channel is intentionally restricted to debug content and should remain available for rendering, animation, sizing, and state-machine testing without a real backend.

Examples:

```bash
dms ipc call toolboxIslandDebug peek "hello"
```

```bash
dms ipc call toolboxIslandDebug peekSized "wide peek" 360 3000
```

```bash
dms ipc call toolboxIslandDebug expand "expanded placeholder"
```

```bash
dms ipc call toolboxIslandDebug expandSized "custom size" 640 320
```

```bash
dms ipc call toolboxIslandDebug clear
```

Raw event injection:

```bash
dms ipc call toolboxIslandDebug pushJson '{"type":"debugExpanded","presentation":"expanded","payload":{"message":"raw event","width":700,"height":380}}'
```

## `IslandController`

The controller owns logical Island state.

Public state:

```qml
readonly property string mode
readonly property var currentEvent
```

External code should call:

```qml
controller.push(event)
controller.clear()
```

### `push(event)`

`push()`:

1. rejects null
2. shallow-clones the event
3. validates `presentation`
4. updates `mode`
5. replaces `currentEvent`
6. stops the previous TTL timer
7. starts a new TTL timer when requested

The clone is shallow, so payload objects are not deep-copied. Treat the entire event tree as immutable after publication.

### `clear()`

`clear()` stops the timeout timer, clears `currentEvent`, and returns `mode` to `compact`.

### Future controller features

Put event arbitration in `IslandController`. Examples:

```text
priority
preemption
queueing
dedupe/coalescing
sticky events
resume previous event
```

Do not put these policies in `DynamicIsland` or content files.

## `IslandContentRegistry`

The registry maps semantic event types to concrete content QML.

For exmaple (a subset of the current implementation):

```text
null / unknown  -> IdleContent.qml
debugPeek       -> DebugPeekContent.qml
debugExpanded   -> DebugExpandedContent.qml
```

## Island Content Contract

Every Island content currently follows this implicit interface:

```qml
property var eventData: null
property var controller: null

readonly property real requestedWidth: ...
readonly property real requestedHeight: ...
```

### Inputs

`eventData` is the current event object.

`controller` allows content interaction such as:

```qml
controller.clear()
```

or:

```qml
controller.push({
    type: "debugExpanded",
    presentation: "expanded",
    payload: { ... }
})
```

### Outputs

`requestedWidth` and `requestedHeight` are geometry requests.

Content must not resize the Island shell directly.

## Content-owned Expanded Size

Requested expanded size is deliberately owned by the concrete content implementation.

Example (this is how you utilize `payload`):

```qml
readonly property real requestedWidth:
    requestedDimension(
        eventData?.payload?.width,
        520
    )

readonly property real requestedHeight:
    requestedDimension(
        eventData?.payload?.height,
        260
    )
```

Ownership:

```text
Content
    requests geometry
        ↓
Presenter
    validates / clamps
        ↓
DynamicIsland
    animates to accepted geometry
```

> Note: 
> `DynamicIsland` is not aware of any implementation details.

## `IslandPresenter`

The Presenter is the policy/lowering layer between application state and the visual shell.

It owns:

```text
which content is loaded
which dimensions are accepted
how mode affects geometry
```

### Dynamic content loading

The Presenter asks the registry for a source and loads it with `Loader`.

After creation it injects:

```text
eventData
controller
```

using dynamic `Binding` objects because `contentLoader.item` does not exist until the Loader has instantiated the content.

### Dimension validation

Content requests pass through `saneDimension()`.

The Presenter performs safe checks and clamps via `saneDimension()`.

### Geometry rules

Final width:

```text
compact  -> compactWidth
peek     -> saneDimension(requestedWidth)
expanded -> saneDimension(requestedWidth)
```

Final height:

```text
compact  -> compactHeight
peek     -> compactHeight
expanded -> saneDimension(requestedHeight)
```

## `DynamicIsland`

`DynamicIsland` is the dumb visual shell.

Public input (it receives the final `width`/`height` from the Presenter):

```qml
required property real targetWidth
required property real targetHeight
```

It must not know about event types, TTL, debug, bash etc.

Current responsibilities:

```text
geometry animation
ShaderEffect
content slot
fallback visual
```

Future responsibilities may include mostly visual effects.

## Shader Contract

After shader changes:

```bash
./dev_scripts/build_shaders.sh 
```

Shader work should stay in:

```text
island/shaders/*
island/DynamicIsland.qml
```

and should not require event/content changes.

## `IslandWindow`

`IslandWindow` is the Wayland/layer-shell boundary. It owns the Presenter.

The outer surface remains stable while the inner Island changes geometry.

## Extension Guide

### Add a new content type

Example: `volume`.

1. Create `island/content/VolumeContent.qml`.
2. Follow the content contract:

   ```qml
   Item {
       property var eventData: null
       property var controller: null

       readonly property real requestedWidth: 260
       readonly property real requestedHeight: 120
   }
   ```

3. Register `"volume"` in `island/core/IslandContentRegistry.qml`.
4. Push semantic events such as:

   ```js
   {
       type: "volume",
       presentation: "peek",
       ttl: 1500,
       payload: {
           volume: 0.75,
           muted: false
       }
   }
   ```

### Add a new producer

Convert producer output into the canonical event object and feed it to:

```qml
bridge.accept(event)
```

or another adapter that emits `eventReceived(event)`.

### Add another transport

For DBus, sockets, filesystem watchers, Niri IPC-derived events, audio providers, or notification providers, add/extend an adapter at the bridge boundary. The final output should be:

```qml
root.eventReceived(event)
```

### Change content transition behavior

For crossfade, dual-loader transitions, delayed reveal, or content morphing, edit:

```text
island/view/IslandPresenter.qml
```
