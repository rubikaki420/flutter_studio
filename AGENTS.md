# flutter_studio — Flutter IDE for Android (Termux Fork)

Flutter-based IDE for Android (package: `com.vault.fide`) with a **custom Termux fork** backend at `/data/data/com.vault.fide/files/usr/`. Uses a custom code editor (`CodeForge`) with LSP support, native terminal view from the Termux fork, and Gradle-based APK builds via the Termux SDK.

## ⚠️ CRITICAL: Development Environment Constraints

- **This project does NOT run on the current device.** The project is developed/edited here but deployed to a separate Android device via APK.
- **Do NOT attempt to run, test, or build this project on this machine** — Flutter/Dart SDKs are not available in this Termux environment.
- **Do NOT use `com.termux` anywhere.** The Termux fork uses package name `com.vault.fide` exclusively. All paths, constants, and environment variables must reference `com.vault.fide`.
- The Termux fork uses a **custom bootstrap zip** (not the official Termux bootstrap). Do not reference or assume official Termux bootstrap paths.
- All environment paths must use `/data/data/com.vault.fide/files/usr/` as the prefix. Never use `/data/data/com.termux/`.

---

## Architecture Overview

```
main.dart
  └─ LanguageRegistry.register(FlutterLanguage)  // only registered language
  └─ MyApp → IntroGate → HomeActivity
                              ├─ Create Project → EditorPage(language, workspace)
                              └─ Open Project  → EditorPage(language, workspace)

EditorPage (stateful, single entry)
  ├─ EditorContext (central context object, passed everywhere)
  ├─ EditorAppbar (action chips: Undo, Redo, Save, Run, HotReload, HotRestart, Stop, Sync, Build)
  ├─ EditorSidebar (nav + panel: Explorer)
  ├─ EditorTabbar (file tabs)
  ├─ CodeForge (custom code editor widget, ~4435 lines)
  └─ EditorBottomPanel (resizable, tabbed: Terminal(s), WebPreview)

FlutterLanguage.initialize()
  ├─ Creates FlutterLanguageState (ChangeNotifier for isAppRunning/isAppLaunched)
  ├─ Creates TerminalSessionManager
  │     └─ createSession('Flutter Output', id='editor.terminal.output_window')
  │           └─ TerminalBottomItem → AndroidView(com.vault.fide/terminal_view)
  └─ (registered later:) getAppbarActions → [Undo, Redo, Save, Run, HotReload, HotRestart, Stop, Sync, Build]
                         getBottomItems  → [WebPreview]
                         getSidebarItems → [ExplorerNavItem, ExplorerPanel]
```

---

## Key Files & Roles

### Entry & Theme
| File | Role |
|------|------|
| `lib/main.dart` | App entry, registers `FlutterLanguage`, loads icon fonts, sets dark Catppuccin theme |
| `lib/core/utils/app_colors.dart` | Catppuccin Mocha palette + VSCode-like UI colors |

### Termux Environment (Critical Fix)
| File | Role |
|------|------|
| `lib/core/termux_env.dart` | **Central PATH/env fix.** Prefix: `/data/data/com.vault.fide/files/usr`. Full PATH includes `$PREFIX/bin`, Android SDK tools, platform-tools, build-tools 36.1.0, Flutter bin, CMake 4.1.2. Sets JAVA_HOME (Java 21), ANDROID_HOME, HOME, TMPDIR, TERM. Wraps all `dart:io` Process calls via `bash -l executable [args]` so login profiles source the correct PATH. Methods: `TermuxEnv.start()` (returns Process), `TermuxEnv.run()` (returns ProcessResult). |

