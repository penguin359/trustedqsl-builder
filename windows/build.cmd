SETLOCAL

SET ROOT=%~dp0
@REM SET PATH=C:\Program Files\NASM;C:\Strawberry\perl\bin;C:\Program Files\CMake\bin;%PATH%


@IF x%VS_RELEASE%==x (
	@SET VS_RELEASE=2008
	@REM SET VS_RELEASE=2012
	@REM SET VS_RELEASE=2013
	@REM SET VS_RELEASE=2015
	@REM SET VS_RELEASE=2019
)

@IF x%OPENSSL_VERSION%==x (
	@REM SET OPENSSL_VERSION=1.0.1e
	@REM SET OPENSSL_VERSION=1.0.1u
	@SET OPENSSL_VERSION=1.1.1m
)

@IF x%WXWIDGETS_VERSION%==x (
	@REM SET WXWIDGETS_VERSION=2.8.12
	@SET WXWIDGETS_VERSION=3.0.5
	@REM SET WXWIDGETS_VERSION=3.2.0
)

@IF x%CURL_VERSION%==x (
	@REM SET CURL_VERSION=7.39.0
	@SET CURL_VERSION=7.81.0
)

@IF x%EXPAT_VERSION%==x (
	@SET EXPAT_VERSION=2.1.0
	@REM SET EXPAT_VERSION=2.1.1
	@REM SET EXPAT_VERSION=2.5.0
)

@IF %VS_RELEASE%==2008 (
	SET VS_VERSION=9.0
	SET VS_GENERATOR=Visual Studio 9 2008
	SET VS_PLATFORMSET=v90
) ELSE IF %VS_RELEASE%==2012 (
		SET VS_VERSION=11.0
		SET VS_GENERATOR=Visual Studio 11 2012
		SET VS_PLATFORMSET=v110
) ELSE IF %VS_RELEASE%==2013 (
		SET VS_VERSION=12.0
		SET VS_GENERATOR=Visual Studio 12 2013
		SET VS_PLATFORMSET=v120
) ELSE IF %VS_RELEASE%==2015 (
		SET VS_VERSION=14.0
		SET VS_GENERATOR=Visual Studio 14 2015
		SET VS_PLATFORMSET=v140
) ELSE IF %VS_RELEASE%==2019 (
		SET VS_VERSION=16.0
		SET VS_GENERATOR=Visual Studio 16 2019
		SET VS_PLATFORMSET=v142
) ELSE (
	@ECHO Unrecognized Visual Studio release: %VS_RELEASE% >&2
	exit /b 1
)

@SET BUILD_OPENSSL=y
@SET BUILD_WXWIDGETS=y
@SET BUILD_CURL=y
@SET BUILD_EXPAT=y
@SET BUILD_ZLIB=y
@SET BUILD_BDB=
@SET BUILD_LMDB=
@IF NOT x%USE_BDB%==x (
	@SET BUILD_BDB=y
	@SET LMDB_DIR=
) ELSE (
	@SET BUILD_LMDB=y
	@SET LMDB_DIR=%ROOT%lmdb
)
@SET BUILD_TQSL=y
@IF NOT x%1==x (
	@SET BUILD_OPENSSL=
	@SET BUILD_WXWIDGETS=
	@SET BUILD_CURL=
	@SET BUILD_EXPAT=
	@SET BUILD_ZLIB=
	@SET BUILD_BDB=
	@SET BUILD_LMDB=
	@SET BUILD_TQSL=
:opt_loop
	REM weird syntax error breaking command after label?
	@IF x%1==xopenssl SET BUILD_OPENSSL=y
	@IF x%1==xwxwidgets SET BUILD_WXWIDGETS=y
	@IF x%1==xcurl SET BUILD_CURL=y
	@IF x%1==xexpat SET BUILD_EXPAT=y
	@IF x%1==xzlib SET BUILD_ZLIB=y
	@IF x%1==xbdb SET BUILD_BDB=y
	@IF x%1==xlmdb SET BUILD_LMDB=y
	@IF x%1==xtqsl SET BUILD_TQSL=y
	@SHIFT
	@IF NOT x%1==x GOTO opt_loop
)

