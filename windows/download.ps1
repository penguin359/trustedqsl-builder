Set-StrictMode -Version 3.0

$ErrorActionPreference = "Stop"
$VerboseActionPreference = "Continue"

Import-Module -Name (Join-Path $PSScriptRoot "common.psm1") -DisableNameChecking

$opensslVersions = @{
	"1.0.1e" = @{
		Name = "OpenSSL";
		File = "openssl-1.0.1e.tar.gz";
		Url  = "https://www.openssl.org/source/openssl-1.0.1e.tar.gz";
		Hash = "F74F15E8C8FF11AA3D5BB5F276D202EC18D7246E95F961DB76054199C69C1AE3";
	};
	"1.0.1u" = @{
		Name = "OpenSSL";
		File = "openssl-1.0.1u.tar.gz";
		Url  = "https://www.openssl.org/source/openssl-1.0.1u.tar.gz";
		Hash = "4312B4CA1215B6F2C97007503D80DB80D5157F76F8F7D3FEBBE6B4C56FF26739";
	};
	"1.1.1m" = @{
		Name = "OpenSSL";
		File = "openssl-1.1.1m.tar.gz";
		Url  = "https://www.openssl.org/source/openssl-1.1.1m.tar.gz";
		Hash = "F89199BE8B23CA45FC7CB9F1D8D3EE67312318286AD030F5316ACA6462DB6C96";
	};
}
$opensslDefault = "1.1.1m"
if($env:openssl_VERSION) {
	$opensslDefault = $env:openssl_VERSION
}

$wxWidgetsVersions = @{
	"2.8.12" = @{
		Name = "wxWidgets 2.8";
		File = "wxWidgets-2.8.12.zip";
		Url  = "https://github.com/wxWidgets/wxWidgets/releases/download/v2.8.12/wxMSW-2.8.12.zip";
		Hash = "307D713D8AFFBED69A89418D9C9073193AADFEF4B16DA3D8EF68558A9F57AE88";
	};
	"3.0.5" = @{
		Name = "wxWidgets 3.0";
		File = "wxWidgets-3.0.5.7z";
		Url  = "https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.7z";
		Hash = "33D7E9327CD0192CCC5D69F78C4A98C3C17F190D94F99F1B1C89BD4A47A1D5DC";
	};
	"3.2.0" = @{
		Name = "wxWidgets 3.2";
		File = "wxWidgets-3.2.0.7z";
		Url  = "https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.0/wxWidgets-3.2.0.7z";
		Hash = "AE3516D75C1D8CBA519AC338310E7B3A9E5896E5CDB03396BBE3CE30A42C1A4E";
	};
}
$wxWidgetsDefault = "3.0.5"
if($env:wxWidgets_VERSION) {
	$wxWidgetsDefault = $env:wxWidgets_VERSION
}

#"https://curl.se/download/curl-7.87.0.tar.gz"
#"https://sourceforge.net/projects/expat/files/expat_win32/2.5.0/expat-win32bin-2.5.0.zip/download"
$dependencies = @(
	@{
		Name = "cURL";
		File = "curl-7.39.0.tar.gz";
		Url  = "https://curl.se/download/curl-7.39.0.tar.gz";
		Hash = "A3A7C2B9E7416C728469EB4CB5B61E9161335DF4278329E1D9CC3C194E25D795";
	},
	@{
		Name = "Expat";
		File = "expat-win32bin-2.1.0.exe";
		Url  = "https://sourceforge.net/projects/expat/files/expat_win32/2.1.0/expat-win32bin-2.1.0.exe/download";
		Hash = "FC264700310B882290D69695E576CC75479F3B0D9E144B6CB816864BBA0C2F33";
	},
	@{
		Name = "zlib";
		File = "zlib-1.2.8.tar.gz";
		Url  = "https://www.zlib.net/fossils/zlib-1.2.8.tar.gz";
		Hash = "36658CB768A54C1D4DEC43C3116C27ED893E88B02ECFCB44F2166F9C0B7F2A0D";
	},
	@{
		Name = "Berkeley DB";
		File = "db-6.0.20.NC.zip";
		Url  = "http://download.oracle.com/berkeley-db/db-6.0.20.NC.zip";
		Hash = "140731D64DA8B7E4DDF1C5FD52ED3C41DFE08E00857D48DC41BBEF2795FD6A16";
	}
)

if(-not($opensslVersions[$opensslDefault])) {
	throw "Can't find openssl version $opensslDefault"
}
$dependencies += $opensslVersions[$opensslDefault]

if(-not($wxWidgetsVersions[$wxWidgetsDefault])) {
	throw "Can't find wxWidgets version $wxWidgetsDefault"
}
$dependencies += $wxWidgetsVersions[$wxWidgetsDefault]

$dependencies | ForEach-Object {
	Download-File @_
}

if(-not(Test-Path -Path "lmdb")) {
	echo "Downloading LMDB..."
	git clone -b LMDB_0.9.29 https://github.com/LMDB/lmdb.git
}

if(-not(Test-Path -Path "tqsl")) {
	echo "Downloading Trusted QSL..."
	git clone https://git.code.sf.net/p/trustedqsl/tqsl tqsl
	cd tqsl
	git remote add penguin359 https://penguin359@git.code.sf.net/u/penguin359/trustedqsl
	git remote set-url --push penguin359 ssh://penguin359@git.code.sf.net/u/penguin359/trustedqsl
	git remote update penguin359
	git config remote.pushDefault penguin359
	git switch other-fixes
}