### Editor Context & Plugin System
| File | Role |
|------|------|
| `lib/core/editor_context.dart` | Central context object: workspaceDirectory, currentFilePath, language, registries, active controllers, onOpenFile callback, BuildContext, showMessage() |
| `lib/core/language/language.dart` | Abstract `Language`: languageId, executable/args for LSP, initialize(), getAppbarActions(), getBottomItems(), getSidebarItems(), startLsp(), createProject(), dispose(). Default actions: [Undo, Redo, Save]. |
| `lib/core/language/language_registry.dart` | Static registry: register(), getById(), getByExtension(), initializeAll(), disposeAll() |
| `lib/core/language/flutter/flutter_language.dart` | `FlutterLanguage` — the **only** registered language. LSP: `dart language-server --protocol-lsp`. Creates TerminalSessionManager + "Flutter Output" session in initialize(). Registers 7 custom appbar actions + 3 base actions. |

### Appbar Action Lifecycle
| File | Role |
|------|------|
| `lib/core/appbar_actions/appbar_action_item.dart` | Abstract action: `prepare()` → `canExecute()` → `execute()` → `postExecute()`, orchestrated by `run()`. Properties: id, label, icon, order, visible, enabled, requiresUIThread, subtitle. |
| `lib/core/appbar_actions/standard_actions.dart` | Built-in: `UndoAction`, `RedoAction`, `SaveAction` |

### Appbar Actions (Flutter)
| File | Command | Pattern Watched |
|------|---------|-----------------|
| `appbar/run_project.dart` | `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0` | `is being served at`, `No command flutter found` |
| `appbar/build_project.dart` | `flutter build apk --debug` or `--debug --split-per-abi` | `Built build`, `appbundle written`, `No command flutter found`, `Error:` |
| `appbar/hot_reload.dart` | Sends `'r'` to running terminal | — |
| `appbar/hot_restart.dart` | Sends `'R'` to running terminal | — |
| `appbar/stop_project.dart` | Sends `'q'` to running terminal | — |
| `appbar/sync_project.dart` | `flutter pub get` | — |

### Registries (UI Component Framework)
| File | Role |
|------|------|
| `lib/core/appbar_actions/appbar_actions_registry.dart` | Abstract: registerAction, unregisterAction, findAction, getActions, ActionExecListener |
| `lib/core/appbar_actions/appbar_actions_registry_impl.dart` | `ChangeNotifier`-based implementation |
| `lib/core/bottom_bar/bottom_item.dart` | Abstract: id, title, icon, build(), onSelected/Unselected, prepare(), dispose() |
| `lib/core/bottom_bar/bottom_registry.dart` | Abstract: registerItem, unregisterItem, selectItemById, findItem, getItems |
| `lib/core/bottom_bar/bottom_registry_impl.dart` | `ChangeNotifier`-based, `_selectedItemId` |
| `lib/core/sidebar/sidebar_registry.dart` | Abstract: register/unregister contributions, getNavItems, getPanels |
| `lib/core/sidebar/sidebar_registry_impl.dart` | `ChangeNotifier`-based |
| `lib/core/sidebar/sidebar_state_controller.dart` | Abstract: isSidebarVisible, activeNavItemId, toggleSidebar() |

### Terminal System
| File | Role |
|------|------|
| `lib/core/terminal/session_manager.dart` | Creates/manages terminal sessions. `createSession()` → creates `TerminalBottomItem` + `TerminalSessionController`, registers in bottom registry, selects tab. `executeInSession(id, cmd)` → finds session, delegates to `terminalItem.executeCommand()`. |
| `lib/core/terminal/session_controller.dart` | Thin wrapper: `execute()` → `terminalItem.executeCommand()` |
| `lib/core/terminal/terminal_bottom_item.dart` | **Key file.** Bottom tab with `AndroidView(com.vault.fide/terminal_view)`. MethodChannel `com.vault.fide/terminal_control_$id`. Methods: `sendCommand` (writes to PTY), `watchPattern` (native-side regex matching), `clearPatterns`, `removePattern`. Queues commands if `_channel` is null, flushes on `onPlatformViewCreated`. |

### Native Bridge (MethodChannel)
| File | Role |
|------|------|
| `lib/core/service/native_bridge.dart` | Static `MethodChannel('com.vault.fide/channel')`: `openTermuxActivity()`, `openLanguageInstaller()` |

