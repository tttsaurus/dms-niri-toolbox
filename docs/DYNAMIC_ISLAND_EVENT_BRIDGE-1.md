# Dynamic Island Widget and Event Guide

This guide explains how to add Island Widgets, connect presentation-specific behavior in `IslandContentRegistry`, and publish external events through `islandEvent`.

## Files used when adding a feature

| File | Edit it when... |
| --- | --- |
| `island/core/IslandContentRegistry.qml` | Registering a Widget/Notification, default edge, view option, title, or companion |
| `island/core/IslandWidget.qml` | Changing the common Widget protocol |
| `island/content/widgets/*.qml` | Implementing Widget visuals and domain behavior |
| `island/content/IdleContent.qml` | Adding/removing a Widget from the Compact root list |
| `island/content/notifications/*.qml` | Implementing a Notification visual |
| `island/core/IslandEventBridge.qml` | Changing the public event grammar or aliases |
| `island/core/IslandController.qml` | Changing navigation, Notification lifetime, or stored Widget state semantics |

Normal feature additions should only need a Widget/Notification component, its registry entry, and optionally `IdleContent.widgets`.

## Implementing a Widget

Widgets derive from `Core.IslandWidget`:

```qml
import QtQuick
import "../../core" as Core

Core.IslandWidget {
    id: root

    contentAvailable: service.ready
    minimumWidthHint: 80
    preferredWidthHint: 140
    preferredHeightHint: 36
    interactive: true

    implicitWidth: root.preferredWidthHint
    implicitHeight: root.preferredHeightHint

    MouseArea {
        anchors.fill: parent
        enabled: root.widgetVisible
        onClicked: root.activated()
    }
}
```

### Common properties

| Property | Meaning |
| --- | --- |
| `widgetState` | State object stored under this `widgetId` and injected by the Host |
| `contentAvailable` | Whether the Widget's domain data currently exists |
| `widgetStateEnabled` | `widgetState.enabled !== false` |
| `widgetVisible` | `widgetStateEnabled && contentAvailable` |
| `minimumWidthHint` | Smallest meaningful layout width |
| `preferredWidthHint` | Natural width requested from the renderer |
| `preferredHeightHint` | Natural height, mainly used by Expanded |
| `interactive` | Semantic input hint exposed by the Host |

`widgetVisible` is not Qt Quick `Item.visible`. Keep the Loader alive and change `contentAvailable` or `{ enabled: false }`; the Host animates layout width and opacity when semantic visibility changes.

The first resolved visibility is snapped. Later visibility changes animate:

```text
layoutWidth = preferredWidthHint * visibilityProgress
opacity     = visibilityProgress
```

### Presentation-specific visuals

Do not branch on an Island presentation enum inside the Widget. Declare a local options input only when the component needs one:

```qml
property var viewOptions: ({})

readonly property bool detailed:
    root.viewOptions?.showMetadata === true
```

The Host asks the registry for the current presentation's `viewOptions` and assigns them if the loaded item declares that property. A Widget without `viewOptions` simply ignores them.

### Widget intents

| Intent | Use it for |
| --- | --- |
| `activated()` | Follow the static registry edge for the Host's current presentation |
| `patchState({...})` | Request a shallow patch to this Widget's stored state |
| `requestAccess({...})` | Choose a navigation target dynamically at runtime |

Registry edges and `requestAccess()` use the internal normalized access shape, without `request: "access"`:

```qml
root.requestAccess({
    navigation: "push",
    widgetId: targetId,
    presentation: "peek"
})
```

Use `activated()` when the target is fixed in the definition. Use `requestAccess()` only when the Widget itself must choose the target from runtime data.

`actionRequested()` exists at the low-level Widget/Host boundary, but current presentation renderers do not route it to the Controller. Add an explicit consumer before using it as a feature API.

## `widgetDefinitionFor()` reference

A definition has this general shape:

