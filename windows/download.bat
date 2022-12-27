@ECHO OFF
cd %~dp0
powershell.exe -ExecutionPolicy Unrestricted -File "download.ps1"
