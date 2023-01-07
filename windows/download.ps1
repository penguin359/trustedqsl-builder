[CmdletBinding()] param ()

Set-StrictMode -Version 3.0

$ErrorActionPreference = "Stop"
$VerboseActionPreference = "Continue"

Import-Module -Name (Join-Path $PSScriptRoot "common.psm1") -DisableNameChecking

$downloads = @{
	"openssl" = @{
		Name = "OpenSSL";
		DefaultVersion = "1.1.1m";
		Files = @{
			"1.0.1e" = @{
				File = "openssl-1.0.1e.tar.gz";
				Url  = "http://www.north-winds.org/tqsl/openssl-1.0.1e.tar.gz";
				Hash = "F74F15E8C8FF11AA3D5BB5F276D202EC18D7246E95F961DB76054199C69C1AE3";
			};
			"1.0.1u" = @{
				File = "openssl-1.0.1u.tar.gz";
				Url  = "http://www.north-winds.org/tqsl/openssl-1.0.1u.tar.gz";
				Hash = "4312B4CA1215B6F2C97007503D80DB80D5157F76F8F7D3FEBBE6B4C56FF26739";
			};
			"1.1.1m" = @{
				File = "openssl-1.1.1m.tar.gz";
				Url  = "http://www.north-winds.org/tqsl/openssl-1.1.1m.tar.gz";
				Hash = "F89199BE8B23CA45FC7CB9F1D8D3EE67312318286AD030F5316ACA6462DB6C96";
			};
		};
	};
	wxwidgets = @{
		Name = "wxWidgets";
		DefaultVersion = "3.0.5";
		Files = @{
			"2.8.12" = @{
				File = "wxWidgets-2.8.12.zip";
				Url  = "http://www.north-winds.org/tqsl/wxMSW-2.8.12.zip";
				Hash = "307D713D8AFFBED69A89418D9C9073193AADFEF4B16DA3D8EF68558A9F57AE88";
			};
			"3.0.5" = @{
				File = "wxWidgets-3.0.5.7z";
				Url  = "http://www.north-winds.org/tqsl/wxWidgets-3.0.5.7z";
				Hash = "33D7E9327CD0192CCC5D69F78C4A98C3C17F190D94F99F1B1C89BD4A47A1D5DC";
			};
			"3.2.0" = @{
				File = "wxWidgets-3.2.0.7z";
				Url  = "http://www.north-winds.org/tqsl/wxWidgets-3.2.0.7z";
				Hash = "AE3516D75C1D8CBA519AC338310E7B3A9E5896E5CDB03396BBE3CE30A42C1A4E";
			};
		};
	};
	curl = @{
		Name = "cURL";
		DefaultVersion = "7.81.0";
		Files = @{
			"7.39.0" = @{
				File = "curl-7.39.0.tar.gz";
				Url  = "http://www.north-winds.org/tqsl/curl-7.39.0.tar.gz";
				Hash = "A3A7C2B9E7416C728469EB4CB5B61E9161335DF4278329E1D9CC3C194E25D795";
			};
			"7.81.0" = @{
				File = "curl-7.81.0.tar.gz";
				Url  = "http://www.north-winds.org/tqsl/curl-7.81.0.tar.gz";
				Hash = "AC8E1087711084548D788EF18B9B732C8DE887457B81F616FC681D1044B32F98";
			};
		};
	};
	expat = @{
		Name = "Expat";
		DefaultVersion = "2.1.1";
		Files = @{
			"2.1.0" = @{
				File = "expat-win32bin-2.1.0.exe";
				Url  = "http://www.north-winds.org/tqsl/expat-win32bin-2.1.0.exe";
				Hash = "FC264700310B882290D69695E576CC75479F3B0D9E144B6CB816864BBA0C2F33";
			};
			"2.1.1" = @{
				File = "expat-win32bin-2.1.1.exe";
				Url  = "http://www.north-winds.org/tqsl/expat-win32bin-2.1.1.exe";
				Hash = "EBF438297B52CA617BF0E00D264CC7A998A50534D023466AD66F4BD66359B534";
			};
			"2.2.8" = @{
				File = "expat-win32bin-2.2.8.exe";
				Url  = "http://www.north-winds.org/tqsl/expat-win32bin-2.2.8.exe";
				Hash = "48DAEC6F027411C4B8D04499366CBD724C05AAA4F09D02B5A822A3FE41FA9335";
			};
			"2.5.0" = @{
				File = "expat-win32bin-2.5.0.zip";
				Url  = "http://www.north-winds.org/tqsl/expat-win32bin-2.5.0.zip"
				Hash = "5A4E79500B0919FC29D83A72DD75B19A373DB62248D1DC3F6388D8127BAB1C1F";
			};
		};
	};
	zlib = @{
		Name = "zlib";
		DefaultVersion = "1.2.8";
		Files = @{
			"1.2.8" = @{
				File = "zlib-1.2.8.tar.gz";
				#Url  = "http://www.north-winds.org/tqsl/zlib-1.2.8.tar.gz";
				Url  = "https://www.zlib.net/fossils/zlib-1.2.8.tar.gz";
				Hash = "36658CB768A54C1D4DEC43C3116C27ED893E88B02ECFCB44F2166F9C0B7F2A0D";
			};
		};
	};
}

