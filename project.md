# LockIn Project Overview

## 1. What this app does
LockIn is an iOS SwiftUI productivity app that combines:
- A **single-card todo focus flow** (show one current task at a time)
- A **sleep mode** (ambient audio + daily journal + todo management)
- A **wake flow** triggered by notification route intent (slide-to-wake + spoken first-card guidance)

The app is designed so users move between evening wind-down and morning activation while keeping todo momentum.

## 2. Tech stack and runtime
- Language/UI: Swift + SwiftUI
- Persistence: SwiftData (`@Model`, `@Query`, `ModelContext`)
- Notifications: UserNotifications (`UNUserNotificationCenter`)
- Audio playback: AVFoundation (`AVAudioPlayer`)
- Text-to-speech: AVFoundation (`AVSpeechSynthesizer`)
- Deployment target: iOS 18.2 (from `LockIn.xcodeproj/project.pbxproj`)

## 3. App entry, navigation, and routing
### Entry point
- `LockIn/LockInApp.swift`

Key behavior:
- Creates `AppRouter` and `SystemSpeechService` as environment objects.
- Requests notification permission on init (`alert`, `sound`).
- Sets a custom notification delegate (`NotificationRouterDelegate`).
- Uses `router.root` to choose app root view:
  - `.todo` -> `SingleCardTodoView`
  - `.wakeFlow` -> `WakeFlowView`
- Installs a SwiftData container for `TodoItem` and `SleepJournal`.

### Routing model
- `LockIn/AppRouter.swift`

Types:
- `RootRoute`: `.wakeFlow`, `.todo`
- `LaunchIntent`: `.none`, `.alarm(notificationID: String?)`

Logic:
- `pendingIntent` setter auto-switches root to `.wakeFlow` when alarm intent arrives.
- `completeWakeFlow()` resets intent to `.none` and returns root to `.todo`.

### Notification-driven route handoff
- Implemented in `NotificationRouterDelegate` in `LockIn/LockInApp.swift`.
- On notification response: reads `userInfo["route"]`.
- If `route == "wakeflow"`, sets `router.pendingIntent = .alarm(...)` on main thread.
- This provides app-level deep-link behavior from local notification tap -> WakeFlow.

## 4. Feature set (current)
### A. Single-card todo focus
- `LockIn/SingleCardTodoView.swift`

User experience:
- Shows one current focus card (`first` todo where `isDone == false`).
- Complete action marks current item done and persists.
- If all done: displays completion state and button to reset sample todos.
- Includes navigation to todo overview and sleep mode.
- Includes debug action that schedules a wakeflow-routed notification.

Core functions:
- `currentTodo`: selects first unfinished item.
- `complete(todo:)`: marks done + save.
- `scheduleDebugWakeFlowNotification()`: posts local notification with `userInfo["route"] = "wakeflow"`.

Startup behavior:
- `.task { TodoStore.seedIfNeeded(...) }` seeds sample data only when empty.

### B. Todo overview management
- `LockIn/TodoOverviewView.swift`

User experience:
- Two list sections: `To do` and `Done`.
- Inline title editing via `TextField` with draft buffering.
- Move/reorder for active todos.
- Mark done and restore from done.
- Add new todo from toolbar (or inline controls when embedded in sleep sheet).
- Can run as full navigation screen or embedded sheet mode (`showsNavigationActions`).

State and commit model:
- `draftTitles: [UUID: String]` stores unsaved edits.
- Drafts commit:
  - on submit
  - on row disappear
  - on view disappear
  - on `commitToken` change (used by sleep-mode sheet “Done” button)

Core functions:
- `move(from:to:)`: reassigns `orderIndex` sequentially and saves.
- `addTodo()`: appends with max `orderIndex + 1`.
- `markDone(_:)`: commits draft, flips `isDone`, saves.
- `restore(_:)`: commits draft, flips to active and appends to end of active list.
- `commitDraftIfNeeded(for:)` and `commitAllDrafts()` handle title trimming + persistence.

### C. Sleep mode
- `LockIn/SleepModeView.swift`

User experience:
- `Music` section: Play/Pause ambient sleep track.
- `Sleep Journal` section: text editor for daily note.
- `Manage Todos` section: opens a sheet with editable todo overview.
- Done button closes mode and persists data.

Data behavior:
- Queries one `SleepJournal` for current day start (`Calendar.current.startOfDay(for:)`).
- On appear: loads existing journal text.
- On disappear and Done: saves trimmed journal content and stops audio.
- Uses upsert-like logic:
  - update existing day journal if present
  - otherwise insert new journal entry for today

Embedded manage-todos sheet:
- Internal `ManageTodosSheet` hosts `TodoOverviewView(showsNavigationActions: false, commitToken: ...)`.
- Sheet “Done” increments `commitToken` before dismiss to force draft commit.

