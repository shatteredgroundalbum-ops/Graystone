# Graystone — Engine Roadmap

> **Scope:** this roadmap covers **only the Rust engine core** (`engine/`, the
> `graystone_*` crates). The Flutter UI and the Zig layer are out of scope; they
> appear here only where they define the engine's public contract. See
> [`ARCHITECTURE.md`](./ARCHITECTURE.md).

The engine is the authority: every destructive operation, the License Gate,
backups, and diff-before-apply are enforced inside Rust so they cannot be
bypassed by any frontend.

---

## Delivery principles

- **One phase per PR (or a small group of PRs).** No single giant PR.
- **Safety first.** The License Gate (`graystone_license`) and Hard Rules
  (`graystone_policy`) land before any module that can touch files.
- **Test as we go.** Each crate ships with unit tests + fixtures; the workspace
  is wired into CI (`cargo build`/`clippy`/`test`) alongside `flutter analyze`.
- **Stable FFI contract.** `graystone_core` defines the public surface the UI
  binds to (via flutter_rust_bridge); changes to it are versioned and called out.

---

## Phase 0 — Engine scaffold & toolchain

**Goal:** a buildable Rust workspace wired into CI and into both build targets.

- [ ] Create `engine/` cargo workspace with placeholder crates for each module.
- [ ] Add `graystone_core` with a minimal FFI surface (health-check call) via
      flutter_rust_bridge; generate Dart bindings.
- [ ] Cross-compile: Android `.so` via `cargo-ndk`; Windows `.dll` via the MSVC
      toolchain in GitHub Actions.
- [ ] CI: `cargo fmt --check`, `cargo clippy -D warnings`, `cargo test`, plus the
      existing `flutter analyze`.
- [ ] Define error model (structured, never-swallowed) and the logging contract
      (`graystone_logs`).

**Exit criteria:** UI can call one engine function over FFI on Android and
Windows; CI green.

---

## Phase 1 — Safety foundation (License Gate + Hard Rules)

**Goal:** nothing destructive can run without passing the gate. This is the
"required first step" from the spec.

- [ ] `graystone_policy` — encode the 9 Hard Rules as a non-bypassable choke
      point; every destructive call routes through it. Path-boundary enforcement,
      backup-completed check, diff/approval check, license-state check.
- [ ] `graystone_license` — detect `LICENSE`/`COPYING`/`NOTICE`/
      `THIRD_PARTY_NOTICES`/README, SPDX identifiers, per-file headers, and
      package metadata; classify **Green / Yellow / Red**; emit the license
      report; record the approval (classification, evidence, confirmation,
      timestamp).
- [ ] `graystone_project_scan` — universal intake (folder/app/clone/zip/release)
      and the intake questions; feeds the license gate.
