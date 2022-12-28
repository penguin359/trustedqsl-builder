Set-StrictMode -Version 3.0

$ErrorActionPreference = "Stop"
$VerboseActionPreference = "Continue"

$url = 'https://raw.githubusercontent.com/penguin359/trustedqsl-builder/main/windows/common.psm1'
$module = (New-Object System.Net.WebClient).DownloadString($url)
Import-Module (New-Module ([ScriptBlock]::Create($module))) -DisableNameChecking

Install-Chocolatey

Update-LocalEnvironment

Write-Verbose "Installing Git..."
choco install git

Update-LocalEnvironment

Write-Verbose "Cloning builder repository..."
git clone https://github.com/penguin359/trustedqsl-builder

.\trustedqsl-builder\windows\setup-vs2008.bat