@IF %VS_RELEASE%==2019 (
	call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x86
) ELSE (
	call "C:\Program Files (x86)\Microsoft Visual Studio %VS_VERSION%\VC\vcvarsall.bat" x86
)

@REM Change to the correct drive
%~d0
cd %ROOT%

@ECHO Checking for downloads...
CALL download.bat
@IF ERRORLEVEL 1 GOTO error

@IF x%BUILD_OPENSSL%==xy GOTO openssl
:end_openssl
@IF x%BUILD_WXWIDGETS%==xy GOTO wxwidgets
:end_wxwidgets
@IF x%BUILD_CURL%==xy GOTO curl
:end_curl
@IF x%BUILD_EXPAT%==xy GOTO expat
:end_expat
@IF x%BUILD_ZLIB%==xy GOTO zlib
:end_zlib
@IF x%BUILD_BDB%==xy GOTO bdb
:end_bdb
@IF x%BUILD_LMDB%==xy GOTO lmdb
:end_lmdb
@IF x%BUILD_TQSL%==xy GOTO tqsl
:end_tqsl
GOTO success


:openssl
@ECHO Building OpenSSL...
@cd %ROOT%
@del /s/q openssl-%OPENSSL_VERSION% 2>NUL
@rmdir /s/q openssl-%OPENSSL_VERSION% 2>NUL
@7z x "downloads\openssl-%OPENSSL_VERSION%.tar.gz" -so | 7z x -aoa -si -ttar
cd openssl-%OPENSSL_VERSION%
IF %OPENSSL_VERSION% LSS 1.1 (
	perl Configure VC-WIN32 --prefix=%ROOT%openssl
	@IF ERRORLEVEL 1 GOTO error
	call ms\do_nasm
	@IF ERRORLEVEL 1 GOTO error
	@REM Use ntdll.mak for DLL
	nmake -f ms\nt.mak
	@IF ERRORLEVEL 1 GOTO error
	nmake -f ms\nt.mak test
	@IF ERRORLEVEL 1 GOTO error
	nmake -f ms\nt.mak install
	@IF ERRORLEVEL 1 GOTO error
) ELSE (
	perl Configure VC-WIN32 no-shared no-capieng no-async --prefix=%ROOT%openssl --openssldir=%ROOT%openssl\bin\
	@IF ERRORLEVEL 1 GOTO error
	nmake
	@IF ERRORLEVEL 1 GOTO error
	@REM Currently broken on 1.1.1m
	@REM nmake test
	@REM IF ERRORLEVEL 1 GOTO error
	nmake install
	@IF ERRORLEVEL 1 GOTO error
)
@IF NOT %VS_RELEASE%==2008 (
	cd ..\openssl\lib
	@mkdir VC
	move *.lib VC/
	@IF ERRORLEVEL 1 GOTO error
)
GOTO end_openssl


