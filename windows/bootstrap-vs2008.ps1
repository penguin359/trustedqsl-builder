$ErrorActionPreference = "Stop"
$VerboseActionPreference = "Continue"

$parent = [System.IO.Path]::GetTempPath()
[string] $name = [System.Guid]::NewGuid()
$name += ".psm1"
$file = $null
try {
	$file = New-Item -ItemType File -Path (Join-Path $parent $name)
	(New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/penguin359/trustedqsl-builder/main/windows/common.psm1', $file)
	Import-Module -Name $file -DisableNameChecking
} finally {
	if($file -ne $null) {
		Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
	}
}

Install-Chocolatey

Update-LocalEnvironment

Write-Verbose "Installing Git..."
choco install git

Update-LocalEnvironment

Write-Verbose "Cloning builder repository..."
git clone https://github.com/penguin359/trustedqsl-builder

.\trustedqsl-builder\windows\setup-vs2008.bat