```js
return {
    widgetId: "example",
    source: Qt.resolvedUrl("../content/widgets/ExampleWidget.qml"),

    activations: {
        compact: { /* normalized access request */ },
        peek: { /* normalized access request */ },
        expanded: { /* normalized access request */ }
    },

    presentations: {
        compact: { /* presentation spec */ },
        peek: { /* presentation spec */ },
        expanded: { /* presentation spec */ }
    },

    companions: {
        peek: { /* companion spec */ }
    }
}
```

The `switch` case is the lookup key. Keep the returned `widgetId` equal to it; the current helpers primarily consume `source`, `activations`, `presentations`, and `companions`.

Unknown ids return `null` and cannot be access targets.

Current definitions demonstrate the main combinations:

| `widgetId` | Compact list | Activation entries | Presentation entries | Companion entries |
| --- | --- | --- | --- | --- |
| `clock` | Yes | None | None | None |
| `musicTrack` | Yes | Compact pushes `musicTrack/peek`; Peek backs | Compact/Peek/Expanded `viewOptions` | Peek loads `musicControlsLauncher` |
| `musicControlsLauncher` | No; companion only | Peek pushes `musicControls/expanded` | None | None |
| `musicControls` | No; access target | Expanded backs | Expanded title + unavailable-back | None |

### `source`

`source` is the component loaded whenever a Host selects this id. The same source can be loaded by Compact, Peek, Expanded, or several placements at once.

Registration does not automatically put a Widget in Compact. Add its id to `IdleContent.widgets` when it belongs in the root list:

```qml
readonly property var widgets: [
    "clock",
    "musicTrack",
    "example"
]
```

A registered Widget omitted from this list is still available as an access target, companion, or external-event target.

### `activations`: default navigation edges

The key is the Host's **current** presentation. The value describes what happens after that Widget instance emits `activated()`.

```js
activations: {
    compact: {
        navigation: "push",
        widgetId: "details",
        presentation: "peek"
    }
}
```

| Edge | Result |
| --- | --- |
| No entry for the current presentation | Host emits its fallback `activated()` signal; normally nothing navigates |
| `{ navigation: "back" }` | Pop one access frame; at the final frame this returns to Compact |
| `push` + same `widgetId` | Visit the same registered component in a new access frame/presentation |
| `push` + another `widgetId` | Open another registered Widget and preserve the current frame below it |
| `replace` + target | Replace the top frame; from Compact it creates the first access frame |

Valid access targets use `peek` or `expanded`. `compact` is not an access target because it is the root Widget list.

Examples:

```js
// Compact Example -> Peek Example
compact: {
    navigation: "push",
    widgetId: "example",
    presentation: "peek"
}

// Peek Example -> Expanded Editor
peek: {
    navigation: "push",
    widgetId: "exampleEditor",
    presentation: "expanded"
}

// Click the accessed Widget to close one level
peek: { navigation: "back" }
```

An edge is copied before dispatch, including a shallow copy of its `context`, so navigation does not mutate the registry object.

### `presentations`: view options and renderer metadata

`presentations[presentation]` returns a presentation spec. Current consumers recognize:

| Key | Consumer | Effect |
| --- | --- | --- |
| `viewOptions` | `IslandWidgetHost` | Shallow-copied and injected into a Widget-local `viewOptions` property |
| `title` | `ExpandedContent` | Expanded header title |
| `backWhenUnavailable` | `ExpandedContent` | Pop when the loaded Widget is Ready/Error but semantically unavailable |

`viewOptions` is Widget-defined data, not a fixed global schema. Music Track uses:

```js
presentations: {
    compact: {
        viewOptions: {
            showMetadata: false
        }
    },
    peek: {
        viewOptions: {
            showMetadata: true,
            metadataWidthLimit: 300
        }
    },
    expanded: {
        viewOptions: {
            showMetadata: true
        }
    }
}
```