:wxwidgets
@ECHO Building wxWidgets...
@cd %ROOT%
@del /s/q wxWidgets-%WXWIDGETS_VERSION% 2>NUL
@rmdir /s/q wxWidgets-%WXWIDGETS_VERSION% 2>NUL
IF %WXWIDGETS_VERSION% LSS 3.0 (
	@7z x "downloads\wxWidgets-%WXWIDGETS_VERSION%.zip" -aoa 
	move wxMSW-%WXWIDGETS_VERSION% wxWidgets-%WXWIDGETS_VERSION%
	cd wxWidgets-%WXWIDGETS_VERSION%
	@REM Needed for VS 2012 and newer
	"C:\Program Files\Git\usr\bin\sed.exe" -i.bak -e "s/\(#include.*<pbt\.h>\)/\/\/\1/" src\msw\window.cpp
	@REM cd build\msw
	@REM nmake -f makefile.vc BUILD=release SHARED=0 UNICODE=1
	@REM @IF ERRORLEVEL 1 GOTO error
	@REM nmake -f makefile.vc BUILD=debug SHARED=0 UNICODE=1
	@REM @IF ERRORLEVEL 1 GOTO error
) ELSE (
	@mkdir wxWidgets-%WXWIDGETS_VERSION%
	cd wxWidgets-%WXWIDGETS_VERSION%
	@7z x "..\downloads\wxWidgets-%WXWIDGETS_VERSION%.7z" -aoa 
)
cd build\msw
@REM nmake -f makefile.vc BUILD=release SHARED=0 UNICODE=1 RUNTIME_LIBS=static CPU=X86
nmake -f makefile.vc BUILD=release SHARED=0 UNICODE=1 CPU=X86
@IF ERRORLEVEL 1 GOTO error
@REM nmake -f makefile.vc BUILD=debug SHARED=0 UNICODE=1 RUNTIME_LIBS=static CPU=X86
nmake -f makefile.vc BUILD=debug SHARED=0 UNICODE=1 CPU=X86
@IF ERRORLEVEL 1 GOTO error
GOTO end_wxwidgets


:curl
@ECHO Building cURL...
@cd %ROOT%
@del /s/q curl-%CURL_VERSION% 2>NUL
@rmdir /s/q curl-%CURL_VERSION% 2>NUL
@7z x "downloads\curl-%CURL_VERSION%.tar.gz" -so | 7z x -aoa -si -ttar
cd curl-%CURL_VERSION%\winbuild
"C:\Program Files\Git\usr\bin\sed.exe" -i.bak -e '/HAVE.*ADDRINFO/s/define\([ \t]\+[A-Za-z0-9_]\+\).*/undef \1/' ../lib/config-win32.h
@REM mode=dll for DLL
nmake -f Makefile.vc mode=static ENABLE_WINSSL=yes ENABLE_IDN=no ENABLE_IPV6=no
@IF ERRORLEVEL 1 GOTO error
GOTO end_curl


:expat
@ECHO Building Expat...
@cd %ROOT%
@del /s/q expat-%EXPAT_VERSION% 2>NUL
@rmdir /s/q expat-%EXPAT_VERSION% 2>NUL
IF %EXPAT_VERSION% LSS 2.3.0 (
	@start /w .\downloads\expat-win32bin-%EXPAT_VERSION%.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="expat-%EXPAT_VERSION%"
	cd expat-%EXPAT_VERSION%
) ELSE (
	@mkdir expat-%EXPAT_VERSION%
	cd expat-%EXPAT_VERSION%
	@7z x "..\downloads\expat-win32bin-%EXPAT_VERSION%.zip" -aoa 
)
@7z x ../expat-vc2008-%EXPAT_VERSION%.zip -aoa 
cd Source
@REM Only expat_static is needed
@REM vcbuild expat.sln "Release|Win32"
msbuild /p:Configuration=Release /p:Platform=Win32 /t:expat_static expat.sln
@IF ERRORLEVEL 1 GOTO error
copy /y win32\bin\Release\libexpatMT.lib ..\Bin\libexpat.lib
@IF ERRORLEVEL 1 GOTO error
GOTO end_expat


:zlib
@ECHO Building zlib...
@cd %ROOT%
@del /s/q zlib-1.2.8 2>NUL
@rmdir /s/q zlib-1.2.8 2>NUL
@7z x "downloads\zlib-1.2.8.tar.gz" -so | 7z x -aoa -si -ttar
cd zlib-1.2.8
cmake -G "%VS_GENERATOR%" -B build -S .
@IF ERRORLEVEL 1 GOTO error
cd build
@IF %VS_RELEASE%==2008 (
	msbuild /p:Configuration=Debug zlibstatic.vcproj
	@IF ERRORLEVEL 1 GOTO error
	msbuild /p:Configuration=Release zlibstatic.vcproj
	@IF ERRORLEVEL 1 GOTO error
) ELSE (
	@REM msbuild /p:Configuration=Debug ALL_BUILD.vcxproj
	msbuild /p:Configuration=Debug zlibstatic.vcxproj
	@IF ERRORLEVEL 1 GOTO error
	@REM msbuild /p:Configuration=Release ALL_BUILD.vcxproj
	msbuild /p:Configuration=Release zlibstatic.vcxproj
	@IF ERRORLEVEL 1 GOTO error
)
copy /y zconf.h ..
@IF ERRORLEVEL 1 GOTO error
GOTO end_zlib


