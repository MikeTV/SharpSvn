# SharpSvn ARM64 Build Plan (.NET Framework + .NET Core)

Pick-up guide for finishing the ARM64 build work and producing working
`SharpSvn.dll` binaries for `Release|ARM64` (targets .NET Framework 4.8.1) and
`ReleaseCore|ARM64` (targets .NET 6+).

## Current State (confirmed)

- `src/SharpSvn.sln` and `src/SharpSvn/SharpSvn.vcxproj` already declare all
  four ARM64 configurations (`Debug`, `DebugCore`, `Release`, `ReleaseCore`).
- Linker `TargetMachine` is `MachineARM64` for every ARM64 config.
- Additional library path `..\..\imports\release\lib-ARM64` is wired in.
- `.github/workflows/MSBuild.yml` has `build-arm64` and `build-arm64-core`
  jobs; `create-nuget` depends on them.
- `imports/Default.build` already accepts `platform=ARM64`.
- `SharpPlink.vcxproj` has `Debug|ARM64` and `Release|ARM64` project
  configurations declared.

## Blockers (in order)

1. **VS 2026 install is missing the ARM64 MSVC toolset.**
   There is no `VC/Tools/MSVC/<ver>/bin/Hostx64/arm64/cl.exe`, only
   `Hostx64/x64` and `Hostx64/x86`. MSBuild therefore can't cross-compile to
   ARM64 and may also fall through to `v120` (the older SharpPlink conditional
   block), producing `MSB8020: Visual Studio 2013 (v120) build tools cannot be
   found`.

2. **Native dependencies not built for ARM64.**
   `imports/release/` is empty. SharpSvn links against a large static chain
   (APR, APR-util, Subversion, serf, OpenSSL, SQLite, zlib, expat, SASL,
   libssh2, etc.) that must be pre-produced into `imports/release/lib-ARM64`.

3. **Dependency-build tools not on PATH.** NAnt, CMake, SCons, NASM, NuGet
   are all needed for the NAnt-driven dep build (`tools/buildbot.build`).
   Perl and Python3 are present.

## Step-by-Step Plan

All commands assume repo root =
`c:\Users\erela\source\repos\VersionSQL-Dependencies-WIP\SharpSvn-main` and an
elevated Developer PowerShell or `cmd` unless noted. Use **bash** for
anything that just needs a shell; use **Developer Command Prompt for VS 2026**
for MSBuild/NAnt native-dep steps.

### Step 1 — Add the ARM64 VC++ toolset to VS 2026

Required component IDs (add all three):

- `Microsoft.VisualStudio.Component.VC.Tools.ARM64` — MSVC v145 ARM64 build tools
- `Microsoft.VisualStudio.Component.VC.Tools.ARM64EC` — ARM64EC (optional but cheap)
- `Microsoft.VisualStudio.Component.Windows11SDK.26100` — Win11 SDK ARM64 libs
  (or whichever SDK version is already installed — match it)

Run from an elevated cmd:

```cmd
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" modify ^
  --installPath "C:\Program Files\Microsoft Visual Studio\18\Community" ^
  --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 ^
  --add Microsoft.VisualStudio.Component.VC.Tools.ARM64EC ^
  --add Microsoft.VisualStudio.Component.Windows11SDK.26100 ^
  --quiet --norestart
```

Verify afterward:

```bash
ls "/c/Program Files/Microsoft Visual Studio/18/Community/VC/Tools/MSVC/14.50.35717/bin/Hostx64/arm64/cl.exe"
```

The file must exist.

### Step 2 — Install dep-build tools

```powershell
winget install --id Kitware.CMake         -e --accept-package-agreements --accept-source-agreements
winget install --id NASM.NASM             -e --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.NuGet       -e --accept-package-agreements --accept-source-agreements
# SCons via Python
pip install scons
```

NAnt 0.92 is installed into the repo itself (the CI does this too):

```cmd
cd imports
nuget.exe install NAnt -Version 0.92
```

That drops `NAnt.0.92.0` under `imports/` and the exe lands at
`imports/NAnt.0.92.0/bin/NAnt.exe`.

Add to PATH for the session (bash):

```bash
export PATH="$PATH:/c/Program Files/CMake/bin:/c/Program Files/NASM:/c/Users/$USER/.local/bin"
```

Verify tools resolve:

```bash
which cmake nasm nuget perl python scons
ls imports/NAnt.0.92.0/bin/NAnt.exe
```

### Step 3 — Build native dependencies for ARM64

