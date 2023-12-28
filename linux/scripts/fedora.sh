#!/bin/sh

set -e

#lxc launch images:fedora/37
#lxc exec vital-rodent -- bash

sudo sed -i 's@https://mirror.csclub.uwaterloo.ca//fedora/linux@https://ftp-osl.osuosl.org/pub/fedora/linux@' /etc/yum.repos.d/fedora.repo
sudo sed -i 's@https://mirror.csclub.uwaterloo.ca//fedora/linux@http://mirrors.mit.edu/fedora/linux@' /etc/yum.repos.d/fedora*.repo
sudo sed -i 's@https://ftp-osl.osuosl.org/pub/fedora/linux@http://mirrors.mit.edu/fedora/linux@' /etc/yum.repos.d/fedora*.repo
#baseurl=http://mirrors.mit.edu/fedora/linux/releases/$releasever/Everything/source/tree/
#dnf config-manager --add-repo ...
dnf update --refresh
sudo dnf install -y dnf-plugins-core
dnf download --source trustedqsl
sudo dnf install -y rpm-build git rpmspectool gvim man

git clone https://src.fedoraproject.org/rpms/trustedqsl.git
cd trustedqsl
rpmbuild --undefine=_disable_source_fetch trustedqsl.spec

rpm -ivh trustedqsl-2.6.4-1.fc37.src.rpm
cd ~/rpmbuild/SPECS/
sudo dnf build-dep -y trustedqsl.spec
rpmlint trustedqsl.spec
rpmbuild -ba trustedqsl.spec

sudo dnf install -y pinentry
sudo dnf install -y rpm-sign rpmlint
gpg2 --gen-key
gpg2 --list-keys
gpg2 --export -a 'Package Manager' > RPM-GPG-KEY-pmanager
sudo rpm --import RPM-GPG-KEY-pmanager
rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'
cat >~/.rpmmacros <<EOF
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name Package Manager
%_gpgbin /usr/bin/gpg2
%__gpg_sign_cmd %{__gpg} gpg --force-v3-sigs --batch --verbose --no-armor --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}'
EOF
#%__gpg_sign_cmd %{__gpg} gpg --force-v3-sigs --batch --verbose --no-armor --passphrase-fd 3 --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}'

cd ~/rpmbuild/RPMS/x86_64/

#echo updatestartuptty | gpg-connect-agent
#export GPG_TTY="$(tty)"

(for i in *.rpm; do rpm --addsign "$i"; done)
(for i in *.rpm; do rpm --checksig "$i"; done)
rpmlint *.rpm
# FIXME This doesn't work
rpm -q --qf '%{SIGPGP:pgpsig} %{SIGGPG:pgpsig}\n' -p trustedqsl-2*.x86_64.rpm

rpm -Uvh *.rpm
tqsl --version

cd ~/rpmbuild/SRPMS/
(for i in *.rpm; do rpm --addsign "$i"; done)
(for i in *.rpm; do rpm --checksig "$i"; done)
rpmlint *.rpm
# FIXME This doesn't work
rpm -q --qf '%{SIGPGP:pgpsig} %{SIGGPG:pgpsig}\n' -p trustedqsl-2*.x86_64.rpm