These options only alter the component loaded into a Host. They do not create navigation; that requires an activation edge or an access event.

Expanded context can override `title` and can additionally enable unavailable-back behavior with `context.backWhenWidgetUnavailable: true`. It cannot disable a registry `backWhenUnavailable: true` entry.

### `companions`: Peek split decoration

Peek checks `companions.peek` after loading its primary Widget:

```js
companions: {
    peek: {
        widgetId: "musicControlsLauncher",
        side: "right",
        square: true
    }
}
```

| Key | Meaning |
| --- | --- |
| `widgetId` | Registered Widget loaded into the split piece |
| `side` | `"left"` or `"right"`; other values resolve to right |
| `square` | Use a height-derived square content width instead of the companion's preferred width |

The companion has its own Host, state entry, semantic visibility, and `activations.peek` edge. If it is unavailable or the split cannot fit, the primary Widget can still render without the split.

Only Peek currently consumes companions. `context.splitCompanion` on an access request can provide a per-frame companion spec instead of the registry entry.

## Adding a Widget: complete checklist

1. Create `island/content/widgets/ExampleWidget.qml` deriving from `Core.IslandWidget`.
2. Bind `contentAvailable` and provide positive width/height hints.
3. Emit `activated()` for a fixed registry edge, or `requestAccess()` for a runtime-selected edge.
4. Add a `widgetDefinitionFor("example")` case with a stable source.
5. Add only the activation entries needed for the presentations where the Widget is clickable.
6. Add `viewOptions`, Expanded metadata, or a Peek companion only if the feature uses them.
7. Add `"example"` to `IdleContent.widgets` only if it should appear in Compact.
8. Use a `request: "widget"` event or `patchState()` for persistent on/off/domain state.

No per-feature Loader or Controller branch is needed for these combinations:

| Desired behavior | Definition/list configuration |
| --- | --- |
| Passive Compact display | Register source, add id to `IdleContent.widgets`, no activation edge |
| Compact opens its own Peek | `activations.compact` pushes same id/Peek |
| Compact opens separate Expanded UI | `activations.compact` pushes another id/Expanded |
| Target-only menu | Register it but omit it from `IdleContent.widgets` |
| Peek click closes | `activations.peek = { navigation: "back" }` |
| Peek opens another Peek/Expanded | `activations.peek` pushes the target id/presentation |
| Peek gains a split launcher | `companions.peek` references a registered companion |
| Same component has different layouts | Per-presentation `viewOptions` plus a local Widget `viewOptions` property |

## Publishing external events

Feature code publishes through the plugin-global `islandEvent` variable. The recommended helper uses a fresh token for every logical event:

```qml
function publishIslandEvent(event) {
    const toolbox = root.toolboxRoot
    if (!toolbox
            || !toolbox.dynamicIslandEnabled
            || !toolbox.pluginService
            || !toolbox.pluginId) return

    toolbox.pluginService.setGlobalVar(
        toolbox.pluginId,
        "islandEvent",
        {
            token: "my-feature-" + Date.now() + "-" + Math.random(),
            event: event
        }
    )
}
```

### Accepted ingress forms

Recommended global envelope:

```js
{
    token: "unique-token",
    event: {
        request: "notification",
        type: "javaVersionSwitch",
        payload: { label: "Java 21" }
    }
}
```

The Bridge ignores an envelope whose stringified token equals the last consumed token. Change the token when repeating the same event.

A bare global event is also accepted:

```js
{
    request: "widget",
    widgetId: "musicTrack",
    patch: { enabled: false }
}
```

This form has no token-level deduplication and is mainly useful for simple tests.

Local Island/testing code can bypass the global variable:

```qml
eventBridge.accept({
    request: "access",
    widgetId: "musicTrack",
    presentation: "peek"
})
```

`accept()` takes the bare event, not the `{ token, event }` envelope.

### Request paths

