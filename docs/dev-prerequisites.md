# Development Prerequisites — Custom LR Stacking

Goal: reproduce the complete dev environment on a fresh Windows machine.
All commands verified on Windows 10/11 x64 with PowerShell 5.1+.

## 1. Machine baseline

- Windows 10/11 x64
- PowerShell 5.1+ (in-box) — junctions used below need no admin rights
- Windows Terminal (optional, recommended)
- ~1 GB free disk for tools and SDK

## 2. Required software

| Tool | Version | Purpose | Install |
|---|---|---|---|
| Adobe Lightroom Classic | 13+ (test against latest, currently 15.x) | Host application | Creative Cloud desktop app |
| Lightroom Classic SDK | Latest published (15.x; the console may still offer 14.3 — either works for our API surface) | API reference, guide, samples | Adobe Developer Console (free Adobe account) |
| Git | Any recent | Version control | `choco install git -y` |
| VS Code | Latest | Editor | `choco install vscode -y` |
| Lua extension for VS Code | Latest | IntelliSense for Lua | `code --install-extension sumneko.lua` |
| Lua interpreter | **5.1.5** (matches LrC's sandbox) | Run unit tests headless | LuaBinaries 5.1.5 zip → unzip to `C:\tools\lua5.1` → add to PATH |
| LuaRocks | Latest (bound to Lua 5.1) | Package manager for test tooling | `choco install luarocks -y` |
| Busted | Via LuaRocks | Test framework | `luarocks --lua-version 5.1 install busted` |
| StyLua (optional) | Latest | Lua formatter | `choco install stylua -y` |
| opencode CLI | Latest | AI-assisted development | From the opencode install page |

> Note on Lua versions: LrC embeds Lua 5.1.5. Keep the local interpreter on 5.1 so tests
> run the same major version as the plugin. (Fallback if 5.1 tooling fights back: use a
> modern Lua for tests, but then all plugin code must stay 5.1-compatible — prefer the
> matching interpreter.)

## 3. SDK download (one-time, needs Adobe account)

1. Go to https://developer.adobe.com/lightroom-classic → "Start building" → Lightroom Classic SDK.
2. Download the zip (e.g. `Lightroom_Classic_SDK.zip`).
3. Unzip to `C:\dev\lrc-sdk`. Contents of interest:
   - `API Reference/` — HTML API docs
   - `Manual/` or `Lightroom SDK Guide.pdf` — the programmer's guide
   - `SamplePlugin.lrdevplugin/` — the reference plugin to crib from

## 4. One-time environment setup

```powershell
# 1. Clone the repo
git clone <repo-url> "C:\dev\Custom LR Stacking"

# 2. Install chocolatey packages
choco install git vscode luarocks -y

# 3. Install VS Code extension
code --install-extension sumneko.lua

# 4. Lua 5.1 interpreter (from LuaBinaries zip, already unzipped to C:\tools\lua5.1)
#    Add to user PATH:
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\tools\lua5.1", "User")

# 5. Busted for Lua 5.1
luarocks --lua-version 5.1 install busted
```

### 4.1 Plugin loading into Lightroom (Windows)

- The plugin bundle lives in the repo as the folder `CustomLRStacking.lrdevplugin`
  (created during scaffold). `.lrdevplugin` = editable during development;
  `.lrplugin` = release packaging.
- Create a **junction** (no admin required, unlike symlinks) so Lightroom auto-discovers it:

```powershell
New-Item -ItemType Junction `
  -Path "$env:APPDATA\Adobe\Lightroom\Modules\CustomLRStacking.lrdevplugin" `
  -Target "<repo>\CustomLRStacking.lrdevplugin"
```

- In Lightroom: File > Plug-in Manager → the plugin should be listed → Enable it.
- **Reload workflow:** code changes to `.lua` files → Plug-in Manager > Reload.
  Changes to `Info.lua` (manifest/menu items) → restart Lightroom.
- Release: rename/copy the folder to `CustomLRStacking.lrplugin` (optionally zip it).

## 5. Logging & debugging

- Plugin logs via `LrLogger` (logger name `customLRStacking`) go to
  `%LOCALAPPDATA%\Adobe\Lightroom\Logs\LrClassicLogs\customLRStacking.log`.
- Quick checks: `LrDialogs.message(...)`.
- `print()` output is visible when Lightroom is launched from a console.
- Plugin Manager > Status button shows load errors.

## 6. AI tooling (opencode)

- The repo will contain a project skill at `.opencode/skills/lrc-sdk/` — a curated,
  accurate LrC SDK reference (manifest fields, catalog/photo APIs, LrView/LrDialogs
  patterns, known pitfalls) so coding agents don't hallucinate APIs.
- Human reference: https://lrc.mcor.dev (SDK API index), the SDK docs from §3,
  and the Adobe Lightroom Classic community forums.

## 7. Verification checklist

Run each on a fresh machine; all must pass before development starts:

```powershell
git --version
code --version
lua -v          # → Lua 5.1.5
luarocks --version
busted --version
```

| Check | Expected |
|---|---|
| Junction created (PowerShell) | No error; `Test-Path` on the Modules path returns `True` |
| Lightroom > Plug-in Manager | "Custom LR Stacking" listed, enabled, Status OK |
| `busted tests/` (once scaffolded) | All green |
| Smoke test | Test folder with 2 jpg+raw pairs + 1 single → W1 flow creates 2 stacks, skips the single |

## 8. Version pinning table

Record versions installed on each machine (helps reproduce exact environments):

| Tool | Version installed | Source | Command used | Date | Machine |
|---|---|---|---|---|---|
| Windows | | | | | |
| Lightroom Classic | | | | | |
| LrC SDK | | | | | |
| Git | | | | | |
| VS Code | | | | | |
| sumneko.lua | | | | | |
| Lua | | | | | |
| LuaRocks | | | | | |
| Busted | | | | | |
| opencode | | | | | |

## 9. Known friction

- **LuaRocks installed Busted against the wrong Lua:** always pass `--lua-version 5.1` and
  check `which lua`/`Get-Command lua` resolves to `C:\tools\lua5.1`.
- **Lightroom ignores edited .lua files:** use Plug-in Manager > Reload; `Info.lua` edits
  need a Lightroom restart.
- **Plugin gets disabled after a crash:** re-enable it in Plug-in Manager.
- **Junction breaks if the repo moves:** recreate the junction (§4.1).
- **macOS notes (for later):** `.lrplugin` folders become opaque packages; develop with
  `.lrdevplugin` there too. Stack shortcut is `Cmd+G`. Paths use `/`.
