# Set-ExecutionPolicy -Scope Process Unrestricted -Force

$ErrorActionPreference = "Stop"

#$scriptDir = $PSScriptRoot
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Set-Location -LiteralPath $scriptDir

function Test-CommandExists {
	param(
		[Parameter(Mandatory)]
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
		[Parameter(Mandatory)]
		[string]$Path,

		[Parameter(Mandatory)]
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
		[Parameter(Mandatory)]
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
		[Parameter(Mandatory)]
		[string]$Url,

		[Parameter(Mandatory)]
		[string]$File,

		[Parameter()]
		[string]$Hash,

		[Parameter()]
		[string]$Name
	)

	if($Name -eq "") {
		$Name = $File
	}

	$downloadDir = Join-Path $scriptDir (Join-Path "downloads" "b")
	$downloadFile = Join-Path $downloadDir $File
	if(-not(Test-Path -Path $downloadDir)) {
		New-Item -Path $downloadDir -Type Directory | Out-Null
	}

	Write-Verbose "Checking for existing download of ${Name}..."
	if(-not(Test-Path -Path $downloadFile) -or
	   -not(Test-FileHash $downloadFile $Hash)) {
		Remove-Item -Force -Path $downloadFile -ErrorAction SilentlyContinue
		Write-Verbose "Downloading ${Name}..."
		Invoke-WebRequest -Uri $Url -OutFile $downloadFile
		if(-not(Test-Path -Path $downloadFile) -or
		   -not(Test-FileHash $downloadFile $Hash)) {
			Write-Error "Downloaded file $downloadFile is missing or corrupted!"
			return
		}
	}

	Write-Output $downloadFile
}

$VisualStudio2008 = @{
	Name = "VC++ 2008";
	Url = "http://download.microsoft.com/download/8/B/5/8B5804AD-4990-40D0-A6AA-CE894CBBB3DC/VS2008ExpressENUX1397868.iso";
	File = "VS2008ExpressENUX1397868.iso";
	Hash = "632318EF0DF5BAD58FCB99852BD251243610E7A4D84213C45B4F693605A13EAD";
}

$imagePath = Download-File @VisualStudio2008

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

Update-SessionEnvironment

Write-Verbose "Installing IDE prerequisites..."
choco install dotnet3.5

Write-Verbose "Mounting disk image..."
$disk = Mount-DiskImage -ImagePath $imagePath -Access ReadOnly -StorageType ISO
try {
	$volume = $disk | Get-Volume
	$drive = $volume.DriveLetter

	Write-Verbose "Copying files..."
	$tempDir = New-TemporaryDirectory 
	Copy-Item "${drive}:\VCExpress" $tempDir -Recurse -Force

	attrib -r "${tempDir}\VCExpress\baseline.dat"
	# Disable optional components from installing
	Get-Content "${drive}:\VCExpress\baseline.dat" | ForEach-Object {
		if($_ -eq "DefaultSelected=1") {
			"DefaultSelected=0"
		} elseif($_ -like "*=silverlight*") {
			$_; "DefaultSelected=0"
		} else {
			$_
		}
	} | Out-File -Force "${tempDir}\VCExpress\baseline.dat"

	Write-Verbose "Starting installer..."
	Start-Process -Wait -FilePath "${tempDir}\VCExpress\setup.exe" -ArgumentList /qb,/norestart,/log,$env:temp\vc.log -WorkingDirectory "${tempDir}\VCExpress"
} finally {
	if($tempDir -ne $null) {
		Write-Verbose "Cleaning up files..."
		Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
	}
	Write-Verbose "Unmounting disk image..."
	Dismount-DiskImage -ImagePath $imagePath | Out-Null
}

Write-Verbose "Installing other build tools..."
choco install nasm 7zip StrawberryPerl cmake git tortoisegit trustedqsl

Update-SessionEnvironment

Update-Path -Path (Join-Path $env:ProgramFiles "CMake\bin") -Command cmake.exe
Update-Path -Path (Join-Path $env:ProgramFiles "NASM") -Command nasm.exe

Update-SessionEnvironment

Write-Verbose "Success!"
