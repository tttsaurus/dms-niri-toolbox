# Dynamic Island Contracts

Stable contracts for Widget composition, access navigation, Notifications, state patches, presentation, geometry, and reservation.

## Data flow

```text
feature / service
  -> islandEvent                  public plugin-global ingress
  -> IslandEventBridge            parse + normalize request path
  -> IslandController             own access chain / Notification / Widget state
  -> IslandPresenter              select renderer + inject state + lower geometry
  -> Idle / Peek / Expanded       compose Widget hosts and Notifications
  -> DynamicIsland                animate the visual shell
```

`IdleContent.qml`, `PeekContent.qml`, and `ExpandedContent.qml` are permanent presentation renderers. They do not own feature state, Notification lifetime, or Widget state.

Event producers never address QML payload files. The Bridge never passes a raw producer envelope into presentation Content; it first normalizes it into domain data.

Feature code should normally access only the plugin-global event ingress through `toolboxRoot.pluginService`. It should **not** acquire `IslandController`, `IslandPresenter`, a Content instance, or `DynamicIsland`.

## Core model: root menu and Widget access chain

The navigation model is a chain of Widget access nodes. `compact`, `peek`, and `expanded` are presentations selected for a node; they are not navigation states.

- The implicit root node is `IdleContent` in Compact presentation. It owns an ordered list of Widgets and behaves like a main menu.
- A Widget edge creates a fresh access node with a monotonically increasing `accessId`, a registered `widgetId`, and either Peek or Expanded presentation.
- Compact can never be an access target. Returning to Compact means popping the final Widget node and returning to the root list.
- A new node may use the same Widget component as its parent. For example, Compact Music Track and Peek Music Track are separate visits to the registered `musicTrack` Widget.
- `push` appends a node, `replace` replaces the top node (or enters access from the root), and `back` pops exactly one node.
- Every non-root Widget access suppresses Notification presentation. The first node pauses the active Notification TTL; nested nodes keep it paused; popping the final node resumes it.

The Controller exposes the derived presentation through `mode` for rendering compatibility, but owns navigation through:

```qml
readonly property var accessChain
readonly property var currentAccess
readonly property int accessDepth
readonly property var sceneState
```

`sceneState` is the current access frame when `accessDepth > 0`; otherwise it is the root presentation frame.

## Request paths

Every public ingress event selects one path:

```js
{ request: "access", ... }
{ request: "scene", ... }          // compatibility + root Notification presentation
{ request: "notification", ... }
{ request: "widget", ... }
{ request: "clear" }
```

Each path has its own permissions. Notification and Widget requests cannot acquire presentation or geometry capabilities.

### Widget access

```js
{
    request: "access",
    navigation: "push",        // push | replace | back
    widgetId: "musicTrack",
    presentation: "peek",      // peek | expanded; never compact
    width: 320,                // optional renderer hint
    height: 200,               // optional renderer hint
    ttl: 1800,                 // optional lease for this top node
    context: { ... }
}
```

`widgetId` must resolve through `IslandContentRegistry.widgetSourceFor()`. The Controller generates `context.accessKind`, `context.accessId`, and canonical `context.widgetId`; callers do not own those fields.

`width` and `height` are hints. The active presentation renderer owns final composition and geometry.

An access lease belongs only to the current top node. If it expires while that node is still current, the Controller performs one `back`. Pushing or replacing a node cancels the previous lease; leases are not retained on hidden chain entries.

Notification suppression is automatic and cannot be weakened by an access request. Do not attach `notificationPolicy` to this path.

Local Content sends the already-normalized form directly to Presenter:

```qml
root.accessRequested({
    navigation: "push",
    widgetId: "musicTrack",
    presentation: "peek"
})
```

### Root scene compatibility

`request: "scene"` remains as a compatibility ingress. A Scene request containing `widgetId`, `context.widgetId`, or legacy `context.exclusiveWidgetId` is converted into Widget access and receives all access invariants.

Without a Widget target, root Scene presentation is deliberately narrow:

- Compact selects the Idle root menu.
- Peek is accepted only for `context.presentationRole: "notificationOverflow"`.
- Other root Peek/Expanded requests are rejected because non-root presentation must address a registered Widget.

The Notification renderers use the local Scene signal for overflow transitions:

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

The root presentation is replaced, never pushed onto Widget access. Its Notification policy is always `keep`.

### Notification

```js
{
    request: "notification",
    type: "javaVersionSwitch",
    ttl: 3200,
    payload: { ... }
}
```

The Bridge normalizes the request to:

```js
{ type, ttl, payload }
```

Notification producers cannot request presentation, width, height, split, reservation, navigation, or access policy. Such fields are ignored. `ttl` defaults to 3000 ms. Persistent feature state belongs in a Widget.

At the root, a Notification coexists with the Compact Widget list when the split fits `compactMaximumWidth`. If it does not fit, the same root list and Notification are rendered by Peek. Once the compact plan fits again, or the Notification finishes and split closes, presentation returns to Compact.

During Widget access, an active Notification is removed from presentation and its remaining TTL is preserved. New Notifications queue FIFO. Popping the final Widget access restores the paused Notification first and then continues the queue.

