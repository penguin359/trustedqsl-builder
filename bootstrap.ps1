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
	Write-Warning "$downloadDir"
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

Write-Verbose "Installing prerequisites..."
choco install dotnet3.5

Write-Verbose "Mounting disk image..."
$disk = Mount-DiskImage -ImagePath $imagePath -Access ReadOnly -StorageType ISO
try {
	$volume = $disk | Get-Volume
	$drive = $volume.DriveLetter
	#& "${drive}:\VCExpress\setup.exe"

	#Copy-Item E:\VCExpress\*.* .
	#E:\VCExpress\WCU\vcredistmin_x86.exe  
	#Copy-Item E:\VCExpress\WCU\WinSDK\ . 

	Write-Verbose "Copying files..."
	Remove-Item -LiteralPath temp -Recurse -Force -ErrorAction SilentlyContinue
	New-Item -Name temp -Type Directory | Out-Null
	Copy-Item "${drive}:\VCExpress" temp -Recurse -Force

	attrib -r "temp\VCExpress\baseline.dat"
	# Disable optional components from installing
	Get-Content E:\VCExpress\baseline.dat | ForEach-Object {
		if($_ -eq "DefaultSelected=1") {
			"DefaultSelected=0"
		} elseif($_ -like "*=silverlight*") {
			$_; "DefaultSelected=0"
		} else {
			$_
		}
	} | Out-File -Force "temp\VCExpress\baseline.dat"

	Write-Verbose "Starting installer..."
	Start-Process -Wait -FilePath temp\VCExpress\setup.exe -ArgumentList /qb,/norestart,/log,$env:temp\vc.log -WorkingDirectory temp\VCExpress
	Remove-Item -LiteralPath temp -Recurse -Force -ErrorAction SilentlyContinue
} finally {
	Dismount-DiskImage -ImagePath $imagePath | Out-Null
}

Write-Verbose "Success!"
