#!/usr/bin/env bash

set -e

. /etc/os-release

if [ "$VERSION_ID" = "14.04" ]; then
	VERSION_CODENAME="trusty"
fi

user="$(id -un)"
group="$(id -gn)"

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi
if [ -f /tmp/cookies ]; then
	touch ~/.Xauthority
	xauth merge /tmp/cookies
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo mkdir -p /output/tarball/
sudo chown -R "${user}:${group}" "$x11_socket" /output
sudo chmod -R u=rwX,go= "$x11_socket"
sudo chmod -R u=rwX,go=rX /output

if [[ "$VERSION_ID" < "14.10" ]]; then
	gtk_package=libwxgtk2.8-dev
elif [[ "$VERSION_ID" < "18.10" ]]; then
	gtk_package=libwxgtk3.0-dev
elif [[ "$VERSION_ID" < "23.04" ]]; then
	gtk_package=libwxgtk3.0-gtk3-dev
else
	gtk_package=libwxgtk3.2-dev
fi

# liblmdb-dev libdb5.3-dev 
if [ "${VERSION_CODENAME}" = "groovy" -o \
     "${VERSION_CODENAME}" = "hirsute" -o \
     "${VERSION_CODENAME}" = "impish" -o \
     "${VERSION_CODENAME}" = "kinetic" ]; then
	sudo sed -i 's:archive.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
	sudo sed -i 's:security.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
fi
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
sudo DEBIAN_FRONTEND=noninteractive apt install -y wget gcc g++ cmake libssl-dev libsqlite3-dev libexpat1-dev zlib1g-dev libcurl4-gnutls-dev "$gtk_package"
# Install some development tools
sudo DEBIAN_FRONTEND=noninteractive apt install -y inotify-tools doxygen vim-gtk3 wdiff colordiff tmux valgrind || true
rm -fr ~/raw
mkdir ~/raw
cd ~/raw
#git clone git://git.code.sf.net/p/trustedqsl/tqsl
#git clone git://git.code.sf.net/u/penguin359/trustedqsl
#git clone ssh://penguin359@git.code.sf.net/u/penguin359/trustedqsl

version="$(curl -qsSLf https://arrl.org/tqsl-download | sed -ne 's@.*/tqsl-\([0-9]\+\(\.[0-9]\+\)\+\)\.tar\.gz.*@\1@p')"
wget "http://www.arrl.org/tqsl/tqsl-${version}.tar.gz"
rm -fr "tqsl-${version}"
tar xvf "tqsl-${version}.tar.gz"
cd "tqsl-${version}"
cmake -B build -S .
cmake --build build
sudo cmake --install build
sudo ldconfig
echo "===> Testing tqsl binary..."
tqsl --version 2>&1 | grep --color 'TQSL Version 2\..*'
echo "Success!"
cd
