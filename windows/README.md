This contains scripts for automatically building Trusted QSL and all it's dependencies. It currently targets 32-bit Windows 2000 with the VS 2008 toolchain and WinSDK 6.0. Make sure that is installed prior to this.

You will also want Chocolatey installed to get some dependencies:

https://chocolatey.org/install#individual

With that, you can install a few prequisites with this:

choco install nasm 7zip StrawberryPerl cmake git tortoisegit trustedqsl
choco install -not-silent git tortoisegit

Download "Visual Studio Express 2012 for Windows Desktop"
https://my.visualstudio.com/Downloads?q=visual%20studio%202012%20express%20for%20windows%20desktop&wt.mc_id=o~msft~vscom~older-downloads
You will need to log in with a valid Microsoft account, but the download is free.

reg add HKEY_CURRENT_USER\Software\Microsoft\WDExpress\11.0\General /v SuppressUppercaseConversion /t REG_DWORD /d 1 /f