| `request` | Purpose | Required identifier |
| --- | --- | --- |
| `"access"` | Push, replace, or pop a Peek/Expanded Widget frame | Registered `widgetId`, except for `back` |
| `"widget"` | Patch/reset stored Widget state | Non-empty `widgetId` or `id` |
| `"notification"` | Queue a typed transient Notification | Non-empty `type`; register it to render |
| `"clear"` | Clear access and transient Notification/root presentation state | None |
| `"scene"` | Compatibility path and internal Notification-overflow presentation | Depends on variant |

Public Bridge events include `request`. Internal `accessRequested()` and `sceneRequested()` signals do not, because their signal already selects the request path.

## `request: "access"`

Canonical form:

```js
{
    request: "access",
    navigation: "push",
    widgetId: "musicTrack",
    presentation: "peek",
    width: 320,
    height: 180,
    ttl: 2000,
    context: {
        customValue: 42
    }
}
```

| Field | Aliases / precedence | Default and behavior |
| --- | --- | --- |
| `navigation` | — | `"push"`; valid: `push`, `replace`, `back` |
| `widgetId` | `context.widgetId`, then legacy `context.exclusiveWidgetId` | Required unless navigation is `back`; must be registered |
| `presentation` | `mode` | `"peek"`; valid access target: `peek` or `expanded` |
| `context` | `payload` when `context` is absent | Shallow-copied custom frame data |
| `width` | `widthHint`, then `context.widthHint` | Positive finite renderer hint copied to context |
| `height` | `heightHint`, then `context.heightHint` | Positive finite renderer hint copied to context |
| `ttl` | — | Positive milliseconds, floored; `0`/invalid means no lease |
| `notificationPolicy` | — | Ignored with a warning; Widget access always suppresses Notifications |

Navigation behavior:

- `push`: append a frame.
- `replace`: replace the top frame; when called from Compact, create the first frame.
- `back`: pop exactly one frame. Other access fields are unnecessary.

Minimal back event:

```js
{ request: "access", navigation: "back" }
```

Open Expanded directly:

```js
{
    request: "access",
    widgetId: "musicControls",
    presentation: "expanded"
}
```

Each accepted target receives a new positive `accessId`. The Controller overwrites these reserved context keys:

```js
context.accessKind = "widget"
context.accessId = generatedAccessId
context.widgetId = canonicalWidgetId
context.exclusiveWidgetId = canonicalWidgetId
```

Useful renderer context keys include:

| Key | Used by |
| --- | --- |
| `widthHint`, `heightHint` | Expanded geometry; retained in context for other renderers |
| `title` | Expanded header override |
| `message` | Expanded unavailable fallback text |
| `backWhenWidgetUnavailable` | Expanded automatic back override |
| `backOnWidgetActivation` | Expanded fallback activation when the definition has no Expanded edge |
| `splitCompanion` | Per-frame Peek companion override |
| `compactRadiusDip` | Peek split planning override |

Entering the first access frame pauses the active Notification and its remaining TTL. Nested frames keep Notifications suppressed. Popping the final frame resumes the paused Notification, then the queued Notifications.

## `request: "widget"`

Patch state:

```js
{
    request: "widget",
    widgetId: "musicTrack",
    operation: "patch",
    patch: {
        enabled: false,
        customValue: 12
    }
}
```

Accepted variants:

```js
// operation defaults to patch
{
    request: "widget",
    id: "musicTrack",
    payload: { enabled: true }
}

// remove the whole stored entry
{
    request: "widget",
    widgetId: "musicTrack",
    operation: "reset"
}
```

Patches are shallow merges:

```text
nextState[widgetId] = { ...previousState, ...patch }
```

All active instances with the same `widgetId` receive the updated state. `{ enabled: false }` hides them through `widgetVisible`. `reset` restores the Widget's default empty state.

The state path validates only a non-empty id; it does not require the id to be currently registered. Widget state survives `request: "clear"`.

