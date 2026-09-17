# Requirements — Custom LR Stacking (Lightroom Classic plugin)

Status: Draft v0.1 — agreed scope for v1
Product: **Custom LR Stacking** — a Lightroom Classic (LrC) plugin that guides the user through
stacking groups of related photos, one group at a time.

## 1. Overview

Lightroom Classic can stack photos natively (`Ctrl+G`, Photo > Stacking > Group into Stack),
but has no bulk way to group "same shot, different format" files (e.g. `IMG_1234.arw` +
`IMG_1234.jpg`). Its plugin SDK cannot create stacks for photos already in the catalog
(stacking is only possible at import time via `catalog:addPhoto`). This plugin closes the
gap with a guided workflow:

1. It finds **groups** — photos sharing the same base file name (e.g. jpg + raw pairs) —
   in a folder or in the current selection.
2. It **selects one group at a time**, putting the preferred file (jpg or raw) as the
   primary selection, which becomes the top of the stack when the user stacks.
3. The user presses `Ctrl+G`.
4. The plugin detects the stack was created and **auto-advances** to the next group.

Photos without a pair are skipped.

## 2. Terminology

| Term | Meaning |
|---|---|
| Base name / stem | File name without extension, e.g. `IMG_1234` |
| Group | All photos in the same folder sharing the same stem (case-insensitive) that meet the pairing rule |
| Pair | A two-member group (jpg + raw). Groups may have more than 2 members |
| Primary photo | The most-selected photo of a group; becomes top of stack (position 1) when the user stacks |
| Stack | Lightroom's native stack (`Ctrl+G` on Windows, `Cmd+G` on macOS) |

## 3. Scope and hard constraints

- **Lightroom Classic only.** Lightroom (cloud/CC) has no third-party plugin support.
- **No direct stacking API.** The SDK can only stack via `catalog:addPhoto()` at import time.
  Therefore the plugin *selects* groups and the user presses the native shortcut to stack.
- **Same-folder rule.** Lightroom only allows stacking photos located in the same folder.
  Accepted — grouping runs per folder, and this is not a limitation for our use case.
- No direct catalog database (SQLite) manipulation, no import interception, no external
  binaries in v1.

## 4. Features

### F1 — Group by base name

- **Modes:**
  - *Folder mode:* analyze the photos of the folder currently shown in the Library grid
    (top-level only by default; subfolder inclusion is an open question, see §9).
  - *Selection mode:* analyze only the currently selected photos.
- **Pairing rule (v1 default):** same stem (case-insensitive), at least 2 members, at least
  one member with a RAW extension, and more than one distinct extension in the group.
- **Extension lists (configurable):**
  - RAW: `arw, cr2, cr3, nef, nrf, raf, orf, rw2, pef, dng, raw, srw, 3fr, sr2, rwl, dcr, mrw, erf, kdc, mef, mos, x3f, fff, gpr`
  - JPG-like: `jpg, jpeg` (extensible later, e.g. `tif, psd`)
- **Singles** (stem with no group) are skipped and reported.
- Photos already in a stack are skipped by default (configurable).

### F2 — Guided stacking with auto-advance

- Loop: select group (primary per F3 preference) → wait for the user's `Ctrl+G` → detect the
  stack (`isInStackInFolder` / `stackInFolderMembers` of the group members) → advance.
- Controls via a **non-modal floating dialog** (must not steal `Ctrl+G` from the main
  window): Skip group, Stop, progress "Group 3 of 47", stem and member names.
- Detection polls every ~300–500 ms inside an `LrTasks` task; no modal dialogs during a run.
- Final summary when done or stopped: X stacked, Y skipped (already stacked), Z singles.

### F3 — Settings (persisted via `LrPrefs.prefsForPlugin()`)

| Setting | Values | Default |
|---|---|---|
| `top_of_stack` | `jpg_first` \| `raw_first` | `raw_first` |
| `raw_extensions` | comma-separated list | list from F1 |
| `jpg_extensions` | comma-separated list | `jpg, jpeg` |
| `skip_already_stacked` | boolean | `true` |
| `log_level` | `off` \| `error` \| `info` \| `trace` | `info` |

### F4 — Extensibility: operation registry

- Every feature is an **operation** module with a fixed contract:
  - metadata: `id`, `name`, `description`
  - `identify(photos) -> groups` (pure grouping, no SDK calls, unit-testable)
  - per-group selection / application, and progress reporting
- Core (catalog access, settings, logger, registry) is operation-agnostic.
- v1 ships `stack_by_name`. Planned future operations: **expanded file renaming**,
  stack by capture time, other bulk operations.

## 5. User workflows

### W1 — Folder mode

1. Open a folder in the Library grid.
2. Library > Plug-in Extras > Custom LR Stacking > **Stack groups in folder**.
3. Floating dialog appears; group 1 is selected with the preferred file as primary.
4. Press `Ctrl+G` → stack created → plugin auto-selects group 2.
5. Repeat; Skip/Stop available; final summary shown.

### W2 — Selection mode

1. Select photos in the grid.
2. Menu > **Stack groups in selection** → same flow, groups limited to the selection.

## 6. Non-goals (v1)

Import-time stacking, direct catalog DB edits, pixel access, develop operations,
export/publish services, macOS-specific packaging (the code remains cross-platform, but the
dev/test target is Windows).

## 7. Target environment

- **Dev/test:** Windows 10/11 x64, Lightroom Classic 13+ (primary test target: latest, 15.x).
- **Plugin metadata:** written against current SDK (15.x); `LrSdkMinimumVersion = 6.0`
  (only long-stable APIs are used).
- **Runtime:** Lua 5.1 sandbox embedded in LrC. No external binaries in v1.

## 8. Acceptance criteria (v1)

1. Running W1 on a folder with N jpg+raw pairs and 1 single creates N stacks after N `Ctrl+G`
   presses, auto-advancing each time; the single is reported as skipped.
2. `top_of_stack` preference determines which file ends up as stack top (position 1).
3. Selection mode produces the same results limited to the selection.
4. Photos already stacked are skipped (unless configured otherwise).
5. Settings persist across Lightroom restarts.
6. Logging is usable via `LrLogger` at the configured level.
7. `grouping.lua` logic is covered by unit tests (Busted) with no LrC dependency.

## 9. Development spikes / open questions

| # | Item | Owner |
|---|---|---|
| S1 | Verify primary selection maps to stack top (position 1) via `Ctrl+G` (UI behavior assumption) | dev |
| S2 | Verify `isInStackInFolder` reflects user stacking without grid refresh while polling in a task | dev |
| S3 | Verify the floating dialog does not intercept `Ctrl+G` keystrokes | dev |
| OQ1 | Folder mode: include subfolders or top-level only? (v1 default: top-level) | user |
| OQ2 | Resume behavior when stopped mid-run and re-invoked (v1 default: restart from first unstacked group) | user |

## 10. Future ideas (backlog)

Rename operation (expanded renaming), stack by capture time, auto-collapse created stacks,
dry-run report mode, multi-stem patterns (e.g. `IMG_1234_a`, `IMG_1234_b`).