### Services
| File | Role |
|------|------|
| `lib/core/service/app_start_service.dart` | First-launch init: `apt update` + installs dart/flutter/nodejs/python/gcc/g++/lua-ls via TermuxEnv.run(). Tracks state in SharedPreferences. |
| `lib/core/service/permission_service.dart` | Requests `notification` + `manageExternalStorage` with rationale dialogs |

### LSP Framework
| File | Role |
|------|------|
| `lib/LSP/lsp.dart` | Core LSP config (1563 lines). Handles: initialize, open/close/change/save, completions, hover, signatureHelp, goto-def, references, semantic tokens, folding, formatting, rename, code actions, document symbols, call/type hierarchy, inlay hints, colors, links. Defines CompletionItemType, LspClientCapabilities, LspCompletion, LspSemanticToken, semantic token mapping. |
| `lib/LSP/lsp_stdio.dart` | `LspStdioConfig` — starts LSP process via `TermuxEnv.start()` with Termux environment. Parses `Content-Length` headers, JSON-RPC messaging. |
| `lib/LSP/lsp_socket.dart` | `LspSocketConfig` — WebSocket-based LSP transport |
| `lib/LSP/language_server_manager.dart` | `LanguageServerManager` — acquires/releases LspStdioConfig per workspacePath, caches instances, provides `isRunning()` |

### CodeForge (Custom Editor)
| File | Lines | Role |
|------|-------|------|
| `lib/code_forge/controller.dart` | ~1695 | `CodeForgeController` — rope-based text manipulation, undo/redo bridge, multi-cursor, selection, folding, LSP integration (semantic tokens, diagnostics, completions, hover), minimap state |
| `lib/code_forge/code_area.dart` | ~4435 | `CodeForge` widget — rendering, syntax highlighting overlays, multi-cursor, folding, LSP popups (completions, signature help, hover tooltips), minimap, find/replace overlay, inline diagnostics, line numbers/gutter |
| `lib/code_forge/rope.dart` | ~1274 | Custom `Rope` — balanced binary tree of string chunks, BiDi text, UTF-16/Unicode offset mapping |
| `lib/code_forge/styling.dart` | ~1980 | `CodeEditorTheme` + 7 built-in themes (vs2015, anOldHope, monokaiSublime, github, dracula, oneDarkPro, catppuccin) |
| `lib/code_forge/syntax_highlighter.dart` | ~1300 | `SyntaxHighlighter` — re_highlight regex + LSP semantic token overlay, grammar caching, isolate-based async parsing |
| `lib/code_forge/scroll.dart` | ~243 | Custom 2D viewport + `Render2DCodeField` |
| `lib/code_forge/find_controller.dart` | ~312 | `FindController` — regex/case/whole-word search state |
| `lib/code_forge/undo_redo.dart` | ~600 | `EditOperation` sealed class (Insert/Delete/Replace/MultiOperation), `UndoRedoController` with group batching |

### Android Native (Java/Gradle)
| File | Role |
|------|------|
| `android/app/src/main/java/com/vault/fide/MainActivity.java` | FlutterActivity + MethodChannel `com.vault.fide/channel`. Registers `TerminalViewFactory` as `com.vault.fide/terminal_view`. Handles `openTermuxActivity`, `openLanguageInstaller`. |
| `android/app/src/main/java/com/vault/fide/TerminalViewFactory.java` | Factory returning `TerminalPlatformView` |
| `android/app/src/main/java/com/vault/fide/TerminalPlatformView.java` | PlatformView with MethodChannel, TermuxService binding, PTY stdin write, terminal session create/list/remove, resize handling, pattern watching |
| `android/app/build.gradle.kts` | minSdk 26, targetSdk 28, buildTools 36.1.0, ndk 29.0.14206865, Java 17, core desugaring |
| `android/build.gradle.kts` | allprojects repositories, custom `buildDir = ../../build` |
| `android/settings.gradle.kts` | AGP 8.11.1, Kotlin 2.2.20, includes: `:app`, `:termux:termux-application`, `:termux:terminal-emulator`, `:termux:terminal-view`, `:termux:termux-shared` |

