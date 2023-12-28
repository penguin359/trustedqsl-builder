#!/bin/sh

set -e

flatpak-builder --user --install --force-clean build org.arrl.TrustedQSL.yml
flatpak run org.arrl.TrustedQSL
