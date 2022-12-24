$WebClient = New-Object System.Net.WebClient
echo "Downloading OpenSSL..."
$WebClient.DownloadFile("https://www.openssl.org/source/openssl-1.0.1e.tar.gz", "openssl-1.0.1e.tar.gz")
echo "Downloading wxWidgets..."
$WebClient.DownloadFile("https://github.com/wxWidgets/wxWidgets/releases/download/v2.8.12/wxMSW-2.8.12.zip", "wxMSW-2.8.12.zip")
echo "Downloading cURL..."
$WebClient.DownloadFile("https://curl.se/download/curl-7.39.0.tar.gz", "curl-7.39.0.tar.gz")
#$WebClient.DownloadFile("https://curl.se/download/curl-7.87.0.tar.gz", "curl-7.87.0.tar.gz")
echo "Downloading Expat..."
$WebClient.DownloadFile("https://sourceforge.net/projects/expat/files/expat_win32/2.1.0/expat-win32bin-2.1.0.exe/download", "expat-win32bin-2.1.0.exe")
#$WebClient.DownloadFile("https://sourceforge.net/projects/expat/files/expat_win32/2.5.0/expat-win32bin-2.5.0.zip/download", "expat-win32bin-2.5.0.zip")
echo "Downloading zlib..."
$WebClient.DownloadFile("https://www.zlib.net/fossils/zlib-1.2.8.tar.gz", "zlib-1.2.8.tar.gz")
echo "Downloading Berkeley DB..."
$WebClient.DownloadFile("http://download.oracle.com/berkeley-db/db-6.0.20.NC.zip", "db-6.0.20.NC.zip")

echo "Downloading Trusted QSL..."
git clone https://git.code.sf.net/p/trustedqsl/tqsl tqsl
cd tqsl
git remote add penguin359 https://penguin359@git.code.sf.net/u/penguin359/trustedqsl
git remote set-url --push penguin359 ssh://penguin359@git.code.sf.net/u/penguin359/trustedqsl
git remote update penguin359
git config remote.pushDefault penguin359
git switch ansi-fix
