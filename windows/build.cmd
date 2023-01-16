SETLOCAL

SET ROOT=%~dp0
@REM SET PATH=C:\Program Files\NASM;C:\Strawberry\perl\bin;C:\Program Files\CMake\bin;%PATH%


@IF x%VS_RELEASE%==x (
	SET VS_RELEASE=2008
	REM SET VS_RELEASE=2010
	REM SET VS_RELEASE=2012
	REM SET VS_RELEASE=2013
	REM SET VS_RELEASE=2015
	REM SET VS_RELEASE=2017
	REM SET VS_RELEASE=2019
	REM SET VS_RELEASE=2022
)

@IF x%OPENSSL_VERSION%==x (
	REM SET OPENSSL_VERSION=1.0.1e
	REM SET OPENSSL_VERSION=1.0.1u
	SET OPENSSL_VERSION=1.1.1m
)

@IF x%WXWIDGETS_VERSION%==x (
	REM SET WXWIDGETS_VERSION=2.8.12
	SET WXWIDGETS_VERSION=3.0.5
	REM SET WXWIDGETS_VERSION=3.2.0
)

@IF x%CURL_VERSION%==x (
	REM SET CURL_VERSION=7.39.0
	SET CURL_VERSION=7.81.0
)

@IF x%EXPAT_VERSION%==x (
	REM SET EXPAT_VERSION=2.1.0
	SET EXPAT_VERSION=2.1.1
	REM SET EXPAT_VERSION=2.2.8
	REM SET EXPAT_VERSION=2.5.0
)

@IF x%ZLIB_VERSION%==x (
	SET ZLIB_VERSION=1.2.8
)

@IF x%BDB_VERSION%==x (
	SET BDB_VERSION=6.0.20
	REM SET BDB_VERSION=6.2.23
)

@IF x%LMDB_VERSION%==x (
	SET LMDB_VERSION=0.9.29
)

@IF %VS_RELEASE%==2008 (
	SET VS_VERSION=9.0
	SET VS_GENERATOR=Visual Studio 9 2008
	SET VS_PLATFORMSET=v90
) ELSE IF %VS_RELEASE%==2010 (
	SET VS_VERSION=10.0
	SET VS_GENERATOR=Visual Studio 10 2010
	SET VS_PLATFORMSET=v100
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
) ELSE IF %VS_RELEASE%==2017 (
	REM SET VS_VERSION=14.1
	SET VS_GENERATOR=Visual Studio 15 2017
	SET VS_PLATFORMSET=v141
) ELSE IF %VS_RELEASE%==2019 (
	REM SET VS_VERSION=16.0
	SET VS_GENERATOR=Visual Studio 16 2019
	SET VS_PLATFORMSET=v142
) ELSE IF %VS_RELEASE%==2022 (
	REM SET VS_VERSION=17.0
	SET VS_GENERATOR=Visual Studio 17 2022
	SET VS_PLATFORMSET=v143
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
	SET BUILD_BDB=y
	SET LMDB_DIR=
) ELSE (
	SET BUILD_LMDB=y
	SET LMDB_DIR=%ROOT%lmdb
)
@SET BUILD_TQSL=y
@IF NOT x%1==x (
	SET BUILD_OPENSSL=
	SET BUILD_WXWIDGETS=
	SET BUILD_CURL=
	SET BUILD_EXPAT=
	SET BUILD_ZLIB=
	SET BUILD_BDB=
	SET BUILD_LMDB=
	SET BUILD_TQSL=
)
:opt_loop
@IF x%1==xopenssl (SET BUILD_OPENSSL=y) ELSE ^
IF x%1==xwxwidgets (SET BUILD_WXWIDGETS=y) ELSE ^
IF x%1==xcurl (SET BUILD_CURL=y) ELSE ^
IF x%1==xexpat (SET BUILD_EXPAT=y) ELSE ^
IF x%1==xzlib (SET BUILD_ZLIB=y) ELSE ^
IF x%1==xbdb (SET BUILD_BDB=y) ELSE ^
IF x%1==xlmdb (SET BUILD_LMDB=y) ELSE ^
IF x%1==xtqsl (SET BUILD_TQSL=y) ELSE ^
IF NOT x%1==x (
	ECHO Unrecognized option %1 1>&2
	exit /b 1
)
@SHIFT
@IF NOT x%1==x GOTO opt_loop

@REM If user explicitly asked for Berkeley DB, use it
@IF NOT x%BUILD_BDB%==x (
	SET USE_BDB=y
)

