[CmdletBinding()] param()

$ErrorActionPreference = "Stop"

Import-Module -Name (Join-Path $PSScriptRoot "common.psm1") -DisableNameChecking

Write-Verbose "Installing other build tools..."
choco --no-progress install nasm trustedqsl

Update-Path -Path (Join-Path $env:ProgramFiles "NASM") -Command nasm.exe

Update-LocalEnvironment

Write-Verbose "Success!"
