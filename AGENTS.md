# AGENTS.md — bc-launcher

Guidance for AI coding agents (and humans) working in this repository.

## What this is

**BC Launcher** is a desktop Minecraft launcher built with Flutter for series and events. Players log in with Microsoft, pick an instance from an organization they added, sync its mods and configs from that organization's server, and launch the game.

This repo contains **only the launcher app**. The backend (`bc-launcher-server`: API + web admin panel) lives in a **separate repository** ([elRubenof/bc-launcher-server](https://github.com/elRubenof/bc-launcher-server)). Do not add server code here.

- Targets: **Windows** (primary today), **macOS**, **Linux**. Only the `windows/`, `macos/` and `linux/` platform folders exist; don't add mobile or web targets.
- Flutter 3.47+ (Dart 3.13+), stable channel. Required by `window_manager` 0.6; older Flutter fails on `pub get`.
- License: GPL (see README).

## Commands

```bash
flutter pub get                 # also regenerates l10n (flutter: generate: true)
flutter analyze                 # must pass with no issues before committing
flutter test                    # unit tests in test/ (see Target architecture → Tests)
flutter run -d windows --dart-define-from-file=.env     # or -d macos / -d linux
flutter build windows --dart-define-from-file=.env      # release build (likewise macos / linux)
```

**Build configuration:** the Azure app's values are compiled in from a `.env` file (ignored by git). Copy `.env.example` to `.env` and fill in `MS_CLIENT_ID` (required to log in) and, optionally, `MS_REDIRECT_URL` (default `http://127.0.0.1`). They are read with `String.fromEnvironment` in `lib/utils/constants.dart` and fixed at build time, so `run` and `build` both need `--dart-define-from-file=.env`; without it the client ID is empty and the Microsoft login fails. `.vscode/` is ignored: any local launch or build configuration has to pass the same flag.

## Project layout

```
lib/
  main.dart                     entry: link listener → load settings and organizations → client ID check → auth
                                → NoOrganizationsScreen (none added) or OrganizationsScreen
  l10n/                         ARB files (app_en.arb template, app_es.arb) + GENERATED app_localizations*.dart
  models/                       API v1 models with fromJson/toJson: organization (from discovery), instance,
                                instance_colors, web_tab, manifest (+ its files), news; instance_settings (an
                                instance's game settings: only what the player changed, the rest its defaults,
                                RAM from the instance's recommended one and never more than the computer's)
  screens/
    no_organizations_screen.dart  shown until an organization is added (only through its link)
    organizations_screen.dart   column of organizations (2+) and the selected one's instances, or why they
                                can't be shown (no access, incompatible, offline); remove an organization (from
                                those screens or a right click on its logo in the column);
                                entering an instance (by click, or the last one used on start without showing
                                the list, unless turned off in Settings or its organization doesn't answer) opens
                                MainScreen; installed instances it no longer serves are listed last, greyed out,
                                newest installation first; while it doesn't answer, only the installed ones, as last
                                served, under a notice with "Retry"
    instance_loading_screen.dart  entering an instance: "Downloading / Installing / Updating <instance>" on the
                                LoadingScreen, and its errors (offline, no space, game files, instance gone); going
                                back from one forgets it as the last instance, so the next start shows the list
    login_screen.dart           Microsoft OAuth (PKCE + state) in the system browser + loopback redirect server;
                                "Sign in again" when Microsoft rejected the saved session
    account_error_screen.dart   why the account can't play (child without permission, no Xbox profile, country,
                                age verification, no Minecraft), fixed outside the launcher: Retry and Use
                                another account
    main_screen.dart            an installed instance: tabs (home, its web tabs, settings) + top & bottom bars (the
                                bottom one only on home); Play repairs,
                                updates and launches it; puts the instance's InstanceTheme on everything under it
                                and its background under its background color at 85 % (the launcher's if it has
                                none or it can't be loaded); on home, the offline notice while the organization
                                doesn't answer
    tabs/                       home (the instance's news, NewsCarousel), web tab (webview_all, for openIn: launcher; the
                                browser ones open from the top bar, marked ↗), settings
  services/
    api_client.dart             one organization's API v1: discovery and version negotiation, sign-in,
                                instances, manifest, news; token, retries, 401 renewal, 426 renegotiation; ApiError
                                with a type (offline, notMember, upgradeRequired, …) and the API's code
    deep_links.dart             bclauncher://add?server= links (app_links); registers the scheme on Windows/Linux
    organization_store.dart     the added organizations (SharedPreferences), keyed by Organization.key, the
                                selected one and each one's last used instance
    instance_manager.dart       what is on disk per instance, <AppSupport>/<organization key>/<instance id>/:
                                .bc-launcher/state.json (what is installed, the instance as last served and
                                when it was installed), its status against the server (not installed, update
                                available, up to date), the installed ones, deleting one instance or all of an
                                organization's (and cleaning the shared files); never sync, install or launch
    sync_plan.dart              what a sync does, without touching the disk: downloads, deletions (managed
                                folders, files the launcher installed), protected player files, unsafe paths
    sync_engine.dart            runs a sync: manifest (ETag, saved copy), free space, downloads with sha256,
                                deletions, installed.json; fetches the manifest again when its URLs expire
    instance_installer.dart     entering an instance and playing it: first time (download, then install the game
                                files), update, or check (sync and check the game files, which repairs); when the
                                organization doesn't answer, a complete installation is entered and played as it is,
                                without syncing (play says so: `offline`); when its list already failed
                                (`InstanceCatalog.isUnreachable`, any failure but 403 or incompatible, a 404 too),
                                it isn't asked at all, while a 404 for one instance whose list loads keeps it
                                blocked; state.json, servers.dat
                                entry (created once, address moved)
    server_list.dart            the game's servers.dat (NBT): create it, move one entry's address
    instance_catalog.dart       each organization's instances and status (ready, no access, incompatible, offline);
                                markOffline when it stops answering before playing
    token_store.dart            each organization's token in flutter_secure_storage (one entry for all)
    organization_auth.dart      sign-in to an organization: challenge → Mojang join → verify; clientFor()
    game_installer.dart         the game files of an instance ("Installing"): version JSON from Mojang, then
                                libraries, client jar, natives, assets and Java in one download (each manager's
                                plan of what is missing), so the bar follows the missing bytes; Fabric/Quilt
                                profile from their meta APIs; Forge/NeoForge through ForgeInstaller (the first
                                half of the bar when its installer has to run)
    forge_installer.dart        Forge 1.7.10+ and NeoForge 1.20.2+ with their official installer: its version JSON
                                and libraries, then its client processors (1.13+) run with Java; the files it puts
                                in the shared libraries/ (Forge's jar before 1.13, what the processors make) are
                                listed in the saved version JSON (bcLauncherGenerated), so the cleaning keeps them
                                and a missing one installs it again; older versions are UnsupportedLoaderError
    asset_manager.dart          the game's assets from Mojang (index and objects by hash), shared by every instance
    shared_files.dart           deletes the shared libraries and assets no installed instance uses (Forge's
                                generated files included)
    java_manager.dart           Java runtime per version from Mojang's java-runtime manifest
    library_manager.dart        missing libraries, client jar and natives for this OS/arch from the version JSON
                                (libraries optionally in the shared folder)
    file_downloader.dart        parallel downloads to .part files with sha1 or sha256 check; progress by the bytes
                                received, at most every 100 ms; PendingDownloads, a part's missing files and what
                                it does after
    game_process.dart           runs the game: its output to .bc-launcher/logs/<date>.log and its crash report
                                beside it, without the token (the 20 newest kept); how it ended (never started,
                                crashed by exit code or a new crash report)
    log_export.dart             the last game's log, crash report and info zipped for support; save dialog
    news_catalog.dart           an instance's news a page (20) at a time with the cursor; error kept until the next
                                load; an invalid cursor starts again from the first page
    credentials_store.dart      Microsoft OAuth credentials in flutter_secure_storage
    xbox_auth.dart              the XSTS step done here, so its XErr codes become an AccountProblem
    minecraft_session_store.dart  the player's profile and Minecraft token (renewed after 23 h) in
                                flutter_secure_storage, to start and play without internet
    instance_settings_store.dart  one instance's game settings (RAM, resolution, fullscreen, auto-connect) in
                                .bc-launcher/settings.json, written at once; reset deletes it
    update_config.dart          the launcher's update feed (this repo's latest GitHub release), the pinned release
                                keys, each platform's package ID and the recovery store's file
    update_recovery_store.dart  desktop_updater's pending install marker in <AppSupport>/update/, so the next
                                start knows whether the update finished
  utils/
    constants.dart              colors, sizes, defaults, releases URL, Azure app values from .env
    news_markdown.dart          a news body's markdown (package:markdown) as blocks and styled spans: headings, bold,
                                italic, lists, code, http(s) links; `_` is never italic
    instance_theme.dart         InstanceTheme (ThemeExtension): the instance's colors inside MainScreen, the
                                launcher's (Constants) anywhere else; its primary also themes switches and sliders
    global_settings.dart        the launcher's own settings, for every instance (keep it open, open the last one):
                                load, set and reset them in SharedPreferences
    system_memory.dart          the computer's total RAM (sysctl, /proc/meminfo, GlobalMemoryStatusEx by FFI)
    trusted_roots.dart          on Windows, adds the bundled Mozilla roots to the default SecurityContext on start
                                (Dart doesn't make Windows fetch the roots it is missing)
    utility.dart                localizations, navigation, launching/playing state
    minecraft.dart              Microsoft → XBL → XSTS → Minecraft auth, building and starting the game process;
                                without internet (a connection failure, never a rejection) it starts with the saved
                                session, `offline` is on (single player: no servers, Auto-Conectar off) and it
                                retries every 30 s; back online, the organizations are asked again
    launch_utils/               version-JSON parsing and command-line building (port of minecraft-launcher-lib)
  widgets/                      reusable UI (top/bottom bar, dialogs, buttons, news carousel (one at a time, read more,
                                loading the next page, retry; nothing without news or if they can't load) and its
                                body (whole, or its first 3 lines counting every block's, the one that doesn't fit
                                ending in "…"), window buttons,
                                full-screen error message, add-organization dialog opened by links,
                                organization logo and rail, instance initials (card and top bar without an icon),
                                the launcher's dropdown menus (LauncherMenu), instance
                                card with its menu, the offline notice (list and instance screen), instance actions (open
                                its folder, delete it from this computer), CustomButton, LoadingScreen with its own
                                or the global progress)
assets/img/                     logo.svg, logo.png, background.png
assets/certs/cacert.pem         Mozilla's root certificates (https://curl.se/ca/cacert.pem), updated before each
                                release
desktop_updater.yaml            the update feed's base URL, read by desktop_updater's release CLI
desktop_updater.keys.json       the release key profile: public keys only, bound to the feed URL; the private key
                                is never in the repo
test/                           unit tests mirroring lib/ (models, services, utils); fixtures/ holds API v1
                                responses shaped like the server's openapi.json, read with fixture();
                                services/fake_server.dart is an organization's server for sync tests
```

## Conventions

- **Match the surrounding code**: naming, comment density, widget style. Keep files small and focused.
- **All user-facing text goes through l10n.** Add the key to **both** `lib/l10n/app_en.arb` (template) and `app_es.arb`, then use `Utility.getLocalizations(context).yourKey`. Never hand-edit `app_localizations*.dart`; they are generated.
- **No new hardcoded URLs, colors or server-specific values.** Under the target architecture these come per server (see below). If you need a constant temporarily, put it in `Constants` and mention it in your summary.
- **Paths:** build them with `package:path` (`join`), never with `'/'` or `'\\'` string concatenation. Several existing bugs come from this.
- **Networking:** every request needs a timeout and error handling. Build query strings with `Uri(queryParameters: …)`, never by interpolation.
- **Never block the UI isolate** with large sync I/O (hashing, unzipping). Use async I/O or `Isolate.run`.
- **Secrets:** never commit `.env`, real `clientID`s, tokens or signing keys. New build-time values go in `.env.example` (empty) and are read with `String.fromEnvironment`. Never log access or refresh tokens.
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

1. **Generic, multi-organization launcher.** One signed executable for everyone, like Discord with servers. Each server deployment is one **organization** (a developer or organizer of series and events) with N **instances** (series, events, servers). Organizations are added **only with the deep link** `bclauncher://add?server=<url>` from the organization's download page (`https://` is added if missing); there is no field to type an address. Without organizations the launcher shows a screen asking the player to open their organization's link. The link **always asks for confirmation** ("Add <name>?", with its logo; the host is not shown) before anything is saved, because any website can fire it. The launcher registers the `bclauncher` scheme itself (macOS through `Info.plist`; Windows and Linux on start, so it works without an installer) and runs as a single instance: a link opened while it is running goes to the open window. Download buttons point to the official generic installer; after installing, the player clicks the link again. Adding an organization means trusting it: every instance it creates and opens to the player **appears automatically** (the launcher refreshes `GET /instances` on start and when returning to the app). The organization selector is shown **only when 2+ organizations are added**. With one organization the UI goes straight to it. There is **no "lock" mode**. UI wording: "organization", never "community".
2. **Discovery document.** Each server exposes `GET /.well-known/bc-launcher`: `discoveryVersion`, `visibility` (`public` | `private`), name, description, logo (the organization's only image), global links (Discord, web), `serverVersion`, `apiVersions`, `minLauncherVersion` and `capabilities`. It is the same for public and private organizations. The organization has **no colors or background**: those belong to each instance. Its format must never break (`discoveryVersion`).
   - `capabilities` are the optional features that server has, added to an API version after its release (e.g. `server-status`, `optional-mods`, `manifest-delta`), or ones its admin can turn off. Everything else in the API version is the baseline and is never announced. The launcher shows or uses a feature only when its capability is announced, hides it silently otherwise (no error, no probing for `404`, no `serverVersion` checks), and ignores capabilities it doesn't know. They describe the whole server; per-instance data (web tabs, news) comes from the instance's own fields. The rules for adding one are in `bc-launcher-server/AGENTS.md` → "Capabilities".
3. **API version negotiation.** The launcher ships `supportedApiVersions` and uses the highest version both sides share.
   - If there is no common version, an **add-organization attempt is rejected** with a clear reason.
   - A saved organization that becomes incompatible is greyed out and offers "Remove organization".
   - If the launcher is too old, the launcher update is triggered.
   - `426 Upgrade Required` from any request re-runs the negotiation.
4. **Deprecation policy.** A `compat.json` published from this repo's releases lists the supported and deprecated API versions with sunset dates. Old API versions are removed only after a long, announced window.
5. **Launcher self-update via [`desktop_updater`](https://pub.dev/packages/desktop_updater)**, published from this repo's GitHub Releases.
   - Ed25519-signed `app-archive.json` → `release.json` → artifact. The feed is `releases/latest/download/app-archive.json` and the release key is bound to that exact URL (`desktop_updater.yaml`, `UpdateConfig`); GitHub's flat release assets need the release CLI's low-level commands with explicit URLs.
   - Only **Windows** installs updates itself (zip, per-user Inno install). desktop_updater refuses to install on macOS without Developer ID signing and doesn't support AppImage, so **macOS and Linux** only notify and "Download" opens the release.
   - `supportPolicy` sets the minimum version.
   - Versions have no `+build` number (it is optional for zip, DMG and Inno).
   - The update feed **never** comes from organization servers.
   - Until then the launcher has no update check (the legacy, server-driven `Utility.isUpdated()` / `Utility.update()` were removed).
   - The private key lives only in CI secrets plus an offline backup.
6. **Two repos.** `bc-launcher` (this one) and `bc-launcher-server`, a TypeScript monorepo with a Hono API, a React + Vite + shadcn/ui admin panel (username + password admins; one `owner`, `admin` = everything except acting on the owner, `editor` = instances, content, news and players only), zod contracts exported as OpenAPI, and Drizzle on SQLite/D1. Server deploy targets are **Cloudflare (Workers + D1 + R2)** and **Docker**. Vercel was discarded. The API contract's source of truth is `bc-launcher-server`'s OpenAPI (`packages/contracts/openapi.json`, attached to each server release); launcher models should be generated from or validated against it.
7. **Auth with organization servers** uses Mojang's `join` / `hasJoined` handshake (done, `OrganizationAuth`): `POST /api/v1/auth/challenge` → the launcher calls Mojang's `join` with the returned `serverId` → `POST /api/v1/auth/verify`, which returns the server's own JWT. The Minecraft token never leaves the client. Discovery's `auth.type` is `mojang-session` or `unverified` (a Cloudflare server without a Mojang session proxy, which trusts the name). The old unauthenticated `GET /auth?uuid=` is gone from the launcher.
8. **Access in two levels.**
   - **Organization:** public (any Minecraft player) or private (only its whitelist). A non-member, or a player on the organization blacklist, gets `403 not_member` ("You don't have access to this organization"), never told it is a ban. Adding is rejected; a saved organization that loses access is greyed out with "You no longer have access" and "Remove organization", and comes back by itself if access returns.
   - **Instance:** `everyone` (all members) or its own whitelist, plus its own blacklist. An instance the player can't play is **invisible**: not listed, and its endpoints answer `404`. Inactive instances are hidden too.
   - Blacklists win over whitelists and public access. Bans can expire.
9. **Instances carry their own look and content.** Each instance has its background and colors (`primary`, `primaryDark`, `background`, `text`; new instances start with BC Launcher's defaults), its web tabs (up to 5 between Home and Settings, each with a label, an http(s) URL where the launcher replaces `{uuid}` and `{name}` with the signed-in player's, one of 10 icons and `openIn`: `launcher` shows it in a webview, `browser` opens the system browser without switching screens; they replace the old map), Discord and web links (falling back to the organization's), its news (there is no organization-wide news), its Minecraft version and loader, and a `contentVersion` counter. The launcher themes the UI with the selected instance's colors and uses its own neutral theme elsewhere.
10. **Content sync, no zip.** Installing = syncing the manifest into an empty folder (`<AppSupport>/<organization>/<instance id>/`); the instance `id` is readable and immutable.
    - Each instance folder holds its content, the player's files, its version JSONs, client jar and natives. Mojang's **libraries and assets are shared** in `<AppSupport>/libraries` and `<AppSupport>/assets` (they are stored by Maven path or hash, so the same path is always the same file), and so is Java (`<AppSupport>/runtime`). Removing an organization deletes the shared files no remaining instance uses; anything missing is downloaded again on the next installation.
    - The manifest lists `{path, sha256, size, policy, url}`, the managed dirs, the Minecraft version and the loader. Files are content-addressed and downloaded from short-lived signed URLs.
    - **The launcher installs the loader itself** from `loader {type, version}`: Fabric/Quilt from their meta APIs, Forge/NeoForge by running the official installer's processors, cached per loader version. The server never serves loader or vanilla files.
    - Managed dirs (set per instance, e.g. `mods/`): anything not in the manifest is deleted, including mods the player added. Elsewhere, the launcher keeps a local list of the files it installed and deletes only those removed from the manifest.
    - The admin applies content changes atomically, so a manifest is always complete.

## Target architecture (direction for new and refactored code)

The current code relies on static globals (`GlobalSettings`, `Utility`'s `ValueNotifier`s, a global `navigatorKey` used to get l10n inside utils) and passes `Map<String, dynamic>` everywhere. New code should move toward:

- **Layers:** `lib/models/` (typed models with hand-written `fromJson`/`toJson`), `lib/services/` (`ApiClient`, `AuthService`, `OrganizationRegistry`/discovery, `SyncEngine`, `LoaderInstaller`, `JavaManager`, `GameLauncher`, `UpdateService`), and `lib/screens/` + `lib/widgets/` for UI only.
- **State management: Riverpod.** Services never touch `BuildContext` or l10n; they return results or typed errors and the UI translates them.
- **One HTTP client** (Dio) per organization, with base URL, timeouts, retries and the token (done: `ApiClient`). The rest of the launcher gets models or an `ApiError`, never HTTP status codes or JSON.
- **Per-instance theming** from the instance's colors and background, instead of `Constants` colors (done for MainScreen and what hangs from it, `InstanceTheme.of(context)`; new UI inside an instance reads its colors from there).
- **Sync engine:**
  1. Fetch the manifest (`If-None-Match` with the `contentVersion`) and compute a plan (add, update, delete).
  2. Download in parallel to `.part` files, verify the hash, then rename atomically.
  3. Cache hashes by `(path, size, mtime)`. Today `SyncEngine` re-hashes the `always` files on every entry and every Play on purpose, so local changes are always repaired; keep that guarantee.
  4. Apply a policy per file: `always` (the server wins, restored on every launch) or `once` (copied only if missing, then the player's).
  5. Clean managed dirs, and delete files that were in the previous manifest but not in the new one (tracked in a local list).
  6. Keep managed files separate from user files: saves, screenshots, `options.txt` and `servers.dat` must survive a reinstall.
- **Vanilla files from Mojang** (piston-meta, libraries, assets; never redistributed by organization servers). Libraries, natives, the client jar (`LibraryManager`) and assets (`AssetManager`) are done. **Java on demand** from the version JSON's `javaVersion` (done, `JavaManager`).
- **Microsoft login in the system browser** (done). Credentials in `flutter_secure_storage` (done, `CredentialsStore`; macOS uses the legacy Keychain because the build is ad-hoc signed, Linux needs `libsecret` and a keyring service). The Minecraft token is cached (done, `MinecraftSessionStore`). Support multiple accounts.
- **Launch** (done, `GameProcess`): game output in a log file, crash detection, the launcher hidden while playing unless it stays open.
- **Tests:** unit-test the pure logic first. Done: models, `ApiClient` (against a fake `HttpClientAdapter`, no network), `DeepLinks.parseAdd`, the organization and token stores (mocked `SharedPreferences` and `FlutterSecureStorage`) and `launch_utils` (rules, library paths, `inheritJson`, command line). Sync planning (`SyncPlanner`) and its execution (`SyncEngine`, against a fake server and a temporary folder) are covered, and so are entering an instance (`InstanceInstaller`: steps, `state.json`, `servers.dat`), `ServerList` installing the game files (`GameInstaller`, against a fake Mojang and fake Fabric/Quilt meta; `ForgeInstaller`, with a fake installer and processors), cleaning the shared files (`SharedFiles`), each instance's settings (`InstanceSettings`, `InstanceSettingsStore`, `SystemMemory`'s parsing), XSTS and its codes (`XboxAuth`), the update recovery marker (`UpdateRecoveryFileStore`) and the pinned keys matching the release key profile (`UpdateConfig`), running the game (`GameProcess`, against a fake process), zipping its logs (`LogExport`), the news pages (`NewsCatalog`) and their markdown (`NewsMarkdown`). Tests never hit the network or the real Keychain; UI and `OrganizationAuth` (needs a real Minecraft session) are tested by hand.

Refactor incrementally. Don't rewrite unrelated code in a feature PR.

## Known issues (fix when touching the area; don't copy these patterns)

**Important**
- None right now.

**Minor**
- Slider thumb color math uses the new 0..1 color channels.
- Hardcoded strings (the footer brand text).
- `FutureBuilder` futures created inside `build`.
