[CmdletBinding()] param()

$ErrorActionPreference = "Stop"

Import-Module -Name (Join-Path $PSScriptRoot "common.psm1") -DisableNameChecking

Install-Chocolatey

refreshenv

Write-Verbose "Installing other build tools..."
choco install nasm trustedqsl

dir $env:ProgramFiles
dir ${env:ProgramFiles(x86)}

Update-Path -Path (Join-Path $env:ProgramFiles "NASM") -Command nasm.exe
Update-Path -Path (Join-Path ${env:ProgramFiles(x86)} "NASM") -Command nasm.exe

refreshenv

Write-Verbose "Success!"
