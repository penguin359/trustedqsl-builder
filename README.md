# Build scripts for TrustedQSL

This contains scripts for automatically building [Trusted QSL](http://www.arrl.org/tqsl-download) and all it's dependencies. There are scripts for doing a complete build in a clean-room environment for both [Windows](README.md#Windows) and [Linux](README.md#Linux).

## Windows

For Windows, it currently targets 32-bit builds compatible with Windows 2000 using the Visual C++ 2008 toolchain and WinSDK 6.0. You will need to install several tools first before the software and it's components can be built. You can follow this guide to set up the environment or you can use the [setup-vs2008.bat](windows/setup-vs2008.bat) script in the _windows_ folder to install all the tools for you automatically. For the absolute quickest method, you can run the following command in PowerShell which will bootstrap setup by cloning this repo and then running the setup script for you. **Note:** This command as well as the setup script need to be run from an elevated PowerShell. Right-click on the Windows Start Menu and select "Windows PowerShell (admin)" (or "Terminal (Admin)" on Windows 11). Run the following command:

    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/penguin359/trustedqsl-builder/main/windows/bootstrap-vs2008.ps1'))

If the bootstrap was successful, it should print out "Success!" at the end and you should have a folder called "trustedqsl-builder" in the location you ran the bootstrap. All prequisites should be set up and ready to run the main build.cmd script. The build script does not need to be run as an Administrator.

Alternatively, just clone this repo and place it anywhere you want on your system, but the path should not include any spaces in it. You can then run `.\windows\setup-vs2008.bat` to automatically install all the prerequisites or follow the guide in [Manual Setup](README.md#manual-setup).


### Manual Setup

If you wish to use Visual Studio 2012, which has a nicer interface, it is recommended to install that first. Once that is installed, you can proceed with installing Visual C++ 2008. You can download a copy of VC 2008 from this link:

http://download.microsoft.com/download/8/B/5/8B5804AD-4990-40D0-A6AA-CE894CBBB3DC/VS2008ExpressENUX1397868.iso

Double-click on the ISO and look for Setup.hta on the CD image. Select "Microsoft Visual C++ 2008 Express Edition". You do not need to install any of the optional components when it asks you. To get the remaining components you will need, I recommend using the [Chocolatey](https://chocolatey.org/) package manager which can be installed using the instructions from this page:

https://chocolatey.org/install#individual

Once Chocolatey is installed, you can install the rest of the build tools needed with this command:

    choco install nasm 7zip StrawberryPerl cmake git tortoisegit trustedqsl
 
If you want to manually change some of the defaults used by the installers such as [Git](https://git-scm.com/), you can use the `-not-silent` switch to have it show the regular installer once it's downloaded:

    choco install -not-silent git tortoisegit

If you would rather install them yourself, you can find the necessary build tools at these links:

  * NASM: https://www.nasm.us/
  * 7-Zip: https://www.7-zip.org/
  * Perl: https://strawberryperl.com/
  * CMake: https://cmake.org/download/
  * Git: https://git-scm.com/download/win
  * TortoiseGit: https://tortoisegit.org/download/
  * Trusted QSL: http://www.arrl.org/tqsl-download

Once all tools are installed, open up a "Visual Studio 2008 Command Prompt" and verify that all the tools are found. You may need to reboot or update the Path environment variable under the System control panel.

  * `nasm --version`
  * `perl --version`
  * `cmake --version`
  * `cl`
  * `nmake /?`
  * `7z`

All of those commands should return some output indicating the software version. If some are missing, make sure the following directories are in your System Path environment variable:

  * C:\Program Files\7-Zip
  * C:\Program Files\CMake\bin
  * C:\Program Files\NASM
  * C:\Strawberry\perl\bin

Once all the tools above are in your path, you should be able to run windows\build.cmd to start the full build of Trusted QSL and all of it's components. This does not require an Administrator command prompt.

## Visual Studio 2012 Notes

Download "[Visual Studio Express 2012 for Windows Desktop](https://my.visualstudio.com/Downloads?q=visual%20studio%202012%20express%20for%20windows%20desktop&wt.mc_id=o~msft~vscom~older-downloads)".
You will need to log in with a valid Microsoft account, but the download is free.

This command will suppress the all-caps menus that VS 2012 uses.

    reg add HKEY_CURRENT_USER\Software\Microsoft\WDExpress\11.0\General /v SuppressUppercaseConversion /t REG_DWORD /d 1 /f


Linux
-----

These are scripts for cleaning building Trusted QSL from the ARRL in a
clean environment for Ubuntu. The primary script uses LXD containers
and is run with this command:

    ./tqsl-lxc.sh [22.04]

There is also preliminary support for Docker builds with:

    ./tqsl-docker.sh