:bdb
@ECHO Building Berkeley DB...
@cd %ROOT%
@del /s/q db-6.0.20.NC 2>NUL
@rmdir /s/q db-6.0.20.NC 2>NUL
@7z x "downloads\db-6.0.20.NC.zip" -aoa 
cd db-6.0.20.NC\build_windows
@IF %VS_RELEASE%==2008 (
	vcbuild /upgrade Berkeley_DB.sln "Debug|Win32"
	@IF ERRORLEVEL 1 GOTO error
	vcbuild /upgrade Berkeley_DB.sln "Static Debug|Win32"
	@IF ERRORLEVEL 1 GOTO error
	vcbuild /upgrade Berkeley_DB.sln "Release|Win32"
	@IF ERRORLEVEL 1 GOTO error
	vcbuild /upgrade Berkeley_DB.sln "Static Release|Win32"
	@IF ERRORLEVEL 1 GOTO error
) ELSE (
	@REM msbuild /p:Configuration="Debug" /p:Platform=Win32 /t:db /p:PlatformToolSet=%VS_PLATFORMSET% Berkeley_DB_vs2010.sln
	@REM @IF ERRORLEVEL 1 GOTO error
	msbuild /p:Configuration="Static Debug" /p:Platform=Win32 /t:db /p:PlatformToolSet=%VS_PLATFORMSET% Berkeley_DB_vs2010.sln
	@IF ERRORLEVEL 1 GOTO error
	@REM msbuild /p:Configuration="Release" /p:Platform=Win32 /t:db /p:PlatformToolSet=%VS_PLATFORMSET% Berkeley_DB_vs2010.sln
	@REM @IF ERRORLEVEL 1 GOTO error
	msbuild /p:Configuration="Static Release" /p:Platform=Win32 /t:db /p:PlatformToolSet=%VS_PLATFORMSET% Berkeley_DB_vs2010.sln
	@IF ERRORLEVEL 1 GOTO error
	move "Win32\Static Debug" "Win32\Static_Debug"
	move "Win32\Static Release" "Win32\Static_Release"
)
GOTO end_bdb


:lmdb
@ECHO Building LMDB...
@cd %ROOT%
cd lmdb
IF NOT EXIST include mkdir include
IF NOT EXIST lib mkdir lib
cd libraries\liblmdb
@del /s/q *.obj 2>NUL
@del /s/q *.lib 2>NUL
SET CFLAGS=/c /O2 /DWIN32
@IF %VS_RELEASE%==2008 GOTO apply_fixup
@IF %VS_RELEASE%==2010 GOTO apply_fixup
@IF %VS_RELEASE%==2012 GOTO apply_fixup
GOTO skip_fixup

:apply_fixup
SET CFLAGS=%CFLAGS% /I..\..\..\lmdb-include
copy /Y ..\..\..\lmdb-include\inttypes.h ..\..\include
@IF ERRORLEVEL 1 GOTO error
git reset --hard origin/mdb.master
@IF ERRORLEVEL 1 GOTO error
git am ..\..\..\lmdb-vs2008-vs2012.patch
@IF ERRORLEVEL 1 GOTO error

:skip_fixup
echo cl %CFLAGS% mdb.c
cl %CFLAGS% mdb.c
@IF ERRORLEVEL 1 GOTO error
cl %CFLAGS% midl.c
@IF ERRORLEVEL 1 GOTO error
lib /out:lmdb.lib *.obj
@IF ERRORLEVEL 1 GOTO error
copy /Y *.h ..\..\include
@IF ERRORLEVEL 1 GOTO error
copy /Y *.lib ..\..\lib
@IF ERRORLEVEL 1 GOTO error
GOTO end_lmdb


