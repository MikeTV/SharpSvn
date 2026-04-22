@echo off
setlocal

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
if errorlevel 1 exit /b %errorlevel%

set "TargetFrameworkRootPath=C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework"
set "LIB=C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8.1\Lib\um\arm64;%LIB%"

"C:\Users\ava\AppData\Local\Microsoft\WinGet\Packages\Microsoft.NuGet_Microsoft.Winget.Source_8wekyb3d8bbwe\nuget.exe" restore src\SharpSvn.sln
if errorlevel 1 exit /b %errorlevel%

"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" /r /v:m /p:Platform=ARM64 /p:Configuration=Release /p:BuildBotBuild=true /p:TargetFrameworkRootPath="%TargetFrameworkRootPath%" src\SharpSvn.sln
exit /b %errorlevel%
