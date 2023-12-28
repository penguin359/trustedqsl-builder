FROM ubuntu:23.10

RUN apt-get update && \
    apt-get install -y flatpak flatpak-builder sudo
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
RUN flatpak install -y flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99-ubuntu-user
USER ubuntu
WORKDIR /build
COPY org.arrl.TrustedQSL.yml .
CMD ["bash"]
