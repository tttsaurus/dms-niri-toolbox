# Dynamic Island Event Bridge Specs

This document specifies the Dynamic Island event, scene-content, geometry, reservation, split, animation, and interaction contracts used by `dms-niri-toolbox`.

## Architecture

```text
external / local event producers
        │
        ▼
IslandEventBridge
        │ eventReceived(event)
        ▼
IslandController
        ├── mode
        ├── currentEvent
        ├── TTL
        └── requestPresentation() preserves the current event + TTL
        │
        ▼
IslandContentRegistry
        ├── sceneSourceFor(mode, event)
        │       └── IdleContent / PeekContent / ExpandedContent
        └── notificationSourceFor(event)
                └── JavaVersionSwitchNotification / future payload components
        │
        ▼
scene template Content.qml
        ├── loads payload components with Loader
        ├── requests geometry / reservation
        ├── optionally requests split
        ├── optionally requests visual change animation
        └── optionally requests another presentation/event/clear
        │
        ▼
IslandPresenter
        ├── validates and clamps geometry
        ├── applies compact / peek / expanded policy
        ├── lowers optional content capabilities
        └── produces barReservationWidth
        │                    │
        ▼                    │ reverse policy result only
DynamicIsland                ▼
        │               IslandWindow.reservationWidth
        │                    │
        │                    ▼
        │               IslandDaemon (composition root)
        │                    │ publish per-screen global var
        │                    ▼
        │               IslandBarReservation
        │                    │
        │                    ▼
        │               Dank Bar center spacer model
        ▼
shader / visual shell
```

`IslandDaemon` is the composition root and is the only layer allowed to bridge the island presentation policy back into `PluginService`. Scene templates and payload components must not know about `PluginService`, Dank Bar, or screen-global reservation storage.

## Canonical Island Event

All producers should publish the same logical event envelope:

```qml
{
    type: "javaVersionSwitch",
    presentation: "compact",
    ttl: 3200,
    payload: {
        label: "Zulu 21",
        javaPath: "/path/to/java/home"
    }
}
```

### `type`

Semantic event/content type. It is resolved by `IslandContentRegistry.qml`. Producers must not send QML paths.

Examples include:

```text
javaVersionSwitch
notification
volume
media
battery
workspace
download
debugPeek
debugExpanded
```

### `presentation`

Valid values:

```text
compact
peek
expanded
```

If omitted, `IslandController.push()` defaults to `peek`. Unknown values fall back to `peek`.

`type` and `presentation` are independent. A semantic event may begin in compact and later promote the *same event* to peek or expanded.

### Geometry semantics

| Mode | Width | Height | Dank Bar reservation |
| --- | --- | --- | --- |
| `compact` | content-requested, clamped to `[initialIdleWidth, compactMaximumWidth]` | Dank Bar height | follows accepted compact width/request |
| `peek` | content-requested, clamped to the window maximum | Dank Bar height | initial idle footprint only (overlay growth) |
| `expanded` | content-requested | content-requested | keeps only the initial idle footprint |

**Compact is not a fixed-width mode anymore.** Compact content may grow the island and therefore dynamically grow the center reservation. This deliberately pushes/squeezes other Dank Bar center pills out of the requested space.

The persistent setting historically named `islandReservedWidth` is retained for settings compatibility, but its meaning is now **Island Initial Idle Width**. It is a baseline, not a permanent reservation.

`islandCompactMaxWidth` is the policy limit for compact growth. A template that cannot represent its content by that width should request `peek` rather than forcing an invalid compact layout.

### `ttl`

Optional lifetime in milliseconds:

```qml
ttl: 3200
```

A positive finite TTL starts the controller timer. Expiry calls `clear()`, removes the event, and returns to compact idle.

A newly `push()`ed event restarts TTL. `requestPresentation()` does **not** restart TTL; it is specifically for promoting/demoting the same transient event while preserving its lifetime.

### `payload`

Arbitrary event-specific immutable data. The bridge/controller do not interpret payload fields.

## `IslandEventBridge`

Public outputs:

```qml
signal eventReceived(var event)
signal clearRequested()
```

The daemon wires them to:

