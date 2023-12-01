@ECHO OFF
powershell.exe -Version 3.0 -ExecutionPolicy Unrestricted -NoProfile -File "%~dp0download.ps1" %*