:tqsl
@ECHO Building Trusted QSL...
@cd %ROOT%
cd tqsl
@del /s/q build 2>NUL
@rmdir /s/q build 2>NUL
@REM cmake -DCMAKE_LIBRARY_PATH="%ROOT%expat-%EXPAT_VERSION%\Bin" -DCMAKE_INCLUDE_PATH="%ROOT%expat-%EXPAT_VERSION%\Source\lib" -DwxWidgets_ROOT_DIR="%ROOT%wxWidgets-%WXWIDGETS_VERSION%" -DBDB_INCLUDE_DIR="%ROOT%db-6.0.20.NC\build_windows" -DBDB_LIBRARY="%ROOT%db-6.0.20.NC\build_windows\Win32\Static_Release\libdb60s.lib" -DOPENSSL_ROOT_DIR=%ROOT%openssl -DCURL_LIBRARY=%ROOT%curl-%CURL_VERSION%\builds\libcurl-vc-x86-release-static-sspi-winssl\lib\libcurl_a.lib -DCURL_INCLUDE_DIR=%ROOT%curl-%CURL_VERSION%\builds\libcurl-vc-x86-release-static-sspi-winssl\include -DwxWidgets_LIB_DIR=%ROOT%wxWidgets-%WXWIDGETS_VERSION%\lib\vc_lib -DZLIB_LIBRARY_REL=%ROOT%zlib-1.2.8\build\Release\zlibstatic.lib -DZLIB_INCLUDE_DIR=%ROOT%zlib-1.2.8 -G "%VS_GENERATOR%" -A Win32 -B build -S .
cmake -DCMAKE_LIBRARY_PATH="%ROOT%expat-%EXPAT_VERSION%\Bin" -DCMAKE_INCLUDE_PATH="%ROOT%expat-%EXPAT_VERSION%\Source\lib" -DwxWidgets_ROOT_DIR="%ROOT%wxWidgets-%WXWIDGETS_VERSION%" -DBDB_INCLUDE_DIR="%ROOT%db-6.0.20.NC\build_windows" -DBDB_LIBRARY="%ROOT%db-6.0.20.NC\build_windows\Win32\Static_Release\libdb60s.lib" -DOPENSSL_ROOT_DIR="%ROOT%openssl" -DCURL_LIBRARY="%ROOT%curl-%CURL_VERSION%\builds\libcurl-vc-x86-release-static-sspi-winssl\lib\libcurl_a.lib" -DCURL_INCLUDE_DIR="%ROOT%curl-%CURL_VERSION%\builds\libcurl-vc-x86-release-static-sspi-winssl\include" -G "%VS_GENERATOR%" -A Win32 -B build -S .
@IF ERRORLEVEL 1 GOTO error
@REM cmake --build build
cd build
@REM Building tests currently has build failures
@REM msbuild /p:Configuration=Release /p:Platform=Win32 TrustedQSL.sln
@REM @IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Release /p:Platform=Win32 /p:CharacterSet=Unicode /t:tqsllib2 TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Release /p:Platform=Win32 /p:CharacterSet=Unicode /t:tqslupdater TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Release /p:Platform=Win32 /p:CharacterSet=Unicode /t:tqsl TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
@REM msbuild /p:Configuration=Debug /p:Platform=Win32 TrustedQSL.sln
@REM @IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=Win32 /p:CharacterSet=Unicode /t:tqsllib2 TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=Win32 /p:CharacterSet=Unicode /t:tqslupdater TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=Win32 /p:CharacterSet=Unicode /t:tqsl TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
GOTO end_tqsl


:success
@ECHO Success!
@GOTO eof


:error
@SET STATUS=%ERRORLEVEL%
@ECHO ************************************ 1>&2
@ECHO There was an error during the build! 1>&2
@ECHO Last command status: %STATUS%
exit /b %STATUS%
@GOTO eof


:eof
