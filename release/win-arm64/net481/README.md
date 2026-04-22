# SharpSvn Consumer Files for .NET Framework 4.8.1 on Windows ARM64

This folder contains a prebuilt SharpSvn runtime set for applications that
target `.NET Framework 4.8.1` on `Windows ARM64`.

Consumers can use these files directly without compiling SharpSvn locally.

## Required Files

These three files are the required SharpSvn payload:

- `SharpSvn.dll`
- `SharpSvn-DB44-20-ARM64.svnDll`
- `SharpPlink-ARM64.svnExe`

All three files should stay together in the application output directory.

## What Each File Does

- `SharpSvn.dll`
  The managed ARM64 SharpSvn assembly that application code references.
- `SharpSvn-DB44-20-ARM64.svnDll`
  The native ARM64 Subversion runtime bundle loaded by `SharpSvn.dll`.
- `SharpPlink-ARM64.svnExe`
  The ARM64 SSH helper used by SharpSvn for SSH-based Subversion access.

## Optional Files

The following are not required for the basic runtime to start:

- Localized `SharpSvn.resources.dll` files for non-English UI/resources
- `SharpSvn.xml` for IntelliSense/documentation
- `SharpSvn.pdb` for debugging

Those files are available from the build output if needed, but they are not
required for a minimal consumer deployment.

## Runtime Prerequisites

Consumers still need the platform runtime prerequisites installed on the target
machine:

- Microsoft `.NET Framework 4.8.1`
- ARM64 Microsoft Visual C++ runtime compatible with the build toolset

The SharpSvn consumer bundle in this folder does not vendor the Microsoft CRT.

## Verification Notes

The files in this folder were copied from the verified ARM64 framework build:

- `src\SharpSvn\bin\ARM64\Release\SharpSvn.dll`
- `src\SharpSvn\bin\ARM64\Release\SharpPlink-ARM64.svnExe`
- `imports\release\bin\SharpSvn-DB44-20-ARM64.svnDll`

The built `SharpSvn.dll` was verified as an ARM64 binary.