```qml
onEventReceived: event => islandController.push(event)
onClearRequested: islandController.clear()
```

The global-QML ingress remains `PluginService` variable `islandEvent`. Use a unique `token` when repeatedly publishing the same semantic event:

```qml
pluginService.setGlobalVar(pluginId, "islandEvent", {
    token: "producer-" + Date.now() + "-" + Math.random(),
    event: event
})
```

The existing `toolboxIslandDebug` IPC remains a debug-only ingress.

## `IslandController`

### `push(event)`

`push()`:

1. rejects null,
2. shallow-clones the event envelope,
3. validates `presentation`,
4. replaces `currentEvent`,
5. switches mode,
6. cancels the previous TTL,
7. starts the event TTL when requested.

Treat the published event tree as immutable after publication.

### `requestPresentation(presentation)`

Switches only the presentation mode of the current event. It intentionally keeps `currentEvent` and the running TTL intact.

Typical use:

```text
compact receives notification
    ↓
IdleContent tries compact split up to compactMaximumWidth
    ↓ does not fit
requestPresentation("peek")
    ↓
PeekContent renders the same event
    ↓ same TTL expires
clear()
    ↓
compact IdleContent
```

### `clear()`

Stops the TTL timer, clears `currentEvent`, and returns to `compact`.

Event arbitration such as priority, queueing, dedupe/coalescing, sticky events, and resume should remain in the controller rather than the shader or content templates.

## Two-level Content Registry

`IslandContentRegistry` separates **scene layout** from **semantic payload**.

### Scene templates

```qml
sceneSourceFor(mode, event)
```

Production mapping:

```text
compact  -> IdleContent.qml
peek     -> PeekContent.qml
expanded -> ExpandedContent.qml
```

Permanent debug event mappings may still select dedicated debug scenes.

### Payload/notification components

```qml
notificationSourceFor(event)
```

Example:

```text
javaVersionSwitch -> content/notifications/JavaVersionSwitchNotification.qml
```

This separation is intentional. `IdleContent.qml` does not implement Java, notifications, clock formatting, lyrics, media, etc. It composes reusable payload components through `Loader`.

## Scene Content Contract

Scene content uses a capability-based contract. Only implement properties/signals that the scene needs; `IslandPresenter` probes optional capabilities and safely falls back when they are missing.

### Optional inputs

```qml
property var eventData: null
property var controller: null
property var islandContext: null
```

`eventData` is the current canonical event.

`controller` is provided for compatibility, but new reusable content should prefer output signals instead of directly reaching into controller methods.

`islandContext` currently provides:

```qml
{
    mode,
    idleWidth,
    compactMaximumWidth,
    compactHeight,
    maximumWidth,
    maximumHeight,
    radiusDip,
    shapeInset
}
```

The context is presentation/geometry information, not a service locator. Do not put `PluginService`, Dank Bar objects, shell internals, or backend providers into it.

### Optional geometry outputs

```qml
readonly property real requestedWidth: ...
readonly property real requestedHeight: ...
readonly property real requestedReservationWidth: ...
```

`requestedWidth` / `requestedHeight` request shell geometry.

`requestedReservationWidth` may request extra **compact** bar space. It cannot shrink compact reservation below the visible shell. Peek and expanded are overlay modes and intentionally ignore large reservation requests, retaining only the idle footprint.

Content must never assign the shell size or modify the Dank Bar spacer directly.

### Optional split outputs

```qml
readonly property bool wantsSplit: false
readonly property real splitPercentage: 0.5
```

When `wantsSplit` is true, the Presenter lowers the split request into the visual shell. `splitPercentage` is clamped to the shader-supported `[0.1, 0.9]` interval.

Content should calculate legal split geometry through `IslandSplitGeometry.qml`; do not duplicate shader math ad hoc.

### Optional content-change animation outputs

```qml
readonly property bool animateContentChange: false
readonly property string contentAnimation: "subtle"
readonly property int animationRevision: 0
```

Increment/change `animationRevision` when a semantic payload visually enters or changes. `DynamicIsland` may use this as a small visual acknowledgement. This does not imply mode changes and does not own event TTL.

Supported values are intentionally soft hints; current shell understands `"subtle"` and `"none"`. Future visual shells may add additional hints without changing event semantics.

