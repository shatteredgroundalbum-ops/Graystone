# Graystone — Architecture

> **Status:** Design proposal (no engine code yet). This document and
> [`ROADMAP.md`](./ROADMAP.md) lock the design before implementation begins.
>
> **Scope of this work:** the deliverable being built is the **Rust engine core**
> (`engine/`, the `graystone_*` crates). The Flutter UI is a *consumer* of the
> engine over FFI and is **out of scope** here; the Zig layer is a **later,
> separate** effort. The UI and Zig are documented only to define the engine's
> boundaries and public contract — they are not part of this build.

## 1. What Graystone Is

Graystone is a **universal, license-gated open-source program crawler, repair,
and modification engine** with a desktop/mobile UI.

A user points Graystone at any project (source folder, installed app, cloned
repo, ZIP, release package). Graystone then:

1. **Verifies the license** and the user's right to modify (the *License Gate*).
2. **Reads the docs** (README, CONTRIBUTING, BUILDING, etc.).
3. **Maps the project** structure using a stack-specific profile.
4. **Finds the files** tied to a requested feature or bug (the *Feature Finder*).
5. **Pulls those files** into a workspace for review.
6. Uses **AI to explain or rewrite** code (AI recommends; it never writes to
   disk directly).
7. **Plans a patch**, applies it **safely** (atomic write + backup), and
   **verifies** the build.
8. **Rolls back** if anything breaks.

AnythingLLM is **one example target**, not the product's purpose.

Graystone has three top-level capabilities:

| # | Capability | What it does |
|---|------------|--------------|
| 1 | **Discover** (Crawler) | Intake, license gate, doc reading, structure map, feature finder |
| 2 | **Modify** (Patch Engine) | File pull, patch planning, safe apply, update installer, backup/restore |
| 3 | **Repair** (Repair Engine) | Stack detection, diagnostic tools, analysis, AI repair plan, build verify |

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter UI  (lib/)                                           │
│  Dashboard · Projects · License Gate · Crawler · File Finder │
│  File Puller · Editor · AI Assistant · Patch Planner ·       │
│  Apply · Backups · Restore · Build & Test · Manual Update ·  │
│  Logs · Settings                                             │
└───────────────────────────────┬──────────────────────────────┘
                                 │  FFI (flutter_rust_bridge)
                                 │  typed, async, no business
                                 │  logic in the UI
┌───────────────────────────────▼──────────────────────────────┐
│  Rust Engine  (engine/)  — THE AUTHORITY                      │
│                                                              │
│  graystone_core      orchestration, session/project state    │
│  graystone_policy    HARD RULES — non-bypassable safety gate  │
│  graystone_license   license detection + Green/Yellow/Red     │
│  graystone_readme    documentation understanding              │
│  graystone_project_scan  intake + classification             │
│  graystone_index     file index / metadata                   │
│  graystone_search    multi-strategy feature finder           │
│  graystone_profiles  per-stack project + repair profiles     │
│  graystone_ast       structure analysis (read)               │
│  graystone_cst       format-preserving edits (write)         │
│  graystone_patch     patch planner                           │
│  graystone_diff      diff generation/preview                 │
│  graystone_backup    snapshot originals before write         │
│  graystone_restore   rollback                                │
│  graystone_update    update-package intake + install         │
│  graystone_build     build & verification runner             │
│  graystone_ai_bridge AI request/response (recommend only)    │
│  graystone_logs      structured, append-only operation log   │
└───────────────────────────────┬──────────────────────────────┘
                                 │  (later) C ABI
