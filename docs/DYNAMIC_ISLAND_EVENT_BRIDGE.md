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

Registry edges and `requestAccess()` use the internal access shape directly; there is no public event discriminator for navigation:

```qml
root.requestAccess({
    navigation: "push",
    widgetId: targetId,
    presentation: "peek",
    context: {
        customValue: 42
    }
})
```

Use `activated()` when the target is fixed in the definition. Use `requestAccess()` only when the Widget itself must choose the target from runtime data.

Internal access requests use these canonical fields:

| Field | Behavior |
| --- | --- |
| `navigation` | `push` by default; `replace` replaces the top frame; `back` pops one frame |
| `widgetId` | Registered target id; required for `push` and `replace` |
| `presentation` | `peek` by default; access targets may use `peek` or `expanded`, never `compact` |
| `context` | Shallow-copied per-frame renderer/Widget data |
| `width` / `widthHint` | Optional positive width hint copied to `context.widthHint` |
| `height` / `heightHint` | Optional positive height hint copied to `context.heightHint` |

The Controller assigns a fresh positive `accessId` and overwrites `context.accessId` and `context.widgetId`. Entering the first frame suspends the active Notification; popping the final frame resumes it with its remaining TTL. Access frames themselves do not expire automatically.

Useful context keys are `title`, `message`, `backWhenWidgetUnavailable`, and `splitCompanion`. Keep presentation-independent domain state in `widgetState`, not in access context.

## `widgetDefinitionFor()` reference

A definition has this general shape:

```js
return {
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

The `switch` case is the Widget id. A definition only needs `source`; add `activations`, `presentations`, or `companions` when that Widget uses them.

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

A registered Widget omitted from this list is still available as an internal access target or companion.

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
| No entry for the current presentation | Nothing navigates |
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

These options only alter the component loaded into a Host. They do not create navigation; that requires an activation edge or the Widget's internal `requestAccess()` intent.

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

External events cannot directly enter, replace, pop, or clear the Widget access chain. Widget navigation stays inside Registry activation edges and Widget-originated `requestAccess()` intents. While a Widget access is active, Notifications wait without replacing the current Peek/Expanded renderer. A Widget state patch can still make the current Widget unavailable; if its presentation declares `backWhenUnavailable`, the renderer then closes that invalid frame through the normal availability rule.

### Request paths

| `request` | Purpose | Required identifier |
| --- | --- | --- |
| `"widget"` | Patch/reset stored Widget state | Non-empty `widgetId` |
| `"notification"` | Queue a typed transient Notification | Non-empty `type`; register it to render |

These are semantic inputs, not presentation commands. The Bridge does not expose push, replace, back, Peek, Expanded, root-scene replacement, or Controller reset. Unknown request paths are rejected with a warning.

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

`operation` defaults to `"patch"`. Use `"reset"` to remove the whole stored entry:

```js
{
    request: "widget",
    widgetId: "musicTrack",
    operation: "reset"
}
```

`widgetId` and `patch` are canonical fields; the Bridge does not accept `id` or `payload` aliases for Widget state.

Patches are shallow merges:

```text
nextState[widgetId] = { ...previousState, ...patch }
```

All active instances with the same `widgetId` receive the updated state. `{ enabled: false }` hides them through `widgetVisible`. `reset` restores the Widget's default empty state.

The state path validates only a non-empty id; it does not require the id to be currently registered. State remains in the Controller until that id is reset or the Controller is recreated.

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

At the root, a Notification is split beside the Compact Widget list when the **combined** layout fits `compactMaximumWidth`. Otherwise the root temporarily promotes the same Widget list and Notification to Peek. This Notification-overflow Peek is not a Widget access frame and cannot disturb the Widget access chain.

`compactMaximumWidth` is only the Compact-versus-Peek decision threshold for that combined layout. It does not cap the Widget list by itself:

- Without a Notification, Compact follows the Widgets' natural width even when it exceeds the threshold.
- The bar reservation follows that actual Compact width.
- Peek and Expanded use the window's physical `maximumWidth`, not `compactMaximumWidth`.
- If the Widget list already exceeds the threshold, the next Notification promotes to Peek.

During Widget access, new Notifications queue FIFO and the active Notification remains suspended.

### Adding a Notification type

1. Create a component under `island/content/notifications/` with `property var notificationData`.
2. Expose `minimumWidthHint`, `preferredWidthHint`, `preferredHeightHint`, `preferredSideHint`, and `animationHint` as needed.
3. Map the semantic type in `notificationSourceFor()`.
4. Publish a `request: "notification"` event from the feature that detected the change.

The component reads its data from `notificationData.payload`.

## Rendering and lifecycle constraints

- `widgetReady` means the selected Loader source is `Loader.Ready` with a non-null item. Do not add a second readiness latch.
- When a renderer should auto-back, Loader Error and stable semantic unavailability are rechecked against the current `accessId`, so an old callback cannot pop a newer frame.
- Peek keeps its background back action active for the whole Widget access, including Loading/Error states.
- A presentation viewport must not bind its own `visible` to a child Host's `visible`. Qt propagates parent visibility into children and that creates a closed dependency. Drive the viewport from its transition opacity.
- Widget component size fields are hints used by the presentation layout. Internal access `width`/`height` become context hints; Expanded currently consumes them directly, while Peek composes width from Widget and split hints.
- Compact is always the root list. Returning to Compact means popping the final access frame, not pushing a Compact frame.