## `request: "notification"`

```js
{
    request: "notification",
    type: "javaVersionSwitch",
    ttl: 3200,
    payload: {
        label: "Java 21",
        javaPath: "/usr/lib/jvm/java-21"
    }
}
```

| Field | Behavior |
| --- | --- |
| `type` | Required non-empty string; `notificationSourceFor()` must map it to a component |
| `ttl` | Positive milliseconds, floored; defaults to `3000` |
| `payload` | Shallow-copied domain data passed to the Notification component |

Notification requests ignore `presentation`, `mode`, width/height aliases, `navigation`, and `notificationPolicy`. The Notification visual provides hints; it does not choose its presentation or Island geometry.

An unregistered non-empty type is accepted into the transient queue but has no visual source, so always add its `notificationSourceFor()` mapping.

At the root, a Notification is split beside the Compact Widget list when it fits `compactMaximumWidth`. If it does not fit, the root temporarily uses Peek presentation with the same Compact Widget list. This Notification-overflow Peek is not a Widget access frame.

During Widget access, new Notifications queue FIFO and the active Notification remains suspended.

### Adding a Notification type

1. Create a component under `island/content/notifications/` with `property var notificationData`.
2. Expose `minimumWidthHint`, `preferredWidthHint`, `preferredHeightHint`, `preferredSideHint`, `animationHint`, and `interactive` as needed.
3. Map the semantic type in `notificationSourceFor()`.
4. Publish a `request: "notification"` event from the feature that detected the change.

The component reads its data from `notificationData.payload`.

## `request: "clear"`

Canonical form:

```js
{ request: "clear" }
```

Legacy form:

```js
{ action: "clear" }
```

The legacy form is recognized only when `request` is absent.

Clear removes the access chain, active/queued/suspended Notifications, scene leases, and the temporary root presentation. It returns to Compact. Stored Widget state is retained.

## `request: "scene"` compatibility variants

Prefer `request: "access"` for feature menus. Scene remains for older callers and the internal Notification-overflow transition.

### Scene with a Widget target

Any of these target locations converts the Scene request into Widget access:

```js
{ request: "scene", widgetId: "musicTrack", presentation: "peek" }

{
    request: "scene",
    context: { widgetId: "musicTrack" },
    mode: "peek"
}

{
    request: "scene",
    payload: { exclusiveWidgetId: "musicTrack" },
    presentation: "peek"
}
```

Scene uses the same `mode`, context/payload, Widget-id, width/height, and TTL aliases as Access. Its default navigation is `replace`, not Access's `push`.

### Scene without a Widget target

Only these root presentations are accepted:

- Compact root.
- Peek with `context.presentationRole: "notificationOverflow"`.

The overflow renderer uses this normalized local request:

```qml
root.sceneRequested({
    presentation: "peek",
    context: {
        presentationRole: "notificationOverflow",
        widgets: root.widgets.slice()
    },
    notificationPolicy: "keep"
})
```

Other root Peek/Expanded requests are rejected. Root presentation is replaced rather than pushed, and it keeps Notification delivery. Feature code normally never needs this variant.

## Rendering and lifecycle constraints

- `widgetReady` means the selected Loader source is `Loader.Ready` with a non-null item. Do not add a second readiness latch.
- When a renderer should auto-back, Loader Error and stable semantic unavailability are rechecked against the current `accessId`, so an old callback cannot pop a newer frame.
- Peek keeps its background back action active for the whole Widget access, including Loading/Error states.
- A presentation viewport must not bind its own `visible` to a child Host's `visible`. Qt propagates parent visibility into children and that creates a closed dependency. Drive the viewport from its transition opacity.
- Widget component size fields are hints used by the presentation layout. Public access `width`/`height` become context hints; Expanded currently consumes them directly, while Peek composes width from Widget and split hints.
- Compact is always the root list. Returning to Compact means popping the final access frame, not pushing a Compact frame.