┌───────────────────────────────▼──────────────────────────────┐
│  Zig Layer  (later)                                          │
│  native execution bridge · safe command runner · plugin      │
│  interface · high-performance file ops · C ABI bridge        │
└──────────────────────────────────────────────────────────────┘
```

### 2.1 Why this split

- **UI (Flutter):** the existing app stays. It renders state and collects
  approvals. It contains **no** destructive logic — it can only *request*
  operations from the engine.
- **Engine (Rust):** the single source of truth. Every destructive operation,
  the license gate, backups, and diff-before-apply are enforced **here** so they
  cannot be bypassed by a UI bug or a future alternate frontend. Rust is the
  authority.
- **Zig (later):** a thin native bridge for execution, plugins, and
  high-performance file operations. Rust remains the authority; Zig is a tool it
  calls.

### 2.2 Build targets

| Target | Status | Engine build |
|--------|--------|--------------|
| Android (APK) | builds on the Linux VM today | Rust → `.so` via cargo-ndk |
| Windows (.exe) | builds in GitHub Actions today | Rust → `.dll` via MSVC toolchain |

The Rust+FFI choice keeps the engine cross-platform; the same crates back both
targets. Pure-Dart was considered and rejected because the user requires a Rust
authority layer and a later Zig bridge.

---

## 3. The License Gate (mandatory first step)

Before Graystone scans deeply or edits anything, it must classify the project's
license and the user's right to modify. **No destructive operation runs until
the gate returns Green, or Yellow with explicit user confirmation.**

### 3.1 Inputs inspected

`README` · `LICENSE` · `COPYING` · `NOTICE` · `THIRD_PARTY_NOTICES` ·
package metadata (`package.json`, `pubspec.yaml`, `Cargo.toml`, `pyproject.toml`,
`setup.py`, `*.csproj`, `*.gemspec`, …) · repository metadata · project headers ·
per-source-file license comments · SPDX identifiers.

### 3.2 Classification

| Light | Meaning | Allowed actions |
|-------|---------|-----------------|
| 🟢 **Green** | Clear permissive/copyleft OSS license (MIT, Apache-2.0, BSD-2/3-Clause, GPL, LGPL, AGPL, MPL-2.0, Unlicense, Public Domain, applicable CC code license) | Full scan + modify + apply, **respecting license obligations** (e.g. preserve GPL terms) |
| 🟡 **Yellow** | Unclear/mixed: missing LICENSE, custom/dual license, mixed third-party, OSS core + proprietary assets, unknown repo origin, generated code of unclear origin | **Read-only scan** until the user confirms they have rights |
| 🔴 **Red** | Proprietary / closed-source commercial / EULA forbids modification / no permission / DRM bypass required / signed-locked binary / "no derivative works" | **Blocked.** Safe metadata review only |

### 3.3 Output (license report)

```
Project: Blender
License: GPL-2.0-or-later
Modification allowed: Yes
Redistribution obligations: Must preserve GPL terms
Status: Green Light
```

```
Project: UnknownApp
License: Proprietary EULA
Modification allowed: No
Status: Red Light
Allowed actions: read-only metadata scan only
```

The gate stores an **approval record** (classification, evidence, user
confirmation, timestamp) in the project knowledge base, so re-opening a project
does not start from scratch.

---

## 4. Hard Rule System (enforced in `graystone_policy`)

These rules are implemented as code in the engine, not as UI conventions, so
they are non-bypassable:

1. Read the license before modifying.
2. Block proprietary modification.
3. Back up before every write.
4. Show a diff before apply.
5. Never hide errors.
6. Never overwrite blindly.
7. Never run scripts silently without showing their purpose.
8. Never edit outside the approved project path.
9. Never apply AI changes without validation.

Every destructive engine call passes through `graystone_policy`, which checks the
license-gate state, the target path boundary, backup completion, and diff/approval
status before allowing the operation. A denied operation returns a structured
error that the UI surfaces (never silently swallowed).

---

## 5. Binary / Compiled Boundary

| Allowed | Blocked or warned |
|---------|-------------------|
| source code, config files, assets, scripts, open package contents, open plugin folders, documented extension points | closed-binary patching, DRM bypass, license bypass, obfuscated proprietary code, modifying signed/protected executables |

This boundary is checked by `graystone_policy` in concert with the License Gate.

---

## 6. Engine Modules (Rust)

| Crate | Responsibility |
|-------|----------------|
| `graystone_core` | Orchestration, session/project lifecycle, public FFI surface |
| `graystone_policy` | Hard-rule enforcement; the choke point for destructive ops |
| `graystone_license` | License file/SPDX/header detection + Green/Yellow/Red classification + report |
| `graystone_readme` | Doc understanding: purpose, build steps, structure, standards, extension points |
| `graystone_project_scan` | Universal intake + project-type classification |
| `graystone_index` | File index, metadata, hashes; persisted to the knowledge base |
| `graystone_search` | Feature Finder: names, content, symbols, imports, routes, UI labels, config keys, AST, comments, docs, error messages |
| `graystone_profiles` | Per-stack project profiles **and** repair profiles |
| `graystone_ast` | AST analysis for understanding structure (read path) |
| `graystone_cst` | CST editing that preserves formatting (write path) |
| `graystone_patch` | Patch planner: target files, reasons, changes, risk, backup/verify/rollback plan |
| `graystone_diff` | Diff generation and preview |
| `graystone_backup` | Snapshot originals before any write |
| `graystone_restore` | Rollback of file/update/build/project snapshots |
| `graystone_update` | Update-package intake (file/folder/zip/exe/msix/bat/ps1/json/diff/patch) + install |
| `graystone_build` | Build & verification runner with live output + error summary |
| `graystone_ai_bridge` | AI requests/responses — **recommend only**, never writes to disk |
| `graystone_logs` | Structured, append-only operation log |

### 6.1 Multi-language support

The engine targets: Dart/Flutter, JavaScript, TypeScript, JSX, TSX, HTML, CSS,
SCSS, JSON, YAML, TOML, Rust, Python, C, C++, CMake, Shell, Batch, PowerShell,
Markdown.

Edit safety layers, from broadest to most precise:

- **regex scanning** — broad discovery
- **token scanning** — safe replacements
- **AST** — structural understanding (read)
- **CST** — format-preserving edits (write)
- **symbol graph** — relationships
- **dependency graph** — imports

---

## 7. AI Model (recommend → validate → approve)

The built-in AI acts as an instructor/repair partner. It can explain files,
summarize functions, write replacement code, repair broken code, add
integrations, fix UI inconsistencies, generate patch plans, review diffs, explain
build errors, and recommend rollbacks.

**Rule:** AI writes or recommends → the Rust engine validates and applies → the
user approves destructive changes. The AI never overwrites files directly.

---

## 8. The Three Capabilities in Detail

### 8.1 Discover (Crawler)

Universal intake accepts: source folder, installed app folder, GitHub clone, ZIP,
release package, unpacked desktop app, Electron/Flutter/Rust/Python/Node/C·C++
app, Blender source/add-on, game-mod project, plugin project. Intake asks: *What
do you want to change? Where is the project? Is it yours or open source? Do you
have permission?* — then runs the License Gate.

The **Structure Mapper** uses the matched profile to locate entry points, source/
UI/backend/config/asset/plugin/extension folders, build & installer scripts,
tests, and docs.

The **Feature Finder** answers requests like *"Find where the update URL is set"*
and returns best-matching files, why they matter, a confidence score, related
files, and a safe next action.

### 8.2 Modify (Patch Engine)

File Pull → Patch Planner → Diff → Backup → **Safe Apply** (confirm path, backup,
compare, syntax/encoding/line-ending checks, atomic write, hash verify, log) →
Restore/Rollback. The **Update Installer** ingests update packages, matches target
files by name/path/hash, asks before overwrite, backs up, applies, verifies, and
rolls back on failure.

The **Patch Planner** always produces a plan before changes: target files, reason
per file, exact changes, risk level, backup plan, verification method, rollback
method.

### 8.3 Repair (Repair Engine) — four phases

1. **Project Identification** — detect the stack (Flutter, Electron, React, Vue,
   Angular, Rust, Python, Blender, Godot, Unreal, Unity, Qt, Java, C#, C++) and
   load the matching repair profile.
2. **Diagnostic Tool Manager** — run the best diagnostic tools for that stack
   (see profiles in §9), e.g. `flutter analyze`/`flutter doctor`, `cargo clippy`,
   `npm doctor`/`tsc`/`eslint`, `pip check`/`ruff`/`mypy`. For Blender, inspect
   Python console, startup/crash/build logs, and the add-on registry.
3. **Graystone Analysis** — engine's own checks: missing files/assets/imports,
   broken references, config problems, invalid JSON/YAML, syntax errors, runtime
   exceptions, dependency/version conflicts; for UI: blank screens, invisible
   widgets, broken layouts/routes, missing icons/themes.
4. **AI Repair Assistant** — summarize findings (problems, confidence,
   recommended repairs, estimated time) and offer: repair automatically, review
   first, repair selected, export report, or cancel.

A **Repair Knowledge Base** captures common issues and fixes per stack (Flutter
white/splash screens, provider/Riverpod/Bloc errors, asset & plugin failures,
platform build failures; Electron renderer/preload/IPC/asar failures; Blender
add-on/API/preferences/startup/render failures).

---

## 9. Project & Repair Profiles

Each supported stack has a profile defining: where source/UI files live, how
builds work, how assets are referenced, how updates are packaged, common failure
points, the diagnostic commands to run, verification tests, and a rollback
strategy.

Initial profile set: Electron, Flutter, Node/React, Rust, Python, C/C++ (CMake),
Blender source, Blender add-on, VS Code extension, browser extension, game-mod
project.

Example — **Flutter**: `lib/`, `windows/`, `pubspec.yaml`, `assets/`, `build/`;
diagnostics `flutter analyze` / `flutter doctor` / `dart analyze` /
`dart fix --dry-run`; verify with `flutter build <target>`.

Example — **Blender source**: `source/`, `intern/`, `extern/`,
`release/scripts/`, `scripts/addons/`, `build_files/`, `CMakeLists.txt`.

---

## 10. Project Knowledge Base

For every scanned project Graystone persists: project map, license status &
approval record, file index, known important files, previous changes, backup
history, AI notes, build commands, update commands. This makes re-opening a
project fast and stateful.

---

## 11. UI Sections

Dashboard · Projects · License Gate · Crawler · File Finder · File Puller ·
Editor · AI Assistant · Patch Planner · Apply Changes · Backups · Restore ·
Build & Test · Manual Update · Logs · Settings.

### 11.1 UI consistency rules (from the brand spec)

- Use the real logo; never rewrite text inside the logo.
- One consistent component system across all screens (the existing
  `lib/widgets/common.dart` primitives: `GSection`, `GCard`, `GBtn`, `GInput`).
- One consistent accent palette (blue/purple); no page-specific random colors.
- No blank/invisible-text screens (white-on-white, missing routes, crashed
  widgets) — covered by the UI Consistency Auditor and Blank Screen Diagnostic.

> **Open question / discrepancy to resolve:** the brand spec calls for a
> "consistent light background," but the current theme in
> `lib/widgets/common.dart` is dark (`kBg = 0xFF0B1020`) with purple/cyan
> accents. We should decide light vs. dark before the UI work in Phase 4. See
> ROADMAP "Open Questions."

---

## 12. Relationship to the Current App

The current repo is a Flutter app oriented around AnythingLLM with
BAT/PowerShell helpers (`lib/services/bat_service.dart`, the `*.bat` scripts) and
Windows-centric flows. The migration:

- **Keep:** Flutter shell, `common.dart` component system, updater, file-manager
  primitives, installer/release pipeline.
- **Generalize:** AnythingLLM-specific screens become one *project profile* among
  many; BAT/PowerShell execution moves behind `graystone_policy` (purpose shown,
  never silent) and, later, the Zig safe command runner.
- **Add:** the Rust engine and the License Gate as the new front door.

See [`ROADMAP.md`](./ROADMAP.md) for the phased delivery plan.
