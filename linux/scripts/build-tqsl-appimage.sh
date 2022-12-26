#!/bin/sh

set -e

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo mkdir -p /output/appimage/
sudo chown -R "$user" "$x11_socket" /output
sudo chmod -R u=rwX,go= "$x11_socket" /output

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
sudo DEBIAN_FRONTEND=noninteractive apt install -y wget dpkg-dev gcc cmake libssl-dev liblmdb-dev libdb5.3-dev libexpat1-dev zlib1g-dev libcurl4-gnutls-dev libwxgtk3.0-gtk3-dev libfuse2 trustedqsl fuse3
rm -fr ~/appimage
mkdir ~/appimage
cd ~/appimage
wget http://www.arrl.org/tqsl/tqsl-2.6.5.tar.gz
rm -fr tqsl-2.6.5
tar xvf tqsl-2.6.5.tar.gz
cd tqsl-2.6.5
sudo mkdir -p /usr/local/bin/
# FIXME: Workaround needed on older Ubuntu releases
# error: RPC failed; curl 56 GnuTLS recv error (-54): Error in the pull function.
git config --global http.postBuffer 1048576000
./linux-make-appimage.sh
#./linux-make-appimage.sh || true
echo "===> Testing tqsl binary..."
./TQSL-x86_64.AppImage --version 2>&1 | grep --color 'TQSL Version 2\..*'
#./TQSL-x86_64.AppImage --version 2>&1 | grep --color 'TQSL Version 2\..*' || true
cp --preserve=timestamps ./TQSL-x86_64.AppImage /output/appimage/
echo "Success!"
cd
