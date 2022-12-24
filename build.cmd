SETLOCAL

SET ROOT=%~dp0
@SET PATH=C:\Program Files\NASM;C:\Strawberry\perl\bin;C:\Program Files\CMake\bin;%PATH%

ECHO ROOT=%ROOT%

REM This file is broken on my system.
REM call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" x86

REM Change to the correct drive
%~d0
cd %ROOT%

IF NOT EXIST tqsl CALL download.bat
IF EXIST vcvars2008.bat CALL vcvars2008.bat

@GOTO openssl
:end_openssl
@GOTO wxwidgets
:end_wxwidgets
@GOTO curl
:end_curl
@GOTO zlib
:end_zlib
@GOTO bdb
:end_bdb
@GOTO expat
:end_expat
@GOTO tqsl
:end_tqsl
GOTO success

:openssl
@ECHO Building OpenSSL...
@cd %ROOT%
@del /s/q openssl-1.0.1e
@rmdir /s/q openssl-1.0.1e
@7z x "openssl-1.0.1e.tar.gz" -so | 7z x -aoa -si -ttar
cd openssl-1.0.1e
perl Configure VC-WIN32 --prefix=%ROOT%openssl
@IF ERRORLEVEL 1 GOTO error
call ms\do_nasm
@IF ERRORLEVEL 1 GOTO error
nmake -f ms\nt.mak
@IF ERRORLEVEL 1 GOTO error
nmake -f ms\nt.mak test
@IF ERRORLEVEL 1 GOTO error
nmake -f ms\nt.mak install
@IF ERRORLEVEL 1 GOTO error
cd ..\openssl\lib
@mkdir VC
move *.lib VC/
@IF ERRORLEVEL 1 GOTO error
GOTO end_openssl

:wxwidgets
@ECHO Building wxWidgets...
@cd %ROOT%
@del /s/q wxMSW-2.8.12
@rmdir /s/q wxMSW-2.8.12
@7z x "wxMSW-2.8.12.zip" -aoa 
cd wxMSW-2.8.12\include\wx\msw
copy setup0.h setup.h
@IF ERRORLEVEL 1 GOTO error
cd ..\..\..\src\msw
REM Hack on window.cpp, not needed?
cd ..\..\build\msw
nmake -f makefile.vc BUILD=release SHARED=0
@IF ERRORLEVEL 1 GOTO error
nmake -f makefile.vc BUILD=debug SHARED=0
@IF ERRORLEVEL 1 GOTO error
GOTO end_wxwidgets

:curl
@ECHO Building cURL...
@cd %ROOT%
@del /s/q curl-7.39.0
@rmdir /s/q curl-7.39.0
@7z x "curl-7.39.0.tar.gz" -so | 7z x -aoa -si -ttar
cd curl-7.39.0\winbuild
nmake -f Makefile.vc mode=static ENABLE_WINSSL=yes ENABLE_IDN=no
@IF ERRORLEVEL 1 GOTO error
GOTO end_curl

:zlib
@ECHO Building zlib...
@cd %ROOT%
@del /s/q zlib-1.2.8
@rmdir /s/q zlib-1.2.8
@7z x "zlib-1.2.8.tar.gz" -so | 7z x -aoa -si -ttar
cd zlib-1.2.8
cmake -G "Visual Studio 9 2008" -B build -S .
@IF ERRORLEVEL 1 GOTO error
cd build
REM msbuild /p:Configuration=Debug ALL_BUILD.vcxproj
msbuild /p:Configuration=Debug zlibstatic.vcproj
@IF ERRORLEVEL 1 GOTO error
REM msbuild /p:Configuration=Release ALL_BUILD.vcxproj
msbuild /p:Configuration=Release zlibstatic.vcproj
@IF ERRORLEVEL 1 GOTO error
copy /y zconf.h ..
@IF ERRORLEVEL 1 GOTO error
GOTO end_zlib

:bdb
@ECHO Building Berkeley DB...
@cd %ROOT%
@del /s/q db-6.0.20.NC
@rmdir /s/q db-6.0.20.NC
@7z x "db-6.0.20.NC.zip" -aoa 
cd db-6.0.20.NC\build_windows
vcbuild /upgrade Berkeley_DB.sln "Debug|Win32"
@IF ERRORLEVEL 1 GOTO error
vcbuild /upgrade Berkeley_DB.sln "Static Debug|Win32"
@IF ERRORLEVEL 1 GOTO error
vcbuild /upgrade Berkeley_DB.sln "Release|Win32"
@IF ERRORLEVEL 1 GOTO error
vcbuild /upgrade Berkeley_DB.sln "Static Release|Win32"
@IF ERRORLEVEL 1 GOTO error
GOTO end_bdb

:expat
@ECHO Building Expat...
@cd %ROOT%
@del /s/q expat-2.1.0
@rmdir /s/q expat-2.1.0
@start /w .\expat-win32bin-2.1.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="expat-2.1.0"
cd expat-2.1.0
@7z x ../expat-vc2008.zip -aoa 
cd Source
vcbuild expat.sln "Release|Win32"
@IF ERRORLEVEL 1 GOTO error
copy /y win32\bin\Release\libexpatMT.lib ..\Bin\libexpat.lib
@IF ERRORLEVEL 1 GOTO error
GOTO end_expat

:tqsl
@ECHO Building Trusted QSL...
@cd %ROOT%
cd tqsl
@del /s/q build32-vs2008
@rmdir /s/q build32-vs2008
cmake -DCMAKE_LIBRARY_PATH="%ROOT%expat-2.1.0\Bin" -DCMAKE_INCLUDE_PATH="%ROOT%expat-2.1.0\Source\lib" -DwxWidgets_ROOT_DIR="%ROOT%wxMSW-2.8.12" -DBDB_INCLUDE_DIR="%ROOT%db-6.0.20.NC\build_windows" -DBDB_LIBRARY="%ROOT%db-6.0.20.NC\build_windows\Win32\Static_Release\libdb60s.lib" -DOPENSSL_ROOT_DIR=%ROOT%openssl -DCURL_LIBRARY=%ROOT%curl-7.39.0\builds\libcurl-vc-x86-release-static-ipv6-sspi-winssl\lib\libcurl_a.lib -DCURL_INCLUDE_DIR=%ROOT%curl-7.39.0\builds\libcurl-vc-x86-release-static-ipv6-sspi-winssl\include -DwxWidgets_ROOT_DIR=%ROOT%wxMSW-2.8.12 -DwxWidgets_LIB_DIR=%ROOT%wxMSW-2.8.12\lib\vc_lib -DZLIB_LIBRARY_REL=%ROOT%zlib-1.2.8\build\Release\zlibstatic.lib -DZLIB_INCLUDE_DIR=%ROOT%zlib-1.2.8 -G "Visual Studio 9 2008" -A Win32 -B build32-vs2008 -S .
@IF ERRORLEVEL 1 GOTO error
REM cmake --build build32-vs2008
cd build32-vs2008
REM Building tests currently has build failures
REM vcbuild TrustedQSL.sln "Release|Win32"
vcbuild src/tqsllib2.vcproj "Release|Win32"
vcbuild apps/tqslupdater.vcproj "Release|Win32"
vcbuild apps/tqsl.vcproj "Release|Win32"
@IF ERRORLEVEL 1 GOTO error
GOTO end_tqsl

:success
@ECHO Success!
@GOTO eof

:error
@ECHO ************************************ 1>&2
@ECHO There was an error during the build! 1>&2
@GOTO eof

:eof
