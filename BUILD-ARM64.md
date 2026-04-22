# SharpSvn ARM64 Build Status

This repository now has a working ARM64 `.NET Framework 4.8.1` build and a
working ARM64 `.NET 6` build on Windows with Visual Studio 2026.

## Verified Outputs

- Framework build:
  - `src\SharpSvn\bin\ARM64\Release\SharpSvn.dll`
  - `src\SharpSvn\bin\ARM64\Release\SharpPlink-ARM64.svnExe`
- Core build:
  - `src\SharpSvn\bin\ARM64\ReleaseCore\SharpSvn.dll`
  - `src\SharpSvn\bin\ARM64\ReleaseCore\SharpPlink-ARM64.svnExe`

The framework DLL was verified after build, and the resulting file is an ARM64
mixed-mode assembly.

## Consumer Drop

A prebuilt consumer-ready `.NET Framework 4.8.1` ARM64 runtime set is committed
under:

- `release\win-arm64\net481`

That folder includes a consumer README plus the required runtime files, so
application developers do not need to compile SharpSvn locally to use the
ARM64 framework build.

## Required Installed Components

The following tooling is installed on the machine used to verify the build:

- Visual Studio 2026 Community with ARM64 MSVC tools
- .NET Framework 4.8.1 Developer Pack
- CMake
- NASM
- NuGet
- Strawberry Perl
- Python 3.12
- `scons`
- SlikSVN
- NAnt 0.92 under `imports\NAnt.0.92.0`
- Local `.NET 6` SDK under `C:\Repos\sharpsvn\.dotnet6`

The critical SDK paths added by the 4.8.1 developer pack are:

- `C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8.1`
- `C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8.1\Lib\um\arm64\mscoree.lib`

## Repository State

The ARM64 bring-up now includes:

- ARM64 native dependency generation into `imports\release\lib-ARM64`
- Visual Studio 2026 support in the native dependency scripts
- ARM64 CI jobs and ARM64 package assets
- `SharpSvn.vcxproj` targeting `.NET Framework 4.8.1`
- ARM64 framework linking against `NETFXSDK\4.8.1\Lib\um\arm64`
- NuGet package metadata updated from `net46` to `net481`

## Working Commands

### 1. Build ARM64 native dependencies

Run from the repo root in `cmd.exe`:

```cmd
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
imports\NAnt.0.92.0\tools\NAnt.exe -f:tools\buildbot.build buildbot-build -D:platform=ARM64
```

Success looks like populated libraries under:

```text
imports\release\lib-ARM64
```

### 2. Restore NuGet packages

```cmd
"C:\Users\ava\AppData\Local\Microsoft\WinGet\Packages\Microsoft.NuGet_Microsoft.Winget.Source_8wekyb3d8bbwe\nuget.exe" restore src\SharpSvn.sln
```

### 3. Build `.NET Framework 4.8.1` ARM64

Use the verified helper script in the repo root:

```cmd
cmd.exe /c _codex_arm64_build.cmd
```

That script:

- loads `vcvarsall.bat x64_arm64`
- sets `TargetFrameworkRootPath=C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework`
- prepends `C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8.1\Lib\um\arm64` to `LIB`
- restores NuGet packages
- builds `src\SharpSvn.sln` with:
  - `Configuration=Release`
  - `Platform=ARM64`
  - `BuildBotBuild=true`

### 4. Build `.NET 6` ARM64

Use the separate helper script:

```cmd
cmd.exe /c _codex_arm64_releasecore.cmd
```

That script additionally sets:

- `DOTNET_ROOT=C:\Repos\sharpsvn\.dotnet6`

and builds:

```text
src\SharpSvn\SharpSvn.vcxproj
```

with `Configuration=ReleaseCore` and `Platform=ARM64`.

## Notes

- The 4.8.1 build only started linking successfully after the official
  `.NET Framework 4.8.1 Developer Pack` was installed.
- Before that install, the machine had no ARM64 `MSCOREE.lib`, which blocked
  the framework ARM64 link step.
- The framework package metadata now uses `net481`, which matches the actual
  target framework of the built assembly.
