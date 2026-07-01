@echo off
setlocal enabledelayedexpansion
REM Runs hooks/<subdir>/<name>.sh via bash (Git Bash / WSL), cross-platform.
REM Usage: run-hook.cmd <subdir> <name>   e.g. run-hook.cmd session-start bootstrap
REM stdin is inherited so PreToolUse JSON reaches the script's `cat`.
REM Delayed expansion (!ERRORLEVEL!) is required: %ERRORLEVEL% inside a
REM parenthesized block expands at parse time (before bash runs) -> always 0,
REM which would swallow a PreToolUse DENY (exit 2).
set "HOOK_DIR=%~1"
set "HOOK_NAME=%~2"
set "SCRIPT=%~dp0%HOOK_DIR%\%HOOK_NAME%.sh"

REM Prefer Git for Windows bash; bare `where bash` resolves to the WSL stub
REM (C:\Windows\System32\bash.exe), which fails when no distro is installed.
if exist "C:\Program Files\Git\bin\bash.exe" (
  "C:\Program Files\Git\bin\bash.exe" "%SCRIPT%"
  exit /b !ERRORLEVEL!
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
  "C:\Program Files (x86)\Git\bin\bash.exe" "%SCRIPT%"
  exit /b !ERRORLEVEL!
)

REM Fall back to bash on PATH (MSYS2 / Cygwin / user-installed Git Bash)
where bash >nul 2>nul
if !ERRORLEVEL! equ 0 (
  bash "%SCRIPT%"
  exit /b !ERRORLEVEL!
)

REM No usable bash: exit silently so the plugin still loads (no context injection).
exit /b 0