### Project Creation
| File | Role |
|------|------|
| `home_activity.dart` | Home screen with action cards: Create/Open project, Open Terminal. Uses `LanguageRegistry.all.first` (always FlutterLanguage). |
| `flutter_create_project_dialog.dart` | Name + package name dialog |
| `flutter_project_creation_progress_dialog.dart` | Progress dialog, runs `TermuxEnv.start(TermuxEnv.templateCreateBin, [name, pkg])` |

---

## Data Flow: Build Button → Terminal Output

```
User taps Build
  → _ActionChip._handleTap()
    → setState(_running = true)                    // spinner on button
    → action.run(context)
      → action.execute(context)
        → _showBuildDialog(ctx)                    // AlertDialog with ChoiceChips
        → lang.state?.setAppRunning(true)          // disables other run actions
        → terminal.watchPattern('Built build',...) // register native pattern callbacks
        → terminal.watchPattern('Error:',...)
        → sessionManager.executeInSession(
            'editor.terminal.output_window',
            'cd $workspace && clear && flutter build apk --debug'
          )
          → findSessionById(id)                    // finds from _sessions list
          → session.execute(command)
            → terminalItem.executeCommand(cmd)
              → if _channel != null:
                  MethodChannel('com.vault.fide/terminal_control_$id')
                    .invokeMethod('sendCommand', {'command': cmd})
                else:
                  _pendingCommands.add(cmd); return  // queued
        → bottomRegistry.selectItemById(terminalId) // switch to terminal tab
        → actionsRegistry.refresh()
    → finallY: _running = false                     // spinner off
```

**Native side receives `sendCommand`:**
- `TerminalPlatformView` gets method call
- Writes `command + "\n"` to PTY stdin
- Native terminal shell (bash -l) executes it
- PTY stdout is rendered in the `AndroidView`

**Pattern watching (build result detection):**
- Native terminal regex-matches output against registered patterns
- On match, calls back to Dart: `onTerminalTextMatched`
- Dart calls the `PatternCallback` (shows success/failure snackbar, resets isAppRunning)

---

## Data Flow: LSP Startup → File Open → Diagnostics

```
User opens file (tap in explorer or editor)
  → EditorPage._openFile(path)
    → widget.language.startLsp(workspacePath)          // if first file, starts LSP process
      → LanguageServerManager.acquire()
        → if cached: return existing LspConfig
        → else: LspStdioConfig.start('dart', ['language-server', '--protocol-lsp'])
          → TermuxEnv.start('dart', ['language-server', '--protocol-lsp'])
            → Process.start('/data/data/.../usr/bin/bash',
                ['-l', 'dart', 'language-server', '--protocol-lsp'],
                environment: TermuxEnv.environment)
            → process.stdout.listen(_handleStdoutData)  // parses JSON-RPC responses
            → process.stderr.listen(debugPrint)         // errors only to debug log
          → returns LspStdioConfig instance
        → caches in _instances[workspacePath]
        → returns config
    → CodeForgeController(lspConfig: lspConfig)         // constructor
      → async IIFE starts:
        1. lspConfig!.initialize()
           → sendRequest('initialize', {processId, rootUri, capabilities})
           → waits for response (10s timeout)
           → on success: sets isInitialized = true
        2. if openedFile != null: _openDocumentInLsp()
      → _lspResponsesSubscription = responses.listen(...)
          handles: diagnostics, code actions, semantic highlights

    → controller.text = content
    → Controller passed to EditorTabItem
    
    → CodeForge widget created (in editor_content.dart)
      → CodeForge.initState()
        → _controller.openedFile = widget.filePath      // triggers setter
          → setter: text = File(path).readAsStringSync() // reloads text from disk
          → setter: _openDocumentInLsp()                 // opens in LSP
            → if !isInitialized: return (silent skip!)  // ⚠️ RACE CONDITION
            → lspConfig!.openDocument(openedFile!)
              → sendNotification('textDocument/didOpen', ...)
              → server starts sending diagnostics via textDocument/publishDiagnostics
            → _lspReady = true
            → _fetchSemanticTokensFull()
            → fetchDocumentColors()
            → fetchLSPFoldRanges()

    → If IIFE's initialize() completes AFTER openedFile setter:
      → IIFE checks openedFile != null → true
      → calls _openDocumentInLsp() again                  // recovery from race
```