@IF NOT x%USE_64BIT%==x (
	IF NOT %VS_RELEASE% LSS 2022 (
		SET target=amd64
	) ELSE (
		SET target=x86_amd64
	)
	SET build_platform=x64
) ELSE (
	SET target=x86
	SET build_platform=Win32
)
@IF NOT %VS_RELEASE% LSS 2022 (
	call "C:\Program Files\Microsoft Visual Studio\%VS_RELEASE%\Community\VC\Auxiliary\Build\vcvarsall.bat" %target%
) ELSE IF NOT %VS_RELEASE% LSS 2017 (
	call "C:\Program Files (x86)\Microsoft Visual Studio\%VS_RELEASE%\Community\VC\Auxiliary\Build\vcvarsall.bat" %target%
) ELSE (
	call "C:\Program Files (x86)\Microsoft Visual Studio %VS_VERSION%\VC\vcvarsall.bat" %target%
)


@REM 
@REM  Validate that the selected build configuration makes sense
@REM

@IF NOT %EXPAT_VERSION% LSS 2.5.0 (
	IF %VS_RELEASE% LSS 2013 (
		ECHO Expat %EXPAT_VERSION% not supported on Visual Studio before 2013 1>&2
		exit /b 1
	)
)

@IF NOT x%USE_64BIT%==x (
	IF %EXPAT_VERSION% LSS 2.2.8 (
		ECHO Expat %EXPAT_VERSION% does not support 64-bit builds, 2.2.8 is minimum required 1>&2
		exit /b 1
	)
	IF %VS_RELEASE% LSS 2012 (
		ECHO Visual Studio %VS_RELEASE% is not supported for 64-bit builds 1>&2
		exit /b 1
	)
)

@IF %EXPAT_VERSION% LSS 2.2.8 (
	IF NOT %VS_RELEASE% LSS 2019 (
		ECHO Visual Studio %VS_RELEASE% does not support Expat before 2.2.8 1>&2
		exit /b 1
	)
)

@IF %OPENSSL_VERSION% LSS 1.0.1u (
	IF NOT %VS_RELEASE% LSS 2015 (
		ECHO OpenSSL %OPENSSL_VERSION% not supported on Visual Studio %VS_RELEASE%, 1.0.1u is minimum required 1>&2
		exit /b 1
	)
)

@IF %VS_RELEASE% == 2012 (
	IF x%USE_BDB%==x (
		ECHO LMDB is not currently supported on Visual Studio %VS_RELEASE%, USE_BDB=y is needed 1>&2
		exit /b 1
	)
)