### Widget state

```js
{
    request: "widget",
    widgetId: "musicTrack",
    operation: "patch",         // patch | reset
    patch: { enabled: false }
}
```

The Controller shallow-merges patches into the persistent state map for that Widget. `reset` removes the Widget entry. Widget state survives `clear`.

Every Widget receives its state through `widgetState`. `Core.IslandWidget` defines `{ enabled: false }` as the universal visibility toggle; Widgets may add domain-specific state fields. A Widget can request the same patch from inside itself:

```qml
root.patchState({ enabled: false })
```

This emits `statePatchRequested()`, which the host routes back to the Controller under the correct Widget id.

### Clear

```js
{ request: "clear" }
```

`clear` removes the access chain and all transient Notification/root-presentation state, then deterministically returns to Compact `IdleContent`. Persistent Widget state is retained.

## Publishing a request

Normal feature code publishes through the plugin-global `islandEvent` ingress. Use a fresh token when the same logical event may happen repeatedly:

```qml
function publishIslandEvent(event) {
    const toolbox = root.toolboxRoot
    if (!toolbox || !toolbox.pluginService || !toolbox.pluginId)
        return

    toolbox.pluginService.setGlobalVar(toolbox.pluginId, "islandEvent", {
        token: "my-feature-" + Date.now() + "-" + Math.random(),
        event: event
    })
}

publishIslandEvent({
    request: "widget",
    widgetId: "myWidget",
    operation: "patch",
    patch: { enabled: true }
})
```

A page or feature object that already owns `toolboxRoot` is a normal place for this helper. If a low-level detector does not have `PluginService`, bubble a semantic signal to an owning page/service instead of injecting island infrastructure downward.

`IslandEventBridge.accept(event)` is the direct local ingress for island composition/testing code. Ordinary feature implementations should use `islandEvent` rather than acquiring the Bridge object.

## Widget interface

Widgets should derive from `Core.IslandWidget`:

```qml
import "../../core" as Core

Core.IslandWidget {
    id: root

    contentAvailable: service.ready
    minimumWidthHint: 80
    preferredWidthHint: 140
    preferredHeightHint: 36
    interactive: true
}
```

Common inputs:

```qml
property var widgetState
```

Island presentation is not Widget state. Compact/Peek/Expanded belongs to the access frame and its Host. A Widget with presentation-specific visuals may declare an optional, Widget-local input such as:

```qml
property var viewOptions: ({})
```

The registry maps the Host presentation to domain-specific options. Music Track receives `showMetadata` and `metadataWidthLimit`; it never receives or branches on the island presentation enum.

Common availability and layout fields:

```qml
property bool contentAvailable
readonly property bool widgetStateEnabled
readonly property bool widgetVisible
property real minimumWidthHint
property real preferredWidthHint
property real preferredHeightHint
property bool interactive
```

`widgetVisible` is Island semantic availability, not Qt Quick `Item.visible`. The base implementation is:

```text
widgetVisible = widgetState.enabled !== false && contentAvailable
```

The Widget Loader stays instantiated at zero presence so later service or state changes can reveal it again.

Common semantic intents:

```qml
signal activated()
signal statePatchRequested(var patch)
signal actionRequested(string action, var payload)
signal accessRequested(var request)

function patchState(patch)
function requestAccess(request)
```

Use `activated()` for the registry-defined default edge. The Host resolves that edge using its own presentation and forwards the copied access request. Use `requestAccess()` only when a Widget must choose a dynamic target; the Controller still validates the target and Compact prohibition.

## Generic Widget hosting and Idle composition

`IslandWidgetHost` is the single protocol adapter. It owns the presentation, resolves a registered source and default activation edge, injects state/optional Widget-local view options/host metrics, forwards semantic signals, and exposes normalized hints.

`widgetReady` means exactly that the Loader has the selected source in `Loader.Ready`; it is never gated by a second owner/preparation latch. Inputs are synchronously injected from `onLoaded`. Peek and Expanded defer an unavailable decision by one event turn, then revalidate the current `accessId`, renderer epoch, load failure, and `widgetVisible` before popping. Peek's background back action remains enabled for the entire access lifetime, so a missing or failed Widget cannot trap the access chain in a blank renderer.

A presentation viewport must not derive its own `visible` value from the hosted child's `visible` value. Qt propagates an invisible parent's state into every child, so that dependency forms a closed visibility loop. The viewport is driven by its own transition opacity; `IslandWidgetHost` independently owns the Widget's presence animation.

For visibility, it keeps one `visibilityProgress` scalar:

```text
layoutWidth = preferredWidthHint * visibilityProgress
opacity     = visibilityProgress
```

The first resolved visibility is snapped, so cold startup never waits behind a fade from an empty Loader. Every later `widgetVisible` change animates layout participation and opacity together.

`IslandWidgetStrip` composes any ordered list of hosts and calculates natural width and animated inter-Widget spacing. `IdleContent` directly owns the root list:

