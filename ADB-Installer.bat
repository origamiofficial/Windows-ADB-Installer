@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_VERSION=2.0.0"
set "ADB_HOME=%LOCALAPPDATA%\Android"
set "ADB_TOOLS_DIR=%ADB_HOME%\platform-tools"
set "ADB_EXE=%ADB_TOOLS_DIR%\adb.exe"
set "ADB_ZIP_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

if not "%~1"=="" (
  set "ACTION=%~1"
  set "NON_INTERACTIVE=1"
  goto dispatch
)

:menu
cls
echo Windows ADB Installer v%SCRIPT_VERSION%
echo.
echo 1. Check if ADB is installed
echo 2. Install ADB
echo 3. Update ADB
echo 4. Remove ADB
echo 5. Exit
echo.
set "ACTION="
set /p "ACTION=Select an option: "
if not defined ACTION goto menu

:dispatch
call :normalize_action "%ACTION%"
if errorlevel 1 (
  echo.
  echo Invalid selection: %ACTION%
  if defined NON_INTERACTIVE exit /b 1
  pause
  goto menu
)

if "%ACTION%"=="1" call :check_adb
if "%ACTION%"=="2" call :install_adb
if "%ACTION%"=="3" call :update_adb
if "%ACTION%"=="4" call :remove_adb
if "%ACTION%"=="5" exit /b 0
set "RESULT=%ERRORLEVEL%"

if defined NON_INTERACTIVE exit /b %RESULT%
echo.
pause
goto menu

:normalize_action
set "ACTION="
for /f "tokens=* delims= " %%A in ("%~1") do set "ACTION=%%A"
if not defined ACTION exit /b 1
if "%ACTION%"=="1" exit /b 0
if "%ACTION%"=="2" exit /b 0
if "%ACTION%"=="3" exit /b 0
if "%ACTION%"=="4" exit /b 0
if "%ACTION%"=="5" exit /b 0
if /I "%ACTION%"=="check"  set "ACTION=1" & exit /b 0
if /I "%ACTION%"=="install" set "ACTION=2" & exit /b 0
if /I "%ACTION%"=="update" set "ACTION=3" & exit /b 0
if /I "%ACTION%"=="remove" set "ACTION=4" & exit /b 0
if /I "%ACTION%"=="uninstall" set "ACTION=4" & exit /b 0
if /I "%ACTION%"=="exit" set "ACTION=5" & exit /b 0
exit /b 1

:check_adb
echo.
if exist "%ADB_EXE%" (
  echo Managed ADB install found at:
  echo %ADB_EXE%
) else (
  echo No managed ADB install was found at:
  echo %ADB_EXE%
)
echo.
where.exe adb >nul 2>&1
if errorlevel 1 (
  echo ADB is not available on PATH.
  exit /b 1
)

echo ADB is available on PATH.
echo.
adb version
exit /b %ERRORLEVEL%

:install_adb
echo.
echo Installing ADB to:
echo %ADB_TOOLS_DIR%
echo.

call :download_and_extract
if errorlevel 1 exit /b 1

call :ensure_user_path "%ADB_TOOLS_DIR%"
if errorlevel 1 exit /b 1

call :ensure_current_session_path "%ADB_TOOLS_DIR%"

if not exist "%ADB_EXE%" (
  echo Installation finished, but adb.exe was not found.
  exit /b 1
)

echo Installation completed successfully.
echo.
"%ADB_EXE%" version
exit /b %ERRORLEVEL%

:update_adb
echo.
echo Updating ADB...
call :install_adb
exit /b %ERRORLEVEL%

:remove_adb
echo.
echo Removing managed ADB install...

call :remove_user_path "%ADB_TOOLS_DIR%"
if errorlevel 1 exit /b 1

if exist "%ADB_TOOLS_DIR%" (
  rmdir /S /Q "%ADB_TOOLS_DIR%"
)

if exist "%ADB_HOME%" (
  2>nul rmdir "%ADB_HOME%"
)

if exist "%ADB_EXE%" (
  echo Failed to remove %ADB_TOOLS_DIR%
  exit /b 1
)

echo Managed ADB files removed.
where.exe adb >nul 2>&1
if not errorlevel 1 (
  echo Another adb.exe is still available on PATH.
)
exit /b 0

:download_and_extract
set "TEMP_DIR=%TEMP%\adb-installer-%RANDOM%%RANDOM%"
set "TEMP_ZIP=%TEMP_DIR%\platform-tools.zip"

if exist "%TEMP_DIR%" rmdir /S /Q "%TEMP_DIR%"
mkdir "%TEMP_DIR%" >nul 2>&1
if errorlevel 1 (
  echo Failed to create temporary folder:
  echo %TEMP_DIR%
  exit /b 1
)

if not exist "%ADB_HOME%" mkdir "%ADB_HOME%" >nul 2>&1
if errorlevel 1 (
  echo Failed to create ADB directory:
  echo %ADB_HOME%
  call :cleanup_temp "%TEMP_DIR%"
  exit /b 1
)

echo Downloading platform-tools from Google...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%ADB_ZIP_URL%' -OutFile '%TEMP_ZIP%'"
if errorlevel 1 (
  echo Download failed.
  call :cleanup_temp "%TEMP_DIR%"
  exit /b 1
)

if exist "%ADB_TOOLS_DIR%" (
  rmdir /S /Q "%ADB_TOOLS_DIR%"
)

echo Extracting archive...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%TEMP_ZIP%' -DestinationPath '%ADB_HOME%' -Force"
if errorlevel 1 (
  echo Extraction failed.
  call :cleanup_temp "%TEMP_DIR%"
  exit /b 1
)

call :cleanup_temp "%TEMP_DIR%"
exit /b 0

:cleanup_temp
if exist "%~1" rmdir /S /Q "%~1"
exit /b 0

:ensure_current_session_path
echo ;%PATH%; | find /I ";%~1;" >nul
if errorlevel 1 set "PATH=%PATH%;%~1"
exit /b 0

:ensure_user_path
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$target='%~1'.TrimEnd('\'); $userPath=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@(); if($userPath){$parts=$userPath -split ';' | Where-Object { $_ }}; $exists=$false; foreach($part in $parts){ if($part.TrimEnd('\') -ieq $target){ $exists=$true; break } }; if(-not $exists){ if($parts.Count -eq 0){ $newPath=$target } else { $newPath=($parts + $target) -join ';' }; [Environment]::SetEnvironmentVariable('Path',$newPath,'User') }"
if errorlevel 1 (
  echo Failed to update the user PATH.
  exit /b 1
)
exit /b 0

:remove_user_path
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$target='%~1'.TrimEnd('\'); $userPath=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@(); if($userPath){ foreach($part in ($userPath -split ';')){ if($part -and $part.TrimEnd('\') -ine $target){ $parts += $part } } }; [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')"
if errorlevel 1 (
  echo Failed to update the user PATH.
  exit /b 1
)
exit /b 0
