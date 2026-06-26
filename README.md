# Graystone — Flutter Windows App

## What's Inside

```
lib/
  main.dart                    — Entry point
  app.dart                     — App root, theme, routes
  widgets/
    common.dart                — Shared UI components (GCard, GBtn, GInput, etc.)
  services/
    bat_service.dart           — Generates and runs BAT files
  screens/
    home_screen.dart           — Dashboard with navigation cards
    file_manager_screen.dart   — Find, copy, move, zip, replace files
    asar_tools_screen.dart     — Extract, repack, install into AnythingLLM
    splash_screen_manager.dart — Install Graystone splash screen
    language_installer_screen.dart — Download 18+ languages
    api_keys_screen.dart       — Manage AI provider API keys
    settings_screen.dart       — App preferences
    updater_screen.dart        — Check for and install updates
```

## How to Build

### Requirements
- Flutter SDK 3.19+ (download from flutter.dev)
- Windows 10/11 with Visual Studio Build Tools
- Git

### Steps

1. Install Flutter:
   - Download from https://flutter.dev/docs/get-started/install/windows
   - Extract to C:\flutter\
   - Add C:\flutter\bin to PATH

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run in development:
   ```
   flutter run -d windows
   ```

4. Build release .exe:
   ```
   flutter build windows --release
   ```
   Output: build\windows\x64\runner\Release\graystone.exe

## One-Click Installer (recommended)

Just run **`BUILD.bat`** on a Windows machine. No extra tools required. It will:
1. Scaffold the Windows runner if `windows\` is missing (`flutter create --platforms=windows .`)
2. Apply the Graystone icon (`assets\app_icon.ico`) to the EXE
3. `flutter pub get` + `flutter build windows --release`
4. Stage a **self-contained installer** → `dist\Graystone-Installer.zip`
5. Offer to install Graystone on the current PC right away

### Installing (no admin, no signing, no third-party tools)
- On the build PC: answer **Y** to "Install Graystone on THIS PC now?" at the end of `BUILD.bat`.
- On any other PC: unzip **`dist\Graystone-Installer.zip`** and double-click
  **`Install Graystone.bat`**.

The installer (`installer\install.ps1`) copies the app to
`%LOCALAPPDATA%\Programs\Graystone`, creates Desktop + Start Menu shortcuts with the
Graystone icon, and registers an entry in Add/Remove Programs. Uninstall from
Add/Remove Programs or by running `uninstall.ps1`. Because it installs per-user, it needs
**no administrator rights and no code signing** — this is why it "just installs."

### Optional: single-file Setup.exe (Inno Setup)
If you also install **Inno Setup 6** (https://jrsoftware.org/isdl.php), `BUILD.bat` will
additionally produce **`dist\Graystone-Setup.exe`** — a classic install wizard. This
filename matches the asset the Updater screen expects, so GitHub-release auto-updates
work out of the box. Inno Setup is optional; the `.zip` installer above always works.

## Publishing updates on GitHub

You don't need GitHub to use the app, but if you want the in-app **Updater** to
check/download updates over the internet:

1. **Build the upload-ready files:** run **`MAKE-RELEASE.bat 1.0.1`** (use your new
   version number). It builds the app and drops a clean **`release\`** folder containing:
   - `Graystone-Installer.zip` — the no-dependency installer (always produced)
   - `Graystone-Setup.exe` — only if Inno Setup is installed
   - `latest.json` — a small version manifest

2. **Set your repo once:** open `lib/screens/updater_screen.dart` and set
   `const _repoSlug = 'your-username/graystone';` to your real GitHub `owner/repo`,
   then rebuild. (Manual File/URL updates work even without this.)

3. **Create the GitHub Release:** on your repo → *Releases* → *Draft a new release* →
   tag it `v1.0.1` → drag the files from `release\` into the binaries box → Publish.

The Updater's **Check for Updates** reads the latest release tag and downloads the
attached `Graystone-Installer.zip` (it now recognizes `.zip`, `.exe`, and `.msix`
assets). The **Generate Update BAT** button pulls the same asset from
`releases/latest/download/`.

> Even without any of this, the Updater's **Choose File & Install** and **Update From
> Link** buttons let you update purely manually.

### App icon
The icon lives at `assets/app_icon.ico` (multi-resolution) and `assets/icon.png`.
`BUILD.bat` copies the `.ico` into `windows\runner\resources\app_icon.ico` so the built
EXE, taskbar, and installer all use it. Replace those files to rebrand.

### MSIX (Microsoft Store style) alternative
   ```
   dart run msix:create
   ```
   Output: build\windows\graystone.msix

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Home | / | Dashboard with 6 navigation cards |
| File Manager | /files | Find, replace, copy, move, zip files |
| ASAR Tools | /asar | Extract/repack AnythingLLM app.asar |
| Splash Screen | /splash | Install Graystone splash into AnythingLLM |
| Languages | /languages | Download 18+ language installers |
| API Keys | /apikeys | Manage AI provider keys with auto-detection |
| Settings | /settings | App preferences and folder paths |
| Updater | /updater | Check GitHub for updates |

## Updater Setup

To enable auto-updates:
1. Create a GitHub repo named `graystone`
2. Create releases with a `Graystone-Setup.exe` asset
3. Update the `_updateUrl` in `lib/screens/updater_screen.dart`

## Adding More Languages

Edit `lib/screens/language_installer_screen.dart` and add to the `_langs` list:
```dart
{'name': 'Your Language', 'ver': '1.0', 'url': 'https://...', 'file': 'installer.exe', 'type': 'EXE'},
```

## Adding More AI Providers

Edit `lib/screens/api_keys_screen.dart` and add to `_providers`:
```dart
{'name': 'Your Provider', 'prefix': 'key_prefix_', 'fmt': 'key_prefix_...', 'color': 0xFF123456, 'env': 'YOUR_PROVIDER_API_KEY'},
```