### Optional interaction outputs

```qml
signal presentationRequested(string presentation)
signal eventRequested(var event)
signal clearRequested()
```

Preferred usage:

```qml
presentationRequested("expanded")
eventRequested({ type: "media", presentation: "peek", ... })
clearRequested()
```

The Presenter translates these into controller operations. This keeps components reusable and prevents them from depending on `IslandWindow` or visual-shell implementation details.

Payload components may expose the same signals. Scene templates should relay them.

## Split Geometry Contract

`IslandSplitGeometry.qml` is the canonical CPU/QML mirror of `dynamic_island.frag` split constraints.

Current shader constraints are:

```text
splitPercentage ∈ [0.1, 0.9]
splitGap = max(shapeInset * 2, 2)
baseRadius = max(radiusDip - shapeInset, 0)
minimum shader piece width = baseRadius * 2 + 0.001
```

The helper also accounts for per-piece content padding.

### `planForPiece(...)`

Checks whether a requested content-width piece can be placed on `left` or `right` for an exact island width.

Inputs:

```qml
planForPiece(
    islandWidth,
    radiusDip,
    shapeInset,
    requestedPieceWidth,
    side,
    otherMinimumWidth,
    piecePadding
)
```

### `findPlanForPiece(...)`

Finds the **smallest** legal island width inside `[minimumIslandWidth, maximumIslandWidth]` for that requested piece.

```qml
findPlanForPiece(
    minimumIslandWidth,
    maximumIslandWidth,
    radiusDip,
    shapeInset,
    requestedPieceWidth,
    side,
    otherMinimumWidth,
    piecePadding
)
```

The returned plan includes:

```text
success / reason
islandWidth
percentage
gap / availableWidth / minimumPieceWidth
leftWidth / rightWidth
leftStartOffset / rightStartOffset
leftContentStartOffset / rightContentStartOffset
leftContentWidth / rightContentWidth
pieceStartOffset / pieceContentStartOffset / pieceWidth / pieceContentWidth
otherStartOffset / otherContentStartOffset / otherWidth / otherContentWidth
```

Offsets are x coordinates relative to the outer Island item.

This means a scene can request “a 180 px notification piece on the right” without manually deriving shader percentage or layout offsets.

## Idle / Peek Composition

### `IdleContent.qml`

Idle is the compact scene template.

Without an event it loads only `widgets/ClockContent.qml` and uses initial idle width.

With a recognized notification event:

1. load the payload component,
2. read its natural/requested content width and preferred side,
3. call `findPlanForPiece(initialIdleWidth, compactMaximumWidth, ...)`,
4. if legal, grow compact width/reservation and enable split,
5. place clock and notification into the returned split pieces,
6. if no legal compact split exists, request `peek` for the same event.

Clock implementation must remain outside `IdleContent.qml`; it is loaded as a reusable component.

### `PeekContent.qml`

Peek uses the same clock + payload composition but may use the full window width policy.

Its main role for transient notifications is overflow presentation: when compact cannot make a legal split before `compactMaximumWidth`, Peek retries with a larger limit.

If split is still impossible due to an extreme screen/payload constraint, the current template falls back to a readable non-split clock + payload row rather than dropping the notification.

TTL remains controller-owned. When notification TTL expires, `clear()` automatically returns to compact idle. Compact split notifications behave identically.

## Java Version Switch Notification

`JavaPage.qml` publishes `javaVersionSwitch` only after `switch_java.sh` exits successfully.

The notification event begins in `compact` and has a short TTL. It contains the selected Java label/path. `JavaVersionSwitchNotification.qml` renders the semantic payload and does not know whether it is currently composed by compact or peek.

This is the first production payload component and is intended as the pattern for future notifications.

## Interaction / Dismissal Rules

Interaction belongs to content, not to compact/peek mode itself.

### Compact and Peek

The shell has **no implicit click behavior**. Clicking an inert clock+notification scene does nothing.

If a component needs interaction, it owns its `MouseArea`, button, hover region, etc., and may request another presentation/event through the optional signals.

### Expanded

Expanded has a global dismissal rule:

