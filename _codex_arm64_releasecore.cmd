@echo off
REM Modified by Wrism Innovations in 2026 to add Windows ARM64 and .NET Framework 4.8.1 support.
setlocal

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
if errorlevel 1 exit /b %errorlevel%

set "TargetFrameworkRootPath=C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework"
set "LIB=C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8.1\Lib\um\arm64;%LIB%"
set "DOTNET_ROOT=C:\Repos\sharpsvn\.dotnet6"
set "PATH=%DOTNET_ROOT%;%PATH%"

"C:\Users\ava\AppData\Local\Microsoft\WinGet\Packages\Microsoft.NuGet_Microsoft.Winget.Source_8wekyb3d8bbwe\nuget.exe" restore src\SharpSvn.sln
if errorlevel 1 exit /b %errorlevel%

"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" /r /v:m /p:Platform=ARM64 /p:Configuration=ReleaseCore /p:BuildBotBuild=true /p:BuildProjectReferences=false /p:SolutionDir=C:\Repos\sharpsvn\src\ /p:TargetFrameworkRootPath="%TargetFrameworkRootPath%" src\SharpSvn\SharpSvn.vcxproj
exit /b %errorlevel%