**How LSP responses reach the editor:**
- `_process.stdout → _handleStdoutData()` (lsp_stdio.dart:130)
  - Accumulates bytes, parses `Content-Length: N\r\n\r\n` headers
  - Decodes JSON body → adds to `_responseController.stream` (broadcast)
- `sendRequest()` listens on same stream, filters by `id`, returns matching response
- Controller's `_lspResponsesSubscription` listens on same stream for notifications:
  - `textDocument/publishDiagnostics` → updates `diagnosticsNotifier` → inline error markers
  - `workspace/applyEdit` → applies edits
  - `workspace/configuration` → responds with workspace config

**Potential LSP failures (silent):**
1. `dart` not in login shell PATH → process fails to start, error goes to `debugPrint`
2. `LanguageServerManager.acquire()` catches everything → returns `null`
3. `CodeForgeController` gets `lspConfig: null` → no LSP features
4. 10s timeout on initialize → TimeoutException caught by controller's catch block
5. `_openDocumentInLsp()` bails if `isInitialized` is false (race condition, but IIFE retries)

### LSP CLI Flag Fix (2026-06-10)
- **Bug:** LSP flag was `--protocol-lsp` (invalid) instead of `--protocol=lsp` (correct). Dart language server CLI uses `=` for flag values.
- **Fix:** Changed in `flutter_language.dart:51` from `--protocol-lsp` to `--protocol=lsp`.
- **Why it broke:** With `--protocol-lsp`, the Dart language server didn't recognize the flag and either failed silently or started without LSP protocol, so no `initialize` response was ever sent, causing the 10s timeout in `sendRequest()`.

---

## Termux PATH Problem & Fix

### The Problem
When Flutter's `dart:io` spawns a child process on Android, the child gets Android's system PATH — **not** the Termux fork's PATH. So commands like `apt`, `dart`, `flutter`, `python`, `node`, `npm` are all "not found".

### The Fix
- **`TermuxEnv`** wraps every `Process.start`/`Process.run` with `bash -l <executable> [args]` and passes a complete environment map.
- The `-l` (login shell) flag causes bash to source `/etc/profile` and `~/.bashrc`, which set the Termux fork PATH correctly.
- The `environment` map is also passed explicitly as a fallback (overrides Android defaults).

### Where TermuxEnv is used (all Process calls):
- `app_start_service.dart` — First-launch dependency installation
- `flutter_project_creation_progress_dialog.dart` — `flutter create`
- `language_server_manager.dart` — LSP process via `LspStdioConfig`
- `lsp_stdio.dart` — `TermuxEnv.start()` with executable/args

### Where TermuxEnv is NOT used (terminal view commands):
- All terminal-based commands (Build, Run, Sync, Pub Get) go through `MethodChannel.sendCommand` to the native `TerminalPlatformView`, which writes to the PTY of a shell that already has the correct PATH (since the Termux terminal shell sources profiles). These do NOT use `dart:io Process`.

---

## Common Issues

