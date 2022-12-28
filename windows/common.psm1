Set-StrictMode -Version 3.0

function Test-CommandExists {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Command
	)

	try {
		$oldErrorAction = $ErrorActionPreference
		$ErrorActionPreference = "stop"
		if(Get-Command $Command) {
			return $true
		}
	} catch {
		# Suppress the exception
	} finally {
		$ErrorActionPreference = $oldErrorAction
	}

	return $false
}

function Add-Path($Path) {
	$Path = [Environment]::GetEnvironmentVariable("PATH", "Machine") + [IO.Path]::PathSeparator + $Path
	[Environment]::SetEnvironmentVariable( "Path", $Path, "Machine" )
}

function Update-Path {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path,

		[Parameter(Mandatory=$true)]
		[string]$Command
	)
	
	if(-not(Test-CommandExists $Command)) {
		$commandPath = Join-Path $Path $Command
		if(Test-Path -Path $commandPath) {
			Write-Verbose "Adding path entry for $Command"
			Add-Path $Path
		} else {
			Write-Warning "Failed to find $Command in $Path"
		}
	}
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Test-FileHash {
	param(
		[Parameter(Mandatory=$true)]
		[string]$File,

		[Parameter()]
		[string]$Hash
	)

	Write-Debug "File: $File, Hash: $Hash"
	$Hash -eq "" -or `
	(Get-FileHash -Path $File -Algorithm SHA256).Hash -eq $Hash
}

function Download-File {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Url,

		[Parameter(Mandatory=$true)]
		[string]$File,

		[Parameter()]
		[string]$Hash,

		[Parameter()]
		[string]$Name
	)

	if($Name -eq "") {
		$Name = $File
	}

	$downloadDir = Join-Path $PSScriptRoot "downloads"
	$downloadFile = Join-Path $downloadDir $File
	if(-not(Test-Path -Path $downloadDir)) {
		New-Item -Path $downloadDir -Type Directory | Out-Null
	}

	Write-Verbose "Checking for existing download of ${Name}..."
	if(-not(Test-Path -Path $downloadFile) -or
	   -not(Test-FileHash $downloadFile $Hash)) {
		Remove-Item -Force -Path $downloadFile -ErrorAction SilentlyContinue
		Write-Verbose "Downloading ${Name}..."
		Invoke-WebRequest -UserAgent "Wget" -Uri $Url -OutFile $downloadFile
		if(-not(Test-Path -Path $downloadFile) -or
		   -not(Test-FileHash $downloadFile $Hash)) {
			Write-Error "Downloaded file $downloadFile is missing or corrupted!"
			return
		}
	}

	Write-Output $downloadFile
}

function Install-Chocolatey {
	if(-not(Test-CommandExists choco)) {
		Write-Verbose "Installing Chocolatey package manager..."
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
		iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	}

	if(-not(Test-CommandExists Update-SessionEnvironment)) {
		if(-not($env:ChocolateyInstall)) {
			$env:ChocolateyInstall = Join-Path $env:ProgramData "chocolatey"
		}
		$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
		if (Test-Path($ChocolateyProfile)) {
			Import-Module "$ChocolateyProfile"
		}
	}
}

function Update-LocalEnvironment {
	Update-SessionEnvironment
}

Export-ModuleMember -Function Test-CommandExists,Update-Path,New-TemporaryDirectory,Download-File,Install-Chocolatey,Update-LocalEnvironment