- click outside the island -> `clear()`;
- click a non-interactive area inside the island -> `clear()`;
- click an interactive child region -> that child handles the click and expanded stays open unless the child explicitly requests clear/transition.

Implementation is layered:

```text
IslandWindow full-screen dismiss area     (outside island)
IslandPresenter expanded background area  (inside island, below content)
loaded content interactive children       (above background dismissal)
```

This avoids putting global input semantics into every Expanded content file.

## Dynamic Reservation Flow

The reservation is per-screen and dynamic.

```text
scene requestedWidth/requestedReservationWidth
        ↓
IslandPresenter.barReservationWidth
        ↓
IslandWindow.reservationWidth
        ↓
IslandDaemon.publishReservation(screenName, width)
        ↓
PluginService global var: islandReservationWidths[screenName]
        ↓
IslandBarReservation.reservedWidth
        ↓
projected Dank Bar centerWidgetsModel
```

Rules:

1. initial idle width is the minimum reserved footprint;
2. compact accepted width may grow reservation up to `islandCompactMaxWidth`;
3. peek may grow the visual shell beyond compact max **without** growing the reservation;
4. clearing an event shrinks the shell back to idle;
5. expanded also reserves only idle footprint because it is an overlay and should not create a huge center-bar hole;
6. missing/stale per-screen runtime data falls back to initial idle width;
7. the persisted key `islandReservedWidth` is not mutated for transient runtime requests.

This is a controlled reverse propagation path. Only `IslandDaemon` crosses from presentation policy back to `PluginService`; content remains DI-clean.

## `IslandPresenter`

The Presenter is the policy/lowering layer. It owns:

- scene selection,
- optional input injection,
- requested dimension validation,
- compact max-width policy,
- split lowering,
- visual-change hint lowering,
- content signal -> controller translation,
- bar reservation policy,
- expanded inside-background dismissal.

Final width policy:

```text
compact  -> clamp(requestedWidth, initialIdleWidth, compactMaximumWidth)
peek     -> clamp(requestedWidth, initialIdleWidth, maximumWidth)
expanded -> clamp(requestedWidth, initialIdleWidth, maximumWidth)
```

Final height policy:

```text
compact  -> Dank Bar height
peek     -> Dank Bar height
expanded -> accepted requestedHeight
```

## `DynamicIsland`

`DynamicIsland` is a visual shell. It must not know event types, Java switching, TTL, registry mappings, Dank Bar reservation transport, or payload semantics.

Current inputs include:

```qml
required property real targetWidth
required property real targetHeight
required property string mode

property bool splitEnabled
property real splitPercentage
property bool contentChangeAnimationEnabled
property int contentChangeRevision
property string contentChangeAnimation
```

It exposes `shapeInset` and the effective target radius so Presenter can provide exact split geometry context without scene files duplicating shell constants.

## Shader Contract

Split geometry in `IslandSplitGeometry.qml` must remain mathematically consistent with `island/shaders/dynamic_island.frag`.

If the shader changes any of these rules, update both together:

- split percentage clamp,
- split gap,
- radius lowering,
- minimum piece width,
- shape inset semantics.

After changing shader source itself, rebuild the `.qsb` with:

```bash
./dev_scripts/build_shaders.sh
```

This refactor only wires existing split uniforms and therefore does not require a new `.qsb` unless the fragment shader source is changed separately.

## Extension Guide

For a new transient notification:

1. create `island/content/notifications/FooNotification.qml`,
2. expose a natural/requested width and optional `preferredSide`,
3. add semantic type -> payload source to `notificationSourceFor()`,
4. publish a canonical event with `presentation: "compact"` and optional TTL,
5. let Idle/Peek templates perform split/overflow policy.

For a new layout family rather than a notification payload:

1. create a scene template,
2. map it in `sceneSourceFor()` based on mode/event policy,
3. use optional content outputs/signals rather than reaching into Window/DynamicIsland,
4. keep backend/service access outside scene/payload QML.

Potential future optional capabilities can be added without breaking old content, for example priority visual hints, progress/state transition hints, focus/keyboard intent for expanded content, or more animation hints. They should stay declarative and be lowered by Presenter/Window rather than interpreted directly by the shader.