### Build/Run command sent but no terminal output
1. **`_channel` is null** — the `AndroidView` platform view hasn't been created yet. Commands are queued in `_pendingCommands` and flushed on `onPlatformViewCreated`. If the flush fails silently (fire-and-forget without await), commands are lost. Fix: ensure flush is awaited and errors caught (see `terminal_bottom_item.dart`).
2. **Session not found** — `executeInSession` throws uncaught `Exception`. The error is silently eaten by `_handleTap()`'s finally block. Fix: wrap in try-catch with user feedback (see `build_project.dart`).
3. **Native side** — `TerminalPlatformView.sendCommand` might not handle the command correctly. Check if `\n` is appended to the command string before writing to PTY.
4. **Wrong tab** — The terminal output goes to the "Flutter Output" tab. Ensure that tab is visible in the bottom panel and selected.

### Project creation fails
- `template-create` script not found at `$PREFIX/bin/template-create`
- Workspace directory (`/storage/emulated/0/AndroidIDEProjects/`) not writable

### APK build fails
- Missing Android SDK components (check TERMUX_PACKAGE_MANAGER)
- Outdated build-tools version in `TermuxEnv.path` (currently `build-tools/36.1.0`)
- Flutter SDK not installed or wrong channel

---

## Build System

### APK Build
```
android/settings.gradle.kts         ← includes :app + 4 termux subprojects
android/build.gradle.kts            ← custom buildDir
android/app/build.gradle.kts        ← minSdk 26, targetSdk 28, Java 17
  └─ depends on: termux-shared, termux-application, terminal-emulator, terminal-view
```

### CI
- **Branch:** `test` (push triggers CI)
- **Command:** `flutter build apk --debug`
- **Flutter/Dart:** Not available in this dev environment (Termux terminal)
- **Workflow:** GitHub workflow on `test` branch, merges to `main` after verification

### Gradle Notes
- `buildToolsVersion = "36.1.0"` (both in Gradle and in TermuxEnv path)
- `ndkVersion = "29.0.14206865"`
- `targetSdk = 28` (required for Termux fork exec() compatibility)
- Java 17 required (Alpine or OpenJDK)
- FlatDir libs + jitpack + scijava maven repos for dependencies

---

## Constraints
- **DO NOT modify** `android/termux/` — it's the Termux fork native source, included as Gradle subprojects. Any changes need to be made in the upstream Termux fork.
- **DO NOT use bare `Process.start`/`Process.run`** — always use `TermuxEnv.start`/`TermuxEnv.run` for `dart:io` process calls.
- **DO NOT add runtime install scripts** — the app has its own apt repo and first-launch installer (`app_start_service.dart`).
- Only `FlutterLanguage` is registered in `LanguageRegistry`. Adding new languages requires implementing a full `Language` subclass and registering in `main.dart`.
- The CodeForge editor is custom (~12000 lines total across all files). Do not replace with a package without understanding the full LSP integration.

---

## Git Workflow
- `test` branch → CI verification → merge to `main`
- Commit messages should be descriptive (e.g., `fix:`, `feat:`, `cleanup:`)

---

## File Count & Stats
- **62 Dart files** in `lib/`
- **4 native Java files** in `android/app/src/main/java/com/vault/fide/`
- **4 Termux subprojects** in `android/termux/`
- Largest files: `code_area.dart` (~4435 lines), `lsp.dart` (~1563 lines), `controller.dart` (~1695 lines), `styling.dart` (~1980 lines)

---

## Session Changelog

### 2026-06-10
- **Fix:** LSP CLI flag `--protocol-lsp` → `--protocol=lsp` in `flutter_language.dart:51`. The `=` sign is required by the Dart language server; without it the flag is unrecognized and the server fails silently.
- **Fix:** `terminal_bottom_item.dart:148-154` — pending command flush now correctly `await`s each `sendCommand` call with try-catch, preventing silent loss of queued terminal commands.
- **Fix:** `build_project.dart:121-130` — `executeInSession` wrapped in try-catch with user-facing error message and `isAppRunning` reset, instead of silently eating `Exception('Session not found')`.
- **Context:** AGENTS.md rewritten from scratch with full architecture, data flow diagrams (build + LSP), registry system, CodeForge editor overview, all file roles, and common failure points.
