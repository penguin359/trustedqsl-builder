#!/bin/sh

set -e

user="$(id -un)"
group="$(id -gn)"

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo mkdir -p /output
sudo chown -R "${user}:${group}" "$x11_socket" /output
sudo chmod -R u=rwX,go= "$x11_socket"
sudo chmod -R u=rwX,go=rX /output

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
sudo DEBIAN_FRONTEND=noninteractive apt install -y wget gcc cmake libssl-dev liblmdb-dev libexpat1-dev zlib1g-dev libcurl4-gnutls-dev libwxgtk3.0-gtk3-dev
# Install some development tools
sudo DEBIAN_FRONTEND=noninteractive apt install -y inotify-tools doxygen vim-gtk3 wdiff colordiff tmux valgrind
rm -fr ~/raw
mkdir ~/raw
cd ~/raw
#git clone git://git.code.sf.net/p/trustedqsl/tqsl
git clone git://git.code.sf.net/u/penguin359/trustedqsl
#git clone ssh://penguin359@git.code.sf.net/u/penguin359/trustedqsl
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
echo "Success!"
cd