```qml
readonly property var widgets: [
    "clock",
    "musicTrack"
]

Content.IslandWidgetStrip {
    widgets: root.widgets
    widgetStates: root.widgetStates
    presentation: "compact"
}
```

Adding/removing a root item is a list change, not a new hand-written Loader, width formula, visibility binding, or signal bridge.

## Registry: Widget definitions and edges

`IslandContentRegistry.widgetDefinitionFor(widgetId)` owns stable identity metadata:

- QML source;
- default activation edge per presentation;
- optional presentation metadata such as Expanded title and unavailable behavior.

`activationRequestFor(widgetId, presentation)` returns a copied edge request. `IslandWidgetHost` resolves and forwards it when the Widget emits `activated()`. A newly registered Widget can therefore choose Compact → Peek, Compact → Expanded, Peek → another Peek/Expanded Widget, or Expanded → another Peek/Expanded Widget without adding feature-specific branches to Idle, Peek, Expanded, Presenter, or Controller.

`viewOptionsFor(widgetId, presentation)` separately returns a copy of optional Widget-local rendering inputs. Access navigation never reads them, and the Widget never needs to know the Host presentation.

Back is also an edge:

```js
activations: {
    expanded: { navigation: "back" }
}
```

## Split companion specialization

`IslandContentRegistry.companionFor(widgetId, presentation)` may decorate a Peek access node with another normal Widget:

```js
{
    widgetId: "musicControlsLauncher",
    side: "right",
    square: true
}
```

Peek loads the companion through `IslandWidgetHost`, so it receives independent Widget state, `widgetVisible`, opacity, and semantic signals. Peek alone owns split planning and animation. The companion's activation uses its own registry edge; the companion specification does not embed feature-specific Scene requests.

This is the generalized special path used by Music Track. A future Widget can opt into the same mechanism without changing Peek composition code.

## Presentation Content interface

Stable inputs:

```qml
property var notificationData
property var sceneContext
property var widgetStates
property var islandContext
```

Optional geometry/animation outputs:

```qml
readonly property real requestedWidth
readonly property real requestedHeight
readonly property real requestedReservationWidth
readonly property bool wantsSplit
readonly property real splitPercentage
readonly property bool animateContentChange
readonly property string contentAnimation
readonly property int animationRevision
```

Semantic requests:

```qml
signal accessRequested(var request)
signal sceneRequested(var request)
signal widgetStatePatchRequested(string widgetId, var patch)
signal notificationDismissRequested()
signal dismissRequested()
signal clearRequested()
```

`dismissRequested()` is access-aware: the Controller pops one Widget node when one exists and otherwise resets root presentation. `clearRequested()` keeps its deterministic hard-clear meaning.

## Notification interface

Input:

```qml
property var notificationData
```

Layout/visual hints:

```qml
readonly property real minimumWidthHint
readonly property real preferredWidthHint
readonly property real preferredHeightHint
readonly property string preferredSideHint
readonly property string animationHint
readonly property bool interactive
```

A Notification never requests island geometry, split, reservation, navigation, or presentation. `IslandContentRegistry.notificationSourceFor()` resolves its semantic `type` to a visual component.

## Migrated reference flow

```text
Idle root: [clock] [musicTrack] [+ Notification]
                       |
                       | registry edge: push musicTrack / Peek
                       v
Peek access: [musicTrack] [musicControlsLauncher companion]
             Notifications paused
                 |                         |
                 | musicTrack back         | launcher edge: push controls / Expanded
                 v                         v
              Idle root           Expanded access: [musicControls]
                                               |
                                               | non-control activation = back
                                               v
                            Peek access: track + launcher
```

Clock and Music Track use exactly the same base Widget API and generic Idle strip. Clock remains permanently domain-available and non-interactive, but can still be hidden with an external `enabled` state patch. Music Track binds `contentAvailable` to MPRIS availability; its existing playback visuals and interaction behavior are unchanged.

Music Controls keeps its generic activation `MouseArea` below actual controls. Buttons and the seekbar consume their own interaction; every non-control click emits `activated()`, whose Expanded registry edge pops back to Music Track Peek.

## Extending the island

### Add a Widget

1. Put the component in `island/content/widgets/` and derive from `Core.IslandWidget`.
2. Bind `contentAvailable`, set layout hints, and emit only semantic intents.
3. Register a stable id/source plus any activation and presentation metadata in `IslandContentRegistry.widgetDefinitionFor()`.
4. Add the id to `IdleContent.widgets` only if it belongs in the root menu.
5. Optionally return a companion from `companionFor()` for a specialized Peek split.
6. Use `request: "widget"` for external persistent state patches; use `patchState()` for self-requested patches.

No new Idle Loader, per-Widget width property, Content connection block, Controller branch, or Notification policy is required.

### Add a Notification

1. Put the visual component in `island/content/notifications/` and implement the Notification interface.
2. Register its semantic `type` in `IslandContentRegistry.notificationSourceFor()`.
3. Keep the producer next to the feature/service that detects the change.
4. Publish `request: "notification"` through `islandEvent`.
5. Let Idle/Peek consume only normalized Notification data and visual hints.

The producer never chooses the QML file, split percentage, island width, access node, or presentation.
