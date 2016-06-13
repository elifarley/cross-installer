install_tar_debian() {
  curl -fsSL http://ftp.debian.org/debian/pool/main/t/tar/tar_1.29-1_amd64.deb -o /tmp/tar.deb && \
  dpkg -i /tmp/tar.deb && rm -f /tmp/tar.deb
}

install_tar_alpine() {
  apk add tar
}
