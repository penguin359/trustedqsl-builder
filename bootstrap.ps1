# Set-ExecutionPolicy -Scope Process Unrestricted -Force

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
#Write-Output $PSScriptRoot
#Write-Output $scriptDir
#return 0
Set-Location -LiteralPath $scriptDir

if(-not(Test-Path -Path downloads)) {
	New-Item -Name downloads -Type Directory | Out-Null
}

$url = "http://download.microsoft.com/download/8/B/5/8B5804AD-4990-40D0-A6AA-CE894CBBB3DC/VS2008ExpressENUX1397868.iso"
$file = "downloads\VS2008ExpressENUX1397868.iso"
$hash = "632318EF0DF5BAD58FCB99852BD251243610E7A4D84213C45B4F693605A13EAD"

Write-Output "Checking for existing download of VC++ 2008..."
if(-not(Test-Path -Path $file) -or (Get-FileHash -Path $file -Algorithm SHA256).Hash -ne $hash) {
	Remove-Item -Force -Path $file -ErrorAction SilentlyContinue
	Write-Output "Downloading VC++ 2008..."
	Invoke-WebRequest -Uri $url -OutFile $file
}
if((Get-FileHash -Path $file -Algorithm SHA256).Hash -ne $hash) {
	Write-Error "Downloaded file is corrupted!"
	return 1
}

Write-Output "Installing prerequisites..."
choco install dotnet3.5

Write-Output "Mounting disk image..."
$disk = Mount-DiskImage -ImagePath "${scriptDir}\${file}" -Access ReadOnly -StorageType ISO
$volume = $disk | Get-Volume
$drive = $volume.DriveLetter
#& "${drive}:\VCExpress\setup.exe"

#Copy-Item E:\VCExpress\*.* .
#E:\VCExpress\WCU\vcredistmin_x86.exe  
#Copy-Item E:\VCExpress\WCU\WinSDK\ . 

Write-Output "Copying files..."
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

Write-Output "Starting installer..."
Start-Process -Wait -FilePath temp\VCExpress\setup.exe -ArgumentList /qb,/norestart,/log,$env:temp\vc.log -WorkingDirectory temp\VCExpress
Remove-Item -LiteralPath temp -Recurse -Force -ErrorAction SilentlyContinue

Dismount-DiskImage -ImagePath "${scriptDir}\${file}" | Out-Null

Write-Output "Success!"