@IF NOT x%USE_BDB%==x (
	IF NOT %VS_RELEASE% LSS 2019 (
		ECHO Visual Studio %VS_RELEASE% is not supported for compiling Berkeley DB 1>&2
		exit /b 1
	)
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
@del /s/q openssl 2>NUL
@rmdir /s/q openssl 2>NUL
@del /s/q openssl-%OPENSSL_VERSION% 2>NUL
@rmdir /s/q openssl-%OPENSSL_VERSION% 2>NUL
@7z x "downloads\openssl-%OPENSSL_VERSION%.tar.gz" -so | 7z x -aoa -si -ttar
cd openssl-%OPENSSL_VERSION%
@IF NOT x%USE_64BIT%==x (
	@SET target=VC-WIN64A
) ELSE (
	@SET target=VC-WIN32
)
@IF NOT x%USE_SHARED%==x (
	@SET makefile=ms\ntdll.mak
	@SET opts=shared
) ELSE (
	@SET makefile=ms\nt.mak
	@SET opts=no-shared
)
IF %OPENSSL_VERSION% LSS 1.1 (
	perl Configure %target% --prefix=%ROOT%openssl
	@IF ERRORLEVEL 1 GOTO error
	call ms\do_nasm
	@IF ERRORLEVEL 1 GOTO error
	nmake -f %makefile%
	@IF ERRORLEVEL 1 GOTO error
	nmake -f %makefile% test
	@IF ERRORLEVEL 1 GOTO error
	nmake -f %makefile% install
	@IF ERRORLEVEL 1 GOTO error
) ELSE (
	perl Configure %target% %opts% no-capieng no-async --prefix=%ROOT%openssl --openssldir=%ROOT%openssl\bin\
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
) ELSE (
	@mkdir wxWidgets-%WXWIDGETS_VERSION%
	cd wxWidgets-%WXWIDGETS_VERSION%
	@7z x "..\downloads\wxWidgets-%WXWIDGETS_VERSION%.7z" -aoa
)
@IF NOT x%USE_SHARED%==x (
	@SET shared=1
) ELSE (
	@SET shared=0
)
@IF NOT x%USE_DYNAMIC_CRT%==x (
	@SET crt=dynamic
) ELSE (
	@SET crt=static
)
@IF NOT x%USE_ANSI%==x (
	@SET unicode=0
) ELSE (
	@SET unicode=1
)
@IF NOT x%USE_64BIT%==x (
	@SET arch=AMD64
) ELSE (
	@SET arch=X86
)
cd build\msw
nmake -f makefile.vc BUILD=release SHARED=%shared% UNICODE=%unicode% RUNTIME_LIBS=%crt% TARGET_CPU=%arch%
@IF ERRORLEVEL 1 GOTO error
nmake -f makefile.vc BUILD=debug SHARED=%shared% UNICODE=%unicode% RUNTIME_LIBS=%crt% TARGET_CPU=%arch%
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
@IF NOT x%USE_SHARED%==x (
	@SET mode=dll
) ELSE (
	@SET mode=static
)
@IF NOT x%USE_DYNAMIC_CRT%==x (
	@SET crt=dll
) ELSE (
	@SET crt=static
)
@IF NOT x%USE_64BIT%==x (
	@SET machine=x64
) ELSE (
	@SET machine=x86
)
nmake -f Makefile.vc mode=%mode% ENABLE_WINSSL=yes ENABLE_IDN=no ENABLE_IPV6=no MACHINE=%machine% RTLIBCFG=%crt%
@IF ERRORLEVEL 1 GOTO error
nmake -f Makefile.vc mode=%mode% ENABLE_WINSSL=yes ENABLE_IDN=no ENABLE_IPV6=no MACHINE=%machine% RTLIBCFG=%crt% DEBUG=yes
@IF ERRORLEVEL 1 GOTO error
GOTO end_curl


:expat
@ECHO Building Expat...

@IF NOT x%USE_DYNAMIC_CRT%==x (
	SET crt_opt=OFF
	SET crt_suffix=MD
) ELSE (
	SET crt_opt=ON
	SET crt_suffix=MT
)
@IF NOT x%USE_SHARED%==x (
	SET target=expat
	IF %EXPAT_VERSION% LSS 2.2.8 (
		SET libfile=libexpat.lib
		SET libfiled=libexpatd.lib
	) ELSE (
		SET libfile=expat.lib
		SET libfiled=expatd.lib
	)
	SET shared_opt=ON
) ELSE (
	SET target=expat_static
	IF %EXPAT_VERSION% LSS 2.2.8 (
		SET libfile=libexpatMT.lib
		SET libfiled=libexpatMT.lib
	) ELSE IF %EXPAT_VERSION% LSS 2.5.0 (
		SET libfile=expat%crt_suffix%.lib
		SET libfiled=expatd%crt_suffix%.lib
	) ELSE (
		SET libfile=libexpat%crt_suffix%.lib
		SET libfiled=libexpatd%crt_suffix%.lib
	)
	SET shared_opt=OFF
)

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
IF %EXPAT_VERSION% LSS 2.2.8 (
	@7z x ../expat-vc2008-%EXPAT_VERSION%.zip -aoa
)
@del /s/q Bin\*.* 2>NUL
cd Source
@REM Only expat_static is needed
@REM vcbuild expat.sln "Release|%build_platform%"

@IF NOT %EXPAT_VERSION% LSS 2.2.8 GOTO new_build_expat
msbuild /p:Configuration=Release /p:Platform=%build_platform% /t:%target% expat.sln
@IF ERRORLEVEL 1 GOTO error
copy /y win32\bin\Release\%libfile% ..\Bin\libexpat.lib
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=%build_platform% /t:%target% expat.sln
@IF ERRORLEVEL 1 GOTO error
copy /y win32\bin\Debug\%libfiled% ..\Bin\libexpatd.lib
@IF ERRORLEVEL 1 GOTO error
GOTO end_expat

:new_build_expat
REM CMake requires these missing files
ECHO _ >> Changes
cmake -G "%VS_GENERATOR%" -A %build_platform% -B build -S . ^
    -DEXPAT_SHARED_LIBS=%shared_opt% ^
    -DEXPAT_MSVC_STATIC_CRT=%crt_opt% ^
    -DEXPAT_BUILD_TOOLS=OFF ^
    -DEXPAT_BUILD_EXAMPLES=OFF ^
    -DEXPAT_BUILD_TESTS=OFF
@IF ERRORLEVEL 1 GOTO error

cd build
msbuild /p:Configuration=Release /p:Platform=%build_platform% /t:expat expat.sln
@IF ERRORLEVEL 1 GOTO error
copy /y Release\%libfile% ..\..\Bin\libexpat.lib

@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=%build_platform% /t:expat expat.sln
@IF ERRORLEVEL 1 GOTO error
copy /y Debug\%libfiled% ..\..\Bin\libexpatd.lib
@IF ERRORLEVEL 1 GOTO error
GOTO end_expat


:zlib
@ECHO Building zlib...
@cd %ROOT%
@del /s/q zlib-%ZLIB_VERSION% 2>NUL
@rmdir /s/q zlib-%ZLIB_VERSION% 2>NUL
@7z x "downloads\zlib-%ZLIB_VERSION%.tar.gz" -so | 7z x -aoa -si -ttar
cd zlib-%ZLIB_VERSION%
@IF NOT x%USE_SHARED%==x (
	@SET project=zlib
) ELSE (
	@SET project=zlibstatic
)
@IF NOT x%USE_DYNAMIC_CRT%==x (
	SET release_flags=/MD
	SET debug_flags=/MDd
) ELSE (
	SET release_flags=/MT
	SET debug_flags=/MTd
)
cmake -G "%VS_GENERATOR%" -A %build_platform% -B build -S . ^
    -DCMAKE_C_FLAGS_DEBUG="%debug_flags% /Zi /Ob0 /Od /RTC1" ^
    -DCMAKE_C_FLAGS_RELEASE="%release_flags% /O2 /Ob2 /DNDEBUG"
@IF ERRORLEVEL 1 GOTO error
cd build
@IF %VS_RELEASE%==2008 (
	msbuild /p:Configuration=Debug %project%.vcproj
	@IF ERRORLEVEL 1 GOTO error
	msbuild /p:Configuration=Release %project%.vcproj
	@IF ERRORLEVEL 1 GOTO error
) ELSE (
	@REM msbuild /p:Configuration=Debug ALL_BUILD.vcxproj
	msbuild /p:Configuration=Debug %project%.vcxproj
	@IF ERRORLEVEL 1 GOTO error
	@REM msbuild /p:Configuration=Release ALL_BUILD.vcxproj
	msbuild /p:Configuration=Release %project%.vcxproj
	@IF ERRORLEVEL 1 GOTO error
)
copy /y zconf.h ..
@IF ERRORLEVEL 1 GOTO error
GOTO end_zlib


:bdb
@ECHO Building Berkeley DB...

@IF %VS_RELEASE% LSS 2010 (
	SET solution=Berkeley_DB.sln
) ELSE IF %VS_RELEASE% LSS 2012 (
	SET solution=Berkeley_DB_vs2010.sln
) ELSE (
	IF %BDB_VERSION% LSS 6.2.23 (
		SET solution=Berkeley_DB_vs2010.sln
	) ELSE (
		SET solution=Berkeley_DB_vs2012.sln
	)
)

@cd %ROOT%
@del /s/q db-%BDB_VERSION%.NC 2>NUL
@rmdir /s/q db-%BDB_VERSION%.NC 2>NUL
@7z x "downloads\db-%BDB_VERSION%.NC.zip" -aoa
cd db-%BDB_VERSION%.NC\build_windows
@IF %VS_RELEASE%==2008 (
	vcbuild /upgrade %solution% "Debug|%build_platform%"
	@IF ERRORLEVEL 1 GOTO error
	@IF x%USE_SHARED%==x (
		vcbuild /upgrade %solution% "Static Debug|%build_platform%"
		@IF ERRORLEVEL 1 GOTO error
	)
	vcbuild /upgrade %solution% "Release|%build_platform%"
	@IF ERRORLEVEL 1 GOTO error
	@IF x%USE_SHARED%==x (
		vcbuild /upgrade %solution% "Static Release|%build_platform%"
		@IF ERRORLEVEL 1 GOTO error
	)
) ELSE (
	@IF x%USE_SHARED%==x (
		msbuild /p:Configuration="Static Debug" /p:Platform=%build_platform% /t:db /p:PlatformToolSet=%VS_PLATFORMSET% %solution%
		@IF ERRORLEVEL 1 GOTO error
		msbuild /p:Configuration="Static Release" /p:Platform=%build_platform% /t:db /p:PlatformToolSet=%VS_PLATFORMSET% %solution%
		@IF ERRORLEVEL 1 GOTO error
		move "%build_platform%\Static Debug" "%build_platform%\Static_Debug"
		move "%build_platform%\Static Release" "%build_platform%\Static_Release"
	) ELSE (
		msbuild /p:Configuration="Debug" /p:Platform=%build_platform% /t:db /p:PlatformToolSet=%VS_PLATFORMSET% %solution%
		@IF ERRORLEVEL 1 GOTO error
		msbuild /p:Configuration="Release" /p:Platform=%build_platform% /t:db /p:PlatformToolSet=%VS_PLATFORMSET% %solution%
		@IF ERRORLEVEL 1 GOTO error
	)
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
git reset --hard
@IF ERRORLEVEL 1 GOTO error
git checkout "tags/LMDB_%LMDB_VERSION%"
@IF ERRORLEVEL 1 GOTO error
SET CFLAGS=/c /O2 /DWIN32
@IF %VS_RELEASE%==2008 GOTO apply_fixup
@IF %VS_RELEASE%==2010 GOTO apply_fixup
@IF %VS_RELEASE%==2012 GOTO apply_fixup
GOTO skip_fixup

:apply_fixup
SET CFLAGS=%CFLAGS% /I..\..\..\lmdb-include
copy /Y ..\..\..\lmdb-include\inttypes.h ..\..\include
@IF ERRORLEVEL 1 GOTO error
REM git am ..\..\..\lmdb-vs2008-vs2012.patch
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
@REM TODO Not sure why it changes to schannel from winssl on 64-bit
IF %CURL_VERSION% LSS 7.81.0 (
	SET curl_build=winssl
) ELSE (
	SET curl_build=schannel
)
@IF NOT x%USE_DYNAMIC_CRT%==x (
	SET crt_opt=OFF
) ELSE (
	SET crt_opt=ON
)
@IF NOT x%USE_64BIT%==x (
	SET curl_machine=x64
) ELSE (
	SET curl_machine=x86
)
cmake -G "%VS_GENERATOR%" -A %build_platform% -B build -S . ^
    -DCMAKE_LIBRARY_PATH="%ROOT%expat-%EXPAT_VERSION%\Bin" ^
    -DCMAKE_INCLUDE_PATH="%ROOT%expat-%EXPAT_VERSION%\Source\lib" ^
    -DwxWidgets_ROOT_DIR="%ROOT%wxWidgets-%WXWIDGETS_VERSION%" ^
    -DBDB_INCLUDE_DIR="%ROOT%db-%BDB_VERSION%.NC\build_windows" ^
    -DBDB_LIBRARY="%ROOT%db-%BDB_VERSION%.NC\build_windows\%build_platform%\Static_Release\libdb60s.lib" ^
    -DOPENSSL_ROOT_DIR="%ROOT%openssl" ^
    -DCURL_LIBRARY="%ROOT%curl-%CURL_VERSION%\builds\libcurl-vc-%curl_machine%-release-static-sspi-%curl_build%\lib\libcurl_a.lib" ^
    -DCURL_INCLUDE_DIR="%ROOT%curl-%CURL_VERSION%\builds\libcurl-vc-%curl_machine%-release-static-sspi-%curl_build%\include" ^
    -DUSE_STATIC_MSVCRT=%crt_opt%
@IF ERRORLEVEL 1 GOTO error
IF NOT %VS_RELEASE% LSS 2013 GOTO full_build_tqsl

cd build
@REM Building tests currently has build failures on old VS
msbuild /p:Configuration=Release /p:Platform=%build_platform% /p:CharacterSet=Unicode /t:tqsllib2 TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Release /p:Platform=%build_platform% /p:CharacterSet=Unicode /t:tqslupdater TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Release /p:Platform=%build_platform% /p:CharacterSet=Unicode /t:tqsl TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
@REM msbuild /p:Configuration=Debug /p:Platform=%build_platform% TrustedQSL.sln
@REM @IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=%build_platform% /p:CharacterSet=Unicode /t:tqsllib2 TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=%build_platform% /p:CharacterSet=Unicode /t:tqslupdater TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
msbuild /p:Configuration=Debug /p:Platform=%build_platform% /p:CharacterSet=Unicode /t:tqsl TrustedQSL.sln
@IF ERRORLEVEL 1 GOTO error
GOTO end_tqsl

:full_build_tqsl
cmake --build build --config Release
@IF ERRORLEVEL 1 GOTO error
cmake --build build --config Debug
@IF ERRORLEVEL 1 GOTO error
GOTO end_tqsl


:success
@ECHO Success!
exit /b 0
@GOTO eof


:error
@SET STATUS=%ERRORLEVEL%
@ECHO ************************************ 1>&2
@ECHO There was an error during the build! 1>&2
@ECHO Last command status: %STATUS%
exit /b %STATUS%
@GOTO eof


:eof
