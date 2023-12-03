#!/bin/sh

set -e

. /etc/os-release

if [ "$VERSION_ID" = "14.04" ]; then
	VERSION_CODENAME="trusty"
fi

branch="backport-${VERSION_CODENAME}"

user="$(id -un)"
group="$(id -gn)"

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi
if [ -f /tmp/cookies ]; then
	xauth merge /tmp/cookies
fi
export SSH_AUTH_SOCK="/tmp/ssh-agent.sock"
export GPG_AGENT_INFO="$(gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2):0:1"
if tty >/dev/null 2>&1; then
	export GPG_TTY=$(tty)
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo mkdir -p /output/deb/
sudo chown -R "${user}:${group}" "$SSH_AUTH_SOCK" "${HOME}/.gnupg" "$x11_socket" /output
sudo chmod -R u=rwX,go= "$SSH_AUTH_SOCK" "${HOME}/.gnupg" "$x11_socket"
sudo chmod -R u=rwX,go=rX /output

echo 'Acquire::http::Proxy "http://10.146.39.1:3142";' | sudo tee /etc/apt/apt.conf.d/00aptproxy

if [ "${VERSION_CODENAME}" = "groovy" -o \
     "${VERSION_CODENAME}" = "hirsute" -o \
     "${VERSION_CODENAME}" = "impish" -o \
     "${VERSION_CODENAME}" = "kinetic" ]; then
	sudo sed -i 's:archive.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
	sudo sed -i 's:security.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
fi
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
#sudo DEBIAN_FRONTEND=noninteractive apt install -y wget dpkg-dev gcc cmake libssl-dev liblmdb-dev libdb5.3-dev libexpat1-dev zlib1g-dev libcurl4-gnutls-dev libwxgtk3.0-gtk3-dev libfuse2 trustedqsl #fuse3
#rm -fr ~/raw
#mkdir ~/raw
#cd ~/raw
#wget http://www.arrl.org/tqsl/tqsl-2.6.5.tar.gz
#rm -fr tqsl-2.6.5
#tar xvf tqsl-2.6.5.tar.gz
#cd tqsl-2.6.5
#cmake -B build -S .
#cmake --build build
#sudo cmake --install build
#sudo ldconfig
#tqsl --version 2>&1 | grep --color 'TQSL Version 2\..*'
#sudo mkdir -p /usr/local/bin/
## FIXME: Workaround needed on older Ubuntu releases
## error: RPC failed; curl 56 GnuTLS recv error (-54): Error in the pull function.
#git config --global http.postBuffer 1048576000
#./linux-make-appimage.sh
#./TQSL-x86_64.AppImage --version 2>&1 | grep --color 'TQSL Version 2\..*'
##./linux-make-appimage.sh || true
##./TQSL-x86_64.AppImage --version 2>&1 | grep --color 'TQSL Version 2\..*' || true
cd


paramiko=python3-paramiko
if [ "$branch" = "backport-trusty" ]; then
	paramiko="python-paramiko python-bzrlib"
fi
sudo DEBIAN_FRONTEND=noninteractive apt install -qy devscripts equivs git-buildpackage gnupg2 $paramiko
if [ "$branch" = "backport-xenial" ]; then
	sudo DEBIAN_FRONTEND=noninteractive apt remove -qy gnupg
fi
export DEBEMAIL="lorenl@north-winds.org"
export DEBFULLNAME="Loren M. Lang"

cat >.devscripts <<EOF
DEBUILD_DPKG_BUILDPACKAGE_OPTS="-i -I -us -uc"
#DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"
DEBSIGN_KEYID="7896E0999FC79F6CE0EDE103222DF356A57A98FA"
DSCVERIFY_KEYRINGS="$HOME/.gnupg/trustedkeys.gpg"
EOF
cat >.dput.cf <<EOF
[trustedqsl]
fqdn = ppa.launchpad.net
incoming = ~penguin359/ubuntu/trustedqsl/
method = sftp
login = penguin359
EOF

