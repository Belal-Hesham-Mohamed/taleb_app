# Graph Report - taleb  (2026-09-23)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 257 nodes · 329 edges · 19 communities (13 shown, 6 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d9c39b8a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- my_application.cc
- auth_interceptor.dart
- FlutterMacOS
- utils.cpp
- main.dart
- AppDelegate
- MessageHandler
- api_endpoint.dart
- manifest.json
- api_config.dart
- windows/flutter/generated_plugin_registrant.cc
- auth_tokens.dart
- MainActivity.kt
- app_config.dart
- b_taleb_taleb_ios_runner_generatedpluginregistrant_h

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `WindowClassRegistrar` - 7 edges
8. `_MyApplication` - 7 edges
9. `OnCreate` - 7 edges
10. `Destroy` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `MessageHandler` --references--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h
- `Create` --calls--> `Scale()`  [EXTRACTED]
  windows/runner/win32_window.h → windows/runner/win32_window.cpp

## Import Cycles
- None detected.

## Communities (19 total, 6 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.07
Nodes (49): dwmapi, FlutterViewController, RECT, unique_ptr, FlutterWindow, flutter_controller_, OnCreate, OnDestroy (+41 more)

### Community 1 - "my_application.cc"
Cohesion: 0.08
Nodes (26): FlPluginRegistry, flutter_linux, flutter_secure_storage_linux_plugin, FlView, GApplication, gboolean, gchar, gdkx (+18 more)

### Community 2 - "auth_interceptor.dart"
Cohesion: 0.07
Nodes (25): api_config.dart, Dio, FlutterSecureStorage, Interceptor, interceptors/auth_interceptor.dart, create, DioConfig, AuthInterceptor (+17 more)

### Community 3 - "FlutterMacOS"
Cohesion: 0.10
Nodes (16): Cocoa, Flutter, flutter_secure_storage_darwin, FlutterMacOS, FlutterPluginRegistry, FlutterSceneDelegate, Foundation, SceneDelegate (+8 more)

### Community 4 - "utils.cpp"
Cohesion: 0.13
Nodes (18): dart_project, flutter_view_controller, flutter_windows, functional, _In_, _In_opt_, io, iostream (+10 more)

### Community 5 - "main.dart"
Cohesion: 0.12
Nodes (16): build, _counter, createState, _incrementCounter, main, MyApp, MyHomePage, _MyHomePageState (+8 more)

### Community 6 - "AppDelegate"
Cohesion: 0.16
Nodes (10): Any, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, AppDelegate, Bool (+2 more)

### Community 7 - "MessageHandler"
Cohesion: 0.18
Nodes (10): generated_plugin_registrant, optional, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM (+2 more)

### Community 8 - "api_endpoint.dart"
Cohesion: 0.18
Nodes (9): ApiEndpoints, login, logout, refreshToken, register, accessToken, refreshToken, SecureStorageKeys (+1 more)

### Community 9 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 10 - "api_config.dart"
Cohesion: 0.29
Nodes (6): Duration, ApiConfig, baseUrl, connectTimeout, receiveTimeout, sendTimeout

### Community 11 - "windows/flutter/generated_plugin_registrant.cc"
Cohesion: 0.33
Nodes (4): flutter_secure_storage_windows_plugin, plugin_registry, PluginRegistry, RegisterPlugins()

### Community 12 - "auth_tokens.dart"
Cohesion: 0.40
Nodes (4): accessToken, AuthTokens, fromJson, refreshToken

## Knowledge Gaps
- **64 isolated node(s):** `flutter_controller_`, `project_`, `x`, `y`, `height` (+59 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 133 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `utils.cpp`, `MessageHandler`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Why does `OnCreate` connect `Win32Window` to `windows/flutter/generated_plugin_registrant.cc`, `MessageHandler`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Why does `MessageHandler` connect `MessageHandler` to `Win32Window`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `WndProc` (e.g. with `GetThisFromHandle` and `MessageHandler`) actually correct?**
  _`WndProc` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `flutter_controller_`, `project_`, `x` to the rest of the system?**
  _64 weakly-connected nodes found - possible documentation gaps or missing edges._