### D. Wake flow
- `LockIn/WakeFlowView.swift`

User experience:
- Morning screen with plan text.
- Slide-to-wake control with drag threshold confirmation.
- After successful slide:
  - marks awake state
  - returns app to todo root (`router.completeWakeFlow()`)
  - queues TTS playback of first-card guidance text

Speech behavior:
- Uses `SystemSpeechService` from environment.
- `pendingSpeak` + `scenePhase == .active` gate speaking.
- Speaks after short delay (0.25s) to avoid lifecycle timing issues.
- Voice language currently `zh-CN`.

Core functions:
- `confirmAwake(maxOffset:)`
- `scheduleSpeakIfPossible()`

### E. Audio and speech services
- `LockIn/SleepAudioPlayer.swift`
  - Loads bundled `sleep_music.mp3`.
  - Exposes `play()`, `pause()`, `stop()`.
- `LockIn/SpeechService.swift`
  - `SpeechService` protocol + `SystemSpeechService` implementation.
  - Configures `AVAudioSession` for spoken audio (`duckOthers`, `interruptSpokenAudioAndMixWithOthers`).
  - Stops any current utterance before speaking new text.

### F. Alarm test utility view
- `LockIn/AlarmTestView.swift`
- Standalone test screen with `Schedule Test Alarm` button.
- Schedules route-tagged local notification (`route = wakeflow`).
- Not wired as root currently, but useful for manual verification.

## 5. Data model and persistence
### `TodoItem` (`LockIn/TodoItem.swift`)
Fields:
- `id: UUID`
- `title: String`
- `orderIndex: Int`
- `isDone: Bool`
- `createdAt: Date`

Usage:
- Ordered list rendering and current-focus selection.
- State toggling between active/done.

### `SleepJournal` (`LockIn/SleepJournal.swift`)
Fields:
- `date: Date` (day start key)
- `content: String`
- `createdAt: Date`

Usage:
- One journal entry per calendar day (enforced by query/update logic, not schema constraint).

### Seed/store helper
- `LockIn/TodoStore.swift`

Functions:
- `seedIfNeeded(in:)`: inserts 3 sample todos if table empty.
- `resetSampleTodos(in:)`: clears all todos then re-inserts samples.

Default sample todos:
1. Review today’s plan
2. Start first 25-min lock-in
3. Drink water and stretch

## 6. View and function map
### Root views
- `SingleCardTodoView`: default app home for focus execution.
- `WakeFlowView`: notification-routed wake confirmation.

### Secondary views
- `TodoOverviewView`: full list management/edit/reorder.
- `SleepModeView`: evening routine + journaling + embedded todo management.
- `ManageTodosSheet` (private in `SleepModeView.swift`): sheet wrapper for overview.
- `AlarmTestView`: manual notification routing test harness.

### Unused starter template
- `LockIn/ContentView.swift` is default Xcode starter UI and currently not used by app routing.

## 7. Git history summary (feature evolution)
Recent commits indicate this progression:
1. `8209858` feat: local alarm notification with sound
2. `489465b` feat: wake flow slider confirm + TTS
3. `63e8bdc` feat: route from alarm notification to wakeflow
4. `4fadc46` fix: app routing for wakeflow
5. `bf2d693` fix: SleepMode todo button freeze

Interpretation:
- The app evolved from basic notifications -> wake interaction -> deep-link routing -> stability fixes around routing and sleep-mode todo management.

## 8. Current backlog
From `LockIn/BACKLOG.md`:
- Improve slider tracking feel (+10%)
- Improve TTS voice quality (voice selection + rate tuning)

## 9. Known implementation notes
- Many persistence calls use `try? modelContext.save()` (errors currently swallowed).
- `SleepJournal` daily uniqueness is handled in app logic, not a strict DB uniqueness rule.
- WakeFlow calls `router.completeWakeFlow()` immediately after confirm, so root can switch back quickly while TTS is queued using lifecycle guards.
- Notification permission result is not surfaced to UI.

## 10. Directory snapshot
Top-level:
- `LockIn/` app source and assets
- `LockIn.xcodeproj/` Xcode project

Primary app files:
- App/bootstrap: `LockIn/LockInApp.swift`, `LockIn/AppRouter.swift`
- Core views: `LockIn/SingleCardTodoView.swift`, `LockIn/TodoOverviewView.swift`, `LockIn/SleepModeView.swift`, `LockIn/WakeFlowView.swift`
- Models/store: `LockIn/TodoItem.swift`, `LockIn/SleepJournal.swift`, `LockIn/TodoStore.swift`
- Services: `LockIn/SleepAudioPlayer.swift`, `LockIn/SpeechService.swift`
- Support/test: `LockIn/AlarmTestView.swift`, `LockIn/BACKLOG.md`
