# Set-ExecutionPolicy -Scope Process Unrestricted -Force

[CmdletBinding()] param()

$ErrorActionPreference = "Stop"

#$scriptDir = $PSScriptRoot
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Verbose "me!"
echo ("IV: " + $MyInvocation.MyCommand.Definition)
echo "SD: ${scriptDir}"
echo "PS: ${PSScriptRoot}"

Set-Location -LiteralPath $scriptDir

Import-Module -Name (Join-Path $scriptDir "common.psm1") -DisableNameChecking

$VisualStudio2008 = @{
	Name = "VC++ 2008";
	Url = "http://download.microsoft.com/download/8/B/5/8B5804AD-4990-40D0-A6AA-CE894CBBB3DC/VS2008ExpressENUX1397868.iso";
	File = "VS2008ExpressENUX1397868.iso";
	Hash = "632318EF0DF5BAD58FCB99852BD251243610E7A4D84213C45B4F693605A13EAD";
}

$imagePath = Download-File @VisualStudio2008

Install-Chocolatey

Update-LocalEnvironment

return

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

Update-LocalEnvironment

Update-Path -Path (Join-Path $env:ProgramFiles "CMake\bin") -Command cmake.exe
Update-Path -Path (Join-Path $env:ProgramFiles "NASM") -Command nasm.exe

Update-LocalEnvironment

Write-Verbose "Success!"
