#!/bin/sh

set -e

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo chown "$user" "$x11_socket"
sudo chmod u=rw,go= "$x11_socket"

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
sudo DEBIAN_FRONTEND=noninteractive apt install -y wget dpkg-dev gcc cmake libssl-dev liblmdb-dev libdb5.3-dev libexpat1-dev zlib1g-dev libcurl4-gnutls-dev libwxgtk3.0-gtk3-dev libfuse2 trustedqsl
# Install some development tools
sudo DEBIAN_FRONTEND=noninteractive apt install -y inotify-tools doxygen
rm -fr ~/raw
mkdir ~/raw
cd ~/raw
#git clone git://git.code.sf.net/p/trustedqsl/tqsl
#git clone git://git.code.sf.net/u/penguin359/trustedqsl
git clone ssh://penguin359@git.code.sf.net/u/penguin359/trustedqsl
wget http://www.arrl.org/tqsl/tqsl-2.6.5.tar.gz
rm -fr tqsl-2.6.5
tar xvf tqsl-2.6.5.tar.gz
cd tqsl-2.6.5
cmake -B build -S .
cmake --build build
sudo cmake --install build
sudo ldconfig
echo "===> Testing tqsl binary..."
tqsl --version 2>&1 | grep --color 'TQSL Version 2\..*'
cd