mkdir -p ~/.ssh/
cat >> ~/.ssh/known_hosts <<EOF
|1|L65WTC0AxkfE4nrvu2RV0ZmhURg=|wRCkGhAHG+NTMvWJZhrOk1Y/o1s= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0aKz5UTUndYgIGG7dQBV+HaeuEZJ2xPHo2DS2iSKvUL4xNMSAY4UguNW+pX56nAQmZKIZZ8MaEvSj6zMEDiq6HFfn5JcTlM80UwlnyKe8B8p7Nk06PPQLrnmQt5fh0HmEcZx+JU9TZsfCHPnX7MNz4ELfZE6cFsclClrKim3BHUIGq//t93DllB+h4O9LHjEUsQ1Sr63irDLSutkLJD6RXchjROXkNirlcNVHH/jwLWR5RcYilNX7S5bIkK8NlWPjsn/8Ua5O7I9/YoE97PpO6i73DTGLh5H9JN/SITwCKBkgSDWUt61uPK3Y11Gty7o2lWsBjhBUm2Y38CBsoGmBw==
|1|xPW80Prm6bDJ95oIpf2oWCo2ZbM=|f/tCGjfc5/6MrNIhruPMyX026nc= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0aKz5UTUndYgIGG7dQBV+HaeuEZJ2xPHo2DS2iSKvUL4xNMSAY4UguNW+pX56nAQmZKIZZ8MaEvSj6zMEDiq6HFfn5JcTlM80UwlnyKe8B8p7Nk06PPQLrnmQt5fh0HmEcZx+JU9TZsfCHPnX7MNz4ELfZE6cFsclClrKim3BHUIGq//t93DllB+h4O9LHjEUsQ1Sr63irDLSutkLJD6RXchjROXkNirlcNVHH/jwLWR5RcYilNX7S5bIkK8NlWPjsn/8Ua5O7I9/YoE97PpO6i73DTGLh5H9JN/SITwCKBkgSDWUt61uPK3Y11Gty7o2lWsBjhBUm2Y38CBsoGmBw==
EOF

# dch -v 2.6.5-3~penguin359~kinetic1
rm -f ~/.gnupg/trustedkeys.gpg
gpg2 --keyserver keyserver.ubuntu.com --recv-key "7896E0999FC79F6CE0EDE103222DF356A57A98FA"
#echo -e "5\ny\nsave\n" | gpg2 --command-fd 0 --edit-key "7896E0999FC79F6CE0EDE103222DF356A57A98FA" trust
gpg2 --import-ownertrust <<EOF
7896E0999FC79F6CE0EDE103222DF356A57A98FA:6:
EOF
gpg2 --check-trustdb
gpg2 --output ~/.gnupg/trustedkeys.gpg --export "7896E0999FC79F6CE0EDE103222DF356A57A98FA"

rm -fr ~/deb
mkdir ~/deb
cd ~/deb
rm -fr trustedqsl
git clone -b "$branch" https://github.com/penguin359/trustedqsl
mk-build-deps trustedqsl/debian/control
if [ "$branch" = "backport-trusty" ]; then
	sudo DEBIAN_FRONTEND=noninteractive dpkg -i ./trustedqsl-build-deps_*.deb || true
	sudo apt install -y -f
else
	sudo DEBIAN_FRONTEND=noninteractive apt install -qy ./trustedqsl-build-deps_*.deb
fi
wget http://archive.ubuntu.com/ubuntu/pool/universe/t/trustedqsl/trustedqsl_2.7.1.orig.tar.gz
cd trustedqsl
#lintian_opts="--fail-on error,warning"
lintian_opts="--fail-on error"
if [ "$branch" = "backport-trusty" -o \
     "$branch" = "backport-xenial" -o \
     "$branch" = "backport-bionic" -o \
     "$branch" = "backport-focal" ]; then
	lintian_opts=""
elif [ "$branch" = "backport-groovy" -o \
       "$branch" = "backport-hirsute" -o \
       "$branch" = "backport-impish" ]; then
	# Warnings are being produced due to Troff segfault
	lintian_opts="--fail-on error"
fi
#dpkg-buildpackage -kfakeroot
#gbp buildpackage --git-debian-branch="$branch" --git-tarball-dir=.. --lintian-opts $lintian_opts
echo "===> Building binary package..."
gbp buildpackage --git-debian-branch="$branch" --git-tarball-dir=.. --git-builder="debuild --no-lintian -i -I"
#lintian -i -I --fail-on error,warning,info,pedantic ../trustedqsl_*_amd64.changes
echo "===> Running lintian on binary package..."
lintian -I --pedantic $lintian_opts ../trustedqsl_*_amd64.changes
echo "===> Building source package..."
debuild --no-lintian -S
echo "===> Running lintian on source package..."
lintian -I --pedantic $lintian_opts ../trustedqsl_*_source.changes
#debsign
debsign -S
cd ..
sudo dpkg -i trustedqsl_*_amd64.deb
# Exits with status 255 on good invocation
tqsl --version 2>&1 | grep --color 'TQSL Version 2\..*'
dscverify trustedqsl_*_source.changes
dput -ol trustedqsl trustedqsl_*_source.changes
if [ "$1" = "-u" ]; then
	dput --debug -l trustedqsl trustedqsl_*_source.changes
fi
cp --preserve=timestamps trustedqsl_* /output/deb/
echo "Success!"
cd