The dep build needs the VS ARM64 cross environment loaded. From a regular
`cmd`:

```cmd
"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
cd c:\Users\erela\source\repos\VersionSQL-Dependencies-WIP\SharpSvn-main
imports\NAnt.0.92.0\bin\NAnt.exe -f:tools\buildbot.build buildbot-build -D:platform=ARM64
```

This matches the CI step in [.github/workflows/MSBuild.yml](.github/workflows/MSBuild.yml)
line 51. Expect 10–30 minutes, and some non-fatal warnings.

Success check: `imports/release/lib-ARM64/` exists and contains `.lib` files
(subversion, apr, serf, openssl, sqlite, etc.). Also:
`imports/release/lib-AnyCPU/` populated.

> **If the dep build fails on a specific package**, check
> `imports/patches/<pkg>/` — patches may need to be refreshed for ARM64.
> The in-tree `subversionMerges="1890223,1890668,1890673"` in
> `imports/Default.build` already pulls the upstream Subversion ARM64
> patches, so svn itself should build cleanly.

### Step 4 — Restore NuGet packages for SharpSvn.sln

```bash
nuget.exe restore src/SharpSvn.sln
```

### Step 5 — Build SharpSvn for ARM64

.NET Framework 4.8.1 ARM64:

```cmd
msbuild.exe /r /v:m /p:Platform=ARM64 /p:Configuration=Release src\SharpSvn.sln /p:BuildBotBuild=true
```

.NET Core/6+ ARM64:

```cmd
msbuild.exe /r /v:m /p:Platform=ARM64 /p:Configuration=ReleaseCore src\SharpSvn.sln /p:BuildBotBuild=true
```

Success check:

- `src/SharpSvn/bin/ARM64/Release/SharpSvn.dll`
- `src/SharpSvn/bin/ARM64/ReleaseCore/SharpSvn.dll`
- `src/SharpPlink/bin/ARM64/Release/SharpPlink.exe`

If you hit `MSB8020: v120` again on SharpPlink, the VS 2026 ARM64 toolset
install didn't populate `DefaultPlatformToolset`. Workaround: pass
`/p:PlatformToolset=v145` on the MSBuild line. A cleaner fix is to edit
[src/SharpPlink/SharpPlink.vcxproj:60-81](src/SharpPlink/SharpPlink.vcxproj#L60-L81)
— the `Release|x64` and `Release|ARM64` blocks have a stale unconditional
`<PlatformToolset Condition="'$(VCTargetsPath11)' != ''">v120</PlatformToolset>`
ahead of the modern guard; reorder so the `DefaultPlatformToolset` line comes
first, or simply delete the two legacy fallback lines.

### Step 6 — Smoke-test the ARM64 DLL

On an ARM64 Windows device (or Windows 11 ARM VM):

```powershell
Add-Type -Path 'src\SharpSvn\bin\ARM64\Release\SharpSvn.dll'
$c = [SharpSvn.SvnClient]::new()
$c.GetVersion()
```

Should print the Subversion client version with no `BadImageFormatException`.
If run from x64 it *will* throw — that's expected, confirming it's a real
ARM64 binary.

## Short Version for Another Env

1. VS 2026 (or 2022) with components:
   `VC.Tools.ARM64`, `VC.Tools.ARM64EC`, matching Windows SDK.
2. `winget install` CMake, NASM, NuGet; `pip install scons`.
3. `cd imports && nuget install NAnt -Version 0.92`.
4. Dev CMD → `vcvarsall.bat x64_arm64` →
   `imports\NAnt.0.92.0\bin\NAnt.exe -f:tools\buildbot.build buildbot-build -D:platform=ARM64`.
5. `nuget restore src\SharpSvn.sln`.
6. `msbuild /r /p:Platform=ARM64 /p:Configuration=Release src\SharpSvn.sln`
   (and repeat with `ReleaseCore`).

## Known Open Items

- `SharpPlink.vcxproj` PlatformToolset ordering bug (see Step 5 note).
- `test-arm64-core` job in CI is commented out because GitHub's
  `windows-11-arm` runner is still preview; once stable, uncomment it
  (MSBuild.yml:417-437).
- `imports/msm/` only has `Microsoft_VC143_CRT_x86.msm` and `x64.msm` —
  when producing the MSI/MSM installer story, an ARM64 MSM may also be
  needed (`Microsoft_VC143_CRT_arm64.msm`).
- WSL is **not** a viable build host for this project; C++/CLI is
  Windows-only by design.
