# Safe Exam Browser (Windows) - Monaco Editor & Clipboard Fix Edition

[![Build and Release](https://github.com/ShingWong08/safe-exam-browser-windows/actions/workflows/build.yml/badge.svg)](https://github.com/ShingWong08/safe-exam-browser-windows/actions/workflows/build.yml)
[![GitHub Release](https://img.shields.io/github/v/release/ShingWong08/safe-exam-browser-windows?include_prereleases&logo=github)](https://github.com/ShingWong08/safe-exam-browser-windows/releases)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-blue.svg)](LICENSE.txt)
[![Target: Windows](https://img.shields.io/badge/Platform-Windows_10%20%2F%2011%20(x64%20%7C%20x86)-0078D6?logo=windows)](https://github.com/ShingWong08/safe-exam-browser-windows)

A specialized distribution of **Safe Exam Browser (SEB) for Windows** based on version 3.10.x, featuring a comprehensive fix for the **Monaco Editor / isolated clipboard multi-line copy-paste bug ([Issue #910](https://github.com/SafeExamBrowser/seb-win-refactoring/issues/910))**, cross-window clipboard synchronization, and automated CI/CD release packaging.

---

## 🌟 Key Highlights & Bug Fixes

### 1. Monaco Editor & Isolated Clipboard Fix ([Issue #910](https://github.com/SafeExamBrowser/seb-win-refactoring/issues/910))
* **The Problem in Upstream SEB**:  
  Under SEB's isolated clipboard security policy (`allowIsolatedClipboard = true`), modern web code editors—most notably **Monaco Editor** (powers VS Code, LeetCode, Moodle CodeRunner, and coding exam platforms)—failed when attempting to copy multiple lines of code. Only the first line was copied, or copied content was corrupted. This occurred because SEB's legacy JavaScript interception immediately called `preventDefault()` during the capturing phase, truncating Monaco's internal event propagation before its multiline text model could populate the clipboard payload.
* **Our Solution**:
  * **Two-Phase Event Interception**: Implemented a non-destructive capturing-phase state observer paired with a dynamic bubbling-phase listener in [`Clipboard.js`](SafeExamBrowser.Browser/Content/Clipboard.js). This ensures web applications have the opportunity to finish populating synthetic multiline text and rich DOM before SEB commits the content to storage.
  * **Full Multiline & HTML Synchronization**: Complete support for multiline plain text, HTML DOM fragments, and Base64 chunked transfer across the CefSharp bridge.
  * **Cross-Window Clipboard Sync**: Enhanced [`Clipboard.cs`](SafeExamBrowser.Browser/Clipboard.cs) and [`BrowserWindowContext.cs`](SafeExamBrowser.Browser/BrowserWindowContext.cs) to ensure copied content is seamlessly shared across popups and additional browser tabs within the exam session.

### 2. Standalone & Custom Build Execution Fix
* **The Problem**: Upstream SEB builds contained hardcoded digital signature checks in [`ApplicationMonitor.cs`](SafeExamBrowser.Monitoring/Applications/ApplicationMonitor.cs), terminating custom or unsigned `SafeExamBrowser.Client.exe` binaries immediately upon launch.
* **Our Solution**: Relaxed internal signature restrictions for SEB's own client process while preserving full application monitoring, blacklisting, and process guards against unauthorized third-party software.

### 3. Automated Dual-Track CI/CD Pipelines
* Automated cloud builds via GitHub Actions with WiX v3.14 toolset.
* **Public Release Pipeline**: Automatically compiles and packages installer bundles (`.exe`), standalone MSIs (`.msi`), and portable zip packages (`.zip`).
* **Automated Assembly Versioning**: Dynamically stamps `3.10.3.0` across all 49 project assemblies to prevent `1.0.0.0` metadata drift.
* **Automated Upstream Tracker**: Includes a scheduled workflow that monitors official ETH Zürich releases and automatically triggers dual builds.

---

## 📥 Downloads

Visit the [GitHub Releases](https://github.com/ShingWong08/safe-exam-browser-windows/releases) page to download the latest build:

| Package | Recommended For | Description |
| :--- | :--- | :--- |
| **`SEB_SetupBundle.exe`** | ⭐ **Most Users** | Full bootstrapper installer. Automatically installs .NET 4.8 and Visual C++ 2015–2022 runtimes if missing. |
| **`SafeExamBrowser-Portable-x64.zip`** | Portable / Lab PCs | Standalone portable archive. Extract and run `SafeExamBrowser.exe` directly without administrative installation. |
| **`SEB_x64_Setup.msi`** | IT Administrators | Standard 64-bit Windows Installer package for Group Policy / MDM deployment. |
| **`SEB_x86_Setup.msi`** | Legacy Systems | Standard 32-bit Windows Installer package. |
| **`SafeExamBrowser.Browser.dll`** | Drop-in Patch | Drop-in DLL replacement for existing Safe Exam Browser installations. |

---

## 📋 System Requirements & Prerequisites

> [!NOTE]  
> Safe Exam Browser requires **Windows 10 version 1803 or newer** (including Windows 11).

If using the **MSI packages** or the **Portable ZIP**, ensure the following Microsoft runtime libraries are installed:
* [Microsoft .NET Framework 4.8 Runtime](https://dotnet.microsoft.com/download/dotnet-framework/net48)
* [Microsoft Visual C++ 2015–2022 Redistributable (x64)](https://aka.ms/vs/17/release/vc_redist.x64.exe)

*(The `SEB_SetupBundle.exe` installer includes and automatically installs these prerequisites).*

---

## 🏗️ Architecture Overview

The codebase is organized into modular layers using WCF Named Pipes IPC:

```
seb-win-refactoring/
├── SafeExamBrowser.Runtime/         # Main supervisor process (Lifecycle, IPC Host, Policy Engine)
├── SafeExamBrowser.Client/          # Kiosk Shell (Desktop locking, taskbar suppression, fullscreen guard)
├── SafeExamBrowser.Browser/         # Chromium Engine (CefSharp integration, Monaco clipboard patch, BEK injection)
│   ├── Content/Clipboard.js         # Two-phase JavaScript clipboard interception & DOM extractor
│   └── Clipboard.cs                 # Thread-safe in-memory isolated clipboard manager
├── SafeExamBrowser.Monitoring/      # Security monitors (Process blacklist, Virtual Machine & Remote Session detectors)
├── SafeExamBrowser.Configuration/   # .seb settings encryption & Browser Exam Key (BEK) generator
├── Setup/ & SetupBundle/            # WiX Toolset installer projects (MSI & Bootstrapper EXE)
└── .github/workflows/               # GitHub Actions automated build & upstream sync pipelines
```

---

## 🚀 Building from Source

### Prerequisites:
* Visual Studio 2022 (with *.NET desktop development* and *C++ desktop development* workloads)
* WiX Toolset v3.14 (and WiX Visual Studio extension)
* NuGet CLI

### Command Line Build:
```powershell
# 1. Restore NuGet packages
nuget restore SafeExamBrowser.sln

# 2. Build 64-bit Release
msbuild /p:Configuration=Release /p:Platform=x64 /p:SignOutput=false SafeExamBrowser.sln

# 3. Build 32-bit Release & Setup Bundle
msbuild /p:Configuration=Release /p:Platform=x86 /p:SignOutput=false SafeExamBrowser.sln
```

---

## 📄 License & Attribution

This project is licensed under the [Mozilla Public License 2.0 (MPL-2.0)](LICENSE.txt).  
Original Safe Exam Browser codebase: Copyright © 2010–2026 ETH Zürich, IT Services.  
Based on [SafeExamBrowser/seb-win-refactoring](https://github.com/SafeExamBrowser/seb-win-refactoring).
