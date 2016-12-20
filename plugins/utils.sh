add_tar_apt() {
  curl -fsSL http://ftp.debian.org/debian/pool/main/t/tar/tar_1.29b-1.1_amd64.deb -o /tmp/tar.deb && \
  dpkg -i /tmp/tar.deb && rm -f /tmp/tar.deb
}

add_tar_apk() {
  main add-pkg tar
}
