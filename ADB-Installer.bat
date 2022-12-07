@echo off

rem Check if the script is up to date
setlocal enabledelayedexpansion
set SCRIPT_URL=https://raw.githubusercontent.com/origamiofficial/Windows-ADB-Installer/main/ADB-Installer.bat
set TEMP_FILE=%temp%\adb_installer_temp.bat
if exist %TEMP_FILE% del %TEMP_FILE%
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%SCRIPT_URL%', '%TEMP_FILE%')"
set /p SCRIPT_VERSION=<%TEMP_FILE%
set /a LOCAL_SCRIPT_VERSION=!SCRIPT_VERSION:~17,-1!
set /p CURRENT_SCRIPT_VERSION=<1.2
set /a CURRENT_SCRIPT_VERSION=!CURRENT_SCRIPT_VERSION:~17,-1!

if !CURRENT_SCRIPT_VERSION! LSS !LOCAL_SCRIPT_VERSION! (
  rem Update the script
  copy /y %TEMP_FILE% %0
  echo Script updated to version %LOCAL_SCRIPT_VERSION%
) else (
  echo Script is up to date
)

rem Ask the user for the action they want to perform
echo Select any one of the options below:
echo 1. Check if ADB is installed
echo 2. Install ADB
echo 3. Update ADB
echo 4. Remove ADB
echo 5. Exit
set /p USER_SELECTION=

rem Perform the selected action
if %USER_SELECTION%==1 (
  rem Check if ADB is installed
  set ADB_COMMAND=adb

  rem Check if the ADB command is available in the PATH environment variable
  set PATH_VAR=%PATH%
  for %%f in (%PATH_VAR%) do (
    if exist "%%f\%ADB_COMMAND%" (
      set ADB_INSTALLED=1
      goto adb_installed
    )
  )

  echo ADB is not installed
  goto end

  :adb_installed
  echo ADB is installed
  echo Running "adb version" to check the version...
  echo.
  adb version

  :end
) else if %USER_SELECTION%==2 (
  rem Install ADB
  echo Downloading ADB zip file...
  set ADB_ZIP_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip
  set TEMP_FOLDER=%temp%\adb_installer_temp
  set ADB_FOLDER=C:\ADB
  set ADB_PATH=%ADB_FOLDER%\platform-tools
  if not exist %TEMP_FOLDER% mkdir %TEMP_FOLDER%
  if exist %TEMP_FOLDER%\adb.zip del %TEMP_FOLDER%\adb.zip
  powershell -command "(New-Object System.Net.WebClient).DownloadFile('%ADB_ZIP_URL%', '%TEMP_FOLDER%\adb.zip')"

if not exist %ADB_FOLDER% mkdir %ADB_FOLDER%
if exist %ADB_PATH% rmdir /S /Q %ADB_PATH%
echo Extracting ADB files...
7z x %TEMP_FOLDER%\adb.zip -o%ADB_FOLDER%

rem Add ADB to the PATH environment variable
echo Adding ADB to the PATH environment variable...
set PATH=%PATH%;%ADB_PATH%

rem Check if ADB is installed
if exist %windir%\System32\adb.exe (
  echo ADB is installed
  echo Running "adb version" to check the version...
  echo.
  adb version
) else (
  echo Failed to install ADB
)

rem Clean up
if exist %TEMP_FOLDER%\adb.zip del %TEMP_FOLDER%\adb.zip
if exist %TEMP_FOLDER% rmdir /S /Q %TEMP_FOLDER%

) else if %USER_SELECTION%==3 (
  rem Update ADB
  if exist %windir%\System32\adb.exe (
    rem ADB is installed, so update it
    call %0 2
  ) else (
    rem ADB is not installed, so ask the user if they want to install it
    echo ADB is not installed. Do you want to install it?
    echo 1. Yes
    echo 2. No
    set /p USER_CONFIRMATION=
    if %USER_CONFIRMATION%==1 (
      call %0 2
    )
  )
) else if %USER_SELECTION%==4 (
  rem Remove ADB
  if exist %windir%\System32\adb.exe (
    rem ADB is installed, so remove it
    echo Removing ADB...
    set ADB_FOLDER=C:\ADB
    set ADB_PATH=%ADB_FOLDER%\platform-tools
    rmdir /S /Q %ADB_PATH%
    echo ADB has been removed
  ) else (
    echo ADB is not installed
  )
) else if %USER_SELECTION%==5 (
  rem Exit the script
  exit
)

