#!/usr/bin/env bash

set -e

. /etc/os-release

user="$(id -un)"
group="$(id -gn)"

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi
if [ -f /tmp/cookies ]; then
	xauth merge /tmp/cookies
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo mkdir -p /output/appimage/
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

if [ "${VERSION_CODENAME}" = "groovy" -o \
     "${VERSION_CODENAME}" = "hirsute" -o \
     "${VERSION_CODENAME}" = "impish" -o \
     "${VERSION_CODENAME}" = "kinetic" ]; then
	sudo sed -i 's:archive.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
	sudo sed -i 's:security.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
fi
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
sudo DEBIAN_FRONTEND=noninteractive apt install -y wget gcc g++ cmake libssl-dev libsqlite3-dev libexpat1-dev zlib1g-dev libcurl4-gnutls-dev "$gtk_package" libfuse2 fuse3
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
