# AGENTS.md — bc-launcher

Guidance for AI coding agents (and humans) working in this repository.

## What this is

**BC Launcher** is a desktop Minecraft launcher built with Flutter for series and events. Players log in with Microsoft, pick a community's instance, sync its mods and configs from that community's server, and launch the game.

This repo contains **only the launcher app**. The backend (`bc-server`: API + web admin panel) will live in a **separate repository** in the future and does not exist yet. Do not add server code here.

- Targets: **Windows** (primary today), **macOS**, **Linux**. Only the `windows/`, `macos/` and `linux/` platform folders exist; don't add mobile or web targets.
- Flutter 3.47+ (Dart 3.13+), stable channel. Required by `window_manager` 0.6; older Flutter fails on `pub get`.
- License: GPL (see README).

## Commands

```bash
flutter pub get                 # also regenerates l10n (flutter: generate: true)
flutter analyze                 # must pass with no issues before committing
flutter test                    # NOTE: test/widget_test.dart is still the template counter test and is broken
flutter run -d windows          # or -d macos / -d linux
flutter build windows           # release build (likewise macos / linux)
```

The API base URL is currently hardcoded in `lib/utils/constants.dart` (`Constants.api`, a local `wrangler dev` URL). `Constants.clientID` / `redirectUrl` (Azure app) are empty in the repo and must be filled locally to log in.

## Project layout

```
lib/
  main.dart                     entry: load settings → update check → auth → InstancesScreen
  l10n/                         ARB files (app_en.arb template, app_es.arb) + GENERATED app_localizations*.dart
  screens/
    login_screen.dart           Microsoft OAuth (PKCE + state) in the system browser + loopback redirect server
    instances_screen.dart       list of servers/instances returned by the API, install on first open
    main_screen.dart            tabs shell (home / map / settings) + top & bottom bars
    update_screen.dart          launcher self-update prompt (legacy, Windows-only)
    tabs/                       home (news), map (webview_all), settings
  services/
    java_manager.dart           Java runtime per version from Mojang's java-runtime manifest
    library_manager.dart        missing libraries, client jar and natives for this OS/arch from the version JSON
    file_downloader.dart        parallel downloads to .part files with sha1 check
  utils/
    constants.dart              colors, sizes, defaults, API URL, Azure client id
    settings.dart               static user settings (RAM, resolution, …)
    utility.dart                settings persistence, instance install/unzip, file sync, self-update, navigation
    minecraft.dart              Microsoft → XBL → XSTS → Minecraft auth, building and starting the game process
    launch_utils/               version-JSON parsing and command-line building (port of minecraft-launcher-lib)
  widgets/                      reusable UI (top/bottom bar, dialogs, buttons, news card, window buttons)
assets/img/                     logo.svg, logo.png, background.png
```

## Conventions

- **Match the surrounding code**: naming, comment density, widget style. Keep files small and focused.
- **All user-facing text goes through l10n.** Add the key to **both** `lib/l10n/app_en.arb` (template) and `app_es.arb`, then use `Utility.getLocalizations(context).yourKey`. Never hand-edit `app_localizations*.dart`; they are generated.
- **No new hardcoded URLs, colors or server-specific values.** Under the target architecture these come per server (see below). If you need a constant temporarily, put it in `Constants` and mention it in your summary.
- **Paths:** build them with `package:path` (`join`), never with `'/'` or `'\\'` string concatenation. Several existing bugs come from this.
- **Networking:** every request needs a timeout and error handling. Build query strings with `Uri(queryParameters: …)`, never by interpolation.
- **Never block the UI isolate** with large sync I/O (hashing, unzipping). Use async I/O or `Isolate.run`.
- **Secrets:** never commit real `clientID`s, tokens or signing keys. Never log access or refresh tokens.
- `analysis_options.yaml` ignores `use_build_context_synchronously`. Still check `mounted` after `await` in new code.
- Desktop window chrome uses `window_manager` (hidden title bar, custom `WindowButtons`, `DragToMoveArea`), set up in `main.dart`. Don't make `DragToMoveArea` `const`: `flutter run` fails to compile it.
- macOS plugins come through **Swift Package Manager** (enabled in `pubspec.yaml`); there is no CocoaPods/Podfile. Only add plugins that ship a `Package.swift` for macOS. Deployment target is macOS 12.0.