if($env:USE_SQLITE3) {
	$downloads["sqlite3"] = @{
		Name = "SQLite 3";
		DefaultVersion = "3440200";
		Files = @{
			"3440200" = @{
				File = "sqlite-amalgamation-3440200.zip";
				Url  = "http://www.north-winds.org/tqsl/sqlite-amalgamation-3440200.zip";
				Hash = "833be89b53b3be8b40a2e3d5fedb635080e3edb204957244f3d6987c2bb2345f";
			};
		};
	}
} elseif($env:USE_BDB) {
	$downloads["bdb"] = @{
		Name = "Berkeley DB";
		DefaultVersion = "6.0.20";
		Files = @{
			"6.0.20" = @{
				File = "db-6.0.20.NC.zip";
				Url  = "http://www.north-winds.org/tqsl/db-6.0.20.NC.zip";
				Hash = "140731D64DA8B7E4DDF1C5FD52ED3C41DFE08E00857D48DC41BBEF2795FD6A16";
			};
			"6.2.23" = @{
				File = "db-6.2.23.NC.zip";
				Url  = "http://www.north-winds.org/tqsl/db-6.2.23.NC.zip";
				Hash = "9A904C5A6A7905311861184E3B048320DC015E3C7818643AAAA6DDE02F2C8E04";
			};
		};
	}
}

$lmdbDefault = "0.9.29"
if($env:lmdb_VERSION) {
	$lmdbDefault = $env:lmdb_VERSION
}

foreach($entry in $downloads.GetEnumerator()) {
	$displayName = $entry.Value.Name
	$version = $entry.Value.DefaultVersion
	$envName = "env:$($entry.Name)_VERSION"
	$envValue = Get-Item $envName -ErrorAction SilentlyContinue
	if($envValue) {
		$envValue = $envValue.Value
	}
	if($envValue) {
		$version = $envValue
	}
	if(-not($entry.Value.Files[$version])) {
		throw "Can't find $displayName version $version"
	}
	Download-File -Name $displayName `
		-File $entry.Value.Files[$version].File `
		-Url $entry.Value.Files[$version].Url `
		-Hash $entry.Value.Files[$version].Hash
}

if(-not($env:USE_BDB)) {
	$lmdbDir = Join-Path $PSScriptRoot "lmdb"
	if(-not(Test-Path -Path $lmdbDir)) {
		echo "Downloading LMDB..."
		git clone -b "LMDB_$lmdbDefault" http://github.com/LMDB/lmdb.git $lmdbDir
		if(-not($?)) {
			throw "Can't clone LMDB version $lmdbDefault"
		}
	}
}

$branch = "other-fixes"
if($env:TQSL_BRANCH) {
	$branch = $env:TQSL_BRANCH
}
$tqslDir = Join-Path $PSScriptRoot "tqsl"
if(-not(Test-Path -Path $tqslDir)) {
	echo "Downloading Trusted QSL..."
	#git clone https://git.code.sf.net/p/trustedqsl/tqsl $tqslDir
	#git clone -b $branch git://git.code.sf.net/u/penguin359/trustedqsl $tqslDir
	git clone -b $branch https://penguin359@git.code.sf.net/u/penguin359/trustedqsl $tqslDir
	if(-not($?)) {
		throw "Can't clone Trusted QSL"
	}
	#cd $tqslDir
	#git remote add penguin359 https://penguin359@git.code.sf.net/u/penguin359/trustedqsl
	#git remote add penguin359 git://git.code.sf.net/u/penguin359/trustedqsl
	#git remote set-url --push penguin359 ssh://penguin359@git.code.sf.net/u/penguin359/trustedqsl
	#git remote update penguin359
	#git config remote.pushDefault penguin359
	#git switch $branch
}
