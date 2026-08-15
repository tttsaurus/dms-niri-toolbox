# Dynamic Island Contracts

Stable contracts for island requests, scene skeletons, notifications, and widgets.

## Data flow

```text
producer
  -> IslandEventBridge        parse request path
  -> IslandController         own scene / notification / widget state
  -> IslandPresenter          inject current state
  -> Idle / Peek / Expanded   compose payloads + request geometry
  -> DynamicIsland
```

`IdleContent.qml`, `PeekContent.qml`, and `ExpandedContent.qml` are permanent scene skeletons. They are orchestrators, not payload/lifecycle owners.

Producers never address QML files. The Bridge never passes a raw producer envelope into Content; it first normalizes it into domain data.

## Request paths

Every ingress event selects one path:

```js
{ request: "scene", ... }
{ request: "notification", ... }
{ request: "widget", ... }
{ request: "clear" }
```

Each path has its own permissions. Convenience paths do not inherit Scene capabilities.

### Scene

```js
{
    request: "scene",
    mode: "peek",             // compact | peek | expanded
    width: 320,                // optional hint
    height: 200,               // optional hint
    ttl: 1800,                 // optional temporary lease
    notificationPolicy: "keep" | "suspend" | "resume",
    context: { ... }
}
```

Scene width/height are hints; the active skeleton owns final layout and geometry.

### Notification

```js
{
    request: "notification",
    type: "javaVersionSwitch",
    ttl: 3200,
    payload: { ... }
}
```

The Bridge produces only:

```js
{ type, ttl, payload }
```

Notification producers cannot request mode, width, height, split, reservation, or scene policy. Those fields are ignored. `ttl` defaults to 3000 ms; persistent state belongs in a Widget instead.

Notifications may be displayed by Compact or Peek. Delivery can be suspended by scene policy; remaining TTL is preserved and later Notifications queue FIFO.

### Widget

```js
{
    request: "widget",
    widgetId: "musicTrack",
    operation: "patch",       // patch | reset
    patch: { paused: true }
}
```

Widget requests update persistent Widget state and cannot request presentation or geometry.

### Clear

```js
{ request: "clear" }
```

`clear` removes transient scene/notification state and deterministically returns to Compact / `IdleContent.qml`. Widget state is retained.

## Ownership

`IslandController` owns:

```text
presentation + scene context
active Notification + TTL + suspension + FIFO queue
persistent Widget state
```

Scene skeletons own:

```text
composition and layout
final geometry / reservation request
split decision
scene-specific presentation policy
```

Notification/Widget components own only their visual representation and semantic interaction intents.

There is no global `compactMaximumWidth -> Peek` rule. Presentation changes are scene policy.

## Scene skeleton interface

Inputs:

```qml
property var notificationData
property var sceneContext
property var widgetStates
property var islandContext
```

Optional outputs:

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

Scenes do not receive `IslandController`, `PluginService`, or Dank Bar objects. Presenter translates their signals.

## Notification interface

Input:

```qml
property var notificationData
```

Hints:

```qml
readonly property real minimumWidthHint
readonly property real preferredWidthHint
readonly property real preferredHeightHint
readonly property string preferredSideHint
readonly property string animationHint
readonly property bool interactive
```

A Notification never requests island geometry, split, reservation, or presentation. The registry resolves its semantic `type` to a component.

## Widget interface

Inputs:

```qml
property string presentation
property var widgetState
```

Hints:

```qml
readonly property real minimumWidthHint
readonly property real preferredWidthHint
readonly property real preferredHeightHint
readonly property bool interactive
```

Typical intents:

```qml
signal activated()
signal statePatchRequested(var patch)
signal actionRequested(string action, var payload)
```

Widgets do not decide island presentation or geometry; the hosting scene interprets their intents.

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

Notifications arriving during exclusive Music Peek are retained but not displayed. This is a scene-specific composition rule.

## Extension rules

Add a Notification: implement the Notification interface, register a semantic `type`, publish `request: "notification"`.

Add a Widget: implement the Widget interface, register a stable id, compose it from supported scenes.

Add another convenience path:

1. define one narrow `request` name/schema,
2. parse and validate it in `IslandEventBridge`,
3. convert it to canonical domain state owned by `IslandController`,
4. expose only resulting state needed by scenes.

Do not grow unrelated feature fields onto `scene`, and do not pass raw producer envelopes into Content.

## Reservation boundary

Compact geometry may dynamically grow Dank Bar reservation; Peek/Expanded keep only the initial idle footprint.

```text
scene geometry -> Presenter -> Window -> Daemon
              -> PluginService reservation -> IslandBarReservation -> Dank Bar
```

Content, Notifications, and Widgets never access this reverse path directly.