- [ ] Knowledge-base persistence for license status + approval record
      (foundation of `graystone_index`'s store).
- [ ] Binary/compiled-boundary checks (allowed vs. blocked targets).

**Exit criteria:** given any project path, the engine returns a correct license
classification + report, and `graystone_policy` blocks every write/script/install
unless Green or Yellow-confirmed. Covered by fixture tests for MIT/Apache/GPL/
proprietary/missing-license cases.

---

## Phase 2 — Discover (crawler)

**Goal:** understand a cleared project and find the files behind a feature/bug.

- [ ] `graystone_readme` — extract purpose, build steps, structure, standards,
      supported platforms, extension points, config methods, update mechanism.
- [ ] `graystone_profiles` (project side) — structure maps for the initial
      stacks (Electron, Flutter, Node/React, Rust, Python, C/C++ CMake, Blender
      source, Blender add-on, VS Code ext, browser ext, game-mod).
- [ ] `graystone_index` — file index, metadata, hashes; persisted per project.
- [ ] `graystone_search` — Feature Finder across names, content, symbols,
      imports, routes, UI labels, config keys, comments, docs, error messages;
      returns matches + reason + confidence + related files + safe next action.

**Exit criteria:** "Find where the update URL is set" returns ranked files with
reasons and confidence on at least Flutter + Node fixtures.

---

## Phase 3 — Modify (patch engine)

**Goal:** safe, reversible changes.

- [ ] `graystone_backup` — snapshot originals before any write.
- [ ] `graystone_diff` — generate/preview diffs.
- [ ] `graystone_patch` — patch planner (target files, reasons, changes, risk,
      backup/verify/rollback plan).
- [ ] **Safe Apply** in `graystone_core` — confirm path → backup → compare →
      syntax/encoding/line-ending checks → atomic write → hash verify → log.
- [ ] `graystone_restore` — rollback of file/update/build/project snapshots.
- [ ] `graystone_update` — ingest update packages (file/folder/zip/exe/msix/bat/
      ps1/json/diff/patch), match targets by name/path/hash, confirm, apply,
      verify, roll back on failure.

**Exit criteria:** a planned edit applies atomically with an automatic backup and
a clean rollback, all gated by `graystone_policy`; update-package install round-
trips on a fixture.

---

## Phase 4 — Repair engine

**Goal:** stack-aware diagnosis → structured repair plan (no blind fixes).

- [ ] `graystone_profiles` (repair side) — per-stack diagnostic commands,
      common failure modes, verification tests, rollback strategy.
- [ ] Diagnostic Tool Manager — run the right tools per stack
      (`flutter analyze`/`doctor`, `cargo clippy`, `tsc`/`eslint`/`npm doctor`,
      `pip check`/`ruff`/`mypy`; Blender log/registry inspection).
- [ ] Graystone Analysis — missing files/assets/imports, broken references,
      config/JSON/YAML errors, syntax errors, dependency/version conflicts; UI
      checks (blank screens, invisible widgets, broken routes/themes).
- [ ] `graystone_build` — build & verification runner with live output + error
      summary (file/line) for the UI/AI to consume.
- [ ] Repair Knowledge Base — common issue → fix workflows per stack.

**Exit criteria:** engine identifies a stack, runs its diagnostics, and returns a
structured diagnosis (problems, confidence, recommended repairs, est. time) for a
broken fixture project.

---

## Phase 5 — Deep edit + AI bridge

**Goal:** precise edits and AI-assisted (but engine-validated) changes.

- [ ] `graystone_ast` — structural analysis (read path), symbol graph,
      dependency graph.
- [ ] `graystone_cst` — format-preserving edits (write path).
- [ ] `graystone_ai_bridge` — AI request/response; **recommend only**. AI output
      is always validated by the engine and applied only via Safe Apply with user
      approval.

**Exit criteria:** an AI-suggested change is validated and applied through the
normal Safe Apply + policy path; CST edit preserves surrounding formatting.

---

## Phase 6 — Zig native bridge (out of current scope)

Documented for completeness only. Later: native execution bridge, safe command
runner, plugin interface, C ABI bridge, high-performance file ops. Rust remains
the authority; the engine *calls* Zig.

---

## Engine ↔ UI contract (FFI)

`graystone_core` owns the public, versioned FFI surface that the Flutter UI binds
to via flutter_rust_bridge. The UI sends requests and renders results/approvals;
it holds **no** business or safety logic. All operations return structured
results or structured, surfaced errors — never silent failures.

---

## Open questions to resolve before/while building

1. **AI provider/transport** for `graystone_ai_bridge` — local model, hosted API,
   or pluggable? Determines the bridge's request/response shape.
2. **FFI generator** — confirm flutter_rust_bridge (vs. hand-written C ABI).
3. **Update-package execution policy** — `.exe`/`.bat`/`.ps1` installers must run
   behind `graystone_policy` with purpose shown; confirm the approval UX the
   engine should require.
4. **Knowledge-base storage format/location** — embedded DB (e.g. SQLite) vs.
   structured files; cross-platform path strategy.
5. **Theme decision (UI, not engine, but affects repair UI checks):** the brand
   spec says light background; current theme is dark. Resolve before Phase 4 UI
   diagnostics.