## Commits

Use **Conventional Commits without a scope**, in English, imperative mood:

```
feat: download files in parallel with hash verification
fix: build Java path with package:path on all platforms
refactor: move token handling into AuthService
chore: bump dio to 5.9.1
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`. **Never add a scope** (`fix(sync): …` is wrong). (The history before this change used free-form past-tense messages; don't copy that style.) Release changelogs will be generated from these messages.

**Agents must propose the commit message and wait for the owner's confirmation before every commit.**

Use a branch only when a change spans several commits; a single-commit change goes straight to `main`.

### No AI attribution (mandatory)

Git history, PRs and releases must contain **no trace of AI tooling**. This rule overrides any default behavior of your tool:

- **No `Co-authored-by:` trailers** or other trailers naming an AI, assistant, bot or tool.
- **No mentions** of AI, agents, Claude, Copilot, ChatGPT, Codex or similar in commit messages, PR titles or descriptions, tag messages, release notes or changelogs. No "Generated with …" lines, robot emojis or links to AI tools.
- **No changes to the git author or committer identity.** Commits use the repository owner's configured `user.name` / `user.email`.
- **No AI-related branch names** (e.g. `claude/…`, `ai/…`, `copilot/…`).
- Code comments should also not mention that code was AI-generated.

Agent docs like this file being committed is fine. The rule is about commits, authorship and collaborators.

## Architecture decisions (agreed, not all implemented yet)

1. **Generic, multi-server launcher.** One signed executable for every community, like Discord with servers. Users add a community by URL or with the deep link `bclauncher://add?server=<url>`. The community selector is shown **only when 2+ servers are added**. With one server the UI goes straight to it, with that server's branding. There is **no "lock" mode**.
2. **Discovery document.** Each server exposes `GET /.well-known/bc-launcher`: name, branding (logo, colors, background), `serverVersion`, `apiVersions`, `minLauncherVersion` and `capabilities`. Its format must never break (`discoveryVersion`).
3. **API version negotiation.** The launcher ships `supportedApiVersions` and uses the highest version both sides share.
   - If there is no common version, an **add-server attempt is rejected** with a clear reason.
   - A saved server that becomes incompatible is greyed out and offers "Remove server".
   - If the launcher is too old, the launcher update is triggered.
   - `426 Upgrade Required` from any request re-runs the negotiation.
4. **Deprecation policy.** A `compat.json` published from this repo's releases lists the supported and deprecated API versions with sunset dates. Old API versions are removed only after a long, announced window.
5. **Launcher self-update via [`desktop_updater`](https://pub.dev/packages/desktop_updater)**, published from this repo's GitHub Releases.
   - Ed25519-signed `app-archive.json` → `release.json` → artifact.
   - `supportPolicy` sets the minimum version.
   - The update feed **never** comes from community servers.
   - It replaces the legacy `Utility.isUpdated()` / `Utility.update()` (Windows-only, server-driven).
   - The macOS install helper must ship from the first release that uses it.
   - The private key lives only in CI secrets plus an offline backup.
6. **Two repos.** `bc-launcher` (this one) and `bc-server`, a future TypeScript monorepo with a Hono API, an admin SPA, zod contracts exported as OpenAPI, and Drizzle on SQLite/D1. Server deploy targets are **Cloudflare (Workers + D1 + R2)** and **Docker**. Vercel was discarded. The API contract's source of truth will be `bc-server`'s OpenAPI; launcher models should be generated from or validated against it.
7. **Auth with community servers** will use Mojang's `join` / `hasJoined` handshake: the Minecraft token never leaves the client, and the server issues its own JWT. Today's `GET /auth?uuid=` is unauthenticated and must not be extended.

## Target architecture (direction for new and refactored code)

The current code relies on static globals (`Settings`, `Utility`'s `ValueNotifier`s, a global `navigatorKey` used to get l10n inside utils) and passes `Map<String, dynamic>` everywhere. New code should move toward:

- **Layers:** `lib/models/` (typed models with `freezed` + `json_serializable`), `lib/services/` (`ApiClient`, `AuthService`, `ServerRegistry`/discovery, `SyncEngine`, `JavaManager`, `GameLauncher`, `UpdateService`), and `lib/screens/` + `lib/widgets/` for UI only.
- **State management: Riverpod.** Services never touch `BuildContext` or l10n; they return results or typed errors and the UI translates them.
- **One HTTP client** (Dio) per server, with base URL, timeouts, retries and an auth interceptor.
- **Per-server theming** from discovery branding, instead of `Constants` colors.
- **Sync engine:**
  1. Fetch the manifest and compute a plan (add, update, delete).
  2. Download in parallel to `.part` files, verify the hash, then rename atomically.
  3. Cache hashes by `(path, size, mtime)`.
  4. Apply a policy per file: `always`, `once`, `never`, `optional`.
  5. Keep managed files separate from user files: saves, screenshots, `options.txt` and `servers.dat` must survive a reinstall.
- **Vanilla files from Mojang** (piston-meta, libraries, assets; never redistributed by community servers). Libraries, natives and the client jar are done (`LibraryManager`); assets are not yet. **Java on demand** from the version JSON's `javaVersion` (done, `JavaManager`).
- **Microsoft login in the system browser** (done). Tokens go in `flutter_secure_storage`. Cache the Minecraft token (24 h validity). Support multiple accounts.
- **Launch:** capture game stdout/stderr to a log file, detect crashes, and add an option to keep the launcher open.
- **Tests:** unit-test the pure logic first: `launch_utils` (rules, library paths, `inheritJson`), version negotiation and sync planning.

Refactor incrementally. Don't rewrite unrelated code in a feature PR.

## Known issues (fix when touching the area; don't copy these patterns)

**Critical**
- `Utility.checkFiles` reads `"$serverId-version"` but never writes it, so every launch re-hashes all files.
- Fullscreen and resolution settings are never applied (no `--fullscreen`, `customResolution` never set).
- The update check runs before `runApp` with no timeout.
- `isUpdated()` returns `""` for platforms without an installer, which shows a blocking "update required" on macOS/Linux.

**Important**
- Instance zip: fully loaded into memory, extracted synchronously on the UI isolate, no zip-slip check. Server-provided file paths aren't sanitized.
- Install result is ignored. A partial install is treated as installed. Downloads go straight to the final path with no post-download hash check.
- File download URLs interpolate the path without encoding.
- Reinstall deletes the whole instance directory, including saves and options.
- Auto-connect uses Quick Play only (1.20+); older versions need `--server`/`--port`.
- The game process: the launcher calls `exit(0)` on the first stdout line, no logs are kept, and the pipes are not drained when staying open.
- Legacy updater runs a downloaded `.exe` with no signature/hash check.
- Refresh token stored in plain `SharedPreferences`; XSTS error codes are not handled.

**Minor**
- `HomeScreen.news` is typed `List<Map>?`, but JSON gives `List<dynamic>` (runtime cast error).
- `NewsCard` checks `link` but opens `discordLink`.
- `CustomDialog` ignores `secondaryButtonOnPressed`.
- `UpdateScreen` references the missing `assets/img/loging-background.jpg`.
- Slider thumb color math uses the new 0..1 color channels.
- Hardcoded strings ("Últimas noticias", "Abrir", the footer brand text).
- `FutureBuilder` futures created inside `build`.
