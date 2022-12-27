Build scripts for TrustedQSL
============================

Windows
-------

This contains scripts for automatically building Trusted QSL and all it's dependencies. It currently targets 32-bit Windows 2000 with the VS 2008 toolchain and WinSDK 6.0. Make sure that is installed prior to this. To get started quickly, you can just run the bootstrap script from an elevated PowerShell and it will install all the prerequisites and clone this repository down to the folder it is run from with this command:

    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/penguin359/trustedqsl-builder/main/windows/bootstrap-vs2008.ps1'))

If you are doing this manually, you will also want Chocolatey installed to get some dependencies:

https://chocolatey.org/install#individual

With that, you can install a few prequisites with this:

choco install nasm 7zip StrawberryPerl cmake git tortoisegit trustedqsl
choco install -not-silent git tortoisegit

Download "Visual Studio Express 2012 for Windows Desktop"
https://my.visualstudio.com/Downloads?q=visual%20studio%202012%20express%20for%20windows%20desktop&wt.mc_id=o~msft~vscom~older-downloads
You will need to log in with a valid Microsoft account, but the download is free.

reg add HKEY_CURRENT_USER\Software\Microsoft\WDExpress\11.0\General /v SuppressUppercaseConversion /t REG_DWORD /d 1 /f


Linux
-----

These are scripts for cleaning building Trusted QSL from the ARRL in a
clean environment for Ubuntu. The primary script uses LXD containers
and is run with this command:

    ./tqsl-lxc.sh [22.04]

There is also preliminary support for Docker builds with:

    ./tqsl-docker.sh
