# Dynamic Island Contracts

Stable contracts for island requests, scene skeletons, Notifications, Widgets, layout, and reservation.

## Data flow

```text
feature / service
  -> islandEvent                 public plugin-global ingress
  -> IslandEventBridge           parse + normalize request path
  -> IslandController            own scene / Notification / Widget state
  -> IslandPresenter             inject state + lower geometry
  -> Idle / Peek / Expanded      compose payloads
  -> DynamicIsland               animate visual shell
```

`IdleContent.qml`, `PeekContent.qml`, and `ExpandedContent.qml` are permanent scene skeletons. They are orchestrators: they choose composition and geometry, but do not own feature state, Notification lifetime, or Widget state.

Event producers never address QML payload files. The Bridge never passes a raw producer envelope into scene Content; it first normalizes it into domain data.

Feature code should normally access only the plugin-global event ingress through `toolboxRoot.pluginService`. It should **not** acquire `IslandController`, `IslandPresenter`, a scene Content instance, or `DynamicIsland`.

## Request paths

Every public ingress event selects one path:

```js
{ request: "scene", ... }
{ request: "notification", ... }
{ request: "widget", ... }
{ request: "clear" }
```

Each path has its own permissions. Convenience paths such as Notification and Widget do not inherit Scene capabilities.

### Scene

```js
{
    request: "scene",
    mode: "peek",                    // compact | peek | expanded
    width: 320,                      // optional hint
    height: 200,                     // optional hint
    ttl: 1800,                       // optional temporary lease
    notificationPolicy: "suspend",   // keep | suspend | resume
    context: { ... }
}
```

`width` and `height` are hints. The active scene skeleton owns final composition and geometry.

`notificationPolicy` is optional:

- `keep`: leave Notification delivery unchanged. The active Notification continues consuming its TTL, and queued Notifications continue normally after it finishes.
- `suspend`: temporarily remove the active Notification from presentation and pause its remaining TTL. New Notifications are retained in FIFO order instead of being displayed.
- `resume`: end a suspended period. Restore the previously active Notification with its remaining TTL first, then continue queued Notifications in FIFO order.

Use `suspend` for a scene that needs exclusive visual ownership, `resume` when returning presentation to the Notification stream, and `keep` when the scene can coexist with Notifications. If omitted, the Controller selects its default policy for the requested presentation.

The public Bridge accepts `mode`. Internally, scene skeletons emit the already-normalized local form through `sceneRequested()` using `presentation`:

```qml
root.sceneRequested({
    presentation: "peek",
    context: {
        exclusiveWidgetId: "musicTrack"
    },
    notificationPolicy: "suspend"
})
```

Scene skeletons do not republish this through `islandEvent`; Presenter translates the signal directly to the Controller.

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

Notification producers cannot request mode, width, height, split, reservation, or scene policy. Such fields are ignored. `ttl` defaults to 3000 ms. Persistent feature state belongs in a Widget instead.

Notifications may be presented by Compact or Peek according to the active scene composition. Delivery can be suspended by scene policy; remaining TTL is preserved and later Notifications queue FIFO.

### Widget

```js
{
    request: "widget",
    widgetId: "musicTrack",
    operation: "patch",     // patch | reset
    patch: { paused: true }
}
```

Widget requests update persistent Widget state. They cannot request presentation or geometry.

### Clear

```js
{ request: "clear" }
```

`clear` removes transient scene/Notification state and deterministically returns to Compact / `IdleContent.qml`. Widget state is retained.

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
    request: "notification",
    type: "myFeatureChanged",
    ttl: 3000,
    payload: {
        label: "Changed"
    }
})
```

A page or feature object that already owns `toolboxRoot` is a normal place for this helper. If a low-level detector does not have `PluginService`, bubble a semantic signal to an owning page/service that does instead of injecting island infrastructure downward.

`IslandEventBridge.accept(event)` is the direct local ingress for island composition/testing code. Ordinary feature implementations should use `islandEvent` rather than acquiring the Bridge object.

## Scene skeleton interface

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
signal sceneRequested(var request)
signal widgetStatePatchRequested(string widgetId, var patch)
signal notificationDismissRequested()
signal clearRequested()
```

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

A Notification never requests island geometry, split, reservation, or presentation. `IslandContentRegistry.notificationSourceFor()` resolves its semantic `type` to a visual component.

## Widget interface

Inputs:

```qml
property string presentation
property var widgetState
```

Layout/visual hints:

```qml
readonly property real minimumWidthHint
readonly property real preferredWidthHint
readonly property real preferredHeightHint
readonly property bool interactive
```

Typical semantic intents:

```qml
signal activated()
signal statePatchRequested(var patch)
signal actionRequested(string action, var payload)
```

Widgets do not decide island presentation or outer geometry. The hosting scene interprets their intents.

## Current composition example

Idle composes Clock + Music Track as one Compact piece. An active Notification may be split into the other piece.

```text
Idle: clock + music [+ notification]
        |
        | activate music
        v
Peek: music only; Notifications suspended
        |
        | activate Peek/music again
        v
Idle: suspended Notification resumes with remaining TTL
      queued Notifications continue FIFO
```

Notifications arriving during exclusive Music Peek are retained but not displayed. This is a scene-specific composition rule, not a generic Peek rule.

## Extending the island

### Add a Notification

1. Put the visual component in `island/content/notifications/` and implement the Notification interface.
2. Register its semantic `type` in `IslandContentRegistry.notificationSourceFor()`.
3. Keep the producer next to the feature/service that actually detects the change.
4. Publish `request: "notification"` through `islandEvent`.
5. Let Idle/Peek consume only normalized Notification data and visual hints.

For example, a feature listening for a profile change can publish:

```qml
Connections {
    target: profileService

    function onActiveProfileChanged(profile) {
        root.publishIslandEvent({
            request: "notification",
            type: "profileChanged",
            ttl: 3000,
            payload: {
                profile: profile
            }
        })
    }
}
```

Then add the visual mapping:

```text
profileService signal
  -> feature producer publishes islandEvent
  -> IslandEventBridge parses "notification"
  -> IslandController owns TTL / queue
  -> IslandContentRegistry resolves "profileChanged"
  -> Idle or Peek loads the Notification component
  -> scene reads its hints and chooses layout
```

The producer never chooses the QML file, split percentage, island width, or presentation.

### Add a Widget

1. Put the component in `island/content/widgets/`.
2. Register a stable Widget id in `IslandContentRegistry.widgetSourceFor()`.
3. Explicitly compose it from each scene skeleton that supports it.
4. Use `request: "widget"` for persistent state updates.
5. Let the hosting scene interpret Widget interaction signals such as `activated()`.
